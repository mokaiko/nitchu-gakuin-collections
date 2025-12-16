// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title Nitchu Gakuin Collections: Create Collection Script
 * @dev Script to create a new collection (and upload related SVG chunks)
 * @author Mo Kaiko
 */
contract CreateCollectionScript is Script {
    struct NetworkConfig {
        string rpcUrl;
        uint256 deployerPrivateKey;
        address proxyAddress;
    }
    mapping(uint256 => NetworkConfig) public networkConfigs;

    function setUp() public {
        networkConfigs[10] = NetworkConfig({
            rpcUrl: vm.envString("OP_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ Step 1/5: proxy address deployed on Optimism
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ Step 1/5: proxy address deployed on Polygon
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ Step 1/5: proxy address for local Anvil
        });
    }

    function run() external {

        NetworkConfig memory config = networkConfigs[block.chainid]; // automatically select config by chain id

        string memory name = unicode"日中学院 初代デジタル記念印"; // ⚠️ Step 2/5: collection name
        string memory description =
            unicode"日中学院日本語科の創立40周年を記念して発行された、学校初のデジタル記念コレクション。「日中学院」の校名を刻んだ印章型デザインが、これまでの歩みと絆を象徴しています。"; // ⚠️ Collection description
        uint256 maxSupply = 0; // ⚠️ Step 3/5: max supply (0 means unlimited)
        bool isWhitelistEnabled = false; // ⚠️ Step 4/5: enable whitelist
        bool isActive = true; // ⚠️ Step 5/5: set collection active

        // Obtain proxy contract instance; replace with your proxy address
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.deployerPrivateKey);
        uint256 tokenId = proxy.createCollection(name, description, maxSupply, isWhitelistEnabled, isActive);
        vm.stopBroadcast();

        console.log("Collection created.");

        (
            string memory _name,
            string memory _description,
            uint256 _maxSupply,
            uint256 _currentSupply,
            bool _isWhitelistEnabled,
            bool _isActive,
            uint256 _svgChunkCount,
            bool _isSvgFinalized
        ) = proxy.getCollectionInfo(tokenId);
        console.log("Created Collection ID:", tokenId);
        console.log("Name:", _name);
        console.log("Description:", _description);
        console.log("Max Supply:", _maxSupply);
        console.log("Current Supply:", _currentSupply);
        console.log("Is Whitelist Enabled:", _isWhitelistEnabled);
        console.log("Is Active:", _isActive);
        console.log("SVG Chunk Count:", _svgChunkCount);
        console.log("Is SVG Finalized:", _isSvgFinalized);
    }
}
