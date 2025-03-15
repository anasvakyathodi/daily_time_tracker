# DailyTimeTracker

![DailyTimeTracker](https://img.shields.io/badge/macOS-Time%20Tracker-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)

A powerful yet simple menu bar application for macOS that helps you track time spent on various activities and projects throughout your day. DailyTimeTracker improves productivity by providing insights into how you spend your time.

## Features

- **Menu Bar Integration**: Access time tracking with a single click from your menu bar
- **Simple Task Recording**: Easily log time spent on tasks with minimal effort
- **Timer Functionality**: Start/stop timer for real-time tracking of your activities
- **Daily View**: Navigate between days to review and edit your time entries
- **Note Taking**: Add detailed notes to your time entries for better context
- **Time Presets**: Quickly add common time durations to save time
- **Date Navigation**: Easily jump to specific dates with the calendar picker
- **Task Suggestions**: Smart suggestions based on your frequently tracked activities
- **Automatic Prompting**: Optional reminders to log your current activity
- **Data Persistence**: All time entries are securely stored using CoreData

## Screenshots

[Screenshots would be placed here]

## Requirements

- macOS 11.0 or later
- Xcode 13.0+ (for building from source)

## Installation

### Option 1: Download Release

1. Download the latest release from the [Releases](https://github.com/yourusername/DailyTimeTracker/releases) page
2. Drag `DailyTimeTracker.app` to your Applications folder
3. Launch the app from your Applications folder or Spotlight

### Option 2: Build from Source

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/DailyTimeTracker.git
   ```
2. Open `DailyTimeTracker.xcodeproj` in Xcode
3. Select your signing team in the project settings if you want to run it on your Mac
4. Build and run the project (⌘+R)

## Usage

1. **Launch the App**: DailyTimeTracker runs in the menu bar for easy access
2. **Add Time Entry**:
   - Click on the clock icon in the menu bar
   - Enter task name and select time spent
   - Optional: Add detailed notes
   - Click "Add" to save the time entry
3. **Track Time in Real-time**:
   - Click "Start Timer" to begin tracking
   - Click "Stop Timer" when finished, then enter task details
4. **Navigate Between Days**:
   - Use the left/right arrows to move between days
   - Click the calendar icon to jump to a specific date
5. **Edit or Delete Entries**:
   - Click on an existing entry to modify it
   - Use the delete button to remove an entry

## Tips for Effective Time Tracking

- Be consistent with task naming for better reporting
- Add detailed notes for context when reviewing later
- Track even small tasks to get a complete picture of your day
- Use the timer feature for accurate tracking of focused work
- Review your time data periodically to identify productivity patterns

## Privacy

DailyTimeTracker stores all your data locally on your Mac. No data is sent to external servers.

## Roadmap

- Export functionality (CSV, PDF)
- Visual reports and analytics
- Dark mode support
- Task categorization and tagging
- Weekly and monthly view
- Cloud sync (optional)

## Contributing

Contributions are welcome! If you'd like to contribute:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI framework
- [CoreData](https://developer.apple.com/documentation/coredata) - Persistence framework

---

Created by Anas Vakyathodi
