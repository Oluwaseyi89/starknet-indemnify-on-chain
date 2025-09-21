use crate::enums::enums::*;

use crate::enums::enums::ClaimStatus;
use crate::enums::enums::UpdateType;
use crate::enums::enums::BurnReason;

pub fn convert_rejection_reason_to_code(reason: RejectionReason) -> u8 {

    let code: u8 = match reason {
        RejectionReason::IncompleteProposal => 0,
        RejectionReason::Misrepresentation => 1,
        RejectionReason::NonDisclosure => 2,
        RejectionReason::RiskTooHigh => 3,
        RejectionReason::LacksInsurableInterest => 4,
        RejectionReason::PoorMoralHazard => 5,
        RejectionReason::PoorPhysicalHazard => 6,
        RejectionReason::UndisclosedReason => 7,
        RejectionReason::NotRejected => 8,
        RejectionReason::LacksKYC => 9,
        RejectionReason::InvalidReason => 100
    };

    code
}

pub fn convert_rejection_code_to_reason(code: u8) -> RejectionReason {
    let reason: RejectionReason = match code {
        0 => RejectionReason::IncompleteProposal,
        1 => RejectionReason::Misrepresentation,
        2 => RejectionReason::NonDisclosure,
        3 => RejectionReason::RiskTooHigh,
        4 => RejectionReason::LacksInsurableInterest,
        5 => RejectionReason::PoorMoralHazard,
        6 => RejectionReason::PoorPhysicalHazard,
        7 => RejectionReason::UndisclosedReason,
        8 => RejectionReason::NotRejected,
        9 => RejectionReason::LacksKYC,
        _ => RejectionReason::InvalidReason
    };

    reason
}


pub fn convert_proposal_status_to_code(status: ProposalStatus) -> u8 {
    let code: u8 = match status {
        ProposalStatus::Draft => 0,
        ProposalStatus::Submitted => 1,
        ProposalStatus::UnderReview => 2,
        ProposalStatus::Approved => 3,
        ProposalStatus::Rejected => 4,
        ProposalStatus::Expired => 5,
        ProposalStatus::InvalidStatus => 100
    };

    code
}

pub fn convert_proposal_code_to_status(code: u8) -> ProposalStatus {

    let status: ProposalStatus = match code {
        0 => ProposalStatus::Draft,
        1 => ProposalStatus::Submitted,
        2 => ProposalStatus::UnderReview,
        3 => ProposalStatus::Approved,
        4 => ProposalStatus::Rejected,
        5 => ProposalStatus::Expired,
        _ => ProposalStatus::InvalidStatus
    };

    status
}


pub fn convert_policy_code_to_class (code: u8) -> PolicyClass {

    let policy_class: PolicyClass = match code {

        0 => PolicyClass::TravelInsurance,
        1 => PolicyClass::BlockchainExploitInsurance,
        2 => PolicyClass::FireInsurance,
        3 => PolicyClass::MotorInsurance,
        4 => PolicyClass::PersonalAccidentInsurance,
        5 => PolicyClass::HealthInsurance,
        _ => PolicyClass::InvalidClassOfInsurance
    };

    policy_class
}


pub fn convert_policy_class_to_code (policy_class: PolicyClass) -> u8 {
    let code: u8 = match policy_class {
        PolicyClass::TravelInsurance => 0,
        PolicyClass::BlockchainExploitInsurance => 1,
        PolicyClass::FireInsurance => 2,
        PolicyClass::MotorInsurance => 3,
        PolicyClass::PersonalAccidentInsurance => 4,
        PolicyClass::HealthInsurance => 5,
        PolicyClass::InvalidClassOfInsurance => 100,        
    };

    code
}

pub fn convert_premium_frequency_to_code(frequency: PremiumFrequency) -> u8 {
    
    let code: u8 = match frequency {
        PremiumFrequency::Monthly => 0,
        PremiumFrequency::Quarterly => 1,
        PremiumFrequency::HalfYearly => 2,
        PremiumFrequency::Annually => 3,
        PremiumFrequency::InvalidFrequency => 100
    };

    code 
}

pub fn convert_premium_code_to_frequency(code: u8) -> PremiumFrequency {

    let frequency: PremiumFrequency = match code {
        0 => PremiumFrequency::Monthly,
        1 => PremiumFrequency::Quarterly,
        2 => PremiumFrequency::HalfYearly,
        3 => PremiumFrequency::Annually,
        _ => PremiumFrequency::InvalidFrequency
    };

    frequency
}


