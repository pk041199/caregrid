enum CareGridAppMode {
  healthcareWorker,
  patient,
}

extension CareGridAppModeDetails on CareGridAppMode {
  String get title {
    switch (this) {
      case CareGridAppMode.healthcareWorker:
        return 'CareGrid Healthcare Worker';
      case CareGridAppMode.patient:
        return 'CareGrid Patient';
    }
  }

  String get demoRole {
    switch (this) {
      case CareGridAppMode.healthcareWorker:
        return 'Field Clinic Worker';
      case CareGridAppMode.patient:
        return 'Patient';
    }
  }

  String? get lockedSamplingUnit {
    switch (this) {
      case CareGridAppMode.healthcareWorker:
      case CareGridAppMode.patient:
        return null;
    }
  }

  String? get lockedEntryPoint {
    switch (this) {
      case CareGridAppMode.healthcareWorker:
      case CareGridAppMode.patient:
        return null;
    }
  }
}
