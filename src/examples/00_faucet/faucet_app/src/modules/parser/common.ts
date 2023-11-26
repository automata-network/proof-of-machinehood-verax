import forge from "node-forge";
import asn1 from "asn1.js";
import * as Asn1js from "asn1js";
import * as Pkijs from "pkijs";
import elliptic from "elliptic";

export const ECDSASignature: any = asn1.define("ECDSASignature", function (this: any) {
  this.seq().obj(this.key("r").int(), this.key("s").int());
});

export class PublicKey {
    keyType: number;
    pubKey: string;

    constructor(keyType: number, pubKey: string) {
        this.keyType = keyType;
        this.pubKey = pubKey;
    }
}

export class Certificate {
    tbsCertificate: string;
    publicKey: PublicKey;
    signature: string;
    sigAlg: number;

    constructor(tbsCertificate: string, publicKey: PublicKey, signature: string, sigAlg: number) {
        this.tbsCertificate = tbsCertificate;
        this.publicKey = publicKey;
        this.signature = signature;
        this.sigAlg = sigAlg;
    }
}

export function getUnknownDeviceError(): Error {
  return new Error("Unknown attestation obj provided for the device type");
}

export function base64UrlToBase64(base64Url: string) {
    // convert base64url to base64
    let base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const pad = base64.length % 4;
    if (pad) {
      if (pad === 1) {
        throw new Error("Base64URlToBase64 conversion failed");
      }
      base64 += new Array(5 - pad).join("=");
    }
    return base64;
}

export function addHexPrefix(data: string) {
  if (data.length % 2 !== 0) {
      return "0x0" + data;
  }
  return "0x" + data;
}

export function decodeX5c(certBase64OrBuffer: Buffer, alg: number | string, index: number) {
    if (index === 0) {
        if (alg === -65535 || alg === -257 || alg === "RS256") {
        return decodeCertificateByForge(certBase64OrBuffer);
        } else if (alg === -7) {
        return decodeCertificateByPkijs(certBase64OrBuffer);
        }
    } else {
        return decodeCertificateByForge(certBase64OrBuffer);
    }
}

export function decodeCACert(pem: string) {
  const cert = forge.pki.certificateFromPem(pem);

  const tbsCertificateDer = forge.asn1.toDer(cert.tbsCertificate);
  const tbsCertificateHex = forge.util.bytesToHex(tbsCertificateDer.getBytes());
  const tbsCertificate = tbsCertificateHex.length % 2 ? "0x0" + tbsCertificateHex : "0x" + tbsCertificateHex;

  const modulusHex = (cert.publicKey as any).n.toString(16);
  const exponentHex = (cert.publicKey as any).e.toString(16);

  const modulus = modulusHex.length % 2 ? "0" + modulusHex : "" + modulusHex;
  const exponent = exponentHex.length % 2 ? "0" + exponentHex : "" + exponentHex;
  const pubKey = addHexPrefix(exponent + modulus);

  const signatureHex = forge.util.bytesToHex(cert.signature);
  const signature = signatureHex.length % 2 ? "0x0" + signatureHex : "0x" + signatureHex;

  const publicKey = new PublicKey(0, pubKey);

  return new Certificate(tbsCertificate, publicKey, signature, 0);
}

function decodeCertificateByForge(certBuffer: Buffer) {
    console.log("decodeCertificateByForge", certBuffer);
    const certBase64 = certBuffer.toString("base64");
    const certPem = `-----BEGIN CERTIFICATE-----\n${certBase64}\n-----END CERTIFICATE-----`;
    // console.log(certPem);
    const cert = forge.pki.certificateFromPem(certPem);
  
    const tbsCertificateDer = forge.asn1.toDer(cert.tbsCertificate);
    const signature = forge.util.bytesToHex(cert.signature);
    // n and e not found for some reason??
    const modulus = (cert.publicKey as any).n.toString(16);
    const exponent = (cert.publicKey as any).e.toString(16);
    const pubKey = addHexPrefix(exponent + modulus);
    const publicKey = new PublicKey(0, pubKey);
    const algorithmId = cert.signatureOid;
  
    let sigAlg;
    if (algorithmId == "1.2.840.113549.1.1.11") {
      //sha256WithRSAEncryption
      sigAlg = 0;
    } else if (algorithmId == "1.2.840.113549.1.1.5") {
      //sha1WithRSAEncryption
      sigAlg = 1;
    } else {
      throw new Error("Failed to parse certificate");
    }
  
    return new Certificate(addHexPrefix(tbsCertificateDer.toHex()), publicKey, addHexPrefix(signature), sigAlg);
}

function decodeCertificateByPkijs(certDer: Buffer) {
    // console.log(certDer.toString('hex'));
  
    // console.log(certPem);
    const der = new Uint8Array(certDer);
    const ber = der.buffer;
    const asn1 = Asn1js.fromBER(ber);
    // const asn1 = forge.asn1.fromDer(derBuffer);
    const cert = new Pkijs.Certificate({ schema: asn1.result });
    const publicKeyInfo = cert.subjectPublicKeyInfo;
    const signature = Buffer.from(cert.signatureValue.valueBlock.valueHex).toString("hex");
    // console.log(Buffer.from(cert.tbs).toString('hex'));
    const tbsCertificate = Buffer.from(cert.tbs).toString("hex");
    const algorithmOid = publicKeyInfo.algorithm.algorithmId;
    const publicKeyData = publicKeyInfo.subjectPublicKey.valueBlock.valueHex;
  
    if (algorithmOid !== "1.2.840.10045.2.1") {
      console.error("Not an ECDSA public key");
      return;
    }
    // 使用elliptic库解析ECDSA公钥
    const ec = new elliptic.ec("p256");
    // console.log(ec.genKeyPair().getPublic());
    const keyPair = ec.keyFromPublic(new Uint8Array(publicKeyData));
  
    // 获取gx和gy坐标
    const gx = keyPair.getPublic().getX().toString(16);
    const gy = keyPair.getPublic().getY().toString(16);
    const pubKey = addHexPrefix(gx + gy);
  
    // console.log('pubKey: ', pubKey);
  
    // console.log("sig: ", signature);
    // console.log("tbs: ", tbsCertificate);
  
    const algorithmId = cert.signatureAlgorithm.algorithmId;
    let sigAlg;
    if (algorithmId == "1.2.840.113549.1.1.11") {
      //sha256WithRSAEncryption
      sigAlg = 0;
    } else if (algorithmId == "1.2.840.113549.1.1.5") {
      //sha1WithRSAEncryption
      sigAlg = 1;
    } else {
      throw new Error("Failed to decodeCertificateByPkijs");
    }
  
    const publicKey = new PublicKey(1, pubKey);
  
    // console.log(sigAlg);
    return new Certificate(addHexPrefix(tbsCertificate), publicKey, addHexPrefix(signature), sigAlg);
    // console.log("TbsCertificate:", tbsCertificateDer.toHex());
    // console.log("Signature:", signature);
    // console.log("Modulus:", modulus);
    // console.log("Exponent:", exponent);
}