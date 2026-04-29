import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  static const LatLng _surabayaCenter = LatLng(-7.2575, 112.7521);

  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _onTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _picked = latlng;
    });
  }

  void _confirm() {
    if (_picked == null) return;
    Navigator.of(
      context,
    ).pop({'latitude': _picked!.latitude, 'longitude': _picked!.longitude});
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? _surabayaCenter;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi di Peta')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onTap: _onTap,
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
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 48,
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
          // Info and confirm button at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_picked != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Lokasi terpilih: ${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Tap pada peta untuk memilih lokasi',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  FilledButton(
                    onPressed: _picked == null ? null : _confirm,
                    child: const Text('Konfirmasi Lokasi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
