import { useEffect, useState } from 'react';
import { AttestationComponent } from './components/Attestation';
import { createCredential, triggerJsonDownload } from './modules/webauthn';
import { 
  provider,
  getAttestationId, 
  submitAttestation
} from './modules/relayer';
import './App.css';

const { REACT_APP_ATTESTATION_REGISTRY_ADDRESS } = process.env;

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
                    setAttestationId(log.topics[1]);
                    walletHasValidAttestation = true;
                    let downloadJson = 
                      window.confirm("Your device has been attested successfully. Would you like to download a copy of the attestation data?");
                    if (downloadJson) {
                      triggerJsonDownload(attestationParamObj!);
                    }
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

  return (
    <div>
      <HomeComponent updateWalletCallback={updateWalletAddress}/>
      { requestEnabled &&
        <AttestationComponent 
          walletAddress={walletAddress}
          attestationId={attestationId}
        />
      }
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