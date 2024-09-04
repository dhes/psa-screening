library PSARecommendation version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include FHIRCommon version '4.0.1' called FC

valueset "PSALOINCValueSet": 'http://example.org/fhir/ValueSet/psa-loinc-valueset'

// parameter "Reference Date" DateTime default Now()

context Patient

define "PatientAge":
  AgeInYearsAt(Now())

define "IsEligibleForPSA":
  "PatientAge" >= 50
    and "PatientAge" <= 75

define PSATests:
  [Observation: code in "PSALOINCValueSet"] O
    where O.status in { 'final', 'amended', 'corrected' }

// define LastPSATest:
//   Exists([Observation: code in "PSALOINCValueSet"])
//   // First([Observation: code in "PSALOINCValueSet"] L
//   //     where L.status = 'final'
//   //     sort by effective desc)

// define LastPSATestDate:
// 	LastPSATest.effective.value

define "IsDueForPSA":
  not Exists(PSATests)
      or ( Exists(PSATests)
          and Last(PSATests).effective on or before ( Now() - 1 year )
      )

define "Recommendation":
  "IsEligibleForPSA"
      and "IsDueForPSA"

define "Rationale":
  if "Recommendation" then 'Order PSA' 
    else 'PSA up to date'