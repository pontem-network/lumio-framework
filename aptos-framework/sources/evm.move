/// EVM Communication Module
/// This module enables the execution of smart contracts within the EVM-compatible layer of the Layer 2 (L2) infrastructure.
/// Designed as a key component of our L2 solution, this module facilitates seamless interaction with the EVM ecosystem.
/// It acts as a bridge, allowing users and other smart contracts to initiate and execute smart contract functions
/// that reside on the EVM side of the L2 platform. This integration ensures compatibility and extends
/// the functionality of L2 solutions within the diverse Ethereum ecosystem.
module aptos_framework::evm {
    use aptos_framework::account;
    use aptos_framework::system_addresses;

    friend aptos_framework::genesis;

    /// Error message for ethereum address length.
    const EETHEREUM_ADDRESS_LENGTH: u64 = 1;

    /// This struct represents a call event that is emitted as part of the cross-communication
    /// between the MoveVM and the EVM layer. It used in `evm` native function to execute a call.
    struct CallEvent has key {
        /// Ethereum contract address to which the call is directed.
        eth_address: vector<u8>,
        /// Call data to be passed to the EVM contract.
        eth_calldata: vector<u8>,
        /// Move signer address.
        move_address: address,
    }

    /// This struct represents an event stream for interactions with the Ethereum Virtual Machine (EVM)
    /// compatible layer. It is designed to track and manage events that are emitted as part of the
    /// cross-communication between the MoveVM and the EVM layer. The `EvmEventStream` struct
    /// plays a crucial role in maintaining the state and metadata associated with these events.
    struct EvmEventStream has key {
        /// Total number of events emitted to this event stream.
        counter: u64,
        /// A globally unique ID for this event stream.
        guid: aptos_framework::guid::GUID,
    }

    /// Facilitates the execution of a function in an EVM contract from within the current VM environment.
    /// This native function signals the VM to initiate a call to a specified contract in the EVM layer.
    /// It's an integral part of cross-VM communication, enabling interoperability between different blockchain protocols.
    ///
    ///  * `account`: The sender's account, which will be used for authorization and executing the call on the EVM side.
    ///  * `to`: The target EVM contract's address to which the call is directed.
    ///  * `fn_abi`: The ABI signature of the function to be called in the EVM contract, for example, `transfer(address,uint256)`.
    ///  * `event_stream`: The event stream to which the call event will be emitted.
    ///  * `calldata`: The arguments to be passed to the function. This can be a single primitive type or multiple parameters packed in an object.
    native fun evm<T, E>(account: address, to: vector<u8>, fn_abi: vector<u8>, event_stream: &EvmEventStream, calldata: &T);

    /// Enables external entities to initiate a call to an EVM contract.
    ///
    ///  * `account`: The sender's account, which will be used for authorization and executing the call on the EVM side.
    ///  * `to`: The target EVM contract's address to which the call is directed.
    ///  * `fn_abi`: The ABI signature of the function to be called in the EVM contract, for example, `transfer(address,uint256)`.
    ///  * `calldata`: The arguments to be passed to the function. This can be a single primitive type or multiple parameters packed in an object.
    public fun call<T>(account: &signer, to: vector<u8>, fn_abi: vector<u8>, calldata: &T) acquires EvmEventStream {
        let stream_ref = borrow_global_mut<EvmEventStream>(@aptos_framework);
        let eth_address_length = std::vector::length(&to);

        // Check if the address is a valid Ethereum address. 20 is without the 0x prefix.
        assert!(eth_address_length == 20, std::error::invalid_argument(EETHEREUM_ADDRESS_LENGTH));

        evm<T, CallEvent>(std::signer::address_of(account), to, fn_abi, stream_ref, calldata);
        stream_ref.counter = stream_ref.counter + 1;
    }

    /// Only called during genesis to initialize system resources for this module.
    public(friend) fun init_event_stream(aptos_framework: &signer) {
        system_addresses::assert_aptos_framework(aptos_framework);
        move_to(aptos_framework, EvmEventStream {
            counter: 0,
            guid: account::create_guid(aptos_framework),
        });
    }
}
