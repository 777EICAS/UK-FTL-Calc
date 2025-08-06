# UK CAA Flight Time Limitations Calculator

A comprehensive iOS app for calculating Flight Time Limitations (FTL) compliance according to UK Civil Aviation Authority (CAA) regulations. Built with SwiftUI and designed with a modern, user-friendly interface inspired by shadcn/ui design principles.

## Features

### 🛩️ Core FTL Calculations
- **Daily Limits**: Maximum 13 hours duty time, 8-10 hours flight time
- **Weekly Limits**: Maximum 60 hours duty time, 56 hours flight time  
- **Monthly Limits**: Maximum 190 hours duty time, 100 hours flight time
- **Rest Periods**: Standard 11 hours, reduced 10 hours with conditions
- **Consecutive Duty Days**: Maximum 6 consecutive duty days

### 📱 User Interface
- **Modern Design**: Clean, intuitive interface following Apple Design Guidelines
- **Real-time Validation**: Input validation with helpful error messages
- **Status Indicators**: Visual compliance status (Compliant/Warning/Non-Compliant)
- **Responsive Layout**: Optimized for iPhone and iPad

### 📅 Calendar Integration
- **Import Flight Data**: Import flight events from iPhone Calendar
- **Smart Parsing**: Automatically extract flight numbers, airports, and times
- **Batch Import**: Select multiple flights for bulk import

### 📊 Data Management
- **Flight History**: Track recent flights with detailed records
- **Export Capability**: Export flight data for record keeping
- **Local Storage**: Secure local data storage with UserDefaults

### ⚙️ Settings & Configuration
- **Pilot Type Selection**: Single Pilot, Multi-Pilot, Commander, Co-Pilot
- **Regulation Reference**: Built-in UK CAA regulation guides
- **Customizable Preferences**: Time format, auto-save, warning settings

## UK CAA Regulations Implemented

### Daily Limits
- **Maximum Duty Time**: 13 hours in any 24-hour period
- **Single Pilot Operations**: Maximum 8 hours flight time
- **Multi-Pilot Operations**: Maximum 10 hours flight time
- **Rest Period**: Minimum 11 hours (10 hours with conditions)

### Weekly Limits
- **Maximum Duty Time**: 60 hours in any 7 consecutive days
- **Maximum Flight Time**: 56 hours in any 7 consecutive days
- **Consecutive Duty Days**: Maximum 6 consecutive days

### Monthly Limits
- **Maximum Duty Time**: 190 hours in any calendar month
- **Maximum Flight Time**: 100 hours in any calendar month

### Annual Limits
- **Maximum Duty Time**: 2,000 hours in any 12 consecutive months
- **Maximum Flight Time**: 1,000 hours in any 12 consecutive months

## Technical Implementation

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **Combine**: Reactive programming for data binding
- **EventKit**: Calendar integration for flight data import

### Key Components
- `FTLViewModel`: Main business logic and data management
- `FTLCalculationService`: Comprehensive FTL compliance calculations
- `CalendarImportView`: Calendar integration and flight data parsing
- `SettingsView`: App configuration and regulation reference

### Data Models
- `FlightRecord`: Flight data structure with Codable support
- `PilotType`: Enumeration of pilot roles
- `FTLCalculationResult`: Calculation results with compliance status
- `FatigueRisk`: Fatigue risk assessment model

## Installation & Setup

### Requirements
- iOS 18.5+
- Xcode 15.0+
- Swift 5.9+

### Build Instructions
1. Clone the repository
2. Open `UK FTL Calc.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run on device or simulator

### Permissions
The app requires the following permissions:
- **Calendar Access**: To import flight events from iPhone Calendar
- **Local Storage**: To save flight records and preferences

## Usage Guide

### Manual Flight Entry
1. Select your pilot type (Single Pilot/Multi-Pilot)
2. Enter flight details:
   - Flight number
   - Departure and arrival airports (3-letter codes)
   - Report time, takeoff time, landing time, duty end time
   - Flight time in hours
3. Tap "Calculate FTL" to see compliance results

### Calendar Import
1. Tap "Import Calendar" from the main screen
2. Grant calendar access when prompted
3. Select flight events to import
4. Review and confirm imported data

### Understanding Results
- **Compliant**: All regulations satisfied
- **Warning**: Approaching limits but still compliant
- **Non-Compliant**: Regulation violations detected

### Settings Configuration
- Set default pilot type for new calculations
- Configure time format preferences
- Access UK CAA regulation references
- Manage flight data export/import

## UK CAA Regulation Sources

The app implements regulations from:
- **CAP 371**: Flight Time Limitations
- **EU OPS**: European Union Operations Regulations
- **UK CAA Guidance**: Official UK Civil Aviation Authority guidance

For the most current regulations, always refer to the official UK CAA website: https://www.caa.co.uk

## Development

### Project Structure
```
UK FTL Calc/
├── ContentView.swift          # Main app interface
├── FTLViewModel.swift         # Business logic and data management
├── Models.swift              # Data models and utilities
├── FTLCalculationService.swift # FTL compliance calculations
├── CalendarImportView.swift   # Calendar integration
├── SettingsView.swift        # App settings and configuration
└── Assets.xcassets/          # App icons and colors
```

### Adding New Features
1. **New Regulations**: Update `UKCAALimits` struct in `Models.swift`
2. **Calculation Logic**: Extend `FTLCalculationService.swift`
3. **UI Components**: Add new views following existing patterns
4. **Data Models**: Extend existing models or create new ones

### Testing
- Unit tests for FTL calculations
- UI tests for user interactions
- Integration tests for calendar import

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with proper testing
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This app is designed to assist pilots in calculating FTL compliance but should not be used as the sole source for regulatory compliance. Always verify calculations against official UK CAA regulations and consult with your airline's flight operations department for specific requirements.

## Support

For technical support or feature requests, please open an issue on the project repository.

---

**Built with ❤️ for the aviation community** 