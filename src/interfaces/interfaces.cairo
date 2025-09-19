use starknet::ContractAddress;
use crate::structs::structs::{
    ProposalFormResponse,
    PolicyDataResponse
};


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

