# Shoply Product Catalogue Implementation Plan

## Objective

Build a small Flutter Android catalogue using DummyJSON, with reliable paginated search, offline list recovery, persistent favourites, and recent searches. Deliver an installable APK and a source ZIP with a complete README (or a GitHub repository link).

This document is an implementation handoff. All feature implementation is in place, including the user-directed compact light-green two-column grid, expandable search, Hero transitions, and simplified detail favourite action. The final Android APK and source ZIP are ready; verification and coverage limits are recorded below. Update task statuses as implementation progresses: `Pending`, `Partially Done`, or `Done`. Mark a task Done only when its acceptance condition is met.

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
- Use full `package:shoply_flutter/...` URIs for internal imports and exports. Relative imports are prevented by the `always_use_package_imports` analyzer rule. Keep generated `part` / `part of` directives relative.
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

**Repository/core pattern:** `ProductRepo extends BaseRepo`, which creates and owns its CoreApiRequest by default and disposes it through `dispose()`. A supplied client remains owned by its caller. Controllers create their repositories; repositories and CoreApiRequest are not registered as UI Providers in RootApp. LocalStorageRepo performs local persistence only and does not inherit a network client. CoreApiRequest exposes `requestAsync(url: ..., queryParameters: ..., cancelToken: ...)`, returning a CoreApiResponse of the raw JSON object. ProductRepo returns `CoreApiResponse<ProductPageModel>` / `CoreApiResponse<ProductModel>`. Catalogue/detail controllers read `response.data` and dispose their owned network repositories. CoreApiErrorResolver maps failures; cancellation remains a separate control-flow exception. DummyJSON uses unauthenticated GET requests, so the reference project's credential, POST-envelope, and environment integrations are not copied.

