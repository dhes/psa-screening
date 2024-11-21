library PSARecommendation version '1.0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

valueset PSALOINCValueSet: 'http://example.org/fhir/ValueSet/psa-loinc-valueset'

codesystem "LOINC": 'http://loinc.org'

code "Birthdate": '21112-8' from "LOINC" display 'Birth date'
code "PSA Follow-up": '21979-0' from "LOINC" display 'Planned/next follow-up'

parameter ReferenceDate Date default Today()

context Patient

define A:
  (singleton from (Patient.extension E where E.url='http://example.org/fhir/StructureDefinition/patient-annotation')).value.value

define Age:
  AgeInYearsAt(ReferenceDate)

define Man:
  Patient.gender='male'

define OlderThan40:
  Age >= 40

define PSATests:
  [Observation: code in PSALOINCValueSet] O
    where O.status in { 'final', 'amended', 'corrected' }

define FollowUpObservation:
	[Observation: "PSA Follow-up"] O
		where O.status in { 'final', 'amended', 'corrected' }

define FollowUpDuration:
	First(FollowUpObservation.value) as Quantity

define OldestAcceptablePSA:
ReferenceDate - Coalesce(FollowUpDuration, 2 years)

define MostRecentPSATestDate:
	Last(PSATests).effective.value

define StringValueOfMostRecentPSATestDate:
	ToString(Last(PSATests).effective.value)

define RecentPSA:
  exists ( PSATests )
  and date from Last(PSATests).effective on or after OldestAcceptablePSA

define "Tickle":
  OlderThan40 and Man and not RecentPSA

define "Reminder":
  if "Tickle" then 'Discuss PSA' 
    else ''