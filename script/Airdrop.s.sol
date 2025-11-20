// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title 日中学院数字藏品空投脚本
 * @dev 用于向指定藏品批量空投 NFT 给多个地址
 * @author Mo Kaiko
 */
contract AirdropScript is Script {
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
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ 步骤 1/5, 使用 Optimism 部署的代理合约地址
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ 使用 Polygon 部署的代理合约地址
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ 使用 Anvil 部署的代理合约地址
        });
    }

    function run() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // 自动获取当前链ID对应配置

        uint256 tokenId = 1; // ⚠️ 要空投的藏品 ID
        address[] memory recipients = new address[](1); // ⚠️ 要空投的地址列表，替换为实际地址
        recipients[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // 已空投过测试

        // 获取代理合约实例，替换为代理合约地址
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.deployerPrivateKey);
        proxy.airdrop(tokenId, recipients);
        vm.stopBroadcast();

        console.log("Airdrop completed. Token ID:", tokenId);
        console.log("Recipients:", recipients.length);
    }
}
