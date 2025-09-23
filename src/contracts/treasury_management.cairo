#[starknet::contract]
pub mod TreasuryManagement {
    // use crate::contracts::erc721_policy::PolicyNFT::Event;
use crate::structs::structs::PremiumPaymentResponse;
use crate::interfaces::interfaces::IPolicyNFTDispatcher;
use crate::interfaces::interfaces::IProposalFormDispatcher;
use crate::structs::structs::ClaimPayment;
use starknet::{ ContractAddress, ClassHash };
    use starknet::{
        get_caller_address,
        // get_contract_address,
        get_block_timestamp,
        get_tx_info,
        TxInfo
    };
    // use core::integer::zeroable::Zeroable;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{ 
        IERC20Dispatcher,
        IERC20DispatcherTrait
    };
    // use openzeppelin::token::erc721::interface::IERC721Dispatcher;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;



    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    use crate::structs::structs::*;
    use crate::enums::enums::*;
    use crate::event_structs::event_structs::*;
    use crate::utils::utils::*;
    use crate::interfaces::interfaces::*;



      // Roles
      const TREASURY_MANAGER_ROLE: felt252 = selector!("TREASURY_MANAGER_ROLE");
      const TREASURY_GUARDIAN_ROLE: felt252 = selector!("TREASURY_GUARDIAN_ROLE");
      const DEFAULT_ADMIN_ROLE: felt252 = selector!("DEFAULT_ADMIN_ROLE");
  
      // Withdrawal proposal status
      const STATUS_PENDING: felt252 = selector!("STATUS_PENDING");
      const STATUS_APPROVED: felt252 = selector!("STATUS_APPROVED");
      const STATUS_EXECUTED: felt252 = selector!("STATUS_EXECUTED");
      const STATUS_REJECTED: felt252 = selector!("STATUS_REJECTED");



    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);




    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

   
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;




    #[storage]
    pub struct Storage {
        // OpenZeppelin Components
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,


        next_transaction_id: u256,
        next_reinsurer_id: u256,

        reinsurers: Map<u256, Reinsurer>,

        //premium payment data by transaction_id
        premiums: Map<u256, PremiumPayment>,
        //By transaction_id
        claim_payments: Map<u256, ClaimPayment>,
        //By transaction_id --- Debits Starknet-Indemnify STINDEM Balance
        native_token_purchases: Map<u256, NativeTokenPurchase>,
        //By transaction_id --- Credits Starknet-Indeminfy STINDEM Balance
        native_token_recoveries: Map<u256, NativeTokenRecovery>,
        //By transaction_id --- Credits Starknet-Indemnify STINDEM Balance
        vote_right_payments: Map<u256, PurchaseVotingCommitment>,
        //Current balance of Investors' fund
        investors_fund_balance: u256,
        gross_premium_written: u256,
        claims_reserve: u256,
        total_premium_allocated_to_reinsurance: u256,
        total_premium_allocated_to_investors_pool: u256,
        total_claims_value_drawn_from_investors_pool: u256,
        total_claims_value_drawn_from_reinsurance: u256,
        total_value_of_claims_paid: u256,
        total_value_of_incurred_claims: u256,
        total_value_of_repudiated_claims: u256,
    
        //STINDEM token address
        stindem_token_address: ContractAddress, 

        //Conversion rates
        current_stindem_to_strk_value: u256,
        current_stindem_to_eth_value: u256,
        current_stindem_to_btc_value: u256,
        current_stindem_to_usd_value: u256,  
        current_strk_to_usd_value: u256,
        current_strk_to_eth_value: u256,
        current_strk_to_btc_value: u256,

        //Currencies balances
        starknet_indemnify_usd_balance: u256,
        starknet_indemnify_strk_balance: u256,
        starknet_indemnify_stindem_balance: u256,
        starknet_indemnify_eth_balance: u256,
        starknet_indemnify_btc_balance: u256,

        proposal_form_address: ContractAddress,
        policy_minting_address: ContractAddress,
        claims_contract_address: ContractAddress,
        governance_contract_address: ContractAddress,
        strk_contract_address: ContractAddress,
        starknet_indemnify_treasury_account: ContractAddress
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }
    

  

   

   
  
    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        manager: ContractAddress,
        guardian: ContractAddress,
        timelock_duration: u64
    ) {
        // Initialize OpenZeppelin components
        self.accesscontrol.initializer();
        // Setup roles
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, admin);
        self.accesscontrol._grant_role(TREASURY_MANAGER_ROLE, manager);
        self.accesscontrol._grant_role(TREASURY_GUARDIAN_ROLE, guardian);

        self.next_transaction_id.write(1);
        self.next_reinsurer_id.write(1);

        // Set timelock duration
    }

    
        #[abi(embed_v0)]
    pub impl TreasuryManagementImpl of ITreasuryManagement<ContractState> {

        fn pay_premium(
            ref self: ContractState,
            proposal_id: u256,
            payer_address: ContractAddress,
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let proposal_form_dispatcher: IProposalFormDispatcher = IProposalFormDispatcher {
                contract_address: self.proposal_form_address.read()
            };

            let proposal_obj: ProposalFormResponse = proposal_form_dispatcher.get_proposal_by_id(proposal_id);

            let is_risk_analytics_approved: bool = proposal_obj.risk_analytics_approved;
            let is_governance_approved: bool = proposal_obj.governance_approved;

            let is_premium_payment_allowed: bool = is_proposal_approved_for_premium_payment(
                is_risk_analytics_approved, 
                is_governance_approved
            );

            assert!(is_premium_payment_allowed, "Unathorized: Proposal form has not been approved for premium payment");           

            let actual_premium_payable: u256 = proposal_obj.premium_payable;

            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();

            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(caller);

            assert!(balance >= actual_premium_payable, "Caller doesn't have enough balance");

            // let contract: ContractAddress = get_contract_address();

            let allowance: u256 = strk_dispatcher.allowance(caller, treasury_account);

            assert!(allowance >= actual_premium_payable, "Treasury Account is not allowed to spend enough premium");


            let success: bool = strk_dispatcher.transfer_from(caller, treasury_account, actual_premium_payable);

            assert!(success, "Premium payment failed");


            let policy_minting_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher {
                contract_address: self.policy_minting_address.read()
            };

            let new_policy_id: u256 = policy_minting_dispatcher.mint_policy(proposal_id); 

            let current_time: u64 = get_block_timestamp();   

            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;



            let new_payment: PremiumPayment = PremiumPayment {
                transaction_id: current_txn_id,
                proposal_id: proposal_id,
                policy_id: new_policy_id,
                payer_address: payer_address,
                policyholder: proposal_obj.proposer,
                amount_paid: actual_premium_payable,
                sum_insured: proposal_obj.sum_insured,
                payment_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code:  convert_payment_status_to_code(PaymentStatus::Successful)
            };

            self.premiums.write(current_txn_id, new_payment);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

             current_txn_id
        }
    
        fn update_premium_payment(
            ref self: ContractState,
            transaction_id: u256,
            policy_id: u256,
            txn_hash: felt252,
            payment_status_code: u8 
        ) {

            let updateable_premium_payment: PremiumPayment = self.premiums.read(transaction_id);

            let current_time: u64 = get_block_timestamp();

            let updated_premium_payment: PremiumPayment = PremiumPayment {
                transaction_id: transaction_id,
                proposal_id: updateable_premium_payment.proposal_id,
                policy_id: policy_id,
                payer_address: updateable_premium_payment.payer_address,
                policyholder: updateable_premium_payment.policyholder,
                amount_paid: updateable_premium_payment.amount_paid,
                sum_insured: updateable_premium_payment.sum_insured,
                payment_date: updateable_premium_payment.payment_date,
                updated_at: current_time,
                txn_hash: txn_hash,
                payment_status_code:  payment_status_code
            };

            self.premiums.write(transaction_id, updated_premium_payment);

        }
    
        fn get_premium_payment(
            self: @ContractState,
            transaction_id: u256
        ) -> PremiumPaymentResponse {

            let sought_premium_payment: PremiumPayment = self.premiums.read(transaction_id);

            let response_obj: PremiumPaymentResponse = PremiumPaymentResponse {
                    transaction_id: transaction_id,
                    proposal_id: sought_premium_payment.proposal_id,
                    policy_id: sought_premium_payment.policy_id,
                    payer_address: sought_premium_payment.payer_address,
                    policyholder: sought_premium_payment.policyholder,
                    amount_paid: sought_premium_payment.amount_paid,
                    sum_insured: sought_premium_payment.sum_insured,
                    payment_date: sought_premium_payment.payment_date,
                    updated_at: sought_premium_payment.updated_at,
                    txn_hash: sought_premium_payment.txn_hash,
                    payment_status: convert_payment_code_to_status(sought_premium_payment.payment_status_code)
            };

            response_obj
        }
    
        fn pay_claim(
            ref self: ContractState,
            policy_id: u256,
            claim_id: u256,
            policyholder: ContractAddress,
            third_party_account: ContractAddress,
            settlement_source_code: u8
        ) -> u256 {

            let current_txn_id: u256 = self.next_transaction_id.read();

            let current_time: u64 = get_block_timestamp();


            let policy_minting_dispatcher: IPolicyNFTDispatcher = IPolicyNFTDispatcher {
                contract_address: self.policy_minting_address.read()
            };

            let claim_dispatcher: IClaimDispatcher = IClaimDispatcher {
                contract_address: self.claims_contract_address.read()
            };

            let policy_obj: PolicyDataResponse = policy_minting_dispatcher.get_policy_data(policy_id);
            let claim_obj: InsuranceClaimResponse = claim_dispatcher.get_claim_by_id(claim_id);

            let is_governance_approved: bool = claim_obj.governance_approved;
            let is_risk_analytics_approved: bool = claim_obj.risk_analytics_approved;

            let claim_is_approved: bool = is_claim_approved_for_settlement(
                is_risk_analytics_approved,
                is_governance_approved
            );

            let payable_claim_amount: u256 = claim_obj.approved_settlement_amount;

            assert!(claim_is_approved, "PaymentDenied: Claim has not been approved for settlement");

            let treasury_account: ContractAddress = self.starknet_indemnify_treasury_account.read();


            let strk_dispatcher: IERC20Dispatcher = IERC20Dispatcher {
                contract_address: self.strk_contract_address.read()
            }; 

            // let caller: ContractAddress = get_caller_address();

            let balance: u256 = strk_dispatcher.balance_of(treasury_account);

            assert!(balance >= payable_claim_amount, "Treasury Account doesn't have enough balance");

            let allowance: u256 = strk_dispatcher.allowance(treasury_account, policyholder);

            assert!(allowance >= payable_claim_amount, "Policyholder is not allowed to spend enough claimed token");


            let success: bool = strk_dispatcher.transfer_from(treasury_account, policyholder, payable_claim_amount);

            assert!(success, "Claim payment failed");




            let txn_info: TxInfo = get_tx_info().unbox();

            let txn_hash: felt252 = txn_info.transaction_hash;


            let paid_claim_txn: ClaimPayment = ClaimPayment {
                transaction_id: current_txn_id,
                proposal_id: policy_obj.proposal_id,
                policy_id: policy_id,
                claim_id: claim_id,
                policyholder: policyholder,
                third_party_account: third_party_account,
                claim_amount: claim_obj.claim_amount,
                approved_settlement_amount: claim_obj.approved_settlement_amount,
                settlement_date: current_time,
                updated_at: current_time,
                txn_hash: txn_hash,
                settlement_status_code: convert_payment_status_to_code(PaymentStatus::Successful),
                settlement_source_code: settlement_source_code
            };

            self.claim_payments.write(current_txn_id, paid_claim_txn);

            let incremented_txn_id: u256 = current_txn_id + 1;

            self.next_transaction_id.write(incremented_txn_id);

            current_txn_id
        }
    
        // fn update_claim_payment(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     third_party_account: ContractAddress,
        //     txn_hash: ByteArray,
        //     settlement_status_code: u8,
        //     settlement_source_code: u8
        // ) {

        // }
    
        // fn get_claim_payment(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> ClaimPaymentResponse {

        // }
    
        // fn purchase_stindem(
        //     ref self: ContractState,
        //     buyer_address: ContractAddress,
        //     quantity: u256,
        // ) -> u256 {

        // }
    
        // fn update_stindem_purchase_detail(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     txn_hash: ByteArray,
        //     payment_status_code: u8
        // ) {

        // }
    
        // fn get_stindem_purchase_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> NativeTokenPurchaseReponse {

        // }
    
        // fn recover_stindem_from_market(
        //     ref self: ContractState,
        //     seller_address: ContractAddress,
        //     quantity: u256,
        // ) -> u256 {

        // }
    
        // fn update_stindem_recovery_from_market(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     txn_hash: ByteArray,
        //     payment_status_code: u8
        // ) {

        // }
    
        // fn get_stindem_recovery_txn_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> NativeTokenRecoveryResponse {

        // }
    
        // fn purchase_voting_commitment(
        //     ref self: ContractState,
        //     seller_address: ContractAddress,
        //     quantity: u256,
        // ) {

        // }
    
        // fn update_voting_commitment_purchase(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     txn_hash: ByteArray,
        //     payment_status_code: u8
        // ) {

        // }
    
        // fn get_voting_commitment_purchase_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> PurchaseVotingCommitmentResponse {

        // }
    
        // fn initiate_reinsurance_premium_payment(
        //     ref self: ContractState,
        //     insured_proposal_id: u256,
        //     insured_policy_id: u256,
        //     reinsurer_id: u256,
        //     reinsurance_payment_address: ContractAddress,
        //     percentage_reinsurance: u16,
        //     gross_sum_insured: u256,
        //     ceded_sum_insured: u256,
        //     gross_premium: u256,
        //     ceded_premium: u256,
        // ) -> u256 {

        // }
    
        // fn update_reinsurance_premium_payment_detail(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     txn_hash: ByteArray,
        //     reinsurance_doc_url: ByteArray,
        //     payment_status_code: u8,
        //     reinsurance_status_code: u8
        // ) {

        // }
    
        // fn get_reinsurance_premium_payment_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> CreditReinsuranceResponse {

        // }
    
        // fn initiate_claim_recovery_from_reinsurance(
        //     ref self: ContractState,
        //     reinsurance_payment_id: u256,
        //     insured_proposal_id: u256,
        //     insured_policy_id: u256,
        //     claim_id: u256,
        //     insured: ContractAddress,
        //     reinsurer_id: u256,
        //     reinsurance_payment_address: ContractAddress,
        //     gross_claim_amount: u256,
        // ) -> u256 {

        // }
    
        // fn update_claim_recovery_from_reinsurance(
        //     ref self: ContractState,
        //     transaction_id: u256,
        //     claim_id: u256,
        //     reinsurance_payment_id: u256,
        //     reinsurance_payment_address: ContractAddress,
        //     txn_hash: ByteArray,
        //     claim_discharge_voucher_url: ByteArray,
        //     settlement_status_code: u8,
        //     reinsurance_status_code: u8 
        // ) {

        // }
    
        // fn get_claim_recovery_from_reinsurance_detail(
        //     self: @ContractState,
        //     transaction_id: u256
        // ) -> DebitReinsuranceResponse {

        // }
    
        // fn create_new_reinsurer(
        //     ref self: ContractState,
        //     reinsurer_name: ByteArray,
        //     reinsurer_head_office: ByteArray,
        //     reinsurer_fiat_account: ByteArray,
        //     reinsurer_web_site: ByteArray,
        //     risk_capacity: u256,
        //     contract_type_code: u8,
        // ) -> u256 {

        // }
    
        // fn update_reinsruer_detail(
        //     ref self: ContractState,
        //     reinsurer_id: u256,
        //     reinsurer_name: ByteArray,
        //     reinsurer_head_office: ByteArray,
        //     reinsurer_fiat_account: ByteArray,
        //     reinsurer_web_site: ByteArray,
        //     risk_capacity: u256,
        //     contract_type_code: u8,
        //     total_obligation_offered: u256,
        //     total_obligation_fulfilled: u256,
        //     reliability_factor: u8,
        // ) {

        // }
    
        // fn get_reinsurer_by_id(
        //     self: @ContractState,
        //     reinsurer_id: u256
        // ) -> ReinsurerResponse {

        // }
    
        // fn set_proposal_form_address(
        //     ref self: ContractState,
        //     proposal_form_address: ContractAddress
        // ) {

        // }
    
        // fn get_proposal_form_address(
        //     self: @ContractState,
        // ) -> ContractAddress {

        // }
    
        // fn set_policy_minting_address(
        //     ref self: ContractState,
        //     policy_minting_address: ContractAddress
        // ) {

        // }
    
        // fn get_policy_minting_address(
        //     self: @ContractState,
        // ) -> ContractAddress {

        // }
    
        // fn set_governance_address(
        //     ref self: ContractState,
        //     governance_address: ContractAddress
        // ) {

        // }
    
        // fn get_governance_address(
        //     self: @ContractState,
        // ) -> ContractAddress {

        // }
    
        // fn set_claims_contract_address(
        //     ref self: ContractState,
        //     claims_contract_address: ContractAddress
        // ) {

        // }
    
        // fn get_claims_contract_address(
        //     self: @ContractState,
        // ) -> ContractAddress {

        // }
    
    }


    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(DEFAULT_ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.upgradeable.upgrade(new_class_hash);
        }
    }
}













