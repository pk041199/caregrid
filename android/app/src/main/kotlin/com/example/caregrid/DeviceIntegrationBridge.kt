package com.example.caregrid

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class DeviceIntegrationBridge : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val adapters: Map<String, DeviceAdapter> = mapOf(
        "ecg" to EcgAdapterTemplate(),
        "pft" to PftAdapterTemplate(),
        "steth" to StethAdapterTemplate(),
    )
    private val connected = mutableSetOf<String>()

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    fun detach() {
        stopAllEmitters()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> {
                val device = normalizeDevice(call.argument<String>("device"))
                if (device == null) {
                    result.error("INVALID_DEVICE", "Missing or invalid device", null)
                    return
                }
                connectDevice(device)
                result.success(mapOf("ok" to true, "device" to device))
            }

            "disconnect" -> {
                val device = normalizeDevice(call.argument<String>("device"))
                if (device == null) {
                    result.error("INVALID_DEVICE", "Missing or invalid device", null)
                    return
                }
                disconnectDevice(device)
                result.success(mapOf("ok" to true, "device" to device))
            }

            "status" -> {
                result.success(
                    mapOf(
                        "connected" to connected.toList(),
                    ),
                )
            }

            "pushReading" -> {
                val device = normalizeDevice(call.argument<String>("device"))
                if (device == null) {
                    result.error("INVALID_DEVICE", "Missing or invalid device", null)
                    return
                }
                val summary = (call.argument<String>("summary") ?: "").trim()
                val source = (call.argument<String>("source") ?: "native_manual").trim()
                if (summary.isNotEmpty()) {
                    emitEvent(
                        device = device,
                        summary = summary,
                        connected = connected.contains(device),
                        source = source,
                    )
                }
                result.success(mapOf("ok" to true))
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun connectDevice(device: String) {
        val adapter = adapters[device]
        if (adapter?.connect() != true) return
        connected.add(device)
        emitEvent(
            device = device,
            summary = "Native bridge connected.",
            connected = true,
            source = "native_bridge",
        )
        adapter.startStreaming { summary ->
            emitEvent(
                device = device,
                summary = summary,
                connected = adapter.isConnected(),
                source = "native_bridge",
            )
        }
    }

    private fun disconnectDevice(device: String) {
        adapters[device]?.disconnect()
        connected.remove(device)
        emitEvent(
            device = device,
            summary = "Native bridge disconnected.",
            connected = false,
            source = "native_bridge",
        )
    }

    private fun stopAllEmitters() {
        adapters.values.forEach {
            it.stopStreaming()
            it.disconnect()
        }
        connected.clear()
    }

    private fun emitEvent(
        device: String,
        summary: String,
        connected: Boolean,
        source: String,
    ) {
        val sink = eventSink ?: return
        sink.success(
            mapOf(
                "device" to device,
                "summary" to summary,
                "connected" to connected,
                "source" to source,
                "timestamp" to System.currentTimeMillis(),
            ),
        )
    }

    private fun normalizeDevice(value: String?): String? {
        val normalized = (value ?: "").trim().lowercase(Locale.US)
        return if (normalized in SUPPORTED_DEVICES) normalized else null
    }

    companion object {
        private const val METHOD_CHANNEL = "caregrid/device_integration"
        private const val EVENT_CHANNEL = "caregrid/device_integration/events"
        private val SUPPORTED_DEVICES = setOf("ecg", "pft", "steth")
    }
}
