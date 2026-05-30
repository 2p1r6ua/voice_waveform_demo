# Voice Waveform Demo

Android-first Flutter voice waveform demo and reusable component inspired by
iPhone Voice Memos.

The waveform is drawn with `CustomPaint` and consumes a plain
`Stream<double>`. Each sample must be in the `0.0` to `1.0` range. The visual
component does not depend on microphone APIs, so the same widget can be driven
by mock data, Android microphone volume, file playback, or any other volume
source.

## 中文说明

这是一个 Android 优先的 Flutter 语音波形 Demo 和可复用组件。组件效果接近
iPhone 语音备忘录：黑色背景、白色圆角竖条、最新柱子从右侧进入、旧柱子平滑
向左滚动。

当前范围仅包含 Android。不要在本阶段加入 iOS、Web 或 Windows 桌面实现。

## 项目目标

- 使用 `CustomPaint` / `CustomPainter` 绘制实时波形。
- 默认显示白色圆角竖条和黑色背景。
- 最新柱子从右侧进入，旧柱子向左平滑移动。
- 默认柱高保持在 `12dp~58dp`。
- 默认柱宽 `6dp`，柱间距 `6dp`。
- 支持 Mock 模式和 Android Recording 模式。
- 保持 waveform 渲染逻辑与录音、权限逻辑分离。

## Android 环境要求

- Flutter SDK
- Android SDK
- Android Studio 或等价 Android 构建环境
- 一台 Android 真机或模拟器

检查环境：

```powershell
flutter doctor -v
flutter devices
adb devices
```

如果本机没有把 `flutter` 或 `dart` 加入 `PATH`，请改用你本机 Flutter SDK 下的
实际路径，例如：

```powershell
<flutter-sdk>\bin\flutter.bat doctor -v
<flutter-sdk>\bin\flutter.bat devices
```

## 运行命令

安装或刷新依赖：

```powershell
flutter pub get
```

格式化、分析和测试：

```powershell
dart format lib test
flutter analyze
flutter test
```

运行到 Android 设备：

```powershell
flutter devices
flutter run -d android
```

如果当前 Flutter 版本不接受 `-d android`，请使用 `flutter devices` 输出的具体
设备 ID：

```powershell
flutter run -d <device-id>
```

## Demo 模式

Demo 页面包含：

- `Use Mock Source`
- `Start Recording`
- `Stop Recording`
- `Clear Waveform`
- `Show Debug` / `Hide Debug`

### Mock 模式

Mock 模式使用 `MockVolumeSource`，不会打开麦克风，也不会触发 Android 权限。
适合验证 UI、滚动、平滑和视觉调参。

### Recording 模式

Recording 模式使用 `RecorderVolumeSource`，通过 Android 麦克风获取音量，并输出
`Stream<double>` 给 `VoiceMemoWaveform`。波形组件本身仍然只消费音量流，不直接
依赖录音 API。

录音显示链路包含 dB 归一化、动态范围校准、噪声门、中值滤波、最大上升限制、
attack/release 平滑和轻量瞬态冲击抑制。

## 可复用组件用法

最小用法：

```dart
VoiceMemoWaveform(volumeStream: someVolumeStream)
```

使用控制器：

```dart
final controller = VoiceMemoWaveformController();

VoiceMemoWaveform(
  volumeStream: someVolumeStream,
  controller: controller,
);

controller.pause();
controller.resume();
controller.clear();
```

常用视觉和灵敏度参数：

```dart
VoiceMemoWaveform(
  volumeStream: someVolumeStream,
  minBarHeight: 12,
  maxBarHeight: 58,
  barWidth: 6,
  barGap: 6,
  noiseGate: 0.14,
  contrastExponent: 1.55,
  attack: 0.50,
  release: 0.18,
  maxRisePerTick: 0.18,
)
```

`noiseGate` 当前默认值是 `0.14`。如果安静环境下柱子仍偏高，可以略微调高；
如果正常说话被压得太低，可以略微调低。

## Android 权限

真实录音需要在 `android/app/src/main/AndroidManifest.xml` 中声明：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

Demo 已处理：

- permission granted
- permission denied
- permission permanently denied
- repeated start/stop taps
- app backgrounding during recording

如果权限被永久拒绝，请到 Android 系统设置中重新打开该应用的麦克风权限。

## 调试信息

点击 `Show Debug` 可以查看：

- current mode
- raw volume
- normalized volume
- display volume
- smoothed volume
- estimated bar height
- impulse suppression state

这些信息只用于调参，不影响普通使用。

## 常见问题排查

### Mock 模式有波形，Recording 模式没有变化

- 确认 Android 麦克风权限已授予。
- 点击 `Show Debug`，观察说话时 display volume 是否变化。
- 靠近设备麦克风说话。
- 确认设备输入没有被系统、耳机或其他应用占用。

### 安静环境下柱子仍偏高

- 提高 `noiseGate`。
- 提高 `contrastExponent`。
- 提高 `RecorderVolumeSource` 的 `ceilingDb`。

### 正常说话波形偏低

- 降低 `noiseGate`。
- 提高 `attack`。
- 将 `ceilingDb` 调低一些，例如接近 `-10.0` 或 `-12.0`。

### 拍桌子或碰设备仍出现明显高柱

- 降低 `maxRisePerTick`。
- 降低 `impulseDamping`。
- 提高 `impulseThreshold`。

### Gradle 或 Android SDK 构建失败

- 检查 Android SDK 是否安装完整。
- 检查 Android Studio SDK Manager。
- 如果依赖下载失败，检查本机 Gradle 或网络代理设置。
- 如果 NDK 损坏，删除损坏的 NDK 目录后从 Android Studio SDK Manager 重新安装。

## 上传/分享注意事项

公开上传或发给第三方时，不要包含 Codex 开发过程使用的上下文、路线图或阶段说明
文件：

- `AGENTS.md`
- `SPEC.md`
- `ROADMAP.md`
- `ANDROID_NOTES.md`
- `ENVIRONMENT.md`
- `ADDITIONAL_PHASE.md`

这些文件已加入 `.gitignore`。如果它们已经被当前仓库跟踪，`.gitignore` 不会自动
将它们从历史或索引中移除；提交前请检查提交清单。

同时不要上传以下本地文件或目录：

- `build/`
- `.dart_tool/`
- `.idea/`
- `.vscode/` 中包含个人配置的文件
- 任何包含本机用户名、设备序列号、代理地址、绝对路径或临时聊天/截图路径的文件

## Known Limits

- Current implementation is Android-only.
- No iOS, Web, Windows desktop, or publishing support is implemented.
- The waveform is a visual volume display, not speech recognition or a full
  audio analysis tool.
- Impulse suppression is lightweight and heuristic; extremely loud or sustained
  non-speech sounds may still produce visible bars.