// // treasury_contract.cairo
// // Reference single-file Cairo contract for treasury management
// // NOTE: adapt imports to your toolchain if necessary.

// #![feature(concat_idents)]
// #![no_std]
// #![allow(unused_imports)]

// // --- Imports (may need to adjust for your Cairo/snforge version) ---
// use starknet::ContractAddress;
// use starknet::get_caller_address;
// use starknet::get_block_timestamp;
// use core::array::ArrayTrait;
// use core::integer::u256;
// use core::option::OptionTrait;
// use starknet::storage::{
//     Map,
// };
// use core::serde::Serde;
// use core::result::ResultTrait;
// use snforge_std::{declare, ContractClassTrait}; // optional

// // --- Types ---
// #[derive(Copy, Drop, Serde)]
// pub struct Policy {
//     pub id: u256,              // policy id
//     pub owner: ContractAddress,
//     pub premium: u256,         // premium paid
//     pub coverage: u256,        // coverage amount
//     pub expires_at: u64,       // timestamp
//     pub active: bool,
// }

// #[derive(Copy, Drop, Serde)]
// pub struct Claim {
//     pub id: u256,
//     pub policy_id: u256,
//     pub claimant: ContractAddress,
//     pub amount: u256,
//     pub timestamp: u64,
//     pub approved: bool,
//     pub paid: bool,
// }

