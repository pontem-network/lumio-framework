/// This module provides an interface to burn or collect and redistribute transaction fees.
module aptos_framework::transaction_fee {
    use aptos_framework::coin::{Self, AggregatableCoin, BurnCapability, Coin};
    use aptos_framework::native_coin::NativeCoin;
    use aptos_framework::system_addresses;
    use std::error;
    use std::option;

    friend aptos_framework::block;
    friend aptos_framework::genesis;
    friend aptos_framework::reconfiguration;
    friend aptos_framework::transaction_validation;

    /// Gas fees are already being collected and the struct holding
    /// information about collected amounts is already published.
    const EALREADY_COLLECTING_FEES: u64 = 1;

    /// The burn percentage is out of range [0, 100].
    const EINVALID_BURN_PERCENTAGE: u64 = 3;

    /// Stores burn capability to burn the gas fees.
    struct NativeCoinCapabilities has key {
        burn_cap: BurnCapability<NativeCoin>,
    }

    /// Stores information about the block proposer and the amount of fees
    /// collected when executing the block.
    struct CollectedFeesPerBlock has key {
        amount: AggregatableCoin<NativeCoin>,
        burn_percentage: u8,
    }

    /// Initializes the resource storing information about gas fees collection and
    /// distribution. Should be called by on-chain governance.
    public entry fun initialize_fee_collection_and_distribution(aptos_framework: &signer, burn_percentage: u8) {
        system_addresses::assert_aptos_framework(aptos_framework);
        assert!(
            !exists<CollectedFeesPerBlock>(@aptos_framework),
            error::already_exists(EALREADY_COLLECTING_FEES)
        );
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        // Initially, no fees are collected and the block proposer is not set.
        let collected_fees = CollectedFeesPerBlock {
            amount: coin::initialize_aggregatable_coin(aptos_framework),
            burn_percentage,
        };
        move_to(aptos_framework, collected_fees);
    }

    fun is_fees_collection_enabled(): bool {
        exists<CollectedFeesPerBlock>(@aptos_framework)
    }

    /// Sets the burn percentage for collected fees to a new value. Should be called by on-chain governance.
    public entry fun upgrade_burn_percentage(
        aptos_framework: &signer,
        new_burn_percentage: u8
    ) acquires NativeCoinCapabilities, CollectedFeesPerBlock {
        system_addresses::assert_aptos_framework(aptos_framework);
        assert!(new_burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        // Prior to upgrading the burn percentage, make sure to process collected
        // fees. Otherwise we would use the new (incorrect) burn_percentage when
        // processing fees later!
        process_collected_fees();

        if (is_fees_collection_enabled()) {
            // Upgrade has no effect unless fees are being collected.
            let burn_percentage = &mut borrow_global_mut<CollectedFeesPerBlock>(@aptos_framework).burn_percentage;
            *burn_percentage = new_burn_percentage
        }
    }

    /// Burns a specified fraction of the coin.
    fun burn_coin_fraction(coin: &mut Coin<NativeCoin>, burn_percentage: u8) acquires NativeCoinCapabilities {
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        let collected_amount = coin::value(coin);
        spec {
            // We assume that `burn_percentage * collected_amount` does not overflow.
            assume burn_percentage * collected_amount <= MAX_U64;
        };
        let amount_to_burn = (burn_percentage as u64) * collected_amount / 100;
        if (amount_to_burn > 0) {
            let coin_to_burn = coin::extract(coin, amount_to_burn);
            coin::burn(
                coin_to_burn,
                &borrow_global<NativeCoinCapabilities>(@aptos_framework).burn_cap,
            );
        }
    }

    /// Calculates the fee which should be distributed to the block proposer at the
    /// end of an epoch, and records it in the system. This function can only be called
    /// at the beginning of the block or during reconfiguration.
    public(friend) fun process_collected_fees() acquires NativeCoinCapabilities, CollectedFeesPerBlock {
        if (!is_fees_collection_enabled()) {
            return
        };
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@aptos_framework);

        // If there are no collected fees, only unset the proposer. See the rationale for
        // setting proposer to option::none() below.
        if (coin::is_aggregatable_coin_zero(&collected_fees.amount)) {
            return
        };

        // Otherwise get the collected fee, and check if it can distributed later.
        let coin = coin::drain_aggregatable_coin(&mut collected_fees.amount);
        burn_coin_fraction(&mut coin, collected_fees.burn_percentage);
        coin::deposit(@sequencer, coin);
    }

    /// Burn transaction fees in epilogue.
    public(friend) fun burn_fee(account: address, fee: u64) acquires NativeCoinCapabilities {
        coin::burn_from<NativeCoin>(
            account,
            fee,
            &borrow_global<NativeCoinCapabilities>(@aptos_framework).burn_cap,
        );
    }

    /// Collect transaction fees in epilogue.
    public(friend) fun collect_fee(account: address, fee: u64) acquires CollectedFeesPerBlock {
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@aptos_framework);

