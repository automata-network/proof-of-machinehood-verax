import { Buffer } from 'buffer';
import {
    getUnknownDeviceError,
    base64UrlToBase64,
    decodeX5c,
    Certificate
} from './common';
import { ParamType, AbiCoder } from 'ethers';

class AndroidAttStmt {
  jwtHeader: string;
  jwtPayload: string;
  jwtSignature: string;
  alg: number;
  x5c: Certificate[];

  constructor(jwtHeader: string, jwtPayload: string, jwtSignature: string, alg: number, x5c: Certificate[]) {
    this.jwtHeader = jwtHeader;
    this.jwtPayload = jwtPayload;
    this.jwtSignature = jwtSignature;
    this.alg = alg;
    this.x5c = x5c;
  }
}

export function parseAndroidSafetyNetAttStmt(decodedAttestationObject: any): string {
    if (decodedAttestationObject?.attStmt?.response) {
        const jwtUint8Array = Buffer.from(decodedAttestationObject.attStmt.response);
        const jwt = jwtUint8Array.toString("utf8");
        console.log("parseAndroidPayload:", { jwt });
        const { attStmt: attStmtParsed, attStmtHex } = decodeJWT(jwt);
        console.log("parseAndroidPayload:", { attStmtParsed, attStmtHex });

        return attStmtHex;
    } else {
        console.log("invalid attStmt", decodedAttestationObject);
        throw getUnknownDeviceError();
    }
}

function decodeJWT(jwt: string) {
    const parts = jwt.split(".");
  
    if (parts.length !== 3) {
      throw new Error("[3] Oops! Something seems to be wrong. Check the FAQ for more information.");
    }
  
    // const header = base64UrlToBase64(parts[0]);
    // const payload = base64UrlToBase64(parts[1]);
    const signature = base64UrlToBase64(parts[2]);
    const header = parts[0];
    const payload = parts[1];
    // const signature = parts[2];
  
    // console.log("JWT Header:", header);
    // console.log();
    // console.log("JWT Payload:", payload);
    // console.log(Buffer.from(parts[1], 'base64').toString('utf8'));
    // console.log();
    // console.log("JWT Signature:", signature);
    // console.log();
  
    const headerDecoded = JSON.parse(Buffer.from(header, "base64").toString("utf8"));
    const alg = headerDecoded.alg;
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
  
    const certificates: Certificate[] = [];
    if (headerDecoded.x5c && Array.isArray(headerDecoded.x5c)) {
      headerDecoded.x5c.forEach((certBase64: string, index: number) => {
        const buf = Buffer.from(certBase64, "base64");
        const certificate = decodeX5c(buf, alg, index);
  
        if (certificate) {
          certificates.push(certificate);
        }
      });
    }
  
    if (certificates.length > 0) {
      const attStmt = new AndroidAttStmt(header, payload, signature, attStmtAlg, certificates);
      console.log("attStmt started.", attStmt);
      const attStmtHex = encodeAndroidAttStmt(attStmt);
      console.log("attStmt: ", attStmtHex);
  
      return { attStmt, attStmtHex };
    } else {
      throw new Error("[5] Oops! Something seems to be wrong. Check the FAQ for more information.");
    }
}

function encodeAndroidAttStmt(attStmt: AndroidAttStmt) {
  return AbiCoder.defaultAbiCoder().encode(
    [
      ParamType.from({
        type: "tuple",
        name: "AttStmt",
        components: [
          { type: "uint8", name: "alg" },
          { type: "string", name: "jwtHeader" },
          { type: "string", name: "jwtPayload" },
          { type: "string", name: "jwtSignature" },
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