// // Events
// #[derive(Drop, Serde, starknet::Event)]
// pub struct PolicyPurchased {
//     pub policy_id: u256,
//     pub owner: ContractAddress,
//     pub premium: u256,
//     pub coverage: u256,
// }

// #[derive(Drop, Serde, starknet::Event)]
// pub struct ClaimSubmitted {
//     pub claim_id: u256,
//     pub policy_id: u256,
//     pub claimant: ContractAddress,
//     pub amount: u256,
// }

// #[derive(Drop, Serde, starknet::Event)]
// pub struct ClaimApproved {
//     pub claim_id: u256,
//     pub payout: u256,
// }

// #[derive(Drop, Serde, starknet::Event)]
// pub struct Staked {
//     pub staker: ContractAddress,
//     pub amount: u256,
// }

// #[derive(Drop, Serde, starknet::Event)]
// pub struct Unstaked {
//     pub staker: ContractAddress,
//     pub amount: u256,
// }

// #[derive(Drop, Serde, starknet::Event)]
// pub struct RewardsDistributed {
//     pub total: u256,
// }

// // --- Storage ---
// // Note: adapt #[storage] annotation for your toolchain (component! or #[storage] used earlier)
// #[storage]
// pub struct Storage {
//     // Counters
//     pub next_policy_id: u256,
//     pub next_claim_id: u256,

