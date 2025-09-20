use starknet::ContractAddress;
use crate::enums::enums::*;

    #[derive(Drop, starknet::Store, Serde, Clone)]
    pub struct ProposalForm {
        pub proposal_id: u256,
        pub proposer: ContractAddress,
        pub policy_class_code: u8,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium_payable: u256,
        pub premium_frequency_code: u8,
        pub frequency_factor: u8,
        pub has_kyc: bool,
        pub submission_date: u64,
        pub last_updated: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub is_premium_paid: bool,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub proposal_status_code: u8,
        pub rejection_reason_code: u8,
        pub risk_score: u256,
        pub premium_rate: u16
    }





    #[derive(Drop, Serde, Clone)]
    pub struct ProposalFormResponse {
        pub proposal_id: u256,
        pub proposer: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium_payable: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub has_kyc: bool,
        pub submission_date: u64,
        pub last_updated: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub is_premium_paid: bool,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub proposal_status: ProposalStatus,
        pub rejection_reason: RejectionReason,
        pub risk_score: u256,
        pub premium_rate: u16
    }




    #[derive(Drop, starknet::Store, Serde, Clone)]
    pub struct PolicyData {
        pub policy_id: u256,
        pub proposal_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class_code: u8,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency_code: u8,
        pub frequency_factor: u8,
        pub start_date: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub claims_count: u256,
        pub has_claimed: bool,
        pub aggregate_claim_amount: u256
    }


    #[derive(Drop, Serde, Clone)]
    pub struct PolicyDataResponse {
        pub policy_id: u256,
        pub proposal_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub start_date: u64,
        pub expiration_date: u64,
        pub is_active: bool,
        pub is_expired: bool,
        pub claims_count: u256,
        pub has_claimed: bool,
        pub claim_ids: Array<u256>,
        pub aggregate_claim_amount: u256
    }



        #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct InsuranceClaim {
        pub claim_id: u256,
        pub policy_id: u256,
        pub proposal_id: u256,
        pub claimant: ContractAddress,
        pub claim_description: ByteArray,
        pub claim_amount: u256,
        pub alternative_account: ContractAddress,
        pub policy_class_code: u8,
        pub claim_status_code: u8,
        pub claim_type_code: u8,
        pub submission_date: u64,
        pub updated_at: u64,
        pub is_approved: bool,
        pub approved_at: u64,
        pub is_repudiated: bool,
        pub repudiated_at: u64,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub is_escalated: bool,
        pub escalation_reason: ByteArray,
        pub repudiation_reason_code: u8
    }


    #[derive(Drop, Serde, Clone)]
    pub struct InsuranceClaimResponse {
        pub claim_id: u256,
        pub policy_id: u256,
        pub proposal_id: u256,
        pub claimant: ContractAddress,
        pub claim_description: ByteArray,
        pub claim_amount: u256,
        pub alternative_account: ContractAddress,
        pub policy_class: PolicyClass,
        pub claim_status: ClaimStatus,
        pub claim_type: ClaimType,
        pub submission_date: u64,
        pub updated_at: u64,
        pub is_approved: bool,
        pub approved_at: u64,
        pub is_repudiated: bool,
        pub repudiated_at: u64,
        pub risk_analytics_approved: bool,
        pub governance_approved: bool,
        pub is_escalated: bool,
        pub escalation_reason: ByteArray,
        pub claim_evidence_urls: Array<ByteArray>,
        pub repudiation_reason: ClaimRepudiationReason
    }


    #[derive(Drop, Serde, Clone)]
    struct ClaimEvidence {
        pub policy_id: u256,
        pub submission_date: u64,
        pub proof_urls: Array<ByteArray>,
    }


