// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./lib/Tick.sol";
import "./lib/Position.sol";
import "./lib/SafeCast.sol";
import "./interfaces/IERC20.sol";
import "./lib/TickMath.sol";

function checkTicks(int24 tickLower, int24 tickUpper) pure {
  require(tickLower < tickUpper, "tickUpper lower than tickLower");
  require(tickLower >= TickMath.MIN_TICK, "tickLower lower than MIN_TICK");
  require(tickUpper <= TickMath.MAX_TICK, "tickUpper greater than MAX_TICK");
}

contract CLAMM {
  using SafeCast for int256;
  using Tick for mapping(int24 => Tick.Info);
  using Position for mapping(bytes32 => Position.Info);
  using Position for Position.Info;

  address public immutable token0;
  address public immutable token1;
  uint24 public immutable fee;
  int24 public immutable tickSpacing;

  uint128 public immutable maxLiquidityPerTick;

  struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // whether the pool is locked
    bool unlocked;
  }

  Slot0 public slot0;
  mapping(int24 => Tick.Info) public ticks;
  mapping(bytes32 => Position.Info) public positions;

  modifier lock() {
    require(slot0.unlocked, "locked");
    slot0.unlocked = false;
    _;
    slot0.unlocked = true;
  }

  constructor(
    address _token0,
    address _token1,
    uint24 _fee,
    int24 _tickSpacing
  ) {
    token0 = _token0;
    token1 = _token1;
    fee = _fee;
    tickSpacing = _tickSpacing;

    maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
      _tickSpacing
    );
  }

  function initialize(uint160 sqrtPriceX96) external {
    require(slot0.sqrtPriceX96 == 0, "already initialized");

    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

    slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick, unlocked: true});
  }

  function _updatePosition(
    address owner,
    int24 tickLower,
    int24 tickUpper,
    int128 liquidityDelta,
    int24 tick
  ) private returns (Position.Info storage position) {
    position = positions.get(owner, tickLower, tickUpper);

    // TODO: fees
    uint256 _feeGrowthGlobal0X128 = 0;
    uint256 _feeGrowthGlobal1X128 = 0;

    position.update(liquidityDelta, _feeGrowthGlobal0X128, _feeGrowthGlobal1X128);
  }

  struct ModifyPositionParams {
    // the address that owns the position
    address owner;
    // the lower and upper tick of the position
    int24 tickLower;
    int24 tickUpper;
    // any change in liquidity
    int128 liquidityDelta;
  }

  function _modifyPosition(ModifyPositionParams memory params)
    private returns (Position.Info storage position, int256 amount0, int256 amount1) {
      checkTicks(params.tickLower, params.tickUpper);

      // loading slot to memory to save gas
      Slot0 memory _slot0 = slot0;

      position = _updatePosition(
        params.owner,
        params.tickUpper,
        params.tickLower,
        params.liquidityDelta,
        _slot0.tick
      );

      return (positions[bytes32(0)], 0, 0);
  }

  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external lock returns (uint256 amount0, uint256 amount1) {
    require(amount > 0, "zero amount");

    (, int256 amount0Int, int256 amount1Int) = 
      _modifyPosition(
        ModifyPositionParams({
          owner: recipient,
          tickLower: tickLower,
          tickUpper: tickUpper,
          liquidityDelta: int256(uint256(amount)).toInt128()
        })
      );

    amount0 = uint256(amount0Int);
    amount1 = uint256(amount1Int);

    if (amount0 > 0) {
      IERC20(token0).transferFrom(msg.sender, address(this), amount0);
    }
    if (amount1 > 0) {
      IERC20(token1).transferFrom(msg.sender, address(this), amount1);
    }
  }
}
