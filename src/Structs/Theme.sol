//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Color} from "solcolor/src/Types.sol";

/**
 * @member customTheme True for all Themes except the default theme
 * @member textColor The hex color of the text.
 * @member bgColor The hex color of the background.
 * @member bgColorDark The hex color of the background in dark mode.
 */
struct Theme {
    bool customTheme;
    Color textColor;
    Color bgColor;
    Color bgColorDark;
}
