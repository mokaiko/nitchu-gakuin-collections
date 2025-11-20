// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NitchuGakuinCollectionsV1} from "../src/NitchuGakuinCollectionsV1.sol"; //  ⚠️ 要部署的合约文件

/**
 * @title 日中学院数字藏品部署脚本
 * @dev 用于首次部署可升级的 ERC-1155 合约
 * @author Mo Kaiko
 */
contract DeployScript is Script {
    struct NetworkConfig {
        string rpcUrl;
        uint256 deployerPrivateKey;
    }
    mapping(uint256 => NetworkConfig) public networkConfigs;
    string public constant CONTRACT_NAME = "NitchuGakuinCollectionsV1.sol"; //  ⚠️ 要部署的合约名称

    function setUp() public {
        networkConfigs[10] = NetworkConfig({
            rpcUrl: vm.envString("OP_RPC_URL"), deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1")
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"), deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1")
        });
        networkConfigs[31337] =
            NetworkConfig({rpcUrl: "http://localhost:8545", deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1")});
    }

    /**
     * @dev 部署可升级代理合约并完成初始化
     */
    function run() external returns (address) {
        NetworkConfig memory config = networkConfigs[block.chainid]; // 自动获取当前链ID对应配置

        vm.startBroadcast(config.deployerPrivateKey);

        address initialOwner = vm.addr(config.deployerPrivateKey); // 使用私钥对应的地址
        console.log("Deploying NitchuGakuinCollections..."); // 首次部署
        console.log("Initial owner:", initialOwner);

        address proxy = Upgrades.deployUUPSProxy(
            CONTRACT_NAME, // V1 版本合约文件名
            abi.encodeCall(NitchuGakuinCollectionsV1.initialize, (initialOwner))
        );

        vm.stopBroadcast();

        console.log("Proxy deployed at:", proxy);
        console.log("Implementation address:", Upgrades.getImplementationAddress(proxy));
        return proxy;
    }
}
