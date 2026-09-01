# WordMemoryCards

An offline, iPad-first vocabulary flashcard app for family learning. Import a
simple Markdown or plain-text word list, then let the app schedule two
independent review directions: English to Chinese and Chinese to English.

The app starts with an empty word library. Vocabulary, review history, and
backups stay on the device unless the user explicitly exports a backup file.

## Features

- Import, edit, search, and remove user-owned vocabulary.
- Direction-specific spaced repetition with levels 0 through 9.
- Same-session retry, weak-item practice, progress reports, and streaks.
- On-device English and Chinese speech, adjustable speech rate, and haptics.
- JSON backup and restore with validation and a safety backup before restore.
- iPad-only SwiftUI interface, supporting portrait and landscape on iPadOS 16+
  without third-party runtime dependencies.

## Build and run

1. Clone this repository on a Mac with Xcode.
2. Open `WordMemoryCards.xcodeproj` in Xcode.
3. In **Signing & Capabilities**, choose your own Apple Development Team.
4. If Xcode reports a bundle identifier conflict, change it to one you own.
5. Select an iPad simulator or device, then press Run.

`project.yml` is the XcodeGen project definition. If you change it, install
[XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate`
from the repository root to regenerate the committed Xcode project.

## Tests

With an iPad Simulator booted, run the following from the repository root:

```sh
xcodebuild test -parallel-testing-enabled NO \
  -project WordMemoryCards.xcodeproj \
  -scheme WordMemoryCards \
  -destination 'platform=iOS Simulator,name=iPad (A16)'
```

The project has unit tests for parsing, import, spaced repetition, queues,
persistence, backup, and progress reset, plus two UI smoke tests. Serial test
execution is used because this Xcode version can intermittently terminate two
UI-test runner launches when scheduled concurrently.

## Privacy

WordMemoryCards has no account system, analytics, advertising SDK, server API,
or bundled vocabulary corpus. The content you add and your learning history are
stored locally in the app's Core Data database. Exported backups are ordinary
files that you choose where to save and share.

## Attribution

This app was independently implemented for an iPad-first, two-direction spaced
repetition workflow. Its architecture and selected general-purpose interaction
patterns were informed by [TOEFL Vocab](https://github.com/a1mohamad/toefl-vocabs-ios-app)
by Amir Mohammad Askari, released under the MIT License.

The upstream project's copyright and MIT notice are preserved in
[LICENSE](LICENSE), with additional attribution in [NOTICE](NOTICE). The
detailed adaptation record is in [REUSE_PLAN.md](REUSE_PLAN.md). No upstream
TOEFL/504 word lists, screenshots, or publisher-owned material are included.

## License

WordMemoryCards is distributed under the MIT License. See [LICENSE](LICENSE)
and [NOTICE](NOTICE).
