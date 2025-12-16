// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Nitchu Gakuin Collections Interface
 * @dev Interface for collection management, whitelist, claim, and SVG handling
 * @author Mo Kaiko
 * @custom:organization Nitchu Gakuin
 * @custom:website https://www.rizhong.org/
 */
interface INitchuGakuinCollections {
    // Events
    event CollectionCreated(
        uint256 indexed tokenId,
        string name,
        string description,
        uint256 maxSupply,
        bool isWhitelistEnabled,
        bool isActive
    );
    event CollectionStatusUpdated(uint256 indexed tokenId, bool isWhitelistEnabled, bool isActive);
    event CollectionClaimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WhitelistAdded(uint256 indexed tokenId, uint256 count);
    event WhitelistRemoved(uint256 indexed tokenId, uint256 count);
    event SvgChunkAdded(uint256 indexed tokenId, uint256 chunkIndex, uint256 totalChunks);
    event FinalizeSvgUpload(uint256 indexed tokenId);
    event AirdropCompleted(uint256 indexed tokenId, uint256 successfulCount, uint256 alreadyClaimedCount);

    // Errors
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

    // Collection information struct. Keep simple data in the struct and
    // store larger or variable data in separate mappings to improve upgrade compatibility.
    struct CollectionInfo {
        string name; // collection name
        string description; // description displayed on marketplaces (e.g., OpenSea)
        uint256 maxSupply; // max supply, 0 for unlimited
        uint256 currentSupply; // current minted amount
        bool isWhitelistEnabled; // whether whitelist is enabled
        bool isActive; // whether claims are active
        uint256 svgChunkCount; // number of SVG chunks
        bool isSvgFinalized; // whether SVG upload is finalized (locked permanently)
    }

    /**
     * @dev Create a new digital collection
     * @param name collection name
     * @param description collection description
     * @param maxSupply maximum supply
     * @param isWhitelistEnabled whether whitelist is enabled
     * @param isActive whether the collection is active immediately
     */
    function createCollection(
        string memory name,
        string memory description,
        uint256 maxSupply,
        bool isWhitelistEnabled,
        bool isActive
    ) external returns (uint256);

    /**
     * @dev Update collection status
     * @param tokenId collection ID
     * @param isWhitelistEnabled whether whitelist is enabled
     * @param isActive whether claims are enabled
     */
    function updateCollectionStatus(uint256 tokenId, bool isWhitelistEnabled, bool isActive) external;

    /**
     * @dev Add an SVG chunk
     * @param tokenId collection ID
     * @param chunkIndex chunk index
     * @param chunkData chunk bytes
     */
    function addSvgChunk(uint256 tokenId, uint256 chunkIndex, bytes memory chunkData) external;

    /**
     * @dev Finalize SVG upload and lock the SVG data permanently
     * @param tokenId collection ID
     */
    function finalizeSvgUpload(uint256 tokenId) external;

    /**
     * @dev Claim a collection token
     * @param tokenId collection ID
     */
    function claim(uint256 tokenId) external;

    /**
     * @dev Admin airdrop collection tokens to a list of recipients
     * @param tokenId collection ID
     * @param recipients recipient addresses
     */
    function airdrop(uint256 tokenId, address[] memory recipients) external;

    /**
     * @dev Add multiple accounts to the whitelist
     * @param tokenId collection ID
     * @param accounts account addresses
     */
    function addToWhitelist(uint256 tokenId, address[] memory accounts) external;

    /**
     * @dev Remove multiple accounts from the whitelist
     * @param tokenId collection ID
     * @param accounts account addresses
     */
    function removeFromWhitelist(uint256 tokenId, address[] memory accounts) external;

    /**
     * @dev Add an admin
     * @param admin admin address
     */
    function addAdmin(address admin) external;

    /**
     * @dev Remove an admin
     * @param admin admin address
     */
    function removeAdmin(address admin) external;

    /**
     * @dev Get the full SVG data
     * @param tokenId collection ID
     * @return full SVG string
     */
    function getSvgData(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Get collection information
     * @param tokenId collection ID
     * @return name name
     * @return description description
     * @return maxSupply maximum supply
     * @return currentSupply current supply
     * @return isWhitelistEnabled whether whitelist is enabled
     * @return isActive whether collection is active
     * @return svgChunkCount number of SVG chunks
     * @return isSvgFinalized whether SVG is finalized and locked
     */
    function getCollectionInfo(uint256 tokenId)
        external
        view
        returns (
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
     * @dev Check whether an account is whitelisted for a collection
     * @param tokenId collection ID
     * @param account address to check
     * @return whether the account is whitelisted
     */
    function isWhitelisted(uint256 tokenId, address account) external view returns (bool);

    /**
     * @dev Check whether an account has claimed a token
     * @param tokenId collection ID
     * @param account address to check
     * @return whether the account has claimed
     */
    function hasClaimed(uint256 tokenId, address account) external view returns (bool);

    /**
     * @dev Check whether an address is an admin
     * @param account address to check
     * @return whether the address is an admin
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @dev Get contract version
     * @return version string
     */
    function getVersion() external pure returns (string memory);
}
