import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class StorageService {
  static const _uuid = Uuid();

  static Future<String?> uploadAvatar(File file) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final ext = file.path.split('.').last;
    final path = 'avatars/$userId/${_uuid.v4()}.$ext';

    await SupabaseService.storage.from('avatars').upload(path, file);

    return SupabaseService.storage.from('avatars').getPublicUrl(path);
  }

  static Future<String?> uploadMatchPhoto(String matchId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'matches/$matchId/${_uuid.v4()}.$ext';

    await SupabaseService.storage.from('matches').upload(path, file);

    return SupabaseService.storage.from('matches').getPublicUrl(path);
  }

  static Future<String?> uploadVenuePhoto(int venueId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'venues/$venueId/${_uuid.v4()}.$ext';

    await SupabaseService.storage.from('venues').upload(path, file);

    return SupabaseService.storage.from('venues').getPublicUrl(path);
  }
}
