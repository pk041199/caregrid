# CareGrid

CareGrid is a Flutter-based public health and primary care data collection app for field teams, doctors, and program administrators. It combines grid-based household or individual enrollment, guided medical forms, follow-up planning, doctor review, and admin exports in a single workflow.

## What It Does

CareGrid is designed for medical outreach and longitudinal follow-up.

- Grid-based setup for `Family`, `Individual`, and future `Community` workflows
- Organization-scoped login with role-aware access
- Guided form filling with JSON-driven forms
- Streamlined medical forms focused on core workflows
- Follow-up dashboards for field staff and clinical reviewers
- ANC, PNC, and New Born follow-up flows aligned to MCP card style tracking
- Local-first persistence using `SharedPreferences`
- Admin download tools for CSV summary, JSON backup, and PDF summary
- Supabase-backed authentication and organization data

## Current Workflow

### 1. Login
Users sign in under an organization and enter the app with a role-aware session.

### 2. Grid Setup
From the home screen, the user sets a grid or operational area using state, district, taluk, locality, and area code details.

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

### Run

```bash
flutter run
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
