import 'package:flutter/widgets.dart';

import '../palette.dart';
import 'neon_container.dart';

/// A glowing neon button rendered by a GPU shader.
///
/// ```dart
/// NeonButton(
///   onPressed: () {},
///   child: const Text('Get started'),
/// )
/// ```
///
/// Hovering and focusing brighten the neon, pressing flashes the fill and
/// squeezes the button, and a light follows the finger or mouse. Supports
/// keyboard activation (Enter / Space) and screen readers.
///
/// Set [onPressed] to null to disable the button.
class NeonButton extends StatefulWidget {
  /// Creates a neon button.
  const NeonButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.palette = ShaderPalette.neon,
    this.borderRadius = 16,
    this.strokeWidth = 2,
    this.glow = 14,
    this.fillColor = const Color(0xE60B0B16),
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    this.textStyle,
    this.speed = 1.0,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Called when the button is tapped or activated with the keyboard.
  final VoidCallback? onPressed;

  /// Called when the button is long-pressed.
  final VoidCallback? onLongPress;

  /// The label, usually a [Text] or a [Row] with an icon.
  final Widget child;

  /// Neon sweep colors.
  final ShaderPalette palette;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Neon line thickness.
  final double strokeWidth;

  /// Glow spread in logical pixels.
  final double glow;

  /// Fill behind the label.
  final Color fillColor;

  /// Space around the label.
  final EdgeInsetsGeometry padding;

  /// Label style; defaults to bold white text.
  final TextStyle? textStyle;

  /// Animation speed multiplier.
  final double speed;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus on first build.
  final bool autofocus;

  /// Overrides the label read by screen readers.
  final String? semanticLabel;

  /// Whether the button reacts to input.
  bool get enabled => onPressed != null || onLongPress != null;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final double highlight = !enabled
        ? 0
        : _pressed
            ? 1
            : (_hovered || _focused)
                ? 0.5
                : 0;

    Widget content = DefaultTextStyle.merge(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ).merge(widget.textStyle),
      textAlign: TextAlign.center,
      child: IconTheme.merge(
        data: const IconThemeData(color: Color(0xFFFFFFFF), size: 20),
        child: widget.child,
      ),
    );

    content = NeonContainer(
      palette: widget.palette,
      borderRadius: widget.borderRadius,
      strokeWidth: widget.strokeWidth,
      glow: widget.glow,
      fillColor: widget.fillColor,
      highlight: highlight,
      speed: widget.speed,
      padding: widget.padding,
      interactive: enabled,
      animate: enabled,
      child: content,
    );

    content = AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );

    content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: content,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: content,
      ),
    );
  }
}
