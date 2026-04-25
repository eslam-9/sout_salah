import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../models/mosque_model.dart';
import '../models/ramadan_day_model.dart';
import '../models/recording_model.dart';
import '../models/day_schedule_entry_model.dart';
import '../../domain/entities/prayer.dart';
import 'dart:io';

abstract class MosqueRemoteDataSource {
  Future<List<MosqueModel>> getMosques();
  Future<List<RamadanDayModel>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  });
  Future<void> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  });
  Future<List<Map<String, int>>> getAvailableMonths(String mosqueId);
  Future<List<RecordingModel>> getDayRecordings(String dayId);
  Future<MosqueModel> addMosque({
    required String name,
    required String location,
    String? description,
  });
  Future<RecordingModel> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  });
  Future<void> deleteRecording(String recordingId);
  Future<void> addPublisher(String mosqueId, String email);
  Future<RecordingModel> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  });

  // Day Schedule Methods
  Future<List<DayScheduleEntryModel>> getDaySchedule(String dayId);
  Future<DayScheduleEntryModel> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  });
  Future<DayScheduleEntryModel> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  });
  Future<void> deleteScheduleEntry(String entryId);
}

class MosqueRemoteDataSourceImpl implements MosqueRemoteDataSource {
  final SupabaseClient supabaseClient;
  final R2StorageService r2StorageService;
  final AppLogger logger;

  MosqueRemoteDataSourceImpl(
    this.supabaseClient,
    this.r2StorageService,
    this.logger,
  );

  @override
  Future<List<MosqueModel>> getMosques() async {
    logger.i('Fetching list of mosques');
    try {
      final response = await supabaseClient
          .from('mosques')
          .select('*, recordings(count)');
      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} mosques');
      return data.map((json) => MosqueModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching mosques', e);
      throw ServerException();
    }
  }

