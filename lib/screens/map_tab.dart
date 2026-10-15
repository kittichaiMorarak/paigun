import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/app_state.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final places = appState.places;
    final selected = appState.selectedPlaces;

    if (places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selIds = selected.map((p) => p.id).toSet();
    final markers = <Marker>{
      for (final p in places)
        Marker(
          markerId: MarkerId('${p.id}'),
          position: LatLng(p.lat, p.lng),
          infoWindow: InfoWindow(title: p.name, snippet: p.province),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selIds.contains(p.id)
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
        ),
    };

    final lines = <Polyline>{
      if (selected.length > 1)
        Polyline(
          polylineId: const PolylineId('plan'),
          points: [for (final p in selected) LatLng(p.lat, p.lng)],
          width: 4,
          color: Theme.of(context).colorScheme.primary,
        ),
    };

    return GoogleMap(
      initialCameraPosition:
          const CameraPosition(target: LatLng(13.0, 101.0), zoom: 5.2),
      markers: markers,
      polylines: lines,
      myLocationButtonEnabled: false,
    );
  }
}
