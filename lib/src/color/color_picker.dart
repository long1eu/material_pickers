import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_pickers/src/color/colors.dart';
import 'package:material_pickers/src/picker.dart';

/// The size of the color box from the main color row.
const double _kColorBoxSize = 24.0;

/// The width of all the main color boxes.
const double _mainColorsBarWidth = 11 * _kColorBoxSize;

/// The with of the frame that surrounds the color box when the frame is over
/// it. This is a magic number. :)
const double _kBaseFrameWidth = 3.3;

/// The margin the two rows have in the [Material] widget.
const double _kMarginSize = 16.0;

// secondary colors
/// The number of logical pixels between each color along the main axis.
const double _kMainAxisSpacing = 4.0;

/// The number of logical pixels between each color along the cross axis.
const double _kCrossAxisSpacing = 4.0;

/// The ratio of the cross-axis to the main-axis extent of each color.
const double _kSizeRatio = 1.5;

/// The number of colors in one row along the main axis.
const int _kCrossAxisCount = 4;

/// The width of a secondary color box.
const double _secondaryColorBoxWidth =
    (_mainColorsBarWidth - (_kCrossAxisCount - 1) * _kCrossAxisSpacing) / 4;

/// The height of a secondary color box.
const double _secondaryColorBoxHeight = _secondaryColorBoxWidth / _kSizeRatio;

// widget sizes

/// The widget width base on main colors bar width and the margins.
const double kWidgetWidth = _mainColorsBarWidth + _kMarginSize * 2;

/// The widget height base on the 4 margins(there a re two between color rows),
/// the size of a primary box, two heights of the secondary box, and the cross
/// axis space between them.
const double kWidgetHeight = _kMarginSize * 4 +
    _kColorBoxSize +
    _secondaryColorBoxHeight * 2 +
    _kCrossAxisSpacing;

/// This sets the animation for both the selection frame and for the secondary
/// color shifting.
const int _kFrameAnimationDuration = 200;

class ColorPicker extends PickerBase<Color> {
  const ColorPicker({
    this.currentColor,
    this.elevation,
    this.onColor,
    this.type,
  })
      : super();

  /// The [Color] you want to initialize the picker with. If the color is not in
  /// the list then black is selected.
  final Color currentColor;

  /// The z-coordinate at which to place this widget. This controls the size
  /// of the shadow below the widget.
  final double elevation;

  /// You will be notified when the user chose a color.
  final ValueChanged<Color> onColor;

  /// The Material type of the picker.
  final MaterialType type;

