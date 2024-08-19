// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

contract AntiBot {
    address owner;
    uint8 public blockDelay = 125;
    mapping(address => uint) public addressToBuyBlock;
    mapping(address => bool) public whitelist;

    constructor(address[] memory _whitelisted) {
        owner = msg.sender;

        for (uint i = 0; i < _whitelisted.length; i++) {
            whitelist[_whitelisted[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "No.");
        _;
    }

    function changeBlockDelay4568468541621584(
        uint8 newBlockDelay
    ) external onlyOwner {
        blockDelay = newBlockDelay;
    }

    function changeWhitelist46848621332154866486(
        address addr,
        bool status
    ) external onlyOwner {
        whitelist[addr] = status;
    }

    function checkAllowance(address buyer) external view returns (uint) {
        if (whitelist[buyer]) {
            return type(uint).max;
        }

        if (addressToBuyBlock[buyer] == 0) {
            return 0;
        }

        return
            (block.number - addressToBuyBlock[buyer]) > blockDelay
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
