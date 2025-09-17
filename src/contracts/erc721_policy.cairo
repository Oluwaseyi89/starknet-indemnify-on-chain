use starknet::{
    ContractAddress,
};

use core::array::Array;
#[starknet::interface]
pub trait IPolicyNFT<TContractState> {
    fn mint_policy(
        ref self: TContractState,
        policyholder: ContractAddress,
        policy_class_code: u8,
        subject_matter: ByteArray,
        sum_insured: u256,
        premium: u256,
        premium_frequency_code: u8,
        frequency_factor: u8,
    );
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
}



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

#[derive(Drop, starknet::Event)]
    pub struct PolicyUpdated {
        #[key]
        token_id: u256,
        sum_insured: u256,
        premium: u256,
        endorsement_amount: u256,
        expiration_date: u64,
        subject_matter: ByteArray,
        update_type: UpdateType
    }


    #[derive(Drop, starknet::Event)]
    pub struct PolicyMinted {
        #[key]
        token_id: u256,
        policyholder: ContractAddress,
        policy_class: PolicyClass,
        subject_matter: ByteArray,
        sum_insured: u256,
        premium: u256,
        premium_frequency: PremiumFrequency,
        frequency_factor: u8,
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

    #[derive(Drop, Copy, Serde)]
    pub enum PremiumFrequency {
        Monthly,
        Quarterly,
        HalfYearly,
        Annually,
        InvalidFrequency
    }

    #[derive(Drop, Copy, Serde)]
    pub enum PolicyClass {
        TravelInsurance,
        BlockchainExploitInsurance,
        FireInsurance,
        MotorInsurance,
        PersonalAccidentInsurance,
        HealthInsurance,
        InvalidClassOfInsurance
    }

    #[derive(Drop, Copy, Serde)]
    pub enum UpdateType {
        Endorsement,
        Renewal,       
        InvalidUpdateType
    }
 


#[starknet::contract]
pub mod PolicyNFT {
    use starknet::get_block_timestamp;
    use openzeppelin_access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ContractAddress, ClassHash, get_caller_address};
    use starknet::storage::{
        Map,
        Vec,
        VecTrait,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
        StoragePathEntry
    };
    use core::traits::Into;

    use super::{
        PolicyData,
        IPolicyNFT,
        BurnReason,
        PolicyMinted,
        PolicyUpdated,
        PolicyBurned,
        PolicyClass,
        PremiumFrequency,
        PolicyDataResponse,
        UpdateType
    };
  

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
    const BURNER_ROLE: felt252 = selector!("BURNER_ROLE");
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");

    const ONE_MONTH: u64 = 3600 * 24 * 30;
    const ONE_QUARTER: u64 = ONE_MONTH * 3;
    const HALF_YEAR: u64 = ONE_MONTH * 6;
    const ONE_YEAR: u64 = ONE_MONTH * 12;


    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl = AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;


    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;


    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        policy_details: Map<u256, PolicyData>,
        general_claim_ids: Map<u256, Vec<u128>>,
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
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
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
            policyholder: ContractAddress,
            policy_class_code: u8,
            subject_matter: ByteArray,
            sum_insured: u256,
            premium: u256,
            premium_frequency_code: u8,
            frequency_factor: u8,
        ) {

            let minter: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(MINTER_ROLE, minter), "AccessControl: Caller has no role - Minter_Role");


            let current_token_id: u256 = self.next_token_id.read();
            let current_policy_id: u256 = self.next_policy_id.read();


            let mut premium_frequency_choice: PremiumFrequency = match premium_frequency_code {
                0 => PremiumFrequency::Monthly,
                1 => PremiumFrequency::Quarterly,
                2 => PremiumFrequency::HalfYearly,
                3 => PremiumFrequency::Annually,             
                _ => PremiumFrequency::InvalidFrequency
            };

            let mut term_length_factor: u64 = match premium_frequency_code {
                0 => ONE_MONTH,
                1 => ONE_QUARTER,
                2 => HALF_YEAR,
                3 => ONE_YEAR,
                _ => 0
            };

            let mut mint_call_data: Array<> = array![];

            let start_date_time: u64 = get_block_timestamp();

            let term_length: u64 = term_length_factor * frequency_factor.into();

            let expiry_time: u64 = start_date_time + term_length;

            assert!(term_length <= ONE_YEAR, "PolicyMintDenied: Insurance term cannot be more than One Year");

 

            let mut policy_class_choice: PolicyClass = match policy_class_code {
                0 => PolicyClass::TravelInsurance,
                1 => PolicyClass::BlockchainExploitInsurance,
                2 => PolicyClass::FireInsurance,
                3 => PolicyClass::MotorInsurance,
                4 => PolicyClass::PersonalAccidentInsurance,
                5 => PolicyClass::HealthInsurance,
                _ => PolicyClass::InvalidClassOfInsurance
            };




            let policy_data: PolicyData = PolicyData {
                policy_id: current_policy_id,
                policyholder: policyholder,
                policy_class_code: policy_class_code,
                subject_matter: subject_matter.clone(),
                sum_insured: sum_insured,
                premium: premium,
                premium_frequency_code: premium_frequency_code,
                frequency_factor: frequency_factor,
                start_date: start_date_time,
                expiration_date: expiry_time,
                is_active: true,
                is_expired: false,
                claims_count: 0,
                has_claimed: false,
                aggregate_claim_amount: 0                
            };

            let policy_data_response: PolicyDataResponse = PolicyDataResponse {
                policy_id: current_policy_id,
                policyholder: policyholder,
                policy_class: policy_class_choice,
                subject_matter: subject_matter.clone(),
                sum_insured: sum_insured,
                premium: premium,
                premium_frequency: premium_frequency_choice,
                frequency_factor: frequency_factor,
                start_date: start_date_time,
                expiration_date: expiry_time,
                is_active: true,
                is_expired: false,
                claims_count: 0,
                has_claimed: false,
                claim_ids: array![],
                aggregate_claim_amount: 0
            };


            policy_data_response.serialize(ref mint_call_data);

           
            self.erc721.safe_mint(policyholder, current_token_id, mint_call_data.span());

            self.policy_details.write(current_token_id, policy_data);


            let policy_minted_event: PolicyMinted = PolicyMinted {
                token_id: current_token_id,
                policyholder: policyholder,
                policy_class: policy_class_choice,
                subject_matter: subject_matter,
                sum_insured: sum_insured,
                premium: premium,
                premium_frequency: premium_frequency_choice,
                frequency_factor: frequency_factor,
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

        fn get_policy_data(self: @ContractState, token_id: u256) -> PolicyDataResponse {

            let policy_data: PolicyData = self.policy_details.read(token_id);

            let mut policy_class_choice: PolicyClass = match policy_data.policy_class_code {
                0 => PolicyClass::TravelInsurance,
                1 => PolicyClass::BlockchainExploitInsurance,
                2 => PolicyClass::FireInsurance,
                3 => PolicyClass::MotorInsurance,
                4 => PolicyClass::PersonalAccidentInsurance,
                5 => PolicyClass::HealthInsurance,
                _ => PolicyClass::InvalidClassOfInsurance
            };

            let mut premium_frequency_choice: PremiumFrequency = match policy_data.premium_frequency_code {
                0 => PremiumFrequency::Monthly,
                1 => PremiumFrequency::Quarterly,
                2 => PremiumFrequency::HalfYearly,
                3 => PremiumFrequency::Annually,             
                _ => PremiumFrequency::InvalidFrequency
            };

            let mut claim_array: Array<u256> = array![]; 

            let len: u64 = self.general_claim_ids.entry(token_id).len();

            for i in 0..len {
                claim_array.append(self.general_claim_ids.entry(token_id).at(i).read().into());
            };

            let policy_data_response: PolicyDataResponse = PolicyDataResponse {
                policy_id: policy_data.policy_id,
                policyholder: policy_data.policyholder,
                policy_class: policy_class_choice,
                subject_matter: policy_data.subject_matter,
                sum_insured: policy_data.sum_insured,
                premium: policy_data.premium,
                premium_frequency: premium_frequency_choice,
                frequency_factor: policy_data.frequency_factor,
                start_date: policy_data.start_date,
                expiration_date: policy_data.expiration_date,
                is_active: policy_data.is_active,
                is_expired: policy_data.is_expired,
                claims_count: policy_data.claims_count,
                has_claimed: policy_data.has_claimed,
                claim_ids: claim_array,
                aggregate_claim_amount: policy_data.aggregate_claim_amount
            };

            policy_data_response
        }

        fn set_base_uri(ref self: ContractState, new_base_uri: ByteArray) {
            self.base_uri.write(new_base_uri);
        }
        fn update_policy_data(
            ref self: ContractState, 
            token_id: u256, 
            subject_matter: ByteArray,
            sum_insured: u256,
            premium: u256,
            premium_frequency_code: u8,
            frequency_factor: u8,
            update_type_code: u8,
            endorsement_amount: u256
        ) {

            let current_policy_data: PolicyData = self.policy_details.read(token_id);

            let time_delta: (u64, u64) = delta_time_choice(update_type_code, premium_frequency_code, frequency_factor);

            let (start, expire) = time_delta;     

            let time_diff_renewal: u64 = expire - start;

            assert!(time_diff_renewal <= ONE_YEAR, "UpdateDenied: Insurance term cannot exceed One Year");



            let mut new_policy_data: PolicyData =  match update_type_code {
                0 => PolicyData {
                        policy_id: current_policy_data.policy_id,
                        policyholder: current_policy_data.policyholder,
                        policy_class_code: current_policy_data.policy_class_code,
                        subject_matter: subject_matter.clone(),
                        sum_insured: sum_insured,
                        premium: premium,
                        premium_frequency_code: premium_frequency_code,
                        frequency_factor: frequency_factor,
                        start_date: current_policy_data.start_date,
                        expiration_date: current_policy_data.expiration_date,
                        is_active: current_policy_data.is_active,
                        is_expired: current_policy_data.is_expired,
                        claims_count: current_policy_data.claims_count,
                        has_claimed: current_policy_data.has_claimed,
                        aggregate_claim_amount: current_policy_data.aggregate_claim_amount     
                    },
                1 => PolicyData {
                        policy_id: current_policy_data.policy_id,
                        policyholder: current_policy_data.policyholder,
                        policy_class_code: current_policy_data.policy_class_code,
                        subject_matter: subject_matter.clone(),
                        sum_insured: sum_insured,
                        premium: premium,
                        premium_frequency_code: premium_frequency_code,
                        frequency_factor: frequency_factor,
                        start_date: start,
                        expiration_date: expire,
                        is_active: current_policy_data.is_active,
                        is_expired: current_policy_data.is_expired,
                        claims_count: current_policy_data.claims_count,
                        has_claimed: current_policy_data.has_claimed,
                        aggregate_claim_amount: current_policy_data.aggregate_claim_amount     
                    },
                _ => current_policy_data
            };

            

            self.policy_details.write(token_id, new_policy_data.clone());

            let mut update_type_var: UpdateType = match update_type_code {
                0 => UpdateType::Endorsement,
                1 => UpdateType::Renewal,
                _ => UpdateType::InvalidUpdateType
            };

            let policy_update_event: PolicyUpdated = PolicyUpdated {
                token_id: token_id,
                sum_insured: sum_insured,
                premium: premium,
                endorsement_amount: endorsement_amount,
                expiration_date: new_policy_data.expiration_date,
                subject_matter: subject_matter,
                update_type: update_type_var
            };

            self.emit(policy_update_event);
        }
    }

    fn delta_time_choice(update_code: u8, frequency_code: u8, frequency_factor: u8) -> (u64, u64) {

        let time_choice: u64 = match frequency_code {
            0 => ONE_MONTH * frequency_factor.into(),
            1 => ONE_QUARTER * frequency_factor.into(),
            2 => HALF_YEAR * frequency_factor.into(),
            3 => ONE_YEAR * frequency_factor.into(),
            _ => 0
        };

        let current_time: u64 = get_block_timestamp();
        let expiry_time: u64 = current_time + time_choice;

        let delta: (u64, u64) = match update_code {           
            0 => (0, 0),
            1 => (current_time, expiry_time),
            _ => (0, 0)
        };

        delta
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {

            let caller: ContractAddress = get_caller_address();

            assert!(self.accesscontrol.has_role(ADMIN_ROLE, caller), "AccessControl: Caller is not the Admin");

            self.upgradeable.upgrade(new_class_hash);
        }
    }
}