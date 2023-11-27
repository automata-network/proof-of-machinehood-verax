import * as cborWeb from "cbor-web";
import { ethers } from "ethers";
import { Buffer } from 'buffer';
import * as Parser from './parser/index';

const REACT_APP_RPID = "localhost";

interface ParsedCredential {
    AAGUID: string,
    decodedAttestationObj: any,
    clientData: string,
    authData: string
}

export interface ProcessedCredntial {
    device: DeviceType,
    attStmt: string,
    clientData: string,
    authData: string
}

// To match with the MachinehoodModule enum definition
enum DeviceType {
    INVALID,
    ANDROID,
    WINDOWS,
    YUBIKEY,
    SELFCLAIM
}

const enabledYubiKeyAAGUIDs = [
    "cb69481e-8ff7-4039-93ec-0a2729a154a8",
    "ee882879-721c-4913-9775-3dfcce97072a",
    "fa2b99dc-9e39-4257-8f92-4a30d23c4118",
    "2fc0579f-8113-47ea-b116-bb5a8db9202a",
    "c1f9a0bc-1dd2-404a-b27f-8e29047a43fd",
    "73bb0cd4-e502-49b8-9c6f-b59445bf720b",
    "c5ef55ff-ad9a-4b9f-b580-adebafe026d0",
    "85203421-48f9-4355-9bc8-8a53846e5083",
    "f8a011f3-8c0a-4d15-8006-17111f9edc7d",
    "b92c3f9a-c014-4056-887f-140a2501163b",
    "6d44ba9b-f6ec-2e49-b930-0c8fe920cb73",
    "149a2021-8ef6-4133-96b8-81f8d5b7f1f5",
    "d8522d9f-575b-4866-88a9-ba99fa02f35b",
    "a4e9fc6d-4cbe-4758-b8ba-37598bb5bbaa",
    "0bb43545-fd2c-4185-87dd-feb0b2916ace",
];

export async function createCredential(challenge: string) {
    let prefixedChallenge = checkPrefixThenPad(challenge);

    console.log("Challenge: ", prefixedChallenge);

    const enc = new TextEncoder();

    const publicKey: PublicKeyCredentialCreationOptions = {
        authenticatorSelection: {
            userVerification: "preferred",
            residentKey: "discouraged",
        },
        attestation: "direct",
        challenge: enc.encode(prefixedChallenge),
        rp: {
            name: "Faucet Demo",
            id: REACT_APP_RPID
        },
        user: {
            id: new Uint8Array([1]),
            name: challenge,
            displayName: challenge
        },
        pubKeyCredParams: [
            {
                type: "public-key",
                alg: -7  // "ES256" IANA COSE Algorithms registry
            }
        ]
    };

    try {
        const credential = (await navigator.credentials.create({ publicKey })) as PublicKeyCredential;
        const parsedCredential = parseCredential(credential);

        const jsonDownload = processCredential(parsedCredential);
        const jsonBlob = new Blob([JSON.stringify(jsonDownload)], { type: 'application/json' });
        
        // Create a download link
        const downloadLink = document.createElement('a');
        downloadLink.href = URL.createObjectURL(jsonBlob);
        downloadLink.download = 'data.json';
        // Trigger the download
        downloadLink.click();

        return jsonDownload;
        
    } catch (err) {
        console.error(err);
    }
}

function checkPrefixThenPad(challenge: string): string {
    let prefixed: string = '';
    if (challenge.substring(0, 2) !== '0x') {
        prefixed = '0x' + '0'.repeat(24) + challenge;
    } else {
        prefixed = '0x' + '0'.repeat(24) + challenge.substring(2);
    }
    return prefixed.toLowerCase();
}

