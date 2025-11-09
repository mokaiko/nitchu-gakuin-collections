// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title 日中学院数字藏品创建新藏品脚本
 * @dev 用于向指定藏品上传 SVG 数据块
 * @author Mo Kaiko
 */
contract CreateCollectionScript is Script {
    struct NetworkConfig { string rpcUrl; uint256 deployerPrivateKey; address proxyAddress; }
    mapping(uint256 => NetworkConfig) public networkConfigs;

    function setUp() public { 
        networkConfigs[10] = NetworkConfig({ 
            rpcUrl: vm.envString("OP_RPC_URL"), 
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress:0x9d291c7a50A3bF0980E732890177FD4e0998E13a     // ⚠️ 步骤 1/5, 使用 Optimism 部署的代理合约地址
        });
        networkConfigs[137] = NetworkConfig({ 
            rpcUrl: vm.envString("POLYGON_RPC_URL"), 
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress:0x627E2C31cB771cfCD1207A7322773BDc3593eE4d     //  ⚠️ 步骤 1/5, 使用 Polygon 部署的代理合约地址
        }); 
        networkConfigs[31337] = NetworkConfig({ 
            rpcUrl: "http://localhost:8545", 
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress:0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512     //  ⚠️ 步骤 1/5, 使用 Anvil 部署的代理合约地址
        });
    }

    function run() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // 自动获取当前链ID对应配置
        
        string memory name = unicode"日中学院 初代デジタル記念印"; //  ⚠️ 步骤 2/5, 藏品名称
        string memory description = unicode"日中学院日本語科の創立40周年を記念して発行された、学校初のデジタル記念コレクション。「日中学院」の校名を刻んだ印章型デザインが、これまでの歩みと絆を象徴しています。";   //  ⚠️ 藏品描述
        uint256 maxSupply = 0;               // ⚠️ 步骤 3/5, 藏品最大供应量，0表示无限量
        bool isWhitelistEnabled = false;    // ⚠️ 步骤 4/5, 是否启用白名单
        bool isActive = true;               // ⚠️ 步骤 5/5, 藏品是否激活

        // 获取代理合约实例，替换为代理合约地址
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.deployerPrivateKey);
        uint tokenId = proxy.createCollection(
                    name,
                    description,
                    maxSupply,
                    isWhitelistEnabled,
                    isActive
                );
        vm.stopBroadcast();

        console.log("Collection created.");
        
        (string  memory _name,
        string  memory _description,
        uint256 _maxSupply,
        uint256 _currentSupply,
        bool _isWhitelistEnabled,
        bool _isActive,
        uint256 _svgChunkCount,
        bool _isSvgFinalized
        )= proxy.getCollectionInfo(tokenId);
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
