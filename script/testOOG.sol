// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {Script} from "forge-std/Script.sol";
import {OOG} from "../src/oog.sol";

contract TestOOG is Script {
    function run() public {
        OOG instance = new OOG();
        instance.start();
    }
}
