spec lumio_framework::dkg {

    spec module {
        use lumio_framework::chain_status;
        invariant [suspendable] chain_status::is_operating() ==> exists<DKGState>(@lumio_framework);
    }

    spec initialize(lumio_framework: &signer) {
        use std::signer;
        let lumio_framework_addr = signer::address_of(lumio_framework);
        aborts_if lumio_framework_addr != @lumio_framework;
    }

    spec start(
        dealer_epoch: u64,
        randomness_config: RandomnessConfig,
        dealer_validator_set: vector<ValidatorConsensusInfo>,
        target_validator_set: vector<ValidatorConsensusInfo>,
    ) {
        aborts_if !exists<DKGState>(@lumio_framework);
        aborts_if !exists<timestamp::CurrentTimeMicroseconds>(@lumio_framework);
    }

    spec finish(transcript: vector<u8>) {
        use std::option;
        requires exists<DKGState>(@lumio_framework);
        requires option::is_some(global<DKGState>(@lumio_framework).in_progress);
        aborts_if false;
    }

    spec fun has_incomplete_session(): bool {
        if (exists<DKGState>(@lumio_framework)) {
            option::spec_is_some(global<DKGState>(@lumio_framework).in_progress)
        } else {
            false
        }
    }

    spec try_clear_incomplete_session(fx: &signer) {
        use std::signer;
        let addr = signer::address_of(fx);
        aborts_if addr != @lumio_framework;
    }

    spec incomplete_session(): Option<DKGSessionState> {
        aborts_if false;
    }
}
