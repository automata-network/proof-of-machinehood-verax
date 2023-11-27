import { 
    AbiCoder, 
    ParamType, 
    Contract,
    JsonRpcProvider, 
    BytesLike, 
    AddressLike, 
    BigNumberish,
    keccak256,
    ZeroHash
} from 'ethers';
import { ProcessedCredntial } from './webauthn';
import { MACHINEHOOD_SCHEMA_ID } from '../utils/constants';

import MachinehoodPortal from "../abi/MachinehoodPortal.json";
import Faucet from "../abi/Faucet.json";
import Token from '../abi/MockERC20.json';

const REACT_APP_RPC_URL = 'http://localhost:8545/';
const REACT_APP_RELAYER_URL = 'http://localhost:3001/';
const REACT_APP_MACHINEHOOD_PORTAL_ADDRESS = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';
const REACT_APP_FAUCET_ADDRESS = '0x9A676e781A523b5d0C0e43731313A708CB607508';
const REACT_APP_TOKEN_ADDRESS = '0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82';

export const provider = new JsonRpcProvider(REACT_APP_RPC_URL);

interface TransactionResponse {
    status: boolean,
    hash: BytesLike,
    error?: any
}

interface AttestationIdResponse {
    status: boolean,
    id: BytesLike
}

export async function submitAttestation(
    walletAddress: AddressLike, 
    credential: ProcessedCredntial
): Promise<TransactionResponse> {
    const paddedWalletAddress = AbiCoder.defaultAbiCoder().encode(['address'], [walletAddress]);
    const validationPayloadObj = {
        attStmt: credential.attStmt.length > 0 ? credential.attStmt : '0x',
        authData: credential.authData,
        clientData: credential.clientData
    };
    const encodedValidationPayload = AbiCoder.defaultAbiCoder().encode(
        [
            ParamType.from({
                type: 'tuple',
                name: 'ValidationPayloadStruct',
                components: [
                    { type: 'bytes', name: 'attStmt' },
                    { type: 'bytes', name: 'authData' },
                    { type: 'bytes', name: 'clientData' }
                ]
            })
        ], [validationPayloadObj]
    );
    const attestationData = AbiCoder.defaultAbiCoder().encode(
        ['bytes32', 'uint8', 'bytes32'],
        [paddedWalletAddress, credential.device, keccak256(encodedValidationPayload)]
    );
    const attestationPayload = {
        schemaId: MACHINEHOOD_SCHEMA_ID,
        expirationDate: 0, // this attestation becomes valid indefinitely
        subject: walletAddress,
        attestationData: attestationData
    };
    const portalContract = new Contract(REACT_APP_MACHINEHOOD_PORTAL_ADDRESS, MachinehoodPortal.abi, provider);
    const txData = portalContract.interface.encodeFunctionData(
        'attest',
        [
            attestationPayload,
            [encodedValidationPayload]
        ]
    );
    return buildTxRequest(walletAddress, REACT_APP_MACHINEHOOD_PORTAL_ADDRESS, txData);
}

export async function submitFaucetRequest(walletAddress: AddressLike): Promise<TransactionResponse> {
    const attestation = await getAttestationId(walletAddress);
    if (!attestation.status) {
        return {
            status: false,
            hash: ZeroHash
        }
    } else {
        const faucetContract = new Contract(REACT_APP_FAUCET_ADDRESS, Faucet.abi, provider);
        const txData = faucetContract.interface.encodeFunctionData(
            'requestTokens',
            [attestation.id]
        );
        return buildTxRequest(walletAddress, REACT_APP_FAUCET_ADDRESS, txData);
    }
}

export async function getAttestationId(walletAddress: AddressLike): Promise<AttestationIdResponse> {
    const url = `${REACT_APP_RELAYER_URL}id?address=${walletAddress}`;
    const responseStr = await fetch(url);
    const response = (await responseStr.json()) as any;
    console.log('attestation validity response: ', responseStr);
    return {
        status: response.status,
        id: response.id
    }
}

export async function getTokenBalance(walletAddress: AddressLike): Promise<BigNumberish> {
    const tokenContract = new Contract(REACT_APP_TOKEN_ADDRESS, Token.abi, provider);
    return await tokenContract.balanceOf(walletAddress);
}

async function buildTxRequest(
    from: AddressLike,
    to: AddressLike,
    data: BytesLike,
    value?: BigNumberish,
): Promise<TransactionResponse> {
    const chainId = (await provider.getNetwork()).chainId;
    const reqBody = {
        jsonrpc: '2.0',
        id: 1,
        method: 'sendTx',
        params: {
            chainId: chainId.toString(),
            from: from,
            to: to,
            value: value ? value.toString() : '0',
            data: data
        }
    };
    const reqOptions = {
        method: 'POST',
        headers: {
        'Content-Type': 'application/json',
        },
        body: JSON.stringify(reqBody)
    };
    console.log('request: ', reqOptions);
    const responseStr = await fetch(REACT_APP_RELAYER_URL, reqOptions);
    const response = await responseStr.json() as any;
    if (responseStr.status !== 200) {
        return {
            status: false,
            hash: ZeroHash,
            error: response
        }
    } else {
        console.log('response: ', response);
        return {
            status: true,
            hash: response.txHash!
        };
    }
}