  @override
  Future<List<RamadanDayModel>> getRamadanDays(
    String mosqueId, {
    int? month,
    int? year,
  }) async {
    logger.i(
      'Fetching Ramadan days for mosque: $mosqueId, month: $month, year: $year',
    );
    try {
      var query = supabaseClient
          .from('ramadan_days')
          .select('*, recordings(count)')
          .eq('mosque_id', mosqueId);

      if (month != null) {
        query = query.eq('month', month);
      }
      if (year != null) {
        query = query.eq('year', year);
      }

      final response = await query.order('day_number', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} days');
      return data.map((json) => RamadanDayModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching Ramadan days', e);
      throw ServerException();
    }
  }

  @override
  Future<MosqueModel> addMosque({
    required String name,
    required String location,
    String? description,
  }) async {
    logger.i('Adding new mosque: $name');
    try {
      final response = await supabaseClient
          .from('mosques')
          .insert({
            'name': name,
            'location': location,
            ...?description != null ? {'description': description} : null,
          })
          .select()
          .single();

      logger.i('Mosque added successfully: ${response['id']}');
      return MosqueModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error adding mosque', e, stackTrace);
      logger.e('Error details: ${e.toString()}');
      throw ServerException();
    }
  }

  @override
  Future<void> addMonth({
    required String mosqueId,
    required int month,
    required int year,
  }) async {
    logger.i('Adding new month: $month/$year for mosque $mosqueId');
    try {
      final List<Map<String, dynamic>> daysToInsert = [];
      for (int i = 1; i <= 30; i++) {
        daysToInsert.add({
          'mosque_id': mosqueId,
          'day_number': i,
          'month': month,
          'year': year,
          'status': 'red',
          'active': true,
        });
      }

      await supabaseClient.from('ramadan_days').insert(daysToInsert);

      logger.i('Successfully added 30 days for month $month/$year');
    } catch (e, stackTrace) {
      logger.e('Error adding month', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<List<Map<String, int>>> getAvailableMonths(String mosqueId) async {
    logger.i('Fetching available months for mosque: $mosqueId');
    try {
      final response = await supabaseClient
          .from('ramadan_days')
          .select('month, year')
          .eq('mosque_id', mosqueId);

      final data = response as List<dynamic>;
      final uniqueMonths = <String, Map<String, int>>{};

      for (var row in data) {
        final m = row['month'] as int?;
        final y = row['year'] as int?;
        if (m != null && y != null) {
          uniqueMonths['$y-$m'] = {'month': m, 'year': y};
        }
      }

      final result = uniqueMonths.values.toList();
      // Sort ascending by year then month
      result.sort((a, b) {
        final yearCmp = a['year']!.compareTo(b['year']!);
        if (yearCmp != 0) return yearCmp;
        return a['month']!.compareTo(b['month']!);
      });

      return result;
    } catch (e, stackTrace) {
      logger.e('Error fetching available months', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<List<RecordingModel>> getDayRecordings(String dayId) async {
    logger.i('Fetching recordings for day: $dayId');
    try {
      final response = await supabaseClient
          .from('recordings')
          .select()
          .eq('day_id', dayId)
          .order('prayer_name', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} recordings');
      return data.map((json) => RecordingModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      logger.e('Error fetching recordings', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<RecordingModel> uploadRecording({
    required String mosqueId,
    required String dayId,
    required Prayer prayer,
    String? customPrayerName,
    required String sheikhName,
    required String filePath,
    required int fileSize,
    int? duration,
    void Function(double)? onProgress,
  }) async {
    final effectivePrayerName =
        prayer == Prayer.other && customPrayerName != null
        ? customPrayerName
        : prayer.englishName;
    logger.i('Uploading recording for prayer: $effectivePrayerName');
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$effectivePrayerName.mp3';
      final storageKey = 'recordings/$mosqueId/$dayId/$fileName';

      // Upload file to R2 and get CDN URL
      final audioUrl = await r2StorageService.uploadFile(
        storageKey,
        file,
        onProgress: onProgress,
      );

      // Save metadata to database
      final response = await supabaseClient
          .from('recordings')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'prayer_name': effectivePrayerName,
            'sheikh_name': sheikhName,
            'audio_url': audioUrl,
            'file_size': fileSize,
            'duration': duration,
          })
          .select()
          .single();

      logger.i('Recording uploaded successfully');
      return RecordingModel.fromJson(response);
    } catch (e) {
      logger.e('Error uploading recording', e);
      throw ServerException();
    }
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    logger.i('Deleting recording: $recordingId');
    try {
      // Get recording to find audio URL
      final recording = await supabaseClient
          .from('recordings')
          .select('audio_url')
          .eq('id', recordingId)
          .single();

      final audioUrl = recording['audio_url'] as String;

      // Extract storage key from CDN URL
      final uri = Uri.parse(audioUrl);
      final storageKey = uri.path.startsWith('/')
          ? uri.path.substring(1)
          : uri.path;

      // Delete from R2
      await r2StorageService.deleteFile(storageKey);

      // Delete from database
      await supabaseClient.from('recordings').delete().eq('id', recordingId);

      logger.i('Recording deleted successfully');
    } catch (e) {
      logger.e('Error deleting recording', e);
      throw ServerException();
    }
  }

  @override
  Future<void> addPublisher(String mosqueId, String email) async {
    logger.i('Adding publisher with email $email to mosque $mosqueId');
    try {
      // 1. Find user by email
      final userResponse = await supabaseClient
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        logger.w('User with email $email not found');
        throw Exception('User not found');
      }

      final userId = userResponse['id'] as String;

      // 2. Check if current user is super admin
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final profileResponse = await supabaseClient
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final currentRole = profileResponse['role'] as String?;
      if (currentRole != 'admin') {
        throw Exception('فقط مدير النظام يمكنه إضافة ناشرين');
      }

      // 3. Add to mosque_publishers
      await supabaseClient.from('mosque_publishers').insert({
        'mosque_id': mosqueId,
        'publisher_id': userId,
        'added_by': currentUser.id,
      });

      logger.i('Publisher added successfully');
    } catch (e) {
      logger.e('Error adding publisher', e);
      if (e.toString().contains('User not found') ||
          e.toString().contains('User with email')) {
        throw Exception('المستخدم غير موجود');
      }
      if (e.toString().contains('Only Super Admin')) {
        throw Exception('فقط مدير النظام يمكنه إضافة ناشرين');
      }
      throw ServerException();
    }
  }

  @override
  Future<RecordingModel> createPendingRecording({
    required String mosqueId,
    required String dayId,
    required String prayerName,
  }) async {
    logger.i('Creating pending recording for: $prayerName');
    try {
      final response = await supabaseClient
          .from('recordings')
          .insert({
            'mosque_id': mosqueId,
            'day_id': dayId,
            'prayer_name': prayerName,
            'sheikh_name': 'Pending',
            'audio_url': 'pending',
            'file_size': 0,
            'duration': 0,
          })
          .select()
          .single();

      logger.i('Pending recording created successfully');
      return RecordingModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating pending recording', e);
      throw ServerException();
    }
  }

  // --- Day Schedule Methods ---

  @override
  Future<List<DayScheduleEntryModel>> getDaySchedule(String dayId) async {
    logger.i('Fetching schedule for day: $dayId');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .select()
          .eq('day_id', dayId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final data = response as List<dynamic>;
      logger.i('Fetched ${data.length} schedule entries');
      return data.map((json) => DayScheduleEntryModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      logger.e('Error fetching day schedule', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<DayScheduleEntryModel> addScheduleEntry({
    required String dayId,
    required String mosqueId,
    required String salah,
    required String shikh,
    String? comments,
    int sortOrder = 0,
  }) async {
    logger.i('Adding schedule entry for $salah by $shikh');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .insert({
            'day_id': dayId,
            'mosque_id': mosqueId,
            'salah': salah,
            'shikh': shikh,
            ...?comments != null ? {'comments': comments} : null,
            'sort_order': sortOrder,
          })
          .select()
          .single();

      logger.i('Schedule entry added successfully');
      return DayScheduleEntryModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error adding schedule entry', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<DayScheduleEntryModel> updateScheduleEntry({
    required String entryId,
    required String salah,
    required String shikh,
    String? comments,
  }) async {
    logger.i('Updating schedule entry: $entryId');
    try {
      final response = await supabaseClient
          .from('day_schedule')
          .update({'salah': salah, 'shikh': shikh, 'comments': comments})
          .eq('id', entryId)
          .select()
          .single();

      logger.i('Schedule entry updated successfully');
      return DayScheduleEntryModel.fromJson(response);
    } catch (e, stackTrace) {
      logger.e('Error updating schedule entry', e, stackTrace);
      throw ServerException();
    }
  }

  @override
  Future<void> deleteScheduleEntry(String entryId) async {
    logger.i('Deleting schedule entry: $entryId');
    try {
      await supabaseClient.from('day_schedule').delete().eq('id', entryId);
      logger.i('Schedule entry deleted successfully');
    } catch (e, stackTrace) {
      logger.e('Error deleting schedule entry', e, stackTrace);
      throw ServerException();
    }
  }
}
