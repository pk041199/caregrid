package com.example.caregrid

import android.os.Handler
import android.os.Looper
import java.util.Locale
import kotlin.random.Random

interface DeviceAdapter {
    val deviceKey: String
    fun connect(): Boolean
    fun disconnect()
    fun isConnected(): Boolean
    fun startStreaming(onReading: (String) -> Unit)
    fun stopStreaming()
}

abstract class BaseTemplateAdapter(
    override val deviceKey: String,
) : DeviceAdapter {
    private val handler = Handler(Looper.getMainLooper())
    private val random = Random(System.currentTimeMillis())
    private var connected = false
    private var emitter: Runnable? = null

    override fun connect(): Boolean {
        // TODO(vendor-sdk): Initialize and connect vendor SDK for this device.
        connected = true
        return true
    }

    override fun disconnect() {
        stopStreaming()
        // TODO(vendor-sdk): Disconnect and release vendor SDK resources.
        connected = false
    }

    override fun isConnected(): Boolean = connected

    override fun startStreaming(onReading: (String) -> Unit) {
        stopStreaming()
        if (!connected) return

        // Mock stream. Replace with vendor callback subscription.
        val task = object : Runnable {
            override fun run() {
                if (!connected) return
                onReading(generateMockSummary(random))
                handler.postDelayed(this, EMIT_INTERVAL_MS)
            }
        }
        emitter = task
        handler.postDelayed(task, EMIT_INTERVAL_MS)
    }

    override fun stopStreaming() {
        emitter?.let(handler::removeCallbacks)
        emitter = null
    }

    protected abstract fun generateMockSummary(random: Random): String

    companion object {
        private const val EMIT_INTERVAL_MS = 2000L
    }
}

class EcgAdapterTemplate : BaseTemplateAdapter("ecg") {
    override fun generateMockSummary(random: Random): String {
        val hr = 60 + random.nextInt(45)
        val rhythm = if (random.nextBoolean()) "Sinus rhythm" else "Irregular rhythm"
        return "ECG HR $hr bpm, $rhythm"
    }
}

class PftAdapterTemplate : BaseTemplateAdapter("pft") {
    override fun generateMockSummary(random: Random): String {
        val fev1 = "%.2f".format(Locale.US, 1.5 + random.nextDouble() * 2.5)
        val fvc = "%.2f".format(Locale.US, 2.0 + random.nextDouble() * 3.0)
        return "PFT FEV1 $fev1 L, FVC $fvc L"
    }
}

class StethAdapterTemplate : BaseTemplateAdapter("steth") {
    override fun generateMockSummary(random: Random): String {
        val finding = if (random.nextBoolean()) "Vesicular sounds" else "Wheeze noted"
        return "Steth audio: $finding"
    }
}

