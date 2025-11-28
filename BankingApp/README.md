# Banking App - MVVM-C Architecture Reference Implementation

## Project Setup

This iOS banking application demonstrates MVVM-C architecture patterns with iOS 15 compatibility.

### Xcode Project Creation

**Manual Setup (Xcode GUI):**

1. Open Xcode
2. File → New → Project
3. Select "iOS" → "App"
4. Configure project:
   - **Product Name:** BankingApp
   - **Organization Identifier:** com.example
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployment:** iOS 15.0

5. Save to this directory (BankingApp folder)

6. In Project Settings → General:
   - Set Deployment Target to **iOS 15.0**
   - Verify Swift Language Version is **5.9**

7. In Project Settings → Build Settings:
   - Ensure Build System is set to **New Build System**

8. Add all folders to Xcode project navigator:
   - Drag folders from Finder into Xcode
   - Select "Create groups" (not folder references)
   - Ensure all folders are added as groups in the project

### Info.plist Configuration

The `App/Info.plist` file is already configured with:

- **Custom URL Scheme:** `bankapp://` for deep linking
- **NSFaceIDUsageDescription:** Privacy string for biometric authentication

### Folder Structure

```
BankingApp/
├── App/                          # Application entry point
│   ├── BankingApp.swift          # @main entry
│   └── Info.plist                # URL scheme, privacy strings
├── Router/                       # Route enums and DeepLinkParser
├── Coordinator/                  # Navigation coordinators
│   └── Features/                 # Feature-specific coordinators
├── ViewFactory/                  # View+ViewModel construction
├── DI/                           # Dependency injection container
├── Services/                     # Service layer
│   ├── Protocols/                # Service interfaces
│   └── Implementations/          # Mock/real implementations
├── Models/                       # Domain models
├── ViewModels/                   # Business logic layer
│   ├── Home/
│   ├── Accounts/
│   ├── Transfer/
│   ├── Cards/
│   ├── More/
│   └── Auth/
└── Views/                        # UI layer
    ├── Common/                   # Reusable components
    ├── Home/
    ├── Accounts/
    ├── Transfer/
    ├── Cards/
    ├── More/
    └── Auth/
```

### Build and Run

1. Select iOS 15.0+ simulator or device
2. Build: ⌘B
3. Run: ⌘R

The app should launch with the default template screen showing "Banking App" with project structure confirmation.

### Next Steps

After creating the Xcode project:

1. **Story 1.2:** Implement Router layer with route enums and DeepLinkParser
2. **Story 1.3:** Implement CoordinatorProtocol and AppCoordinator
3. **Story 1.4:** Implement all six feature coordinators
4. **Story 1.5-1.11:** Continue with remaining Epic 1 stories

### Architecture Constraints

**iOS 15 Compatibility:**
- ❌ NO NavigationStack (iOS 16+)
- ❌ NO navigationDestination modifier (iOS 16+)
- ✅ USE NavigationView with .navigationViewStyle(.stack)
- ✅ USE NavigationLink(destination:isActive:) for programmatic navigation

### References

- **Architecture:** `docs/architecture.md`
- **PRD:** `docs/prd.md`
- **Epic 1 Tech Spec:** `docs/sprint/tech-spec-epic-1.md`
- **Story Context:** `docs/sprint-artifacts/1-1-initialize-xcode-project-and-configure-basic-structure.context.xml`
