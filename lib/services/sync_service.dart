class SyncService {
  Future<String> uploadPendingForSamplingUnit({
    required String samplingUnitId,
  }) async {
    // Placeholder upload step until local queue + full sync pipeline is added.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return 'Upload triggered for sampling unit: $samplingUnitId';
  }
}
