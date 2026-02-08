// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/**
 * @title AddLiquidity
 * @notice Add liquidity to the Native ETH / EWT pool with SurgeHook
 */
contract AddLiquidity is Script {
    
    // ============= ADDRESSES (checksummed) =============
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POSITION_MANAGER = 0xf969Aee60879C54bAAed9F3eD26147Db216Fd664;
    address constant SURGE_HOOK = 0xbB9620C96A409d321552Cff9F8c1397b879440c0;
    address constant EWT_TOKEN = 0x312CF8c8F041df4444A19e0525452aE362F3B043;
    
    // ============= LIQUIDITY PARAMS =============
    uint256 constant ETH_AMOUNT = 0.01 ether;
    uint256 constant EWT_AMOUNT = 0.01 ether;
    
    // Full range liquidity (aligned to tick spacing 60)
    int24 constant TICK_LOWER = -887220;
    int24 constant TICK_UPPER = 887220;
    int24 constant TICK_SPACING = 60;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Adding Liquidity to ETH/EWT Pool");
        console.log("Deployer:", deployer);
        
        // Check balances
        uint256 ethBalance = deployer.balance;
        uint256 ewtBalance = IERC20(EWT_TOKEN).balanceOf(deployer);
        
        console.log("ETH Balance:", ethBalance);
        console.log("EWT Balance:", ewtBalance);
        
        require(ethBalance >= ETH_AMOUNT + 0.01 ether, "Not enough ETH");
        require(ewtBalance >= EWT_AMOUNT, "Not enough EWT");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // STEP 1: Approve EWT
        console.log("Approving EWT...");
        IERC20(EWT_TOKEN).approve(POSITION_MANAGER, type(uint256).max);
        
        // STEP 2: Create Pool Key
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(EWT_TOKEN),
            fee: 0x800000,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(SURGE_HOOK)
        });
        
        // STEP 3: Encode Actions
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR),
            uint8(Actions.SWEEP)
        );
        
        // STEP 4: Encode Parameters
        bytes[] memory params = new bytes[](3);
        
        uint128 liquidityAmount = uint128(ETH_AMOUNT / 2);
        
        // MINT_POSITION params
        params[0] = abi.encode(
            poolKey,
            TICK_LOWER,
            TICK_UPPER,
            liquidityAmount,
            uint128(ETH_AMOUNT * 2),
            uint128(EWT_AMOUNT * 2),
            deployer,
            ""
        );
        
        // SETTLE_PAIR params
        params[1] = abi.encode(
            Currency.wrap(address(0)),
            Currency.wrap(EWT_TOKEN)
        );
        
        // SWEEP params
        params[2] = abi.encode(
            Currency.wrap(address(0)),
            deployer
        );
        
        console.log("Minting position with liquidity:", liquidityAmount);
        
        // STEP 5: Call PositionManager
        bytes memory hookData = abi.encode(actions, params);
        
        IPositionManager(POSITION_MANAGER).modifyLiquidities{value: ETH_AMOUNT}(
            hookData,
            block.timestamp + 60
        );
        
        vm.stopBroadcast();
        
        console.log("LIQUIDITY ADDED SUCCESSFULLY!");
    }
}
