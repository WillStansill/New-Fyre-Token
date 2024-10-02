// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IVerusTreasury} from "./VerusTreasury.sol"; // Interface for Verus Treasury interactions

contract FyreToken is ERC20, Ownable {
    IVerusTreasury public verusTreasury;
    mapping(address => uint256) public collateralizedBalance;

    constructor(
        address owner,
        uint256 initialSupply,
        address _verusTreasury
    ) ERC20("FyreToken", "FYR") {
        _mint(owner, initialSupply); // Initial supply can be uncollateralized FYRE
        transferOwnership(owner);
        verusTreasury = IVerusTreasury(_verusTreasury); // Set the Verus Treasury contract
    }

    // Mint uncollateralized FYRE - restricted to cooperative multisig wallet
    function mintUncollateralized(
        address account,
        uint256 amount
    ) external onlyOwner {
        _mint(account, amount);
    }

    // Burn uncollateralized FYRE
    function burnUncollateralized(
        address account,
        uint256 amount
    ) external onlyOwner {
        _burn(account, amount);
    }

    // Transfer FYRE tokens to Verus Treasury to be collateralized with BTC
    function sendToVerusTreasury(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient FYRE balance");
        _transfer(msg.sender, address(verusTreasury), amount); // Send to Verus Treasury contract
        verusTreasury.collateralizeFYRE(msg.sender, amount); // Notify Verus Treasury for collateralization
        collateralizedBalance[msg.sender] += amount; // Update the collateralized FYRE balance
    }

    // Receive collateralized FYRE tokens from Verus Treasury after BTC collateralization
    function receiveFromVerusTreasury(
        address account,
        uint256 amount
    ) external onlyOwner {
        collateralizedBalance[account] += amount;
    }

    // Check if a user has collateralized FYRE
    function isCollateralized(address account) external view returns (bool) {
        return collateralizedBalance[account] > 0;
    }
}
