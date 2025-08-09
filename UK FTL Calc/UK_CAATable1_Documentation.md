# UK CAA Table 1 Acclimatisation Logic - Complete Documentation

## Overview
This document captures the exact implementation of UK CAA Table 1 acclimatisation rules and their corresponding FDP table selection logic. This information is **VITAL** for the project to function correctly.

## UK CAA Table 1 Data Structure

### Time Zone Difference Ranges
| **Table 1 Range** | **Time Zone Difference** | **Implementation Logic** |
|-------------------|--------------------------|-------------------------|
| **"<4"** | Less than 4 hours | `timeZoneDifference < 4` |
| **"4-6"** | Equal to or more than 4 hours and less than or equal to 6 hours | `timeZoneDifference >= 4 && timeZoneDifference <= 6` |
| **"6-9"** | More than 6 hours and less than or equal to 9 hours | `timeZoneDifference > 6 && timeZoneDifference <= 9` |
| **"9-12"** | More than 9 hours and less than or equal to 12 hours | `timeZoneDifference > 9 && timeZoneDifference <= 12` |

### Elapsed Time Ranges
| **Table 1 Range** | **Elapsed Time** | **Implementation Logic** |
|-------------------|------------------|-------------------------|
| **"<48"** | Less than 48 hours | `elapsedTimeHours < 48.0` |
| **"48-71:59"** | 48 to 71 hours 59 minutes | `elapsedTimeHours >= 48.0 && elapsedTimeHours < 72.0` |
| **"72-95:59"** | 72 to 95 hours 59 minutes | `elapsedTimeHours >= 72.0 && elapsedTimeHours < 96.0` |
| **"96-119:59"** | 96 to 119 hours 59 minutes | `elapsedTimeHours >= 96.0 && elapsedTimeHours < 120.0` |
| **">=120"** | 120 hours or more | `elapsedTimeHours >= 120.0` |

## UK CAA Table 1 Complete Matrix

| **Time Zone Difference** | **<48h** | **48-71:59h** | **72-95:59h** | **96-119:59h** | **≥120h** |
|-------------------------|----------|---------------|---------------|---------------|-----------|
| **<4h** | B | D | D | D | D |
| **4-6h** | B | X | D | D | D |
| **6-9h** | B | X | X | D | D |
| **9-12h** | B | X | X | X | D |

## Result Definitions

### Result 'B' - Acclimatised to Home Base
- **Meaning**: User is acclimatised to home base time zone
- **FDP Table**: **Table 2** (FDPAcclimatisedTable)
- **Reference Time**: Report time converted to **home base local time**
- **Two Conditions**:
  1. **Departing from Home Base**: User is acclimatised for current sector
  2. **Departing from Away Base**: User is NOT acclimatised to departure airport, but still acclimatised to home base

### Result 'D' - Acclimatised to Current Departure
- **Meaning**: User is acclimatised to current departure location
- **FDP Table**: **Table 2** (FDPAcclimatisedTable)
- **Reference Time**: Report time converted to **current departure local time**

