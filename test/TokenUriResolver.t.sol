// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenUriResolver, IJBProjects} from "../src/TokenUriResolver.sol";
import {DefaultTokenUriResolver, IJBOperatorStore, IJBDirectory, IJBProjectHandles, ITypeface, IJBTokenUriResolver, JBOperatable, JBUriOperations} from "../src/DefaultTokenUriResolver.sol";
import {JBOperatorData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBOperatorData.sol";

contract ContractTest is Test {
    // DefaultTokenUriResolver constructor args
    IJBOperatorStore public _operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBDirectory public _directory = IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBProjectHandles public _projectHandles = IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public _capsulesTypeface = ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);

    // Additional TokenUriResolver constructor args
    IJBProjects public _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

    DefaultTokenUriResolver d =
        new DefaultTokenUriResolver(_operatorStore, _directory, _projectHandles, _capsulesTypeface);

    TokenUriResolver t = new TokenUriResolver(_projects, _operatorStore, d);

    /*//////////////////////////////////////////////////////////////
                         TOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

    // Tests that the default resolver works correctly
    function testGetDefaultMetadata() external {
        string memory x = t.getUri(1);
        assertTrue(keccak256(abi.encodePacked(x)) != keccak256(abi.encodePacked(string(""))));
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    // Tests that setting a new default resolver works
    function testSetDefaultMetadata() external {
        uint256 projectId = 1;
        // Get the default metadata
        string memory defaultMetadata = t.getUri(projectId);
        // Set a theme on the original resolver
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.setTheme(projectId, "FFFFFF", "000FFF", "000FFF");
        // Create and set a new default resolver
        DefaultTokenUriResolver n = new DefaultTokenUriResolver(
            _operatorStore,
            _directory,
            _projectHandles,
            _capsulesTypeface
        );
        t.setDefaultTokenUriResolver(n);
        assertEq(t.getUri(1), defaultMetadata, "New default metadata does not match");
        // Get metadata from the new resolver
        string memory x = t.getUri(1);
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }

    // Tests that calls to getUri fail when no working resolver is set, and that setting a new default resolver works correctly
    function testGetNoDefaultSet() external {
        TokenUriResolver x = new TokenUriResolver(_projects, _operatorStore, IJBTokenUriResolver(address(uint160(55))));
        vm.expectRevert();
        string memory z = x.getUri(1);
        assertEq(z, "", "Default metadata should be empty");
        DefaultTokenUriResolver y = new DefaultTokenUriResolver(
            _operatorStore,
            _directory,
            _projectHandles,
            _capsulesTypeface
        );
        x.setDefaultTokenUriResolver(y);
        x.getUri(1);
    }

    // Tests that only the TokenUriResolver owner can set the default resolver
    function testSetDefaultTokenUriResolverRequiresOwner() external {
        // Attempt to set default resolver from a non-owner address
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert("Ownable: caller is not the owner");
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
        // Attempt as owner
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
    }

    // Tests that the default resolver cannot be set via the setTokenUriResolverForProject function
    function testSetTokenUriResolverForProjectCannotSetDefaultResolver() external {
        // Attempt to set default resolver via setTokenUriResolverForProject
        vm.expectRevert("ERC721: owner query for nonexistent token");
        // vm.expectRevert(TokenUriResolver.Unauthorized.selector); // Will never reach here because the requirePermission call fails first as there is no project with projectId 0
        t.setTokenUriResolverForProject(0, IJBTokenUriResolver(address(uint160(55))));
    }

    // Tests that addresses that are not owners or operators cannot set a project's custom resolver
    function testSetTokenUriResolverForProjectWithoutPermission(address x) external {
        // Impersonate a valid non-owner address
        vm.assume(x != address(0));
        vm.assume(x != address(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e));
        assumeNoPrecompiles(x, 1);
        vm.prank(x);
        // Attempt to set custom resolver for a project that address doesn't own
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(1, IJBTokenUriResolver(address(uint160(55))));
    }

    // Tests that a project owner can set a custom resolver for their project
    function testSetTokenUriResolverForProjectAsOwner() external {
        // Set a custom resolver for a project as owner
        uint256 projectId = 1;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        t.setTokenUriResolverForProject(projectId, IJBTokenUriResolver(address(uint160(55))));
        // Get the custom resolver for the project
        address x = address(t.tokenUriResolvers(projectId));
        assertEq(x, address(uint160(55)), "Custom resolver does not match");
    }

    // Tests that a project operator can set a custom resolver for their project
    function testSetTokenUriResolverForProjectAsOperator() external {
        // Attempt to set a custom resolver for a project as non-operator, non-owner
        uint256 projectId = 1;
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(projectId, IJBTokenUriResolver(address(uint160(55))));
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        _operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            _operatorStore.hasPermission(
                0x1234567890123456789012345678901234567890,
                0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e,
                projectId,
                JBUriOperations.SET_TOKEN_URI
            ),
            true,
            "Operator should be set"
        );
        // Set a custom resolver for a project as operator
        vm.prank(0x1234567890123456789012345678901234567890);
        t.setTokenUriResolverForProject(1, IJBTokenUriResolver(address(uint160(55))));
        // // Check that the custom resolver for the project was set as expected
        address x = address(t.tokenUriResolvers(1));
        assertEq(x, address(uint160(55)), "Custom resolver does not match");
    }

    // Tests that an operator can only modify the resolver for projects they are operators for, and not other projects owned by the same address
    function testSetTokenUriResolverForProjectAsOperatorCorrectDomainOnly() external {
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        uint256 projectId1 = 273; // https://juicebox.money/v2/p/273
        uint256 projectId2 = 267; // https://juicebox.money/v2/p/267 (owned by the same address at block 16303332)
        address ownerOfTwoProjects = 0x190803C6dF6141a5278844E06420bAa71c622ea4;
        vm.prank(ownerOfTwoProjects); // experiments.daodevinc.eth owns 2 projects
        _operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId1,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            _operatorStore.hasPermission(
                0x1234567890123456789012345678901234567890,
                ownerOfTwoProjects,
                projectId1,
                JBUriOperations.SET_TOKEN_URI
            ),
            true,
            "Operator should be set"
        );
        // Attempt to set a custom resolver for a project as operator, but for a different project
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(projectId2, IJBTokenUriResolver(address(uint160(55))));
    }

    /*//////////////////////////////////////////////////////////////
                     DEFAULTTOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevert_when_non_owner_sets_theme() external {
        uint256 projectId = 1;
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        d.setTheme(projectId, "FFFFFF", "FFFAAA", "FFFAAA");
    }

    // Tests that project owners can set themes on the default resolver and they render correctly when called from the tokenUriResolver.
    function testSetTheme() external {
        uint256 projectId = 1;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.setTheme(projectId, "FFFFFF", "FFFAAA", "FFFAAA");
        string memory x = t.getUri(projectId); // 1, 311, 305, 308, 323
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./open.js";
        inputs[2] = x;
        // bytes memory res = vm.ffi(inputs);
        vm.ffi(inputs);
    }
}
