# Add project specific ProGuard rules here.
# Keep Kotlin Coroutines & Serialization metadata
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod

# Keep Domain Models from obfuscation issues if reflected
-keep class com.nexus.core.model.** { *; }

