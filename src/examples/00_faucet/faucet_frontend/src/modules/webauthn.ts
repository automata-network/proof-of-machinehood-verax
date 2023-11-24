import * as cborWeb from "cbor-web";
import { ethers } from "ethers";
import { Buffer } from 'buffer';

const REACT_APP_RPID = "localhost";

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
            name: "username",
            displayName: "User Name"
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
        const jsonDownload = parseCredential(credential);
        const jsonBlob = new Blob([JSON.stringify(jsonDownload)], { type: 'application/json' });

        // Create a download link
        const downloadLink = document.createElement('a');
        downloadLink.href = URL.createObjectURL(jsonBlob);
        console.log('json url: ', downloadLink.href);
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

function parseCredential(credential: any) {
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
        attestationObj: decodedAttestationObject, 
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