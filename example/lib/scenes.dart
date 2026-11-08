// Entry point used to render the README / pub.dev screenshots on the web:
//   flutter build web -t lib/scenes.dart
//   open index.html?scene=siri | controls | aurora
import 'package:flutter/widgets.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

import 'main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShaderLibrary.precache();
  runApp(GalleryApp(scene: Uri.base.queryParameters['scene']));
}
