# ANDROID_NOTES.md

# Android Notes

## Current Android SDK

```text
Android SDK: D:\Android\Sdk
ANDROID_HOME: D:\Android\Sdk
ANDROID_SDK_ROOT: D:\Android\Sdk
```

## Android Studio

```text
Android Studio: D:\Program Files\Android\Android Studio
JDK: D:\Program Files\Android\Android Studio\jbr\bin\java
```

## Test Device

```text
Device: DBY W09
Target: Android physical device
```

## Common Commands

```powershell
flutter doctor -v
flutter devices
adb devices
flutter run -d android
```

## Gradle Proxy

If Gradle cannot download dependencies, check:

```text
C:\Users\hello\.gradle\gradle.properties
```

Example proxy config:

```properties
org.gradle.jvmargs=-Xmx4G -Dfile.encoding=UTF-8

systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=7890
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=7890

systemProp.http.nonProxyHosts=localhost|127.0.0.1
systemProp.https.nonProxyHosts=localhost|127.0.0.1
```

## NDK

If build fails with NDK install error, check:

```text
D:\Android\Sdk\ndk
```

Recommended fix:

* Delete corrupted NDK folder.
* Reinstall required NDK from Android Studio SDK Manager.
* Or use `sdkmanager`.

## Android Permission

For real recording, add:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

File:

```text
android/app/src/main/AndroidManifest.xml
```
