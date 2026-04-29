import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/study_group.dart';

class GroupMapScreen extends StatelessWidget {
  const GroupMapScreen({super.key, required this.group});

  final StudyGroup group;

  @override
  Widget build(BuildContext context) {
    final latitude = group.latitude;
    final longitude = group.longitude;

    return Scaffold(
      appBar: AppBar(title: Text('${group.subjectName} Map')),
      body: latitude == null || longitude == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Group ini belum punya koordinat GPS. Buka edit group dan gunakan tombol GPS perangkat.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                  maxNativeZoom: 20,
                  userAgentPackageName: 'com.example.studyGroupFinder',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude),
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                    TextSourceAttribution('CARTO'),
                  ],
                ),
              ],
            ),
    );
  }
}