//     // Core managed maps
//     pub policies: Map<u256, Policy>,
//     pub claims: Map<u256, Claim>,

//     // Pools (amounts are u256)
//     pub claims_reserve: u256,     // funds reserved for claims
//     pub investor_pool: u256,      // funds staked by investors (risk-bearing)
//     pub treasury_pool: u256,      // protocol revenue

//     // Investor stakes mapping and withdrawal locks
//     pub stakes: Map<ContractAddress, u256>,
//     pub stake_lock_until: Map<ContractAddress, u64>,

//     // Reward accounting
//     pub pending_rewards: Map<ContractAddress, u256>,

//     // Admin / governance
//     pub owner: ContractAddress,
//     pub paused: bool,

//     // Configuration
//     pub reserve_ratio_bps: u32,   // basis points to claims reserve from premium (e.g 7000 for 70%)
//     pub investor_ratio_bps: u32,  // share to investors
//     pub treasury_ratio_bps: u32,  // share to treasury
//     pub unstake_lock_seconds: u64,
// }

// // --- Contract implementation ---
// #[contract]
// impl TreasuryContract {
//     #[constructor]
//     fn constructor(ref self: Storage, owner: ContractAddress) {
//         self.next_policy_id.write(u256 { low: 1, high: 0 });
//         self.next_claim_id.write(u256 { low: 1, high: 0 });

