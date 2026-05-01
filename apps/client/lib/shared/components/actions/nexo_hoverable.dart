import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NexoHoverable extends StatefulWidget {
  const NexoHoverable({
    super.key,
    required this.child,
    this.enabled = true,
    this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<NexoHoverable> createState() => _NexoHoverableState();
}

class _NexoHoverableState extends State<NexoHoverable> {
  bool _hovered = false;

  bool get _canHover {
    return widget.enabled &&
        (kIsWeb ||
            defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: _hovered ? 1.01 : 1.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        opacity: _hovered ? 1.0 : 0.96,
        child: widget.child,
      ),
    );

    final wrapped = widget.onTap == null
        ? child
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onTap : null,
            child: child,
          );

    if (!_canHover) {
      return wrapped;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null || !widget.enabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: wrapped,
    );
  }
}