  @override
  _ColorPickerState createState() => new _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker>
    with TickerProviderStateMixin {
  /// This is the color list that is displayed on the secondary row, and it
  /// updates on animation with the new colors gradually.
  List<Color> _lastColorList;

  /// This is the index at witch the color shifting of the second row is at. Once
  /// the shift is done this is equal to the length of the [_lastColorList].
  int _currentColorChangeIndex = 0;

  /// The index of the main color that is currently shown.
  int _lastKnownColorIndex = 0;

  /// The position at witch the selection frame is at.
  double _dragPosition = 0.0;

  double _frameWidth;
  double _frameBorderWidth;

  Color _selectedColor = Colors.black;

  @override
  void initState() {
    super.initState();

    _frameWidth = _kBaseFrameWidth * 2 + _kColorBoxSize;
    _frameBorderWidth = (_frameWidth - _kColorBoxSize) / 2;

    int i = 0;
    colorList.forEach((key, list) {
      int colorIndex = list.indexOf(widget.currentColor);
      if (colorIndex != -1) {
        _lastColorList = list.toList();
        _lastKnownColorIndex = i;
        _dragPosition = i * _kColorBoxSize;
        _selectedColor = widget.currentColor;
      }
      i++;
    });

    if (_lastColorList == null)
      _lastColorList = colorList[mainColors[0]].toList();
  }

  _onDragUpdate(DragUpdateDetails details, RenderFittedBox renderObject) {
    var localPosition = renderObject.globalToLocal(details.globalPosition);
    if (localPosition.dx <= 0) {
      setState(() => _dragPosition = 0.0);
      return;
    }

    if (localPosition.dx > renderObject.size.width - _kColorBoxSize) {
      setState(() => _dragPosition = renderObject.size.width - _kColorBoxSize);
      return;
    }

    setState(() => _dragPosition = localPosition.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    _lastKnownColorIndex = (_dragPosition / _kColorBoxSize).round();
    _moveFrameToPosition();
    _showColors();
  }

  void _moveFrameToPosition() {
    AnimationController controller = new AnimationController(
        duration: const Duration(milliseconds: _kFrameAnimationDuration),
        vsync: this);
    CurvedAnimation curve =
        new CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    double endPoint = _lastKnownColorIndex * _kColorBoxSize;
    Animation animation;
    animation = new Tween(begin: _dragPosition, end: endPoint).animate(curve)
      ..addListener(() {
        setState(() {
          _dragPosition = animation.value;
          if (controller.status == AnimationStatus.completed)
            controller.dispose();
        });
      });

    controller.forward();
  }

  void _mainColorSelected(Color color) {
    _dragPosition = _lastKnownColorIndex * _kColorBoxSize;
    _lastKnownColorIndex = mainColors.indexOf(color);
    _moveFrameToPosition();
    _showColors();
  }

  void _showColors() {
    AnimationController controller = new AnimationController(
        duration: const Duration(milliseconds: _kFrameAnimationDuration),
        vsync: this);

    Animation animation;
    animation =
        new Tween(begin: 0.0, end: _lastColorList.length).animate(controller)
          ..addListener(() {
            int position =
                (animation.value * _lastColorList.length / 10).ceil();
            if (position == _currentColorChangeIndex) return;

            setState(() => _currentColorChangeIndex = position);
          });

    controller.forward();
  }

  Widget _mainRow() {
    List<Widget> children = [];

    for (Color color in mainColors) {
      children.add(
        new GestureDetector(
          child: new Container(
            width: _kColorBoxSize,
            height: _kColorBoxSize,
            decoration: new BoxDecoration(
              color: color,
            ),
          ),
          onTap: () => _mainColorSelected(color),
        ),
      );
    }

    return new Row(children: children);
  }

  void _onColorSelected(Color color) {
    if (widget.onColor != null) widget.onColor(color);
    setState(() {
      _selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Color> currentColorList = colorList[mainColors[_lastKnownColorIndex]]
        .sublist(0, _currentColorChangeIndex);

    _lastColorList.replaceRange(0, _currentColorChangeIndex, currentColorList);

    List<Widget> children = <Widget>[];
    for (Color color in _lastColorList) {
      List<Widget> stackChildren = <Widget>[
        new InkWell(
          child: new Container(
            alignment: Alignment.center,
            decoration: new BoxDecoration(
              color: color,
              borderRadius: new BorderRadius.all(
                new Radius.circular(2.0),
              ),
              border: new Border.all(color: Colors.black12),
            ),
          ),
        ),
      ];

      if (color == _selectedColor) {
        stackChildren.add(
          new Container(
            decoration: new BoxDecoration(
                shape: BoxShape.circle, color: Colors.white70),
            child: new Icon(Icons.check),
            margin: new EdgeInsets.all(4.0),
          ),
        );
      }

      children.add(
        new GestureDetector(
          child: new Stack(
            children: stackChildren,
            alignment: new AlignmentDirectional(1.0, 1.0),
          ),
          onTap: () => _onColorSelected(color),
        ),
      );
    }

    MainColorsBox mainColorBox = new MainColorsBox(child: _mainRow());
    return new Container(
      width: kWidgetWidth,
      alignment: Alignment.center,
      height: kWidgetHeight,
      child: new Material(
        elevation: widget.elevation ?? 8.0,
        type: widget.type ?? MaterialType.card,
        child: new Column(
          children: <Widget>[
            new Container(
              padding: new EdgeInsets.all(_kMarginSize),
              child: new Stack(
                overflow: Overflow.visible,
                children: <Widget>[
                  mainColorBox,
                  new Positioned(
                    top: -_frameBorderWidth,
                    left: _dragPosition - _frameBorderWidth,
                    child: new GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        _onDragUpdate(details, mainColorBox.renderObject);
                      },
                      onHorizontalDragEnd: _onDragEnd,
                      child: new Material(
                        elevation: 8.0,
                        color: new Color(0x00000000),
                        child: new Image.asset(
                          "res/images/placer.png",
                          package: "material_color_picker",
                          width: _frameWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            new Container(
              width: mainColors.length * _kColorBoxSize,
              margin: new EdgeInsets.all(16.0),
              child: new GridView.count(
                shrinkWrap: true,
                children: children,
                mainAxisSpacing: _kMainAxisSpacing,
                crossAxisSpacing: _kCrossAxisSpacing,
                childAspectRatio: _kSizeRatio,
                crossAxisCount: _kCrossAxisCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// We need access to the render object to convert the global position into
/// local position.
class MainColorsBox extends SingleChildRenderObjectWidget {
  MainColorsBox({Key key, Widget child}) : super(key: key, child: child);

  RenderFittedBox renderObject;

  @override
  RenderFittedBox createRenderObject(BuildContext context) {
    renderObject = new RenderFittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      textDirection: Directionality.of(context),
    );

    return renderObject;
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBox renderObject) {
    renderObject
      ..fit = BoxFit.contain
      ..alignment = Alignment.center
      ..textDirection = Directionality.of(context);
    this.renderObject = renderObject;
  }
}
