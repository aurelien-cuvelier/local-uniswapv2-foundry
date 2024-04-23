// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract UniswapDeployer is Script, StdCheats {
    function run() public {
        deployCodeTo(
            "UniswapV2Factory.sol:UniswapV2Factory",
            abi.encode(address(5555555555555555555555)),
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        );

        deployCodeTo(
            "WETH.sol:WETH",
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );

        deployCodeTo(
            "UniswapV2Router02.sol:UniswapV2Router02",
            abi.encode(
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            ),
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }
}
