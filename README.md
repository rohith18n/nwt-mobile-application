# Networth Tracker Mobile Application (`nwt_app`)

> **"Make your money grow"** — A comprehensive, multi-platform Flutter application for wealth tracking, mutual fund trading, portfolio management, account aggregation, and financial advisory.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started & Setup](#-getting-started--setup)
- [Development & Build Scripts](#-development--build-scripts)
- [CI/CD & OTA Updates](#-cicd--ota-updates)
- [Integration Documentation](#-integration-documentation)
- [License](#-license)

---

## 🚀 Overview

**Networth Tracker (`nwt_app`)** is a feature-rich mobile and web application engineered with Flutter. It offers users a unified dashboard to manage personal net worth, sync financial accounts via Account Aggregators (AA), track & execute mutual fund investments (via BSE Star and MF Central), run paper trading simulations, and receive tailored financial advisory recommendations.

---

## ✨ Key Features

- 💼 **Portfolio & Asset Management**: Real-time tracking of mutual funds, equities, personal assets, bank balances, and family finances.
- 🔄 **Mutual Fund Trading**: Direct order placement, fund switching, SIP management, buy/sell workflows powered by **BSE Star V2** and **MF Central V2**.
- 🏦 **Account Aggregator (AA) Integration**: Automated, consent-driven financial data fetch integrated with **Saafe AA SDK** and **Finarkein Engine**.
- 📊 **Paper Trading & Advisory**: Interactive financial profiling, simulated paper trading, and personalized asset allocation recommendations.
- 💳 **Payments & KYC**: Seamless onboarding with integrated KYC workflows, UCC creation, and **Cashfree Payment Gateway** SDK integration.
- 🔐 **Security & Authentication**: Multi-layered authentication supporting Firebase Auth, Google Sign-In, MPIN, Biometrics (`local_auth`), and encrypted local storage (`flutter_secure_storage`).
- 📈 **Comprehensive Analytics**: Event tracking across Firebase Analytics, CleverTap, AppsFlyer, and Meta (Facebook) App Events.
- ⚡ **Over-The-Air (OTA) Updates**: Instant, seamless app patching delivered directly via **Shorebird Code Push**.

---

## 🛠 Architecture & Tech Stack

### Framework & Core
- **Flutter SDK**: `^3.7.2`
- **Dart SDK**: `^3.7.2`

### State Management & Navigation
- **GetX (`get`)**: Reactive state management, dependency injection, and route management.
- **Provider**: Secondary state propagation where required.
- **GetStorage**: Fast, light key-value storage.

### UI / UX & Design
- **Responsive Layout**: `flutter_screenutil`
- **Typography**: Custom Google Fonts (`Poppins` & `Montserrat`)
- **Visuals & Charts**: `syncfusion_flutter_charts`, `lottie`, `animate_do`, `flutter_animate`, `shimmer`, `flutter_svg`, `syncfusion_flutter_pdfviewer`

### Backend, APIs & Services
- **Firebase Services**: Core, Auth, Analytics, Remote Config, Crashlytics, Cloud Messaging (FCM), In-App Messaging
- **Supabase**: `supabase_flutter` for real-time database capabilities
- **WebSockets**: `web_socket_channel` for real-time market data streaming

### Third-Party Integrations
- **Account Aggregators**: `saafe_aa_sdk`, Finarkein Data Store
- **Payment Gateway**: `flutter_cashfree_pg_sdk`
- **Analytics & Marketing**: `clevertap_plugin`, `appsflyer_sdk`, `facebook_app_events`, `flutter_branch_sdk`

---

## 📁 Project Structure

```text
nwt-mobile-application/
├── .github/
│   └── workflows/
│       └── build.yml               # GitHub Actions CI/CD pipeline
├── assets/                          # App fonts, SVG icons, Lottie animations, integration assets
├── integration_docs/                # Detailed technical guides (APIs, AA, Analytics, Onboarding)
├── lib/
│   ├── main.dart                    # Application entry point & service initialization
│   ├── firebase_options.dart        # Generated Firebase configuration
│   ├── constants/                   # Theme tokens, colors, API endpoints, analytics keys
│   ├── controllers/                 # GetX controllers (Portfolio, AA, MF Central, Realtime)
│   ├── extensions/                  # Dart extension methods
│   ├── models/                      # Data models & DTOs
│   ├── notification/                # Push notification & FCM handlers
│   ├── screens/                     # Feature modules (Dashboard, MF, Advisory, KYC, Auth, etc.)
│   ├── services/                    # Auth, MPIN, Analytics, Deep Linking, Remote Config, Connectivity
│   ├── types/                       # Enums, type definitions
│   ├── utils/                       # Loggers, helpers, formatters
│   └── widgets/                     # Reusable UI components
├── scripts/                         # Shell scripts for development, building, and utilities
├── shorebird.yaml                   # Shorebird Code Push configuration
└── pubspec.yaml                     # Dependencies and package manifests
```

---

## ⚙️ Getting Started & Setup

### Prerequisites

Ensure you have the following installed on your machine:
- **Flutter SDK** (`>= 3.7.2`)
- **Java Development Kit (JDK)** (`17`)
- **Xcode** (for iOS development, macOS only)
- **Android Studio** & Android SDK (for Android development)

### Local Environment Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd nwt-mobile-application
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   - **Android**:
     ```bash
     flutter run -t lib/main.dart
     ```
   - **iOS**:
     ```bash
     flutter run -d ios -t lib/main.dart
     ```
   - **Web**:
     ```bash
     flutter run -d chrome -t lib/main.dart
     ```

---

## 📜 Development & Build Scripts

The repository includes helper scripts inside the [`scripts/`](file:///Users/rohith_n/Documents/tasks/nwt-mobile-application/scripts) directory to streamline daily workflow.

### Sourcing Utility Scripts

To make utility functions accessible in your terminal session, source the utility script:

```bash
source ./scripts/utils.sh
```

Available utility commands:
- `flutter_clean`: Cleans the build cache and re-fetches dependencies.
- `run_tests`: Executes unit and widget test suites.
- `generate_code`: Runs `build_runner` for code generation.
- `analyze_code`: Runs `flutter analyze` against the project.
- `format_code`: Formats all Dart files according to guidelines.

### Development Script (`dev.sh`)

Launch the app in development mode across platforms:

```bash
./scripts/dev.sh android   # Launch on connected Android device/emulator
./scripts/dev.sh ios       # Launch on iOS Simulator
./scripts/dev.sh web       # Launch on Web browser
```

### Build Script (`build.sh`)

Compile release or development binaries:

```bash
./scripts/build.sh dev           # Build all platforms for development
./scripts/build.sh prod          # Build all platforms for production
./scripts/build.sh prod apk      # Build production Android APKs (split per ABI)
```

---

## 🚢 CI/CD & OTA Updates

### GitHub Actions CI/CD Pipeline

The project uses GitHub Actions ([`.github/workflows/build.yml`](file:///Users/rohith_n/Documents/tasks/nwt-mobile-application/.github/workflows/build.yml)) to automate builds:
- Triggers on push or pull requests merged into `main` or `develop`.
- Automatically executes `flutter test`.
- Builds APK binaries split per target architecture (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- Distributes release builds directly to **Firebase App Distribution**.

### Shorebird Over-The-Air (OTA) Patches

Shorebird is configured ([`shorebird.yaml`](file:///Users/rohith_n/Documents/tasks/nwt-mobile-application/shorebird.yaml)) to deliver instant live code updates without requiring Play Store / App Store submissions:

```bash
# Push an OTA patch release
shorebird patch android
shorebird patch ios
```

---

## 📚 Integration Documentation

Refer to the [`integration_docs/`](file:///Users/rohith_n/Documents/tasks/nwt-mobile-application/integration_docs) directory for technical deep dives:
- **Account Aggregator**: `finarkein_aa_app_open_refresh_frontend.md`, `AA_EQUITY_ETF_REALTIME_WEBSOCKET_CONTRACT.md`
- **Onboarding & KYC**: `COMPLETE_ONBOARDING_FLOW.md`, `onboarding_new.md`
- **Investment & Orders**: `frontend_investment_apisv2.md`, `order.md`, `mf_central_transactions.md`
- **Analytics Mapping**: `comprehensive_analytics_events.md`, `analytics_implementation_guide.md`
