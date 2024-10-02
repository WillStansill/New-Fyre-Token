// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {FyreToken} from "./FyreToken.sol";
import {AggregatorV3Interface} from "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract VerusTreasury is Ownable {
    // Custom Errors
    error VerusTreasury__AmountMustBeGreaterThanZero();
    error VerusTreasury__UnsupportedToken();
    error VerusTreasury__TransferFailed();
    error VerusTreasury__InsufficientCollateral();
    error VerusTreasury__InsufficientFyreInTreasury();

    FyreToken public fyreToken;
    address public btcReserve; // BTC reserve address for collateralization

    uint256 private constant _PRECISION = 1e18;

    mapping(address => uint256) public fyreMinted;
    mapping(address => mapping(address => uint256)) public collateralDeposited; // User => Token => Amount
    mapping(address => address) public priceFeeds; // Token => Price Feed address

    address[] public collateralTokens; // List of accepted collateral tokens

    constructor(address _fyreToken, address _btcReserve) {
        fyreToken = FyreToken(_fyreToken);
        btcReserve = _btcReserve;
    }

    // Set price feed for a collateral token
    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = feed;
        collateralTokens.push(token);
    }

    // Deposit collateral and mint FYRE tokens
    function depositCollateralAndMintFyre(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountFyreToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintFyre(amountFyreToMint);
    }

    // Deposit collateral
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) public {
        if (amountCollateral == 0) {
            revert VerusTreasury__AmountMustBeGreaterThanZero();
        }
        if (priceFeeds[tokenCollateralAddress] == address(0)) {
            revert VerusTreasury__UnsupportedToken();
        }

        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );
        if (!success) {
            revert VerusTreasury__TransferFailed();
        }
        collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;
    }

    // Mint FYRE tokens based on collateral deposited
    function mintFyre(uint256 amountFyreToMint) public {
        // FYRE tokens minted 1:1 based on collateral, so no health factor needed.
        fyreMinted[msg.sender] += amountFyreToMint;
        fyreToken.mint(msg.sender, amountFyreToMint);
    }

    // Redeem collateral by burning FYRE
    function redeemCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) public {
        if (
            collateralDeposited[msg.sender][tokenCollateralAddress] <
            amountCollateral
        ) {
            revert VerusTreasury__InsufficientCollateral();
        }

        collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] -= amountCollateral;
        bool success = IERC20(tokenCollateralAddress).transfer(
            msg.sender,
            amountCollateral
        );
        if (!success) {
            revert VerusTreasury__TransferFailed();
        }
    }

    // Collateralize FYRE with BTC (for the hackathon, your wallet simulates BTC collateralization)
    function collateralizeFYRE(
        address account,
        uint256 amount
    ) external onlyOwner {
        if (fyreToken.balanceOf(address(this)) < amount) {
            revert VerusTreasury__InsufficientFyreInTreasury();
        }

        // Simulate assigning collateralization to the account
        fyreMinted[account] += amount;

        // For now, we'll assume BTC collateralization happens off-chain or manually
    }

    // Mint collateralized FYRE after BTC collateralization
    function mintCollateralizedFYRE(
        address account,
        uint256 amount
    ) external onlyOwner {
        fyreToken.receiveFromVerusTreasury(account, amount); // Add to collateralized balance in FYRE token
    }

    // Get account information: total FYRE minted and total collateral in USD
    function _getAccountInformation(
        address user
    )
        internal
        view
        returns (uint256 totalFyreMinted, uint256 collateralValueInUsd)
    {
        totalFyreMinted = fyreMinted[user];
        collateralValueInUsd = _getCollateralValue(user);
    }

    // Get the total value of user's collateral in USD
    function _getCollateralValue(
        address user
    ) internal view returns (uint256 totalCollateralValueInUsd) {
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            address token = collateralTokens[i];
            uint256 amount = collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
    }

    // Get the USD value of a specific token and amount
    function _getUsdValue(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeeds[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * amount) / _PRECISION;
    }
}
