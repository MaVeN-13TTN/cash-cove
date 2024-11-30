# Budget Tracker Mobile App

A comprehensive Flutter-based mobile application for personal and shared expense tracking, budget management, and financial analytics.

## Features

- 🔐 Secure Authentication
  - Biometric authentication
  - Email/password login
  - Social media integration (Google, Facebook)
  - Secure token management

- 💰 Expense Management
  - Track personal expenses
  - Categorize transactions
  - Add receipts and attachments
  - Search and filter transactions
  - Export expense reports

- 👥 Shared Expenses
  - Create expense groups
  - Split bills with friends
  - Track group balances
  - Settle up feature
  - Real-time updates

- 📊 Budget Planning
  - Set monthly budgets
  - Category-wise budget allocation
  - Budget vs actual tracking
  - Smart alerts and notifications
  - Spending insights

- 📈 Analytics & Reports
  - Spending patterns
  - Category-wise analysis
  - Monthly trends
  - Custom date range reports
  - Visual charts and graphs

- 🔔 Smart Notifications
  - Budget alerts
  - Bill reminders
  - Payment due notifications
  - Group expense updates
  - Custom notification settings

## Project Structure

```
frontend/
├── lib/
│   ├── core/               # Core functionality
│   │   ├── config/         # App configuration
│   │   ├── constants/      # Constants and enums
│   │   ├── services/       # Core services
│   │   ├── theme/          # App theme
│   │   └── utils/          # Utility functions
│   ├── data/
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   └── repositories/   # Data repositories
│   ├── presentation/
│   │   ├── screens/        # App screens
│   │   ├── widgets/        # Reusable widgets
│   │   └── routes/         # Navigation routes
│   └── main.dart           # App entry point
├── assets/                 # Static assets
├── test/                   # Test files
└── pubspec.yaml           # Dependencies
```

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- iOS development setup (for iOS builds)
- Active internet connection

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/budget_tracker.git
   cd budget_tracker/frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup environment variables:
   - Copy `.env.example` to `.env`
   - Update the variables with your configuration

4. Run the app:
   ```bash
   flutter run
   ```

## Development Setup

1. Enable sound null safety:
   ```bash
   flutter run --no-sound-null-safety
   ```

2. Generate required files:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run tests:
   ```bash
   flutter test
   ```

## State Management

- Provider for simple state management
- GetX for complex state and navigation
- Hive for local storage
- Secure storage for sensitive data

## API Integration

- RESTful API communication
- JWT authentication
- Offline-first architecture
- Automatic retry mechanism
- Error handling

## Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for features
- Golden tests for visual regression

## Build & Deploy

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Then archive using Xcode
```

## Performance Optimization

- Lazy loading of images
- Efficient state management
- Memory leak prevention
- Network caching
- Asset optimization

## Security Features

- Biometric authentication
- Secure storage for sensitive data
- API key protection
- Network security
- Input validation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Code Style

Follow the official Dart style guide and Flutter best practices:
- Use proper naming conventions
- Write meaningful comments
- Create reusable widgets
- Maintain proper file structure
- Follow SOLID principles

## Troubleshooting

Common issues and solutions:
- Build errors: Clean and rebuild
- Package conflicts: Update dependencies
- Platform-specific issues: Check documentation
- State management: Review provider setup
- API integration: Verify endpoints

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support:
- Create an issue in the repository
- Contact the development team
- Check the documentation
- Join our Discord community

## Acknowledgments

- Flutter team for the framework
- Contributors and maintainers
- UI/UX designers
- Testing team
- Community feedback
