import { FunctionComponentElement } from "react";

interface AttestationFormProp {
    walletAddress: string
}

export function AttestForm(prop: AttestationFormProp): FunctionComponentElement<AttestationFormProp> {
    return (
        <div>
            <p> This address {prop.walletAddress} has not submitted a device attestation to Verax yet. </p>
            <button> Attest Device </button>
        </div>
    )
}