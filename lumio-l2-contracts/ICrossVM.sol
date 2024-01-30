// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title ICrossVM Interface
/// @notice Interface for integrating Solidity contracts with MoveVM contracts.
/// @dev This interface defines the standard functions for Solidity contracts to interact with contracts
///      deployed in the MoveVM environment. It facilitates cross-contract communication and operations
///      between Solidity and MoveVM, broadening the scope of possible applications and functionalities.
interface ICrossVM {
    /// @notice Emitted when a call is made to a VM, enabling VMs to capture the event and execute the corresponding call.
    /// @dev This event logs critical information needed for VMs to process and execute calls, including
    ///      sender address, module address, module ID, function ID, call data, and any generic parameters.
    ///      It serves as a bridge for communication between different VMs, facilitating interoperability in a
    ///      multi-VM environment.
    event Call(address sender, bytes moduleAddress, bytes moduleId, bytes functionId, bytes callData, bytes generics);

    /// @notice Executes a call to a specified virtual machine (Move VM), targeting a specific module and function.
    ///         The `msg.sender` is used as the initiator of the call.
    /// @dev This function facilitates interaction between Solidity contracts and modules deployed in a Move VM.
    ///      It encodes the call data for compatibility with Move VM standards and handles the complexities
    ///      of cross-VM communications.
    /// @param _moduleAddress The hexadecimal address of the module in the Move VM to which the call is directed.
    ///                       Example: `0x1` for a core module in Move VM.
    /// @param _moduleId The identifier of the module within the Move VM. For instance, `coin` for a module handling
    ///                  cryptocurrency operations.
    /// @param _functionId The identifier of the function within the specified module to be called, e.g. `transfer`.
    /// @param _callData ABI-encoded data to be passed to the function. This data should be formatted according
    ///                  to the requirements of the target function and should only include supported primitive types.
    /// @param _generics A list of fully qualified paths of any generics involved in the function call.
    ///                  Use the format `module_path::module_name::GenericType` for single generics.
    ///                  For multiple generics, separate them with commas and detail nested generics where necessary.
    function call(
        bytes calldata _moduleAddress,
        bytes calldata _moduleId,
        bytes calldata _functionId,
        bytes calldata _callData,
        bytes calldata _generics
    ) external;
}
