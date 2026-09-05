import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/mosque_location.dart';

class MosqueLocationMapPreview extends StatelessWidget {
  final MosqueLocation location;
  final VoidCallback onChangeLocation;

  const MosqueLocationMapPreview({
    super.key,
    required this.location,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 150,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(location.latitude, location.longitude),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sout_salah',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        LucideIcons.mapPin,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (location.locationName != null) ...[
          Text(
            location.locationName!,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: onChangeLocation,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('تغيير الموقع'),
        ),
      ],
    );
  }
}
