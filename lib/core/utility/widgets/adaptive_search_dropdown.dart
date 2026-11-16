import 'package:flutter/material.dart';

class AdaptiveSearchDropdown extends StatefulWidget {
  const AdaptiveSearchDropdown({
    super.key,
    required this.visible,
    required this.field,
    required this.options,
  });

  final bool visible;
  final Widget field;
  final Widget options;

  @override
  State<AdaptiveSearchDropdown> createState() => AdaptiveSearchDropdownState();
}

class AdaptiveSearchDropdownState extends State<AdaptiveSearchDropdown> {
  final _overlay = OverlayPortalController();

  bool _visibilityUpdateScheduled = false;

  void _scheduleVisibilityUpdate() {
    if (_visibilityUpdateScheduled) return;
    _visibilityUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityUpdateScheduled = false;
      if (!mounted || _overlay.isShowing == widget.visible) return;
      if (widget.visible) {
        _overlay.show();
      } else {
        _overlay.hide();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleVisibilityUpdate();
  }

  @override
  void didUpdateWidget(covariant AdaptiveSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _scheduleVisibilityUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlay,
      overlayChildBuilder: (context, info) {
        final field = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final visibleBottom =
            info.overlaySize.height -
            media.viewInsets.bottom -
            media.padding.bottom;
        final above = (field.top - media.padding.top).clamp(
          0.0,
          double.infinity,
        );
        final below = (visibleBottom - field.bottom).clamp(
          0.0,
          double.infinity,
        );
        final opensUp = below < 240 && above > below;
        final available = opensUp ? above : below;
        return Positioned(
          left: field.left,
          width: field.width,
          top: opensUp ? null : field.bottom,
          bottom: opensUp ? info.overlaySize.height - field.top : null,
          child: TextFieldTapRegion(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: available.clamp(0.0, 240.0),
                ),
                child: widget.options,
              ),
            ),
          ),
        );
      },
      child: widget.field,
    );
  }
}
