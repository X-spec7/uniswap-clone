// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./FullMath.sol";
import "./SqrtPriceMath.sol";

library SwapMath {
  function computeSwapStep(
    uint160 sqrtRatioCurrentX96,
    uint160 sqrtRatioTargetX96,
    uint128 liquidity,
    int256 amountRemaining,
    // 1 bit = 1/100 * 1% = 1/1e4
    // 1e6 = 100%, 1/100 of a bip
    uint24 feePips
  ) internal pure returns (
    uint160 sqrtRatioNextX96,
    uint256 amountIn,
    uint256 amountOut,
    uint256 feeAmount
  ) {
    // token 1 | token 0
    // current tick
    //   <--- 0 for 1
    //        1 for 0 --->
    bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioCurrentX96;
    bool exactIn = amountRemaining >= 0;

    if (exactIn) {
      // Calculate max amount in, round up amount in
      amountIn = zeroForOne
        ? SqrtPriceMath.getAmount0Delta(
          sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true
        )
        : sqrtPriceMath.getAmount1Delta(
          sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true
        )
      // Calculate next sqrt ratio
    } else {

    }
    // Calculate max amount in or out and next sqrt ratio
    // Calculate amount in and out between sqrt current and next
    // Cap the output amount to not exceed the remaining output amount
    // Calculate fee on amount in
  }
}
