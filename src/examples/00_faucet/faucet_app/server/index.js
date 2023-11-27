// dependencies
require('dotenv').config({path: '../../../../.env'});

const express = require('express');
const app = express();
const port = process.env.PORT || 3001;
const cors = require('cors');
const NodeCache = require('node-cache'); // caches user address and attestationId mapping
const ethers = require('ethers');
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'http://127.0.0.1:8545');
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const attestationRegistryAddress = process.env.ATTESTATION_REGISTRY_ADDRESS;
const machinehoodPortalAddress = process.env.MACHINEHOOD_PORTAL_ADDRESS;
const faucetAddress = process.env.FAUCET_DEMO;

const { abi: FaucetABI } = require('../src/abi/Faucet.json');

const cache = new NodeCache({ stdTTL: 30 * 24 * 60 * 60 }); // 1 month TTL

// === SERVER PIPELINE ===
app.use(express.json());
app.use(
  cors({
    origin: '*',
  })
);

// Sends on chain transactions
// Can be used for (1) making attestations, and (2) requesting tokens from the faucet
app.post('/', async (req, res) => {
    // supports one chainId only. TODO: multiple chainIds
    const currentChainId = (await provider.getNetwork()).chainId;
    
    // request body params: {chainId: Number, from: address, to: address, value: Number, input: BytesLike}
    const body = req.body;
    if (body.method !== 'sendTx') {
        res.status(400).send(
            "400 Bad Request: Unknown method"
        )
    } else if (body.params.chainId !== currentChainId.toString()) {
        res.status(400).send(
            "400 Bad Request: Unsupported chainId"
        )
    } else {
        // Send the transaction
        const to = body.params.to;
        const value = body.params.value;
        const data = body.params.data;
        const user = body.params.from;

        let tx;

        try {
            tx = await wallet.sendTransaction({
                to: to,
                value: value,
                data: data
            });
            const response = {txHash: tx.hash};
            console.log(response);
            res.status(200).send(JSON.stringify(response));
        } catch (e) {
            console.log(e);
            // TODO: clarity on error message
            res.send(JSON.stringify(e));
        }

        // handling machinehood-verax transactions
        if (tx && to === machinehoodPortalAddress) {
            const receipt = await tx.wait(1);
            await getAndStoreAttestationId(user, receipt);
        }
    }
})

// Retrieve the attestation id for the provided user address
// Sends zero hash in the response if no attestations were made
app.get('/id', async (req, res) => {
    class AttestationStatus {
        constructor(id, status) {
            this.id = id;
            this.status = status;
        }
    }
    const user = req.query.address;
    let response;
    
    if (!cache.has(user.toLowerCase())) {
        response = new AttestationStatus(ethers.ZeroHash, false);
    } else {
        const id = cache.get(user.toLowerCase());
        const faucetContract = new ethers.Contract(faucetAddress, FaucetABI, provider);
        const status = await faucetContract.attestationIsValid(id);
        response = new AttestationStatus(id, status);
        // expired, remove from cache
        if (!status) {
            cache.del(user);
        }
    }

    res.status(200).send(JSON.stringify(response));
})

app.listen(port, () => {
    console.log(`Listening at port ${port}...`);
});

// === HELPER FUNCTION(s) ===

async function getAndStoreAttestationId(user, txReceipt) {
    const logs = txReceipt.logs;
    for (let log of logs) {
        const expectedTopic = '0xfe10586889e06530420fe4a0d86aa4f7afc3c9dc84b0c77b731a9615496ef18a';
        const expectedAddress = attestationRegistryAddress;
        if (log.address === expectedAddress && log.topics[0] === expectedTopic) {
            const attestationId = log.topics[1];
            console.log(`Saving attestation ID: ${attestationId}...`);
            cache.set(user.toLowerCase(), attestationId);
        }
    }
}