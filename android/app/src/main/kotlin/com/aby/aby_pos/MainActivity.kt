package com.aby.aby_pos

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.Executors

/// Bluetooth printers and scales for Aby (lib/app/services/printing/
/// bluetooth_link.dart, lib/app/services/scale/): lists the paired devices,
/// writes bytes and reads replies over the serial port profile, which most
/// cheap thermal printers and scales speak.
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val spp: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aby/bluetooth").setMethodCallHandler { call, result ->
            if (!allowed()) {
                result.error("permission", "Allow Aby to use nearby devices (Bluetooth), then try again.", null)
                return@setMethodCallHandler
            }
            val adapter = getSystemService(BluetoothManager::class.java)?.adapter
            if (adapter == null || !adapter.isEnabled) {
                result.error("off", "Bluetooth is off. Turn it on, then try again.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "bonded" -> result.success(bonded(adapter))
                "write" -> {
                    val address = call.argument<String>("address")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (address == null || bytes == null) {
                        result.error("args", "No printer or nothing to print.", null)
                    } else {
                        write(adapter, address, bytes, result)
                    }
                }
                "read" -> {
                    val address = call.argument<String>("address")
                    val request = call.argument<ByteArray>("request") ?: ByteArray(0)
                    val millis = call.argument<Int>("millis") ?: 1500
                    if (address == null) {
                        result.error("args", "No scale chosen.", null)
                    } else {
                        read(adapter, address, request, millis, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun bonded(adapter: android.bluetooth.BluetoothAdapter): List<Map<String, String>> =
        adapter.bondedDevices.map { mapOf("name" to (it.name ?: it.address), "address" to it.address) }

    @SuppressLint("MissingPermission")
    private fun write(adapter: android.bluetooth.BluetoothAdapter, address: String, bytes: ByteArray, result: MethodChannel.Result) {
        io.execute {
            try {
                adapter.cancelDiscovery()
                adapter.getRemoteDevice(address).createRfcommSocketToServiceRecord(spp).use { socket ->
                    socket.connect()
                    socket.outputStream.write(bytes)
                    socket.outputStream.flush()
                    // Some printers drop what is still in their buffer when
                    // the link closes straight away.
                    Thread.sleep(400L + bytes.size / 20)
                }
                runOnUiThread { result.success(null) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", "Cannot reach the Bluetooth printer: ${e.message}", null) }
            }
        }
    }

    /// A Bluetooth scale: sends [request] (if any), then collects what comes
    /// back for [millis] milliseconds.
    @SuppressLint("MissingPermission")
    private fun read(
        adapter: android.bluetooth.BluetoothAdapter,
        address: String,
        request: ByteArray,
        millis: Int,
        result: MethodChannel.Result,
    ) {
        io.execute {
            try {
                adapter.cancelDiscovery()
                val got = java.io.ByteArrayOutputStream()
                adapter.getRemoteDevice(address).createRfcommSocketToServiceRecord(spp).use { socket ->
                    socket.connect()
                    if (request.isNotEmpty()) {
                        socket.outputStream.write(request)
                        socket.outputStream.flush()
                    }
                    val input = socket.inputStream
                    val buffer = ByteArray(256)
                    val end = System.currentTimeMillis() + millis
                    while (System.currentTimeMillis() < end) {
                        if (input.available() > 0) {
                            got.write(buffer, 0, input.read(buffer))
                        } else {
                            Thread.sleep(20)
                        }
                    }
                }
                runOnUiThread { result.success(got.toByteArray()) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", "Cannot reach the Bluetooth scale: ${e.message}", null) }
            }
        }
    }

    /// Android 12 and later ask the person once; older versions grant it at
    /// install.
    private fun allowed(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) return true
        requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 1)
        return false
    }
}
