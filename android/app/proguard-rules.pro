# Keep Firebase and Flutter classes for release builds.
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter deferred components / Play Core.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Razorpay checkout SDK (razorpay_flutter) invokes the launching Activity's
# onPaymentSuccess()/onPaymentError() via reflection — without this, R8 can
# rename/strip those callbacks so a real release-build payment silently
# never returns a result to the app (a known, documented Razorpay Android
# gotcha, not something Flutter's own template rules above cover).
-keep class com.razorpay.** { *; }
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
-keepattributes Exceptions, InnerClasses, Signature, Deprecated, SourceFile, LineNumberTable, *Annotation*, EnclosingMethod
-dontwarn com.razorpay.**
