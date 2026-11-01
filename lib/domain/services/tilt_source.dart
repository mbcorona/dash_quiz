/// Reports how far the device is leaning left or right.
/// Implemented in the data layer.
abstract interface class TiltSource {
  /// Lean in `-1..1`; negative is left.
  double get lean;

  void start();

  void dispose();
}
