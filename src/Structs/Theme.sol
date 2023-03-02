//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member customTheme True for all Themes except the default theme
 * @member textColor The hex color of the text.
 * @member bgColor The hex color of the background.
 * @member bgColorDark The hex color of the background in dark mode.
 */
struct Theme {
    bool customTheme;
    string textColor;
    string bgColor;
    string bgColorDark;
}
