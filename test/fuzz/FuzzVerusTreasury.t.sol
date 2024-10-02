// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {VerusTreasury} from "../../src/VerusTreasury.sol";
import {FyreToken} from "../../src/FyreToken.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {AggregatorV3Interface} from "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FuzzVerusTreasury is Test {
    VerusTreasury _treasury;
    FyreToken _fyreToken;
    ERC20Mock _mockCollateral;
    address _owner = address(1);
    address _user = address(2);
    address _btcReserve = address(3);

    function setUp() public {
        fyreToken = new FyreToken(owner, 1000 ether, address(this));
        mockCollateral = new ERC20Mock();
        treasury = new VerusTreasury(address(fyreToken), btcReserve);
        treasury.setPriceFeed(address(mockCollateral), address(this));
    }

    // Fuzz test for deposit collateral and mint FYRE
    function testFuzzDepositCollateralAndMintFyre(
        uint256 amountCollateral,
        uint256 amountFyre
    ) public {
        vm.assume(amountCollateral > 0 && amountFyre > 0);
        mockCollateral.mint(user, amountCollateral);
        vm.prank(user);
        mockCollateral.approve(address(treasury), amountCollateral);
        vm.prank(user);
        treasury.depositCollateralAndMintFyre(
            address(mockCollateral),
            amountCollateral,
            amountFyre
        );
        assertEq(fyreToken.balanceOf(user), amountFyre);
    }

    // Fuzz test for redeeming collateral
    function testFuzzRedeemCollateral(uint256 amountCollateral) public {
        vm.assume(amountCollateral > 0);
        mockCollateral.mint(user, amountCollateral);
        vm.prank(user);
        mockCollateral.approve(address(treasury), amountCollateral);
        vm.prank(user);
        treasury.depositCollateral(address(mockCollateral), amountCollateral);
        vm.prank(user);
        treasury.redeemCollateral(address(mockCollateral), amountCollateral);
        assertEq(mockCollateral.balanceOf(user), amountCollateral);
    }
}
