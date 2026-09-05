import 'package:url_launcher/url_launcher.dart';
import '../../../../core/error/exceptions.dart';
import 'package:logger/logger.dart';
import '../../../../core/utils/app_logger.dart';

class MapsNavigationService {
  final AppLogger _logger;

  MapsNavigationService(this._logger);

  Future<void> openGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
    final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        throw MapLaunchException();
      }
    } catch (e) {
      _logger.e('Failed to launch map: $e');
      throw MapLaunchException();
    }
  }
}
