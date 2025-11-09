// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @title 日中学院数字藏品升级脚本
 * @dev 用于升级代理合约、验证兼容性、或准备新实现
 * @author Mo Kaiko
 */
contract UpgradeScript is Script {
    struct NetworkConfig { string rpcUrl; uint256 deployerPrivateKey; address proxyAddress; }
    mapping(uint256 => NetworkConfig) public networkConfigs;
    string public constant OLD_CONTRACT_NAME = "NitchuGakuinCollectionsV1.sol"; //  ⚠️ 步骤 1/3, 旧版本合约名称
    string public constant NEW_CONTRACT_NAME = "NitchuGakuinCollectionsV2.sol"; //  ⚠️ 步骤 2/3, 新版本合约名称

    function setUp() public { 
        networkConfigs[10] = NetworkConfig({ 
            rpcUrl: vm.envString("OP_RPC_URL"), 
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress:0x9d291c7a50A3bF0980E732890177FD4e0998E13a     // ⚠️ 步骤 3/3, 使用 Optimism 部署的代理合约地址
        });
        networkConfigs[137] = NetworkConfig({ 
            rpcUrl: vm.envString("POLYGON_RPC_URL"), 
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress:0x627E2C31cB771cfCD1207A7322773BDc3593eE4d     //  ⚠️ 步骤 3/3, 使用 Polygon 部署的代理合约地址
        }); 
        networkConfigs[31337] = NetworkConfig({ 
            rpcUrl: "http://localhost:8545", 
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress:0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512     //  ⚠️ 步骤 3/3, 使用 Anvil 部署的代理合约地址
        });
    }

    /**
     * @dev 第1/3步 验证新旧合约是否兼容升级（不会写链上）
     */
    function validateUpgrade() external {
        Options memory opts;
        opts.referenceContract = OLD_CONTRACT_NAME;

        console.log("Validating upgrade compatibility...");
        Upgrades.validateUpgrade(NEW_CONTRACT_NAME, opts);
        console.log("Upgrade validation passed!");
    }

    /**
     * @dev 第2/3步(可跳过) 准备升级：仅部署新的实现，不修改代理地址。
     *      可用于预部署、CI/CD 自动化验证。
     */
    function prepareUpgrade() external returns (address) {
        Options memory opts;
        opts.referenceContract = OLD_CONTRACT_NAME;

        console.log("Preparing upgrade (deploying new implementation)...");
        address newImpl = Upgrades.prepareUpgrade(NEW_CONTRACT_NAME, opts);

        console.log("New implementation deployed:", newImpl);
        return newImpl;
    }

    /**
     * @dev 第3/3步 升级代理到新实现
     */
    function upgradeTo() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // 自动获取当前链ID对应配置
        vm.startBroadcast(config.deployerPrivateKey);

        Options memory opts;
        opts.referenceContract = OLD_CONTRACT_NAME; // 明确指定参考合约
        console.log("Upgrading proxy...");
        
        Upgrades.upgradeProxy(config.proxyAddress, NEW_CONTRACT_NAME, "", opts);
        vm.stopBroadcast();

        console.log("Upgrade completed!");
        console.log("New implementation:", Upgrades.getImplementationAddress(config.proxyAddress));
        console.log("Proxy address remains the same:", config.proxyAddress);
    }
}
