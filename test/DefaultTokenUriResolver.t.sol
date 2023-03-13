// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenUriResolver} from "../src/TokenUriResolver.sol";
import "../src/DefaultTokenUriResolver.sol";

// import "juice-project-handles/interfaces/IJBProjectHandles.sol";
// import "base64/base64.sol";

contract ContractTest is Test {
    IJBFundingCycleStore public fundingCycleStore =
        IJBFundingCycleStore(0x6f18cF9173136c0B5A6eBF45f19D58d3ff2E17e6);
    IJBProjects public projects =
        IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);
    IJBDirectory public directory =
        IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBTokenStore public tokenStore =
        IJBTokenStore(0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7);
    IJBSingleTokenPaymentTerminalStore public singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(
            0xdF7Ca703225c5da79A86E08E03A206c267B7470C
        );
    IJBController public controller =
        IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);
    IJBOperatorStore public operatorStore =
        IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBProjectHandles public projectHandles =
        IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public capsulesTypeface =
        ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);

    DefaultTokenUriResolver d =
        new DefaultTokenUriResolver(
            operatorStore,
            directory,
            projectHandles,
            capsulesTypeface
        );
}
