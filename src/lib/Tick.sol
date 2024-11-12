// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './TickMath.sol';

// Q: max liquidity calculated evenly?
library Tick {
  function tickSpacingToMaxLiquidityPerTick(
      int24 tickSpacing
  ) internal pure returns (uint128) {
    int24 mminTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
    int24 mmaxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
    uint24 numTicks = uint24((mmaxTick - mminTick) / tickSpacing) + 1;
    return type(uint128).max / numTicks;
  }

  struct Info {
    // the total position liquidity that references this tick
    uint128 liquidityGross;
    // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
    int128 liquidityNet;
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside0X128;
    uint256 feeGrowthOutside1X128;

    bool initialized;
  }

  function update(
    mapping(int24 => Tick.Info) storage self,
    int24 tick,
    int24 tickCurrent,
    int128 liquidityDelta,
    uint256 feeGrowthGlobal0X128,
    uint256 feeGrowthGlobal1X128,
    bool upper,
    uint128 maxLiquidity
  ) internal returns (bool flipped) {
    Info memory info = self[tick];

    uint128 liquidityGrossBefore = info.liquidityGross;
    uint128 liquidityGrossAfter = liquidityDelta < 0
      ? liquidityGrossBefore - uint128(-liquidityDelta)
      : liquidityGrossBefore + uint128(liquidityDelta);
    
    require(liquidityGrossAfter <= maxLiquidity, "LiquidityGrossAfter > max");

    flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

    if (liquidityGrossBefore ==0) {
      info.initialized = true;
    }

    info.liquidityGross = liquidityGrossAfter;

    info.liquidityNet = upper
      ? info.liquidityNet - liquidityDelta
      : info.liquidityNet + liquidityDelta;
  }
}