//         self.claims_reserve.write(u256 { low: 0, high: 0 });
//         self.investor_pool.write(u256 { low: 0, high: 0 });
//         self.treasury_pool.write(u256 { low: 0, high: 0 });

//         self.owner.write(owner);
//         self.paused.write(false);

//         // defaults: 70% reserve, 20% investor, 10% treasury (bps)
//         self.reserve_ratio_bps.write(7000u32);
//         self.investor_ratio_bps.write(2000u32);
//         self.treasury_ratio_bps.write(1000u32);

//         self.unstake_lock_seconds.write(86400u64); // 1 day by default
//     }

//     // ---- Helpers ----
//     fn only_owner(self: @Storage) {
//         let caller = get_caller_address();
//         assert!(caller == self.owner.read(), "Only owner");
//     }

//     fn ensure_not_paused(self: @Storage) {
//         assert!(!self.paused.read(), "Contract paused");
//     }

//     // Safe u256 operations helpers (wraps simple ops)
//     fn u256_add(a: u256, b: u256) -> u256 {
//         let res = a + b;
//         res
//     }
//     fn u256_sub(a: u256, b: u256) -> u256 {
//         // assume a >= b for simplicity in this reference
//         let res = a - b;
//         res
//     }

//     // Utility: allocate premium into pools based on basis points
//     fn allocate_premium(self: @Storage, premium: u256) {
//         // compute parts: (premium * ratio_bps) / 10000
//         let reserve_bps = self.reserve_ratio_bps.read();
//         let investor_bps = self.investor_ratio_bps.read();
//         let treasury_bps = self.treasury_ratio_bps.read();

