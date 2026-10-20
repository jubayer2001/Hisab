# Release builds shrink code with R8. These plugins call into Android through JNI,
# which finds methods by name at runtime, so R8 must not remove or rename them.
# Without these rules the app crashes at startup in release mode (blank white screen).
# The plugin looks up suspend functions by their JVM signature, which contains
# kotlin.coroutines.Continuation. If R8 renames it (e.g. to "u4") the lookup fails
# with NoSuchMethodError at startup.
# The JNI layer also looks up kotlin.Result and friends by name, so keep the whole
# Kotlin base library intact rather than chasing individual classes.
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class io.flutter.plugins.sharedpreferences.** { *; }
# Reminder notifications are stored as JSON (Gson) and read back by the boot receiver.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature,*Annotation*
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-dontwarn com.github.dart_lang.jni.**
