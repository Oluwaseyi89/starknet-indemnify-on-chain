// #[starknet::contract]
// mod InsuranceClaims {
//     use starknet::ContractAddress;
//     use starknet::get_caller_address;
//     use openzeppelin::token::erc20::interface::IERC20Dispatcher;
//     use openzeppelin::access::accesscontrol::AccessControlComponent;
//     use openzeppelin::security::pausable::PausableComponent;
//     use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
//     use openzeppelin::utils::uint::uint256::Uint256;

//     component!(path: AccessControlComponent, storage: access, event: AccessControlEvent);
//     component!(path: PausableComponent, storage: pausable, event: PausableEvent);
//     component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);

//     // Roles
//     const CLAIM_ADJUSTER_ROLE: felt252 = 'CLAIM_ADJUSTER';
//     const CLAIM_APPROVER_ROLE: felt252 = 'CLAIM_APPROVER';
//     const EMERGENCY_MANAGER_ROLE: felt252 = 'EMERGENCY_MANAGER';

//     // Claim statuses
//     const STATUS_PENDING: felt252 = 'PENDING';
//     const STATUS_APPROVED: felt252 = 'APPROVED';
//     const STATUS_DENIED: felt252 = 'DENIED';
//     const STATUS_PAID: felt252 = 'PAID';
//     const STATUS_ESCALATED: felt252 = 'ESCALATED';
//     const STATUS_UNDER_REVIEW: felt252 = 'UNDER_REVIEW';

//     // Claim types
//     const TYPE_SMALL: felt252 = 'SMALL_CLAIM';
//     const TYPE_MEDIUM: felt252 = 'MEDIUM_CLAIM';
//     const TYPE_LARGE: felt252 = 'LARGE_CLAIM';
//     const TYPE_CATASTROPHIC: felt252 = 'CATASTROPHIC_CLAIM';

//     #[derive(Drop, Serde, Copy)]
//     struct InsuranceClaim {
//         policy_id: u256,
//         claimant: ContractAddress,
//         amount: Uint256,
//         currency: ContractAddress, // Token address (0 for ETH/STRK)
//         status: felt252,
//         claim_type: felt252,
//         timestamp: u64,
//         approved_at: u64,
//         evidence_hash: felt252, // IPFS hash of evidence
//         approval_threshold: u8, // Number of approvals needed
//         current_approvals: u8,
//         escalation_reason: felt252
//     }

