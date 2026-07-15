import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps content inside a single visible pane on foldable screens.
///
/// On regular screens this behaves like a centered max-width container.
class FoldAwarePane extends StatelessWidget {
  const FoldAwarePane({
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double? maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final pane = _resolvePane(mediaQuery);
    final resolvedMaxWidth = maxWidth ?? double.infinity;
    final targetWidth = math.min(pane.width, resolvedMaxWidth);

    if (pane.usePaneAlignment) {
      return Align(
        alignment: pane.alignment,
        child: SizedBox(width: targetWidth, child: child),
      );
    }

    if (!targetWidth.isFinite || targetWidth >= screenSize.width) {
      return Align(alignment: alignment, child: child);
    }

    return Align(
      alignment: alignment,
      child: SizedBox(width: targetWidth, child: child),
    );
  }

  _FoldPane _resolvePane(MediaQueryData mediaQuery) {
    final screenSize = mediaQuery.size;

    final verticalFold = mediaQuery.displayFeatures.where((feature) {
      final typeName = feature.type.toString().toLowerCase();
      final isFoldOrHinge =
          typeName.contains('fold') || typeName.contains('hinge');
      if (!isFoldOrHinge) return false;

      final bounds = feature.bounds;
      if (bounds.width <= 0) return false;
      return bounds.height >= (screenSize.height * 0.8);
    });

    if (verticalFold.isEmpty) {
      return _FoldPane(
        width: screenSize.width,
        alignment: Alignment.topCenter,
        usePaneAlignment: false,
      );
    }

    final hingeBounds = verticalFold.first.bounds;
    final leftPaneWidth = hingeBounds.left;
    final rightPaneWidth = screenSize.width - hingeBounds.right;

    if (leftPaneWidth <= 0 && rightPaneWidth <= 0) {
      return _FoldPane(
        width: screenSize.width,
        alignment: Alignment.topCenter,
        usePaneAlignment: false,
      );
    }

    final useRightPane = rightPaneWidth > leftPaneWidth;
    return _FoldPane(
      width: useRightPane ? rightPaneWidth : leftPaneWidth,
      alignment: useRightPane ? Alignment.topRight : Alignment.topLeft,
      usePaneAlignment: true,
    );
  }
}

class _FoldPane {
  const _FoldPane({
    required this.width,
    required this.alignment,
    required this.usePaneAlignment,
  });

  final double width;
  final Alignment alignment;
  final bool usePaneAlignment;
}
