# Shoply Product Catalogue Implementation Plan

## Objective

Build a small Flutter Android catalogue using DummyJSON, with reliable paginated search, offline list recovery, persistent favourites, and recent searches. Deliver an installable APK and a source ZIP with a complete README (or a GitHub repository link).

This document is an implementation handoff. Part 1 foundations are implemented; catalogue loading and the remaining features are still pending. Update task statuses as implementation progresses: `Pending`, `Partially Done`, or `Done`. Mark a task Done only when its acceptance condition is met.

## Scope

### Included

- Catalogue cards showing image, name, price, rating, and favourite action.
- Pages of 20, automatic loading near the bottom, and duplicate prevention.
- Debounced product search with protection against stale responses and paginated results.
- Product details with images, description, price, stock, and favourite action.
- Loading, empty, offline/error, retry, and pull-to-refresh behaviour.
- Persistent last-loaded list, shared favourites, Wishlist, and five recent searches.
- Android release build, source packaging, and required README.

### Excluded

- Login, checkout, cart, payments, custom backend, and server-side favourites.
- iOS delivery, extra catalogue filters, and loyalty features from the reference app.
- A separate test plan or new test code; acceptance conditions below guide implementation verification.

### Constraints

- Work in `shoply-flutter/`. Treat `../emart24-loyalty-codex/` as a read-only structural reference; it is a junction to another project.
- Read applicable AGENTS.md files before editing each target area. The reference project's local rules apply within that reference project; borrowing its folder layout does not automatically impose those rules on Shoply.
- Keep network, persistence, and business logic out of widgets. Use typed models and snake_case filenames.
- Use the free API without authentication. Do not copy reference credentials, assets, branding, Firebase setup, or unrelated dependencies.
- Keep the app small: choose dependency versions compatible with the installed Flutter SDK during implementation and commit `pubspec.lock`.

## Architecture and Reference Mapping

Follow the reference app's layer-oriented layout rather than adding a separate feature-folder architecture. Its existing `root_app.dart`, `app_router.dart`, `core/api`, `repositories`, `screens`, `utils`, and `widgets` provide the structural pattern. Following the user's refinement, Shoply uses `controllers` for ChangeNotifier state and `_repo.dart` / `Repo` names for repositories.

Proposed target layout (create only folders actually needed):

```text
shoply-flutter/
  android/
  lib/
    main.dart                         # Initialise storage and start app
    root_app.dart                     # Theme and app-scoped controllers
    app_router.dart                   # Catalogue, details, Wishlist routes
    constants/
      enums.dart                      # Shared loading/status enums if needed
      dimensions.dart
    core/
      api/
        core_api_const.dart           # DummyJSON base URL and endpoints
        core_api_request.dart         # Dio client, timeouts, cancellation
        core_api_response.dart        # Typed success envelopes
        core_api_error_resolver.dart  # Transport/model error mapping
        exceptions/                   # Base exception, request error, cancellation
      models/
        product_model.dart
        product_model.g.dart
        product_page_model.dart       # products, total, skip, limit
        product_page_model.g.dart
        catalogue_cache_model.dart    # Query, products, offset, total, time
        catalogue_cache_model.g.dart
    repositories/
      base_repo.dart                  # Network client ownership and disposal
      product_repo.dart               # List, search, details
      local_storage_repo.dart         # Cache, favourites, recent searches
    controllers/
      catalogue_controller.dart         # Query, pagination, refresh, cache
      product_detail_controller.dart    # Detail request lifecycle
      favourites_controller.dart        # Single shared favourites source
      recent_searches_controller.dart   # Ordered persistent history
    screens/
      product_list_screen.dart
      product_detail_screen.dart
      wishlist_screen.dart
    widgets/
      product_card.dart
      favourite_button.dart
      product_search_bar.dart
      recent_searches_panel.dart
      error_retry_view.dart
      empty_state_view.dart
      pagination_footer.dart
    utils/
      app_theme_config.dart
      debounce.dart
  README.md
  PLAN.md
  pubspec.yaml
  pubspec.lock
```

