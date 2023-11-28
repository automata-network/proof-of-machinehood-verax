# Faucet Demo With Proof of Machinehood On Verax

There are three components that we need to set up in our testing envrionment before we can begin interacting with the demo.


## Setting Up Local Anvil Fork

You must complete all steps described in the root [`README.md`](../../../README.md#for-developers-test-it-out-on-your-machine) before continuing.

Step 0: Make sure that you are on the current directory.

```bash
cd src/examples/00_faucet
```

> ℹ️ **NOTE** 
>
> Please make sure that the deployed addresses match with the addresses provided in `.env`.

Step 1: Deploy the `SigVerifyLib` and `DerParser` libraries.

```bash
./scripts/setup-lib.sh
```

Step 2: Deploy [`proof-of-machinehood-contracts`](https://github.com/automata-network/proof-of-machinehood-contracts)

```bash
./scripts/setup-pom.sh
```

Step 3: Deploy the Faucet and MockERC20 contracts

```bash
./scripts/deploy-faucet.sh
```

Step 4: Configure `MachinehoodModule` to link with the POM contracts

```bash
./scripts/configure-module.sh
```

The local fork is ready for the demo.


## Setting up the UI and the Relayer

Step 1: `cd` into the `faucet_app` directory

```bash
cd faucet_app
```

Step 2: Make a copy of `.env` using the exmaple provided, then make sure the addresses provided match with your deployment.

```bash
cp .env.example .env
```

Step 3: Install the dependencies

```bash
yarn install
```

Step 4: Start the Relayer

```bash
yarn serve
```

Step 5: Open up another Terminal, then start React

```bash
yarn start
```

Congrats! The demo is now ready at http://localhost:3000/ Have fun! :)