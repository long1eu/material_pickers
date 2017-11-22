import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const double _kIconSize = 24.0;
const double _kIconMargin = 16.0;
const double _kRowHeight = _kIconSize + 2 * _kIconMargin;

typedef void ExpansionPanelCallback(int panelIndex, bool isExpanded);

typedef Widget ExpansionPanelHeaderBuilder(
    BuildContext context, bool isExpanded);

class _SaltedKey<S, V> extends LocalKey {
  const _SaltedKey(this.salt, this.value);

  final S salt;
  final V value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final _SaltedKey<S, V> typedOther = other;
    return salt == typedOther.salt && value == typedOther.value;
  }

  @override
  int get hashCode => hashValues(runtimeType, salt, value);

  @override
  String toString() {
    final String saltString = S == String ? '<\'$salt\'>' : '<$salt>';
    final String valueString = V == String ? '<\'$value\'>' : '<$value>';
    return '[$saltString $valueString]';
  }
}

class ExpansionPanelItem<T> {
  ExpansionPanelItem({
    @required this.widget,
    @required this.isSelected,
    this.value,
  });

  final Widget widget;

  final bool isSelected;

  final T value;
}

class ExpansionPanel<T> {
  ExpansionPanel({
    @required this.headerBuilder,
    @required this.children,
    this.isExpanded: false,
  })
      : assert(headerBuilder != null),
        assert(children.isNotEmpty),
        assert(isExpanded != null);

  final WidgetBuilder headerBuilder;

  final List<ExpansionPanelItem<T>> children;

  bool isExpanded;
}

class ExpansionListWithSelection<T> extends StatefulWidget {
  const ExpansionListWithSelection(
      {Key key,
      this.children: const <ExpansionPanel>[],
      this.onValue,
      this.animationDuration: kThemeAnimationDuration})
      : assert(children != null),
        assert(animationDuration != null),
        super(key: key);

  final List<ExpansionPanel> children;

  final ValueChanged<T> onValue;

  final Duration animationDuration;

  @override
  _ExpansionPanelListWithSelectionState<T> createState() =>
      new _ExpansionPanelListWithSelectionState<T>();
}

class _ExpansionPanelListWithSelectionState<T>
    extends State<ExpansionListWithSelection<T>> {
  void _setSelectedAndCloseOthers(ExpansionPanel selected) {
    widget.children.forEach((item) {
      if (item != selected) item.isExpanded = false;
    });
    selected.isExpanded = !selected.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];

    widget.children.forEach((item) => print(item.isExpanded));

    for (int index = 0; index < widget.children.length; index += 1) {
      ExpansionPanel currentPanel = widget.children[index];

      if (currentPanel.isExpanded &&
          index != 0 &&
          !widget.children[index - 1].isExpanded)
        items.add(
          new MaterialGap(
            key: new _SaltedKey<BuildContext, int>(context, index * 2 - 1),
          ),
        );

      List<Widget> panelChildren = [];
      for (ExpansionPanelItem item in currentPanel.children) {
        List<Widget> weightList = [
          new InkWell(
            onTap: () {
              if (widget.onValue != null) widget.onValue(item.value);
            },
            child: new Container(
              height: _kRowHeight,
              margin: new EdgeInsets.only(
                left: 56.0,
                right: 56.0,
              ),
              alignment: Alignment.centerLeft,
              child: item.widget,
            ),
          ),
        ];

        if (item.isSelected) {
          weightList.add(
            new Container(
              margin: new EdgeInsets.all(_kIconMargin),
              child: new Icon(
                Icons.check,
                size: _kIconSize,
                color: Colors.black,
              ),
            ),
          );
        }

        panelChildren.add(new Stack(children: weightList));
      }

      items.add(
        new MaterialSlice(
          key: new _SaltedKey<BuildContext, int>(context, index * 2),
          child: new Column(
            children: <Widget>[
              new AnimatedContainer(
                duration: widget.animationDuration,
                curve: Curves.fastOutSlowIn,
                child: new SizedBox(
                  height: _kRowHeight,
                  child: new InkWell(
                    onTap: () {
                      setState(() => _setSelectedAndCloseOthers(currentPanel));
                    },
                    child: new Container(
                      margin: new EdgeInsets.only(
                        left: 56.0,
                        right: 56.0,
                      ),
                      alignment: Alignment.centerLeft,
                      child: currentPanel.headerBuilder(context),
                    ),
                  ),
                ),
              ),
              new AnimatedCrossFade(
                firstChild: new Container(height: 0.0),
                secondChild: new Column(
                  children: panelChildren,
                ),
                firstCurve:
                    const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
                secondCurve:
                    const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
                sizeCurve: Curves.fastOutSlowIn,
                crossFadeState: currentPanel.isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: widget.animationDuration,
              ),
            ],
          ),
        ),
      );

      if (currentPanel.isExpanded && index != widget.children.length - 1)
        items.add(
          new MaterialGap(
            key: new _SaltedKey<BuildContext, int>(context, index * 2 + 1),
          ),
        );
    }

    return new SingleChildScrollView(
      child: new MergeableMaterial(
        hasDividers: true,
        children: items,
      ),
    );
  }
}
