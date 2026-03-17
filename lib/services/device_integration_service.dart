import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

enum DeviceType {
  ecg,
  pft,
  steth,
}

class DeviceReading {
  const DeviceReading({
    required this.device,
    required this.summary,
    required this.timestamp,
    this.source = 'app',
  });

  final DeviceType device;
  final String summary;
  final DateTime timestamp;
  final String source;
}

class DeviceIntegrationService {
  DeviceIntegrationService._();

  static final DeviceIntegrationService instance = DeviceIntegrationService._();

  static const MethodChannel _channel = MethodChannel(
    'caregrid/device_integration',
  );
  static const EventChannel _eventChannel = EventChannel(
    'caregrid/device_integration/events',
  );

  final Map<DeviceType, StreamController<DeviceReading>> _controllers = {};
  final Map<DeviceType, Timer> _mockTimers = {};
  final Map<DeviceType, bool> _connected = {};
  final Random _random = Random();
  StreamSubscription<dynamic>? _nativeEventSub;
  bool _nativeEventListenerStarted = false;

  bool isConnected(DeviceType device) => _connected[device] == true;

  Stream<DeviceReading> readings(DeviceType device) {
    return _controllerFor(device).stream;
  }

  StreamController<DeviceReading> _controllerFor(DeviceType device) {
    return _controllers.putIfAbsent(
      device,
      () => StreamController<DeviceReading>.broadcast(),
    );
  }

  Future<void> connect(
    DeviceType device, {
    bool preferNative = true,
  }) async {
    if (_connected[device] == true) return;
    _connected[device] = true;

    if (preferNative) {
      try {
        _ensureNativeEventListener();
        await _channel.invokeMethod<void>(
          'connect',
          <String, dynamic>{'device': device.name},
        );
        _emit(device, 'Native device connected.');
        return;
      } catch (_) {
        // Fallback to mock stream when native bridge is unavailable.
      }
    }

    _startMock(device);
  }

  Future<void> disconnect(DeviceType device) async {
    _connected[device] = false;
    _mockTimers.remove(device)?.cancel();
    try {
      await _channel.invokeMethod<void>(
        'disconnect',
        <String, dynamic>{'device': device.name},
      );
    } catch (_) {}
    _emit(device, 'Disconnected.');
  }

  void _ensureNativeEventListener() {
    if (_nativeEventListenerStarted) return;
    _nativeEventListenerStarted = true;
    _nativeEventSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        final map = event.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final deviceName = (map['device'] ?? '').toString();
        final device = _deviceFromName(deviceName);
        if (device == null) return;

        final connected = map['connected'];
        if (connected is bool) {
          _connected[device] = connected;
        }

        final summary = (map['summary'] ?? '').toString().trim();
        final source = (map['source'] ?? 'native').toString();
        if (summary.isNotEmpty) {
          _emit(device, summary, source: source);
        }
      },
      onError: (_) {},
    );
  }

  DeviceType? _deviceFromName(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'ecg':
        return DeviceType.ecg;
      case 'pft':
        return DeviceType.pft;
      case 'steth':
        return DeviceType.steth;
      default:
        return null;
    }
  }

  void _startMock(DeviceType device) {
    _mockTimers[device]?.cancel();
    _mockTimers[device] = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isConnected(device)) return;
      _emit(device, _mockSummary(device), source: 'mock');
    });
    _emit(device, 'Connected in mock mode.', source: 'mock');
  }

  String _mockSummary(DeviceType device) {
    switch (device) {
      case DeviceType.ecg:
        final hr = 60 + _random.nextInt(45);
        final rhythm = _random.nextBool() ? 'Sinus rhythm' : 'Irregular rhythm';
        return 'ECG HR $hr bpm, $rhythm';
      case DeviceType.pft:
        final fev1 = (1.5 + _random.nextDouble() * 2.5).toStringAsFixed(2);
        final fvc = (2.0 + _random.nextDouble() * 3.0).toStringAsFixed(2);
        return 'PFT FEV1 $fev1 L, FVC $fvc L';
      case DeviceType.steth:
        final sound = _random.nextBool() ? 'Vesicular sounds' : 'Wheeze noted';
        return 'Steth audio: $sound';
    }
  }

  Future<Map<String, dynamic>> status() async {
    try {
      final resp = await _channel.invokeMethod<dynamic>('status');
      if (resp is Map) {
        return resp.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> pushReadingForTest({
    required DeviceType device,
    required String summary,
    String source = 'test',
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'pushReading',
        <String, dynamic>{
          'device': device.name,
          'summary': summary,
          'source': source,
        },
      );
    } catch (_) {
      _emit(device, summary, source: source);
    }
  }

  void _emit(DeviceType device, String summary, {String source = 'app'}) {
    _controllerFor(device).add(
      DeviceReading(
        device: device,
        summary: summary,
        timestamp: DateTime.now(),
        source: source,
      ),
    );
  }

  Future<void> disposeAll() async {
    for (final timer in _mockTimers.values) {
      timer.cancel();
    }
    _mockTimers.clear();
    _connected.clear();
    await _nativeEventSub?.cancel();
    _nativeEventSub = null;
    _nativeEventListenerStarted = false;
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
  }
}
