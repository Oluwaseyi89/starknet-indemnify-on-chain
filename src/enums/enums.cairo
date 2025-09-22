
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
pub enum RejectionReason {
    IncompleteProposal,
    Misrepresentation,
    NonDisclosure,
    RiskTooHigh,
    LacksInsurableInterest,
    PoorMoralHazard,
    PoorPhysicalHazard,
    UndisclosedReason,
    NotRejected,
    LacksKYC,
    InvalidReason
}


#[derive(Drop, Copy, Serde)]
pub enum ProposalStatus {
    Draft,
    Submitted,
    UnderReview,
    Approved,
    Rejected,
    Expired,
    InvalidStatus  
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
pub enum BurnReason {
    PolicyExpired,
    PolicyCancelled,
    FraudulentClaim,
    RecklessRepresentation,
    InvalidReason
}


#[derive(Drop, Copy, Serde)]
pub enum UpdateType {
    Endorsement,
    Renewal,       
    InvalidUpdateType
}


#[derive(Drop, Copy, Serde)]
pub enum ClaimRepudiationReason {
    NonDisclosure,
    Misrepresentation,
    PolicyExclusion,
    FraudulentClaim,
    LapsedPolicy,
    PolicyTermsAndConditionsBreach,
    InsufficientDocumentation,
    IllegalClaim,
    LackOfInsurableInterest,
    NotRepudiated,
    InvalidRepudiationReason  
}

#[derive(Drop, Copy, Serde)]
pub enum ClaimStatus {
    Submitted,
    UnderReview,
    Approved,
    Repudiated,
    Settled,
    InvalidStatus
}


#[derive(Drop, Copy, Serde)]
pub enum ClaimType {
    Small,
    Medium,
    Large,
    Catastrophic,
    Undetermined,
    InvalidClaimType
}

#[derive(Drop, Copy, Serde)]
pub enum PaymentStatus {
    Pending,
    Processing,
    Successful,
    Failed,
    Cancelled,
    Refunded,
    InvalidPaymentStatus
}

#[derive(Drop, Copy, Serde)]
pub enum ClaimsPaymentSource {
    Reserve,
    Reinsurance,
    InvestorsPool,
    Mixed,
    InvalidPaymentSource
}

#[derive(Drop, Copy, Serde)]
pub enum ReinsuranceStatus {
    Initiated,
    Submitted,
    Acknowledged,
    UnderReview,
    Pending,
    Quoted,
    Negotiated,
    Approved,
    Rejected,
    Withdrawn,
    Expired,
    InvalidReinsuranceStatus
}


#[derive(Drop, Copy, Serde)]
pub enum ReinsuranceContractType {
    Treaty,
    Facultative,
    InvalidContractType
}

pub fn convert_reinsurance_contract_type_to_code(contract_type: ReinsuranceContractType) -> u8 {
    
    let code: u8 = match contract_type {
        ReinsuranceContractType::Treaty => 0,
        ReinsuranceContractType::Facultative => 1,
        ReinsuranceContractType::InvalidContractType => 100,
    };

    code
}

pub fn convert_reinsurance_contract_code_to_type(code: u8) -> ReinsuranceContractType {

    let contract_type: ReinsuranceContractType = match code {
        0 => ReinsuranceContractType::Treaty,
        1 => ReinsuranceContractType::Facultative,
        _ => ReinsuranceContractType::InvalidContractType
    };

    contract_type
}

