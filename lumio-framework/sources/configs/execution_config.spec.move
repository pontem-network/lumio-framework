spec lumio_framework::execution_config {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;
    }

    /// Ensure the caller is admin
    /// When setting now time must be later than last_reconfiguration_time.
    spec set(account: &signer, config: vector<u8>) {
        use lumio_framework::timestamp;
        use std::signer;
        use std::features;
        use lumio_framework::chain_status;
        use lumio_framework::staking_config;
        use lumio_framework::lumio_coin;

        // TODO: set because of timeout (property proved)
        pragma verify_duration_estimate = 600;
        let addr = signer::address_of(account);
        requires chain_status::is_genesis();
        requires exists<staking_config::StakingRewardsConfig>(@lumio_framework);
        requires len(config) > 0;
        include features::spec_periodical_reward_rate_decrease_enabled() ==> staking_config::StakingRewardsConfigEnabledRequirement;
        include lumio_coin::ExistsLumioCoin;
        requires system_addresses::is_lumio_framework_address(addr);
        requires timestamp::spec_now_microseconds() >= reconfiguration::last_reconfiguration_time();

        ensures exists<ExecutionConfig>(@lumio_framework);
    }

    spec set_for_next_epoch(account: &signer, config: vector<u8>) {
        include config_buffer::SetForNextEpochAbortsIf;
    }

    spec on_new_epoch(framework: &signer) {
        requires @lumio_framework == std::signer::address_of(framework);
        include config_buffer::OnNewEpochRequirement<ExecutionConfig>;
        aborts_if false;
    }
}
