# ── Flutter Engine ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Firebase Core ────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Firebase Crashlytics ─────────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# ── Firebase Analytics ───────────────────────────────────────────────────────────
-keep class com.google.firebase.analytics.** { *; }

# ── Firebase Auth ────────────────────────────────────────────────────────────────
-keep class com.google.firebase.auth.** { *; }

# ── Cloud Firestore ──────────────────────────────────────────────────────────────
-keep class com.google.cloud.firestore.** { *; }

# ── Google Mobile Ads (AdMob) ────────────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ── In-App Purchase / Play Billing ──────────────────────────────────────────────
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# ── AndroidX / FileProvider ──────────────────────────────────────────────────────
-keep class androidx.core.content.FileProvider { *; }

# ── Kotlin Metadata (needed by many Kotlin libs) ─────────────────────────────────
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep class kotlin.** { *; }
-dontwarn kotlin.**
