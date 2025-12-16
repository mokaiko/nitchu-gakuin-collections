// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @title Nitchu Gakuin Collections Upgrade Script
 * @dev Utilities to upgrade proxy contracts, validate upgrade compatibility,
 *      and prepare new implementation deployments
 * @author Mo Kaiko
 */
contract UpgradeScript is Script {
    struct NetworkConfig {
        string rpcUrl;
        uint256 deployerPrivateKey;
        address proxyAddress;
    }
    mapping(uint256 => NetworkConfig) public networkConfigs;
    string public constant OLD_CONTRACT_NAME = "NitchuGakuinCollectionsV1.sol"; //  ⚠️ Step 1/3: reference old contract name
    string public constant NEW_CONTRACT_NAME = "NitchuGakuinCollectionsV2.sol"; //  ⚠️ Step 2/3: new implementation contract name

    function setUp() public {
        networkConfigs[10] = NetworkConfig({
            rpcUrl: vm.envString("OP_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ Step 3/3: proxy address deployed on Optimism
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ Step 3/3: proxy address deployed on Polygon
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ Step 3/3: proxy address for local Anvil
        });
    }

    /**
     * @dev Step 1/3: Validate upgrade compatibility between old and new implementations
     *      (off-chain check, no on-chain state changes)
     */
    function validateUpgrade() external {
        Options memory opts;
        opts.referenceContract = OLD_CONTRACT_NAME;

        console.log("Validating upgrade compatibility...");
        Upgrades.validateUpgrade(NEW_CONTRACT_NAME, opts);
        console.log("Upgrade validation passed!");
    }

    /**
     * @dev Step 2/3 (optional): Prepare upgrade by deploying the new implementation
     *      without changing the proxy. Useful for pre-deployment or CI checks.
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
     * @dev Step 3/3: Perform an on-chain upgrade of the proxy to the new implementation
     */
    function upgradeTo() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // automatically select config by chain id
        vm.startBroadcast(config.deployerPrivateKey);

        Options memory opts;
        opts.referenceContract = OLD_CONTRACT_NAME; // explicitly set reference contract
        console.log("Upgrading proxy...");

        Upgrades.upgradeProxy(config.proxyAddress, NEW_CONTRACT_NAME, "", opts);
        vm.stopBroadcast();

        console.log("Upgrade completed!");
        console.log("New implementation:", Upgrades.getImplementationAddress(config.proxyAddress));
        console.log("Proxy address remains the same:", config.proxyAddress);
    }
}
