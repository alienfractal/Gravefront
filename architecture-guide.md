# Building the MIDI Flutter player

This is guidance for building RetroMIDI. The ownership principles are adaptable; the Phase 1 paths and behavior below describe the current implementation. Prefer the smallest structure that supports the requested behavior and update this guide as the app takes shape.

The supplied documents illustrate ownership, lifecycle, screen flow, audio handling, and verification patterns. Adapt those ideas to this MIDI player; they do not define its features or dependencies.

## Ownership and data flow

- In Phase 1, libADLMIDI owns MIDI parsing, sequencing, and OPL3 synthesis. The UI displays playback state and sends user intent; it does not schedule notes or decide when playback has finished.
- Give one playback controller/service responsibility for play, pause, seek, stop, completion, and active-note cleanup. It owns its clock and any subscriptions or timers it creates.
- Put platform MIDI/audio output behind an injectable interface. The playback rules should be testable with a fake output and clock, without a device or audio plugin.
- Create services at an application composition boundary and dispose them there. Avoid global mutable playback state. A new session should not inherit stale notes or callbacks from an old one.
- Let asset or file-loading code own decoding and caching. Widgets consume prepared state; they do not repeatedly parse files during build.
- Separate persistent preferences from a particular playback session. Only add persistence when the feature calls for it.

The audio path is `Flutter UI -> MidiEngine -> Dart worker isolate -> C ABI -> libADLMIDI -> miniaudio -> Windows default device`. Snapshots flow back from the worker to the UI. Audio rendering runs in miniaudio's callback, independent of Flutter frames. A widget animation cannot change musical timing rules.

The player screen owns the current playlist order and selection. `PlaylistStore` persists only track paths to `%APPDATA%/RetroMIDI/playlist.json`; it does not own playback. The screen serializes playlist edits and engine commands, loads a selected track before playing it, and advances to the next track after a `finished` snapshot. Completion work is deferred until after snapshot delivery so a synchronous engine stream cannot be reentered. Restored tracks are shown but not loaded or played until the user selects one or adds new files.

The player screen also owns its visual breakpoints. It shows the deck and playlist side by side from 940 logical pixels of content width, stacks them below that, and uses tighter spacing and a single track-action menu below 560 logical pixels. The visual layout does not affect engine timing or playlist order. Press Start 2P is used for display headings; Pixelify Sans remains the readable interface face.

## Structure as the app grows

Start with cohesive folders, and split a folder only when it has a real responsibility or lifecycle boundary. The current layout is:

```text
lib/
  app/              retro player screen, playlist order, and persistence boundary
  playback/         platform-neutral interface and Windows worker/FFI adapter
assets/fonts/        bundled interface font and license notice
native/              C ABI engine, audio callback, and PCM smoke check
  third_party/      pinned libADLMIDI and miniaudio sources
windows/             Flutter runner and native CMake integration
test/                transport widget check and a small MIDI fixture
tool/                real-device playback smoke check
docs/                architecture and dependency decisions
```

Put a new type beside the feature it serves. Move it into a shared folder only when multiple consumers need the same behavior. Avoid a generic service, manager, factory, or cache layer without a concrete owner and purpose. A future Web backend implements `MidiEngine` without changing the player screen's transport calls.

## State and screen flow

The native engine reports `empty`, `ready`, `playing`, `paused`, `finished`, or `error`. Loading a replacement file stops the audio device first. Pause retains the loaded song and position; stop rewinds it. Destruction stops and releases the device and synth. The Dart worker owns its native handle and status timer; the Flutter screen owns and disposes the worker. The playlist remains in order across restarts; the active playback session does not. Removing the selected track stops it and loads the next available entry without starting playback. Clearing the playlist stops playback and saves an empty list. Reject late work from an old state when adding more asynchronous features.

The supplied `menu-flow.md` illustrates nested state ownership and exit-before-entry transitions. Define this player's actual screens and transitions from its own requirements.

## MIDI and audio behavior

- libADLMIDI handles MIDI ticks, tempo changes, and sequencing in Phase 1. Keep that responsibility in one engine; do not add a competing Dart scheduler.
- Define how seeking, pausing, looping, and switching files affect sounding notes before implementing those operations. Send the required note-off or all-notes-off cleanup at session boundaries.
- Make async starts cancellable or generation-checked so an old load, resume, or device request cannot restart playback after stop, navigation, or disposal.
- For a later web backend, handle any required user gesture before starting audio. Check the chosen backend's platform behavior rather than copying another app's sound-pool design.
- Keep audio failures separate from file parsing and UI readiness. Surface an actionable error while leaving the player in a consistent state.

The supplied `audio.md` is useful for injection, cleanup, gesture retry, and stale async-result handling. Choose the player's audio behavior and dependencies from its own requirements.

## Build and verification

1. Define an observable behavior and the smallest data/ownership change needed for it.
2. Implement the behavior in a verifiable unit. Use a known MIDI fixture to check that the native synth produces nonzero PCM, and use a fake engine and playlist store to check UI transport, ordering, and completion behavior. Test interruption and cleanup paths when they change.
3. Run `dart format` on changed Dart files, `flutter analyze`, `flutter test`, `flutter build windows`, and the relevant smoke checks. Run broader checks when shared playback behavior changes.
4. Exercise the Windows app with speakers for file loading, sound, pause/resume, and stop. Automated checks confirm PCM generation and audio-device calls but cannot replace a listening pass. Check seeking, device loss, or web gestures when those features are introduced.
5. Update this guide and any architecture or user documentation when the implementation changes their stated behavior. Report the checks actually performed.

Add a framework, state machine, cache, or abstraction only when a player feature needs that boundary.
