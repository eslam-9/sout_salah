# Developer Quickstart: UI and Network Optimization

## 1. Network Timeouts

All HTTP requests across the application must strictly adhere to the unified timeout constraints.
To enforce this, we have extracted timeouts into base configurations.

- **Audio Transfer (Upload / Download)**
  - Timeout: `120 seconds`
  - Implementation requirement: Pass the `Options(connectTimeout: ..., receiveTimeout: ...)` overrides down explicitly for large media files in `R2StorageService` and `DownloadsService`.

- **Standard API Requests**
  - Timeout: `10 seconds`
  - Implementation requirement: Ensure the base `Dio` instance injected via Riverpod operates on this shorter, snappier timeout globally by default, unless explicitly overridden.

## 2. Widget Modularity Rules (Strict 70-Line Limit)

Any file living under `features/*/presentation/widgets/` must NOT exceed 70 lines.
To obey this constraint:
1. Extract repeating elements into their own stateless widgets tightly scoped to their parent module.
2. Separate business logic from UI using Riverpod consumer combinations.
3. Group related micro-widgets logically into folders rather than monolithic mega-widgets.
4. If a widget nears 60 lines, immediately begin isolating its constituent children.
