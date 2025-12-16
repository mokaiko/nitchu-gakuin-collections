// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title Nitchu Gakuin Collections Claim Script
 * @dev Script for users to claim a specified collection NFT
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
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ Step 1/5: proxy address deployed on Optimism
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            userPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ proxy address deployed on Polygon
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            userPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ proxy address for local Anvil
        });
    }

    function run() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // automatically select config by chain id

        uint256 tokenId = 1; // ⚠️ Token ID to claim

        // Obtain proxy contract instance; replace with your proxy address
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.userPrivateKey);
        proxy.claim(tokenId);
        vm.stopBroadcast();

        console.log("Claim completed. Token ID:", tokenId);
    }
}
