import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// For the tablet size we show a drop down version, just like a menu because we
/// have space. For the mobile we show a bottom sheet that can replace the
/// keyboard if needed.
enum DisplayType { bottomSheet, dropDown }

class _DropdownRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownRouteLayout({this.rect, this.screen});

  final Rect rect;
  final Size screen;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return new BoxConstraints(
      maxWidth: screen.width,
      maxHeight: screen.height * 0.4,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double dx = rect.left;
    double dy = rect.top;
    return new Offset(
        screen.width / 2, screen.height / 2); // new Offset(dx, dy);
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

  @override
  String get barrierLabel => "Dismiss";

  void _dismiss() {
    navigator?.removeRoute(this);
  }
}

typedef Widget HeaderBuilder<T extends PickerBase<T>>(T value);

class ValuePickerButton<W extends PickerBase<V>, V> extends StatefulWidget {
  const ValuePickerButton({
    @required this.picker,
    this.currentValue,
    @required this.headerBuilder,
    this.onValue,
    this.onShow,
  });

  final W picker;

  final V currentValue;

  final HeaderBuilder<V> headerBuilder;

  final ValueChanged<V> onValue;

  final ValueChanged<DisplayType> onShow;

  @override
  _ValuePickerButtonState<W, V> createState() =>
      new _ValuePickerButtonState<W, V>();
}

class _ValuePickerButtonState<W extends PickerBase<V>, V>
    extends State<ValuePickerButton> with WidgetsBindingObserver {
  V _value;

  _WidgetDropdownRoute<V> _dropdownRoute;

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

  void _openFontPanel() {
    final screen = MediaQuery.of(context).size;

    widget.picker.onValue[0] = (newValue) => Navigator.pop(context, newValue);

    if (screen.shortestSide > 600) {
      // This is a tablet, we are going for [PopupRoute]
      final RenderBox itemBox = context.findRenderObject();
      final Rect itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

      assert(_dropdownRoute == null);
      _dropdownRoute = new _WidgetDropdownRoute<V>(
        child: widget.picker,
        rect: itemRect,
      );

      if (widget.onShow != null) widget.onShow(DisplayType.dropDown);
      Navigator.push(context, _dropdownRoute).then<Null>((V newValue) {
        _dropdownRoute = null;
        if (!mounted || newValue == null) return null;

        if (widget.onValue != null) {
          widget.onValue(newValue);
        }
      });
    } else {
      if (widget.onShow != null) widget.onShow(DisplayType.bottomSheet);
      showModalBottomSheet(
        builder: (context) => widget.picker,
        context: context,
      ).then((newValue) {
        if (widget.onValue != null) {
          widget.onValue(newValue);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: 112.0,
      child: new GestureDetector(
          onTap: _openFontPanel, child: widget.headerBuilder(_value)),
    );
  }
}

abstract class PickerBase<V> extends StatefulWidget {
  const PickerBase();

  final List<ValueChanged<V>> onValue = const [];
}
