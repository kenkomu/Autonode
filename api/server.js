// api/server.js
require('dotenv').config();
const express = require('express');
const Web3 = require('web3');
const processData = require('../agent/aiAgent');
const { uploadData } = require('../agent/ipfsClient');
const messenger = require('../agent/messaging');
const { attestWithEigenLayer } = require('../integration/eigenlayer');

const app = express();
app.use(express.json());

const web3 = new Web3(process.env.BLOCKCHAIN_URL);

// Attestation contract ABI (ensure it matches your deployed contract)
const attestationABI = [
  {
    "constant": false,
    "inputs": [{ "name": "ipfsHash", "type": "string" }],
    "name": "attestResult",
    "outputs": [],
    "type": "function"
  },
  {
    "anonymous": false,
    "inputs": [
      { "indexed": true, "name": "agent", "type": "address" },
      { "indexed": false, "name": "ipfsHash", "type": "string" },
      { "indexed": false, "name": "timestamp", "type": "uint256" }
    ],
    "name": "Attested",
    "type": "event"
  }
];

const attestationAddress = process.env.ATTESTATION_ADDRESS;
const attestationContract = new web3.eth.Contract(attestationABI, attestationAddress);

app.post('/run-task', async (req, res) => {
  try {
    const { input } = req.body;
    if (!input) {
      return res.status(400).json({ error: "Input is required" });
    }

    // 1. Process input using the AI agent.
    const result = processData(input);

    // 2. Upload processed result to IPFS.
    const ipfsHash = await uploadData(result);

    // 3. Submit the IPFS hash to EigenLayer for attestation.
    const eigenlayerResult = await attestWithEigenLayer(ipfsHash);

    // 4. Attest the result on-chain via the Attestation contract.
    const accounts = await web3.eth.getAccounts();
    const tx = await attestationContract.methods.attestResult(ipfsHash).send({ from: accounts[0] });

    // 5. Emit a "taskCompleted" event with all results.
    messenger.emit('taskCompleted', { input, result, ipfsHash, eigenlayerResult, txHash: tx.transactionHash });

    res.json({ result, ipfsHash, eigenlayerResult, txHash: tx.transactionHash });
  } catch (error) {
    console.error("Error in /run-task:", error);
    res.status(500).json({ error: error.toString() });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API server running on port ${PORT}`);
});

module.exports = app; // For testing purposes
