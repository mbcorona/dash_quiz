import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/services/tilt_source.dart';

/// Reads how far the phone is leaning left or right.
///
/// Uses the accelerometer (gravity direction) rather than the gyroscope: the
/// gyroscope only reports rotation speed, so it cannot tell that the phone is
/// being *held* tilted.
class AccelerometerTiltSource implements TiltSource {
  /// Lean angle that maps to a full `-1` / `1`.
  static const double fullTiltDegrees = 30;

  StreamSubscription<AccelerometerEvent>? _subscription;
  double _sensor = 0;

  @override
  double get lean => _sensor;

  @override
  void start() {
    _subscription ??=
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen((event) {
              // x grows as the left edge of the phone drops.
              final roll = math.atan2(
                event.x,
                math.sqrt(event.y * event.y + event.z * event.z),
              );
              final target = (-roll * 180 / math.pi / fullTiltDegrees).clamp(
                -1.0,
                1.0,
              );
              // Low-pass filter so a shaky hand does not flicker the selection.
              _sensor += (target - _sensor) * 0.2;
            }, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
