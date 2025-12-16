# Nitchu Gakuin Digital Collections

[🇬🇧 **English**](README.md) 　[🇨🇳 中文](README.cn.md) 　[🇯🇵 日本語](README.ja.md)

---

The "Nitchu Gakuin Digital Collections" project provides a sustainable, low-cost platform for institutions and alumni to issue, claim, and airdrop digital collectibles.

Built for low gas fees on Optimism (an Ethereum Layer-2), the system implements an upgradeable ERC-1155 contract architecture.

- Supports creating multiple collections
- Each collection can represent fungible or non-fungible quantities (ERC-1155: NFT / SFT)
- Supports on-chain storage of SVG images (no external URLs required)
- Supports whitelist-controlled claims, airdrops, and free claims
- Upgradeable via UUPS proxy pattern

---

### Mainnet (Production) Contract

Proxy Address: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a  
Implementation Address: 0x4753eD9Ddb4eEE055D7103F0754DfA9c2dCC1053 (implementation address may change after upgrades)

### Test Contracts

Test proxy (V1, owner = Account1): 0x37d272B8d4f844c29eB05C5ABC8271E8f22cFeA3  
Test proxy (V1, owner = Account2; Account1 remains an admin): 0x5866e3731E7d77781e9588C3A00c93EF7f5dEe2F

### Recommended Workflow (Foundry CLI)

| Action                                           | Example Command                                                                                                                             |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Run tests                                        | `forge test -vvvv`                                                                                                                          |
| Deploy initial implementation                    | `forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --broadcast --verify --etherscan-api-key <ETHERSCAN_API_KEY> -vvvv` |
| Validate upgrade compatibility                   | `forge script script/Upgrade.s.sol:UpgradeScript --sig "validateUpgrade()" --rpc-url <your_rpc_url> --broadcast -vvvv`                      |
| (Optional) Prepare new implementation deployment | `forge script script/Upgrade.s.sol:UpgradeScript --sig "prepareUpgrade()" --rpc-url ${your_rpc_url} --broadcast -vvvv`                      |
| Execute upgrade on-chain                         | `forge script script/Upgrade.s.sol:UpgradeScript --sig "upgradeTo()" --rpc-url ${your_rpc_url} --broadcast -vvvv`                           |

Before deploying or upgrading, run:

```bash
forge clean && forge build
```

> When testing SVG uploads on mainnet, measure gas for different SVG sizes (block gas limit ~30M). Example measurements (approximate):

| Network      |               Operation | Chunks |        Gas | Approx. Cost                 |
| ------------ | ----------------------: | -----: | ---------: | ---------------------------- |
| Polygon      |                  Deploy |      - |  3,170,857 | 0.746498259310977786 POL     |
| Polygon      |       Create collection |      - |    116,477 | 0.037038327500328612 POL     |
| Polygon      | Upload 3.3 KB (1 chunk) |      1 |  2,510,479 | 2.557224407104099114 POL     |
| Polygon      |  Upload 22 KB (1 chunk) |      1 | 15,649,101 | 1.742997666200924718 POL     |
| Polygon      |                 Upgrade |      - |  2,975,668 | 0.191769677865799832 POL     |
| **Optimism** |                  Deploy |      - |  3,170,857 | **0.000000001854951345 ETH** |
| **Optimism** |       Create collection |      - |    116,453 | **0.000000000095724366 ETH** |
| **Optimism** |  Upload 22 KB (1 chunk) |      1 | 15,785,220 | **0.00000000672450372 ETH**  |
| **Optimism** | Upload 57 KB (2 chunks) |      2 | 20,106,850 | **0.00000107505294895 ETH**  |

## 🧪 Test Example (Local Anvil)

- Network: Anvil (local)
- Proxy: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- V1 implementation: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- Initial owner: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Test PK 0: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
- Test PK 2: `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`

---

### 🔹 Common Queries & Commands

| Action                     | Example Command                                                                                                                                                                                                                                                                                                                        |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Get contract version       | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getVersion() returns(string)" --rpc-url http://127.0.0.1:8545`                                                                                                                                                                                                                  |
| Create collection (direct) | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "createCollection(string,string,uint256,bool,bool)" "Nitchu Gakuin Digital Collection Test" "Nitchu Gakuin Digital Collection Description Test" 100 false true --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| Create collection (script) | `forge script script/CreateCollection.s.sol:CreateCollectionScript --rpc-url anvil --broadcast -vvvv`                                                                                                                                                                                                                                  |
| Get collection info        | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getCollectionInfo(uint256) returns (string,string,uint256,uint256,bool,bool,uint256,bool)" 1 --rpc-url http://127.0.0.1:8545`                                                                                                                                                   |
| Check claim status         | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "hasClaimed(uint256,address)" 1 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC --rpc-url http://127.0.0.1:8545`                                                                                                                                                                      |
| Check balance              | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "balanceOf(address,uint256)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 1 --rpc-url http://127.0.0.1:8545`                                                                                                                                                                       |

---

### 🔹 Claiming & SVG Upload

| Action              | Example Command                                                                                                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Claim NFT           | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "claim(uint256)" 1 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://127.0.0.1:8545`             |
| Claim (script)      | `forge script script/Claim.s.sol:ClaimScript --rpc-url anvil --broadcast -vvvv`                                                                                                                        |
| Airdrop (script)    | `forge script script/Airdrop.s.sol:AirdropScript --rpc-url anvil --broadcast -vvvv`                                                                                                                    |
| Finalize SVG upload | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "finalizeSvgUpload(uint256)" 1 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| Get SVG data        | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getSvgData(uint256) returns(string)" 1 --rpc-url http://127.0.0.1:8545`                                                                         |

---

### 🔹 Permissions & Management

| Action                        | Example Command                                                                                                                                      |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Get contract owner            | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "owner() returns (address)" --rpc-url http://127.0.0.1:8545`                                   |
| Get admin list                | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getAdmins() returns (address[])" --rpc-url http://127.0.0.1:8545`                             |
| Get upgrade interface version | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "UPGRADE_INTERFACE_VERSION() returns (string)" --rpc-url http://127.0.0.1:8545`                |
| Is address admin?             | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "isAdmin(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C9 --rpc-url http://127.0.0.1:8545` |
| Transfer ownership            | `cast send <0xProxyContractAddress> "transferOwnership(address)" 0xNewOwnerAddress --rpc-url <rpc> --private-key <your_private_key>`                 |

---

### 🔹 SVG Uploads

| Action              | Example Command                                                                                                                                                                                                         |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Add SVG chunk       | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "addSvgChunk(uint256,uint256,bytes)" 1 0 ABCDEF --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| Add chunks (script) | `forge script script/AddSvgChucks.s.sol:AddSvgChunksScript --rpc-url anvil --broadcast -vvvv`                                                                                                                           |

---

✅ Notes:

All commands above are runnable on a local Anvil instance for validating the deployment, management, and upgrade behavior of `NitchuGakuinCollections`.

---

### Explorer Verification (source verification)

Verify implementation contract:

```bash
forge verify-contract ImplementationAddress src/NitchuGakuinCollectionsV1.sol:NitchuGakuinCollectionsV1 --chain CHAIN_ID
```

Verify proxy contract (ERC1967 proxy):

```bash
forge verify-contract PROXY_ADDRESS lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy --chain CHAIN_ID
```
