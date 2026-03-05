# Product Catalog App

Flutter product catalog app built with a reusable design system, Riverpod state management, GoRouter navigation, and Drift offline cache.

## Setup & Run Instructions

### Flutter/Dart Version
- Flutter: `3.38.3` (stable)
- Dart: `3.10.1`

### Install Dependencies
```bash
flutter pub get
```

### Generate Drift Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the App
```bash
flutter run
```

### Run Tests
```bash
flutter test
```

### Run Static Analysis
```bash
dart analyze
```

## Architecture Overview

### Folder Structure
- `lib/src/core`: app-wide concerns (`router`, `theme`, `logging`)
- `lib/src/design_system`: reusable themed UI components
- `lib/src/features/catalog/domain`: business entities and paging models
- `lib/src/features/catalog/data`: API, repository, and Drift local database
- `lib/src/features/catalog/presentation`: Riverpod controllers/providers and screens

### State Management
- Uses `StateNotifier` + `StateNotifierProvider` (Riverpod).
- `ProductListController` owns list state transitions and side effects.
- Explicit list phases are handled: `initial`, `loading`, `loaded`, `empty`, `error`.
- Search uses debounce to reduce API calls.

### Data Flow
1. UI dispatches intents (search, filter, refresh, paginate) to `ProductListController`.
2. Controller asks `ProductRepository` for data.
3. Repository fetches from DummyJSON API first.
4. On success, data is validated/mapped and upserted into Drift.
5. On remote failure, repository falls back to Drift cache.

### Navigation
- GoRouter routes are centralized in `core/router/app_router.dart`.
- Deep link is supported at `/products/:id`.
- Responsive behavior:
  - `< 768`: push navigation (list -> detail)
  - `>= 768`: master-detail split layout (list left, detail right)

## Design System Rationale

### Component API Choices
The design system components are intentionally small and composable:
- `AppSearchBar`
- `CategoryFilterChip`
- `ProductCard`
- `AppNetworkImage`
- `SkeletonCardList` / `PaginationLoader`
- `StatusView` (error, empty, prompt)

Each component has a narrow API and can be reused across list/detail/split screens without business logic coupling.

### Theming
- Material 3 with custom seeded light/dark color schemes.
- Typography uses `google_fonts` (`Manrope`) to avoid default system feel.
- Shared shape, chip, card, and input styles are centralized in `AppTheme`.

### Spec Deviations
- For combined `category + search`, category endpoint is used first and search is applied client-side per fetched page. This keeps category filter authoritative while still supporting search.
