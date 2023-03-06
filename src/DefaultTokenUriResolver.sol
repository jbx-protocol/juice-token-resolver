//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol";
import {IJBToken, IJBTokenStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenStore.sol";
import {JBFundingCycle} from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycle.sol";
import {IJBPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import {JBTokens} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import {JBCurrencies} from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import {IJBController, IJBDirectory, IJBFundingCycleStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol";
import {IJBOperatorStore} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBOperatorStore.sol";
import {IJBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";
import {IJBSingleTokenPaymentTerminalStore, IJBSingleTokenPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import {JBPayoutRedemptionPaymentTerminal} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBPayoutRedemptionPaymentTerminal.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {IJBProjectHandles} from "@jbx-protocol/project-handles/contracts/interfaces/IJBProjectHandles.sol"; // Needs updating when NPM is renamed to /juice-project-handles
import {JBOperatable} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {Theme} from "./Structs/Theme.sol";
import {Base64} from "base64-sol/base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Font, ITypeface} from "typeface/interfaces/ITypeface.sol";
import "solcolor/src/Color.sol";

contract StringSlicer {
    // This function is in a separate contract so that TokenUriResolver can pass it a string memory and we can still use Array Slices (which only work on calldata)
    function slice(
        string calldata _str,
        uint256 _start,
        uint256 _end
    ) external pure returns (string memory) {
        return string(bytes(_str)[_start:_end]);
    }
}

contract DefaultTokenUriResolver is IJBTokenUriResolver, JBOperatable {
    using Strings for uint256;

    StringSlicer slice = new StringSlicer();

    event Log(string message);
    event ThemeSet(
        uint256 projectId,
        Color textColor,
        Color bgColor,
        Color bgColorDark
    );
    error InvalidTheme();

    IJBFundingCycleStore public immutable fundingCycleStore;
    IJBProjects public immutable projects;
    IJBDirectory public immutable directory;
    IJBTokenStore public immutable tokenStore;
    IJBSingleTokenPaymentTerminalStore
        public immutable singleTokenPaymentTerminalStore;
    IJBController public immutable controller;
    IJBProjectHandles public immutable projectHandles;
    ITypeface public immutable capsulesTypeface; // Capsules typeface
    mapping(uint256 => Theme) public themes;

    constructor(
        IJBOperatorStore _operatorStore,
        IJBDirectory _directory,
        IJBProjectHandles _projectHandles,
        ITypeface _capsulesTypeface
    ) JBOperatable(_operatorStore) {
        directory = _directory;
        projects = directory.projects();
        fundingCycleStore = directory.fundingCycleStore();
        controller = IJBController(directory.controllerOf(1));
        tokenStore = controller.tokenStore();
        singleTokenPaymentTerminalStore = IJBSingleTokenPaymentTerminalStore(
            IJBPayoutRedemptionPaymentTerminal(
                address(
                    IJBPaymentTerminal(
                        directory.primaryTerminalOf(1, JBTokens.ETH)
                    )
                )
            ).store()
        );
        projectHandles = _projectHandles;
        capsulesTypeface = _capsulesTypeface;
        themes[0] = Theme({
            customTheme: false,
            textColor: newColorFromRGBString("FF9213"),
            bgColor: newColorFromRGBString("44190F"),
            bgColorDark: newColorFromRGBString("3A0F0C")
        });
    }

    // @notice Gets the Base64 encoded Capsules-500.otf typeface
    /// @return fontSource The Base64 encoded font file
    function getFontSource() internal view returns (bytes memory fontSource) {
        return
            ITypeface(capsulesTypeface).sourceOf(
                Font({weight: 500, style: "normal"})
            ); // Capsules font source
    }

    /// @notice Transform strings to target length by abbreviation or left padding with spaces.
    /// @dev Shortens long strings to 13 characters including an ellipsis and adds left padding spaces to short strings. Allows variable target length to account for strings that have unicode characters that are longer than 1 byte but only take up 1 character space.
    /// @param left True adds padding to the left of the passed string, and false adds padding to the right
    /// @param str The string to transform
    /// @param targetLength The length of the string to return
    /// @return string The transformed string
    function pad(
        bool left,
        string memory str,
        uint256 targetLength
    ) internal view returns (string memory) {
        uint256 length = bytes(str).length;

        // If string is already target length, return it
        if (length == targetLength) {
            return str;
        }

        // If string is longer than target length, abbreviate it and add an ellipsis
        if (length > targetLength) {
            str = string.concat(
                slice.slice(str, 0, targetLength - 1), // Abbreviate to 1 character less than target length
                unicode"…"
            ); // And add an ellipsis
            return str;
        }

        // If string is shorter than target length, pad it on the left or right as specified
        string memory padding;
        uint256 _paddingToAdd = targetLength - length;
        for (uint256 i; i < _paddingToAdd; ) {
            padding = string.concat(padding, " ");
            unchecked {
                ++i;
            }
        }
        str = left ? string.concat(padding, str) : string.concat(str, padding);
        return str;
    }

    function getProjectName(uint256 _projectId)
        internal
        view
        returns (string memory projectName)
    {
        // Project Handle
        string memory _projectName;
        // If handle is set
        if (
            keccak256(abi.encode(projectHandles.handleOf(_projectId))) !=
            keccak256(abi.encode(string("")))
        ) {
            // Set projectName to handle
            _projectName = string.concat(
                "@",
                projectHandles.handleOf(_projectId)
            );
        } else {
            // Set projectName to name to 'Project #projectId'
            _projectName = string.concat("Project #", _projectId.toString());
        }
        // Abbreviate handle to 27 chars if longer
        if (bytes(_projectName).length > 26) {
            _projectName = string.concat(
                slice.slice(_projectName, 0, 26),
                unicode"…"
            );
        }
        return _projectName;
    }

    function getOverflowString(uint256 _projectId)
        internal
        view
        returns (string memory overflowString)
    {
        uint256 overflow = singleTokenPaymentTerminalStore
            .currentTotalOverflowOf(_projectId, 0, 1); // Project's overflow to 0 decimals
        return string.concat(unicode"Ξ", overflow.toString());
    }

    function getOverflowRow(string memory overflowString)
        internal
        view
        returns (string memory overflowRow)
    {
        string memory paddedOverflowLeft = string.concat(
            pad(true, overflowString, 14),
            "  "
        ); // Length of 14 because Ξ counts as 2 characters, but has character width of 1
        string memory paddedOverflowRight = string.concat(
            pad(false, unicode"  ovᴇʀꜰʟow    ", 21)
        ); //  E = 3, ʀ = 2, ꜰ = 3, ʟ = 2
        return string.concat(paddedOverflowRight, paddedOverflowLeft);
    }

    function getRightPaddedFC(JBFundingCycle memory _fundingCycle)
        internal
        view
        returns (string memory rightPaddedFCString)
    {
        uint256 currentFundingCycleId = _fundingCycle.number; // Project's current funding cycle id
        string memory fundingCycleIdString = currentFundingCycleId.toString();
        return
            pad(false, string.concat(unicode"  ꜰc ", fundingCycleIdString), 17);
    }

    function getLeftPaddedTimeLeft(JBFundingCycle memory _fundingCycle)
        internal
        view
        returns (string memory leftPaddedTimeLeftString)
    {
        // Time Left
        uint256 start = _fundingCycle.start; // Project's funding cycle start time
        uint256 duration = _fundingCycle.duration; // Project's current funding cycle duration
        uint256 timeLeft;
        string memory paddedTimeLeft;
        string memory countString;
        if (duration == 0) {
            paddedTimeLeft = string.concat(
                pad(true, string.concat(unicode" ɴoᴛ sᴇᴛ"), 22),
                "  "
            ); // If the funding cycle has no duration, show infinite duration
        } else {
            timeLeft = start + duration - block.timestamp; // Project's current funding cycle time left
            if (timeLeft > 2 days) {
                countString = (timeLeft / 1 days).toString();
                paddedTimeLeft = string.concat(
                    pad(
                        true,
                        string.concat(
                            unicode"",
                            " ",
                            countString,
                            unicode" ᴅᴀʏs"
                        ),
                        20
                    ),
                    "  "
                );
            } else if (timeLeft > 2 hours) {
                countString = (timeLeft / 1 hours).toString(); // 12 bytes || 8 visual + countString
                paddedTimeLeft = string.concat(
                    pad(
                        true,
                        string.concat(
                            unicode"",
                            " ",
                            countString,
                            unicode" ʜouʀs"
                        ),
                        17
                    ),
                    "  "
                );
            } else if (timeLeft > 2 minutes) {
                countString = (timeLeft / 1 minutes).toString();
                paddedTimeLeft = string.concat(
                    pad(
                        true,
                        string.concat(
                            unicode"",
                            " ",
                            countString,
                            unicode" ᴍɪɴuᴛᴇs"
                        ),
                        23
                    ),
                    "  "
                );
            } else {
                countString = (timeLeft / 1 seconds).toString();
                paddedTimeLeft = string.concat(
                    pad(
                        true,
                        string.concat(
                            unicode"",
                            " ",
                            countString,
                            unicode" sᴇcoɴᴅs"
                        ),
                        20
                    ),
                    "  "
                );
            }
        }
        return paddedTimeLeft;
    }

    function getFCTimeLeftRow(JBFundingCycle memory fundingCycle)
        internal
        view
        returns (string memory fCTimeLeftRow)
    {
        return
            string.concat(
                getRightPaddedFC(fundingCycle),
                getLeftPaddedTimeLeft(fundingCycle)
            );
    }

    function getBalanceRow(
        IJBPaymentTerminal primaryEthPaymentTerminal,
        uint256 _projectId
    ) internal view returns (string memory balanceRow) {
        // Balance
        uint256 balance = singleTokenPaymentTerminalStore.balanceOf(
            IJBSingleTokenPaymentTerminal(address(primaryEthPaymentTerminal)),
            _projectId
        ) / 10**18; // Project's ETH balance //TODO Try/catch
        string memory paddedBalanceLeft = string.concat(
            pad(true, string.concat(unicode"Ξ", balance.toString()), 14),
            "  "
        ); // Project's ETH balance as a string
        string memory paddedBalanceRight = pad(
            false,
            unicode"  ʙᴀʟᴀɴcᴇ     ",
            24
        ); // ʙ = 2,    ᴀ = 3, ʟ = 2, ᴀ = 3, ɴ = 2, E = 3
        return string.concat(paddedBalanceRight, paddedBalanceLeft);
    }

    function getDistributionLimitRow(
        IJBPaymentTerminal primaryEthPaymentTerminal,
        uint256 _projectId
    ) internal view returns (string memory distributionLimitRow) {
        // Distribution Limit
        uint256 latestConfiguration = fundingCycleStore.latestConfigurationOf(
            _projectId
        ); // Get project's current FC  configuration
        string memory distributionLimitCurrency;
        (
            uint256 distributionLimitPreprocessed,
            uint256 distributionLimitCurrencyPreprocessed
        ) = controller.distributionLimitOf(
                _projectId,
                latestConfiguration,
                primaryEthPaymentTerminal,
                JBTokens.ETH
            ); // Project's distribution limit
        if (distributionLimitCurrencyPreprocessed == 1) {
            distributionLimitCurrency = unicode"Ξ";
        } else {
            distributionLimitCurrency = "$";
        }
        string memory distributionLimit = string.concat(
            distributionLimitCurrency,
            (distributionLimitPreprocessed / 10**18).toString()
        ); // Project's distribution limit
        string memory paddedDistributionLimitLeft = string.concat(
            pad(
                true,
                distributionLimit,
                12 + bytes(distributionLimitCurrency).length
            ),
            "  "
        );
        string memory paddedDistributionLimitRight = string.concat(
            pad(false, unicode"  ᴅɪsᴛʀ. ʟɪᴍɪᴛ", 28)
        ); // ᴅ = 3, ɪ = 2, T = 3, ʀ = 2, ʟ = 2, ɪ = 2, ᴍ = 3, ɪ = 2, T = 3
        return
            string.concat(
                paddedDistributionLimitRight,
                paddedDistributionLimitLeft
            );
    }

    function getTotalSupplyRow(uint256 _projectId)
        internal
        view
        returns (string memory totalSupplyRow)
    {
        // Supply
        uint256 totalSupply = tokenStore.totalSupplyOf(_projectId) / 10**18; // Project's token total supply
        string memory paddedTotalSupplyLeft = string.concat(
            pad(true, totalSupply.toString(), 13),
            "  "
        ); // Project's token total supply as a string
        string memory paddedTotalSupplyRight = pad(
            false,
            unicode"  ᴛoᴛᴀʟ suᴘᴘʟʏ",
            28
        );
        return string.concat(paddedTotalSupplyRight, paddedTotalSupplyLeft);
    }

    function setTheme(
        uint256 _projectId,
        string memory _textColor,
        string memory _bgColor,
        string memory _bgColorDark
    )
        external
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            JBUriOperations.SET_TOKEN_URI
        )
    {
        Color textColor = newColorFromRGBString(_textColor);
        Color bgColor = newColorFromRGBString(_bgColor);
        Color bgColorDark = newColorFromRGBString(_bgColorDark);
        themes[_projectId] = Theme(true, textColor, bgColor, bgColorDark);
        emit ThemeSet(_projectId, textColor, bgColor, bgColorDark);
    }

    function getOwnerName(address owner)
        internal
        view
        returns (string memory ownerName)
    {
        return
            string.concat(
                "0x",
                slice.slice(toAsciiString(owner), 0, 4),
                unicode"…",
                slice.slice(toAsciiString(owner), 36, 40)
            ); // Abbreviate owner address
    }

    function getUri(uint256 _projectId)
        external
        view
        override
        returns (string memory tokenUri)
    {
        // Owner & Owner Name
        address owner = projects.ownerOf(_projectId); // Project's owner
        string memory ownerName = getOwnerName(owner);
        string memory projectOwnerPaddedRight = pad(
            false,
            unicode"  ᴘʀoᴊᴇcᴛ owɴᴇʀ",
            28
        );

        // Project Name
        string memory projectName = getProjectName(_projectId);

        // Theme
        Theme memory theme = themes[_projectId].customTheme == true
            ? themes[_projectId]
            : themes[0];

        string memory textColor = LibColor.toString(theme.textColor);
        string memory bgColor = LibColor.toString(theme.bgColor);
        string memory bgColorDark = LibColor.toString(theme.bgColorDark);

        // Funding Cycle
        // FC#
        JBFundingCycle memory fundingCycle = fundingCycleStore.currentOf(
            _projectId
        );

        // Get Project's Primary ETH Terminal
        IJBPaymentTerminal primaryEthPaymentTerminal = directory
            .primaryTerminalOf(_projectId, JBTokens.ETH);

        string[] memory parts = new string[](4);
        parts[0] = string("data:application/json;base64,");
        parts[1] = string(
            abi.encodePacked(
                '{"name":"',
                projectName,
                '", "description":"',
                projectName,
                " is a project on the Juicebox Protocol. It has an overflow of ",
                getOverflowString(_projectId),
                ' ETH.", "image":"data:image/svg+xml;base64,'
            )
        );
        // Each line (row) of the SVG is 30 monospaced characters long
        // The first half of each line (15 chars) is the title
        // The second half of each line (15 chars) is the value
        // The first and last characters on the line are two spaces
        // The first line (head) is an exception.
        bytes memory svg = abi.encodePacked(
            '<svg width="289" height="403" viewBox="0 0 289 403" xmlns="http://www.w3.org/2000/svg"><style>@font-face{font-family:"Capsules-500";src:url(data:font/truetype;charset=utf-8;base64,',
            getFontSource(), // import Capsules typeface
            ');format("opentype");}a,a:visited,a:hover{fill:inherit;text-decoration:none;}text{font-size:16px;fill:#',
            textColor,
            ';font-family:"Capsules-500",monospace;font-weight:500;white-space:pre;}#head text{fill:#',
            bgColor,
            ';}</style><g clip-path="url(#clip0)"><path d="M289 0H0V403H289V0Z" fill="url(#paint0)"/><rect width="289" height="22" fill="#',
            textColor,
            '"/><g id="head"><a href="https://juicebox.money/v2/p/',
            _projectId.toString(),
            '">', // Line 0: Head
            '<text x="16" y="16">',
            projectName,
            '</text></a><a href="https://juicebox.money"><text x="259.25" y="16">',
            unicode"",
            "</text></a></g>"
        );
        svg = abi.encodePacked(
            svg,
            // Line 1: FC + Time left
            '<g filter="url(#filter1)"><text x="0" y="48">',
            getFCTimeLeftRow(fundingCycle),
            "</text>",
            // Line 2: Spacer
            '<text x="0" y="64">',
            unicode"                              ",
            "</text>",
            // Line 3: Balance
            '<text x="0" y="80">',
            getBalanceRow(primaryEthPaymentTerminal, _projectId),
            "</text>",
            // Line 4: Overflow
            '<text x="0" y="96">',
            getOverflowRow(getOverflowString(_projectId)),
            "</text>",
            // Line 5: Distribution Limit
            '<text x="0" y="112">',
            getDistributionLimitRow(primaryEthPaymentTerminal, _projectId),
            "</text>",
            // Line 6: Total Supply
            '<text x="0" y="128">',
            getTotalSupplyRow(_projectId),
            "</text>",
            // Line 7: Project Owner
            '<text x="0" y="144">',
            projectOwnerPaddedRight,
            "  ", // additional spaces hard coded for this line, presumes address is 11 chars long
            '<a href="https://etherscan.io/address/',
            toAsciiString(owner),
            '">',
            ownerName,
            "</a>"
        );
        svg = abi.encodePacked(
            svg,
            '</text></g></g><defs><filter id="filter1" x="-3.36" y="26.04" width="294.539" height="126.12" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feMorphology operator="dilate" radius="1" in="SourceAlpha" result="thicken"/><feGaussianBlur in="thicken" stdDeviation="0.5" result="blurred"/><feFlood flood-color="',
            'rgb(44,44,44)', //TKTKTK
            '" result="glowColor"/><feComposite in="glowColor" in2="blurred" operator="in" result="softGlow_colored"/><feMerge><feMergeNode in="softGlow_colored"/><feMergeNode in="SourceGraphic"/></feMerge></filter><linearGradient id="paint0" x1="0" y1="202" x2="289" y2="202" gradientUnits="userSpaceOnUse"><stop stop-color="#',
            bgColorDark,
            '"/><stop offset="0.119792" stop-color="#',
            bgColor,
            '"/><stop offset="0.848958" stop-color="#',
            bgColor,
            '"/><stop offset="1" stop-color="#',
            bgColorDark,
            '"/></linearGradient><clipPath id="clip0"><rect width="289" height="403" /></clipPath></defs></svg>'
        );
        parts[2] = Base64.encode(svg);
        parts[3] = string('"}'); // Close the JSON object
        string memory uri = string.concat(
            parts[0],
            Base64.encode(abi.encodePacked(parts[1], parts[2], parts[3]))
        );
        return uri;
    }

    // borrowed from https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; ) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
            unchecked {
                ++i;
            }
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
