import { FunctionComponentElement } from "react";

interface FaucetFormProp {
    walletAddress: string
}

export function FaucetForm(prop: FaucetFormProp): FunctionComponentElement<FaucetFormProp> {
    return (
        <div>
            <p> This address {prop.walletAddress} has provided a valid device attestation on Verax! </p>
            <p> Click the button below to claim tokens. </p>
            <button> Request Tokens </button>
        </div>
    )
}