//         // NOTE: u256 * u32 requires careful arithmetic; simplified here:
//         let reserve_part = premium * u256 { low: reserve_bps as u64, high: 0 } / u256 { low: 10000u64, high: 0 };
//         let investor_part = premium * u256 { low: investor_bps as u64, high: 0 } / u256 { low: 10000u64, high: 0 };
//         let treasury_part = premium * u256 { low: treasury_bps as u64, high: 0 } / u256 { low: 10000u64, high: 0 };

//         // add to pools
//         self.claims_reserve.write(self.claims_reserve.read() + reserve_part);
//         self.investor_pool.write(self.investor_pool.read() + investor_part);
//         self.treasury_pool.write(self.treasury_pool.read() + treasury_part);

//         // leftover goes to treasury (to handle rounding)
//         let allocated = reserve_part + investor_part + treasury_part;
//         if premium > allocated {
//             let leftover = premium - allocated;
//             self.treasury_pool.write(self.treasury_pool.read() + leftover);
//         }
//     }

//     // ---- Public API ----

//     // Buy policy: user pays premium (assume payment handled off-chain via ERC20 approval + transfer to this contract)
//     // For simplicity, this function receives 'premium' and 'coverage' values and records policy.
//     fn buy_policy(
//         ref self: Storage,
//         premium: u256,
//         coverage: u256,
//         duration_seconds: u64
//     ) -> u256 {
//         self.ensure_not_paused();
//         let caller = get_caller_address();

