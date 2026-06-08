# ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-dontwarn com.google.mlkit.**

# Camera2
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Keep the plugin class
-keep class com.cerisetechsolutions.flutter_face_liveness.** { *; }
