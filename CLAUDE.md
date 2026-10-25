# app_events

Flutter + Firebase app for GDG community events (agenda, QR networking, gamification, resource library). Clean Architecture with Provider + GetIt.

## Commands

```bash
flutter pub get --enforce-lockfile
flutter analyze --fatal-infos
dart format lib test
flutter test                       # whole suite
flutter test test/architecture     # layer and DI rules only
npx --yes cspell@8.19.4 --no-progress
./tool/ci/coverage_helper.sh && flutter test --coverage && ./tool/ci/check_coverage.sh coverage/lcov.info 14
```

`lib/env.dart`, `lib/firebase_options.dart` and `android/app/google-services.json` are git-ignored secrets. Never edit them; `tool/ci/create_config.sh` creates stubs where they are missing.

## Architecture (enforced by test/architecture/layer_dependencies_test.dart)

```
lib/domain/  models, abstract datasources and repositories. Pure Dart: no Flutter, Firebase, dart:io or other layers.
lib/data/    Firebase implementations of the domain contracts. Never imports ui/ or config/.
lib/ui/      providers (ChangeNotifier) and widgets. Talks only to abstract repositories, never to Firebase or data/.
lib/config/  DI (config/di/service_locator.dart), theme, AppStrings, asset paths, AppLinks.
```

- Every datasource and repository contract is registered in `service_locator.dart` with `registerLazySingleton<Contract>`; providers are wired in `main.dart`'s `MultiProvider`.
- `_knownViolations` in the architecture test is empty and must stay that way: fix violations instead of listing them.

## Conventions

- Code, comments and tests are in English. Spanish user-facing text lives only in `lib/config/theme/app_strings.dart` (cspell enforces this in CI).
- UI code never hardcodes texts, colors, asset paths or URLs: use `AppStrings`, `AppStyles` (colors named by role, e.g. `onAccentColor`, not by hue), `AppAssetsPath` and `AppLinks` in `lib/config/theme/`. Only `Colors.transparent` is allowed. Enforced by `test/architecture/hardcoded_values_test.dart` and the edit hook.
- Models: `fromJson` with safe defaults for missing fields, `toJson`, `copyWith`; enums map to strings through a `fromValue` with a fallback.
- Firestore keys and collection names are a data contract: renaming one (e.g. `SocialNetwork`, `workshow`) orphans stored data.
- Providers reset loading flags in `finally` and rethrow errors so the UI can react; do not swallow errors silently.

## Tests

- Mirror `lib/` under `test/`. Shared builders live in `test/helpers/fixtures.dart`.
- Tests assert the correct behavior, never an existing bug. A known bug is a test for the correct behavior marked `skip: 'BUG: <description>'`; tell the user and ask before changing production code.
- Use the `write-tests` skill for per-layer patterns.

## Workflow

- Do not run `git commit` or `git push`: the developer commits. Leave changes in the working tree and summarize them.
- Hooks in `.claude/settings.json` format Dart files, block layer violations, protect secrets, block desktop platforms and run the quality gate when Claude stops.
- The app targets Android, iOS and Web only: never create, enable or build macOS, Windows or Linux (ignored in git and rejected by CI).
- Skills: `new-feature` (vertical slice across layers), `write-tests`, `architecture-review`.
