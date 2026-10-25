import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:ar_furniture_configurator/screens/room_ar_screen.dart';

void main() {
  /// Arah sisi depan (+Z) furnitur di dunia setelah anchor dan node digabung.
  Vector3 frontInWorld(Matrix4 anchor, Matrix4 local) {
    final world = anchor.multiplied(local);
    return world.getRotation().transformed(Vector3(0, 0, 1));
  }

  test('furnitur menghadap kamera walau anchor berputar', () {
    for (final anchorYaw in [0.0, 0.7, -2.1, math.pi]) {
      final anchor = Matrix4.compose(
        Vector3(1, 0, -2),
        Quaternion.axisAngle(Vector3(0, 1, 0), anchorYaw),
        Vector3.all(1),
      );
      final camera = Matrix4.translation(Vector3(1, 1.4, 1));
      final front = frontInWorld(anchor, faceCameraTransform(anchor, camera));
      // Kamera ada tepat di +Z dari titik anchor.
      expect(front.x, closeTo(0, 1e-9), reason: 'yaw $anchorYaw');
      expect(front.z, closeTo(1, 1e-9), reason: 'yaw $anchorYaw');
    }
  });

  test('tanpa pose kamera, rotasi tidak diubah', () {
    expect(faceCameraTransform(Matrix4.identity(), null), Matrix4.identity());
  });
}
