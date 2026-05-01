import 'package:flutter/material.dart';

import '../../../core/design_system/nexo_spacing.dart';
import 'nexo_header.dart';

class NexoPageScaffold extends StatelessWidget {
  const NexoPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.maxWidth = 1180,
    this.contentSpacing = NexoSpacing.xl,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final double maxWidth;
  final double contentSpacing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth >= 1024 ? NexoSpacing.x2l : NexoSpacing.md;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              NexoSpacing.md,
              horizontalPadding,
              120,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NexoHeader(
                      title: title,
                      subtitle: subtitle,
                      trailing: trailing,
                    ),
                    SizedBox(height: contentSpacing),
                    child,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