pub fn convert_code_to_burn_reason (reason_index: u8) -> BurnReason {

    let burn_reason: BurnReason = match reason_index {
        0 => BurnReason::PolicyExpired,
        1 => BurnReason::PolicyCancelled,
        2 => BurnReason::FraudulentClaim,
        3 => BurnReason::RecklessRepresentation,
        _ => BurnReason::InvalidReason

    };

    burn_reason
}  


pub fn convert_burn_reason_to_code (burn_reason: BurnReason) -> u8 {

    let code: u8 = match burn_reason {
        BurnReason::PolicyExpired => 0,
        BurnReason::PolicyCancelled => 1,
        BurnReason::FraudulentClaim => 2,
        BurnReason::RecklessRepresentation => 3,
        BurnReason::InvalidReason => 100

    };

    code
}  

pub fn convert_code_to_policy_update_type (code: u8) -> UpdateType {

    let mut update_type: UpdateType = match code {
        0 => UpdateType::Endorsement,
        1 => UpdateType::Renewal,
        _ => UpdateType::InvalidUpdateType
    };

    update_type
}


pub fn convert_policy_update_type_to_code (update_type: UpdateType) -> u8 {

    let mut code: u8 = match update_type {
        UpdateType::Endorsement => 0,
        UpdateType::Renewal => 1,
        UpdateType::InvalidUpdateType => 100
    };

    code
}




pub fn convert_claim_status_to_code (status: ClaimStatus) -> u8 {

    let code: u8 = match status {
        ClaimStatus::Submitted => 0,
        ClaimStatus::UnderReview => 1,
        ClaimStatus::Approved => 2,
        ClaimStatus::Repudiated => 3,
        ClaimStatus::Settled => 4,
        ClaimStatus::InvalidStatus => 100
    };

    code 
}


pub fn convert_claim_code_to_status (code: u8) -> ClaimStatus {

    let status: ClaimStatus = match code {
        0 => ClaimStatus::Submitted,
        1 => ClaimStatus::UnderReview,
        2 => ClaimStatus::Approved,
        3 => ClaimStatus::Repudiated,
        4 => ClaimStatus::Settled,
        _ => ClaimStatus::InvalidStatus
    };

    status
}

pub fn convert_repudiation_reason_to_code (reason: ClaimRepudiationReason) -> u8 {

    let code: u8 = match reason {
        ClaimRepudiationReason::NonDisclosure => 0,
        ClaimRepudiationReason::Misrepresentation => 1,
        ClaimRepudiationReason::PolicyExclusion => 2,
        ClaimRepudiationReason::FraudulentClaim => 3,
        ClaimRepudiationReason::LapsedPolicy => 4,
        ClaimRepudiationReason::PolicyTermsAndConditionsBreach => 5,
        ClaimRepudiationReason::InsufficientDocumentation => 6,
        ClaimRepudiationReason::IllegalClaim => 7,
        ClaimRepudiationReason::LackOfInsurableInterest => 8,
        ClaimRepudiationReason::NotRepudiated => 9,
        ClaimRepudiationReason::InvalidRepudiationReason => 100
    };

    code
}

pub fn convert_repudiation_code_to_reason (code: u8) -> ClaimRepudiationReason {

    let reason: ClaimRepudiationReason = match code {
        0 => ClaimRepudiationReason::NonDisclosure,
        1 => ClaimRepudiationReason::Misrepresentation,
        2 => ClaimRepudiationReason::PolicyExclusion,
        3 => ClaimRepudiationReason::FraudulentClaim,
        4 => ClaimRepudiationReason::LapsedPolicy,
        5 => ClaimRepudiationReason::PolicyTermsAndConditionsBreach,
        6 => ClaimRepudiationReason::InsufficientDocumentation,
        7 => ClaimRepudiationReason::IllegalClaim,
        8 => ClaimRepudiationReason::LackOfInsurableInterest,
        9 => ClaimRepudiationReason::NotRepudiated,
        _ => ClaimRepudiationReason::InvalidRepudiationReason
    };

    reason

}



pub fn convert_claim_type_to_code (claim_type: ClaimType) -> u8 {

    let code: u8 = match claim_type {
        ClaimType::Small => 0,
        ClaimType::Medium => 1,
        ClaimType::Large => 2,
        ClaimType::Catastrophic => 3,
        ClaimType::Undetermined => 4,
        ClaimType::InvalidClaimType => 100
    };

    code
}


pub fn convert_claim_code_to_type (code: u8) -> ClaimType {
    
    let claim_type: ClaimType = match code {
        0 => ClaimType::Small,
        1 => ClaimType::Medium,
        2 => ClaimType::Large,
        3 => ClaimType::Catastrophic,
        4 => ClaimType::Undetermined,
        _ => ClaimType::InvalidClaimType

    };

    claim_type
}