//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member projectId The id of the project.
 * @member textColor The hex color of the text.
 * @member bgColor The hex color of the background.
 * @member bgColorDark The hex color of the background in dark mode.
 */
struct Theme {
    uint184 projectId;
    bytes3 textColor;
    bytes3 bgColor;
    bytes3 bgColorDark;
}
