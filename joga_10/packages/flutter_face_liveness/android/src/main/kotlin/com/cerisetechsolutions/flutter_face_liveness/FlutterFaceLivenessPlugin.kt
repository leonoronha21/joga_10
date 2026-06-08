package com.cerisetechsolutions.flutter_face_liveness

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FlutterFaceLivenessPlugin — native stub; all processing is done in Dart via ML Kit. */
class FlutterFaceLivenessPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // No native method channels required; ML Kit and Camera are consumed as
        // Flutter pub.dev packages directly from Dart.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
