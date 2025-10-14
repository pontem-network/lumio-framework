/// Define the GovernanceProposal that will be used as part of on-chain governance by LumioGovernance.
///
/// This is separate from the LumioGovernance module to avoid circular dependency between LumioGovernance and Stake.
module lumio_framework::governance_proposal {
    friend lumio_framework::lumio_governance;

    struct GovernanceProposal has store, drop {}

    /// Create and return a GovernanceProposal resource. Can only be called by LumioGovernance
    public(friend) fun create_proposal(): GovernanceProposal {
        GovernanceProposal {}
    }

    /// Useful for LumioGovernance to create an empty proposal as proof.
    public(friend) fun create_empty_proposal(): GovernanceProposal {
        create_proposal()
    }

    #[test_only]
    public fun create_test_proposal(): GovernanceProposal {
        create_empty_proposal()
    }
}
