// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SurgeHook} from "../src/SurgeHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

/**
 * @title DeploySurgeHook
 * @notice Deploys SurgeHook to Unichain Sepolia with correct hook address
 * 
 * Usage:
 * forge script script/DeploySurgeHook.s.sol:DeploySurgeHook \
 *   --rpc-url $UNICHAIN_SEPOLIA_RPC \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast \
 *   -vvvv
 */
contract DeploySurgeHook is Script {
    // Unichain Sepolia PoolManager address (from app .env.local)
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    
    function run() external {
        // Define which hooks we're enabling
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG
        );
        
        console.log("Mining salt for hook address with flags:", flags);
        
        // Mine a salt that will give us the correct hook address
        bytes memory creationCode = type(SurgeHook).creationCode;
        bytes memory constructorArgs = abi.encode(POOL_MANAGER);
        
        // CREATE2_FACTORY is inherited from Script base contract
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            flags,
            creationCode,
            constructorArgs
        );
        
        console.log("Found salt:", uint256(salt));
        console.log("Hook will deploy to:", hookAddress);
        
        // Deploy
        vm.startBroadcast();
        
        SurgeHook hook = new SurgeHook{salt: salt}(IPoolManager(POOL_MANAGER));
        
        console.log("SurgeHook deployed to:", address(hook));
        
        // Verify address matches
        require(address(hook) == hookAddress, "Hook address mismatch!");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("SurgeHook:", address(hook));
        console.log("PoolManager:", POOL_MANAGER);
        console.log("");
        console.log("Next steps:");
        console.log("1. Initialize pool with hook address");
        console.log("2. Add liquidity to the pool");
        console.log("3. Update swap API with new pool key");
    }
}
