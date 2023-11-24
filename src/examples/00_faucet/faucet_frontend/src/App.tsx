import React, { useState } from 'react';
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

  function updateWalletAddress(newWalletAddress: string) {
    console.log(newWalletAddress);

    // TODO: check if wallet address has made a valid attestation on chain
    let walletHasValidAttestation = false;
    setRequestEnabled(walletHasValidAttestation);

    while (!walletHasValidAttestation) {
      let beginAttesting = window.confirm("You must provide an attestation for this wallet before proceeding.");
      if (beginAttesting) {
        console.log("begin attesting...");
        setRequestEnabled(true);
      } else {
        console.log("Cancelled...");
        break;
      }
    }
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
  
  function handleSubmit() {
      setWalletAddress(walletAddress);
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
      <button onClick={handleSubmit}> Submit </button>
    </div>
  )
}

export default App;