**State management:** Provider with ChangeNotifier controllers. `FavouritesController` lives in `lib/controllers/favourites_controller.dart` and is registered once in RootApp using ChangeNotifierProvider. Renaming it does not introduce GetX. This matches the reference app's Provider-based composition and gives all routes the same favourites instance. Use focused consumers/selectors so favourite changes rebuild only relevant widgets. Catalogue and detail request state remain separate; widget-only state can use ValueNotifier. Do not combine Provider and GetX.

**Repository/core pattern:** `ProductRepo extends BaseRepo`, which creates and owns its CoreApiRequest by default and disposes it through `dispose()`. A supplied client remains owned by its caller. Controllers create their repositories; repositories and CoreApiRequest are not registered as UI Providers in RootApp. LocalStorageRepo performs local persistence only and does not inherit a network client. CoreApiRequest exposes `requestAsync(url: ..., queryParameters: ..., cancelToken: ...)`, returning a CoreApiResponse of the raw JSON object. ProductRepo returns `CoreApiResponse<ProductPageModel>` / `CoreApiResponse<ProductModel>`. Future catalogue/detail controllers must read `response.data` and dispose owned network repositories. CoreApiErrorResolver maps failures; cancellation remains a separate control-flow exception. DummyJSON uses unauthenticated GET requests, so the reference project's credential, POST-envelope, and environment integrations are not copied.

