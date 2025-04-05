# ProGuard rules for the Community Dashboard app
# Add custom rules here if needed

# Keep class names for Firebase
-keep class com.google.firebase.** { *; }

# Keep class names for Flutter
-keep class io.flutter.** { *; }

# Keep class names for Kotlin
-keep class kotlin.** { *; }

# General Android rules
-dontwarn android.support.**
-dontwarn androidx.**