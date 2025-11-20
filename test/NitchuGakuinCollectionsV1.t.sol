// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NitchuGakuinCollectionsV1} from "../src/NitchuGakuinCollectionsV1.sol";

/**
 * @title 日中学院数字藏品测试合约
 * @dev 测试合约的所有功能
 */
contract NitchuGakuinCollectionsV1Test is Test {
    NitchuGakuinCollectionsV1 public collection;
    address public owner;
    address public admin;
    address public user1;
    address public user2;

    // 测试常量
    string constant COLLECTION_NAME = "Nitchu Gakuin Digital Collection Test";
    string constant COLLECTION_DESCRIPTION = "Nitchu Gakuin Digital Collection Description Test";
    uint256 constant MAX_SUPPLY = 1000;

    // Svg测试数据
    string constant SVG_CHUNK_1 =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1000 600\"><rect width=\"100%\" height=\"100%\" fill=\"none\"/><rect width=\"800\" height=\"50\" x=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"250\" x=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"250\" x=\"850\" fill=\"#317c72\" rx=\"2\"/><rect width=\"1000\" height=\"50\" y=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"150\" height=\"50\" y=\"200\" fill=\"#317c72\" rx=\"2\"/><rect width=\"150\" height=\"50\" ";
    string constant SVG_CHUNK_2 =
        "x=\"850\" y=\"200\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"400\" y=\"150\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"400\" x=\"950\" y=\"150\" fill=\"#317c72\" rx=\"2\"/><rect width=\"280\" height=\"260\" x=\"260\" y=\"252\" fill=\"none\" rx=\"4\"/><rect width=\"50\" height=\"20\" y=\"535\" fill=\"#2b6a64\" rx=\"3\"/><rect width=\"50\" height=\"20\" x=\"950\" y=\"535\" fill=\"#2b6a64\" rx=\"3\"/><text x=\"500\" y=\"135\" fill=\"#fff\" font-family=\"'Hannotate SC', 'Kaishu', 'DFKai-SB', ";
    string constant SVG_CHUNK_3 =
        "'Noto Serif TC', serif\" font-size=\"32\" font-weight=\"500\" letter-spacing=\"32\" text-anchor=\"middle\">ABC</text><text x=\"500\" y=\"400\" fill=\"#ff570f\" font-size=\"50\" letter-spacing=\"16\" text-anchor=\"middle\">";
    string constant SVG_CHUNK_4 = "DEF</text></svg>";

    // 在合约内部，run() 函数仍保留
    function setUp() public {
        run();
    }

    function run() public {
        // 设置测试账户
        owner = makeAddr("owner");
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 部署实现合约
        address implementation = address(new NitchuGakuinCollectionsV1());

        // 部署代理合约
        vm.startPrank(owner);
        address proxyAddr = UnsafeUpgrades.deployUUPSProxy(
            implementation, abi.encodeCall(NitchuGakuinCollectionsV1.initialize, (owner))
        );
        address payable proxy = payable(proxyAddr);

        collection = NitchuGakuinCollectionsV1(proxy);

        // 添加管理员
        collection.addAdmin(admin);
        vm.stopPrank();
    }

    function test_Initialization() public view {
        assertEq(collection.owner(), owner);
        assertTrue(collection.isAdmin(admin));
        assertFalse(collection.isAdmin(user1));
    }

    function test_CreateCollection() public {
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(
            COLLECTION_NAME,
            COLLECTION_DESCRIPTION,
            MAX_SUPPLY,
            false, // 不启用白名单
            true // 立即激活
        );

        // 验证藏品信息
        (
            string memory name,
            string memory description,
            uint256 maxSupply,
            uint256 currentSupply,
            bool isWhitelistEnabled,
            bool isActive,
            uint256 svgChunkCount,
            bool isSvgFinalized
        ) = collection.getCollectionInfo(tokenId);

        assertEq(name, COLLECTION_NAME);
        assertEq(description, COLLECTION_DESCRIPTION);
        assertEq(maxSupply, MAX_SUPPLY);
        assertEq(currentSupply, 0);
        assertEq(isWhitelistEnabled, false);
        assertEq(isActive, true);
        assertEq(svgChunkCount, 0);
        assertEq(isSvgFinalized, false);
    }

    function test_CreateCollection_OnlyAdmin() public {
        // 非管理员应该无法创建藏品
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyAdminOrOwner()"));
        collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
    }

    function test_AddSvgChunks() public {
        // 先创建藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 添加Svg数据块
        vm.prank(admin);
        collection.addSvgChunk(tokenId, 0, bytes(SVG_CHUNK_1));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 1, bytes(SVG_CHUNK_2));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 2, bytes(SVG_CHUNK_3));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 3, bytes(SVG_CHUNK_4));

        // 完成Svg上传
        vm.prank(admin);
        collection.finalizeSvgUpload(tokenId);

        // 验证Svg数据
        string memory svg = collection.getSvgData(tokenId);
        assertEq(svg, string(abi.encodePacked(SVG_CHUNK_1, SVG_CHUNK_2, SVG_CHUNK_3, SVG_CHUNK_4)));

        // 验证藏品信息
        (,,,,,, uint256 svgChunkCount, bool isSvgFinalized) = collection.getCollectionInfo(tokenId);

        assertEq(svgChunkCount, 4);
        assertEq(isSvgFinalized, true);
    }

    function test_ClaimWithoutWhitelist() public {
        // 创建不需要白名单的藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 用户领取
        vm.prank(user1);
        collection.claim(tokenId);

        // 验证领取状态
        assertTrue(collection.hasClaimed(tokenId, user1));
        assertEq(collection.balanceOf(user1, tokenId), 1);
    }

    function test_ClaimWithWhitelist() public {
        // 创建需要白名单的藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, true, true);

        // 添加白名单
        address[] memory whitelist = new address[](1);
        whitelist[0] = user1;

        vm.prank(admin);
        collection.addToWhitelist(tokenId, whitelist);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 白名单用户应该可以领取
        vm.prank(user1);
        collection.claim(tokenId);
        assertTrue(collection.hasClaimed(tokenId, user1));

        // 非白名单用户应该无法领取
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("NotWhitelisted()"));
        collection.claim(tokenId);
    }

    function test_ClaimInactiveCollection() public {
        // 创建未激活的藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, false);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 尝试领取未激活的藏品应该失败
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("CollectionNotActive()"));
        collection.claim(tokenId);
    }

    function test_ClaimAlreadyClaimed() public {
        // 创建藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 第一次领取
        vm.prank(user1);
        collection.claim(tokenId);

        // 第二次领取应该失败
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
        collection.claim(tokenId);
    }

    function test_ClaimMaxSupplyReached() public {
        // 创建供应量为1的藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, 1, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 第一个用户领取
        vm.prank(user1);
        collection.claim(tokenId);

        // 第二个用户应该无法领取
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached()"));
        collection.claim(tokenId);
    }

    function test_UpdateCollection() public {
        // 创建藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 更新藏品状态
        vm.prank(admin);
        collection.updateCollectionStatus(tokenId, true, false);

        // 验证更新后的状态
        (,,,, bool isWhitelistEnabled, bool isActive,,) = collection.getCollectionInfo(tokenId);
        assertEq(isWhitelistEnabled, true);
        assertEq(isActive, false);
    }

    function test_Airdrop() public {
        // 1️⃣ 创建藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 2️⃣ 上传完整 SVG 数据（否则 airdrop 会报 Svg_NotFinalized）
        _setupSvgData(tokenId);

        // 3️⃣ 准备空投地址列表
        address[] memory recipients = new address[](4);
        recipients[0] = user1; // 有效
        recipients[1] = user2; // 有效
        recipients[2] = address(0); // 无效地址（跳过）
        recipients[3] = user1; // 重复领取（跳过）

        // 4️⃣ 执行 airdrop
        vm.prank(admin);
        collection.airdrop(tokenId, recipients);

        // 5️⃣ 验证
        assertEq(collection.balanceOf(user1, tokenId), 1);
        assertEq(collection.balanceOf(user2, tokenId), 1);
        assertTrue(collection.hasClaimed(tokenId, user1));
        assertTrue(collection.hasClaimed(tokenId, user2));

        // 6️⃣ 再次空投相同地址，应计入 “已领取过”
        address[] memory again = new address[](2);
        again[0] = user1;
        again[1] = user2;
        vm.prank(admin);
        collection.airdrop(tokenId, again);
        assertEq(collection.balanceOf(user1, tokenId), 1);
        assertEq(collection.balanceOf(user2, tokenId), 1);
    }

    function test_AdminManagement() public {
        // 所有者可以添加管理员
        vm.prank(owner);
        collection.addAdmin(user1);
        assertTrue(collection.isAdmin(user1));

        // 所有者可以移除管理员
        vm.prank(owner);
        collection.removeAdmin(user1);
        assertFalse(collection.isAdmin(user1));

        // 非所有者不能添加管理员
        vm.prank(user2);
        vm.expectRevert();
        collection.addAdmin(user2);
    }

    function test_URI() public {
        // 创建藏品并设置Svg
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
        _setupSvgData(tokenId);

        // 获取URI
        string memory tokenURI = collection.uri(tokenId);

        // URI应该包含base64编码的JSON和Svg
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(_startsWith(tokenURI, "data:application/json;base64,"));
    }

    function test_Upgrade() public {
        // 创建藏品
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
        _setupSvgData(tokenId);

        console.log("vm.prank owner:", owner);
        console.log("proxy owner:", NitchuGakuinCollectionsV1(payable(address(collection))).owner());

        // 用户领取
        vm.prank(user1);
        collection.claim(tokenId);

        // 保存当前状态
        uint256 balanceBefore = collection.balanceOf(user1, tokenId);
        bool claimedBefore = collection.hasClaimed(tokenId, user1);

        // 新的实现
        NitchuGakuinCollectionsV1 newImpl = new NitchuGakuinCollectionsV1();

        // 明确指定：owner 来执行升级操作
        vm.startPrank(owner);
        NitchuGakuinCollectionsV1(payable(address(collection))).upgradeToAndCall(address(newImpl), "");
        vm.stopPrank();

        // 验证
        assertEq(NitchuGakuinCollectionsV1(payable(address(collection))).UPGRADE_INTERFACE_VERSION(), "5.0.0");

        // 验证状态保持不变
        uint256 balanceAfter = collection.balanceOf(user1, tokenId);
        bool claimedAfter = collection.hasClaimed(tokenId, user1);

        assertEq(balanceAfter, balanceBefore);
        assertEq(claimedAfter, claimedBefore);

        // 验证功能仍然正常
        (,,, uint256 currentSupply,,,,) = collection.getCollectionInfo(tokenId);
        assertEq(currentSupply, 1);
    }

    // 辅助函数：设置完整的Svg数据
    function _setupSvgData(uint256 tokenId) internal {
        vm.prank(admin);
        collection.addSvgChunk(tokenId, 0, bytes(SVG_CHUNK_1));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 1, bytes(SVG_CHUNK_2));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 2, bytes(SVG_CHUNK_3));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 3, bytes(SVG_CHUNK_4));

        vm.prank(admin);
        collection.finalizeSvgUpload(tokenId);
    }

    // 辅助函数：检查字符串是否以指定前缀开头
    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) {
                return false;
            }
        }

        return true;
    }

    function test_Pause_Unpause() public {
        vm.prank(owner);
        collection.pause();
        assertTrue(collection.paused());

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        collection.claim(1);

        vm.prank(owner);
        collection.unpause();
        assertFalse(collection.paused());
    }

    function test_Airdrop_Revert_NotFinalized() public {
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("Svg_NotFinalized()"));
        collection.airdrop(tokenId, recipients);
    }
}
