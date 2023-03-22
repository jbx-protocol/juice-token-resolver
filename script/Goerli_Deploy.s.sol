// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import { IJBTokenUriResolver, DefaultTokenUriResolver,IJBProjects, IJBProjectHandles, Font, ITypeface, IJBOperatorStore, IJBController, IJBController3_1, IJBDirectory, IJBFundingCycleStore} from "src/DefaultTokenUriResolver.sol";
import {TokenUriResolver} from "src/TokenUriResolver.sol";

contract DeployScript is Script {

    // Goerli addresses
    IJBOperatorStore public operatorStore = IJBOperatorStore(0x99dB6b517683237dE9C494bbd17861f3608F3585);
    IJBDirectory public directory = IJBDirectory(0x8E05bcD2812E1449f0EC3aE24E2C395F533d9A99);
    IJBController public controller = IJBController(0x7Cb86D43B665196BC719b6974D320bf674AFb395);
    IJBController3_1 public controller3_1 = IJBController3_1(0x1d260DE91233e650F136Bf35f8A4ea1F2b68aDB6);
    IJBProjectHandles public projectHandles = IJBProjectHandles(0x3ff1f0583a41CE8B9463F74a1227C75FC13f7C27);
    ITypeface public capsulesTypeface = ITypeface(0x8Df17136B20DA6D1E23dB2DCdA8D20Aa4ebDcda7);
    IJBProjects public projects = IJBProjects(0x8E05bcD2812E1449f0EC3aE24E2C395F533d9A99);

    // function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        
        // Deploy DefaultTokenUriResolver
        // StringSlicer and LibColor autodeployed by forge
        DefaultTokenUriResolver defaultTokenUriResolver = new DefaultTokenUriResolver(
            operatorStore,
            directory,
            controller,
            controller3_1,
            projectHandles,
            capsulesTypeface
        );

        // Deploy TokenUriResolver
        TokenUriResolver tokenUriResolver = new TokenUriResolver(projects, operatorStore, IJBTokenUriResolver(defaultTokenUriResolver));

        vm.stopBroadcast();
    }
}