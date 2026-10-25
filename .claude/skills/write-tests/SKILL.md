---
name: write-tests
description: Write or extend tests for the app_events Flutter app following its per-layer conventions (domain model tests, repository tests with mocktail, Firebase datasource tests with fake_cloud_firestore, ChangeNotifier provider tests, widget tests) and its rule that tests must never encode a bug. Use this whenever the user asks to add, fix or review tests, raise coverage, test a model/provider/datasource/widget, reproduce a bug with a test, or says things like "agrega tests", "cubrir con pruebas", "subir la cobertura", "test para este provider", even if they don't name a layer.
---

# Writing tests in app_events

Tests here exist to protect behavior. A test that passes because it asserts what the code currently does, bug included, is worse than no test: it makes the bug look intended. So before writing an assertion, decide what the **correct** behavior is from the domain and the UI that consumes it, then check whether the code does that.

## The bug policy

When the implementation is wrong:

1. Write the test for the correct behavior.
2. Mark it `skip: 'BUG: <one-line description>'` so CI stays green while the bug stays visible (CI lists every `BUG:` skip in the job summary; the PostToolUse hook rejects skips without that prefix).
3. Prove it is a real bug and not a bad test: `flutter test --run-skipped <file>` must fail.
4. Tell the user what is wrong and where (`file:line`), and ask before changing production code. Once they approve and it is fixed, remove the `skip`.

If you are unsure whether something is a bug or a design decision (e.g. a provider that swallows errors and shows an empty list), do not assert either way; test only the part that is unambiguous and ask.

## Where tests go

Mirror `lib/` under `test/` (`lib/ui/providers/x_provider.dart` → `test/ui/providers/x_provider_test.dart`). Reuse and extend the builders in `test/helpers/fixtures.dart` (`makeEvent`, `makeChallenge`, `makeSpeaker`, `makeSponsor`) so each test only overrides the fields it cares about. Test data and names are in English; when a widget shows Spanish text, reference the `AppStrings` constant instead of the literal.

## Per-layer patterns

Read the existing test of the same layer first and match it.

**Domain models**: `test/domain/models/speed_run_challenge_test.dart`
- `fromJson({})` or with missing optional fields uses safe defaults and never throws.
- Round trip `fromJson(toJson(x))`, compare with `toJson()` equality.
- `copyWith` replaces only the given fields; enum `fromValue` falls back for null/unknown.
- Pin Firestore key names that are a data contract (e.g. `SocialNetwork`).

**Repositories**: `test/data/repositories/repository_impl_test.dart`
- `class _MockXDatasource extends Mock implements XDatasource {}` and `registerFallbackValue(...)` in `setUpAll` for custom types used with `any()`.
- Verify delegation with the exact arguments (`verify(() => ds.addX(x, imagePath: '/tmp/a.png'))`).
- Errors: `thenAnswer((_) async => throw Exception('offline'))`, not `thenThrow`; real datasources fail asynchronously and `thenThrow` throws before `expect` can catch it.

**Firebase datasources**: `test/data/datasources/firebase_event_datasource_test.dart`
- `FakeFirebaseFirestore()` and `MockFirebaseStorage()` injected through the constructor.
- Seed with `firestore.collection('x').doc('id').set(...)`; assert on stored documents (collection name, field names, id handling, ordering).
- For uploads, create a real temp file with `Directory.systemTemp.createTempSync` and clean it up in `addTearDown`.
- For streams, set up `expect(stream, emitsInOrder([...]))` before writing the data.

**Providers**: `test/ui/providers/schedule_provider_test.dart`
- Mock the abstract repository with mocktail; `dispose()` the provider in `tearDown`.
- Assert state after success and after failure: loading flags must return to `false` and the error must propagate (`await expectLater(provider.load(), throwsException)`).
- To check notification order, record values in `provider.addListener`.

**Widgets**: `test/ui/widgets/card_challenge_test.dart`
- Pump inside `MaterialApp(home: Scaffold(body: ...))`; provide providers with `ChangeNotifierProvider.value` around a mocked repository when the widget reads one.
- Assert what the user sees and can do: texts, enabled/disabled taps, dialogs returning values.

**Architecture**: `test/architecture/layer_dependencies_test.dart` already covers imports and DI registration. Never add entries to `_knownViolations`.

## Run and report

```bash
flutter test <files you touched>
flutter test                                    # full suite before finishing
./tool/ci/coverage_helper.sh && flutter test --coverage && ./tool/ci/check_coverage.sh coverage/lcov.info 14
```

If coverage rose clearly above the `MIN_COVERAGE` value in `.github/workflows/ci.yml`, suggest raising it (it is a ratchet: it only goes up). Report what is now covered, any `BUG:` tests added with their verification, and coverage before and after.
