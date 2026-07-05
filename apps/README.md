# CareGrid Apps

This folder contains the two separate CareGrid apps in one GitHub repository.

The apps do not share screens or workflows. The only common dependency is:

```text
packages/caregrid_supabase_dataset
```

That package owns the Supabase URL, anon key, client initialization, and shared table names.

## Apps

```text
apps/caregrid_healthcare_worker  Healthcare worker app
apps/caregrid_patient      Patient record view and doctor consultation
```

## Run

Run each app from its own folder:

```bash
cd apps/caregrid_healthcare_worker
flutter pub get
flutter run
```

Repeat the same pattern for `caregrid_patient`.
