use crate::enums::enums::ClaimType;
use crate::enums::enums::ClaimRepudiationReason;
use starknet::ContractAddress;
use crate::enums::enums::*;


#[derive(Drop, starknet::Event)]
    pub struct PolicyUpdated {
        #[key]
        pub token_id: u256,
        pub sum_insured: u256,
        pub premium: u256,
        pub endorsement_amount: u256,
        pub expiration_date: u64,
        pub subject_matter: ByteArray,
        pub update_type: UpdateType
    }


    #[derive(Drop, starknet::Event)]
    pub struct PolicyMinted {
        #[key]
        pub token_id: u256,
        pub policyholder: ContractAddress,
        pub policy_class: PolicyClass,
        pub subject_matter: ByteArray,
        pub sum_insured: u256,
        pub premium: u256,
        pub premium_frequency: PremiumFrequency,
        pub frequency_factor: u8,
        pub minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PolicyBurned {
        pub burner: ContractAddress,
        pub token_id: u256,
        pub reason: BurnReason
    }



#[derive(Drop, starknet::Event)]
pub struct ProposalCreated {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub sum_insured: u256
}


#[derive(Drop, starknet::Event)]
pub struct ProposalUpdated {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub sum_insured: u256,
    pub last_updated: u64
}



#[derive(Drop, starknet::Event)]
pub struct ProposalApproved {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub approver: ContractAddress,
    pub premium_payable: u256,
    pub premium_rate: u16,
}

#[derive(Drop, starknet::Event)]
pub struct ProposalRejected {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub rejector: ContractAddress,
    pub reason: RejectionReason
}


#[derive(Drop, starknet::Event)]
pub struct PremiumPaymentSuccess {
    #[key]
    pub proposal_id: u256,
    pub policyholder: ContractAddress,
    pub payer: ContractAddress,
    pub amount: u256,
    pub policy_token_id:u256,
    pub policy_id: u256
}

#[derive(Drop, starknet::Event)]
pub struct ProposalExpired {
    #[key]
    pub proposal_id: u256,
    pub proposer: ContractAddress,
    pub policy_class: PolicyClass,
    pub expired_at: u64
}



    #[derive(Drop, starknet::Event)]
    pub struct ClaimSubmitted {
        #[key]
        pub claim_id: u256,
        pub policy_id: u256,
        pub claimant: ContractAddress,
        pub amount: u256,
        pub claim_type: ClaimType
    }


    #[derive(Drop, starknet::Event)]
    pub struct ClaimUpdated {
        #[key]
        pub claim_id: u256,
        pub policy_id: u256,
        pub claimant: ContractAddress,
        pub amount: u256,
        pub claim_type: ClaimType
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimApproved {
        #[key]
        pub claim_id: u256,
        pub approver: ContractAddress,
        pub amount: u256,
        pub timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimRepudiated {
        #[key]
        pub claim_id: u256,
        pub denier: ContractAddress,
        pub reason: ClaimRepudiationReason
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimPaid {
        #[key]
        pub claim_id: u256,
        pub recipient: ContractAddress,
        pub amount: u256,
        pub tx_hash: felt252
    }

    #[derive(Drop, starknet::Event)]
    pub struct ClaimEscalated {
        #[key]
        pub claim_id: u256,
        pub escalator: ContractAddress,
        pub reason: ByteArray,
    }

   