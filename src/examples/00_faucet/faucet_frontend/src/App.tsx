import React, { useEffect, useState } from 'react';
import { createCredential } from './modules/webauthn';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1> Faucet Demo </h1>
          <MainComponent/>
      </header>
    </div>
  );
}

function MainComponent(): JSX.Element {
  let [requestEnabled, setRequestEnabled] = useState(false);
  let [walletAddress, setWalletAddress] = useState("");

  useEffect(() => {
    if (walletAddress.length > 0) {
      // TODO: check if wallet address has made a valid attestation on chain
      let walletHasValidAttestation = false;

      const attest = async() => {
        while (!walletHasValidAttestation) {
          let beginAttesting = window.confirm("You must provide an attestation for this wallet before proceeding.");
          if (beginAttesting) {
            console.log("begin attesting...");
            try {
              const attestationParamObj = await createCredential(walletAddress);
              // sends the transaction
              // wait for confirmation
              walletHasValidAttestation = true;
            } catch (e) {
              alert("Attestation failed");
              break;
            }
          } else {
            console.log("Cancelled...");
            break;
          }
        }
      }
      
      attest().then(() => {
        setRequestEnabled(walletHasValidAttestation);
      });
    }
  }, [walletAddress]);

  function updateWalletAddress(newWalletAddress: string) {
    console.log(newWalletAddress);
    setRequestEnabled(false);
    setWalletAddress(newWalletAddress);
  }

  // TODO: Conditionally rendering either HomeComponent, AttestForm or FaucetForm component
  // otherwise it looks ugly af
  return (
    <div>
      <HomeComponent updateWalletCallback={updateWalletAddress}/>
      <button id = "request-btn" disabled = {!requestEnabled}> Request Tokens </button>
    </div>
  )
}

interface HomeProp {
  updateWalletCallback: Function
}

function HomeComponent(prop: HomeProp): JSX.Element {
  let [walletAddress, setWalletAddress] = useState("");
  
  function handleCheckAttestation() {
      prop.updateWalletCallback(walletAddress);
  }

  return (
    <div>
      <p> Welcome To Faucet Demo! </p>
      <p> To begin, please provide your wallet address. </p>
      <input 
        type = "text" 
        id = "wallet-address"
        value = {walletAddress} 
        onChange = {(e) => {
          setWalletAddress(e.target.value)
        }}/>
      <button onClick={handleCheckAttestation}> Check Attestation </button>
    </div>
  )
}

export default App;