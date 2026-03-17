package com.example.caregrid

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var deviceBridge: DeviceIntegrationBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceBridge = DeviceIntegrationBridge().also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        deviceBridge?.detach()
        deviceBridge = null
        super.onDestroy()
    }
}
