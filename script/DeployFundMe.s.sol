// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    FundMe fundMe;

    function run() external returns (FundMe fundMe) {
        // The next line runs before the vm.startBroadcast() is called
        // This will not be deployed because the `real` signed txs are happening
        // between the start and stop Broadcast lines.
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // just a test address, not a real PriceFeed
        // new FundMe(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

        // the address is sepolia deployment of the AggregatorV3 contract from the video
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // use ethUsdPriceFeed
        fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
    }
}
