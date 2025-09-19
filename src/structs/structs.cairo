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



// #[derive(Drop, starknet::Event)]
//     struct ProposalCreated {
//         #[key]
//         proposal_id: u256,
//         proposer: ContractAddress,
//         policy_class: PolicyClass,
//         sum_insured: u256
//     }


//     #[derive(Drop, starknet::Event)]
//     struct ProposalUpdated {
//         #[key]
//         proposal_id: u256,
//         proposer: ContractAddress,
//         policy_class: PolicyClass,
//         sum_insured: u256,
//         last_updated: u64
//     }



//     #[derive(Drop, starknet::Event)]
//     struct ProposalApproved {
//         #[key]
//         proposal_id: u256,
//         proposer: ContractAddress,
//         approver: ContractAddress,
//         premium_payable: u256,
//         premium_rate: u16,
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ProposalRejected {
//         #[key]
//         proposal_id: u256,
//         proposer: ContractAddress,
//         rejector: ContractAddress,
//         reason: RejectionReason
//     }

   
//     #[derive(Drop, starknet::Event)]
//     struct PremiumPaymentSuccess {
//         #[key]
//         proposal_id: u256,
//         policyholder: ContractAddress,
//         payer: ContractAddress,
//         amount: u256,
//         policy_token_id:u256,
//         policy_id: u256
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ProposalExpired {
//         #[key]
//         proposal_id: u256,
//         proposer: ContractAddress,
//         policy_class: PolicyClass,
//         expired_at: u64
//     }


#[derive(Drop, starknet::Store, Serde, Clone)]
pub struct PolicyData {
    pub policy_id: u256,
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

// #[derive(Drop, starknet::Event)]
//     pub struct PolicyUpdated {
//         #[key]
//         token_id: u256,
//         sum_insured: u256,
//         premium: u256,
//         endorsement_amount: u256,
//         expiration_date: u64,
//         subject_matter: ByteArray,
//         update_type: UpdateType
//     }


//     #[derive(Drop, starknet::Event)]
//     pub struct PolicyMinted {
//         #[key]
//         token_id: u256,
//         policyholder: ContractAddress,
//         policy_class: PolicyClass,
//         subject_matter: ByteArray,
//         sum_insured: u256,
//         premium: u256,
//         premium_frequency: PremiumFrequency,
//         frequency_factor: u8,
//         minter: ContractAddress,
//     }

//     #[derive(Drop, starknet::Event)]
//     pub struct PolicyBurned {
//         burner: ContractAddress,
//         token_id: u256,
//         reason: BurnReason
//     }

