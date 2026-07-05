# CareGrid Monorepo

CareGrid now targets two apps in one GitHub repository:

- `CareGrid Healthcare Worker`
- `CareGrid Patient`

The only shared package between them is the Supabase dataset package under `packages/caregrid_supabase_dataset`.

```text
apps/
  caregrid_healthcare_worker/  Separate healthcare worker app
  caregrid_patient/        Separate patient app
packages/
  caregrid_supabase_dataset/
```

Run one app:

```bash
cd apps/caregrid_healthcare_worker
flutter pub get
flutter run
```

Use the same commands from `apps/caregrid_patient` for the patient app. The root Flutter app is the active healthcare-worker implementation while the dedicated worker app shell is being split out.

CareGrid is a single GitHub repository with two separate Flutter apps. The apps should grow independently. The only shared package is the Supabase dataset connection and table contract.

## What It Does

CareGrid is designed for medical outreach and longitudinal follow-up.

- App-specific grid setup for community, school, and occupational workflows
- Organization-scoped login with role-aware access
- Guided form filling with JSON-driven forms
- Streamlined medical forms focused on core workflows
- Follow-up dashboards for field staff and clinical reviewers
- Doctor-only pulled-grid review flow
- Patient-only local record and consult request flow
- ANC, PNC, and New Born follow-up flows aligned to MCP card style tracking
- Local-first persistence using `SharedPreferences`
- Admin download tools for CSV summary, JSON backup, and PDF summary
- Supabase-backed authentication and organization data

## Current Workflow

### 1. Login
Users sign in under an organization and enter the app with a role-aware session.

### 2. Grid Setup
From each field app, the user sets the operational grid using state, district, taluk, locality, and area code details.

- Community locks to community grids
- Schools locks to individual school entry
- Occupation locks to individual workplace entry
- Doctors do not set grids; they pull and review field-created grids
- Patients do not set grids; they view downloaded records and request consults

### 3. Data Collection
Depending on the selected sampling unit, the app supports:

- Family registration and member management
- Individual registration
- Clinical data capture using guided forms
- Quick follow-up actions for relevant cases

### 4. Follow-up Management
Follow-up entries are collected from form outcomes and shown in dashboard views.

- Field workflow focuses on planned visits and completion
- Doctor workflow focuses on clinical review and follow-up confirmation
- Calendar and filter views help track due, overdue, and completed visits

### 5. Admin Download Setup
The admin panel supports download-oriented operations only.

- Copy CSV summary
- Copy JSON backup
- Download PDF summary

## Roles

CareGrid uses a medical role model instead of a generic admin-only model.

- `Medical Creator`: organization setup and governance
- `Program Manager`: operational oversight and admin access
- `Clinical Curator`: clinical review support
- `Doctor`: treatment review and follow-up confirmation
- `Field Collector`: registration, form entry, and follow-up execution
- `Read-only Viewer`: reporting-oriented access

## Core Forms

The app has been simplified to focus on essential forms.

- `Clinical History`
- `NCD`
- `ANC`
- `PNC`
- `New Born`
- `Under 5`

The form renderer is JSON-driven, so form structure can be updated without rebuilding the full screen layer.

## Technical Notes

- Framework: `Flutter`
- State style: screen-managed local state
- Local persistence: `SharedPreferences`
- Backend integration: `Supabase`
- Document generation: `pdf`, `printing`
- QR support: `qr_flutter`

## Project Structure

```text
lib/
  main_doctor.dart         CareGrid Doctor entrypoint
  main_patient.dart        CareGrid Patient entrypoint
  main_community.dart      CareGrid Community entrypoint
  main_schools.dart        CareGrid Schools entrypoint
  main_occupation.dart     CareGrid Occupation entrypoint
  app/                    App shell and routing
  controllers/            Auth controller
  screens/                Login, home, data collection, follow-up, admin, doctor views
  services/               Auth, follow-up, org, sync, area code, device services
assets/
  forms/                  JSON form definitions
```

## Running the App

### Prerequisites

- Flutter SDK
- A configured Supabase project for organization-backed login
- Platform toolchains for Android, iOS, Windows, macOS, or Linux as needed

### Install

```bash
flutter pub get
```

### Run One App

```bash
flutter run --flavor doctor --target lib/main_doctor.dart
flutter run --flavor patient --target lib/main_patient.dart
flutter run --flavor community --target lib/main_community.dart
flutter run --flavor schools --target lib/main_schools.dart
flutter run --flavor occupation --target lib/main_occupation.dart
```

### Build Android APKs

```bash
flutter build apk --flavor doctor --target lib/main_doctor.dart
flutter build apk --flavor patient --target lib/main_patient.dart
flutter build apk --flavor community --target lib/main_community.dart
flutter build apk --flavor schools --target lib/main_schools.dart
flutter build apk --flavor occupation --target lib/main_occupation.dart
```

### Analyze

```bash
flutter analyze
```

## Notes for Developers

- Most clinical forms are defined in `assets/forms/`
- Follow-up behavior is derived from form save results and local revisit state
- Admin exports currently read from locally stored CareGrid datasets
- Some features are still local-first and not yet fully synced to a remote clinical record system

## Roadmap Direction

The current codebase is moving toward:

- cleaner field workflow screens
- stronger role separation between field and doctor actions
- tighter MCP-card-style maternal and newborn follow-up
- download-first admin operations instead of upload-heavy workflows
- gradual backend hardening around follow-up and reporting
