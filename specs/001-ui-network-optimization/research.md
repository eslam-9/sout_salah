# Phase 0: Research & Technical Decisions (001-ui-network-optimization)

## 1. Dio Timeout Configuration Strategies

**Context**: The spec requires dynamic network timeouts depending on the operation type—120 seconds for large audio uploads/downloads, and strict short timeouts (e.g., 10 seconds) for standard JSON API fetches.

**Decision**: Implement domain-specific HTTP clients or inject specific `Options` overrides in the repository layer using a centralized `NetworkConfig` constant class.
**Rationale**: Flutter's `dio` package allows defining base options on the `Dio` instance itself, but also allows overriding `connectTimeout`, `sendTimeout`, and `receiveTimeout` dynamically per request using the `Options` parameter. By defining named constants like `NetworkConfig.audioTimeout` and `NetworkConfig.standardTimeout`, we can explicitly pass these down in the data sources where audio transfers or data fetches occur.

**Alternatives considered**: Create completely separate `Dio` instances for API vs. Media. Rejected because the base URL, interceptors (for auth), and certificate handling are identical across requests, making separated instances redundant and slightly heavier on memory.

## 2. Enforcing 70-line Maximum Constraint in Flutter

**Context**: The spec heavily mandates that UI components must not exceed 70 lines to enforce strict, "senior-level" modularity.

**Decision**: Extract the monolithic screens heavily utilizing the `Widget` extraction pattern (subclasses of `StatelessWidget` / `ConsumerWidget`) rather than helper text functions returning `Widget`. Organize these files into grouped granular folders (e.g., `features/mosques/presentation/widgets/mosque_detail_components/`).
**Rationale**: Method-based widget extraction (e.g., `Widget _buildHeader() { ... }`) retains the code inside the same file, severely violating the 70-line limit per file. True class-based extraction forces separation into individual files. Because the constraint is strict (70 lines), even moderate stateful components will need deliberate separation of state logic (using `flutter_riverpod` providers) from the pure UI rendering widgets.

**Alternatives considered**: Raising the limit to 150 lines. Rejected as it explicitly violates the `001-ui-network-optimization` user-defined hard constraint.
