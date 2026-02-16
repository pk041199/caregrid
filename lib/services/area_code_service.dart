import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AreaCodeEntry {
  AreaCodeEntry({
    required this.stateCode,
    required this.districtCode,
    required this.talukCode,
    required this.localityCode,
    required this.stateName,
    required this.districtName,
    required this.talukName,
    required this.localityName,
    required this.localityType,
    this.areaSuffixCode = '',
    this.areaSuffixType = 'cluster',
    this.phcArea = '',
    this.clusterName = '',
  });

  final String stateCode;
  final String districtCode;
  final String talukCode;
  final String localityCode;
  final String stateName;
  final String districtName;
  final String talukName;
  final String localityName;
  final String localityType;
  final String areaSuffixCode;
  final String areaSuffixType;
  final String phcArea;
  final String clusterName;

  String get areaCode =>
      '$stateCode-$districtCode-$talukCode-$localityCode-$areaSuffixCode';

  Map<String, dynamic> toMap() {
    return {
      'stateCode': stateCode,
      'districtCode': districtCode,
      'talukCode': talukCode,
      'localityCode': localityCode,
      'stateName': stateName,
      'districtName': districtName,
      'talukName': talukName,
      'localityName': localityName,
      'localityType': localityType,
      'areaSuffixCode': areaSuffixCode,
      'areaSuffixType': areaSuffixType,
      'phcArea': phcArea,
      'clusterName': clusterName,
    };
  }

  factory AreaCodeEntry.fromMap(Map<String, dynamic> map) {
    return AreaCodeEntry(
      stateCode: (map['stateCode'] ?? '').toString(),
      districtCode: (map['districtCode'] ?? '').toString(),
      talukCode: (map['talukCode'] ?? '').toString(),
      localityCode: (map['localityCode'] ?? '').toString(),
      stateName: (map['stateName'] ?? '').toString(),
      districtName: (map['districtName'] ?? '').toString(),
      talukName: (map['talukName'] ?? '').toString(),
      localityName: (map['localityName'] ?? '').toString(),
      localityType: (map['localityType'] ?? '').toString(),
      areaSuffixCode: (map['areaSuffixCode'] ?? map['clusterCode'] ?? '').toString(),
      areaSuffixType: (map['areaSuffixType'] ?? 'cluster').toString(),
      phcArea: (map['phcArea'] ?? '').toString(),
      clusterName: (map['clusterName'] ?? '').toString(),
    );
  }
}

class AreaCodeService {
  static const String _storageKey = 'area_code_entries_v1';

  static final List<AreaCodeEntry> _defaultEntries = [
    AreaCodeEntry(
      stateCode: '29',
      districtCode: '01',
      talukCode: '03',
      localityCode: '012',
      stateName: 'Karnataka',
      districtName: 'Bengaluru Urban',
      talukName: 'Yelahanka',
      localityName: 'Attur Village',
      localityType: 'village',
      areaSuffixCode: '01',
      areaSuffixType: 'cluster',
      phcArea: 'Yelahanka PHC',
      clusterName: 'Cluster 1',
    ),
    AreaCodeEntry(
      stateCode: '29',
      districtCode: '01',
      talukCode: '03',
      localityCode: '013',
      stateName: 'Karnataka',
      districtName: 'Bengaluru Urban',
      talukName: 'Yelahanka',
      localityName: 'Jakkur City',
      localityType: 'city',
      areaSuffixCode: '02',
      areaSuffixType: 'cluster',
      phcArea: 'Yelahanka PHC',
      clusterName: 'Cluster 2',
    ),
  ];

