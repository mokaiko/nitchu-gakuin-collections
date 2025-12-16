// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// OpenZeppelin upgradeable contract imports
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

// Import interface
import {INitchuGakuinCollections} from "./interfaces/INitchuGakuinCollections.sol";

/**
 * @title Nitchu Gakuin Collections V2 (optimized)
 * @dev ERC-1155 with UUPS upgradeability, SVG chunking, whitelist and admin system
 * @author Mo Kaiko
 * @custom:organization Nitchu Gakuin
 * @custom:website https://www.rizhong.org/
 */
contract NitchuGakuinCollectionsV2 is
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
    // collection counter
    uint256 private _collectionCounter;

    // admin mapping
    mapping(address => bool) private _admins;

    // collection metadata
    mapping(uint256 => CollectionInfo) private _collections;

    // SVG chunk storage: tokenId => chunkIndex => chunkData. Stored outside the struct for upgrade safety.
    mapping(uint256 => mapping(uint256 => bytes)) private _svgChunks;

    // claim records: tokenId => account => claimed
    mapping(uint256 => mapping(address => bool)) private _claimed;

    // whitelist: tokenId => account => whitelisted
    mapping(uint256 => mapping(address => bool)) private _whitelists;

    // reserve 50 storage slots for upgrade safety
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
        _disableInitializers(); // disable initializers for implementation contract
    }

    /// ------------------------
    /// Initialize
    /// ------------------------
    function initialize(address initialOwner) public initializer {
        __ERC1155_init(""); // empty ERC1155 URI
        __Ownable_init(initialOwner); // initialize owner
        __Pausable_init();
        _collectionCounter = 1; // token IDs start from 1
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
        // assign fields one by one
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
     * @param tokenId collection ID
     * @param chunkIndex index of the SVG chunk (must start at 0)
     * @param chunkData chunk bytes (must not be empty)
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
     * @dev Get the SVG data for preview. This can be used before finalizing upload.
     *      Call `finalizeSvgUpload` after verifying frontend preview is correct.
     */
    function getSvgData(uint256 tokenId) public view returns (string memory) {
        CollectionInfo storage collection = _collections[tokenId];
        if (bytes(collection.name).length == 0) revert CollectionNotExists();
        if (collection.svgChunkCount == 0) revert Svg_ChunksEmpty();

        // concatenate all chunks
        bytes memory svgData;
        for (uint256 i = 0; i < collection.svgChunkCount; i++) {
            svgData = abi.encodePacked(svgData, _svgChunks[tokenId][i]);
        }

        return string(svgData); // return final string
    }

    /**
     * @dev Finalize SVG upload and permanently lock the SVG data. After finalization
     *      the SVG cannot be modified.
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
        uint256 amount = 1; // amount per claim (1)
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
     * @dev Admin batch airdrop for a collection. Rules:
     * - Each address receives 1 token
     * - Airdrop ignores isActive, whitelist, and maxSupply checks
     * - Preconditions: collection must exist and SVG must be finalized
     * - Skips (does not revert) for:
     *    • zero address
     *    • address that already claimed
     * @param tokenId collection ID
     * @param recipients recipient addresses
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
        // Use string.concat to improve gas efficiency
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// ------------------------
    // Receive native token (ETH)
    receive() external payable {}

    /// Withdraw native token balance from the contract to the owner
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
        return "V2.0.0";
    }
}
