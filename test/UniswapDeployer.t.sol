// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {Test} from "forge-std/Test.sol";
import {UniswapDeployer} from "../script/UniswapDeployer.s.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import {Token} from "../src/TokenTest.sol";

contract UniswapTests is Test {
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    WETH deployedWeth =
        WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function setUp() public {
        UniswapDeployer deployer = new UniswapDeployer();
        deployer.run();
    }

    function test_uniswapFactory() public view {
        assert(factory.feeToSetter() != address(0));
    }

    function test_wrappedEther() public view {
        assert(abi.encode(deployedWeth.name()).length > 0);
    }

    function test_deployedRouter() public view {
        assert(router.WETH() != address(0));
    }

    function test_addLiqToken() public {
        Token token = new Token();

        token.approve(address(router), type(uint).max);

        IUniswapV2Router01(router).addLiquidityETH{value: 10 ether}(
            address(token),
            token.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 1000
        );
    }
}
