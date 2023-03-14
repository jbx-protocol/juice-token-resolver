# Juicebox Token Resolver

Creates onchain SVG Metadata for all v2 Juicebox projects.

## Getting started

This repo relies on Mainnet forking for its tests. This approach allows tests to surface real chain data, and avoids the need to redeploy the entire Juicebox protocol, Juicebox Project Handles, and ENS protocol, as well as instantiating projects, .eth addresses, and handles, before running its own test. The tradeoff is that you need access to an RPC to test the repo.

⚠️ Security note ⚠️ This repo's tests use forge's `ffi` to save SVG images to disk and open them in your default SVG reader (usually the browser). This rendering approach means that malicious updates to this repo, or forks thereof, could allow Node to execute code on your system with filesystem access, and open files in your browser or other applications. Please be careful to check that no malicious changes have been introduced to the code before running tests. This code is provided as-is with no guarantee or warranty. 

### Installation

1. `git clone` this repo.
2. Install [Foundry](https://book.getfoundry.sh/getting-started/installation.html), or update Foundry with `foundryup`.
3. `cd` into the directory and call `forge install && yarn install` to install dependencies.
4. You will need an ETH RPC API key to fork mainnet in tests. You can acquire a free API key from Infura, Alchemy, and other providers listed on https://ethereumnodes.com/.

## Testing

### Run all tests

Run `forge test --fork-url $ETH_RPC_URL -v --ffi`, replacing `$ETH_RPC_URL` with your own RPC provider and API key. An RPC url might look like `https://mainnet.infura.io/v3/xyzabc123xyzabc123xyzabc123`.

If you append `--fork-block-number BLOCK_NUMBER` to the above, replacing `BLOCK_NUMBER` with a recent block height, Forge will cache the fork and the tests will run faster. Do not be surprised if values don't change when you set a new project handle onchain.

### Test *only* the default SVG output

This test generates the default SVG to `src/onchain.svg`.

Run `forge test --fork-url $ETH_RPC_URL -v --ffi --match-test Get`

## Deploying

Note: Update `foundry.toml`'s `solc` reference as needed.

### Goerli
Run the following commands sequentially. You'll need to replace values marked with `$` and `<DEPLOYED_ADDRESS>`, and update the `constructor-args` files with addresses that correspond to your deployment — specifically the last constructor arg for both DefaultTokenUriResolver and TokenUriResolver.

#### StringSlicer
`forge create --rpc-url $GOERLI_RPC_URL --private-key $GOERLI_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify src/Libraries/StringSlicer.sol:StringSlicer`

#### LibColor
`forge create --rpc-url $GOERLI_RPC_URL --private-key $GOERLI_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify lib/solcolor/src/Color.sol:LibColor`

#### DefaultTokenUriResolver
Update `foundry.toml`'s `libraries` key with the deployment addresses returned when you deployed StringSlicer and LibColor in the last two steps.

`forge create --rpc-url $GOERLI_RPC_URL --constructor-args-path constructor-args/DefaultTokenUriResolver/goerli_constructor_args --libraries src/Libraries/StringSlicer.sol:StringSlicer:<DEPLOYED_ADDRESS> --private-key $GOERLI_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify src/DefaultTokenUriResolver.sol:DefaultTokenUriResolver`

#### TokenUriResolver (untested)
Update the third address in `/constructor-args/tokenUriResolver/goerli_constructor_args` to the DefaultTokenUriResolver deployed in the previous step.

`forge create --rpc-url $GOERLI_RPC_URL --constructor-args-path constructor-args/TokenUriResolver/goerli_constructor_args --private-key $GOERLI_PRIV_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify src/TokenUriResolver.sol:TokenUriResolver`

## Example output

![](src/onchain.svg)

## Default Resolver

Each row of the output SVG is 30 characters long. The Capsules typeface is monospaced, so as long as each row is composed of 30 characters, it will fit the image perfectly. Each row begins and ends with two space characters for visual symmetry. 

Unicode and small cap characters are used to enhance aesthetics of the output SVG. These characters are sometimes composed of multiple bytes. For example, wile the character `L` [is one byte](https://mothereff.in/byte-counter#L), the small cap `ʟ` [is two bytes](https://mothereff.in/byte-counter#%CA%9F). The version of the Capsules typeface that was stored on Ethereum did not include intelligent small caps assignment, and so we are forced to use manually specify the small caps variant. 

String length is calculated onchain using `bytes(string).length`. As a result, naively counting each byte as a single display character would fail for unicode and small caps, which may constitute more bytes, but only one monospaced visual character output. Thus calls to the `pad` function rely on passing desired `targetLength` values. If we're drawing the left side of a row, we might concatenate a string composed of two spaces with a right-padded string of 13 characters. If the string has no special characters, then we can simply call `pad(false, "L", 13)`, but if the string contains a special character, we'll have to add the number of extra bytes needed to represent it to the third argument: `pad (false, "ʟ", 14)`.

## Additional resources 
- Useful byte length checker https://mothereff.in/byte-counter

## Credits
This project would not have been possible without the following contributions. Thank you! 

- [Capsules](https://cpsls.app/) is an onchain typeface by [Peripheralist](https://github.com/peripheralist/typeface).
- The `ffi` script and `open.js` was developed by [Jeton Connu](https://github.com/jeton-connu).
- [Dr.Gorilla](https://github.com/drgorillamd) provided devops support during the development of this project.
- [Jango](https://github.com/mejango) and the Juicebox Contract Crew created the Juicebox protocol.