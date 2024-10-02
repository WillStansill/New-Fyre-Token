// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {FyreToken} from "../../src/FyreToken.sol";
import {IVerusTreasury} from "../../src/VerusTreasury.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract FuzzFyreToken is Test {
    FyreToken _fyreToken;
    address _owner = address(1);
    address _user = address(2);
    address _treasury = address(3);
    uint256 _initialSupply = 1000 ether;

    function setUp() public {
        fyreToken = new FyreToken(owner, initialSupply, treasury);
    }

    // Fuzz test for minting uncollateralized tokens
    function testFuzzMintUncollateralized(address to, uint256 amount) public {
        vm.assume(amount > 0);
        fyreToken.mintUncollateralized(to, amount);
        assertEq(fyreToken.balanceOf(to), amount);
    }

    // Fuzz test for burning uncollateralized tokens
    function testFuzzBurnUncollateralized(address from, uint256 amount) public {
        vm.assume(amount > 0);
        fyreToken.mintUncollateralized(from, amount);
        fyreToken.burnUncollateralized(from, amount);
        assertEq(fyreToken.balanceOf(from), 0);
    }

    // Fuzz test for transfer to VerusTreasury
    function testFuzzSendToVerusTreasury(uint256 amount) public {
        vm.assume(amount > 0 && amount <= initialSupply);
        fyreToken.transfer(user, amount);
        vm.prank(user);
        fyreToken.sendToVerusTreasury(amount);
        assertEq(fyreToken.collateralizedBalance(user), amount);
        assertEq(fyreToken.balanceOf(treasury), amount);
    }
}
