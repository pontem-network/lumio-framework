
<a name="0x1_evm"></a>

# Module `0x1::evm`

EVM Communication Module
This module enables the execution of smart contracts within the EVM-compatible layer of the Layer 2 (L2) infrastructure.
Designed as a key component of our L2 solution, this module facilitates seamless interaction with the EVM ecosystem.
It acts as a bridge, allowing users and other smart contracts to initiate and execute smart contract functions
that reside on the EVM side of the L2 platform. This integration ensures compatibility and extends
the functionality of L2 solutions within the diverse Ethereum ecosystem.


-  [Resource `CallEvent`](#0x1_evm_CallEvent)
-  [Resource `EvmEventStream`](#0x1_evm_EvmEventStream)
-  [Constants](#@Constants_0)
-  [Function `evm`](#0x1_evm_evm)
-  [Function `call`](#0x1_evm_call)
-  [Function `init_event_stream`](#0x1_evm_init_event_stream)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="guid.md#0x1_guid">0x1::guid</a>;
<b>use</b> <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/signer.md#0x1_signer">0x1::signer</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
</code></pre>



<a name="0x1_evm_CallEvent"></a>

## Resource `CallEvent`

This struct represents a call event that is emitted as part of the cross-communication
between the MoveVM and the EVM layer. It used in <code><a href="evm.md#0x1_evm">evm</a></code> native function to execute a call.


<pre><code><b>struct</b> <a href="evm.md#0x1_evm_CallEvent">CallEvent</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>eth_address: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>
 Ethereum contract address to which the call is directed.
</dd>
<dt>
<code>eth_calldata: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>
 Call data to be passed to the EVM contract.
</dd>
<dt>
<code>move_address: <b>address</b></code>
</dt>
<dd>
 Move signer address.
</dd>
</dl>


</details>

<a name="0x1_evm_EvmEventStream"></a>

## Resource `EvmEventStream`

This struct represents an event stream for interactions with the Ethereum Virtual Machine (EVM)
compatible layer. It is designed to track and manage events that are emitted as part of the
cross-communication between the MoveVM and the EVM layer. The <code><a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a></code> struct
plays a crucial role in maintaining the state and metadata associated with these events.


<pre><code><b>struct</b> <a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>counter: u64</code>
</dt>
<dd>
 Total number of events emitted to this event stream.
</dd>
<dt>
<code><a href="guid.md#0x1_guid">guid</a>: <a href="guid.md#0x1_guid_GUID">guid::GUID</a></code>
</dt>
<dd>
 A globally unique ID for this event stream.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1_evm_EETHEREUM_ADDRESS_LENGTH"></a>

Error message for ethereum address length.


<pre><code><b>const</b> <a href="evm.md#0x1_evm_EETHEREUM_ADDRESS_LENGTH">EETHEREUM_ADDRESS_LENGTH</a>: u64 = 1;
</code></pre>



<a name="0x1_evm_evm"></a>

## Function `evm`

Facilitates the execution of a function in an EVM contract from within the current VM environment.
This native function signals the VM to initiate a call to a specified contract in the EVM layer.
It's an integral part of cross-VM communication, enabling interoperability between different blockchain protocols.

* <code><a href="account.md#0x1_account">account</a></code>: The sender's account, which will be used for authorization and executing the call on the EVM side.
* <code><b>to</b></code>: The target EVM contract's address to which the call is directed.
* <code>fn_abi</code>: The ABI signature of the function to be called in the EVM contract, for example, <code>transfer(<b>address</b>,uint256)</code>.
* <code>event_stream</code>: The event stream to which the call event will be emitted.
* <code>calldata</code>: The arguments to be passed to the function. This can be a single primitive type or multiple parameters packed in an object.


<pre><code><b>fun</b> <a href="evm.md#0x1_evm">evm</a>&lt;T, E&gt;(<a href="account.md#0x1_account">account</a>: <b>address</b>, <b>to</b>: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fn_abi: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, event_stream: &<a href="evm.md#0x1_evm_EvmEventStream">evm::EvmEventStream</a>, calldata: &T)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>native</b> <b>fun</b> <a href="evm.md#0x1_evm">evm</a>&lt;T, E&gt;(<a href="account.md#0x1_account">account</a>: <b>address</b>, <b>to</b>: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fn_abi: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, event_stream: &<a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a>, calldata: &T);
</code></pre>



</details>

<a name="0x1_evm_call"></a>

## Function `call`

Enables external entities to initiate a call to an EVM contract.

* <code><a href="account.md#0x1_account">account</a></code>: The sender's account, which will be used for authorization and executing the call on the EVM side.
* <code><b>to</b></code>: The target EVM contract's address to which the call is directed.
* <code>fn_abi</code>: The ABI signature of the function to be called in the EVM contract, for example, <code>transfer(<b>address</b>,uint256)</code>.
* <code>calldata</code>: The arguments to be passed to the function. This can be a single primitive type or multiple parameters packed in an object.


<pre><code><b>public</b> <b>fun</b> <a href="evm.md#0x1_evm_call">call</a>&lt;T&gt;(<a href="account.md#0x1_account">account</a>: &<a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fn_abi: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, calldata: &T)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="evm.md#0x1_evm_call">call</a>&lt;T&gt;(<a href="account.md#0x1_account">account</a>: &<a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>, <b>to</b>: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fn_abi: <a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, calldata: &T) <b>acquires</b> <a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a> {
    <b>let</b> stream_ref = <b>borrow_global_mut</b>&lt;<a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a>&gt;(@aptos_framework);
    <b>let</b> eth_address_length = std::vector::length(&<b>to</b>);

    // Check <b>if</b> the <b>address</b> is a valid Ethereum <b>address</b>. 20 is without the 0x prefix.
    <b>assert</b>!(eth_address_length == 20, std::error::invalid_argument(<a href="evm.md#0x1_evm_EETHEREUM_ADDRESS_LENGTH">EETHEREUM_ADDRESS_LENGTH</a>));

    <a href="evm.md#0x1_evm">evm</a>&lt;T, <a href="evm.md#0x1_evm_CallEvent">CallEvent</a>&gt;(std::signer::address_of(<a href="account.md#0x1_account">account</a>), <b>to</b>, fn_abi, stream_ref, calldata);
    stream_ref.counter = stream_ref.counter + 1;
}
</code></pre>



</details>

<a name="0x1_evm_init_event_stream"></a>

## Function `init_event_stream`

Only called during genesis to initialize system resources for this module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="evm.md#0x1_evm_init_event_stream">init_event_stream</a>(aptos_framework: &<a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="evm.md#0x1_evm_init_event_stream">init_event_stream</a>(aptos_framework: &<a href="../../../../../../../aptos-stdlib/../move-stdlib/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_aptos_framework">system_addresses::assert_aptos_framework</a>(aptos_framework);
    <b>move_to</b>(aptos_framework, <a href="evm.md#0x1_evm_EvmEventStream">EvmEventStream</a> {
        counter: 0,
        <a href="guid.md#0x1_guid">guid</a>: <a href="account.md#0x1_account_create_guid">account::create_guid</a>(aptos_framework),
    });
}
</code></pre>



</details>


[move-book]: https://aptos.dev/move/book/SUMMARY
