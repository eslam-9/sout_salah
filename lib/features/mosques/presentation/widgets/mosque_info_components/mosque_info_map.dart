import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/mosque.dart';

class MosqueInfoMap extends StatelessWidget {
  final Mosque mosque;

  const MosqueInfoMap({super.key, required this.mosque});

  @override
  Widget build(BuildContext context) {
    if (mosque.latitude == null || mosque.longitude == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(mosque.latitude!, mosque.longitude!),
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
                    point: LatLng(mosque.latitude!, mosque.longitude!),
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
    );
  }
}
