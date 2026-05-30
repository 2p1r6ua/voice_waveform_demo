# Development Environment

## Project

* Project name: voice_waveform_demo
* Project path: `D:\Projects\voice_waveform_demo`
* Main target platform: Android
* Later target platform: iOS
* Current OS: Windows

## Flutter SDK

* Flutter SDK path: `D:\dev\flutter`

### flutter --version

```text
在这里粘贴 flutter --version 输出
```

## Android SDK

* Android SDK path: `D:\Android\Sdk`

If Android Studio uses another SDK path, update this section.

## Android Studio

* Android Studio installed: yes
* Android SDK Manager available: yes
* Android SDK Build-Tools installed: yes
* Android SDK Platform-Tools installed: yes
* Android SDK Command-line Tools installed: yes

## VS Code

* VS Code installed: yes
* Flutter extension installed: yes
* Dart extension installed: yes

## flutter doctor -v

```text
在这里粘贴 flutter doctor -v 的关键输出
[✓] Flutter (Channel stable, 3.44.0, on Microsoft Windows [版本 10.0.26200.8457], locale zh-CN) [571ms]
    • Flutter version 3.44.0 on channel stable at D:\dev\flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 559ffa3f75 (13 days ago), 2026-05-15 14:13:13 -0700
    • Engine revision 4c525dac5e
    • Dart version 3.12.0
    • DevTools version 2.57.0
    • Feature flags: enable-web, enable-linux-desktop, enable-macos-desktop, enable-windows-desktop, enable-android,
      enable-ios, cli-animations, enable-native-assets, enable-swift-package-manager, omit-legacy-version-file,
      enable-lldb-debugging, enable-uiscene-migration


重点保留：
[√] Flutter
[√] Android toolchain
[√] Android Studio
[√] Connected device

如果有报错，需要保留完整报错信息。
```

## Connected Devices

### flutter devices

```text
在这里粘贴 flutter devices 输出
```

### adb devices

```text
在这里粘贴 adb devices 输出
```

## Notes

* Android is the first test target.
* iOS testing will be done later on macOS with Xcode.
* The first development stage uses mock volume stream.
* Real microphone recording will be added after the waveform UI is stable.
