import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class FakeGpsService {
  static StreamSubscription<Position>? _subscription;

  static Future<void> start({required VoidCallback onFakeDetected}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _subscription?.cancel();

    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((Position position) {
          if (position.isMocked) {
            onFakeDetected();
          }
        });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
