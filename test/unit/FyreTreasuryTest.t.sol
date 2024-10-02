// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "lib/forge-std/src/Test.sol";
import {VerusTreasury} from "../../src/VerusTreasury.sol";
import {FyreToken} from "../../src/FyreToken.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";

contract UnitVerusTreasury is Test {
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

    function testSetPriceFeed() public {
        address priceFeed = address(4);
        treasury.setPriceFeed(address(mockCollateral), priceFeed);
        assertEq(treasury.priceFeeds(address(mockCollateral)), priceFeed);
    }

    function testDepositCollateralAndMintFyre() public {
        uint256 collateralAmount = 100 ether;
        uint256 fyreAmount = 50 ether;

        mockCollateral.mint(user, collateralAmount);
        vm.prank(user);
        mockCollateral.approve(address(treasury), collateralAmount);

        vm.prank(user);
        treasury.depositCollateralAndMintFyre(
            address(mockCollateral),
            collateralAmount,
            fyreAmount
        );

        assertEq(fyreToken.balanceOf(user), fyreAmount);
        assertEq(
            treasury.collateralDeposited(user, address(mockCollateral)),
            collateralAmount
        );
    }

    function testRedeemCollateral() public {
        uint256 collateralAmount = 100 ether;

        mockCollateral.mint(user, collateralAmount);
        vm.prank(user);
        mockCollateral.approve(address(treasury), collateralAmount);

        vm.prank(user);
        treasury.depositCollateral(address(mockCollateral), collateralAmount);

        vm.prank(user);
        treasury.redeemCollateral(address(mockCollateral), collateralAmount);

        assertEq(mockCollateral.balanceOf(user), collateralAmount);
        assertEq(
            treasury.collateralDeposited(user, address(mockCollateral)),
            0
        );
    }

    function testCollateralizeFYRE() public {
        uint256 amount = 200 ether;

        fyreToken.mintUncollateralized(treasury, amount);
        vm.prank(owner);
        treasury.collateralizeFYRE(user, amount);

        assertEq(treasury.fyreMinted(user), amount);
    }
}
