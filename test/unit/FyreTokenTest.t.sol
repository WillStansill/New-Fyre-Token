// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {FyreToken} from "../../src/FyreToken.sol";

contract UnitFyreToken is Test {
    FyreToken _fyreToken;
    address _owner = address(1);
    address _user = address(2);
    address _treasury = address(3);
    uint256 _initialSupply = 1000 ether;

    function setUp() public {
        fyreToken = new FyreToken(owner, initialSupply, treasury);
    }

    function testInitialSupply() public {
        assertEq(fyreToken.balanceOf(owner), initialSupply);
    }

    function testMintUncollateralized() public {
        uint256 mintAmount = 500 ether;
        fyreToken.mintUncollateralized(user, mintAmount);
        assertEq(fyreToken.balanceOf(user), mintAmount);
    }

    function testBurnUncollateralized() public {
        uint256 burnAmount = 300 ether;
        fyreToken.mintUncollateralized(user, burnAmount);
        fyreToken.burnUncollateralized(user, burnAmount);
        assertEq(fyreToken.balanceOf(user), 0);
    }

    function testSendToVerusTreasury() public {
        uint256 amount = 200 ether;
        fyreToken.transfer(user, amount);
        vm.prank(user);
        fyreToken.sendToVerusTreasury(amount);
        assertEq(fyreToken.balanceOf(treasury), amount);
        assertEq(fyreToken.collateralizedBalance(user), amount);
    }

    function testIsCollateralized() public {
        uint256 amount = 150 ether;
        fyreToken.transfer(user, amount);
        vm.prank(user);
        fyreToken.sendToVerusTreasury(amount);
        assertTrue(fyreToken.isCollateralized(user));
    }
}
