# Data Layer

## Backend
Supabase PostgreSQL + Auth. `main.dart:22 Supabase.initialize(AppConfig.supabaseUrl/anonKey)`; `injection_container.dart:16` + `riverpod_providers.dart:28` expose client. Tables: `profiles`, `mosques`, `mosque_publishers`, `mosque_requests`, `ramadan_days`, `day_schedule`, `recordings`, `daily_videos`, `fcm_tokens`, `data`. Schema in `database_schema.sql`. RLS assumed in SQL — verify in Supabase dashboard (UNKNOWN: RLS enforcement not verified from code).

## Datasources (all `SupabaseClient`-injected, `from('table')`, throw `ServerException`)
- `auth_remote_data_source.dart`: signIn/signUp/anonymously/signOut + `from('profiles')`.
- `mosque_remote_data_source.dart`: `from('mosques,profiles,mosque_publishers')` (location fields added recently).
- `ramadan_days|recordings|mosque_requests|day_schedule_remote_data_source.dart` — one per table.
- Helpers: `mosques/data/services/location_service.dart` (geolocator+geocoding+permission → `Location*Exception`), `maps_navigation_service.dart` (url_launcher → `MapLaunchException`).
- Core services acting as datasources: `r2_storage_service.dart` (Dio PUT/DELETE + AWS4 SigV4 via `AppConfig.r2*`), `startup_service.dart (from('data'))`, `notification_service.dart (from('fcm_tokens') + functions.invoke)`; `recordings_remote_data_source.dart:92,137` is the only R2 consumer (`audio_url=pending` flow).

## Models / repos
- Models: `auth/{user_model (fromSupabase), profile_model}`, `mosques/{mosque,recording,ramadan_day,mosque_request,mosque_publisher,day_schedule_entry,daily_video}_model.dart`, `core/models/{downloaded_recording,favorite_recording}.dart` (JSON).
- Repo impls (`auth_repository_impl`, `mosque|ramadan_days|recordings|mosque_requests|day_schedule|location_repository_impl`) implement domain contracts and wrap calls in `executeWithCatch → Either<Failure,T>`.
- **Exception:** `mosques/data/repositories/video_repository.dart` queries Supabase directly and returns models — must be refactored to datasource+`Either` like the rest.

## Network / local
- `dioProvider` (`riverpod_providers.dart:18-26`) with `NetworkConfig.standardTimeout`; `network_info.dart (Connectivity)`, `network_policy.dart`, `retry_executor.dart`; `internet_connection_checker` + `connectivity_plus`.
- Downloads: `downloads_service.dart:101 _dio.download → app docs/downloads/<id>.mp3`, index in `SharedPreferences ('downloaded_recordings')`. Favorites: `SharedPreferences ('favorite_recordings')`. Guest flag: `permission_checker.dart:41 is_guest_mode`. Files via `path_provider`.

## Rules
- New backend access: datasource (Supabase/R2) → repo impl (`executeWithCatch`) → domain contract (`Either`) → usecase. No direct `SupabaseClient`/datasource/model imports in presentation or routing.
- `DailyVideoModel` must not cross into `route_args.dart`/widgets — add a domain video entity or document the exception.
- R2 signing stays in `r2_storage_service.dart`; recordings flow keeps `pending → upload → update url`.
