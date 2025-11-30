# InterviewReady

InterviewReady is an offline-first, premium-feeling interview preparation companion built with SwiftUI for iOS 17+. It provides structured templates, daily practice prompts, and space to organise your interview prep without any network dependency.

## Features
- **Home hub** with quick stats and navigation to all tools
- **Daily Question** rotation with structure guidance and editable saved answers
- **My Answers Vault** with favourites and filters
- **STAR Story Builder** to capture Situation/Task/Action/Result narratives
- **Achievements tracker** to remember recent wins and impact
- **Question Library** with example answers and save-to-vault flow
- **Role Packs** (free + Pro-gated) with an in-app paywall stub
- **Interview Notes** for company research and upcoming interview prep
- **Settings** with Pro simulation toggle and paywall preview

Everything is stored locally using `UserDefaults` + `Codable`, ready for offline use.

## Architecture
The project follows a simple, beginner-friendly MVVM-ish structure:

- `Models/` – Core data models (`InterviewQuestion`, `UserAnswer`, `StarStory`, `Achievement`, `InterviewNote`, `RolePack`, `QuestionCategory`).
- `Services/` – `DataStore` for persistence and seed content; `ProAccessManager` for Pro gating state.
- `ViewModels/` – Lightweight view models per feature (Home, Daily Question, Answers, Stories, Achievements, Library, Role Packs, Notes).
- `Views/` – SwiftUI screens for each feature plus the `PaywallView`.
- `Components/` – Reusable UI building blocks (`PrimaryButton`, `SecondaryButton`, `CardView`, `TagChipView`, `Theme`).

The app entry point is `InterviewReadyApp.swift`, which wires up the `DataStore` and `ProAccessManager` as environment objects and presents a tab-based navigation shell.

## Running the App
1. Open `InterviewReady.xcodeproj` or create a new Xcode project and replace its sources with the contents of the `InterviewReady/` directory.
2. Target **iOS 17** or later.
3. Build and run on Simulator or device. No network or backend configuration is required.

## Pro Upgrade Stub
A simple `ProAccessManager` toggles `isProUnlocked`. The `PaywallView` uses a simulated unlock button to set the flag. Replace this logic with real StoreKit in a future update.

## Offline-first
No network calls are present. All content (question library, role packs, daily rotation) is defined locally. User data is persisted via `UserDefaults` using `Codable` models.
