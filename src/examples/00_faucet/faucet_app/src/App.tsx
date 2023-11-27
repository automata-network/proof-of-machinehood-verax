import { useEffect, useState } from 'react';
import { createCredential } from './modules/webauthn';
import { 
  provider,
  getAttestationId, 
  submitAttestation, 
  submitFaucetRequest 
} from './modules/relayer';
import './App.css';

const REACT_APP_ATTESTATION_REGISTRY_ADDRESS = '0x3de3893aa4Cdea029e84e75223a152FD08315138';

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
  let [attestationId, setAttestationId] = useState("");

  let fetchedAttestationId = "";

  useEffect(() => {
    if (walletAddress.length > 0) {
      let walletHasValidAttestation = requestEnabled;
      const attest = async() => {
        while (!walletHasValidAttestation) {
          let beginAttesting = window.confirm("You must provide an attestation for this wallet before proceeding.");
          if (beginAttesting) {
            console.log("begin attesting...");
            try {
              console.log("Getting credentials...");
              const attestationParamObj = await createCredential(walletAddress);
              console.log("Submitting attestations...");
              const tx = await submitAttestation(walletAddress, attestationParamObj!);
              if (tx.error) {
                throw new Error(tx.error);
              }
              let txReceipt;
              while (!txReceipt) {
                txReceipt = await provider.getTransactionReceipt(tx.hash as string);
              }
              const logs = txReceipt.logs;
              for (let log of logs) {
                  const expectedTopic = '0xfe10586889e06530420fe4a0d86aa4f7afc3c9dc84b0c77b731a9615496ef18a';
                  const expectedAddress = REACT_APP_ATTESTATION_REGISTRY_ADDRESS;
                  if (log.address === expectedAddress && log.topics[0] === expectedTopic) {
                    console.log("Attestation found!");
                    fetchedAttestationId = log.topics[1];
                    setAttestationId(fetchedAttestationId);
                    walletHasValidAttestation = true;
                  }
              }
            } catch (e) {
              console.log(e);
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
        if (walletHasValidAttestation) {
          const outputId = fetchedAttestationId.length > 0 ? fetchedAttestationId : attestationId;
          alert(`The provided wallet has a valid attestation ID: ${outputId}`);
        }
        setRequestEnabled(walletHasValidAttestation);
      });
    }
  }, [walletAddress]);

  function updateWalletAddress(newWalletAddress: string) {
    if (newWalletAddress.length === 0) {
      alert("Am I a joke to you?");
    } else {
      getAttestationId(newWalletAddress).then((attestation) => {
        setRequestEnabled(attestation.status);
        setAttestationId(attestation.id as string);
        setWalletAddress(newWalletAddress);
      })
    }
  }

  function handleRequestTokens() {
    submitFaucetRequest(walletAddress).then((tx) => {
      console.log(tx.hash);
      alert("Tokens are coming your way! :)");
    }).catch(e => {
      console.log(e);
      alert("Failed to request tokens");
    })
  }  

  // TODO: Conditionally rendering either HomeComponent, AttestForm or FaucetForm component
  // otherwise it looks ugly af
  return (
    <div>
      <HomeComponent updateWalletCallback={updateWalletAddress}/>
      <button 
        id = "request-btn" 
        disabled = {!requestEnabled} 
        onClick={handleRequestTokens}
      > Request Tokens </button>
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