//     #[derive(Drop, Serde)]
//     struct ClaimEvidence {
//         description: felt252,
//         proof_hash: felt252,
//         witnesses: Array<ContractAddress>,
//         external_reports: Array<felt252>
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     enum Event {
//         AccessControlEvent: AccessControlComponent::Event,
//         PausableEvent: PausableComponent::Event,
//         ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
//         ClaimSubmitted: ClaimSubmitted,
//         ClaimApproved: ClaimApproved,
//         ClaimDenied: ClaimDenied,
//         ClaimPaid: ClaimPaid,
//         ClaimEscalated: ClaimEscalated,
//         EmergencyPayout: EmergencyPayout
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ClaimSubmitted {
//         #[key]
//         claim_id: u256,
//         policy_id: u256,
//         claimant: ContractAddress,
//         amount: Uint256,
//         claim_type: felt252
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ClaimApproved {
//         #[key]
//         claim_id: u256,
//         approver: ContractAddress,
//         amount: Uint256,
//         timestamp: u64
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ClaimDenied {
//         #[key]
//         claim_id: u256,
//         denier: ContractAddress,
//         reason: felt252
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ClaimPaid {
//         #[key]
//         claim_id: u256,
//         recipient: ContractAddress,
//         amount: Uint256,
//         currency: ContractAddress,
//         tx_hash: felt252
//     }

//     #[derive(Drop, starknet::Event)]
//     struct ClaimEscalated {
//         #[key]
//         claim_id: u256,
//         escalator: ContractAddress,
//         reason: felt252,
//         new_threshold: u8
//     }

//     #[derive(Drop, starknet::Event)]
//     struct EmergencyPayout {
//         #[key]
//         claim_id: u256,
//         executor: ContractAddress,
//         amount: Uint256,
//         reason: felt252
//     }

//     #[storage]
//     struct Storage {
//         // OpenZeppelin Components
//         access: AccessControlComponent::Storage,
//         pausable: PausableComponent::Storage,
//         reentrancy_guard: ReentrancyGuardComponent::Storage,

//         // Claims Management Storage
//         claims: LegacyMap::<u256, InsuranceClaim>,
//         claim_evidence: LegacyMap::<u256, ClaimEvidence>,
//         claim_nonce: u256,
//         treasury_contract: ContractAddress,
//         governance_contract: ContractAddress,

//         // Claim thresholds and parameters
//         claim_thresholds: LegacyMap::<felt252, Uint256>,
//         auto_approval_limit: Uint256,
//         max_claim_amount: Uint256,
//         approval_requirements: LegacyMap::<felt252, u8>,

//         // Tracking and analytics
//         total_claims_paid: Uint256,
//         total_premiums_collected: Uint256,
//         claim_approvals: LegacyMap::<(u256, ContractAddress), bool>
//     }

//     #[abi(embed_v0)]
//     impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
//     impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

//     #[abi(embed_v0)]
//     impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
//     impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

//     #[abi(embed_v0)]
//     impl ReentrancyGuardImpl = ReentrancyGuardComponent::ReentrancyGuardImpl<ContractState>;
//     impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

//     #[constructor]
//     fn constructor(
//         ref self: ContractState,
//         admin: ContractAddress,
//         treasury: ContractAddress,
//         governance: ContractAddress,
//         adjusters: Array<ContractAddress>,
//         approvers: Array<ContractAddress>
//     ) {
//         // Initialize OpenZeppelin components
//         self.access.initializer();
//         self.pausable.initializer();
//         self.reentrancy_guard.initializer();

//         // Setup roles
//         self.access._grant_role(DEFAULT_ADMIN_ROLE, admin);
//         self.access._grant_role(CLAIM_ADJUSTER_ROLE, admin);
//         self.access._grant_role(CLAIM_APPROVER_ROLE, admin);
//         self.access._grant_role(EMERGENCY_MANAGER_ROLE, admin);

//         // Grant roles to provided addresses
//         self._grant_roles_to_array(CLAIM_ADJUSTER_ROLE, adjusters);
//         self._grant_roles_to_array(CLAIM_APPROVER_ROLE, approvers);

//         // Set contract addresses
//         self.treasury_contract.write(treasury);
//         self.governance_contract.write(governance);

//         // Initialize claim parameters
//         self.auto_approval_limit.write(Uint256 { low: 100000000000000000u128, high: 0 }); // 0.1 ETH
//         self.max_claim_amount.write(Uint256 { low: 10000000000000000000u128, high: 0 }); // 10 ETH

//         // Set approval requirements by claim type
//         self.approval_requirements.write(TYPE_SMALL, 1);
//         self.approval_requirements.write(TYPE_MEDIUM, 2);
//         self.approval_requirements.write(TYPE_LARGE, 3);
//         self.approval_requirements.write(TYPE_CATASTROPHIC, 5);

//         // Set claim thresholds
//         self.claim_thresholds.write(TYPE_SMALL, Uint256 { low: 50000000000000000u128, high: 0 }); // 0.05 ETH
//         self.claim_thresholds.write(TYPE_MEDIUM, Uint256 { low: 500000000000000000u128, high: 0 }); // 0.5 ETH
//         self.claim_thresholds.write(TYPE_LARGE, Uint256 { low: 5000000000000000000u128, high: 0 }); // 5 ETH
//     }

//     // ========== CLAIM SUBMISSION ==========

//     #[external(v0)]
//     fn submit_claim(
//         ref self: ContractState,
//         policy_id: u256,
//         amount: Uint256,
//         currency: ContractAddress,
//         evidence_hash: felt252,
//         description: felt252
//     ) -> u256 {
//         self.pausable.assert_not_paused();
//         assert(amount > Uint256 { low: 0, high: 0 }, 'Claim amount must be positive');
//         assert(amount <= self.max_claim_amount.read(), 'Claim exceeds maximum amount');

//         let claimant = get_caller_address();
//         let claim_id = self.claim_nonce.read();
        
//         // Determine claim type based on amount
//         let claim_type = self._determine_claim_type(amount);
//         let approval_threshold = self.approval_requirements.read(claim_type);

//         let claim = InsuranceClaim {
//             policy_id: policy_id,
//             claimant: claimant,
//             amount: amount,
//             currency: currency,
//             status: STATUS_PENDING,
//             claim_type: claim_type,
//             timestamp: get_block_timestamp(),
//             approved_at: 0,
//             evidence_hash: evidence_hash,
//             approval_threshold: approval_threshold,
//             current_approvals: 0,
//             escalation_reason: ''
//         };

//         // Store evidence
//         let evidence = ClaimEvidence {
//             description: description,
//             proof_hash: evidence_hash,
//             witnesses: Array::new(),
//             external_reports: Array::new()
//         };

//         self.claims.write(claim_id, claim);
//         self.claim_evidence.write(claim_id, evidence);
//         self.claim_nonce.write(claim_id + 1);

//         self.emit(ClaimSubmitted {
//             claim_id: claim_id,
//             policy_id: policy_id,
//             claimant: claimant,
//             amount: amount,
//             claim_type: claim_type
//         });

//         // Auto-approve small claims
//         if amount <= self.auto_approval_limit.read() {
//             self._auto_approve_claim(claim_id);
//         }

//         claim_id
//     }

//     // ========== CLAIM APPROVAL & MANAGEMENT ==========

//     #[external(v0)]
//     #[access_control(role: "CLAIM_ADJUSTER_ROLE")]
//     fn review_claim(
//         ref self: ContractState,
//         claim_id: u256,
//         approval: bool,
//         reason: felt252
//     ) {
//         self.pausable.assert_not_paused();
        
//         let mut claim = self.claims.read(claim_id);
//         assert(claim.status == STATUS_PENDING || claim.status == STATUS_UNDER_REVIEW, 'Claim not reviewable');

//         let reviewer = get_caller_address();
//         assert(!self.claim_approvals.read((claim_id, reviewer)), 'Already reviewed this claim');

//         if approval {
//             claim.current_approvals += 1;
//             self.claim_approvals.write((claim_id, reviewer), true);

//             if claim.current_approvals >= claim.approval_threshold {
//                 claim.status = STATUS_APPROVED;
//                 claim.approved_at = get_block_timestamp();
//                 self.emit(ClaimApproved {
//                     claim_id: claim_id,
//                     approver: reviewer,
//                     amount: claim.amount,
//                     timestamp: claim.approved_at
//                 });
//             }
//         } else {
//             claim.status = STATUS_DENIED;
//             self.emit(ClaimDenied {
//                 claim_id: claim_id,
//                 denier: reviewer,
//                 reason: reason
//             });
//         }

//         self.claims.write(claim_id, claim);
//     }

//     #[external(v0)]
//     #[access_control(role: "CLAIM_APPROVER_ROLE")]
//     fn escalate_claim(
//         ref self: ContractState,
//         claim_id: u256,
//         reason: felt252,
//         new_threshold: u8
//     ) {
//         let mut claim = self.claims.read(claim_id);
//         assert(claim.status == STATUS_PENDING, 'Claim not pending');
        
//         claim.status = STATUS_ESCALATED;
//         claim.approval_threshold = new_threshold;
//         claim.escalation_reason = reason;

//         self.claims.write(claim_id, claim);

//         self.emit(ClaimEscalated {
//             claim_id: claim_id,
//             escalator: get_caller_address(),
//             reason: reason,
//             new_threshold: new_threshold
//         });
//     }

//     // ========== CLAIM PAYOUT ==========

//     #[external(v0)]
//     #[access_control(role: "CLAIM_APPROVER_ROLE")]
//     fn process_payout(ref self: ContractState, claim_id: u256) {
//         self.pausable.assert_not_paused();
//         self.reentrancy_guard._non_reentrant(());
        
//         let claim = self.claims.read(claim_id);
//         assert(claim.status == STATUS_APPROVED, 'Claim not approved');
//         assert(get_block_timestamp() - claim.approved_at >= 86400u64, '24h waiting period not over'); // 24 hours

//         // Execute payout through treasury
//         self._execute_payout(claim.claimant, claim.amount, claim.currency);

//         // Update claim status
//         let mut updated_claim = claim;
//         updated_claim.status = STATUS_PAID;
//         self.claims.write(claim_id, updated_claim);

//         // Update statistics
//         self.total_claims_paid.write(self.total_claims_paid.read() + claim.amount);

//         self.emit(ClaimPaid {
//             claim_id: claim_id,
//             recipient: claim.claimant,
//             amount: claim.amount,
//             currency: claim.currency,
//             tx_hash: 'treasury_payout' // Would be actual tx hash in implementation
//         });
//     }

//     #[external(v0)]
//     #[access_control(role: "EMERGENCY_MANAGER_ROLE")]
//     fn emergency_payout(
//         ref self: ContractState,
//         claim_id: u256,
//         reason: felt252
//     ) {
//         self.reentrancy_guard._non_reentrant(());
        
//         let claim = self.claims.read(claim_id);
        
//         // Bypass normal approval process for emergencies
//         self._execute_payout(claim.claimant, claim.amount, claim.currency);

//         let mut updated_claim = claim;
//         updated_claim.status = STATUS_PAID;
//         self.claims.write(claim_id, updated_claim);

//         self.emit(EmergencyPayout {
//             claim_id: claim_id,
//             executor: get_caller_address(),
//             amount: claim.amount,
//             reason: reason
//         });
//     }

//     // ========== ADMIN FUNCTIONS ==========

//     #[external(v0)]
//     #[access_control(role: "DEFAULT_ADMIN_ROLE")]
//     fn update_claim_parameters(
//         ref self: ContractState,
//         claim_type: felt252,
//         new_threshold: Uint256,
//         approvals_required: u8
//     ) {
//         self.claim_thresholds.write(claim_type, new_threshold);
//         self.approval_requirements.write(claim_type, approvals_required);
//     }

//     #[external(v0)]
//     #[access_control(role: "DEFAULT_ADMIN_ROLE")]
//     fn pause_claims(ref self: ContractState) {
//         self.pausable._pause();
//     }

//     #[external(v0)]
//     #[access_control(role: "DEFAULT_ADMIN_ROLE")]
//     fn unpause_claims(ref self: ContractState) {
//         self.pausable._unpause();
//     }

//     // ========== VIEW FUNCTIONS ==========

//     #[view]
//     fn get_claim(self: @ContractState, claim_id: u256) -> InsuranceClaim {
//         self.claims.read(claim_id)
//     }

//     #[view]
//     fn get_claim_evidence(self: @ContractState, claim_id: u256) -> ClaimEvidence {
//         self.claim_evidence.read(claim_id)
//     }

//     #[view]
//     fn get_claim_stats(self: @ContractState) -> (Uint256, Uint256) {
//         (self.total_claims_paid.read(), self.total_premiums_collected.read())
//     }

//     #[view]
//     fn can_auto_approve(self: @ContractState, amount: Uint256) -> bool {
//         amount <= self.auto_approval_limit.read()
//     }

//     // ========== INTERNAL FUNCTIONS ==========

//     fn _execute_payout(
//         ref self: ContractState,
//         recipient: ContractAddress,
//         amount: Uint256,
//         currency: ContractAddress
//     ) {
//         // Call treasury contract to execute payout
//         let treasury_calldata = array![
//             recipient.into(), 
//             amount.low.into(), 
//             amount.high.into(), 
//             currency.into()
//         ];
        
//         let _ = starknet::call_contract_syscall(
//             self.treasury_contract.read(),
//             selector: 'execute_payout',
//             calldata: treasury_calldata
//         );
//     }

//     fn _determine_claim_type(self: @ContractState, amount: Uint256) -> felt252 {
//         let small_threshold = self.claim_thresholds.read(TYPE_SMALL);
//         let medium_threshold = self.claim_thresholds.read(TYPE_MEDIUM);
//         let large_threshold = self.claim_thresholds.read(TYPE_LARGE);

//         if amount <= small_threshold {
//             TYPE_SMALL
//         } else if amount <= medium_threshold {
//             TYPE_MEDIUM
//         } else if amount <= large_threshold {
//             TYPE_LARGE
//         } else {
//             TYPE_CATASTROPHIC
//         }
//     }

//     fn _auto_approve_claim(ref self: ContractState, claim_id: u256) {
//         let mut claim = self.claims.read(claim_id);
//         claim.status = STATUS_APPROVED;
//         claim.approved_at = get_block_timestamp();
//         claim.current_approvals = claim.approval_threshold;
        
//         self.claims.write(claim_id, claim);
        
//         self.emit(ClaimApproved {
//             claim_id: claim_id,
//             approver: get_contract_address(),
//             amount: claim.amount,
//             timestamp: claim.approved_at
//         });
//     }

//     fn _grant_roles_to_array(ref self: ContractState, role: felt252, addresses: Array<ContractAddress>) {
//         loop {
//             match addresses.pop_front() {
//                 Option::Some(address) => {
//                     self.access._grant_role(role, address);
//                 },
//                 Option::None(_) => {
//                     break;
//                 }
//             };
//         }
//     }

//     fn _assert_has_role(self: @ContractState, role: felt252) {
//         self.access._assert_has_role(role, get_caller_address());
//     }
// }