**Model generation:** ProductModel, ProductPageModel, and CatalogueCacheModel use `@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)` and generated `.g.dart` files. Following the user's refinement, every fromJson factory delegates directly to its generated function; do not add manual product or page validation to these factories. The cache additionally serializes dates in UTC and uses `@JsonKey(name: 'savedAt')` to preserve the existing storage format. LocalStorageRepo owns cache schema/pagination integrity checks. Generated type-conversion failures are mapped by the API/storage layers. JSON maps use the generator's standard `Map<String, dynamic>` signatures; models and repository responses remain typed. After model changes, run `C:/fvm/versions/3.44.0/bin/cache/dart-sdk/bin/dart.exe run build_runner build` from the project directory. Do not hand-edit generated files. See the [json_serializable documentation](https://pub.dev/packages/json_serializable).

**Routing practice:** Follow the reference's AppRouter.appRouter(), static AppRouter.home/wishlist/productDetail constants, GoRoute.pageBuilder returning MaterialPage<void> with state.pageKey, and errorPageBuilder returning ErrorScreen with ErrorScreenArguments. Product details use `/product_detail/:id`, ProductDetailScreenArguments supplied through state.extra, and an ID-based fallback for direct links. Navigation calls use GoRouter.of(context). RootApp wires routeInformationParser, routerDelegate, and routeInformationProvider from its single `_appRouter`. MainScreen owns a ValueNotifier tab index; an IndexedStack preserves catalogue/Wishlist widget state without a StatefulShellRoute. The tab-hosted Wishlist returns to Catalogue using its supplied callback, while the standalone Wishlist route can navigate home.

**Installed dependencies:** `provider` 6.1.5+1 for state, `dio` 5.11.1 for HTTP and cancellation, `shared_preferences` 2.5.6 for small JSON snapshots, `go_router` 18.1.4 for central routes, and `cached_network_image` 4.0.3 for best-effort image caching. Model generation adds `json_annotation` 4.12.0 and development dependencies `json_serializable` 6.15.2 / `build_runner` 2.15.1. Resolved versions are recorded in `pubspec.lock`. Full guaranteed offline image downloads are outside scope; uncached images show placeholders. SharedPreferencesAsync avoids stale in-memory preference caches. SharedPreferences is suitable for this small exercise; a database would be an improvement as data grows.

## API and Behaviour Contract

Source: [DummyJSON products documentation](https://dummyjson.com/docs/products), reviewed 10 November 2026.

- Browse: `GET /products?limit=20&skip={offset}`.
- Search: `GET /products/search?q={encodedQuery}&limit=20&skip={offset}`.
- Details: `GET /products/{id}`.
- Parse `products`, `total`, `skip`, and `limit`; map API `title` to the displayed product name. Do not hardcode the total catalogue size. Build query parameters through the HTTP client.
- Search uses DummyJSON search pages plus case-insensitive title filtering. Continue consuming server pages until a batch of up to 20 title matches is ready or the server is exhausted; retain surplus matches for the next scroll. Advance offsets by server records consumed. Report loaded matching products rather than an incorrect server-provided name-match total.
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

- [x] **Done - Replace demo composition with Shoply shell.** Result: `RootApp` owns the router and app-scoped FavouritesController; repositories and the API client are owned outside UI Provider registration. Following the routing refinement, MainScreen retains tabs using ValueNotifier/IndexedStack; catalogue has a PageStorageKey for its eventual scroll position. The original preview confirmed Catalogue -> Wishlist -> Browse products and the previous `/products/1` route; the current product route is `/product_detail/:id`. Invalid IDs have a fallback route. Product content was initially a placeholder and is now implemented in Part 4. Preserved the existing guarded entry point and replaced its silent error handler with Flutter error reporting; removed the obsolete generated counter test that referenced the deleted demo app.
- [x] **Done - Add typed API models and repository.** Result: Generated typed models and CoreApiResponse repositories were exercised by live browse, title search, and detail flows. Browse/search pagination, connection-error mapping, generation/cancellation guards, and native release startup are implemented and verified through compilation, source inspection, preview flows, and the installed Android app.
- [x] **Done - Add persistence repository.** Result: Versioned independent snapshots, ordered immutable writes, safe corrupt-data defaults, and recoverable storage errors are implemented. Preview confirmed favourite/history persistence, clear-history persistence, and the final result of rapid toggles after reload. The user confirmed saved products remained after an Android offline close/reopen. Corrupt-store and disk-write-failure injection were source-reviewed rather than deliberately triggered.
- [x] **Done - Add shared visual foundations.** Result: Shared theme/dimensions, product card, square cached image with fallback, USD price formatter, labelled 48-pixel favourite controls, and loading/empty/retry widgets compile and pass analysis. Empty screens and navigation were visually inspected in the local preview. Interactive favourite wiring is complete in Part 4.
- [x] **Done - Align repository, controller, core, and model conventions with the reference.** Result: Renamed repositories to ProductRepo / LocalStorageRepo in `_repo.dart` files, moved FavouritesController into `controllers`, and added BaseRepo, CoreApiResponse, CoreApiErrorResolver, and typed exceptions. RootApp registers the shared controller only. ProductRepo extends BaseRepo and returns typed CoreApiResponse envelopes; it retains 20-item GET pagination and cancellation support. All three models use generated JsonSerializable codecs. The initial alignment preserved custom factory validation; the user's subsequent refinement removes those factory checks and keeps cache-specific integrity checks in LocalStorageRepo. `build_runner build` generated three `.g.dart` files, `flutter analyze` reports no issues, and the updated Android debug APK builds successfully. The reference project was not modified.
- [x] **Done - Apply direct model factories and reference routing practice.** Result: All fromJson factories delegate directly to generated codecs; annotations use FieldRename.snake and explicitToJson. RootApp and AppRouter follow the reference's router construction, MaterialPage builders, route constants, explicit router delegates, and screen argument classes. MainScreen owns tab state with ValueNotifier/IndexedStack. Generation, static analysis, and the Android debug build succeed. Preview confirmed tab switching, Browse products, `/product_detail/1`, back/home navigation, invalid-ID fallback, and the standalone `/wishlist` route returning home. No application feature scope beyond the requested model/routing refinements was added.

## Part 2 - Catalogue and Pagination

- [x] **Done - Load and display the first 20 products.** Result: Screen-owned CatalogueController calls ProductRepo and renders responsive product cards with image/name/price/rating and a favourite control. Live preview showed 20 of 194 products with loaded images and numeric prices/ratings. Initial loading and no-cache connection-error/retry states were observed. Favourite actions are now wired through the shared controller in Part 4. Static analysis and the Android debug build pass.
- [x] **Done - Add guarded infinite scroll.** Result: Live scrolling advanced through the catalogue to 194 of 194 unique products and displayed the end-of-list message. One in-flight page per generation, ID deduplication, server-record offsets, viewport autofill, and append-error retry are implemented; error states gate automatic retry. Refresh cancels and invalidates older requests. Refreshing after pagination replaced the data with the first 20 items. Append-error retry and superseded-response protection were source-reviewed; a dedicated delayed/failed-page scenario has not been exercised on Android.
- [x] **Done - Add refresh and offline restoration.** Result: Pull-to-refresh retains data on failure, cache restores the matching list and query before networking, and pagination pauses while stale data requires refresh. Earlier API-unavailable preview checks restored all 194 saved products and showed the no-cache retry state on a fresh origin. The user confirmed pull-to-refresh and saved-list recovery after reopening the final Android app with connectivity off. The final toolbar has no refresh button, per the user request.

## Part 3 - Search and Recent Searches

- [x] **Done - Implement debounced search lifecycle.** Result: Expandable top-bar search uses a 350 ms debounce, immediate generation invalidation/cancellation on edits, and stale success/error/finally guards. Live checks covered fast lip/app/apple edits and title filtering (phone returned eight name matches). Search pagination advanced from 20 to 40 loaded matches for a. Server offsets and buffered title matches preserve complete pagination without using broader server totals as exact name counts.
- [x] **Done - Add recent search persistence and panel.** Result: Focused search displays five newest entries, case-insensitive repeats move to the top, and tapping an entry reruns it. Preview exercised six submitted queries, confirmed the five-entry limit and phone moving above apple, then verified Clear all remained cleared after reload. History also survived an earlier reload. Revision guards prevent delayed writes from restoring cleared entries.
- [x] **Done - Complete search empty and failure states.** Result: A deliberately unmatched query displayed zero matches and the empty-results view. A new edit invalidates old requests immediately but keeps settled content visible during the debounce; the search/loading view starts only on dispatch. Errors have Retry, and the existing cache/error/generation guards apply to searches. Cache restores both query text and its displayed results before refreshing.

## Part 4 - Details and Shared Wishlist

- [x] **Done - Build product detail screen.** Result: Live product details display the image gallery, title, description, numeric price, rating, and stock. The Apple detail showed its image, description, price, and eight in stock. Route arguments carry snapshots; direct links fall back to saved catalogue/favourite data before fetching. Retry and refresh retain useful data on failure. Final user refinements add a Hero image transition and one shared top-right image-corner favourite action in both cards and details.
- [x] **Done - Implement persistent shared favourites.** Result: One app-scoped controller backs all three screens, updates optimistically, and queues immutable snapshots for persistence. Preview verified catalogue-to-detail selection, detail removal emptying Wishlist, Wishlist removal updating the underlying detail, and selection surviving reload. Writes are revision-guarded and save errors offer Retry.
- [x] **Done - Build Wishlist screen.** Result: Wishlist displays full persisted snapshots in the shared two-column grid and opens details. Removal updates every screen immediately; removing the final item displays the empty Wishlist state. Saved content does not require a network fetch.

## Part 5 - README and Android Submission

- [x] **Done - Write project README.** Result: README contains prerequisites, exact run/build/generation commands, state management and architecture reasoning, feature/cache/search semantics, signing notes, AI assistance and user-directed changes, and a concrete known weakness/improvement.
- [x] **Done - Complete release verification.** Result: Final formatting and flutter analyze pass with no issues. The universal release APK builds, its APK v2 signature verifies, and its manifest reports Shoply 1.0.0, minimum API 24, target API 36, INTERNET permission, and arm64-v8a/armeabi-v7a/x86_64 support. It was installed and launched on Android 16; native screenshots confirmed the two-column layout and final detail view. The user confirmed native pull-to-refresh and offline reopening. Preview checks covered catalogue exhaustion, debounced title search, search pagination, history, cross-screen favourites, persistence, and Hero navigation. No new test code or separate test plan was created.
- [x] **Done - Produce submission artefacts.** Result: deliverables/Shoply-1.0.0.apk contains the signature-verified, installed release build. deliverables/Shoply-source.zip contains 177 source entries, including README, lockfile, generated models, Android platform source, Gradle wrapper and this plan. Build caches, local configuration, signing secrets and the reference junction are excluded. SHA256SUMS.txt accompanies both files.

## Completion / Exit Criteria

- [x] **Done - Meet all functional requirements.** Result: All requested feature flows are implemented, with the verification and coverage limits recorded below.
- [x] **Done - Complete the handoff.** Result: Named APK and source ZIP are available in deliverables. README includes all required disclosures, all implementation tasks are Done, and verification limits are explicitly recorded.

## Current Handoff

All feature implementation and the final user-directed UX changes are complete. The release APK has been built, signature-verified, installed, and launched on the connected Android device. Functional preview checks passed, and the user confirmed Android pull-to-refresh and offline reopening. The named APK and source ZIP are packaged and verified in deliverables. The reference project was not modified.

Historical Part 1 verification on 10 November 2026 (pending coverage statements below are superseded by the final verification section):

- `dart format lib`: Original Part 1 contained 26 files; the naming/core/model refinement formats 36 files including generated outputs. Final formatting pass reported no changes.
- `flutter analyze`: No issues found.
- `flutter build apk --debug`: Succeeded; `build/app/outputs/flutter-apk/app-debug.apk` is a development artefact, not the final submission APK.
- Local web preview: Catalogue/Wishlist switching, browse action, `/products/1`, and back navigation rendered successfully. Preview screenshot: `build/verification/part1-shell.png` (ignored build output).
- Android device installation/runtime interaction, populated list scroll restoration, live API calls, and persisted-write/restart scenarios have not been verified. No new test code or separate test plan was created.
- Dependency installation regenerated desktop plugin registration files; these are expected Flutter-generated changes, not extra desktop feature work.
- Naming/core/model refinement: Installed json_annotation 4.12.0, json_serializable 6.15.2, and build_runner 2.15.1. Generated files were produced by build_runner, not edited by hand. The cache schema version and existing storage keys are unchanged. Generator validation errors are handled as invalid API data or corrupt local snapshots, while cancellation is preserved. The fresh debug build succeeds and final static analysis has no issues; live API and Android restart scenarios remain pending as stated above.
- Direct-factory/routing refinement: Regenerated all three model parts without checked decoding or handwritten factory validation. Cache version/pagination validation now belongs to LocalStorageRepo. Analysis has no issues and the Android debug APK builds. Verified current route/tab navigation in the web preview; screenshot: `build/verification/router-practice.png`. The web development tooling emitted an injected `client.js` deserialization warning; application rendering and the navigation checks still succeeded. This does not verify Android runtime behaviour or live-data feature flows, which remain pending in Parts 2-4.

Historical Part 2 verification on 10 November 2026 (later UI changes and native checks are recorded in the final section):

- `flutter analyze`: No issues found. Formatting verification reports no changes in the four new/updated catalogue files.
- `flutter build apk --debug`: Succeeded with the normal DummyJSON API address. The temporary failure-simulation configuration was restored exactly; CoreApiConst has no remaining content diff.
- Profile web preview: Initial 20 products, pagination to all 194 products, unique displayed count matching the server total, clean exhaustion, toolbar refresh resetting to page one, product-card routing with typed arguments, and retained scroll position across Catalogue/Wishlist tab switching were observed.
- Cache/recovery: Temporarily pointed the existing API constant to an unreachable local address, rebuilt the preview at the same origin, and reloaded. All 194 saved products were restored with a connection-error banner and Retry. A fresh `localhost` origin without saved data showed the initial error screen; Retry returned cleanly to the same error while the API remained unavailable. Restored `https://dummyjson.com`, rebuilt the preview, and observed successful online loading/refresh. This simulates API unavailability; it does not claim a native Android offline-process-restart check.
- Screenshots in ignored build output: `build/verification/catalogue-part2.png`, `catalogue-end.png`, `catalogue-saved-list.png`, and `catalogue-no-cache.png`.
- The browser viewport override did not change the reported 1280x720 viewport and was reset; a phone-sized runtime layout check is not claimed. Native browser access was unavailable, so no desktop connection settings were changed. Android installation/touch gestures, storage write failure, corrupt-cache recovery, and a deliberately failing/delayed append still require runtime coverage. No new test code or separate test plan was created.

Handoff ready: deliver the named APK and source ZIP from deliverables; no required implementation work remains.


## Final Implementation and Verification - 10 November 2026

- All requested features are implemented. Final UX: exactly two compact light-green cards per row; one shared top-right image heart on cards/details; Hero image navigation with inactive-tab HeroMode; expandable search; no toolbar refresh icon; opening/cancelling unused search preserves data and scroll; settled results remain visible during debounce and the search/loading view starts on dispatch.
- Search uses 350 ms debounce and immediate cancellation/generation invalidation, with pending and committed queries separated. Preview observed 40 browse products remaining while apple was typed, followed by nine apple title matches after dispatch. Phone matched eight product names. Search a paginated from 20 to 40 matching products.
- Recent-search checks exercised six queries, the five-entry cap, deduplication/reordering, tapping an entry, persistence, and clearing across reload. Favourites were added/removed from all three screens; rapid toggles preserved the final selected state after reload. Details showed images, price, rating, stock, and description.
- Final release build and APK signature verification pass. The final APK was installed/launched on Android 16. Actual phone screenshots confirmed the grid and the Soft Drinks detail screen with a single image-corner heart. The user explicitly reported that native pull-to-refresh and offline reopening work.
- Latest preview console had no errors/warnings during the checked flows. Hero navigation was checked from Catalogue and Wishlist without duplicate-tag errors. Full package imports are enforced by analysis options. Generated model files are included and were not hand-edited.
- Non-blocking coverage limits: no deliberately corrupted storage or disk-write-failure injection, no exhaustive artificial network timing permutations, and no iOS verification. Browser and native evidence are distinguished above; these are coverage limits, not known broken functionality. No new test code or separate test plan was created.
- Evidence files are under ignored build/verification output, including shoply-final-catalogue.png and shoply-final-android.png. Submission files: deliverables/Shoply-1.0.0.apk and deliverables/Shoply-source.zip (177 entries), accompanied by SHA256SUMS.txt.
