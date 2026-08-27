package com.corextra.corextra

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// Backs the App Size tab's Android quick scan: exposes the running app's own installed APK path(s), which pure Dart has no way to discover on this platform.
class CorextraPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: android.content.Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "corextra/app_size")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getApkPaths" -> result.success(getApkPaths())
            else -> result.notImplemented()
        }
    }

    // The base APK plus any split APKs from an Android App Bundle install, each contributing to the app's real installed size.
    private fun getApkPaths(): List<String> {
        val info = applicationContext.packageManager.getApplicationInfo(
            applicationContext.packageName,
            0,
        )
        val paths = mutableListOf<String>()
        info.sourceDir?.let { paths.add(it) }
        info.splitSourceDirs?.let { paths.addAll(it) }
        return paths
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