        // Here, we are always optimistic and always collect fees. If the proposer is not set,
        // or we cannot redistribute fees later for some reason (e.g. account cannot receive AptoCoin)
        // we burn them all at once. This way we avoid having a check for every transaction epilogue.
        let collected_amount = &mut collected_fees.amount;
        coin::collect_into_aggregatable_coin<NativeCoin>(account, fee, collected_amount);
    }

    /// Only called during genesis.
    public(friend) fun store_native_coin_burn_cap(aptos_framework: &signer, burn_cap: BurnCapability<NativeCoin>) {
        system_addresses::assert_aptos_framework(aptos_framework);
        move_to(aptos_framework, NativeCoinCapabilities { burn_cap })
    }

    #[test_only]
    use aptos_framework::aggregator_factory;

    #[test(aptos_framework = @aptos_framework)]
    fun test_initialize_fee_collection_and_distribution(aptos_framework: signer) acquires CollectedFeesPerBlock {
        aggregator_factory::initialize_aggregator_factory_for_test(&aptos_framework);
        initialize_fee_collection_and_distribution(&aptos_framework, 25);

        // Check struct has been published.
        assert!(exists<CollectedFeesPerBlock>(@aptos_framework), 0);

        // Check that initial balance is 0 and there is no proposer set.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@aptos_framework);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(collected_fees.burn_percentage == 25, 0);
    }

    #[test(aptos_framework = @aptos_framework)]
    fun test_burn_fraction_calculation(aptos_framework: signer) acquires NativeCoinCapabilities {
        use aptos_framework::native_coin;
        let (burn_cap, mint_cap) = native_coin::initialize_for_test(&aptos_framework);
        store_native_coin_burn_cap(&aptos_framework, burn_cap);

        let c1 = coin::mint<NativeCoin>(100, &mint_cap);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 100, 0);

        // Burning 25%.
        burn_coin_fraction(&mut c1, 25);
        assert!(coin::value(&c1) == 75, 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 75, 0);

        // Burning 0%.
        burn_coin_fraction(&mut c1, 0);
        assert!(coin::value(&c1) == 75, 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 75, 0);

        // Burning remaining 100%.
        burn_coin_fraction(&mut c1, 100);
        assert!(coin::value(&c1) == 0, 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 0, 0);

        coin::destroy_zero(c1);
        let c2 = coin::mint<NativeCoin>(10, &mint_cap);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 10, 0);

        burn_coin_fraction(&mut c2, 5);
        assert!(coin::value(&c2) == 10, 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 10, 0);

        burn_coin_fraction(&mut c2, 100);
        coin::destroy_zero(c2);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @aptos_framework, alice = @0xa11ce, bob = @0xb0b, carol = @0xca101)]
    fun test_fees_distribution(
        aptos_framework: signer,
        alice: signer,
        bob: signer,
        carol: signer,
    ) acquires NativeCoinCapabilities, CollectedFeesPerBlock {
        use std::signer;
        use aptos_framework::aptos_account;
        use aptos_framework::native_coin;

        // Initialization.
        let (burn_cap, mint_cap) = native_coin::initialize_for_test(&aptos_framework);
        store_native_coin_burn_cap(&aptos_framework, burn_cap);
        initialize_fee_collection_and_distribution(&aptos_framework, 10);

        aptos_account::create_account(@sequencer);

        // Create dummy accounts.
        let alice_addr = signer::address_of(&alice);
        let bob_addr = signer::address_of(&bob);
        let carol_addr = signer::address_of(&carol);
        aptos_account::create_account(alice_addr);
        aptos_account::create_account(bob_addr);
        aptos_account::create_account(carol_addr);
        coin::deposit(alice_addr, coin::mint(10000, &mint_cap));
        coin::deposit(bob_addr, coin::mint(10000, &mint_cap));
        coin::deposit(carol_addr, coin::mint(10000, &mint_cap));
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 30000, 0);

        // Block 1 starts.
        process_collected_fees();
        // register_proposer_for_fee_collection(alice_addr);

        // Check that there was no fees distribution in the first block.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@aptos_framework);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 30000, 0);

        // Simulate transaction fee collection - here we simply collect some fees from Bob.
        collect_fee(bob_addr, 100);
        collect_fee(bob_addr, 500);
        collect_fee(bob_addr, 400);

        // Now Bob must have 1000 less in his account. Alice and Carol have the same amounts.
        assert!(coin::balance<NativeCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<NativeCoin>(bob_addr) == 9000, 0);
        assert!(coin::balance<NativeCoin>(carol_addr) == 10000, 0);

        // Block 2 starts.
        process_collected_fees();
        // register_proposer_for_fee_collection(bob_addr);

        assert!(coin::balance<NativeCoin>(@sequencer) == 900, 0);

        // Collected fees from Bob must have been assigned to Alice.
        assert!(coin::balance<NativeCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<NativeCoin>(bob_addr) == 9000, 0);
        assert!(coin::balance<NativeCoin>(carol_addr) == 10000, 0);

        // Also, aggregator coin is drained and total supply is slightly changed (10% of 1000 is burnt).
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@aptos_framework);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 29900, 0);

        // Simulate transaction fee collection one more time.
        collect_fee(bob_addr, 5000);
        collect_fee(bob_addr, 4000);

        assert!(coin::balance<NativeCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<NativeCoin>(bob_addr) == 0, 0);
        assert!(coin::balance<NativeCoin>(carol_addr) == 10000, 0);

        // Block 3 starts.
        process_collected_fees();

        assert!(coin::balance<NativeCoin>(@sequencer) == 9000, 0);

        // Collected fees should have been assigned to Bob because he was the peoposer.
        assert!(coin::balance<NativeCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<NativeCoin>(bob_addr) == 0, 0);
        assert!(coin::balance<NativeCoin>(carol_addr) == 10000, 0);

        // Again, aggregator coin is drained and total supply is changed by 10% of 9000.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@aptos_framework);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 29000, 0);

        // Simulate transaction fee collection one last time.
        collect_fee(alice_addr, 1000);
        collect_fee(alice_addr, 1000);

        // Block 4 starts.
        process_collected_fees();

        assert!(coin::balance<NativeCoin>(@sequencer) == 10800, 0);

        // Check that 2000 was collected from Alice.
        assert!(coin::balance<NativeCoin>(alice_addr) == 8000, 0);
        assert!(coin::balance<NativeCoin>(bob_addr) == 0, 0);

        // Carol must have some fees assigned now.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@aptos_framework);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&coin::supply<NativeCoin>()) == 28800, 0);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}
