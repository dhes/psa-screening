library PSARecommendation version '1.0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

valueset PSALOINCValueSet: 'http://example.org/fhir/ValueSet/psa-loinc-valueset'

codesystem "LOINC": 'http://loinc.org'

code "Birthdate": '21112-8' from "LOINC" display 'Birth date'
code "PSA Follow-up": '21979-0' from "LOINC" display 'Planned/next follow-up'

parameter ReferenceDate DateTime default Today()

context Patient

define A:
  (singleton from (Patient.extension E where E.url='http://example.org/fhir/StructureDefinition/patient-annotation')).value.value
	// return E.value // this is a FHIR path

// consider
//  first degree relative with prostate cancer
//    onset before age 65
//  African American

define Age:
  AgeInYearsAt(ReferenceDate)

define Man:
  Patient.gender='male'

define OlderThan40:
  Age >= 40
    // and Age <= 75 // follow patient preference consider prior test results and functional status
    // this is the age to assess risk and discuss with patient

define PSATests:
  [Observation: code in PSALOINCValueSet] O
    where O.status in { 'final', 'amended', 'corrected' }

// define PSACarePlan:
// 	[CarePlan] CP 
// 		where exists (CP.category Categ where Categ.text='Prostate cancer screening') // apparently not case sensitive
// 		and CP.status ~ 'active'
// // this assumes only one care plan with this category

// define scheduledTiming:
// 	First(PSACarePlan.activity.detail.scheduled.repeat.period)

define FollowUpObservation:
	[Observation: "PSA Follow-up"] O
		where O.status in { 'final', 'amended', 'corrected' }

define FollowUpDuration:
	First(FollowUpObservation.value) as Quantity

// define LastPSATestEffective:
// 	Last(PSATests).effective.value

// define "NoRecentPSA":
//   not Exists("PSATests")
//       or ( Exists("PSATests")
//           and Last("PSATests").effective on or before ( Now() - 2 year ) // as an outer boundary
//       )

// BEWARE THE not EXISTS TRAP
// If it doesn't exist, you can't look for the Last one!

// define OneYearQuantity:
//   // Quantity { value: 1 as decimal, unit: 'year' }
// 	ToQuantity('scheduledTiming \'years\'')

// define blah:
// Quantity { value:1, unit: 'year' }

define LatestAcceptablePSATestDate:
ReferenceDate - Coalesce(FollowUpDuration, 2 years)

define MostRecentPSATestDate:
	Last(PSATests).effective.value

define RecentPSA:
  exists ( PSATests )
  and date from Last(PSATests).effective on or after (ReferenceDate - FollowUpDuration)

define "Tickle":
  OlderThan40 and Man and not RecentPSA
		// and not PatientOptsOut

define "Reminder":
  if "Tickle" then 'Discuss PSA' 
    else ''