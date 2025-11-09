# 日中学院 NFT 项目

[🇨🇳 中文](README.md) [🇯🇵 日本語](README.ja.md)

### 正式合约地址

Proxy Address: 0x9d291c7a50A3bF0980E732890177FD4e0998E13a  
Implementation Address: 0x4753eD9Ddb4eEE055D7103F0754DfA9c2dCC1053 (升级合约后会改变)

### 测试合约地址

测试用代理合约：0x37d272B8d4f844c29eB05C5ABC8271E8f22cFeA3 (V1, owner 属于 Account1)  
测试用代理合约：0x5866e3731E7d77781e9588C3A00c93EF7f5dEe2F (V1, owner 属于 Account2, 但 Account1 仍是管理员)

### 使用顺序（Foundry CLI 命令）

| 操作                       | 命令示例                                                                                                                                    |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| **测试脚本执行全部函数**   | `forge test -vvvv`                                                                                                                          |
| **部署初版**               | `forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --broadcast --verify --etherscan-api-key <ETHERSCAN_API_KEY> -vvvv` |
| **验证兼容性**             | `forge script script/Upgrade.s.sol:UpgradeScript --sig "validateUpgrade()" --rpc-url <your_rpc_url> --broadcast -vvvv`                      |
| **预部署新实现（可跳过）** | `forge script script/Upgrade.s.sol:UpgradeScript --sig "prepareUpgrade()" --rpc-url ${your_rpc_url} --broadcast -vvvv`                      |
| **正式升级**               | `forge script script/Upgrade.s.sol:UpgradeScript --sig "upgradeTo()" --rpc-url ${your_rpc_url} --broadcast -vvvv`                           |
| `                          |

部署或升级前先执行

`forge clean && forge build `

在真实主网实际测试不同大小、格式的 SVG，所消耗的 Gas 费 (区块链限制 3000 万上限)
| 区块链网络 | 操作 | Chunks | 消耗 Gas(确定的) | 价值(会根据网络情况改变) |
|------|------|---------|-----------|------------|
| Polygon | 部署 | - | 3,170,857 | 0.746498259310977786 POL |
| Polygon | 创建藏品 | - | 116,477 | 0.037038327500328612 POL |
| Polygon | 上传 3.3 KB | 1 | 2,510,479 | 2.557224407104099114 POL |
| Polygon | 上传 22 KB | 1 | 15,649,101 | 1.742997666200924718 POL |
| Polygon | 升级 | - | 2,975,668 | 0.191769677865799832 POL |
| **Optimism** | 部署 | - | 3,170,857 | **0.000000001854951345 ETH** |
| **Optimism** | 创建数字藏品 | - | 116,453 | **0.000000000095724366 ETH** |
| **Optimism** | 上传 22 KB | 1 | 15,785,220 | **0.00000000672450372 ETH** |
| **Optimism** | 上传 57 KB | 2 | 20,106,850 | **0.00000107505294895 ETH** |

## 🧪 测试用例演示

**网络：** Anvil（本地测试链）  
**代理地址：** `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`  
**V1 实现地址：** `0x5FbDB2315678afecb367f032d93F642f64180aa3`  
**初始拥有者：** `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`  
**测试 PK 0：** `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`  
**测试 PK 2：** `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`

---

### 🔹 基础查询与操作

| 操作说明             | 命令                                                                                                                                                                                                                                                                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **获取合约版本号**   | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getVersion() returns(string)" --rpc-url http://127.0.0.1:8545`                                                                                                                                                                                                                  |
| **创建新藏品**       | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "createCollection(string,string,uint256,bool,bool)" "Nitchu Gakuin Digital Collection Test" "Nitchu Gakuin Digital Collection Description Test" 100 false true --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| **创建新藏品(脚本)** | `forge script script/CreateCollection.s.sol:CreateCollectionScript --rpc-url anvil --broadcast -vvvv`                                                                                                                                                                                                                                  |
| **获取藏品信息**     | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getCollectionInfo(uint256) returns (string,string,uint256,uint256,bool,bool,uint256,bool)" 1 --rpc-url http://127.0.0.1:8545`                                                                                                                                                   |
| **是否已领取过**     | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "hasClaimed(uint256,address)" 1 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC --rpc-url http://127.0.0.1:8545`                                                                                                                                                                      |
| **查看 NFT 数量**    | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "balanceOf(address,uint256)" 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 1 --rpc-url http://127.0.0.1:8545`                                                                                                                                                                       |

---

### 🔹 NFT 领取与上传

| 操作说明             | 命令                                                                                                                                                                                                   |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **领取 NFT**         | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "claim(uint256)" 1 --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a --rpc-url http://127.0.0.1:8545`             |
| **领取 NFT（脚本）** | `forge script script/Claim.s.sol:ClaimScript --rpc-url anvil --broadcast -vvvv`                                                                                                                        |
| **空投 NFT（脚本）** | `forge script script/Airdrop.s.sol:AirdropScript --rpc-url anvil --broadcast -vvvv`                                                                                                                    |
| **完成 SVG 上传**    | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "finalizeSvgUpload(uint256)" 1 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| **获取 SVG 数据**    | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getSvgData(uint256) returns(string)" 1 --rpc-url http://127.0.0.1:8545`                                                                         |

---

### 🔹 权限与管理相关

| 操作说明             | 命令                                                                                                                                                 |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **查看合约拥有者**   | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "owner() returns (address)" --rpc-url http://127.0.0.1:8545`                                   |
| **查看管理员列表**   | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getAdmins() returns (address[])" --rpc-url http://127.0.0.1:8545`                             |
| **查看升级接口版本** | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "UPGRADE_INTERFACE_VERSION() returns (string)" --rpc-url http://127.0.0.1:8545`                |
| **检查是否为管理员** | `cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "isAdmin(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C9 --rpc-url http://127.0.0.1:8545` |
| **转移 Owner**       | `cast send <0xProxyContractAddress> "transferOwnership(address)" 0xNewOwnerAddress --rpc-url <rpc> --private-key <your_private_key>`                 |

---

### 🔹 SVG 数据上传

| 操作说明                        | 命令                                                                                                                                                                                                                    |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **添加 SVG Chunk**              | `cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "addSvgChunk(uint256,uint256,bytes)" 1 0 ABCDEF --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545` |
| **批量添加 SVG Chunks（脚本）** | `forge script script/AddSvgChucks.s.sol:AddSvgChunksScript --rpc-url anvil --broadcast -vvvv`                                                                                                                           |

---

✅ **说明：**

以上命令全部可在本地 Anvil 网络执行，用于验证 `NitchuGakuinCollections` 的部署、管理与升级逻辑是否正常工作。

---

**区块链浏览器实现合约验证**

`forge verify-contract ImplementationAddress  src/NitchuGakuinCollectionsV1.sol:NitchuGakuinCollectionsV1 --chain CHAIN_ID`

---

**区块链浏览器代理合约验证**

`forge verify-contract PROXY_ADDRESS lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy --chain CHAIN_ID`
