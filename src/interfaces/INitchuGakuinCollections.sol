// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title 日中学院数字藏品合约接口
 * @dev 定义藏品管理、白名单、领取等功能接口
 * @author Mo Kaiko
 * @custom:organization 日中学院
 * @custom:website https://www.rizhong.org/
 */
interface INitchuGakuinCollections {
    // 事件定义
    event CollectionCreated(uint256 indexed tokenId, string name, string description, uint256 maxSupply, bool isWhitelistEnabled, bool isActive);
    event CollectionStatusUpdated(uint256 indexed tokenId, bool isWhitelistEnabled, bool isActive);
    event CollectionClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WhitelistAdded(uint256 indexed tokenId, uint256 count);
    event WhitelistRemoved(uint256 indexed tokenId, uint256 count);
    event SvgChunkAdded(uint256 indexed tokenId, uint256 chunkIndex, uint256 totalChunks);
    event FinalizeSvgUpload(uint256 indexed tokenId);
    event AirdropCompleted(uint256 indexed tokenId, uint256 successfulCount, uint256 alreadyClaimedCount);

    // 错误定义
    error OnlyAdminOrOwner();
    error CollectionNotExists();
    error CollectionNotActive();
    error WhitelistRequired();
    error NotWhitelisted();
    error AlreadyClaimed();
    error MaxSupplyReached();
    error InvalidChunkIndex();
    error Svg_ParameterEmpty();
    error Svg_ChunksEmpty();
    error Svg_AlreadyFinalized();
    error Svg_NotFinalized();
    error ZeroAddress();
    error InvalidTokenId();
    error NoFundsTowithdraw();
    error TransferFailed();

    // 藏品信息结构体 推荐只存储简单数据，复杂数据放在映射外，以提高升级兼容性
    struct CollectionInfo {
        string name;                    // 藏品名称
        string description;             // 简介 在OpenSea等平台显示
        uint256 maxSupply;             // 最大供应量 0表示无限量
        uint256 currentSupply;         // 当前已铸造数量
        bool isWhitelistEnabled;       // 是否启用白名单
        bool isActive;                 // 是否可领取
        uint256 svgChunkCount;         // SVG数据块数量
        bool isSvgFinalized;           // SVG数据是否上传完成最终确定（锁定后永久不可修改）
    }

    /**
     * @dev 创建新的数字藏品
     * @param name 藏品名称
     * @param description 藏品简介
     * @param maxSupply 最大供应量
     * @param isWhitelistEnabled 是否启用白名单
     * @param isActive 是否立即激活
     */
    function createCollection(
        string memory name,
        string memory description,
        uint256 maxSupply,
        bool isWhitelistEnabled,
        bool isActive
    ) external returns (uint256);

    /**
     * @dev 更新藏品状态
     * @param tokenId 藏品ID
     * @param isWhitelistEnabled 是否启用白名单
     * @param isActive 是否可领取
     */
    function updateCollectionStatus(
        uint256 tokenId,
        bool isWhitelistEnabled,
        bool isActive
    ) external;

    /**
     * @dev 添加SVG数据块
     * @param tokenId 藏品ID
     * @param chunkIndex 数据块索引
     * @param chunkData 数据块内容
     */
    function addSvgChunk(
        uint256 tokenId,
        uint256 chunkIndex,
        bytes memory chunkData
    ) external;

    /**
     * @dev 完成上传并永久锁定SVG数据
     * @param tokenId 藏品ID
     */
    function finalizeSvgUpload(uint256 tokenId) external;

    /**
     * @dev 领取数字藏品
     * @param tokenId 藏品ID
     */
    function claim(uint256 tokenId) external;

    /**
     * @dev 管理员空投数字藏品给指定地址列表
     * @param tokenId 藏品ID
     * @param recipients 接收地址数组
     */
    function airdrop(uint256 tokenId, address[] memory recipients) external;

    /**
     * @dev 批量添加白名单
     * @param tokenId 藏品ID
     * @param accounts 账户地址数组
     */
    function addToWhitelist(uint256 tokenId, address[] memory accounts) external;

    /**
     * @dev 批量移除白名单
     * @param tokenId 藏品ID
     * @param accounts 账户地址数组
     */
    function removeFromWhitelist(uint256 tokenId, address[] memory accounts) external;

    /**
     * @dev 添加管理员
     * @param admin 管理员地址
     */
    function addAdmin(address admin) external;

    /**
     * @dev 移除管理员
     * @param admin 管理员地址
     */
    function removeAdmin(address admin) external;

    /**
     * @dev 获取完整的SVG数据
     * @param tokenId 藏品ID
     * @return 完整的SVG字符串
     */
    function getSvgData(uint256 tokenId) external view returns (string memory);

    /**
     * @dev 获取藏品信息
     * @param tokenId 藏品ID
     * @return name 名称
     * @return description 简介
     * @return maxSupply 最大供应量
     * @return currentSupply 当前供应量
     * @return isWhitelistEnabled 是否启用白名单
     * @return isActive 是否激活
     * @return svgChunkCount SVG块数量
     * @return isSvgFinalized SVG是否已完成并永久锁定
     */
    function getCollectionInfo(uint256 tokenId) external view returns (
        string memory name,
        string memory description,
        uint256 maxSupply,
        uint256 currentSupply,
        bool isWhitelistEnabled,
        bool isActive,
        uint256 svgChunkCount,
        bool isSvgFinalized
    );

    /**
     * @dev 检查地址是否在白名单中
     * @param tokenId 藏品ID
     * @param account 检查的地址
     * @return 是否在白名单中
     */
    function isWhitelisted(uint256 tokenId, address account) external view returns (bool);

    /**
     * @dev 检查地址是否已领取
     * @param tokenId 藏品ID
     * @param account 检查的地址
     * @return 是否已领取
     */
    function hasClaimed(uint256 tokenId, address account) external view returns (bool);

    /**
     * @dev 检查地址是否是管理员
     * @param account 检查的地址
     * @return 是否是管理员
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @dev 获取合约版本
     * @return 版本字符串
     */
    function getVersion() external pure returns (string memory);
}
