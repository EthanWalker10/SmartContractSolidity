// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

// we can access `vm.startBroadcast` and `vm.stopBroadcast` from the forge-std/Script.sol
// we use it to deploy our mocks
contract HelperConfig is Script{
    // If we are on a local Anvil, we deploy the mocks
    // Else, grab the existing address from the live network

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    NetworkConfig public activeNetworkConfig;
    MockV3Aggregator mockPriceFeed;

    // if we need to store multiple addresses or even more blockchain-specific information.
    // a struct is better than a variable
    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor(){
        // block is just like msg, which is inborn. I guess.
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }

    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){

        // to check if we already deployed the `mockPriceFeed` before deploying it once more.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        // 8:decimals, 2000:initialAnswer
        // get PriceFeed contract, but what's the meaning of the 2 params?
        mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;

    }
}