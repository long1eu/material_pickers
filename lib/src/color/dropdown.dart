import 'package:flutter/material.dart';
import 'package:material_pickers/src/color/color_picker.dart';
import 'package:material_pickers/src/picker.dart';

class _DropdownRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownRouteLayout({this.rect, this.screen});

  final Rect rect;
  final Size screen;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      minWidth: kWidgetWidth,
      maxWidth: screen.width,
      minHeight: kWidgetHeight,
      maxHeight: kWidgetHeight ?? screen.height * 0.4,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double dx = rect.left - (kWidgetWidth / 2) + rect.width / 2;
    double dy = rect.top - kWidgetHeight;
    return new Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_DropdownRouteLayout<T> oldDelegate) {
    return rect != oldDelegate.rect || screen != oldDelegate.screen;
  }
}

class _WidgetDropdownRoute<T> extends PopupRoute<T> {
  _WidgetDropdownRoute({this.child, this.rect});

  final Widget child;

  final Rect rect;

  @override
  Color get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return new CustomSingleChildLayout(
      delegate: new _DropdownRouteLayout<T>(
        rect: rect,
        screen: MediaQuery.of(context).size,
      ),
      child: child,
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  void _dismiss() {
    navigator?.removeRoute(this);
  }
}

/// This is an implementation for the [ColorPicker] witch displays a drop down
/// if on tablet just above the [button] and shows a [BottomSheet] if on mobile.
class ColorPickerButton extends StatefulWidget {
  ColorPickerButton(
      {this.button, this.currentColor, this.onColor, this.onShow});

  /// Provide a button that your want to show the color picker.
  final Widget button;

  /// The [Color] you want to initialize the picker with. If the color is not in
  /// the list then black is selected.
  final Color currentColor;

  /// You will be notified with ne new color.
  final ValueChanged<Color> onColor;

  /// You will be notified just before the picker becomes visible with the mode
  /// that was picked. You can use this occasion to prepare yourself for focus
  /// loss for example.
  final ValueChanged<DisplayType> onShow;

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton>
    with WidgetsBindingObserver {
  _WidgetDropdownRoute<Color> _dropdownRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _removeDropdownRoute();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
  }

  void _handleTap() {
    final screen = MediaQuery.of(context).size;

    if (screen.shortestSide > 600) {
      // This is a table, we are going for [PopupRoute]
      final RenderBox itemBox = context.findRenderObject();
      final Rect itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

      assert(_dropdownRoute == null);
      _dropdownRoute = new _WidgetDropdownRoute<Color>(
        child: new ColorPicker(
          onColor: (newValue) {
            Navigator.pop(context, newValue);
          },
          currentColor: widget.currentColor,
        ),
        rect: itemRect,
      );

      if (widget.onShow != null) widget.onShow(DisplayType.dropDown);
      Navigator.push(context, _dropdownRoute).then<Null>((Color newValue) {
        _dropdownRoute = null;
        if (!mounted || newValue == null) return null;
        if (widget.onColor != null) widget.onColor(newValue);
      });
    } else {
      if (widget.onShow != null) widget.onShow(DisplayType.bottomSheet);
      showModalBottomSheet(
        builder: (context) {
          return new ColorPicker(
            onColor: (newValue) {
              Navigator.pop(context, newValue);
            },
            currentColor: widget.currentColor,
            type: MaterialType.transparency,
          );
        },
        context: context,
      ).then((newValue) {
        if (widget.onColor != null) widget.onColor(newValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.findRenderObject();
    return new GestureDetector(
      onTap: _handleTap,
      child: widget.button,
    );
  }
}