function parseCredential(credential: any): ParsedCredential {
    const attestationObject = (credential?.response as AuthenticatorAttestationResponse)?.attestationObject;
    const decodedAttestationObject = cborWeb.decodeFirstSync(attestationObject);
    const AAGUID = getAAGUID(decodedAttestationObject);
    const authDataHex = "0x" + decodedAttestationObject?.authData?.toString("hex");
    const clientDataJSONBuffer = Buffer.from(credential?.response?.clientDataJSON);
    const clientDataJSONString = clientDataJSONBuffer.toString("utf8");
    const clientDataJSONHex = ethers.dataSlice(clientDataJSONBuffer);
  
    console.log("parseCredential", {
      fmt: decodedAttestationObject.fmt,
      AAGUID,
      clientDataJSONString,
      clientDataJSONHex,
      authDataHex,
      authData: decodedAttestationObject.authData,
    });
  
    return { 
        AAGUID: AAGUID, 
        decodedAttestationObj: decodedAttestationObject, 
        clientData: clientDataJSONHex, 
        authData: authDataHex 
    };
}

function getAAGUID(decodedAttestationObject: any): string {
    if (decodedAttestationObject?.authData) {
        const aaguid = extraAAGUID(decodedAttestationObject.authData);
        return aaguid;
    } else {
        console.log("decodedAttestationObject is not valid.", decodedAttestationObject);
        throw new Error("Unknown Device");
    }
}

function extraAAGUID(authData: Uint8Array) {
    const aaguidUint8 = authData.slice(37, 53);
    const aaguid = aaguidToString(aaguidUint8);  
    return aaguid;
}

function aaguidToString(aaguid: Uint8Array): string {
    // Raw Hex: adce000235bcc60a648b0b25f1f05503
    const hex = Buffer.from(aaguid).toString("hex");
  
    const segments: string[] = [
      hex.slice(0, 8), // 8
      hex.slice(8, 12), // 4
      hex.slice(12, 16), // 4
      hex.slice(16, 20), // 4
      hex.slice(20, 32), // 8
    ];
  
    // Formatted: adce0002-35bc-c60a-648b-0b25f1f05503
    return segments.join("-");
}

function processCredential(credential: ParsedCredential): ProcessedCredntial {
    let device = getDeviceType(credential.decodedAttestationObj, credential.AAGUID);
    let attStmt = parseAttStmt(device, credential.decodedAttestationObj);
    
    return {
        device: device,
        authData: credential.authData,
        clientData: credential.clientData,
        attStmt: attStmt
    }
}

function getDeviceType(decodedAttestationObject: any, AAGUID: string): DeviceType {
    if (
        decodedAttestationObject &&
        (decodedAttestationObject.fmt === "android-safetynet" ||
          decodedAttestationObject.fmt === "tpm" ||
          decodedAttestationObject.fmt === "packed") &&
        decodedAttestationObject.authData &&
        decodedAttestationObject.authData.length > 53 &&
        (decodedAttestationObject.authData.slice(32, 33)[0] & 0x40) === 0x40
    ) {
        if (decodedAttestationObject.fmt === "android-safetynet") {
            return DeviceType.ANDROID;
        } else if (decodedAttestationObject.fmt === "tpm") {
            return DeviceType.WINDOWS;
        } else if (decodedAttestationObject.fmt === "packed") {
            if (enabledYubiKeyAAGUIDs.includes(AAGUID.toLowerCase())) {
                return DeviceType.YUBIKEY;
            }
        }
    }

    return DeviceType.SELFCLAIM;
}

function parseAttStmt(device: DeviceType, decodedAttestationObj: any): string {
    if (device === DeviceType.ANDROID) {
        return Parser.Android.parseAndroidSafetyNetAttStmt(decodedAttestationObj);
    } else if (device === DeviceType.WINDOWS) {
        return Parser.Windows.parseWindowsTPMAttStmt(decodedAttestationObj);
    } else if (device === DeviceType.YUBIKEY) {
        return Parser.Yubikey.parseYubikeyAttStmt(decodedAttestationObj);
    } else {
        return "";
    }
}