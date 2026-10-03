# Performance

**Performance Status: UNKNOWN.** Static review only.
**Performance Runtime Validation: NOT PERFORMED — Reason: no device/profile session available in audit environment.**
Never claim "performance is good" — neither level below is complete without runtime numbers.

## Static Performance Review (measured from code, 2026-09-24)
1. **List-wide rebuild on playback state** — every audio card watches `audioPlayerServiceProvider + currentPlayingRecordingProvider` (`audio_player_widget.dart:21-22`, `download_card.dart:47-48`, `saved_recording_card.dart:59-60`, `day_recording_play_button.dart:18-19`). Fix: `select()`/per-card family. Verify: DevTools rebuild counts.
2. **Full-list wipes** — `loadMore`/refresh/requests mutations emit bare `loading()` (`mosque_controller.dart:64,76`, `day_schedule_provider.dart:39`, `mosque_requests_provider.dart:101,127`). Fix: `copyWithPrevious` + footer loader.
3. **Provider thrash** — `FutureProvider.autoDispose.family` (day recordings/schedule/videos/months) with no `keepAlive`/TTL; back-and-forth navigation refetches identically. Fix: `keepAlive` + stale-while-revalidate or cached `AsyncNotifier`.
4. **Search: no debounce + defeated pagination** — keystroke → full rebuild + client `contains` over loaded pages only (`mosques_page.dart:68,78-80`); `grep debounce` = zero hits. Fix: 300ms debounce + server-side `ilike` or fetch-all contract.
5. **O(N) video players** — `DailyVideoPage` instantiates a `VideoPlayerController` per item; dispose correct (`daily_video_widget.dart:145-149`) but no `mounted` guard after `await initialize` (`:134`), late-init hazard, no lazy-init on visibility.
6. **Slider tick rebuilds** — `positionStream` rebuilds column per tick; sync `duration` read; unthrottled seeks. Fix: throttle + `durationStream`.
7. **Leaks** — singleton `AudioPlayer` never disposed (provider non-`autoDispose`, `dispose()` uncalled); `R2 readAsBytes` whole-file memory; double `File.length()` IO.
8. **`const` density** — ~1 per 12 lines in biggest widgets (`day_schedule_table_widget.dart` 21/257, `download_card.dart` 19/250); `prefer_const_constructors` unenforced (no CI).
9. **Critical bug (functional, found via perf-adjacent read)** — `getCurrentRoute()` pops the entire stack (`navigation_service.dart:124-131`). Fix + regression test immediately.

## Non-issues (verified)
- No remote images (`Image./NetworkImage/cached_network_image` zero hits) — nothing to cache until thumbnails arrive.
- Pagination genuinely exists (defeated only by client search + unstable pages: limit+range, no order).
- Chewie dispose present; lists use builders (1 horizontal `ListView` should be `Row`: `home_widgets.dart:58`).

## Runtime Performance Review
NOT PERFORMED. When a device is available: `flutter run --profile` + DevTools Performance view over browse → day detail → play → download → upload → map flows. Record frame/jank, build/raster time, rebuild hotspots, memory, slow screens. Debug-mode timings are not accepted as final measurement.

## Rules
- Profile before optimizing; smallest fix first. No caching/pagination/slivers/isolates without a measured number.
- Disposition each static risk with a number before closing (see REFACTOR_PLAN Phase 5).