  Future<List<AreaCodeEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await _saveEntries(_defaultEntries);
      return List<AreaCodeEntry>.from(_defaultEntries);
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AreaCodeEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(AreaCodeEntry entry) async {
    final normalized = _normalizeEntry(entry);
    final list = await getEntries();
    final index = list.indexWhere(
      (e) =>
          _normalizeCode(e.stateCode, 2) == _normalizeCode(normalized.stateCode, 2) &&
          _normalizeCode(e.districtCode, 2) == _normalizeCode(normalized.districtCode, 2) &&
          _normalizeCode(e.talukCode, 2) == _normalizeCode(normalized.talukCode, 2) &&
          _normalizeCode(e.localityCode, 3) == _normalizeCode(normalized.localityCode, 3) &&
          _normalizeSuffixCode(e.areaSuffixCode, e.areaSuffixType) ==
              _normalizeSuffixCode(
                normalized.areaSuffixCode,
                normalized.areaSuffixType,
              ),
    );
    if (index >= 0) {
      list[index] = normalized;
    } else {
      list.add(normalized);
    }
    await _saveEntries(list);
  }

  Future<void> deleteByAreaCode(String areaCode) async {
    final list = await getEntries();
    list.removeWhere((e) => e.areaCode == areaCode);
    await _saveEntries(list);
  }

  AreaCodeEntry? findByCodeParts(
    List<AreaCodeEntry> entries, {
    required String stateCode,
    required String districtCode,
    required String talukCode,
    required String localityCode,
    required String areaSuffixCode,
    required String areaSuffixType,
  }) {
    final s = _normalizeCode(stateCode, 2);
    final d = _normalizeCode(districtCode, 2);
    final t = _normalizeCode(talukCode, 2);
    final l = _normalizeCode(localityCode, 3);
    final c = _normalizeSuffixCode(areaSuffixCode, areaSuffixType);

    return entries.where((e) {
      return _normalizeCode(e.stateCode, 2) == s &&
          _normalizeCode(e.districtCode, 2) == d &&
          _normalizeCode(e.talukCode, 2) == t &&
          _normalizeCode(e.localityCode, 3) == l &&
          _normalizeSuffixCode(e.areaSuffixCode, e.areaSuffixType) == c;
    }).cast<AreaCodeEntry?>().firstWhere((_) => true, orElse: () => null);
  }

  AreaCodeEntry? findByNames(
    List<AreaCodeEntry> entries, {
    required String stateName,
    required String districtName,
    required String talukName,
    required String localityName,
    required String areaSuffixType,
  }) {
    final s = _normalizeText(stateName);
    final d = _normalizeText(districtName);
    final t = _normalizeText(talukName);
    final l = _normalizeText(localityName);

    return entries.where((e) {
      return _normalizeText(e.stateName) == s &&
          _normalizeText(e.districtName) == d &&
          _normalizeText(e.talukName) == t &&
          _normalizeText(e.localityName) == l &&
          _normalizeText(e.areaSuffixType) == _normalizeText(areaSuffixType);
    }).cast<AreaCodeEntry?>().firstWhere((_) => true, orElse: () => null);
  }

  Future<void> _saveEntries(List<AreaCodeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => _normalizeEntry(e).toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  AreaCodeEntry _normalizeEntry(AreaCodeEntry entry) {
    return AreaCodeEntry(
      stateCode: _normalizeCode(entry.stateCode, 2),
      districtCode: _normalizeCode(entry.districtCode, 2),
      talukCode: _normalizeCode(entry.talukCode, 2),
      localityCode: _normalizeCode(entry.localityCode, 3),
      stateName: entry.stateName.trim(),
      districtName: entry.districtName.trim(),
      talukName: entry.talukName.trim(),
      localityName: entry.localityName.trim(),
      localityType: entry.localityType.trim().toLowerCase(),
      areaSuffixCode: _normalizeSuffixCode(
        entry.areaSuffixCode,
        entry.areaSuffixType,
      ),
      areaSuffixType: entry.areaSuffixType.trim().toLowerCase(),
      phcArea: entry.phcArea.trim(),
      clusterName: entry.clusterName.trim(),
    );
  }

  String _normalizeCode(String value, int len) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    if (digitsOnly.length >= len) return digitsOnly.substring(digitsOnly.length - len);
    return digitsOnly.padLeft(len, '0');
  }

  String _normalizeSuffixCode(String value, String type) {
    final normalizedType = type.trim().toLowerCase();
    final len = normalizedType == 'cluster' ? 2 : 3;
    return _normalizeCode(value, len);
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
