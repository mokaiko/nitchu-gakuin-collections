// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {INitchuGakuinCollections} from "./interfaces/INitchuGakuinCollections.sol";

/**
 * @title 日中学院数字藏品合约 V1
 * @dev ERC-1155 + UUPS 升级 + SVG 分块 + 白名单 + 管理员系统
 * @author Mo Kaiko
 * @custom:organization 日中学院
 * @custom:website https://www.rizhong.org/
 */
contract NitchuGakuinCollectionsV1 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    INitchuGakuinCollections,
    PausableUpgradeable
{
    /// ------------------------
    /// Storage
    /// ------------------------
    // 藏品计数器
    uint256 private _collectionCounter;

    // 管理员映射
    mapping(address => bool) private _admins;

    // 藏品信息
    mapping(uint256 => CollectionInfo) private _collections;

    // SVG 分块存储：tokenId => chunkIndex => chunkData 放在结构体外面 以提高升级兼容性
    mapping(uint256 => mapping(uint256 => bytes)) private _svgChunks;

    // 领取记录：tokenId => account => claimed
    mapping(uint256 => mapping(address => bool)) private _claimed;

    // 白名单：tokenId => account => whitelisted
    mapping(uint256 => mapping(address => bool)) private _whitelists;

    // 预留50个存储槽，永远放在变量的最后
    uint256[50] private __gap;

    /// ------------------------
    /// Modifiers
    /// ------------------------
    modifier onlyAdminOrOwner() {
        _onlyAdminOrOwner();
        _;
    }

    function _onlyAdminOrOwner() internal view {
        if (msg.sender != owner() && !_admins[msg.sender]) {
            revert OnlyAdminOrOwner();
        }
    }

    /// ------------------------
    /// Constructor
    /// ------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); // 禁用实现合约初始化
    }

    /// ------------------------
    /// Initialize
    /// ------------------------
    function initialize(address initialOwner) public initializer {
        __ERC1155_init(""); // ERC1155 URI 空
        __Ownable_init(initialOwner); // 初始化所有者
        __Pausable_init();
        _collectionCounter = 1; // tokenId 从1开始
        _admins[initialOwner] = true;
    }

    /// ------------------------
    /// Collection Management
    /// ------------------------

    function createCollection(
        string memory name,
        string memory description,
        uint256 maxSupply,
        bool isWhitelistEnabled,
        bool isActive
    ) public override onlyAdminOrOwner returns (uint256) {
        uint256 tokenId = _collectionCounter;
        _collectionCounter++;

        CollectionInfo storage collection = _collections[tokenId];
        // 逐个字段赋值
        collection.name = name;
        collection.description = description;
        collection.maxSupply = maxSupply;
        collection.currentSupply = 0;
        collection.isWhitelistEnabled = isWhitelistEnabled;
        collection.isActive = isActive;
        collection.svgChunkCount = 0;
        collection.isSvgFinalized = false;

        emit CollectionCreated(tokenId, name, description, maxSupply, isWhitelistEnabled, isActive);
        return tokenId;
    }

    function updateCollectionStatus(uint256 tokenId, bool isWhitelistEnabled, bool isActive)
        public
        override
        onlyAdminOrOwner
    {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();

        collection.isWhitelistEnabled = isWhitelistEnabled;
        collection.isActive = isActive;

        emit CollectionStatusUpdated(tokenId, isWhitelistEnabled, isActive);
    }

    /// ------------------------
    /// SVG Management
    /// ------------------------
    /**
     * @param tokenId 藏品ID
     * @param chunkIndex svg数据块索引 必须从0开始
     * @param chunkData svg数据块内容 不能为空
     */
    function addSvgChunk(uint256 tokenId, uint256 chunkIndex, bytes memory chunkData) public override onlyAdminOrOwner {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (collection.isSvgFinalized) revert Svg_AlreadyFinalized();
        if (chunkIndex != collection.svgChunkCount) revert InvalidChunkIndex();
        if (chunkData.length == 0) revert Svg_ParameterEmpty();

        _svgChunks[tokenId][chunkIndex] = chunkData;
        collection.svgChunkCount++;

        emit SvgChunkAdded(tokenId, chunkIndex, collection.svgChunkCount);
    }

    /**
     * @dev 获取 SVG 数据、预览（未完成上传完也可预览）前端预览没问题后再调用 completeSvgUpload 完成上传
     */
    function getSvgData(uint256 tokenId) public view returns (string memory) {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (collection.svgChunkCount == 0) revert Svg_ChunksEmpty();

        // 拼接所有 chunk
        bytes memory svgData;
        for (uint256 i = 0; i < collection.svgChunkCount; i++) {
            svgData = abi.encodePacked(svgData, _svgChunks[tokenId][i]);
        }

        return string(svgData); // 最终返回 string
    }

    /**
     * @dev 完成SVG数据上传并永久锁定 锁定后将不能再修改 SVG 数据
     */
    function finalizeSvgUpload(uint256 tokenId) public override onlyAdminOrOwner {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (collection.svgChunkCount == 0) revert Svg_ChunksEmpty();

        collection.isSvgFinalized = true;
        emit FinalizeSvgUpload(tokenId);
    }

    /// ------------------------
    /// Claim
    /// ------------------------

    function claim(uint256 tokenId) public override whenNotPaused {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (!collection.isActive) revert CollectionNotActive();
        if (_claimed[tokenId][msg.sender]) revert AlreadyClaimed();
        if (collection.isWhitelistEnabled && !_whitelists[tokenId][msg.sender]) revert NotWhitelisted();
        uint256 amount = 1; // 每次只能领取1个
        if (collection.maxSupply != 0 && collection.currentSupply + amount > collection.maxSupply) {
            revert MaxSupplyReached();
        }
        if (!collection.isSvgFinalized) revert Svg_NotFinalized();

        _claimed[tokenId][msg.sender] = true;
        collection.currentSupply++;

        _mint(msg.sender, tokenId, amount, "");

        emit CollectionClaimed(tokenId, msg.sender, 1);
    }

    /// ------------------------
    /// Airdrop
    /// ------------------------
    /**
     * @dev
     * 用于管理员一次性向多个地址发放指定藏品。
     * 规则说明：
     * - 每个地址仅空投 1 个 token
     * - 不受以下限制：
     *    • isActive（藏品激活状态）
     *    • isWhitelistEnabled（白名单状态）
     *    • maxSupply（最大供应量限制）
     * - 但必须满足以下条件：
     *    • 对应藏品已存在
     *    • SVG 已完成上传并锁定（isSvgFinalized == true）
     * - 跳过以下情况（不会回滚整个交易）：
     *    • 地址为 0x0（invalidAddress）
     *    • 地址已领取过（hasClaimed == true）
     * @param tokenId 藏品ID
     * @param recipients 接收空投的地址数组
     */
    function airdrop(uint256 tokenId, address[] memory recipients) external override onlyAdminOrOwner whenNotPaused {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (!collection.isSvgFinalized) revert Svg_NotFinalized();
        if (recipients.length == 0) revert Svg_ParameterEmpty();

        uint256 successfulCount;
        uint256 alreadyClaimedCount;

        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            if (to == address(0)) {
                continue;
            }
            if (_claimed[tokenId][to]) {
                alreadyClaimedCount++;
                continue;
            }

            _claimed[tokenId][to] = true;
            collection.currentSupply += 1;
            _mint(to, tokenId, 1, "");

            successfulCount++;
        }

        emit AirdropCompleted(tokenId, successfulCount, alreadyClaimedCount);
    }

    /// ------------------------
    /// Whitelist Management
    /// ------------------------

    function addToWhitelist(uint256 tokenId, address[] memory accounts) public override onlyAdminOrOwner {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) revert ZeroAddress();
            _whitelists[tokenId][accounts[i]] = true;
        }
        emit WhitelistAdded(tokenId, accounts.length);
    }

    function removeFromWhitelist(uint256 tokenId, address[] memory accounts) public override onlyAdminOrOwner {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) revert ZeroAddress();
            _whitelists[tokenId][accounts[i]] = false;
        }
        emit WhitelistRemoved(tokenId, accounts.length);
    }

    /// ------------------------
    /// Admin Management
    /// ------------------------

    function addAdmin(address admin) public override onlyOwner {
        if (admin == address(0)) revert ZeroAddress();
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) public override onlyOwner {
        if (admin == address(0)) revert ZeroAddress();
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    /// ------------------------
    /// SVG Retrieval
    /// ------------------------

    function uri(uint256 tokenId) public view override returns (string memory) {
        CollectionInfo storage collection = _collections[tokenId];

        string memory svgData = getSvgData(tokenId);
        // 使用string.concat提高Gas效率
        string memory json = string.concat(
            '{"name":"',
            collection.name,
            '",',
            '"description":"',
            collection.description,
            '",',
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svgData)),
            '",',
            '"attributes":[{"trait_type":"Collection","value":"Nitchu Gakuin"}]}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// ------------------------
    /// Info & Checks
    /// ------------------------

    function getCollectionInfo(uint256 tokenId)
        public
        view
        override
        returns (
            string memory name,
            string memory description,
            uint256 maxSupply,
            uint256 currentSupply,
            bool isWhitelistEnabled,
            bool isActive,
            uint256 svgChunkCount,
            bool isSvgFinalized
        )
    {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();

        return (
            collection.name,
            collection.description,
            collection.maxSupply,
            collection.currentSupply,
            collection.isWhitelistEnabled,
            collection.isActive,
            collection.svgChunkCount,
            collection.isSvgFinalized
        );
    }

    function isWhitelisted(uint256 tokenId, address account) public view override returns (bool) {
        return _whitelists[tokenId][account];
    }

    function hasClaimed(uint256 tokenId, address account) public view override returns (bool) {
        return _claimed[tokenId][account];
    }

    function isAdmin(address account) public view override returns (bool) {
        return _admins[account];
    }

    /// ------------------------
    /// UUPS Upgrade
    /// ------------------------

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// ------------------------
    /// Supports Interface
    /// ------------------------

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable) returns (bool) {
        return interfaceId == type(INitchuGakuinCollections).interfaceId || super.supportsInterface(interfaceId);
    }

    /// ------------------------
    /// Pausable
    /// ------------------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// ------------------------
    // 接收原生币
    receive() external payable {}

    /// 提现合约中的原生币到所有者地址
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsTowithdraw();
        (bool success,) = owner().call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    /// ------------------------
    /// Version
    /// ------------------------
    function getVersion() external pure returns (string memory) {
        return "V1.0.0";
    }
}
