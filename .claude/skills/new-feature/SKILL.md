---
name: new-feature
description: Scaffold a new feature in the app_events Flutter app as a full vertical slice across the Clean Architecture layers (domain model and contracts, Firebase datasource, repository, DI registration, provider, UI wiring and tests). Use this whenever the user wants to add a new feature, screen backed by Firestore data, entity, collection, CRUD flow, or "módulo"/"funcionalidad"/"nueva sección" to the app, even if they only mention one layer (e.g. "add a provider for sponsors", "crear el modelo y el repositorio de badges", "agregar una pantalla de encuestas que lea de Firestore").
---

# New feature (vertical slice)

This app follows Clean Architecture so Firebase can be swapped without touching the UI, and a feature is only done when every layer exists, is registered, and is tested. Adding just a provider that calls Firestore "because it's faster" is exactly the coupling the architecture test and hooks will reject, so build the slice in order: domain first, UI last.

Read `CLAUDE.md` for the rules. Before writing anything, open the closest existing feature and copy its shape; `speed_run` is the smallest complete example:

- `lib/domain/models/speed_run_challenge.dart`
- `lib/domain/datasources/speed_run_datasource.dart`, `lib/domain/repositories/speed_run_repository.dart`
- `lib/data/datasources/firebase_speed_run_datasource.dart`, `lib/data/repositories/speed_run_repository_impl.dart`
- `lib/ui/providers/speed_run_provider.dart`, `lib/ui/screens/speed_run/`
- the matching files under `test/`

## 1. Clarify the data contract

Confirm with the user, if not already clear: the Firestore collection path (top level or under `events/{eventId}`), the document fields and which are optional, whether images go to Storage, and who can write (admin only?). Firestore keys and collection names become a contract with stored data, so agree on them before coding; renaming later orphans documents.

## 2. Domain (`lib/domain/`), pure Dart

- **Model** `models/<feature>.dart`: fields, constructor, `copyWith`, `fromJson` with safe defaults (`json['x'] ?? ''`, `?? 0`, null-checked lists like `json['items'] == null ? [] : List.from(...)`), `toJson`. A missing optional field must never throw.
- **Enums** stored as strings: a private value map plus `static X fromValue(String? text)` that falls back to a safe default (see `ChallengeState`).
- **Contracts** `datasources/<feature>_datasource.dart` and `repositories/<feature>_repository.dart`: abstract classes with one-line doc comments per method. Image uploads take an optional `{String? imagePath}`.

No imports from Flutter, Firebase, `dart:io`, `data/`, `ui/` or `config/`.

## 3. Data (`lib/data/`)

- `datasources/firebase_<feature>_datasource.dart` implements the datasource contract and receives `FirebaseFirestore` (and `FirebaseStorage` if needed) through the constructor; never use `FirebaseFirestore.instance` here.
- Copy the document id into the model on read (`json['id'] = doc.id`) and remove it on write if the id is the document key.
- Upload an image only when `imagePath != null && imagePath.isNotEmpty`.
- `repositories/<feature>_repository_impl.dart` implements the repository contract by delegating to the datasource; keep it a thin adapter.

## 4. Dependency injection

In `lib/config/di/service_locator.dart` register both contracts:

```dart
sl.registerLazySingleton<FeatureDatasource>(() => FirebaseFeatureDatasource(sl(), sl()));
sl.registerLazySingleton<FeatureRepository>(() => FeatureRepositoryImpl(sl()));
sl.registerFactory(() => FeatureProvider(sl<FeatureRepository>()));
```

Then add `ChangeNotifierProvider(create: (_) => sl<FeatureProvider>())` to `_listProviders` in `lib/main.dart`. The architecture test fails if a contract is not registered.

## 5. Provider (`lib/ui/providers/<feature>_provider.dart`)

A `ChangeNotifier` that receives the abstract repository. Reset loading flags in `finally` so a failed request never leaves a spinner forever, and rethrow so the screen can show an error:

```dart
Future<void> loadItems() async {
  _loading = true;
  notifyListeners();
  try {
    _items = await _repository.getItems();
  } finally {
    _loading = false;
    notifyListeners();
  }
}
```

## 6. UI (`lib/ui/screens/`, `lib/ui/widgets/`)

Read state with `Provider.of`/`context.watch`. Never hardcode a text, color, asset path or URL in UI code (the hardcoded-values test and the edit hook reject it): add the value to `lib/config/theme/` and reference it. Texts go to `AppStrings` (Spanish lives only there), colors to `AppStyles` named by role (`onAccentColor`, `shadowColor`), assets to `AppAssetsPath` and links to `AppLinks`.

## 7. Tests

Follow the `write-tests` skill: model, repository, datasource (fake Firestore), provider and at least one widget test, mirrored under `test/`. Add builders for the new model to `test/helpers/fixtures.dart`.

## 8. Verify and hand off

```bash
dart format lib test && flutter analyze --fatal-infos && flutter test
npx --yes cspell@8.19.4 --no-progress
```

Do not commit. Finish with a short summary listing the files per layer, the Firestore collection and fields chosen, and anything the user must set up manually (Firestore rules, indexes, seed documents, admin-only access).
