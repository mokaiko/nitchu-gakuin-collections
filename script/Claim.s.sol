// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title 日中学院数字藏品领取脚本
 * @dev 用于用户领取指定藏品 NFT
 * @author Mo Kaiko
 */
contract ClaimScript is Script {
    struct NetworkConfig {
        string rpcUrl;
        uint256 userPrivateKey;
        address proxyAddress;
    }
    mapping(uint256 => NetworkConfig) public networkConfigs;

    function setUp() public {
        networkConfigs[10] = NetworkConfig({
            rpcUrl: vm.envString("OP_RPC_URL"),
            userPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ 步骤 1/5, 使用 Optimism 部署的代理合约地址
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            userPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ 使用 Polygon 部署的代理合约地址
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            userPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ 使用 Anvil 部署的代理合约地址
        });
    }

    function run() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // 自动获取当前链ID对应配置

        uint256 tokenId = 1; // ⚠️ 要领取的藏品 ID

        // 获取代理合约实例，替换为代理合约地址
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.userPrivateKey);
        proxy.claim(tokenId);
        vm.stopBroadcast();

        console.log("Claim completed. Token ID:", tokenId);
    }
}
