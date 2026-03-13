# Implementation Plan: UI and Network Optimization

**Branch**: `001-ui-network-optimization` | **Date**: 2026-03-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-ui-network-optimization/spec.md`

## Summary

The feature enforces a highly strict, production-level modular widget standard across the Sout Salah app, enforcing a hard 70-line limit per file for all complex UI screens. Furthermore, networking layers heavily utilizing `dio` will separate configuration defaults—applying a highly forgiving 120-second timeout to audio operations (upload/download), while rigidly bounding the standard JSON API fetch requests (like loading mosques) to 10-second fast-fail limits.

## Technical Context

**Language/Version**: Dart (Flutter 3.10.7+)
**Primary Dependencies**: `dio`, `flutter_riverpod`
**Storage**: N/A (Networking layer modifies Dio Options; Presentation layer extracts Widgets)
**Testing**: Unit testing Dio configuration logic; code analysis linting to enforce file size
**Target Platform**: Android, iOS (Flutter Mobile)
**Project Type**: Mobile Application
**Performance Goals**: API Network responses fail gracefully under 10 seconds. Transfers permit up to 120 seconds.
**Constraints**: 70-line maximum line limit per `.dart` presentation widget file.
**Scale/Scope**: Refactoring the largest monolithic user interfaces (Mosque details, Reader pages).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clean Architecture**: Pass. Refactoring targets solely the UI layer. `dio` modifications reside in Infrastructure/Data services, respecting domain layers.
- **Offline Support**: Pass. Downloads logic is explicitly enhanced, not removed, by tuning large timeouts to support flaky offline/semi-offline setups.
- **Security via Build Args**: Pass. Network changes only affect Timeout config; URLs remain driven by `env.json`.
- **Privacy First**: Pass. Guest logic is unimpacted.
- **State Management**: Pass. `flutter_riverpod` integration retained.

## Project Structure

### Documentation (this feature)

```text
specs/001-ui-network-optimization/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── quickstart.md        # Phase 1 output
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── network/
│   │   └── dio_client.dart           # [MODIFY] Base 10-second timeout constraints
│   ├── services/
│   │   ├── downloads_service.dart    # [MODIFY] Audio download 120-second override
│   │   └── r2_storage_service.dart   # [MODIFY] Audio upload 120-second override
│   └── theme/
│       └── app_constants.dart        # [MODIFY] Network Timeout configs created here
└── features/
    └── mosques/
        └── presentation/
            ├── pages/
            │   ├── mosque_detail_page.dart # [MODIFY] Break down monolith
            │   └── day_detail_page.dart    # [MODIFY] Break down monolith
            └── widgets/                    # [NEW] Multiple tiny <70 line files
```

**Structure Decision**: The primary core modifications will be in existing network services and large presentation directories in the `mosques` module, slicing large monolithic pages into subcomponents.

## Verification Plan

### Automated Tests
- Build verification: Run `flutter analyze` ensuring 0 warnings.
- Linting checks: Manually enforce (or script) a line count limit script traversing `features/mosques/presentation/` to assert that no file surpasses `70` lines of code.

### Manual Verification
1. Open the application with Developer Tools (Network link conditioning on device/emulator) set to slow 3G.
2. Attempt to download a 5-minute audio recitation and verify that it does not crash or timeout abruptly before 2 minutes (120s limit).
3. Disable the network interface completely (100% loss).
4. Launch the application and observe the Mosque fetch logic. Ensure a network error occurs visibly in exactly 10 seconds or less.