**Model generation:** ProductModel, ProductPageModel, and CatalogueCacheModel use `@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)` and generated `.g.dart` files. Following the user's refinement, every fromJson factory delegates directly to its generated function; do not add manual product or page validation to these factories. The cache additionally serializes dates in UTC and uses `@JsonKey(name: 'savedAt')` to preserve the existing storage format. LocalStorageRepo owns cache schema/pagination integrity checks. Generated type-conversion failures are mapped by the API/storage layers. JSON maps use the generator's standard `Map<String, dynamic>` signatures; models and repository responses remain typed. After model changes, run `C:/fvm/versions/3.44.0/bin/cache/dart-sdk/bin/dart.exe run build_runner build` from the project directory. Do not hand-edit generated files. See the [json_serializable documentation](https://pub.dev/packages/json_serializable).

**Routing practice:** Follow the reference's AppRouter.appRouter(), static AppRouter.home/wishlist/productDetail constants, GoRoute.pageBuilder returning MaterialPage<void> with state.pageKey, and errorPageBuilder returning ErrorScreen with ErrorScreenArguments. Product details use `/product_detail/:id`, ProductDetailScreenArguments supplied through state.extra, and an ID-based fallback for direct links. Navigation calls use GoRouter.of(context). RootApp wires routeInformationParser, routerDelegate, and routeInformationProvider from its single `_appRouter`. MainScreen owns a ValueNotifier tab index; an IndexedStack preserves catalogue/Wishlist widget state without a StatefulShellRoute. The tab-hosted Wishlist returns to Catalogue using its supplied callback, while the standalone Wishlist route can navigate home.

**Installed dependencies:** `provider` 6.1.5+1 for state, `dio` 5.11.1 for HTTP and cancellation, `shared_preferences` 2.5.6 for small JSON snapshots, `go_router` 18.1.4 for central routes, and `cached_network_image` 4.0.3 for best-effort image caching. Model generation adds `json_annotation` 4.12.0 and development dependencies `json_serializable` 6.15.2 / `build_runner` 2.15.1. Resolved versions are recorded in `pubspec.lock`. Full guaranteed offline image downloads are outside scope; uncached images show placeholders. SharedPreferencesAsync avoids stale in-memory preference caches. SharedPreferences is suitable for this small exercise; a database would be an improvement as data grows.

## API and Behaviour Contract

Source: [DummyJSON products documentation](https://dummyjson.com/docs/products), reviewed 10 November 2026.

- Browse: `GET /products?limit=20&skip={offset}`.
- Search: `GET /products/search?q={encodedQuery}&limit=20&skip={offset}`.
- Details: `GET /products/{id}`.
- Parse `products`, `total`, `skip`, and `limit`; map API `title` to the displayed product name. Do not hardcode the total catalogue size. Build query parameters through the HTTP client.
- Search uses DummyJSON's documented search behaviour. It is not documented as strictly title-only; verify behaviour during implementation and record the limitation if matches include other fields. Do not simply filter each server page by title and claim correct search totals.
- Trim queries; an empty query restores the ordinary catalogue. Debounce for approximately 350 ms.
- On every text edit, immediately invalidate the current request generation, cancel old work, and prevent old-query pagination during debounce. Start the new request after the delay. Accept success, error, and finally/loading updates only if their generation still matches. Cancellation alone is insufficient.
- Each generation owns its query, items, offset, total, loading flags, and errors. Refresh also starts a new generation. Allow one page request at a time for that generation.
- Deduplicate appended products by ID while preserving server order. Advance the offset by the number of server records consumed, not the unique displayed count. Stop when the offset reaches total or the server returns no records; suppress repeated bottom triggers.
- A failed append keeps existing items and the same offset for retry. A failed refresh keeps existing items. A successful refresh replaces the list with page one, then resumes pagination.
- Persist the most recent successfully displayed list snapshot, including its query, loaded products, consumed offset, total, timestamp, and schema version. Successful empty results are valid snapshots. Restore the matching search field and list together on startup, then attempt an online refresh. Keep the cached list with an offline/stale notice if refresh fails. Do not overwrite good cache with a network error.
- While viewing a cached list after failed refresh, offer retry and avoid mixing old cached pages with newly fetched pages until page one refresh succeeds. Offline scrolling must not repeatedly issue failing requests.
- Store full favourite product snapshots keyed by ID so Wishlist works without fetching each product again. All favourite buttons derive their selected state from one app-scoped provider, never a copied boolean.
- Load persisted favourites before enabling toggles. Update shared state immediately, serialize writes to preserve the latest toggle, and surface storage failures with a recoverable state. Apply equivalent write ordering to history and cache; storage failure must not masquerade as network failure.
- History is recorded for non-empty queries when their current search is dispatched after debounce, or when submitted/tapped. Deduplicate using trimmed case-insensitive keys, retain the latest display spelling, move repeated searches to the front, and keep five. Never save individual keystrokes or refresh/page requests as new history.
- Show history below the focused search bar, with tap-to-search and clear-all actions. Clearing history must also clear persisted storage without a delayed write restoring it.

## Prerequisites

- [x] **Done - Inspect starter and reference structure.** Result: Shoply has the starter `lib/main.dart`; the reference uses layer-oriented API/repository/provider/screen/widget folders and central routing.
- [x] **Done - Confirm documented API contract.** Result: Product, search, detail, and limit/skip endpoints are documented at the source above. Strict title-only search is not guaranteed by the documentation.
- [x] **Done - Confirm Android toolchain.** Result: Flutter 3.44.0 / Dart 3.12.0 at `C:/fvm/versions/3.44.0`, Android SDK 36.1.0, Android Studio JDK 21, accepted Android licences, and a connected Android 16 device were reported by `flutter doctor -v` / `flutter devices`. Flutter is not on PATH and the system Dart differs; use the Flutter SDK's explicit executable path for commands.
- [x] **Done - Resolve dependencies and build configuration.** Result: Dependencies resolve and the Android debug build succeeds. Main manifest includes INTERNET permission. App label is Shoply, ID remains `com.example.shoply_flutter`, version is `1.0.0+1`; existing Gradle configuration uses debug-key signing even for release. Suitable for development/installable assignment builds; production signing remains a delivery consideration in Part 5.

## Part 1 - App Foundation and Data Layers

- [x] **Done - Replace demo composition with Shoply shell.** Result: `RootApp` owns the router and app-scoped FavouritesController; repositories and the API client are owned outside UI Provider registration. Following the routing refinement, MainScreen retains tabs using ValueNotifier/IndexedStack; catalogue has a PageStorageKey for its eventual scroll position. The original preview confirmed Catalogue -> Wishlist -> Browse products and the previous `/products/1` route; the current product route is `/product_detail/:id`. Invalid IDs have a fallback route. Product content remains a placeholder until later parts. Preserved the existing guarded entry point and replaced its silent error handler with Flutter error reporting; removed the obsolete generated counter test that referenced the deleted demo app.
- [ ] **Partially Done - Add typed API models and repository.** Result: Immutable product/page/cache models use generated JSON parsing and preserve numeric prices/ratings. Repository supports browse/search pages of 20 and detail by ID, with HTTP timeouts, cancellation separated from user-facing failures, and encoded query parameters. Static analysis and Android compilation pass. Remaining: Exercise live browse/search/detail requests and failure/cancellation behaviour when the UI is connected in Parts 2-4.
- [ ] **Partially Done - Add persistence repository.** Result: SharedPreferencesAsync stores versioned independent cache/favourites/history JSON; malformed data returns safe defaults. Writes capture snapshots and run in order, a failed write does not poison later writes, and history normalization limits entries to five without case-insensitive duplicates. Favourites hydrate through one app-scoped provider with retry and disposal protection. Remaining: Verify actual saved snapshots survive Android process restart and exercise corrupt-data/write-failure recovery after feature writes are connected in Parts 2-4.
- [x] **Done - Add shared visual foundations.** Result: Shared theme/dimensions, product card, square cached image with fallback, USD price formatter, labelled 48-pixel favourite controls, and loading/empty/retry widgets compile and pass analysis. Empty screens and navigation were visually inspected in the local preview. Interactive favourite wiring belongs to Part 4.
- [x] **Done - Align repository, controller, core, and model conventions with the reference.** Result: Renamed repositories to ProductRepo / LocalStorageRepo in `_repo.dart` files, moved FavouritesController into `controllers`, and added BaseRepo, CoreApiResponse, CoreApiErrorResolver, and typed exceptions. RootApp registers the shared controller only. ProductRepo extends BaseRepo and returns typed CoreApiResponse envelopes; it retains 20-item GET pagination and cancellation support. All three models use generated JsonSerializable codecs. The initial alignment preserved custom factory validation; the user's subsequent refinement removes those factory checks and keeps cache-specific integrity checks in LocalStorageRepo. `build_runner build` generated three `.g.dart` files, `flutter analyze` reports no issues, and the updated Android debug APK builds successfully. The reference project was not modified.
- [x] **Done - Apply direct model factories and reference routing practice.** Result: All fromJson factories delegate directly to generated codecs; annotations use FieldRename.snake and explicitToJson. RootApp and AppRouter follow the reference's router construction, MaterialPage builders, route constants, explicit router delegates, and screen argument classes. MainScreen owns tab state with ValueNotifier/IndexedStack. Generation, static analysis, and the Android debug build succeed. Preview confirmed tab switching, Browse products, `/product_detail/1`, back/home navigation, invalid-ID fallback, and the standalone `/wishlist` route returning home. No application feature scope beyond the requested model/routing refinements was added.

## Part 2 - Catalogue and Pagination

- [ ] **Pending - Load and display the first 20 products.** Acceptance: Every card shows image, name, price, rating, and favourite button; initial loading and initial error with retry are visible.
- [ ] **Pending - Add guarded infinite scroll.** Acceptance: Bottom scrolling requests the next offset once, appends without duplicate IDs, shows an append spinner/error retry, and stops cleanly at exhaustion.
- [ ] **Pending - Add refresh and offline restoration.** Acceptance: Pull-to-refresh works on short and empty lists, refresh invalidates older work, and an offline cold launch restores the last successful list. With no cache, show a clear error and retry action.

## Part 3 - Search and Recent Searches

- [ ] **Pending - Implement debounced search lifecycle.** Acceptance: Fast typing, clearing, switching queries, and refresh cannot display stale results or stale errors; paginated search uses the active query and resets offsets on change.
- [ ] **Pending - Add recent search persistence and panel.** Acceptance: Focus shows up to five recent entries newest first; duplicate queries move to the top; tap reruns a query; clear persists; closing and reopening preserves history.
- [ ] **Pending - Complete search empty and failure states.** Acceptance: No matches show an empty state, failures show retry, and results from another query are never presented as matches for the current query.

## Part 4 - Details and Shared Wishlist

- [ ] **Pending - Build product detail screen.** Acceptance: A tapped product shows its image gallery, description, formatted price, stock, and favourite action. Existing snapshots can render immediately; detail fetch failure offers retry without hiding usable data.
- [ ] **Pending - Implement persistent shared favourites.** Acceptance: Toggling on catalogue, details, or Wishlist updates every screen immediately, repeated rapid toggles persist the final state, and restarting restores favourites.
- [ ] **Partially Done - Build Wishlist screen.** Result: Part 1 supplies the routed screen, persisted-snapshot rendering, loading/error/retry/empty views, and product navigation. Remaining: Wire favourite removal and verify cross-screen updates/offline behaviour in Part 4. Full acceptance remains: All stored favourite products appear, can open details, remain available offline, and disappear immediately when removed; the last removal shows an empty Wishlist state.

## Part 5 - README and Android Submission

- [ ] **Pending - Write project README.** Acceptance: Include prerequisites, exact setup/run/build commands, Provider choice and reasoning, architecture overview, offline/search behaviour, actual AI-generated portions and human changes, and one honest weakness or future improvement. Do not invent human edits or verification results.
- [ ] **Pending - Complete release verification.** Acceptance: Formatting/static analysis and Android release build succeed; required app behaviours have been exercised on Android, including offline restart, pagination exhaustion, stale-search protection, and cross-screen persistence. Record actual results and any unavailable checks here; no separate test plan is required.
- [ ] **Pending - Produce submission artefacts.** Acceptance: Build with `flutter build apk --release`, install and open the resulting `build/app/outputs/flutter-apk/app-release.apk`, and provide an explicitly named APK plus a source ZIP containing README, lockfile, platform source, and this plan. Exclude build caches, local paths/configuration, signing secrets, and the reference-project junction. A verified accessible GitHub repository may replace the source ZIP.

## Completion / Exit Criteria

- [ ] **Pending - Meet all functional requirements.** Acceptance: Catalogue, search, detail, refresh/error handling, cached startup, favourites/Wishlist, and recent searches behave as specified above.
- [ ] **Pending - Complete the handoff.** Acceptance: APK and source ZIP or repository link are available, README includes all required disclosures, all implementation tasks are Done, and any limitations or unavailable verification are explicitly recorded without claiming unsupported success.

## Current Handoff

Part 1 implementation is in place; API and storage runtime acceptance is explicitly Partially Done until connected feature flows can exercise it. Parts 2-5 remain outstanding, apart from the Wishlist foundation noted above. Catalogue/detail screens currently show intentional placeholders; the app does not yet fetch or search products, toggle favourites, or display history. The reference project was not modified. No known implementation blocker remains.

Verification on 10 November 2026:

- `dart format lib`: Original Part 1 contained 26 files; the naming/core/model refinement formats 36 files including generated outputs. Final formatting pass reported no changes.
- `flutter analyze`: No issues found.
- `flutter build apk --debug`: Succeeded; `build/app/outputs/flutter-apk/app-debug.apk` is a development artefact, not the final submission APK.
- Local web preview: Catalogue/Wishlist switching, browse action, `/products/1`, and back navigation rendered successfully. Preview screenshot: `build/verification/part1-shell.png` (ignored build output).
- Android device installation/runtime interaction, populated list scroll restoration, live API calls, and persisted-write/restart scenarios have not been verified. No new test code or separate test plan was created.
- Dependency installation regenerated desktop plugin registration files; these are expected Flutter-generated changes, not extra desktop feature work.
- Naming/core/model refinement: Installed json_annotation 4.12.0, json_serializable 6.15.2, and build_runner 2.15.1. Generated files were produced by build_runner, not edited by hand. The cache schema version and existing storage keys are unchanged. Generator validation errors are handled as invalid API data or corrupt local snapshots, while cancellation is preserved. The fresh debug build succeeds and final static analysis has no issues; live API and Android restart scenarios remain pending as stated above.
- Direct-factory/routing refinement: Regenerated all three model parts without checked decoding or handwritten factory validation. Cache version/pagination validation now belongs to LocalStorageRepo. Analysis has no issues and the Android debug APK builds. Verified current route/tab navigation in the web preview; screenshot: `build/verification/router-practice.png`. The web development tooling emitted an injected `client.js` deserialization warning; application rendering and the navigation checks still succeeded. This does not verify Android runtime behaviour or live-data feature flows, which remain pending in Parts 2-4.

Next implementation step: Part 2, using ProductRepo and LocalStorageRepo for the initial 20 products, guarded pagination, refresh, and cache restoration. Keep Part 1 API/storage statuses synchronized as runtime evidence becomes available.
