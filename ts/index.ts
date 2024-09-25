import axios from "axios";
import { JsonRpcProvider, Wallet } from "ethers";
import util from "util";
import { utils, Web3 } from "web3";

import MevShareClient, { BundleParams } from "@flashbots/mev-share-client";
import { SimBundleOptions } from "@flashbots/mev-share-client/build/api/interfaces";

//const RPC = "https://mainnet.infura.io/v3/0b0c190b3042481d8c58e84e1a8da82a";
const RPC = "https://rpc.mevblocker.io/fullprivacy";

const pkFunder =
  "0x820b585de4e5db91c3739398af79545f2359ef8801193bdecdf5980def016068";
const pkScammer =
  "0xee9cec01ff03c0adea731d7c5a84f7b412bfd062b9ff35126520b3eb3d5ff258";

main();

export async function main() {
  const providerEthers = new JsonRpcProvider(RPC);
  const provider = new Web3(RPC);

  const authSigner = new Wallet(pkFunder, providerEthers);

  const mevShareClient = MevShareClient.useEthereumMainnet(authSigner);

  //console.log(await provider.eth.getBlockNumber());

  const accFunder = provider.eth.accounts.privateKeyToAccount(pkFunder);
  const accScammer = provider.eth.accounts.privateKeyToAccount(pkScammer);

  const nonceFunder = await provider.eth.getTransactionCount(accFunder.address);
  const nonceScammer = await provider.eth.getTransactionCount(
    accScammer.address
  );

  //   console.log(
  //     provider.eth.abi.encodeFunctionSignature("transfer(address,uint256)") +
  //       provider.eth.abi
  //         .encodeParameters(
  //           ["address", "uint256"],
  //           [accFunder.address, "2117674759"]
  //         )
  //         .replace("0x", "")
  //   );

  const currentBlock = await provider.eth.getBlock("latest");
  const targetBlock = 1 + (await providerEthers.getBlockNumber());

  const baseFee = currentBlock.baseFeePerGas;
  console.log(`baseFee: ${Web3.utils.fromWei(String(baseFee), "gwei")}`);
  const maxPriorityFeePerGas = Web3.utils.toWei("50", "gwei");
  if (!baseFee) {
    console.error(`No base fee`);
    return;
  }

  if (Number(Web3.utils.fromWei(String(baseFee), "gwei")) > 30) {
    console.error(
      `High base fee: ${Web3.utils.fromWei(String(baseFee), "gwei")}`
    );

    return;
  }
  const maxFeePerGas = String(baseFee + BigInt(maxPriorityFeePerGas));

  const tx1 = await accFunder.signTransaction({
    to: accScammer.address,
    gasLimit: 21000,
    gasPrice: maxPriorityFeePerGas,
    data: "0x",
    value: Web3.utils.toWei("0.008", "ether"),
    //maxPriorityFeePerGas: maxPriorityFeePerGas,
    //maxFeePerGas: maxFeePerGas,
    nonce: nonceFunder,
  });

  const tx2 = await accScammer.signTransaction({
    to: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    gasLimit: 50000,
    gasPrice: maxPriorityFeePerGas,
    //maxPriorityFeePerGas: maxPriorityFeePerGas,
    //maxFeePerGas: maxFeePerGas,
    data:
      provider.eth.abi.encodeFunctionSignature("transfer(address,uint256)") +
      provider.eth.abi
        .encodeParameters(
          ["address", "uint256"],
          [accFunder.address, "2117674759"]
        )
        .replace("0x", ""),
    nonce: nonceScammer,
  });

  console.log(
    await provider.eth.call({
      to: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      gasLimit: 100000,
      gasPrice: maxPriorityFeePerGas,
      //maxPriorityFeePerGas: maxPriorityFeePerGas,
      //maxFeePerGas: maxFeePerGas,
      //   data:
      //     provider.eth.abi.encodeFunctionSignature("balanceOf(address)") +
      //     provider.eth.abi
      //       .encodeParameter("address", accScammer.address)
      //       .replace("0x", ""),
      data:
        provider.eth.abi.encodeFunctionSignature("transfer(address,uint256)") +
        provider.eth.abi
          .encodeParameters(
            ["address", "uint256"],
            [accFunder.address, "2117674759"]
          )
          .replace("0x", ""),
      nonce: nonceScammer,
    })
  );

  const bundleParams: BundleParams = {
    inclusion: {
      block: targetBlock,
      maxBlock: targetBlock + 10, // allow bundle to land in next 5 blocks
    },
    body: [
      { tx: tx1.rawTransaction, canRevert: false },
      { tx: tx2.rawTransaction, canRevert: false },
    ],
    privacy: {
      hints: {
        txHash: true,
        calldata: true,
        logs: true,
        functionSelector: true,
        contractAddress: true,
      },
    },
  };

  const simBundleOptions: SimBundleOptions = {
    parentBlock: targetBlock - 1,
    blockNumber: targetBlock,
    /*
    Set any of these (block header) fields to override their respective values in the simulation context: 
    */
    // coinbase: string,
    // timestamp: number,
    // gasLimit: number,
    // baseFee: bigint,
    // timeout: number,
  };

  //   console.log(
  //     util.inspect(await mevshare.simulateBundle(bundleParams), false, null, true)
  //   );

  //return;

  //console.log(await mevshare.sendTransaction(tx1.rawTransaction));

  const body = {
    jsonrpc: "2.0",
    id: 1,
    method: "eth_sendBundle",
    params: [
      {
        txs: [tx1.rawTransaction, tx2.rawTransaction], // Array[String], A list of signed transactions to execute in an atomic bundle
        blockNumber: "0x" + BigInt(targetBlock).toString(16), // String, a hex encoded block number for which this bundle is valid on
        minTimestamp: Number(currentBlock.timestamp), // (Optional) Number, the minimum timestamp for which this bundle is valid, in seconds since the unix epoch
        maxTimestamp: Number(currentBlock.timestamp + 120n), // (Optional) Number, the maximum timestamp for which this bundle is valid, in seconds since the unix epoch
        //   revertingTxHashes, // (Optional) Array[String], A list of tx hashes that are allowed to revert
        //   replacementUuid, // (Optional) String, UUID that can be used to cancel/replace this bundle
        //   builders, // (Optional) Array[String], A list of [registered](https://github.com/flashbots/dowg/blob/main/builder-registrations.json) block builder names to share the bundle with
      },
    ],
  };

  if (true) {
    //using libs

    const bundleParam = {
      inclusion: {
        block: targetBlock,
        // target several blocks with `maxBlock`
        maxBlock: targetBlock + 5,
      },
      body: [
        { tx: tx1.rawTransaction, canRevert: false },
        { tx: tx2.rawTransaction, canRevert: false },
      ],
      privacy: {
        hints: {
          txHash: true,
          calldata: true,
          logs: true,
          functionSelector: true,
          contractAddress: true,
        },
      },
    };

    const simResult = await mevShareClient.simulateBundle(bundleParam);
    console.log(simResult);
    if (!simResult.success) {
      console.log("Simulation did not succeed!");
      return;
    }

    return;
    //console.log(util.inspect(simResult));
    const signature =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(utils.keccak256(JSON.stringify(body))));
    const { data: sentBundle } = await axios.post(
      "https://relay.flashbots.net",
      JSON.stringify(body),
      {
        headers: {
          "X-Flashbots-Signature": signature,
        },
      }
    );
    console.log(sentBundle);
    // const bundleResult = await mevShareClient.sendBundle(bundleParam);
    // console.log(bundleResult);

    const bodyStats = {
      jsonrpc: "2.0",
      id: 1,
      method: "flashbots_getBundleStatsV2",
      params: [
        {
          bundleHash: sentBundle.result.bundleHash, // String, returned by the flashbots api when calling eth_sendBundle
          blockNumber: body.params[0].blockNumber, // String, the block number the bundle was targeting (hex encoded)
        },
      ],
    };

    const signatureCheck =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(
        utils.keccak256(JSON.stringify(bodyStats))
      ));
    for (let i = 0; i < 10; i++) {
      console.log("=====================================");
      const { data } = await axios.post(
        "https://relay.flashbots.net",
        bodyStats,
        {
          headers: {
            "X-Flashbots-Signature": signatureCheck,
          },
        }
      );
      console.log(util.inspect(data, false, null, true /* enable colors */));
      provider.eth
        .getTransactionCount(accFunder.address)
        .then((nonce) => console.log(`Nonce: ${nonce}`))
        .catch();
      await new Promise((r) => setTimeout(r, 12000));
    }
  }

  if (false) {
    //mev simulate bundle

    const simBody = {
      jsonrpc: "2.0",
      id: 1,
      method: "mev_simBundle",
      params: [
        {
          /* MevSimBundleParams */ version: "beta-1",
          inclusion: {
            block: "0x" + currentBlock.number.toString(16), // hex-encoded number
            maxBlock: "0x" + (currentBlock.number + 20n).toString(16), // hex-encoded number
          },
          body: bundleParams,
          //   privacy: {
          //     hints: Array<
          //       | "calldata"
          //       | "contract_address"
          //       | "logs"
          //       | "function_selector"
          //       | "hash"
          //       | "tx_hash"
          //     >,
          //     builders: Array<string>,
          //   },
          //   metadata: {
          //     originId: string,
          //   },
          //   simOptions: {
          //     /* SimBundleOptions */
          //     parentBlock: number | string, // Block used for simulation state. Defaults to latest block.
          //     blockNumber: number, // default = parentBlock.number + 1
          //     coinbase: string, // default = parentBlock.coinbase
          //     timestamp: number, // default = parentBlock.timestamp + 12
          //     gasLimit: number, // default = parentBlock.gasLimit
          //     baseFee: bigint, // default = parentBlock.baseFeePerGas
          //     timeout: number, // default = 5 (defined in seconds)
          //   },
        },
      ],
    };

    const signature =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(utils.keccak256(JSON.stringify(simBody))));
    console.log(`Signature: ${signature}`);
    console.log(
      await axios.post("https://relay.flashbots.net", JSON.stringify(simBody), {
        headers: {
          "X-Flashbots-Signature": signature,
        },
      })
    );
  }

  if (false) {
    //call bundle

    const callBody = {
      jsonrpc: "2.0",
      id: 1,
      method: "eth_callBundle",
      params: [
        {
          txs: [tx1.rawTransaction, tx2.rawTransaction], // Array[String], A list of signed transactions to execute in an atomic bundle
          blockNumber: "0x" + BigInt(targetBlock + 5).toString(16), // String, a hex encoded block number for which this bundle is valid on
          stateBlockNumber: "latest",
        },
      ],
    };

    const signature =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(utils.keccak256(JSON.stringify(callBody))));
    console.log(`Signature: ${signature}`);
    const { data } = await axios.post(
      "https://relay.flashbots.net",
      JSON.stringify(callBody),
      {
        headers: {
          "X-Flashbots-Signature": signature,
        },
      }
    );
    console.log(util.inspect(data, false, null, true));
  }

  if (false) {
    //send bundle
    const signature =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(utils.keccak256(JSON.stringify(body))));
    console.log(`Signature: ${signature}`);
    console.log(
      await axios.post("https://relay.flashbots.net", JSON.stringify(body), {
        headers: {
          "X-Flashbots-Signature": signature,
        },
      })
    );
    console.log(
      "Target block: " +
        "0x" +
        BigInt(targetBlock + 10).toString(16) +
        ` (${BigInt(targetBlock + 10).toString(10)})`
    );
  }

  //   console.log(
  //     util.inspect(await mevshare.simulateBundle(bundleParams), false, null, true)
  //   );

  if (false) {
    //get bundle stats

    const bodyStats = {
      jsonrpc: "2.0",
      id: 1,
      method: "flashbots_getBundleStatsV2",
      params: [
        {
          bundleHash:
            "0x1944e6d965ce0a4eead6a5eb63cca9f5e89fd70365afdfe3081e19c6d6ae28e8", // String, returned by the flashbots api when calling eth_sendBundle
          blockNumber: "0x13cce48", // String, the block number the bundle was targeting (hex encoded)
        },
      ],
    };

    const signatureCheck =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(
        utils.keccak256(JSON.stringify(bodyStats))
      ));

    const { data } = await axios.post(
      "https://relay.flashbots.net",
      bodyStats,
      {
        headers: {
          "X-Flashbots-Signature": signatureCheck,
        },
      }
    );
    console.log(util.inspect(data, false, null, true /* enable colors */));
  }

  if (false) {
    //get user stats

    const bodyStats = {
      jsonrpc: "2.0",
      id: 1,
      method: "flashbots_getUserStatsV2",
      params: [
        {
          blockNumber: "0x" + currentBlock.number.toString(16), // String, the block number the bundle was targeting (hex encoded)
        },
      ],
    };

    const signatureCheck =
      authSigner.address +
      ":" +
      (await authSigner.signMessage(
        utils.keccak256(JSON.stringify(bodyStats))
      ));

    const { data } = await axios.post(
      "https://relay.flashbots.net",
      bodyStats,
      {
        headers: {
          "X-Flashbots-Signature": signatureCheck,
        },
      }
    );
    console.log(util.inspect(data, false, null, true /* enable colors */));
  }

  //console.log(await mevshare.sendBundle(bundleParams));
  //console.log(await mevshare.simulateBundle(bundleParams));

  //console.log(backrunResult);

  //   provider.eth.sendSignedTransaction(tx1.rawTransaction);

  //   const { data } = await axios.get();

  //   for (const tx of [tx1, tx2]) {
  //     provider.eth
  //       .sendSignedTransaction(tx.rawTransaction)
  //       .then((receipt) => {
  //         console.log(receipt.status);
  //       })
  //       .catch((e) => {
  //         console.error(e);
  //       });
  //   }

  //   const tx1 = await accFunder.signTransaction({
  //     to: accScammer.address,
  //     gasLimit: 21000,
  //     gasPrice: Web3.utils.toWei("35", "gwei"),
  //     data: "0x",
  //     value: "0.0002",
  //     nonce: nonceFunder,
  //   });

  //   const tx2 = await accScammer.signTransaction({
  //     to: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  //     gasLimit: 50000,
  //     gasPrice: Web3.utils.toWei("34.9", "gwei"),
  //     data:
  //       provider.eth.abi.encodeFunctionSignature("transfer(address,uint256)") +
  //       provider.eth.abi
  //         .encodeParameters(
  //           ["address", "uint256"],
  //           [accFunder.address, "2117674759"]
  //         )
  //         .replace("0x", ""),
  //     nonce: nonceScammer,
  //   });
}
