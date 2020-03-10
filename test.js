const { TezosToolkit } = require("@taquito/taquito");
const fs = require("fs");
const assert = require("assert");
const BigNumber = require("bignumber.js");
const network = "https://api.tez.ie/rpc/babylonnet";
let contractAddress;

const loadAddress = readPath => {
  let { address } = JSON.parse(fs.readFileSync(readPath).toString());
  contractAddress = address;
};

const deploy = async (writePath = "AtomicSwapContract.json") => {
  const { Tezos1 } = await getAccounts();
  const operation = await Tezos1.contract.originate({
    code: JSON.parse(fs.readFileSync("./AtomicSwap.json").toString()),
    storage: {
      swaps: {},
      swapStates: {}
    },
    balance: 0
  });
  await operation.confirmation();
  const contract = await operation.contract();

  const detail = {
    address: contract.address
  };
  fs.writeFileSync(writePath, JSON.stringify(detail));
  contractAddress = contract.address;
};

const getFullStorage = async address => {
  const { Tezos1 } = await getAccounts();
  const contract = await Tezos1.contract.at(address);
  return await contract.storage();
};

const createTezosFromFaucet = async path => {
  const { email, password, mnemonic, secret } = JSON.parse(
    fs.readFileSync(path).toString()
  );
  const Tezos = new TezosToolkit();
  Tezos.setProvider({ rpc: network, confirmationPollingTimeoutSecond: 300 });
  await Tezos.importKey(email, password, mnemonic.join(" "), secret);
  return Tezos;
};

const getAccounts = async () => {
  const Tezos1 = await createTezosFromFaucet("./alice.json");
  const Tezos2 = await createTezosFromFaucet("./bob.json");
  return { Tezos1, Tezos2 };
};

const testDeploy = async () => {
  console.log("Deploy Test");
  // loadAddress("./AtomicSwapContract.json");
  await deploy();
  const initialStorage = await getFullStorage(contractAddress);
  assert(Object.keys(initialStorage.swaps).length === 0);
  assert(Object.keys(initialStorage.swapStates).length === 0);
};

const testOpenSwap = async (tezAmount = "1.0") => {
  console.log("OpenSwap Test");
  const { Tezos1, Tezos2 } = await getAccounts();
  loadAddress("./AtomicSwapContract.json");

  const contract = await Tezos1.contract.at(contractAddress);
  const pkhSender = await Tezos1.signer.publicKeyHash();
  const pkhReceiver = await Tezos2.signer.publicKeyHash();
  const hash =
    "40de489d2086fcffd63c4473964765fdb387d676b5a9f306ca171a032b144e40";
  const timelock = 1000;
  const operation = await contract.methods
    .open(hash, hash, timelock, pkhReceiver)
    .send({ amount: tezAmount });
  await operation.confirmation();

  const finalStorage = await getFullStorage(contractAddress);
  const swap = finalStorage.swaps[hash];
  assert(swap);
  assert(parseInt(swap.timelock) === timelock);
  assert(swap.ethTrader === pkhSender);
  assert(swap.withdrawTrader === pkhReceiver);
  assert(swap.secretLock === hash);
  assert(parseInt(swap.value) === parseInt(tezAmount) * 1000000);
};

const testCheckSwap = async (tezAmount = "1.0") => {
  console.log("CheckSwap Test");
  const { Tezos1, Tezos2 } = await getAccounts();
  loadAddress("./AtomicSwapContract.json");

  const contract = await Tezos1.contract.at(contractAddress);
  const pkhSender = await Tezos1.signer.publicKeyHash();
  const pkhReceiver = await Tezos2.signer.publicKeyHash();
  const hash =
    "40de489d2086fcffd63c4473964765fdb387d676b5a9f306ca171a032b144e40";
  const timelock = 1000;

  // should not fail but change nothing
  const operation = await contract.methods.check(hash).send();
  await operation.confirmation();

  const finalStorage = await getFullStorage(contractAddress);
  const swap = finalStorage.swaps[hash];
  assert(swap);
  assert(parseInt(swap.timelock) === timelock);
  assert(swap.ethTrader === pkhSender);
  assert(swap.withdrawTrader === pkhReceiver);
  assert(swap.secretLock === hash);
  assert(parseInt(swap.value) === parseInt(tezAmount) * 1000000);
};

const testCloseSwap = async (tezAmount = "1.0") => {
  console.log("CloseSwap Test");
  const { Tezos1, Tezos2 } = await getAccounts();
  loadAddress("./AtomicSwapContract.json");

  const contract = await Tezos1.contract.at(contractAddress);
  const pkhSender = await Tezos1.signer.publicKeyHash();
  const pkhReceiver = await Tezos2.signer.publicKeyHash();
  const hash =
    "40de489d2086fcffd63c4473964765fdb387d676b5a9f306ca171a032b144e40";
  const secret = "3137434542463641443532314239333532363937343346373339364244";
  const timelock = 1000;

  const operation = await contract.methods.close(secret, hash).send();
  await operation.confirmation();

  const finalStorage = await getFullStorage(contractAddress);
  const swap = finalStorage.swaps[hash];
  assert(swap);
  assert(parseInt(swap.timelock) === timelock);
  assert(swap.ethTrader === pkhSender);
  assert(swap.withdrawTrader === pkhReceiver);
  assert(swap.secretLock === hash);
  assert(swap.secretKey === secret);
  assert(parseInt(swap.value) === parseInt(tezAmount) * 1000000);
};

const testCheckSecretSwap = async (tezAmount = "1.0") => {
  console.log("CheckSwap Test");
  const { Tezos1, Tezos2 } = await getAccounts();
  loadAddress("./AtomicSwapContract.json");

  const contract = await Tezos1.contract.at(contractAddress);
  const pkhSender = await Tezos1.signer.publicKeyHash();
  const pkhReceiver = await Tezos2.signer.publicKeyHash();
  const hash =
    "40de489d2086fcffd63c4473964765fdb387d676b5a9f306ca171a032b144e40";
  const timelock = 1000;

  // should not fail but change nothing
  const operation = await contract.methods.checkSecretKey(hash).send();
  await operation.confirmation();

  const finalStorage = await getFullStorage(contractAddress);
  const swap = finalStorage.swaps[hash];
  assert(swap);
  assert(parseInt(swap.timelock) === timelock);
  assert(swap.ethTrader === pkhSender);
  assert(swap.withdrawTrader === pkhReceiver);
  assert(swap.secretLock === hash);
  assert(parseInt(swap.value) === parseInt(tezAmount) * 1000000);
};
const assertInvariant = async testFn => {
  await testFn();
};

const test = async () => {
  const tests = [
    () => testDeploy(),
    () => testOpenSwap(),
    () => testCheckSwap(),
    () => testCloseSwap(),
    () => testCheckSecretSwap()
  ];

  for (let test of tests) {
    await assertInvariant(test);
  }
};

try {
  test().catch(console.log);
} catch (ex) {
  console.log(ex);
}
