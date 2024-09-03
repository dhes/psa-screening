library PSARecommendation version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

valueset "PSALOINCValueSet": 'http://example.org/fhir/ValueSet/psa-loinc-valueset'

parameter "Reference Date" DateTime default Now()

context Patient

define "PatientAge":
  // AgeInYearsAt(FHIRHelpers.ToDateTime(Patient.birthDate))
  // AgeInYears(FHIRHelpers.ToDate(Patient.birthDate))
  
  
  AgeInYearsAt("Reference Date")

define "IsEligibleForPSA":
  "PatientAge" >= 50
    and "PatientAge" <= 75

define LastPSATest:
  First([Observation: code in "PSALOINCValueSet"] L
      where L.status = 'final'
      sort by effective desc)

define "IsDueForPSA":
  LastPSATest is null
    or ( end of "LastPSATest".effective + 1 year <= Now() )

define "Recommendation":
  if "IsEligibleForPSA"
    and "IsDueForPSA" then true 
    else false

define "Rationale":
  if "Recommendation"
    then 'Order PSA'
    else 'PSA up to date'