import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ExpansionPanelList, ExpansionPanel;
import 'package:material_pickers/src/font/expansion.dart';
import 'package:material_pickers/src/picker.dart';

const double _kMaxHeight = 384.0;
const double _kMaxWidth = 256.0;

/// Signature for [FontPicker.previewBuilder] callback.
///
/// Here you can customize the preview text for the font weight.
typedef String PreviewBuilder(FontValue value);

const FontItem defaultFont = const FontItem(
  name: "Roboto",
  weights: const <FontWeight>[
    FontWeight.w100,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w700,
    FontWeight.w900
  ],
);

const FontValue defaultValue =
    const FontValue(font: "Roboto", weight: FontWeight.w400);

@immutable
class FontItem {
  const FontItem({@required this.name, @required this.weights});

  /// The family font name as declared in pubspec.yaml at the family field.
  final String name;

  /// All the weights that this font supports. If the provided weights don't
  /// match with the font then the platform will pick the closest, witch will
  /// not be what you are expecting.
  final List<FontWeight> weights;

  @override
  String toString() => "FontItem {name: \"$name\", weights: \"$weights\"}";
}

@immutable
class FontValue {
  const FontValue({@required this.font, @required this.weight});

  /// The font family that was selected.
  final String font;

  /// The weight that that was selected.
  final FontWeight weight;

  @override
  String toString() => "FontValue {font: \"$font\", weight: \"$weight\"}";
}

class FontPicker extends PickerBase<FontValue> {
  const FontPicker({
    this.fonts,
    this.currentFont,
    this.onFont,
    this.previewBuilder,
    this.elevation,
    this.type,
  });

  /// A list of fonts that will be displayed along with their weights
  final List<FontItem> fonts;

  /// The font that is currently selected.
  final FontValue currentFont;

  /// The callback that will be triggered once a font is selected.
  final ValueChanged<FontValue> onFont;

  /// This will be called to allow you to customise the preview text for each
  /// font weight.
  final PreviewBuilder previewBuilder;

  /// The elevation of the [Material]
  final double elevation;

  /// The type of the [Material]
  ///
  /// see: [MaterialType]
  final MaterialType type;

  @override
  _FontPickerState createState() => new _FontPickerState();
}

class _FontPickerState extends State<FontPicker> {
  FontValue _selectedFont;

  @override
  void initState() {
    super.initState();
    _selectedFont = widget.currentFont ?? defaultValue;
  }

  void _onFont(FontValue font) {
    if (widget.onFont != null) widget.onFont(font);
    setState(() => _selectedFont = font);
  }

  @override
  Widget build(BuildContext context) {
    List<ExpansionPanel> panels = <ExpansionPanel>[];
    for (FontItem font in widget.fonts) {
      bool isSelected = _selectedFont.font == font.name;

      List<ExpansionPanelItem<FontValue>> weights = [];
      for (FontWeight weight in font.weights) {
        String weightPreview;

        if (widget.previewBuilder != null) {
          weightPreview = widget
              .previewBuilder(new FontValue(font: font.name, weight: weight));
        } else {
          weightPreview = weight.toString();
        }

        weights.add(
          new ExpansionPanelItem(
            widget: new Text(
              weightPreview,
              style: new TextStyle(
                fontFamily: font.name,
                fontWeight: weight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            isSelected: isSelected && weight == _selectedFont.weight,
            value: new FontValue(
              font: font.name,
              weight: weight,
            ),
          ),
        );
      }

      panels.add(
        new ExpansionPanel<FontValue>(
          headerBuilder: (context) => new Text(
                font.name,
                style: new TextStyle(fontFamily: font.name),
                overflow: TextOverflow.ellipsis,
              ),
          children: weights,
          isExpanded: isSelected,
        ),
      );
    }

    return new Container(
      constraints: new BoxConstraints(
        maxWidth: _kMaxWidth,
        maxHeight: _kMaxHeight,
      ),
      alignment: Alignment.center,
      child: new Material(
        elevation: widget.elevation ?? 8.0,
        type: widget.type ?? MaterialType.card,
        child: new ExpansionListWithSelection<FontValue>(
          children: panels,
          onValue: _onFont,
        ),
      ),
    );
  }
}