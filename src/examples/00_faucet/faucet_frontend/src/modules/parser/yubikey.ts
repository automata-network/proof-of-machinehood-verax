import {
    getUnknownDeviceError,
    addHexPrefix,
    decodeX5c,
    Certificate,
    decodeCACert,
    ECDSASignature
} from './common';
import { ParamType, AbiCoder } from 'ethers';
import { yubikeyRootCA } from '../../vendor/rootCA';

class YubiKeyAttStmt {
    alg: number;
    signature: string;
    x5c: Certificate[];
  
    constructor(alg: number, signature: string, x5c: Certificate[]) {
      this.alg = alg;
      this.signature = signature;
      this.x5c = x5c;
    }
}

export function parseYubikeyAttStmt(decodedAttestationObject: any): string {
    if (decodedAttestationObject?.attStmt) {
        const attStmt = decodedAttestationObject.attStmt;
        console.log("parseYubikeyPayload:", { attStmt });
        const { attStmt: attStmtParsed, attStmtHex } = decodeYubikeyAttStmt(attStmt);
        console.log("parseYubikeyPayload:", { attStmtParsed, attStmtHex });
    
        return attStmtHex;
      } else {
        console.log("invalid attStmt", decodedAttestationObject);
        throw getUnknownDeviceError();
      }
}

function decodeYubikeyAttStmt(attStmtObj: any) {
    const signature = attStmtObj.sig;
    const x5c = attStmtObj.x5c;
    const alg = attStmtObj.alg;
    console.log("attStmt.alg", alg);
    let attStmtAlg;
    if (alg == -7) {
      attStmtAlg = 1;
    } else if (alg == -257 || alg === "RS256") {
      attStmtAlg = 0;
    } else if (alg == -65535) {
      attStmtAlg = 2;
    } else {
      throw new Error("[4] Oops! Something seems to be wrong. Check the FAQ for more information.");
    }
  
    const decodedSig = ECDSASignature.decode(signature, "der");
    const sigHex = decodedSig.r.toString(16) + decodedSig.s.toString(16);
  
    const certificates: Certificate[] = [];
  
    if (x5c && Array.isArray(x5c)) {
      x5c.forEach((certDer, index) => {
        const certificate = decodeX5c(certDer, alg, index);
  
        if (certificate) {
          certificates.push(certificate);
        }
      });
  
      const rootCA = decodeCACert(yubikeyRootCA);
  
      certificates.push(rootCA);
    }
  
    if (certificates.length > 1) {
      const attStmt = new YubiKeyAttStmt(attStmtAlg, addHexPrefix(sigHex), certificates);
      const attStmtHex = encodeYubikeyAttStmt(attStmt);
  
      return { attStmt, attStmtHex };
    } else {
      throw new Error("[5] Oops! Something seems to be wrong. Check the FAQ for more information.");
    }
}

function encodeYubikeyAttStmt(attStmt: YubiKeyAttStmt) {
    // console.log(attStmt);
    return AbiCoder.defaultAbiCoder().encode(
      [
        ParamType.from({
          type: "tuple",
          name: "AttStmt",
          components: [
            { type: "uint8", name: "alg" },
            { type: "bytes", name: "signature" },
            {
              type: "tuple[]",
              name: "x5c",
              components: [
                { type: "bytes", name: "tbsCertificate" },
                {
                  type: "tuple",
                  name: "publicKey",
                  components: [
                    { type: "uint8", name: "keyType" },
                    { type: "bytes", name: "pubKey" },
                  ],
                },
                { type: "bytes", name: "signature" },
                { type: "uint8", name: "sigAlg" },
              ],
            },
          ],
        }),
      ],
      [attStmt],
    );
  }