// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    string constant contractURI = "https://ipfs.io/ipfs/QmYyM3e2pTWXbhoo1wChPCaK1f5ZoXLuAvJ4Y9YkeyZ1E1";
    string constant tokenURI = "https://ipfs.io/ipfs/bafybeihjjkwdrxxjnuwevlqtqmh3iegcadc32sio4wmo7bv2gbf34qs34a/";

    Token token;

    address minter = vm.addr(100);

    event URISet(string tokenURI); // TODO: поправить и добавить событие для контракта

    function setUp() external {
        token = new Token(contractURI, tokenURI);

        // set minter role
        token.grantRole(token.MINTER_ROLE(), minter);
    }

    // region - Deploy contract -

    function test_deploy() external {

        vm.expectEmit(true, true, false, true);
        emit URISet(tokenURI);

        token = new Token(contractURI, tokenURI);

        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    // endregion

    // region - Mint -

    function test_mint() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;

        vm.prank(minter);
        token.mint(to, id, quantity);

        assertEq(token.balanceOf(to, id), quantity);
        assertFalse(token.isTokenLocked(id));
    }

    function test_mint_revertIfNotMinter() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;
        address notMinter = vm.addr(2);

        vm.expectRevert(_getAccessControlError(notMinter, token.MINTER_ROLE()));

        vm.prank(notMinter);
        token.mint(to, id, quantity);
    }

    function test_mint_revertIfPause() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;

        token.pause();

        vm.expectRevert("Pausable: paused");

        vm.prank(minter);
        token.mint(to, id, quantity);
    }

    // endregion

    // region - Burn -

    function _beforeEach_burn(address _to, uint256 _id, uint256 _quantity) private {
        vm.prank(minter);
        token.mint(_to, _id, _quantity);
    }

    function test_burn() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;

        _beforeEach_burn(to, id, quantity);

        vm.prank(to);
        token.burn(id, quantity);

        assertEq(token.balanceOf(to, id), 0);
        assertFalse(token.isTokenLocked(id));
    }

    function test_burn_revertIfInsufficientAmount() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;

        _beforeEach_burn(to, id, quantity);

        vm.expectRevert("ERC1155: burn amount exceeds balance");

        token.burn(id, quantity);
    }

    function test_burn_revertIfPause() external {
        uint256 id = 1;
        address to = vm.addr(1);
        uint256 quantity = 1;

        _beforeEach_burn(to, id, quantity);

        token.pause();

        vm.expectRevert("Pausable: paused");

        token.burn(id, quantity);
    }

    function test_burn_ifTokenLocked() external {
        uint256 id = 1;
        address mintTo = vm.addr(1);
        address transferTo = vm.addr(1);
        uint256 quantity = 1;

        _beforeEach_burn(mintTo, id, quantity);

        vm.prank(mintTo);
        token.safeTransferFrom(mintTo, transferTo, id, quantity, "");

        vm.prank(transferTo);
        token.burn(id, quantity);

        assertEq(token.balanceOf(transferTo, id), 0);
        assertFalse(token.isTokenLocked(id));
    }

    // endregion

    // region - Transfer -

    function _beforeEach_safeTransferFrom(address _to, uint256 _id, uint256 _quantity) private {
        vm.prank(minter);
        token.mint(_to, _id, _quantity);
    }

    function test_safeTransferFrom() external {
        uint256 id = 1;
        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);
        uint256 quantity = 1;

        _beforeEach_safeTransferFrom(mintTo, id, quantity);

        vm.prank(mintTo);
        token.safeTransferFrom(mintTo, transferTo, id, quantity, "");

        assertEq(token.balanceOf(transferTo, id), quantity);
        assertTrue(token.isTokenLocked(id));
    }

    function test_safeTransferFrom_ifApproved() external {
        uint256 id = 1;
        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);
        uint256 quantity = 1;

        _beforeEach_safeTransferFrom(mintTo, id, quantity);

        vm.prank(mintTo);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(mintTo, transferTo, id, quantity, "");

        assertEq(token.balanceOf(transferTo, id), quantity);
    }

    function test_safeTransferFrom_revertIfCallernotOwner() external {
        uint256 id = 1;
        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);
        uint256 quantity = 1;

        _beforeEach_safeTransferFrom(mintTo, id, quantity);

        vm.expectRevert("ERC1155: caller is not token owner or approved");

        token.safeTransferFrom(mintTo, transferTo, id, quantity, "");
    }

    function test_safeTransferFrom_revertIfPause() external {
        uint256 id = 1;
        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);
        uint256 quantity = 1;

        _beforeEach_safeTransferFrom(mintTo, id, quantity);

        token.pause();

        vm.expectRevert("Pausable: paused");

        token.safeTransferFrom(mintTo, transferTo, id, quantity, "");
    }

    // endregion

    // region - Batch transfer -

    function _beforeEach_safeBatchTransferFrom(address _to, uint256 _id, uint256 _quantity) private {
        vm.prank(minter);
        token.mint(_to, _id, _quantity);
    }

    function test_safeBatchTransferFrom() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory quantities = new uint256[](2);
        quantities[0] = 1;
        quantities[1] = 1;

        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);

        _beforeEach_safeBatchTransferFrom(mintTo, ids[0], quantities[0]);
        _beforeEach_safeBatchTransferFrom(mintTo, ids[1], quantities[1]);

        vm.prank(mintTo);
        token.safeBatchTransferFrom(mintTo, transferTo, ids, quantities, "");

        assertEq(token.balanceOf(transferTo, ids[0]), quantities[0]);
        assertEq(token.balanceOf(transferTo, ids[1]), quantities[1]);
        assertTrue(token.isTokenLocked(ids[0]));
        assertTrue(token.isTokenLocked(ids[1]));
    }

    function test_safeBatchTransferFrom_ifApproved() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory quantities = new uint256[](2);
        quantities[0] = 1;
        quantities[1] = 1;

        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);

        _beforeEach_safeBatchTransferFrom(mintTo, ids[0], quantities[0]);
        _beforeEach_safeBatchTransferFrom(mintTo, ids[1], quantities[1]);

        vm.prank(mintTo);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(mintTo, transferTo, ids, quantities, "");

        assertEq(token.balanceOf(transferTo, ids[0]), quantities[0]);
        assertEq(token.balanceOf(transferTo, ids[1]), quantities[1]);
    }

    function test_safeBatchTransferFrom_revertIfCallernotOwner() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory quantities = new uint256[](2);
        quantities[0] = 1;
        quantities[1] = 1;

        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);

        _beforeEach_safeBatchTransferFrom(mintTo, ids[0], quantities[0]);
        _beforeEach_safeBatchTransferFrom(mintTo, ids[1], quantities[1]);

        vm.expectRevert("ERC1155: caller is not token owner or approved");

        token.safeBatchTransferFrom(mintTo, transferTo, ids, quantities, "");
    }

    function test_safeBatchTransferFrom_revertIfPause() external {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory quantities = new uint256[](2);
        quantities[0] = 1;
        quantities[1] = 1;

        address mintTo = vm.addr(1);
        address transferTo = vm.addr(2);

        _beforeEach_safeBatchTransferFrom(mintTo, ids[0], quantities[0]);
        _beforeEach_safeBatchTransferFrom(mintTo, ids[1], quantities[1]);

        token.pause();

        vm.expectRevert("Pausable: paused");

        vm.prank(mintTo);
        token.safeBatchTransferFrom(mintTo, transferTo, ids, quantities, "");
    }

    // endregion

    // region - Set URI - // TODO: переименовать в setTokenURI

    function test_setURI() external {
        string memory newURI = "https://testURI";

        token.setTokenURI(newURI);

        assertEq(token.uri(1), newURI);
    }

    function test_setURI_revertIfNotAdmin() external {
        string memory newURI = "https://testURI";
        address notAdmin = vm.addr(1);

        vm.expectRevert(_getAccessControlError(notAdmin, token.DEFAULT_ADMIN_ROLE()));

        vm.prank(notAdmin);
        token.setTokenURI(newURI);
    }

    // endregion

    // region - Pausable -

    function test_pause() external {
        token.pause();

        assertEq(token.paused(), true);
    }

    function test_unpause() external {
        token.pause();
        assertEq(token.paused(), true);

        token.unpause();
        assertEq(token.paused(), false);
    }

    function test_pause_revertIfNotAdmin() external {
        address notAdmin = vm.addr(1);

        vm.expectRevert(_getAccessControlError(notAdmin, token.DEFAULT_ADMIN_ROLE()));
        vm.prank(notAdmin);

        token.pause();
    }

    function test_unpause_revertIfNotAdmin() external {
        address notAdmin = vm.addr(1);

        token.pause();
        assertEq(token.paused(), true);

        vm.expectRevert(_getAccessControlError(notAdmin, token.DEFAULT_ADMIN_ROLE()));
        vm.prank(notAdmin);

        token.pause();
    }

    // endregion

    // region - Service functions -

    function _getAccessControlError(address account, bytes32 role) private pure returns (bytes memory) {
        return abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(account),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
        );
    }

    // endregion
}
