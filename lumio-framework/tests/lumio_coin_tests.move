#[test_only]
module lumio_framework::lumio_coin_tests {
    use lumio_framework::lumio_coin;
    use lumio_framework::coin;
    use lumio_framework::fungible_asset::{Self, FungibleStore, Metadata};
    use lumio_framework::primary_fungible_store;
    use lumio_framework::object::{Self, Object};

    public fun mint_apt_fa_to_for_test<T: key>(store: Object<T>, amount: u64) {
        fungible_asset::deposit(store, lumio_coin::mint_apt_fa_for_test(amount));
    }

    public fun mint_apt_fa_to_primary_fungible_store_for_test(
        owner: address,
        amount: u64,
    ) {
        primary_fungible_store::deposit(owner, lumio_coin::mint_apt_fa_for_test(amount));
    }

    #[test(lumio_framework = @lumio_framework)]
    fun test_apt_setup_and_mint(lumio_framework: &signer) {
        let (burn_cap, mint_cap) = lumio_coin::initialize_for_test(lumio_framework);
        let coin = coin::mint(100, &mint_cap);
        let fa = coin::coin_to_fungible_asset(coin);
        primary_fungible_store::deposit(@lumio_framework, fa);
        assert!(
            primary_fungible_store::balance(
                @lumio_framework,
                object::address_to_object<Metadata>(@lumio_fungible_asset)
            ) == 100,
            0
        );
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);
    }

    #[test]
    fun test_fa_helpers_for_test() {
        assert!(!object::object_exists<Metadata>(@lumio_fungible_asset), 0);
        lumio_coin::ensure_initialized_with_apt_fa_metadata_for_test();
        assert!(object::object_exists<Metadata>(@lumio_fungible_asset), 0);
        mint_apt_fa_to_primary_fungible_store_for_test(@lumio_framework, 100);
        let metadata = object::address_to_object<Metadata>(@lumio_fungible_asset);
        assert!(primary_fungible_store::balance(@lumio_framework, metadata) == 100, 0);
        let store_addr = primary_fungible_store::primary_store_address(@lumio_framework, metadata);
        mint_apt_fa_to_for_test(object::address_to_object<FungibleStore>(store_addr), 100);
        assert!(primary_fungible_store::balance(@lumio_framework, metadata) == 200, 0);
    }
}
