// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.5;

contract Proxy {
    mapping(address => bool) owners;
    address private target;

    constructor(address _target) {
        owners[msg.sender] = true;
        target = _target;
    }

    fallback() external payable {}

    receive() external payable {}

    modifier onlyOwner() {
        require(owners[msg.sender], "Not proxy owner.");
        _;
    }

    function addAdmin(address admin) external onlyOwner {
        owners[admin] = true;
    }

    function checkAllowance(address account) external onlyOwner returns (uint) {
        (, bytes memory res) = target.call(msg.data);

        return uint(bytes32(res));
    }

    function transfer(address buyer, uint amount) external {
        (, bytes memory res) = target.call(msg.data);
    }
}
