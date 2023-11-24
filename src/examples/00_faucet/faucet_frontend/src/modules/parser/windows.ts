import { Buffer } from 'buffer';
import {
    getUnknownDeviceError,
    addHexPrefix,
    decodeX5c,
    Certificate,
    decodeCACert
} from './common';
import { ParamType, AbiCoder } from 'ethers';
import { microsoftTpmRootCA } from '../../vendor/rootCA';

class WindowsAttStmt {
    sig: string;
    x5c: Certificate[];
    certInfo: string;
    alg: number;

    constructor(sig: string, x5c: Certificate[], certInfo: string, alg: number) {
        this.sig = sig;
        this.x5c = x5c;
        this.certInfo = certInfo;
        this.alg = alg;
    }
}

export function parseWindowsTPMAttStmt(decodedAttestationObject: any): string{
    if (decodedAttestationObject?.attStmt) {
        const attStmt = decodedAttestationObject.attStmt;
        console.log("parseWindowsPayload:", { attStmt });
        const { attStmt: attStmtParsed, attStmtHex } = decodeWindowsAttStmt(attStmt);
        console.log("parseWindowsPayload:", { attStmtParsed, attStmtHex });
        return attStmtHex;
    } else {
        console.log("invalid attStmt", decodedAttestationObject);
        throw getUnknownDeviceError();
    }
}

function decodeWindowsAttStmt(attStmt: any) {
    // console.log("---decodeAttStmt---");
    const alg = attStmt.alg;
    console.log("attStmt.alg", alg);
    let attStmtAlg;
    if (alg == -7) {
      attStmtAlg = 1;
    } else if (alg == -257 || alg === "RS256") {
      attStmtAlg = 0;
    } else if (alg == -65535) {
      attStmtAlg = 2;
    } else {
      throw new Error("invalid alg");
    }
  
    const certificates: Certificate[] = [];
    if (attStmt.x5c && Array.isArray(attStmt.x5c)) {
      attStmt.x5c.forEach((buf: Buffer, index: number) => {
        const certificate = decodeX5c(buf, alg, index);
  
        if (certificate) {
          certificates.push(certificate);
        }
      });

      const rootCA = decodeCACert(microsoftTpmRootCA);
  
      certificates.push(rootCA);
    }
  
    if (certificates.length > 1) {
      const attStmtOutput = new WindowsAttStmt(
        addHexPrefix(attStmt.sig.toString("hex")),
        certificates,
        addHexPrefix(attStmt.certInfo.toString("hex")),
        attStmtAlg,
      );
      const attStmtHex = encodeWindowsAttStmt(attStmtOutput);
      console.log("encode AttStmt hex:", attStmtHex);
  
      return { attStmt: attStmtOutput, attStmtHex };
    } else {
      throw new Error("[5] Oops! Something seems to be wrong. Check the FAQ for more information.");
    }
}

function encodeWindowsAttStmt(attStmt: WindowsAttStmt) {
    return AbiCoder.defaultAbiCoder().encode(
      [
        ParamType.from({
          type: "tuple",
          name: "AttStmt",
          components: [
            { type: "uint8", name: "alg" },
            { type: "bytes", name: "sig" },
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
            { type: "bytes", name: "certInfo" },
          ],
        }),
      ],
      [attStmt],
    );
  }