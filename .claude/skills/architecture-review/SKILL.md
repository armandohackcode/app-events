---
name: architecture-review
description: Review changes in the app_events Flutter app against its Clean Architecture rules (layer boundaries, DI registration, provider patterns, Firestore data contracts, AppStrings for Spanish text, tests that do not hide bugs, secrets). Use this whenever the user asks to review a branch, PR, diff or recent changes, asks "¿esto respeta la arquitectura?", "revisa mi rama antes del PR", "check this before I merge", or wants a pre-merge sanity check on Dart code, even if they don't say "architecture".
---

# Architecture review

The goal is to catch what CI cannot: CI already blocks bad imports, unregistered contracts, formatting, lints, Spanish outside AppStrings and failing tests. This review adds judgment on top: whether the change is designed the way this codebase intends, and whether it can break stored data or hide failures.

This is a read-only review. Report findings; do not edit files unless the user asks for fixes afterwards.

## 1. Scope the diff

Default to the current branch against `main`, including uncommitted work:

```bash
git diff --stat main...HEAD; git status --short
git diff main...HEAD -- lib test; git diff -- lib test
```

If the user names a PR, file or commit range, use that instead. Read the full changed files, not only the hunks, when a finding depends on context.

## 2. Run the mechanical checks first

```bash
flutter analyze --fatal-infos
flutter test test/architecture
```

Report their failures as findings, but do not stop there.

## 3. Review checklist

Read `CLAUDE.md` for the rules behind each point.

1. **Layers**: domain stays pure Dart; UI depends on abstract repositories only; no Firebase types leak through domain contracts (e.g. `DocumentSnapshot`, `Timestamp` in a model or repository signature).
2. **Contracts and DI**: new datasource/repository contracts have Firebase implementations, are registered in `service_locator.dart`, and providers are wired in `main.dart`. No `FirebaseFirestore.instance` or `sl<...>()` calls inside widgets or datasources.
3. **Providers**: loading flags reset in `finally`; errors are rethrown or exposed as state, not swallowed into an empty list; `notifyListeners()` after every state change; no `BuildContext` stored in providers.
4. **Data contract**: renamed or removed Firestore keys, collection names or enum string values break existing documents. Flag any change to `toJson` keys, `fromValue` strings or collection paths, and check that `fromJson` handles documents written by older versions (missing fields).
5. **Centralized values**: no hardcoded texts, colors, asset paths or URLs in UI code; they live in `AppStrings`, `AppStyles` (named by role, not hue), `AppAssetsPath` and `AppLinks`. Check that new constants reuse existing ones instead of duplicating a value under a new name.
6. **Tests**: new behavior has tests in the mirrored folder; no test asserts buggy behavior; every skip uses `BUG:` and the bug was reported; `_knownViolations` did not grow.
7. **Security**: no secrets, tokens or client IDs committed; admin-only actions are still gated by the admin check.

## 4. Report

Use this structure so the developer can act on it quickly:

```
## Architecture review: <branch or scope>

**Verdict:** Ready / Ready after fixes / Needs rework

### Blocking
- [file.dart:42](lib/path/file.dart#L42): what is wrong, why it matters, suggested fix

### Should fix
- ...

### Notes
- smaller suggestions or questions for the author

Checks run: flutter analyze ✔/✘, architecture tests ✔/✘
```

Only include findings you verified in the code. If a section is empty, write "None". Ask the user before fixing anything.
