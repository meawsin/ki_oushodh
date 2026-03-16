# Ki Oushodh — ProGuard / R8 rules

# Keep ML Kit text recognition classes for all scripts
# (referenced by the plugin even though we only use Latin)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Keep Hive model classes
-keep class * extends com.hive.** { *; }
-keep @com.google.gson.annotations.SerializedName class * { *; }

# Flutter TTS
-keep class com.eyedeadevelopment.fluttertts.** { *; }

# General Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**