import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/navigation_service.dart';
import '../../domain/entities/mosque.dart';
import '../widgets/mosque_info_components/mosque_info_header.dart';
import '../widgets/mosque_info_components/mosque_info_description.dart';
import '../widgets/mosque_info_components/mosque_info_location_text.dart';
import '../widgets/mosque_info_components/mosque_info_map.dart';
import '../widgets/mosque_info_components/mosque_info_maps_button.dart';

class MosqueInfoPage extends StatefulWidget {
  final Mosque mosque;

  const MosqueInfoPage({super.key, required this.mosque});

  @override
  State<MosqueInfoPage> createState() => _MosqueInfoPageState();
}

class _MosqueInfoPageState extends State<MosqueInfoPage> {
  @override
  void initState() {
    super.initState();
    GetIt.I<AppLogger>().i('Opened MosqueInfoPage for ${widget.mosque.name}');
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = widget.mosque.latitude != null && widget.mosque.longitude != null;
    final hasDescription = widget.mosque.description != null && widget.mosque.description!.isNotEmpty;
    final hasLocationText = widget.mosque.location != null && widget.mosque.location!.isNotEmpty;
    final hasNoExtraInfo = !hasCoordinates && !hasDescription && !hasLocationText;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'معلومات المسجد',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.black),
          onPressed: () => NavigationService.goBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MosqueInfoHeader(mosque: widget.mosque),
            const SizedBox(height: 32),
            MosqueInfoDescription(mosque: widget.mosque),
            MosqueInfoLocationText(mosque: widget.mosque),
            MosqueInfoMap(mosque: widget.mosque),
            MosqueInfoMapsButton(mosque: widget.mosque),
            if (hasNoExtraInfo)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'لا توجد معلومات إضافية لهذا المسجد.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
