# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (required by Flutter, suppress R8 missing class warnings)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# SQLite
-keep class net.sqlcipher.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# Timezone
-keep class org.joda.** { *; }
