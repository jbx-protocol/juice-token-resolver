// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenUriResolver, IJBProjects} from "../src/TokenUriResolver.sol";
import {DefaultTokenUriResolver, Theme, LibColor, Color, newColorFromRGBString, IJBOperatorStore, IJBDirectory, IJBProjectHandles, ITypeface, IJBTokenUriResolver, JBOperatable, JBUriOperations, IJBController, IJBController3_1} from "../src/DefaultTokenUriResolver.sol";
import {JBOperatorData} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBOperatorData.sol";
import {KNOWN_OUTPUT_DIRECTORY_V2_CONTROLLER_V1, KNOWN_OUTPUT_DIRECTORY_V3_CONTROLLER_V1, KNOWN_OUTPUT_DIRECTORY_V3_CONTROLLER_V3_1} from "./KnownOutput.sol";

// Helper contract for tests
contract RevertingResolver is IJBTokenUriResolver {
    function getUri(uint256 _projectId) external view returns (string memory tokenUri) {
        _projectId;
        tokenUri;
        revert();
    }
}

contract ContractTest is Test {
    using LibColor for Color;

    // DefaultTokenUriResolver mainnet constructor args
    IJBOperatorStore public operatorStore = IJBOperatorStore(0x6F3C5afCa0c9eDf3926eF2dDF17c8ae6391afEfb);
    IJBDirectory public directory = IJBDirectory(0x65572FB928b46f9aDB7cfe5A4c41226F636161ea);
    IJBController public controller = IJBController(0xFFdD70C318915879d5192e8a0dcbFcB0285b3C98);
    IJBController3_1 public controller3_1 = IJBController3_1(0x97a5b9D9F0F7cD676B69f584F29048D0Ef4BB59b);
    IJBProjectHandles public projectHandles = IJBProjectHandles(0xE3c01E9Fd2a1dCC6edF0b1058B5757138EF9FfB6);
    ITypeface public capsulesTypeface = ITypeface(0xA77b7D93E79f1E6B4f77FaB29d9ef85733A3D44A);

    // Additional TokenUriResolver mainnet constructor args
    IJBProjects public _projects = IJBProjects(0xD8B4359143eda5B2d763E127Ed27c77addBc47d3);

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    //  Setup vars
    uint256 constant FORK_BLOCK_NUMBER = 16848000; // All tests executed at this block
    string MAINNET_RPC_URL = "MAINNET_RPC_URL";
    uint256 forkId = vm.createSelectFork(vm.envString(MAINNET_RPC_URL), FORK_BLOCK_NUMBER);
    DefaultTokenUriResolver d =
        new DefaultTokenUriResolver(
            operatorStore,
            directory,
            controller,
            controller3_1,
            projectHandles,
            capsulesTypeface
        );
    TokenUriResolver t = new TokenUriResolver(_projects, operatorStore, d);

    /*//////////////////////////////////////////////////////////////
                         TOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

    // Tests that the default resolver returns expected output for a Directory V2 project on Controller V1: basic metadata instructing the owner to upgrade the project.
    function testGetDefaultMetadataDirectoryV2ControllerV1() public {
        // Load known output at block 16848000
        string memory knownOutput = KNOWN_OUTPUT_DIRECTORY_V2_CONTROLLER_V1;

        // Get uri
        string memory output = t.getUri(5); // Project 5 is a Directory V2 project that's very unlikely to be upgraded to DirectoryV3 https://juicebox.money/v2/p/5
        // console.log(output);

        // Check that tokenUri returns something
        assertTrue(keccak256(abi.encodePacked(output)) != keccak256(abi.encodePacked(string(""))));
        
        // Compare hash of known (expected) output and new output
        assertEq(keccak256(abi.encodePacked(knownOutput)), keccak256(abi.encodePacked(output)));
    }

    // Tests that the default resolver returns expected output for a for a Directory V3, Controller 1 project
    function testGetDefaultMetadataDirectoryV3Controller1() public {
        // Load known output at block 16848000
        string memory knownOutput = KNOWN_OUTPUT_DIRECTORY_V3_CONTROLLER_V1; 
        
        // Get uri
        string memory output = t.getUri(313); // Project 313 is a Directory V3 Controller V1 project that's very unlikely to be upgraded to Controller 3.1 https://juicebox.money/v2/p/313
        // console.log(output);
       
        // Check that tokenUri returns something
        assertTrue(keccak256(abi.encodePacked(output)) != keccak256(abi.encodePacked(string(""))));
        
        // Output to file
        // string[] memory inputs = new string[](3);
        // inputs[0] = "node";
        // inputs[1] = "./open.js";
        // inputs[2] = output;
        // vm.ffi(inputs);

        // Compare hash of known (expected) output and new output
        assertEq(keccak256(abi.encodePacked(knownOutput)), keccak256(abi.encodePacked(output)));
    }

    // Tests that the default resolver returns expected output for a for a Directory V2, Controller 3.1 project
    function testGetDefaultMetadataDirectoryV3Controller3_1() public {
        // Load known output at block 16848000
        string memory knownOutput = KNOWN_OUTPUT_DIRECTORY_V3_CONTROLLER_V3_1; 
        
        // Get uri
        string memory output = t.getUri(1);
        // console.log(output);

        // Check that tokenUri returns something
        assertTrue(keccak256(abi.encodePacked(output)) != keccak256(abi.encodePacked(string(""))));
        
        // Output to file
        // string[] memory inputs = new string[](3);
        // inputs[0] = "node";
        // inputs[1] = "./open.js";
        // inputs[2] = output;
        // vm.ffi(inputs);
        
        // Compare hash of known (expected) output and new output
        assertEq(keccak256(abi.encodePacked(knownOutput)), keccak256(abi.encodePacked(output)));
    }

    // Tests that setting a new default resolver works
    function testSetDefaultResolver() public {
        uint256 projectId = 1;
        // Get the default metadata
        string memory defaultMetadata = t.getUri(projectId);
        // Set a custom theme on the original resolver
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.setTheme(projectId, "FFFFFF", "000FFF", "000FFF");
        // Create and set a new default resolver
        DefaultTokenUriResolver n = new DefaultTokenUriResolver(
            operatorStore,
            directory,
            controller,
            controller3_1,
            projectHandles,
            capsulesTypeface
        );
        t.setDefaultTokenUriResolver(n);
        // Check that the new resolver metadata matches the original
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
    function testGetNoDefaultSet() public {
        TokenUriResolver x = new TokenUriResolver(_projects, operatorStore, IJBTokenUriResolver(address(uint160(55))));
        vm.expectRevert();
        string memory z = x.getUri(1);
        assertEq(z, "", "Default metadata should be empty");
        DefaultTokenUriResolver y = new DefaultTokenUriResolver(
            operatorStore,
            directory,
            controller,
            controller3_1,
            projectHandles,
            capsulesTypeface
        );
        x.setDefaultTokenUriResolver(y);
        x.getUri(1);
    }

    // Tests that only the TokenUriResolver owner can set the default resolver
    function testSetDefaultTokenUriResolverRequiresOwner() public {
        // Attempt to set default resolver from a non-owner address
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert("Ownable: caller is not the owner");
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
        // Attempt as owner
        t.setDefaultTokenUriResolver(IJBTokenUriResolver(address(uint160(55))));
        assertEq(address(t.defaultTokenUriResolver()), address(uint160(55)));
    }

    // Tests that the default resolver cannot be set via the setTokenUriResolverForProject function
    function testSetTokenUriResolverForProjectCannotSetDefaultResolver() public {
        // Attempt to set default resolver via setTokenUriResolverForProject
        vm.expectRevert("ERC721: owner query for nonexistent token");
        // vm.expectRevert(TokenUriResolver.Unauthorized.selector); // Will never reach here because the requirePermission call fails first as there is no project with projectId 0
        t.setTokenUriResolverForProject(0, IJBTokenUriResolver(address(uint160(55))));
    }

    // Tests that addresses that are not owners or operators cannot set a project's custom resolver
    function testSetTokenUriResolverForProjectWithoutPermission(address x) public {
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
    function testSetTokenUriResolverForProjectAsOwner() public {
        // Set a custom resolver for a project as owner
        uint256 projectId = 1;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        t.setTokenUriResolverForProject(projectId, IJBTokenUriResolver(address(uint160(55))));
        // Get the custom resolver for the project
        address x = address(t.tokenUriResolvers(projectId));
        assertEq(x, address(uint160(55)), "Custom resolver does not match");
    }

    // Tests that a project operator can set a custom resolver for their project
    function testSetTokenUriResolverForProjectAsOperator() public {
        // Attempt to set a custom resolver for a project as non-operator, non-owner
        uint256 projectId = 1;
        vm.prank(0x1234567890123456789012345678901234567890);
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        t.setTokenUriResolverForProject(projectId, IJBTokenUriResolver(address(uint160(55))));
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            operatorStore.hasPermission(
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
    function testSetTokenUriResolverForProjectAsOperatorCorrectDomainOnly() public {
        // Set an operator
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = JBUriOperations.SET_TOKEN_URI;
        uint256 projectId1 = 273; // https://juicebox.money/v2/p/273
        uint256 projectId2 = 267; // https://juicebox.money/v2/p/267 (owned by the same address at block 16303332)
        address ownerOfTwoProjects = 0x190803C6dF6141a5278844E06420bAa71c622ea4;
        vm.prank(ownerOfTwoProjects); // experiments.daodevinc.eth owns 2 projects
        operatorStore.setOperator(
            JBOperatorData({
                operator: 0x1234567890123456789012345678901234567890,
                domain: projectId1,
                permissionIndexes: indexes
            })
        );
        // Check operator is set
        assertEq(
            operatorStore.hasPermission(
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

    // Test that reverting custom resolver falls back to the default resolver
    function testCustomResolverReverts() public {
        // Get default metadata
        string memory defaultMetadata = t.getUri(1);
        // Set custom resolver that reverts for project 1
        RevertingResolver revertingResolver = new RevertingResolver();
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        t.setTokenUriResolverForProject(1, IJBTokenUriResolver(revertingResolver));
        string memory newMetadata = t.getUri(1);
        // Confirm that it falls back to the default
        assertEq(keccak256(abi.encodePacked(defaultMetadata)), keccak256(abi.encodePacked(newMetadata)));
    }

    /*//////////////////////////////////////////////////////////////
                     DEFAULTTOKENURIRESOLVER TESTS
    //////////////////////////////////////////////////////////////*/

    /// SET THEME
    // Tests that project owners can set themes on the default resolver and they render correctly when called from the tokenUriResolver.
    function testSetTheme() public {
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

    // Test that Theme can be reset by authorized non-owner addresses
    function testSetThemeAuthorized() public {
        uint256 projectId = 1;
        // Give operator to 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        uint256[] memory permissions = new uint[](1);
        permissions[0] = 20;
        JBOperatorData memory data = JBOperatorData({
            operator: address(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045),
            domain: uint256(1),
            permissionIndexes: permissions
        });
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        operatorStore.setOperator(data);
        // Set with operator
        vm.prank(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045); // Newly authorized address
        Theme memory expectedTheme = Theme({
            customTheme: true,
            textColor: newColorFromRGBString("FFFFFF"),
            bgColor: newColorFromRGBString("FFFAAA"),
            bgColorAlt: newColorFromRGBString("FFFAAA")
        });
        d.setTheme(projectId, "FFFFFF", "FFFAAA", "FFFAAA");
        Theme memory newTheme = d.getTheme(projectId);
        // Compare hash of new vs expected Theme
        assertEq(keccak256(abi.encode(newTheme)), keccak256(abi.encode(expectedTheme)));
    }

    function testSetThemeUnauthorized() public {
        uint256 projectId = 1;
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        d.setTheme(projectId, "FFFFFF", "FFFAAA", "FFFAAA");
    }

    /// RESET THEME
    // Test that Theme can be reset by the project creator
    function testResetTheme() public {
        uint256 projectId = 1;
        string memory defaultOutput = t.getUri(projectId);
        testSetTheme();
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        d.resetTheme(projectId);
        string memory resetOutput = t.getUri(projectId);
        assertEq(defaultOutput, resetOutput);
    }

    // Test that Theme can be reset by authorized non-owner addresses
    function testResetThemeAuthorized() public {
        uint256 projectId = 1;
        string memory defaultOutput = t.getUri(projectId);
        testSetTheme();
        // Give operator to 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
        uint256[] memory permissions = new uint[](1);
        permissions[0] = 20;
        JBOperatorData memory data = JBOperatorData({
            operator: address(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045),
            domain: uint256(1),
            permissionIndexes: permissions
        });
        vm.prank(0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e);
        operatorStore.setOperator(data);
        // Reset with operator
        vm.prank(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045); // Newly authorized address
        d.resetTheme(projectId);
        string memory resetOutput = t.getUri(projectId);
        assertEq(defaultOutput, resetOutput);
    }

    // Test that Theme cannot be reset by unauthorized addresses
    function testResetThemeUnauthorized() public {
        uint256 projectId = 1;
        testSetTheme();
        string memory customOutput = t.getUri(projectId);
        vm.prank(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045); // Unauthorized address
        vm.expectRevert(JBOperatable.UNAUTHORIZED.selector);
        d.resetTheme(projectId);
        string memory resetOutput = t.getUri(projectId);
        assertEq(customOutput, resetOutput);
    }
}
