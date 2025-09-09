// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title OffsetInt Library
/// @notice Simulates signed integers using uint with an offset.
/// @dev Stores values as uint to remain compatible with unsigned storage,
///      while providing signed math behavior via offset adjustment.
library OffsetInt {
    /// @dev Internal offset used to simulate signed integers
    uint constant OFFSET = 1e18;

    /// @notice Struct representing an offset-based signed integer
    struct Int {
        uint raw; // Stored as: int value + OFFSET
    }

    /// @notice Converts a signed integer into the offset-based format
    /// @param x The signed integer to convert
    /// @return OffsetInt.Int struct representing the value
    function fromInt(int x) internal pure returns (Int memory) {
        return Int(uint(int(OFFSET) + x));
    }

    /// @notice Converts an offset-based integer back to signed int
    /// @param x The offset-based struct
    /// @return Signed int value
    function toInt(Int memory x) internal pure returns (int) {
        return int(x.raw) - int(OFFSET);
    }

    /// @notice Adds a signed value to an offset-based integer
    /// @param a The original offset-based value
    /// @param b The signed value to add
    /// @return New offset-based result after addition
    function add(Int memory a, int b) internal pure returns (Int memory) {
        return fromInt(toInt(a) + b);
    }

    /// @notice Subtracts a signed value from an offset-based integer
    /// @param a The original offset-based value
    /// @param b The signed value to subtract
    /// @return New offset-based result after subtraction
    function sub(Int memory a, int b) internal pure returns (Int memory) {
        return fromInt(toInt(a) - b);
    }

    /// @notice Compares if one offset-based int is greater than another
    /// @param a First value
    /// @param b Second value
    /// @return True if a > b
    function gt(Int memory a, Int memory b) internal pure returns (bool) {
        return toInt(a) > toInt(b);
    }

    /// @notice Compares if one offset-based int is less than another
    /// @param a First value
    /// @param b Second value
    /// @return True if a < b
    function lt(Int memory a, Int memory b) internal pure returns (bool) {
        return toInt(a) < toInt(b);
    }

    /// @notice Checks if two offset-based values are equal
    /// @param a First value
    /// @param b Second value
    /// @return True if a == b
    function eq(Int memory a, Int memory b) internal pure returns (bool) {
        return toInt(a) == toInt(b);
    }
}