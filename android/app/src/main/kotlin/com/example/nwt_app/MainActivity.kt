package com.app.networthtracker

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "app.pivotm/branch_io"
    private var branchData: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // Register CleverTap Activity Lifecycle Callbacks
        com.clevertap.android.sdk.ActivityLifecycleCallback.register(this.application)
        super.onCreate(savedInstanceState)
        
        // Enable CleverTap Debug logging
        com.clevertap.android.sdk.CleverTapAPI.setDebugLevel(com.clevertap.android.sdk.CleverTapAPI.LogLevel.DEBUG)
        
        // Handle intent when app is started from a Branch link
        if (intent != null && intent.data != null) {
            branchData = intent.data.toString()
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Handle intent when app is already running and receives a Branch link
        if (intent != null && intent.data != null) {
            branchData = intent.data.toString()
            // Send data to Flutter
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("handleBranchDeepLink", branchData)
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel to communicate with Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBranchData" -> {
                    result.success(branchData)
                    // Clear the data after sending it to Flutter
                    branchData = null
                }
                else -> result.notImplemented()
            }
        }
    }
}
