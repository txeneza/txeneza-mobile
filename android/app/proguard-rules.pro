# Flutter / Dart — mantém as classes da engine intactas
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Realtime — mantém anotações e reflexão necessárias
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Firebase Messaging — necessário para notificações push
-keep class com.google.firebase.** { *; }

# Evita remover enums usados no código Kotlin/Java
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Mapbox Maps
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
