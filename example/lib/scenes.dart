// Entry point used to render the README / pub.dev screenshots on the web:
//   flutter build web -t lib/scenes.dart
//   open index.html?scene=siri | controls | aurora | skeleton | glass |
//                         particles | motion
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

import 'main.dart';
import 'motion_sections.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShaderLibrary.precache();
  // ?slow=8 slows every animation 8x for frame-by-frame GIF capture.
  final double slow =
      double.tryParse(Uri.base.queryParameters['slow'] ?? '') ?? 1;
  timeDilation = slow;
  demoSlowdown = slow;
  runApp(GalleryApp(scene: Uri.base.queryParameters['scene']));
}
