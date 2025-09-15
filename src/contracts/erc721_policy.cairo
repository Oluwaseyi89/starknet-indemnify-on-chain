use starknet::{
    ContractAddress,
};
#[starknet::interface]
pub trait IPolicyNFT<TContractState> {
    fn mint_policy(
        ref self: TContractState,
        recipient: ContractAddress,
        coverage_amount: u256,
        premium: u256,
        expiration_date: u64,
        asset_covered: felt252,
    );
    fn burn_policy(ref self: TContractState, token_id: u256, reason_index: u8);
    fn get_policy_data(self: @TContractState, token_id: u256) -> PolicyData;
    fn set_base_uri(ref self: TContractState, new_base_uri: ByteArray);
    fn update_policy_data(
        ref self: TContractState,
        token_id: u256, 
        coverage_amount: u256,
        premium: u256,
        expiration_date: u64,
        asset_covered: felt252,
    );
}



#[derive(Drop, starknet::Store, Serde, Clone, Copy)]
pub struct PolicyData {
    pub policy_id: u256,
    pub coverage_amount: u256,
    pub premium: u256,
    pub expiration_date: u64,
    pub asset_covered: felt252,
}

#[derive(Drop, starknet::Event)]
    pub struct PolicyUpdated {
        #[key]
        token_id: u256,
        new_coverage_amount: u256,
        new_premium: u256,
        new_expiration_date: u64,
        new_asset_covered: felt252,
    }


    #[derive(Drop, starknet::Event)]
    pub struct PolicyMinted {
        recipient: ContractAddress,
        #[key]
        token_id: u256,
        policy_data: PolicyData,
        minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PolicyBurned {
        burner: ContractAddress,
        token_id: u256,
        reason: BurnReason
    }

#[derive(Drop, Copy, Serde)]
pub enum BurnReason {
    PolicyExpired,
    PolicyCancelled,
    FraudulentClaim,
    RecklessRepresentation,
    InvalidReason
}

#[starknet::contract]
pub mod PolicyNFT {
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess
    };
    use core::traits::Into;

    use super::{
        PolicyData,
        IPolicyNFT,
        BurnReason,
        PolicyMinted,
        PolicyUpdated,
        PolicyBurned
    };
  


    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
    const BURNER_ROLE: felt252 = selector!("BURNER_ROLE");
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");


    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;


    // #[abi(embed_v0)]
    // impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        policy_details: Map<u256, PolicyData>,
        next_policy_id: u256,
        next_token_id: u256,
        base_uri: ByteArray
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        PolicyUpdated: PolicyUpdated,
        PolicyMinted: PolicyMinted,
        PolicyBurned: PolicyBurned
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        admin_address: ContractAddress
    ) {
        self.erc721.initializer(name, symbol, base_uri.clone());
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(AccessControlComponent::DEFAULT_ADMIN_ROLE, admin_address);
        self.accesscontrol._grant_role(MINTER_ROLE, admin_address);
        self.accesscontrol._grant_role(BURNER_ROLE, admin_address);
        self.accesscontrol._grant_role(ADMIN_ROLE, admin_address);
        self.next_policy_id.write(1);
        self.next_token_id.write(1);
        self.base_uri.write(base_uri);
    }
    

    #[abi(embed_v0)]
    pub impl PolicyNFTImpl of IPolicyNFT<ContractState> {

        fn mint_policy(
            ref self: ContractState,
            recipient: ContractAddress,
            coverage_amount: u256,
            premium: u256,
            expiration_date: u64,
            asset_covered: felt252,
        ) {

            let minter: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(MINTER_ROLE, minter), "AccessControl: Caller has no role - Minter_Role");


            let current_token_id: u256 = self.next_token_id.read();
            let current_policy_id: u256 = self.next_policy_id.read();

            let mut mint_call_data: Array<> = array![];

            let policy_data: PolicyData = PolicyData {
                policy_id: current_policy_id,
                coverage_amount: coverage_amount,
                premium: premium,
                expiration_date: expiration_date,
                asset_covered: asset_covered
            };

            policy_data.serialize(ref mint_call_data);

           
            self.erc721.safe_mint(recipient, current_token_id, mint_call_data.span());

            self.policy_details.write(current_token_id, policy_data);

            let policy_minted_event: PolicyMinted = PolicyMinted {
                recipient: recipient,
                token_id: current_token_id,
                policy_data: policy_data,
                minter: minter,
            };

            self.next_policy_id.write(current_policy_id + 1);
            self.next_token_id.write(current_token_id + 1);

            self.emit(policy_minted_event);
        }

        fn burn_policy(ref self: ContractState, token_id: u256, reason_index: u8) {

              let caller_address: ContractAddress = get_caller_address();
              
              assert!(self.accesscontrol.has_role(BURNER_ROLE, caller_address), "AccessControl: Caller has no role - Burner_Role");
              
              self.erc721.burn(token_id); 

            let set_reason: BurnReason = match reason_index {
                0 => BurnReason::PolicyExpired,
                1 => BurnReason::PolicyCancelled,
                2 => BurnReason::FraudulentClaim,
                3 => BurnReason::RecklessRepresentation,
                _ => BurnReason::InvalidReason

            };

            let policy_burn_event: PolicyBurned = PolicyBurned {
                burner: caller_address,
                token_id: token_id,
                reason: set_reason
            };

            self.emit(policy_burn_event);
        }

        fn get_policy_data(self: @ContractState, token_id: u256) -> PolicyData {

            let policy_data: PolicyData = self.policy_details.read(token_id);

            policy_data
        }

        fn set_base_uri(ref self: ContractState, new_base_uri: ByteArray) {
            self.base_uri.write(new_base_uri);
        }
        fn update_policy_data(
            ref self: ContractState, 
            token_id: u256, 
            coverage_amount: u256,
            premium: u256,
            expiration_date: u64,
            asset_covered: felt252,
        ) {
            let current_policy_data: PolicyData = self.policy_details.read(token_id);

            let new_policy_data: PolicyData = PolicyData {
                policy_id: current_policy_data.policy_id,
                coverage_amount: coverage_amount,
                premium: premium,
                expiration_date: expiration_date,
                asset_covered: asset_covered,
            };

            self.policy_details.write(token_id, new_policy_data);

            let policy_update_event: PolicyUpdated = PolicyUpdated {
                token_id: token_id,
                new_coverage_amount: coverage_amount,
                new_premium: premium,
                new_expiration_date: expiration_date,
                new_asset_covered: asset_covered,
            };

            self.emit(policy_update_event);
        }
    }
}