//         // basic checks
//         assert!(premium.low > 0u64 || premium.high > 0u64, "Premium must be > 0");
//         assert!(coverage.low > 0u64 || coverage.high > 0u64, "Coverage must be > 0");
//         assert!(duration_seconds > 0u64, "Duration required");

//         // create policy
//         let pid = self.next_policy_id.read();
//         let now = get_block_timestamp();
//         let expires = now + duration_seconds;

//         let policy = Policy {
//             id: pid,
//             owner: caller,
//             premium,
//             coverage,
//             expires_at: expires,
//             active: true,
//         };
//         self.policies.write(pid, policy);

//         // allocate premium to pools
//         self.allocate_premium(premium);

//         // increment next id
//         self.next_policy_id.write(pid + u256 { low: 1, high: 0 });

//         // emit event
//         self.emit(Event::PolicyPurchased(PolicyPurchased {
//             policy_id: pid,
//             owner: caller,
//             premium,
//             coverage,
//         }));

//         pid
//     }

//     // Submit claim
//     fn submit_claim(
//         ref self: Storage,
//         policy_id: u256,
//         claim_amount: u256
//     ) -> u256 {
//         let caller = get_caller_address();
//         // load policy
//         let policy = self.policies.read(policy_id);
//         // policy must exist and be owned by caller
//         assert!(policy.owner == caller, "Not policy owner");
//         assert!(policy.active, "Policy inactive");
//         // ensure within coverage
//         assert!(claim_amount <= policy.coverage, "Claim exceeds coverage");

//         let cid = self.next_claim_id.read();
//         let now = get_block_timestamp();

//         let claim = Claim {
//             id: cid,
//             policy_id,
//             claimant: caller,
//             amount: claim_amount,
//             timestamp: now,
//             approved: false,
//             paid: false,
//         };

//         self.claims.write(cid, claim);
//         self.next_claim_id.write(cid + u256 { low: 1, high: 0 });

//         self.emit(Event::ClaimSubmitted(ClaimSubmitted {
//             claim_id: cid,
//             policy_id,
//             claimant: caller,
//             amount: claim_amount,
//         }));

//         cid
//     }

//     // Approve claim (only owner / governance); after approval, call payout_claim to execute funds
//     fn approve_claim(ref self: Storage, claim_id: u256) {
//         self.only_owner();
//         let mut claim = self.claims.read(claim_id);
//         assert!(!claim.approved, "Already approved");
//         claim.approved = true;
//         self.claims.write(claim_id, claim);

//         // event
//         self.emit(Event::ClaimApproved(ClaimApproved {
//             claim_id,
//             payout: claim.amount,
//         }));
//     }

//     // Payout approved claim. This will withdraw from claims_reserve first, then investor_pool if reserve insufficient.
//     fn payout_claim(ref self: Storage, claim_id: u256) {
//         self.only_owner(); // admin triggers payout (or this could be automated)
//         let mut claim = self.claims.read(claim_id);
//         assert!(claim.approved, "Claim not approved");
//         assert!(!claim.paid, "Claim already paid");

//         let payout = claim.amount;

//         // ensure pools cover payout: reserve then investor pool
//         let reserve = self.claims_reserve.read();
//         if reserve >= payout {
//             self.claims_reserve.write(reserve - payout);
//         } else {
//             // reserve insufficient: use all reserve then draw from investor pool
//             let remaining = payout - reserve;
//             self.claims_reserve.write(u256 { low: 0, high: 0 });

//             let inv_pool = self.investor_pool.read();
//             assert!(inv_pool >= remaining, "Insufficient funds (solvency)");
//             self.investor_pool.write(inv_pool - remaining);
//         }

