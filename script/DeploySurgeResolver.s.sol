// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SurgeResolver} from "../src/SurgeResolver.sol";

contract DeploySurgeResolver is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory gatewayUrl = vm.envString("GATEWAY_URL");
        
        // Get signer address from private key (same key for now)
        address signer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying SurgeResolver to Sepolia...");
        console.log("Gateway URL:", gatewayUrl);
        console.log("Signer Address:", signer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SurgeResolver
        SurgeResolver resolver = new SurgeResolver(gatewayUrl, signer);
        
        console.log("\n=== DEPLOYMENT SUCCESSFUL ===");
        console.log("SurgeResolver deployed at:", address(resolver));
        console.log("\nNext steps:");
        console.log("1. Go to https://app.ens.domains");
        console.log("2. Find your ENS name");
        console.log("3. Edit -> Set Custom Resolver");
        console.log("4. Enter address:", address(resolver));
        
        vm.stopBroadcast();
    }
}
