##############################################
# ✅ ErrorProne, Annotation 관련
##############################################
-keep class com.google.errorprone.annotations.** { *; }
-keep class javax.annotation.** { *; }
-dontwarn com.google.errorprone.**
-dontwarn javax.lang.model.**
-keep class javax.lang.model.element.** { *; }

##############################################
# ✅ Tink 보안 라이브러리 (필요 시)
##############################################
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

##############################################
# ✅ Flutter 관련 보호 규칙
##############################################
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# MethodChannel 핸들러 리플렉션 보호
-keepclassmembers class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler {
    public <init>(...);
}

# PlatformView 사용 시 필수
-keep class io.flutter.plugin.platform.** { *; }

##############################################
# ✅ 앱 클래스 전체 보호 (MainActivity 및 내부 클래스)
##############################################
-keep class com.kmain.pentype_probe_viewer.** { *; }
-keepclassmembers class com.kmain.pentype_probe_viewer.** { *; }

##############################################
# ✅ JNI 및 암호화/보안 관련 클래스
##############################################

# FFmpeg native wrapper 보호
-keep class com.generalplus.ffmpegLib.ffmpegWrapper { *; }
-keepclassmembers class com.generalplus.ffmpegLib.ffmpegWrapper { *; }

# CamWrapper 네이티브 클래스
-keep class generalplus.com.GPCamLib.CamWrapper { *; }
-keepclassmembers class generalplus.com.GPCamLib.CamWrapper { *; }

# 보안 및 암호화 API
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }
-keep class android.security.** { *; }
-keep class android.security.keystore.** { *; }
-keep class javax.crypto.Mac { *; }

##############################################
# ✅ 싱글톤/중요 렌더러 클래스 보호
##############################################
-keep class com.kmain.pentype_probe_viewer.TextRenderer { *; }
-keep class com.kmain.pentype_probe_viewer.ProbeRenderer { *; }

##############################################
# 🚫 로그 제거 비활성화 (개발 중에는 유지 추천)
##############################################
# 릴리즈 빌드 시 로그 제거하려면 아래 주석 해제:
# -assumenosideeffects class android.util.Log {
#     public static *** d(...);
#     public static *** v(...);
#     public static *** i(...);
#     public static *** w(...);
#     public static *** e(...);
# }
