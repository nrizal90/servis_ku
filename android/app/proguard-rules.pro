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

# Gson TypeToken - required by flutter_local_notifications to load scheduled notifications
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Timezone
-keep class org.joda.** { *; }
