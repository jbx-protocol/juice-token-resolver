// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {IJBTokenUriResolver, DefaultTokenUriResolver, IJBProjects, IJBProjectHandles, Font, ITypeface, IJBOperatorStore, IJBController, IJBController3_1, IJBDirectory, IJBFundingCycleStore} from "src/DefaultTokenUriResolver.sol";
import {TokenUriResolver} from "src/TokenUriResolver.sol";

contract DeployScript is Script {
    // Mainnet addresses
    IJBOperatorStore public operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBDirectory public directory = IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBController public controller = IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);
    IJBController3_1 public controller3_1 = IJBController3_1(0x97a5b9D9F0F7cD676B69f584F29048D0Ef4BB59b);
    IJBProjectHandles public projectHandles = IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public capsulesTypeface = ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);
    IJBProjects public projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DefaultTokenUriResolver (StringSlicer and LibColor libs autodeployed by forge)
        DefaultTokenUriResolver defaultTokenUriResolver = new DefaultTokenUriResolver(
            operatorStore,
            directory,
            controller,
            controller3_1,
            projectHandles,
            capsulesTypeface
        );

        vm.stopBroadcast();
    }
}
