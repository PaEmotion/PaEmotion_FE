package com.sungshin.paemotion

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                "deeplink_channel"
        ).invokeMethod("onDeepLink", intent.dataString)
    }
}