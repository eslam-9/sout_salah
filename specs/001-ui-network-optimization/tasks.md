---
description: "Implementation tasks for UI and Network Optimization"
---

# Tasks: UI and Network Optimization

**Feature**: 001-ui-network-optimization
**Input**: Design documents from `/specs/001-ui-network-optimization/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [quickstart.md](./quickstart.md)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure confirmation

- [ ] T001 [P] Verify `dio` and `flutter_riverpod` dependencies are correctly defined in `pubspec.yaml`
- [ ] T002 [P] Review `lib/core/di/providers.dart` (or equivalent core network module) to locate where the centralized base `Dio` instance is provided to the app

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Define `NetworkConfig.audioTimeout` (120s) and `NetworkConfig.standardTimeout` (10s) constants in `lib/core/theme/app_constants.dart` (or create `lib/core/config/network_config.dart` if appropriate)

**Checkpoint**: Foundation ready - timeouts are globally accessible.

---

## Phase 3: User Story 1 - Reliable Audio Transfers (Priority: P1) 🎯 MVP

**Goal**: Users can reliably upload or download large audio recordings without the transfer failing prematurely due to strict standard timeouts.

**Independent Test**: Download a large recitation file while simulating a slow 3G network connection ensuring the transfer completes successfully without a timeout error.

### Implementation for User Story 1

- [ ] T004 [P] [US1] Apply `NetworkConfig.audioTimeout` via `Options(sendTimeout, receiveTimeout)` to upload methods in `lib/core/services/r2_storage_service.dart`
- [ ] T005 [P] [US1] Apply `NetworkConfig.audioTimeout` via `Options(receiveTimeout)` to download operations in `lib/core/services/downloads_service.dart`
- [ ] T006 [P] [US1] Ensure exceptions caught in these services gracefully handle partial failures (clear partial files if incomplete)

**Checkpoint**: Audio handling operations strictly obey the extended 120s timeout limit.

---

## Phase 4: User Story 2 - Snappy Data Retrieval (Priority: P2)

**Goal**: Standard text-based API fetches quick-fail inside 10 seconds if the network drops, avoiding infinite loading spinners.

**Independent Test**: Launch the app with a dropped network connection (100% packet loss) and verify the data fetch fails within exactly 10 seconds, showing an error UI.

### Implementation for User Story 2

- [ ] T007 [US2] Enforce standard `NetworkConfig.standardTimeout` on the primary `Dio` instance configuration in `lib/core/di/providers.dart` (or wherever Dio is initialized globally)
- [ ] T008 [US2] Review Mosque fetching logic to ensure it displays the offline cache or a visible network error dialog distinctly upon a timeout exception
- [ ] T008b [US2] Integrate Riverpod `AsyncValue` caching fallbacks into the fetched screens (e.g. Mosque Details) so previously fetched data remains visible during timeout errors

**Checkpoint**: API fetches are noticeably snappy on failure and recover visually.

---

## Phase 5: User Story 3 - Consistent User Interface (Priority: P3)

**Goal**: Users interact with a heavily polished UI powered by modular custom widgets adhering strictly to the <70 lines-of-code per file limitation.

**Independent Test**: Run a line-limit check on the `mosques/presentation` directory and verify 0 violations.

### Implementation for User Story 3

- [ ] T009 [P] [US3] Extract heavy sub-widgets (headers, lists, floating panels) from `lib/features/mosques/presentation/pages/mosque_detail_page.dart` into a new `widgets/mosque_detail_components/` directory (strict <= 70 lines each)
- [ ] T010 [P] [US3] Extract repeating elements from `lib/features/mosques/presentation/pages/day_detail_page.dart` into a new `widgets/day_detail_components/` directory (strict <= 70 lines each)
- [ ] T011 [US3] Refactor the main placeholder screens (`mosque_detail_page.dart` and `day_detail_page.dart`) to consume the newly extracted micro-widgets exclusively

**Checkpoint**: UI code maintains semantic consistency and forces hyper-separation of concerns.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality assurance and final validation across all modules

- [ ] T012 Run internal metrics scripts or manual review validating that absolutely zero UI component files violate the 70-line limit
- [ ] T013 [P] Execute integration tests simulating slow 3G networks confirming audio files do not prematurely time out (120s duration holds)
- [ ] T014 [P] Execute integration tests simulating 100% packet loss confirming API metadata endpoints fail quickly (10s limit holds)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Phase 1
- **User Stories (Phase 3-5)**: Depend on Phase 2 constant definitions
- **Polish (Final Phase)**: Depends on Phase 2-5 completion

### Parallel Opportunities

- Networking tasks (US1/US2) and UI tasks (US3) operate in completely detached layers. Thus, T004/T005 (Audio timeouts) can be developed directly in parallel with T009/T010 (UI Widget isolation).

### Implementation Strategy

1. **MVP**: Complete Setup, Foundational, and User Story 1 (Timeout reliability is paramount).
2. **Expansion**: Implement User Story 2 to fix infinite spinner issues.
3. **Refactor**: Finally address User Story 3 by carving down the monolithic UI screens to match the strict modularity limits.
