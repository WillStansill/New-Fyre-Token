// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {FyreToken} from "../src/FyreToken.sol";
import {VerusTreasury} from "../src/VerusTreasury.sol";
import {console} from "lib/forge-std/src/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployContracts is Script {
    HelperConfig _helperConfig;

    function run() external {
        // Fetch config and addresses from HelperConfig
        _helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = _helperConfig
            .activeNetworkConfig;

        // Use values from config for deployment
        address owner = config.weth; // Example usage of the config variable
        address btcReserve = config.wbtc;

        // Deploy FyreToken
        uint256 initialSupply = 1000 ether;
        vm.startBroadcast();
        FyreToken fyreToken = new FyreToken(owner, initialSupply);
        console.log("Deployed FyreToken at:", address(fyreToken));

        // Deploy VerusTreasury with the deployed FyreToken address
        VerusTreasury verusTreasury = new VerusTreasury(
            address(fyreToken),
            btcReserve
        );
        console.log("Deployed VerusTreasury at:", address(verusTreasury));

        vm.stopBroadcast();
    }
}
