# Local Uniswap V2 using Foundry

This repo allows you to deploy a working version of UniswapV2 onto your local foundry environement. This allows you to save a lot of time if you want to test anything related to UniswapV2 with foundry, without having to fork anything from mainnet (or anywhere else).

This repo is the result of a youtube video i made, if you want to see the whole process feel free to check it out:
https://www.youtube.com/watch?v=izz4xYKNZQM

The lib directory contains an un-linked submodule (v2-periphery), this is necessary as re-compiling the UniswapV2Pair smart-contract on your own machine, will prevent you to properly use the Router (see video for more details).

### To fork the repo and the dependencies:

```sh
git clone https://github.com/aurelien-cuvelier/local-uniswap-v2-foundry-old.git --recursive
```

or

```sh
git clone https://github.com/aurelien-cuvelier/local-uniswap-v2-foundry-old.git
cd local-uniswap-v2-foundry/
git submodule update --init
```

### To compile the smart contracts of the project:

```sh
forge build
```

### To test that you properly installed everything:

```sh
forge test --initial-balance 10000000000000000000
```

You should get 4 passing tests our of 4.

The Uniswap V2 Router, WETH & Uniswap V2 Factory are deployed on the same addresses as on mainnet.
