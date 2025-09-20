use starknet::ContractAddress;
use crate::structs::structs::*;


#[starknet::interface]
pub trait IProposalForm<TContractState> {
    fn submit_proposal(
        ref self: TContractState,
        proposer: ContractAddress,
        policy_class_code: u8,
        subject_matter: ByteArray,
        sum_insured: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
    );
    fn update_proposal(
        ref self: TContractState,
        proposal_id: u256, 
        subject_matter: ByteArray,
        sum_insured: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
    );
    fn get_proposal_by_id(
        self: @TContractState,
        proposal_id: u256
    ) -> ProposalFormResponse;
    fn get_min_premium_rate(
        self: @TContractState
    ) -> u16;
    fn set_min_premium_rate(
        ref self: TContractState,
        new_rate: u16
    );
    fn get_max_premium_rate(
        self: @TContractState
    ) -> u16;
    fn set_max_premium_rate(
        ref self: TContractState,
        new_rate: u16
    );
    fn get_min_coverage_amount(
        self: @TContractState
    ) -> u256;
    fn set_min_coverage_amount(
        ref self: TContractState,
        new_amount: u256
    );
    fn get_max_coverage_amount(
        self: @TContractState
    ) -> u256;
    fn set_max_coverage_amount(
        ref self: TContractState,
        new_amount: u256
    );
    fn assess_proposal_by_risk_service(
        ref self: TContractState,
        proposal_id: u256,
        has_kyc: bool,
        risk_analytics_approved: bool,
        premium_payable: u256,
        premium_rate: u16,
        risk_score: u256,
        proposal_status_code: u8,
        rejection_reason_code: u8
    );

    fn assess_proposal_by_governance(
        ref self: TContractState,
        proposal_id: u256,
        has_kyc: bool,
        governance_approved: bool,
        premium_payable: u256,
        premium_rate: u16,
        risk_score: u256,
        proposal_status_code: u8,
        rejection_reason_code: u8
    );

    fn pay_premium_on_approval(
        ref self: TContractState,
        proposal_id: u256,
    ) -> bool;
    
    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn set_policy_minting_address(
        ref self: TContractState,
        policy_minting_address: ContractAddress
    );

    fn set_claims_contract_address(
        ref self: TContractState,
        claims_contract_address: ContractAddress
    );
}



#[starknet::interface]
pub trait IPolicyNFT<TContractState> {
    fn mint_policy(
        ref self: TContractState,
        proposal_id: u256
    ) -> u256;
    fn burn_policy(ref self: TContractState, token_id: u256, reason_index: u8);
    fn get_policy_data(self: @TContractState, token_id: u256) -> PolicyDataResponse;
    fn set_base_uri(ref self: TContractState, new_base_uri: ByteArray);
    fn update_policy_data(
        ref self: TContractState,
        token_id: u256, 
        subject_matter: ByteArray,
        sum_insured: u256,
        premium: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
        update_type_code: u8,
        endorsement_amount: u256
    );
    fn add_claim_to_policy(
        ref self: TContractState,
        policy_id: u256,
        claim_id: u256,
        claim_amount: u256
    );

    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn set_proposal_form_address(
        ref self: TContractState,
        proposal_form_address: ContractAddress
    );

    fn set_claims_contract_address(
        ref self: TContractState,
        claims_contract_address: ContractAddress
    );
}




#[starknet::interface]
pub trait IClaim<TContractState> {
    fn file_claim(
        ref self: TContractState,
        policy_id: u256,
        claimant: ContractAddress,
        claim_description: ByteArray,
        claim_amount: u256,
        alternative_account: ContractAddress,
        policy_class_code: u8,
        proof_urls: Array<ByteArray>
    ) -> u256;

    fn update_claim(
        ref self: TContractState,
        claim_id: u256,
        policy_id: u256,
        claimant: ContractAddress,
        claim_description: ByteArray,
        claim_amount: u256,
        alternative_account: ContractAddress,
        policy_class_code: u8,
        proof_urls: Array<ByteArray>
    );

    fn get_claim_by_id(
        self: @TContractState,
        claim_id: u256
    ) -> InsuranceClaimResponse;

    fn get_claim_evidence_urls_for_current_claim(
        self: @TContractState,
        claim_id: u256
    ) -> Array<ByteArray>;

    fn assess_claim_by_risk_analytics(
        ref self: TContractState,
        claim_id: u256,
        risk_analytics_approved: bool,
        is_approved: bool,
        is_repudiated: bool,
        repudiation_reason_code: u8,
        claim_status_code: u8,
        claim_type_code: u8
    );

    fn assess_claim_by_governance(
        ref self: TContractState,
        claim_id: u256,
        governance_approved: bool,
        is_approved: bool,
        is_repudiated: bool,
        repudiation_reason_code: u8,
        claim_status_code: u8,
        claim_type_code: u8
    );

    fn set_claim_as_settled(
        ref self: TContractState,
        claim_id: u256
    );

    fn set_claim_as_repudiated(
        ref self: TContractState,
        claim_id: u256
    );

    fn get_settled_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_repudiated_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_pending_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_escalated_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn get_all_claims(
        self: @TContractState
    ) -> Array<InsuranceClaimResponse>;

    fn escalate_claim(
        ref self: TContractState,
        claim_id: u256,
        is_escalated: bool,
        escalation_reason: ByteArray,
        proof_urls: Array<ByteArray>
    );

    fn settle_claim(
        ref self: TContractState,
        claim_id: u256,
    );

    fn set_treasury_address(
        ref self: TContractState,
        treasury_address: ContractAddress
    );

    fn get_treasury_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_proposal_form_address(
        ref self: TContractState,
        proposal_form_address: ContractAddress
    );

    fn get_proposal_form_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_policy_minting_address(
        ref self: TContractState,
        policy_minting_address: ContractAddress
    );

    fn get_policy_minting_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_governance_address(
        ref self: TContractState,
        governance_address: ContractAddress
    );

    fn get_governance_address(
        self: @TContractState,
    ) -> ContractAddress;

    fn set_auto_approval_limit(
        ref self: TContractState,
        auto_approval_limit: u256
    );

    fn get_auto_approval_limit(
        self: @TContractState,
    ) -> u256;

    fn set_max_claim_amount_payable(
        ref self: TContractState,
        max_claim_amount_payable: u256
    );

    fn get_max_claim_amount_payable(
        self: @TContractState,
    ) -> u256;    
}


