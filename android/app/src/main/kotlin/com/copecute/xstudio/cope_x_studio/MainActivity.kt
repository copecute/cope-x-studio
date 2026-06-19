package com.copecute.xstudio.cope_x_studio

import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformBridge(this).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
