#[starknet::contract]
pub mod TreasuryManagement {
    // use crate::contracts::erc721_policy::PolicyNFT::Event;
use starknet::{ ContractAddress, ClassHash };
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    // use core::integer::zeroable::Zeroable;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::IERC20Dispatcher;
    use openzeppelin::token::erc721::interface::IERC721Dispatcher;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;



    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };



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

        // Treasury Storage
        withdrawal_proposals: Map<u256, WithdrawalProposal>,
        //premium per owner per policy_id
        premiums: Map<(ContractAddress, u256), u256>,
        //investment fund per investor per investment_id
        investors_fund: Map<(ContractAddress, u256), u256>,
        gross_premium_written: u256,
        claims_reserve: u256,
        total_equity_fund: u256,
        proposal_nonce: u256,
        asset_balances: Map<(ContractAddress, ContractAddress), u256>, // (asset, token) -> balance
        whitelist: Map<ContractAddress, bool>,
        role_limits: Map<(felt252, ContractAddress), u256>, // (role, asset) -> limit
        timelock_duration: u64,
        proposal_approvals: Map<(u256, ContractAddress), bool> // (proposal_id, approver) -> has_approved
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
        SRC5Event: SRC5Component::Event,
        
        Deposit: Deposit,
        WithdrawalProposed: WithdrawalProposed,
        WithdrawalApproved: WithdrawalApproved,
        WithdrawalExecuted: WithdrawalExecuted,
        WithdrawalRejected: WithdrawalRejected,
        WhitelistUpdated: WhitelistUpdated,
        LimitsUpdated: LimitsUpdated
    }
    

    #[derive(Drop, starknet::Event)]
    struct WithdrawalProposal {
        recipient: ContractAddress,
        amount: u256,
        asset: ContractAddress, // token address (0 for ETH/STRK)
        timestamp: u64,
        status: felt252,
        approvals: u8,
        required_approvals: u8,
        timelock_until: u64
    }

   
    #[derive(Drop, starknet::Event)]
    struct Deposit {
        #[key]
        depositor: ContractAddress,
        asset: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalProposed {
        #[key]
        proposal_id: u256,
        proposer: ContractAddress,
        recipient: ContractAddress,
        asset: ContractAddress,
        amount: u256,
        required_approvals: u8
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalApproved {
        #[key]
        proposal_id: u256,
        approver: ContractAddress,
        role: felt252,
        current_approvals: u8
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalExecuted {
        #[key]
        proposal_id: u256,
        executor: ContractAddress,
        recipient: ContractAddress,
        asset: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalRejected {
        #[key]
        proposal_id: u256,
        rejector: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct WhitelistUpdated {
        #[key]
        address: ContractAddress,
        whitelisted: bool
    }

    #[derive(Drop, starknet::Event)]
    struct LimitsUpdated {
        #[key]
        role: felt252,
        asset: ContractAddress,
        new_limit: u256
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

        // Set timelock duration
        self.timelock_duration.write(timelock_duration);
    }

    // ========== ASSET MANAGEMENT ==========

    // #[external(v0)]
    // fn deposit(
    //     ref self: ContractState, 
    //     asset: ContractAddress, 
    //     amount: Uint256
    // ) {
    //     let caller = get_caller_address();
        
    //     if asset.is_zero() {
    //         // ETH/STRK deposit - value should be sent with call
    //         // Balance tracking happens automatically
    //         self.emit(Deposit { depositor: caller, asset: asset, amount: amount });
    //         return ();
    //     }

    //     // ERC20 token deposit
    //     let token = IERC20Dispatcher { contract_address: asset };
    //     let current_allowance = token.allowance(caller, get_contract_address());
    //     assert(current_allowance >= amount, 'Insufficient allowance');

    //     token.transfer_from(caller, get_contract_address(), amount);
        
    //     // Update balance
    //     let current_balance = self.asset_balances.read((asset, caller));
    //     self.asset_balances.write((asset, caller), current_balance + amount);

    //     self.emit(Deposit { depositor: caller, asset: asset, amount: amount });
    // }

    // #[external(v0)]
    // fn deposit_eth(ref self: ContractState) {
    //     let caller = get_caller_address();
    //     // ETH balance is tracked automatically by the protocol
    //     self.emit(Deposit { 
    //         depositor: caller, 
    //         asset: ContractAddress::default(), 
    //         amount: Uint256 { low: 0, high: 0 } // Actual amount handled by protocol
    //     });
    // }

    // // ========== WITHDRAWAL PROPOSAL SYSTEM ==========

    // #[external(v0)]
    // #[access_control(role: "TREASURY_MANAGER")]
    // fn propose_withdrawal(
    //     ref self: ContractState,
    //     recipient: ContractAddress,
    //     amount: Uint256,
    //     asset: ContractAddress,
    //     required_approvals: u8
    // ) -> u256 {
    //     self.pausable.assert_not_paused();
    //     assert(required_approvals > 0, 'Required approvals must be > 0');
    //     assert(self.whitelist.read(recipient), 'Recipient not whitelisted');

    //     // Check treasury balance
    //     let treasury_balance = self.get_asset_balance(asset);
    //     assert(treasury_balance >= amount, 'Insufficient treasury balance');

    //     let proposal_id = self.proposal_nonce.read();
    //     let timestamp = get_block_timestamp();
    //     let timelock_until = timestamp + self.timelock_duration.read();

    //     let proposal = WithdrawalProposal {
    //         recipient: recipient,
    //         amount: amount,
    //         asset: asset,
    //         timestamp: timestamp,
    //         status: STATUS_PENDING,
    //         approvals: 0,
    //         required_approvals: required_approvals,
    //         timelock_until: timelock_until
    //     };

    //     self.withdrawal_proposals.write(proposal_id, proposal);
    //     self.proposal_nonce.write(proposal_id + 1);

    //     self.emit(WithdrawalProposed {
    //         proposal_id: proposal_id,
    //         proposer: get_caller_address(),
    //         recipient: recipient,
    //         asset: asset,
    //         amount: amount,
    //         required_approvals: required_approvals
    //     });

    //     proposal_id
    // }

    // #[external(v0)]
    // #[access_control(role: "TREASURY_GUARDIAN")]
    // fn approve_withdrawal(ref self: ContractState, proposal_id: u256) {
    //     self.pausable.assert_not_paused();
        
    //     let mut proposal = self.withdrawal_proposals.read(proposal_id);
    //     assert(proposal.status == STATUS_PENDING, 'Proposal not pending');
        
    //     let approver = get_caller_address();
    //     assert(!self.proposal_approvals.read((proposal_id, approver)), 'Already approved');

    //     // Check if approver has sufficient privileges based on amount
    //     let approver_role = self.get_approver_role(approver);
    //     let limit = self.role_limits.read((approver_role, proposal.asset));
        
    //     if !limit.is_zero() {
    //         assert(proposal.amount <= limit, 'Amount exceeds approval limit for role');
    //     }

    //     proposal.approvals += 1;
    //     self.proposal_approvals.write((proposal_id, approver), true);

    //     if proposal.approvals >= proposal.required_approvals {
    //         proposal.status = STATUS_APPROVED;
    //     }

    //     self.withdrawal_proposals.write(proposal_id, proposal);

    //     self.emit(WithdrawalApproved {
    //         proposal_id: proposal_id,
    //         approver: approver,
    //         role: self.get_approver_role(approver),
    //         current_approvals: proposal.approvals
    //     });
    // }

    // #[external(v0)]
    // fn execute_withdrawal(ref self: ContractState, proposal_id: u256) {
    //     self.pausable.assert_not_paused();
    //     self.reentrancy_guard._non_reentrant(());
        
    //     let proposal = self.withdrawal_proposals.read(proposal_id);
    //     assert(proposal.status == STATUS_APPROVED, 'Proposal not approved');
    //     assert(get_block_timestamp() >= proposal.timelock_until, 'Timelock not expired');

    //     // Check balance again before execution
    //     let treasury_balance = self.get_asset_balance(proposal.asset);
    //     assert(treasury_balance >= proposal.amount, 'Insufficient treasury balance');

    //     // Execute transfer
    //     self._transfer_assets(proposal.asset, proposal.recipient, proposal.amount);

    //     // Update proposal status
    //     let mut updated_proposal = proposal;
    //     updated_proposal.status = STATUS_EXECUTED;
    //     self.withdrawal_proposals.write(proposal_id, updated_proposal);

    //     // Update treasury balance
    //     self._update_balance(proposal.asset, proposal.amount, false);

    //     self.emit(WithdrawalExecuted {
    //         proposal_id: proposal_id,
    //         executor: get_caller_address(),
    //         recipient: proposal.recipient,
    //         asset: proposal.asset,
    //         amount: proposal.amount
    //     });
    // }

    // #[external(v0)]
    // #[access_control(role: "TREASURY_GUARDIAN")]
    // fn reject_withdrawal(ref self: ContractState, proposal_id: u256) {
    //     let mut proposal = self.withdrawal_proposals.read(proposal_id);
    //     assert(proposal.status == STATUS_PENDING, 'Proposal not pending');

    //     proposal.status = STATUS_REJECTED;
    //     self.withdrawal_proposals.write(proposal_id, proposal);

    //     self.emit(WithdrawalRejected {
    //         proposal_id: proposal_id,
    //         rejector: get_caller_address()
    //     });
    // }

    // // ========== ADMIN FUNCTIONS ==========

    // #[external(v0)]
    // #[access_control(role: "DEFAULT_ADMIN_ROLE")]
    // fn set_withdrawal_limit(
    //     ref self: ContractState,
    //     role: felt252,
    //     asset: ContractAddress,
    //     limit: Uint256
    // ) {
    //     self.role_limits.write((role, asset), limit);
    //     self.emit(LimitsUpdated { role: role, asset: asset, new_limit: limit });
    // }

    // #[external(v0)]
    // #[access_control(role: "DEFAULT_ADMIN_ROLE")]
    // fn update_whitelist(
    //     ref self: ContractState,
    //     address: ContractAddress,
    //     whitelisted: bool
    // ) {
    //     self.whitelist.write(address, whitelisted);
    //     self.emit(WhitelistUpdated { address: address, whitelisted: whitelisted });
    // }

    // #[external(v0)]
    // #[access_control(role: "DEFAULT_ADMIN_ROLE")]
    // fn set_timelock_duration(ref self: ContractState, duration: u64) {
    //     self.timelock_duration.write(duration);
    // }

    // #[external(v0)]
    // #[access_control(role: "DEFAULT_ADMIN_ROLE")]
    // fn pause_treasury(ref self: ContractState) {
    //     self.pausable._pause();
    // }

    // #[external(v0)]
    // #[access_control(role: "DEFAULT_ADMIN_ROLE")]
    // fn unpause_treasury(ref self: ContractState) {
    //     self.pausable._unpause();
    // }

    // // ========== VIEW FUNCTIONS ==========

    // #[view]
    // fn get_asset_balance(self: @ContractState, asset: ContractAddress) -> Uint256 {
    //     if asset.is_zero() {
    //         // Return ETH balance (pseudo-code - actual implementation may vary)
    //         return Uint256 { low: 0, high: 0 }; // Placeholder
    //     }
    //     let token = IERC20Dispatcher { contract_address: asset };
    //     token.balance_of(get_contract_address())
    // }

    // #[view]
    // fn get_proposal(self: @ContractState, proposal_id: u256) -> WithdrawalProposal {
    //     self.withdrawal_proposals.read(proposal_id)
    // }

    // #[view]
    // fn is_whitelisted(self: @ContractState, address: ContractAddress) -> bool {
    //     self.whitelist.read(address)
    // }

    // #[view]
    // fn get_withdrawal_limit(
    //     self: @ContractState, 
    //     role: felt252, 
    //     asset: ContractAddress
    // ) -> Uint256 {
    //     self.role_limits.read((role, asset))
    // }

    // // ========== INTERNAL FUNCTIONS ==========

    // fn _transfer_assets(
    //     ref self: ContractState,
    //     asset: ContractAddress,
    //     recipient: ContractAddress,
    //     amount: Uint256
    // ) {
    //     if asset.is_zero() {
    //         // Transfer ETH/STRK
    //         let _ = starknet::call_contract_syscall(
    //             recipient, 
    //             selector: 'transfer', 
    //             calldata: array![amount.low, amount.high]
    //         );
    //     } else {
    //         // Transfer ERC20 tokens
    //         let token = IERC20Dispatcher { contract_address: asset };
    //         token.transfer(recipient, amount);
    //     }
    // }

    // fn _update_balance(
    //     ref self: ContractState,
    //     asset: ContractAddress,
    //     amount: Uint256,
    //     is_deposit: bool
    // ) {
    //     if !asset.is_zero() {
    //         let current_balance = self.asset_balances.read((asset, get_contract_address()));
    //         let new_balance = if is_deposit {
    //             current_balance + amount
    //         } else {
    //             current_balance - amount
    //         };
    //         self.asset_balances.write((asset, get_contract_address()), new_balance);
    //     }
    // }

    // fn get_approver_role(self: @ContractState, approver: ContractAddress) -> felt252 {
    //     if self.access.has_role(TREASURY_GUARDIAN_ROLE, approver) {
    //         return TREASURY_GUARDIAN_ROLE;
    //     }
    //     if self.access.has_role(TREASURY_MANAGER_ROLE, approver) {
    //         return TREASURY_MANAGER_ROLE;
    //     }
    //     if self.access.has_role(DEFAULT_ADMIN_ROLE, approver) {
    //         return DEFAULT_ADMIN_ROLE;
    //     }
    //     'UNAUTHORIZED'
    // }


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