### Result 'X' - Unknown Acclimatisation State
- **Meaning**: Unknown acclimatisation state
- **FDP Table**: **Table 3** (FDPUnknownAcclimatisedTable)
- **Reference Time**: No time conversion needed (Table 3 doesn't use report time)

## Implementation Logic

### Acclimatisation Status Return Values
```swift
// Return format: (isAcclimatised, shouldBeAcclimatised, reason)
// isAcclimatised: true if acclimatised to CURRENT departure location
// shouldBeAcclimatised: true if acclimatised to home base
```

### Result 'B' Logic
```swift
// Result 'B': User is acclimatised to home base time zone
if departure.uppercased() == homeBase.uppercased() {
    return (true, true, "acclimatised (Result B)")
} else {
    return (false, true, "not acclimatised (Result B)")
}
```

### Result 'D' Logic
```swift
// Result 'D': User is acclimatised to current departure location
return (true, true, "acclimatised (Result D)")
```

### Result 'X' Logic
```swift
// Result 'X': Unknown acclimatisation state
return (false, false, "unknown acclimatisation state (X)")
```

## FDP Table Selection Logic

### Step 2: Determine Base FDP
```swift
private static func determineBaseFDP(input: FDPCalculationInput, acclimatisationState: String) -> Double {
    switch acclimatisationState {
    case "B": // Acclimatised to home base - use home base local time for Table 2
        let homeBaseLocalTime = convertToLocalTime(input.reportTime, timeZone: input.previousAcclimatisedTimeZone)
        return RegulatoryTableLookup.lookupFDPAcclimatised(
            reportTime: homeBaseLocalTime,
            sectors: input.sectors
        )
    case "D": // Acclimatised to current departure - use departure local time for Table 2
        let departureLocalTime = convertToLocalTime(input.reportTime, timeZone: input.currentLocationTimeZone)
        return RegulatoryTableLookup.lookupFDPAcclimatised(
            reportTime: departureLocalTime,
            sectors: input.sectors
        )
    case "X": // Unknown acclimatisation - use Table 3 (no time conversion needed)
        return RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: input.sectors)
    default:
        return 9.0 // Default minimum
    }
}
```

## Example Scenarios

### Example 1: LHR-JFK (First Sector)
- **Time Zone Difference**: 5 hours (4-6h range)
- **Elapsed Time**: 0 hours (<48h range)
- **Result**: B (acclimatised to home base)
- **Departure**: LHR (home base)
- **FDP Table**: Table 2
- **Reference Time**: 15:35z → 16:35 local LHR time
- **User Status**: Acclimatised for current sector

### Example 2: JFK-LHR (Return Sector)
- **Time Zone Difference**: 5 hours (4-6h range)
- **Elapsed Time**: 32h 40m (<48h range)
- **Result**: B (acclimatised to home base)
- **Departure**: JFK (away from home base)
- **FDP Table**: Table 2
- **Reference Time**: 00:15z → 01:15 local LHR time
- **User Status**: NOT acclimatised to JFK, but acclimatised to LHR

### Example 3: IAH-LHR (Subsequent Sector)
- **Time Zone Difference**: 6 hours (6-9h range)
- **Elapsed Time**: 60h 25m (48-71:59h range)
- **Result**: X (unknown acclimatisation state)
- **Departure**: IAH (away from home base)
- **FDP Table**: Table 3
- **Reference Time**: No time conversion needed
- **User Status**: Unknown acclimatisation state

## Critical Implementation Notes

### 1. Time Zone Difference Calculation
- **For acclimatisation**: Calculate from home base to current departure location
- **For FDP calculation**: Use appropriate local time based on acclimatisation result

### 2. Elapsed Time Calculation
- **First sector**: elapsedTime = 0.0
- **Subsequent sectors**: Calculate from original home base report time to current report time
- **Must account for date differences** across multiple days

### 3. Report Time Conversion
- **Result B**: Convert to home base local time
- **Result D**: Convert to current departure local time
- **Result X**: No conversion needed (Table 3)

### 4. Acclimatisation Status Display
- **Result B (home base departure)**: "Crew acclimatised" (green/extension)
- **Result B (away base departure)**: "Crew not acclimatised (user is acclimatised to LHR)" (amber/reduction)
- **Result D**: "Crew acclimatised" (green/extension)
- **Result X**: "Unknown acclimatisation state (X)" (amber/reduction)

## Validation Checklist

Before making any changes to acclimatisation logic, verify:

- [ ] Time zone difference ranges match UK CAA Table 1 exactly
- [ ] Elapsed time ranges match UK CAA Table 1 exactly
- [ ] Result B, D, X logic is correctly implemented
- [ ] FDP table selection matches acclimatisation results
- [ ] Time zone conversions use correct reference points
- [ ] UI displays correct acclimatisation status and impact

## File Locations

- **Acclimatisation Logic**: `Models.swift` - `determineAcclimatisationStatus()`
- **FDP Table Selection**: `RegulatoryFDPCalculator.swift` - `determineBaseFDP()`
- **Active Factors Display**: `Models.swift` - `getActiveFactorsWithImpact()`
- **Time Zone Utilities**: `Models.swift` - `TimeUtilities` struct

---

**IMPORTANT**: This documentation must be kept up-to-date with any changes to the acclimatisation logic. The UK CAA Table 1 rules are regulatory requirements and must be implemented exactly as specified. 