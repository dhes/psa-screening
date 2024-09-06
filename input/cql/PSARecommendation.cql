library PSARecommendation version '1.0.1'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

valueset PSALOINCValueSet: 'http://example.org/fhir/ValueSet/psa-loinc-valueset'

// parameter "Reference Date" DateTime default Now()

context Patient

// consider
//  first degree relative with prostate cancer
//    onset before age 65
//  African American

define "PatientAge":
  AgeInYearsAt(Now())

// define PatientGender

define "OlderThan40":
  PatientAge >= 40
    // and "PatientAge" <= 75 // follow patient preference consider prior test results and functional status
    // this is the age to assess risk and discuss with patient

define PSATests:
  [Observation: code in PSALOINCValueSet] O
    where O.status in { 'final', 'amended', 'corrected' }

define LastPSATestEffective:
	Last(PSATests).effective.value

// define "NoRecentPSA":
//   not Exists("PSATests")
//       or ( Exists("PSATests")
//           and Last("PSATests").effective on or before ( Now() - 2 year ) // as an outer boundary
//       )

// BEWARE THE not EXISTS TRAP
// If it doesn't exist, you can't look for the Last one!

define "RecentPSA":
  exists ( PSATests )
  and date from Last(PSATests).effective on or after (Now() - 2 years)

// define PatientOptsOut

// define "NotRecentPSA":
// 	not "RecentPSA"

define "Tickle":
  OlderThan40 and not RecentPSA
		// and not PatientOptsOut

define "Reminder":
  if "Tickle" then 'Discuss PSA' 
    else ''