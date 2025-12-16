// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {INitchuGakuinCollections} from "../src/interfaces/INitchuGakuinCollections.sol";

/**
 * @title Nitchu Gakuin Collections Airdrop Script
 * @dev Batch airdrop collection NFTs to a list of addresses
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
            proxyAddress: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a // ⚠️ Step 1/5: proxy address deployed on Optimism
        });
        networkConfigs[137] = NetworkConfig({
            rpcUrl: vm.envString("POLYGON_RPC_URL"),
            deployerPrivateKey: vm.envUint("PRIVATE_KEY_ACCOUNT_1"),
            proxyAddress: 0x627E2C31cB771cfCD1207A7322773BDc3593eE4d //  ⚠️ proxy address deployed on Polygon
        });
        networkConfigs[31337] = NetworkConfig({
            rpcUrl: "http://localhost:8545",
            deployerPrivateKey: vm.envUint("ANVIL_PRIVATE_KEY_1"),
            proxyAddress: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 //  ⚠️ proxy address for local Anvil
        });
    }

    function run() external {
        NetworkConfig memory config = networkConfigs[block.chainid]; // automatically select config by chain id

        uint256 tokenId = 1; // ⚠️ Token ID to airdrop
        address[] memory recipients = new address[](1); // ⚠️ Recipient list to airdrop; replace with real addresses
        recipients[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // sample test recipient

        // Obtain proxy contract instance; replace with your proxy address
        INitchuGakuinCollections proxy = INitchuGakuinCollections(config.proxyAddress);

        vm.startBroadcast(config.deployerPrivateKey);
        proxy.airdrop(tokenId, recipients);
        vm.stopBroadcast();

        console.log("Airdrop completed. Token ID:", tokenId);
        console.log("Recipients:", recipients.length);
    }
}
