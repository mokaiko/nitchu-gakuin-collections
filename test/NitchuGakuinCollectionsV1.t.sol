// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {UnsafeUpgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {NitchuGakuinCollectionsV1} from "../src/NitchuGakuinCollectionsV1.sol";

/**
 * @title Nitchu Gakuin Collections Test Contract
 * @dev Tests covering core contract functionality
 */
contract NitchuGakuinCollectionsV1Test is Test {
    NitchuGakuinCollectionsV1 public collection;
    address public owner;
    address public admin;
    address public user1;
    address public user2;

    // test constants
    string constant COLLECTION_NAME = "Nitchu Gakuin Digital Collection Test";
    string constant COLLECTION_DESCRIPTION = "Nitchu Gakuin Digital Collection Description Test";
    uint256 constant MAX_SUPPLY = 1000;

    // SVG test data
    string constant SVG_CHUNK_1 =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1000 600\"><rect width=\"100%\" height=\"100%\" fill=\"none\"/><rect width=\"800\" height=\"50\" x=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"250\" x=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"250\" x=\"850\" fill=\"#317c72\" rx=\"2\"/><rect width=\"1000\" height=\"50\" y=\"100\" fill=\"#317c72\" rx=\"2\"/><rect width=\"150\" height=\"50\" y=\"200\" fill=\"#317c72\" rx=\"2\"/><rect width=\"150\" height=\"50\" ";
    string constant SVG_CHUNK_2 =
        "x=\"850\" y=\"200\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"400\" y=\"150\" fill=\"#317c72\" rx=\"2\"/><rect width=\"50\" height=\"400\" x=\"950\" y=\"150\" fill=\"#317c72\" rx=\"2\"/><rect width=\"280\" height=\"260\" x=\"260\" y=\"252\" fill=\"none\" rx=\"4\"/><rect width=\"50\" height=\"20\" y=\"535\" fill=\"#2b6a64\" rx=\"3\"/><rect width=\"50\" height=\"20\" x=\"950\" y=\"535\" fill=\"#2b6a64\" rx=\"3\"/><text x=\"500\" y=\"135\" fill=\"#fff\" font-family=\"'Hannotate SC', 'Kaishu', 'DFKai-SB', ";
    string constant SVG_CHUNK_3 =
        "'Noto Serif TC', serif\" font-size=\"32\" font-weight=\"500\" letter-spacing=\"32\" text-anchor=\"middle\">ABC</text><text x=\"500\" y=\"400\" fill=\"#ff570f\" font-size=\"50\" letter-spacing=\"16\" text-anchor=\"middle\">";
    string constant SVG_CHUNK_4 = "DEF</text></svg>";

    // keep run() for internal test setup
    function setUp() public {
        run();
    }

    function run() public {
        // set up test accounts
        owner = makeAddr("owner");
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // deploy implementation contract
        address implementation = address(new NitchuGakuinCollectionsV1());

        // deploy proxy contract
        vm.startPrank(owner);
        address proxyAddr = UnsafeUpgrades.deployUUPSProxy(
            implementation, abi.encodeCall(NitchuGakuinCollectionsV1.initialize, (owner))
        );
        address payable proxy = payable(proxyAddr);

        collection = NitchuGakuinCollectionsV1(proxy);

        // add admin
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
            false, // whitelist disabled
            true // activate immediately
        );

        // verify collection info
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
        // non-admin should not be able to create a collection
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OnlyAdminOrOwner()"));
        collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
    }

    function test_AddSvgChunks() public {
        // first create a collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // add SVG chunks
        vm.prank(admin);
        collection.addSvgChunk(tokenId, 0, bytes(SVG_CHUNK_1));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 1, bytes(SVG_CHUNK_2));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 2, bytes(SVG_CHUNK_3));

        vm.prank(admin);
        collection.addSvgChunk(tokenId, 3, bytes(SVG_CHUNK_4));

        // finalize SVG upload
        vm.prank(admin);
        collection.finalizeSvgUpload(tokenId);

        // verify SVG data
        string memory svg = collection.getSvgData(tokenId);
        assertEq(svg, string(abi.encodePacked(SVG_CHUNK_1, SVG_CHUNK_2, SVG_CHUNK_3, SVG_CHUNK_4)));

        // verify collection info
        (,,,,,, uint256 svgChunkCount, bool isSvgFinalized) = collection.getCollectionInfo(tokenId);

        assertEq(svgChunkCount, 4);
        assertEq(isSvgFinalized, true);
    }

    function test_ClaimWithoutWhitelist() public {
        // create a collection without whitelist
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // user claims
        vm.prank(user1);
        collection.claim(tokenId);

        // 验证领取状态
        assertTrue(collection.hasClaimed(tokenId, user1));
        assertEq(collection.balanceOf(user1, tokenId), 1);
    }

    function test_ClaimWithWhitelist() public {
        // create a collection that requires whitelist
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, true, true);

        // add whitelist
        address[] memory whitelist = new address[](1);
        whitelist[0] = user1;

        vm.prank(admin);
        collection.addToWhitelist(tokenId, whitelist);

        // add complete SVG data
        _setupSvgData(tokenId);

        // whitelisted user should be able to claim
        vm.prank(user1);
        collection.claim(tokenId);
        assertTrue(collection.hasClaimed(tokenId, user1));

        // non-whitelisted user should not be able to claim
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("NotWhitelisted()"));
        collection.claim(tokenId);
    }

    function test_ClaimInactiveCollection() public {
        // create an inactive collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, false);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // attempt to claim inactive collection should fail
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("CollectionNotActive()"));
        collection.claim(tokenId);
    }

    function test_ClaimAlreadyClaimed() public {
        // create a collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 第一次领取
        vm.prank(user1);
        collection.claim(tokenId);

        // second claim should fail
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
        collection.claim(tokenId);
    }

    function test_ClaimMaxSupplyReached() public {
        // create a collection with max supply 1
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, 1, false, true);

        // 添加完整的Svg数据
        _setupSvgData(tokenId);

        // 第一个用户领取
        vm.prank(user1);
        collection.claim(tokenId);

        // second user should not be able to claim
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("MaxSupplyReached()"));
        collection.claim(tokenId);
    }

    function test_UpdateCollection() public {
        // create a collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 更新藏品状态
        vm.prank(admin);
        collection.updateCollectionStatus(tokenId, true, false);

        // verify updated status
        (,,,, bool isWhitelistEnabled, bool isActive,,) = collection.getCollectionInfo(tokenId);
        assertEq(isWhitelistEnabled, true);
        assertEq(isActive, false);
    }

    function test_Airdrop() public {
        // 1) create collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);

        // 2) upload complete SVG data (airdrop requires SVG finalized)
        _setupSvgData(tokenId);

        // 3) prepare recipient list
        address[] memory recipients = new address[](4);
        recipients[0] = user1; // 有效
        recipients[1] = user2; // 有效
        recipients[2] = address(0); // 无效地址（跳过）
        recipients[3] = user1; // 重复领取（跳过）

        // 4) execute airdrop
        vm.prank(admin);
        collection.airdrop(tokenId, recipients);

        // 5) verify results
        assertEq(collection.balanceOf(user1, tokenId), 1);
        assertEq(collection.balanceOf(user2, tokenId), 1);
        assertTrue(collection.hasClaimed(tokenId, user1));
        assertTrue(collection.hasClaimed(tokenId, user2));

        // 6) repeat airdrop to same addresses; already-claimed addresses should be skipped
        address[] memory again = new address[](2);
        again[0] = user1;
        again[1] = user2;
        vm.prank(admin);
        collection.airdrop(tokenId, again);
        assertEq(collection.balanceOf(user1, tokenId), 1);
        assertEq(collection.balanceOf(user2, tokenId), 1);
    }

    function test_AdminManagement() public {
        // owner can add admin
        vm.prank(owner);
        collection.addAdmin(user1);
        assertTrue(collection.isAdmin(user1));

        // owner can remove admin
        vm.prank(owner);
        collection.removeAdmin(user1);
        assertFalse(collection.isAdmin(user1));

        // non-owner cannot add admin
        vm.prank(user2);
        vm.expectRevert();
        collection.addAdmin(user2);
    }

    function test_URI() public {
        // create collection and set SVG
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
        _setupSvgData(tokenId);

        // 获取URI
        string memory tokenURI = collection.uri(tokenId);

        // URI should contain base64-encoded JSON and SVG
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(_startsWith(tokenURI, "data:application/json;base64,"));
    }

    function test_Upgrade() public {
        // create collection
        vm.prank(admin);
        uint256 tokenId = collection.createCollection(COLLECTION_NAME, COLLECTION_DESCRIPTION, MAX_SUPPLY, false, true);
        _setupSvgData(tokenId);

        console.log("vm.prank owner:", owner);
        console.log("proxy owner:", NitchuGakuinCollectionsV1(payable(address(collection))).owner());

        // user claims
        vm.prank(user1);
        collection.claim(tokenId);

        // save current state
        uint256 balanceBefore = collection.balanceOf(user1, tokenId);
        bool claimedBefore = collection.hasClaimed(tokenId, user1);

        // 新的实现
        NitchuGakuinCollectionsV1 newImpl = new NitchuGakuinCollectionsV1();

        // explicitly perform upgrade as owner
        vm.startPrank(owner);
        NitchuGakuinCollectionsV1(payable(address(collection))).upgradeToAndCall(address(newImpl), "");
        vm.stopPrank();

        // verify
        assertEq(NitchuGakuinCollectionsV1(payable(address(collection))).UPGRADE_INTERFACE_VERSION(), "5.0.0");

        // verify state is preserved
        uint256 balanceAfter = collection.balanceOf(user1, tokenId);
        bool claimedAfter = collection.hasClaimed(tokenId, user1);

        assertEq(balanceAfter, balanceBefore);
        assertEq(claimedAfter, claimedBefore);

        // 验证功能仍然正常
        (,,, uint256 currentSupply,,,,) = collection.getCollectionInfo(tokenId);
        assertEq(currentSupply, 1);
    }

    // helper: set up full SVG data
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

    // helper: check if string starts with prefix
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
