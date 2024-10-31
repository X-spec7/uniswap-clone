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
}
