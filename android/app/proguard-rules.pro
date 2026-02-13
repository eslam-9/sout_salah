# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase (if used internally by other packages)
-keep class com.google.firebase.** { *; }

# Audio Service & Just Audio
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keep class io.ktor.** { *; }

# Json Serialization (if used indirectly)
-keepnames class * {
    String toString();
}
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter embedding
-keep class io.flutter.embedding.engine.FlutterJNI { *; }

# Generated Plugin Registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Suppress warnings for Play Store missing classes (Deferred Components)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
