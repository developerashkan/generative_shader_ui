# generative_shader_ui example

Gallery app showing every widget of
[generative_shader_ui](https://pub.dev/packages/generative_shader_ui):
Siri orb and waves with a simulated voice, neon buttons, mesh gradients,
aurora, gradient text and shader progress indicators. Tap the palette chips to
watch every widget cross-fade to a new theme.

```bash
flutter run -d chrome   # or windows, macos, linux, android, ios
```

Minimal usage:

```dart
import 'package:flutter/material.dart';
import 'package:generative_shader_ui/generative_shader_ui.dart';

void main() => runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SiriOrb(),
                NeonButton(onPressed: () {}, child: const Text('Boom')),
              ],
            ),
          ),
        ),
      ),
    );
```
