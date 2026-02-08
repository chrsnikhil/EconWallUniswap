// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

/**
 * @title InitializeNativeETHPool
 * @notice Initialize a Native ETH / EWT pool with aggressive SurgeHook
 * 
 * NATIVE ETH: Uses address(0) for ETH - no WETH wrapping needed!
 * 
 * Usage:
 * forge script script/InitializeNativeETHPool.s.sol:InitializeNativeETHPool \
 *   --rpc-url https://sepolia.unichain.org \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast -vvvv
 */
contract InitializeNativeETHPool is Script {
    
    // ============= UNICHAIN SEPOLIA ADDRESSES =============
    // PoolManager (verified working)
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    
    // Aggressive SurgeHook (just deployed with correct PoolManager)
    address constant SURGE_HOOK = 0xbB9620C96A409d321552Cff9F8c1397b879440c0;
    
    // ============= POOL CONFIGURATION =============
    // Starting price: 1:1 ETH/EWT (let market adjust)
    uint160 constant STARTING_PRICE = 79228162514264337593543950336;  // 2^96 = 1:1
    int24 constant TICK_SPACING = 60;
    
    function run() public {
        // Get EWT token from env or use default
        address ewtToken = vm.envOr(
            "EWT_TOKEN", 
            address(0x312CF8c8F041df4444A19e0525452aE362F3B043)
        );
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("========================================");
        console.log("Initializing Native ETH / EWT Pool");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("PoolManager:", POOL_MANAGER);
        console.log("SurgeHook (Aggressive):", SURGE_HOOK);
        console.log("EWT Token:", ewtToken);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ===== CREATE POOL KEY =====
        // Native ETH = address(0), no WETH needed!
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),    // Native ETH
            currency1: Currency.wrap(ewtToken),       // EWT Token
            fee: 0x800000,                            // Dynamic fee flag
            tickSpacing: TICK_SPACING,
            hooks: IHooks(SURGE_HOOK)
        });
        
        console.log("PoolKey created:");
        console.log("  currency0: address(0) [Native ETH]");
        console.log("  currency1:", ewtToken);
        console.log("  fee: 0x800000 [Dynamic]");
        console.log("  tickSpacing:", uint24(TICK_SPACING));
        console.log("  hooks:", SURGE_HOOK);
        
        // ===== INITIALIZE POOL =====
        IPoolManager poolManager = IPoolManager(POOL_MANAGER);
        
        int24 tick = poolManager.initialize(poolKey, STARTING_PRICE);
        
        console.log("");
        console.log("========================================");
        console.log("POOL INITIALIZED SUCCESSFULLY!");
        console.log("========================================");
        console.log("Initial tick:", tick);
        console.log("");
        console.log("Next steps:");
        console.log("1. Add liquidity via PositionManager");
        console.log("2. Update swap API with new poolKey");
        console.log("3. Test swaps!");
        
        vm.stopBroadcast();
    }
}
