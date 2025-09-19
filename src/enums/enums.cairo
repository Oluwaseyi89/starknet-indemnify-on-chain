
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