//         // Here you would call transfer to claimant (omitted; use ERC20 transfer or native token transfer)
//         // transfer_to(claim.claimant, payout);

//         claim.paid = true;
//         self.claims.write(claim_id, claim);
//     }

//     // Stake: investor deposits amount (off-chain token transfer assumed; this records stake)
//     fn stake(ref self: Storage, amount: u256) {
//         self.ensure_not_paused();
//         let caller = get_caller_address();
//         assert!(amount.low > 0u64 || amount.high > 0u64, "Stake amount > 0");

//         // increment stake
//         let prev = self.stakes.read(caller);
//         self.stakes.write(caller, prev + amount);

//         // add to investor_pool
//         self.investor_pool.write(self.investor_pool.read() + amount);

//         // set lock time
//         let lock_until = get_block_timestamp() + self.unstake_lock_seconds.read();
//         self.stake_lock_until.write(caller, lock_until);

//         self.emit(Event::Staked { staker: caller, amount });
//     }

//     // Unstake (after lock). Here we simply mark and reduce pool; withdrawals may be processed off-chain or via ERC20 transfer call.
//     fn unstake(ref self: Storage, amount: u256) {
//         let caller = get_caller_address();
//         let lock_until = self.stake_lock_until.read(caller);
//         let now = get_block_timestamp();
//         assert!(now >= lock_until, "Stake locked");

//         let prev = self.stakes.read(caller);
//         assert!(prev >= amount, "Insufficient stake");

//         self.stakes.write(caller, prev - amount);
//         // reduce investor_pool
//         let inv = self.investor_pool.read();
//         assert!(inv >= amount, "Investor pool underflow");
//         self.investor_pool.write(inv - amount);

//         // transfer to caller (omitted: do ERC20 transfer)
//         // transfer_to(caller, amount);

//         self.emit(Event::Unstaked { staker: caller, amount });
//     }

//     // Distribute rewards (simple proportional distribution from treasury_pool to stakers)
//     fn distribute_rewards(ref self: Storage) {
//         self.only_owner();

//         let total_rewards = self.treasury_pool.read();
//         assert!(total_rewards.low > 0u64 || total_rewards.high > 0u64, "No rewards");

//         // Compute total stakes
//         // NOTE: Maps don't have direct iteration in this simplistic reference.
//         // In a production contract you'd keep a ledger array of stakers or
//         // perform reward distribution off-chain. Here we provide a simplified
//         // placeholder: move entire treasury to pending_rewards pool for manual distribution.
//         self.pending_rewards.write(self.owner.read(), total_rewards);
//         self.treasury_pool.write(u256 { low: 0, high: 0 });

//         self.emit(Event::RewardsDistributed { total: total_rewards });
//     }

//     // Admin controls
//     fn set_ratios(ref self: Storage, reserve_bps: u32, investor_bps: u32, treasury_bps: u32) {
//         self.only_owner();
//         assert!(reserve_bps + investor_bps + treasury_bps == 10000u32, "Ratios must sum to 10000");
//         self.reserve_ratio_bps.write(reserve_bps);
//         self.investor_ratio_bps.write(investor_bps);
//         self.treasury_ratio_bps.write(treasury_bps);
//     }

//     fn pause_underwriting(ref self: Storage) {
//         self.only_owner();
//         self.paused.write(true);
//     }
//     fn resume_underwriting(ref self: Storage) {
//         self.only_owner();
//         self.paused.write(false);
//     }

//     // Getters
//     fn get_pools(self: @Storage) -> (u256, u256, u256) {
//         (self.claims_reserve.read(), self.investor_pool.read(), self.treasury_pool.read())
//     }

//     fn get_policy(self: @Storage, pid: u256) -> Policy {
//         self.policies.read(pid)
//     }

//     fn get_claim(self: @Storage, cid: u256) -> Claim {
//         self.claims.read(cid)
//     }

//     fn get_stake(self: @Storage, staker: ContractAddress) -> u256 {
//         self.stakes.read(staker)
//     }
// }
