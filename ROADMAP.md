# ROADMAP.md

# Voice Waveform Roadmap

## Phase 1: Mock Waveform UI

Goal:

* Build the basic waveform UI using mock volume stream.

Status:

* Complete this first before adding microphone input.

Validation:

* `flutter analyze`
* `flutter test`
* `flutter run -d android`

## Phase 2: Visual Refinement

Goal:

* Make the waveform visually closer to iPhone Voice Memos.

Tasks:

* Tune bar width, gap, and radius.
* Tune scroll offset logic.
* Tune mock volume naturalness.
* Add attack/release smoothing.
* Prevent flickering and jumping.
* Ensure height remains between 12dp and 58dp.

Done criteria:

* Bars move smoothly from right to left.
* New bars enter from the right edge.
* Bars look natural and voice-like.
* No sudden random jitter.

## Phase 3: Android Recording Input

Goal:

* Add real microphone volume source for Android.

Tasks:

* Add `record` package.
* Add `permission_handler` package if needed.
* Add `RecorderVolumeSource`.
* Add Android microphone permission.
* Convert amplitude/dB to 0.0~1.0 volume.
* Keep mock mode available.

Done criteria:

* User can switch from mock to recording.
* Real voice changes waveform height.
* Stop recording releases resources.
* Repeated start/stop does not crash.

## Phase 4: Permission and Lifecycle

Goal:

* Make recording robust.

Tasks:

* Handle permission denied.
* Handle permanently denied.
* Handle app lifecycle pause/resume.
* Stop recorder on dispose.
* Avoid duplicate recorder sessions.
* Show errors in demo page.

Done criteria:

* App does not crash on permission denial.
* App does not keep recording after leaving the page.
* Repeated start/stop is safe.

## Phase 5: Reusable API

Goal:

* Make the waveform reusable in other Flutter projects.

Tasks:

* Clean public widget API.
* Add style parameters.
* Add optional controller.
* Add clear/pause/resume support if needed.
* Keep source interface independent.

Done criteria:

* A developer can use the component by passing a `Stream<double>`.
* The component can be reused without the demo page.
* Recording source can be replaced without changing waveform UI.

## Phase 6: Tests and Documentation

Goal:

* Add tests and usage documentation.

Tasks:

* Add tests for volume mapping.
* Add README usage example.
* Add Android setup notes.
* Add troubleshooting notes for Gradle, NDK, proxy, and permissions.

Done criteria:

* `flutter analyze` passes.
* `flutter test` passes.
* README explains how to run on Android.
* Known Android setup issues are documented.
