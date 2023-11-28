import { FunctionComponentElement, useState, useEffect } from 'react';
import { AddressLike, BytesLike, formatEther } from 'ethers';
import { 
    submitFaucetRequest,
    getTokenBalance,
    provider
  } from '../modules/relayer';

interface AttestationProp {
    walletAddress: AddressLike,
    attestationId: BytesLike
}

export function AttestationComponent(prop: AttestationProp): FunctionComponentElement<AttestationProp> {
    const [mockBalance, setMockBalance] = useState("0");
    const [txHash, setTxHash] = useState("");

    useEffect(() => {
        getTokenBalance(prop.walletAddress).then((balInWei) => {
            const balInETH = formatEther(balInWei);
            setMockBalance(balInETH);
        })
    }, [txHash]);
    
    function handleRequestTokens() {
        submitFaucetRequest(prop.walletAddress).then((tx) => {
            console.log(tx.hash);
            setTxHash(tx.hash as string);
            alert("Tokens are coming your way! :)");
        }).catch(e => {
            console.log(e);
            alert("Failed to request tokens");
        })
    }  
    
    return (
        <>
            <p> Your wallet address: {prop.walletAddress as string} </p>
            <p> Your attestation ID: {prop.attestationId} </p>
            <p> Your balance: {mockBalance} $MOCK</p>
            <button 
                id = "request-btn" 
                onClick={handleRequestTokens}
            > 
                Request Tokens
            </button>
        </>
    )
}