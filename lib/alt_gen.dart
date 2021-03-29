import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_noise/fast_noise.dart';

class AltGen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final graphr = GraphController();
    return GraphScreen(graphr);
  }
}

final size = ui.window.physicalSize / ui.window.devicePixelRatio;

GlobalKey globalKey = GlobalKey();

const double dyG = 3.0;
const double cG = 0.04;

final random = Random();

const black = const Color(0xff000000);
const white = const Color(0xffFFFFFF);

class Config {
  final Color backgroundColor;
  final Color fillColor;
  final Color strokeColor;
  final bool applyForce;
  final bool fadeColor;
  final bool generative;

  Config(
      [this.backgroundColor = Colors.black,
      this.fillColor = white,
      this.strokeColor = Colors.transparent,
      this.applyForce = false,
      this.fadeColor = true,
      this.generative = false]);

  copyWith({
    Color backgroundColor,
    Color fillColor,
    Color strokeColor,
    bool applyForce,
    bool fadeColor,
    bool generative,
  }) =>
      Config(
        backgroundColor ?? this.backgroundColor,
        fillColor ?? this.fillColor,
        strokeColor ?? this.strokeColor,
        applyForce ?? this.applyForce,
        fadeColor ?? this.fadeColor,
        generative ?? this.generative,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Config &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          fillColor == other.fillColor &&
          strokeColor == other.strokeColor &&
          applyForce == other.applyForce &&
          fadeColor == other.fadeColor &&
          generative == other.generative;

  @override
  int get hashCode =>
      backgroundColor.hashCode ^
      fillColor.hashCode ^
      strokeColor.hashCode ^
      applyForce.hashCode ^
      fadeColor.hashCode ^
      generative.hashCode;
}

class Node {
  static final whiteFill = Paint()..color = Color(0x90FFFFFF);

  Offset gravity = Offset(0, dyG);

  Offset offset;

  Color color;

  Color strokeColor;

  final bool applyForce;

  bool fadeColor;

  bool _freezed = false;

  bool generative;

  double get x => offset.dx;
  double get y => offset.dy;

  Node(this.offset, this.color, this.strokeColor, this.applyForce,
      this.fadeColor, this.generative);

  update() {
    if (_freezed) return;

    if (applyForce) {
      offset += gravity;
      gravity *= 1 + cG;
    }

    if (fadeColor) {
      final hsl = HSLColor.fromColor(color);
      color = hsl.withLightness(max(hsl.lightness - 0.0075, 0)).toColor();
      color = color.withOpacity(max(color.opacity - 0.01, 0));
    }
  }

  freeze() => _freezed = true;

  void draw(Canvas canvas) {
    //canvas.drawCircle(offset, 2, whiteFill);
  }
}

class Line {
  final List<Node> points;

  static final paint = Paint()..color = const Color(0xFF424242);

  Line(this.points);

  void draw(Canvas canvas) {
    //canvas.drawLine(points.first.offset, points.last.offset, paint);
  }
}

class Polygon {
  final List<Node> nodes;
  final double distance;

  final List<Offset> previousPoints;

  final Color fillColor;
  final Color strokeColor;
  final Size size;
  final bool generative;

  List<Offset> get points {
    // Fix desktop
    final width = Offset(0, 30) * distance / 100;
    final c0 = nodes.first.offset - width;
    final c1 = nodes.last.offset - width;
    final c2 = nodes.last.offset + width;
    final c3 = nodes.first.offset + width;
    return [c0, c1, c2, c3];
  }

  Polygon(this.nodes,
      {this.previousPoints,
      this.fillColor,
      this.strokeColor,
      this.size,
      this.generative})
      : distance = (nodes.first.offset - nodes.last.offset).distance;

  void draw(Canvas canvas) {
    final width = Offset(0, 30) * distance / 100;

    var paint;
    final c0 = previousPoints.first;
    final c1 = nodes.last.offset - width;
    final c2 = nodes.last.offset + width;
    final c3 = previousPoints.last;

    var path = Path()
      ..moveTo(c0.dx, c0.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c0.dx, c0.dy);

    paint = Paint()..color = fillColor;

    /* if (generative) {
      paint = Paint()
        ..color = fillColor
        ..blendMode = BlendMode.difference;
    } else {
      paint = Paint()..color = fillColor;
    } */

    canvas.drawPath(path, paint);
  }
}

class GraphController {
  GraphController() {
    _config = Config();
    _configStreamer.stream.listen((c) => _config = c);
  }

  List<List<Node>> polygons = [];

  StreamController<List<List<Node>>> _polygonStreamer = StreamController();

  Stream<List<List<Node>>> get polygon$ => _polygonStreamer.stream;

  List<Node> nodes = [];

  get isEmpty => nodes.isEmpty && polygons.isEmpty;

  Config _config;

  Config get config => _config;

  set config(Config value) {
    _config = value;
    _configStreamer.add(value);
  }

  StreamController<Config> _configStreamer =
      StreamController<Config>.broadcast()..add(Config());

  Stream<Config> get config$ => _configStreamer.stream;

  get backgroundColor => _config.backgroundColor;

  set backgroundColor(Color backgroundColor) =>
      _configStreamer.add(_config.copyWith(backgroundColor: backgroundColor));

  Color get fillColor => _config.fillColor;

  set fillColor(Color fillColor) =>
      _configStreamer.add(_config.copyWith(fillColor: fillColor));

  Color get strokeColor => _config.strokeColor;

  set strokeColor(Color strokeColor) =>
      _configStreamer.add(_config.copyWith(strokeColor: strokeColor));

  bool get applyForce => _config.applyForce;

  set applyForce(bool applyForce) =>
      _configStreamer.add(_config.copyWith(applyForce: applyForce));

  bool get fadeColor => _config.fadeColor;

  set fadeColor(bool fadeColor) =>
      _configStreamer.add(_config.copyWith(fadeColor: fadeColor));

  bool get generative => _config.generative;

  set generative(bool generative) =>
      _configStreamer.add(_config.copyWith(generative: generative));

  void dispose() {
    _configStreamer.close();
    _polygonStreamer.close();
  }

  void addPoint(Offset offset) {
    nodes.add(Node(offset, fillColor, strokeColor, config.applyForce,
        config.fadeColor, generative));
  }

  void update(Size size) {
    final filteredNodes = <Node>[];
    for (final node in nodes) {
      if (node.offset.dy < size.height) {
        node.update();
        filteredNodes.add(node);
      }
      nodes = filteredNodes;
    }
  }

  void clear() {
    nodes = [];
    polygons = [];
    _polygonStreamer.add(polygons);
  }

  void freeze() {
    polygons.add([for (final node in nodes) node..freeze()]);
    _polygonStreamer.add(polygons);
    nodes = [];
  }

  void undo() {
    if (polygons.isEmpty) return;

    polygons.removeLast();
    _polygonStreamer.add(polygons);
  }
}

class GraphScreen extends StatelessWidget {
  final GraphController controller;

  const GraphScreen(this.controller, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = MediaQuery.of(context).size.width <= 900;
    final luminance = controller.config.backgroundColor.computeLuminance();
    final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
    final iconColor =
        brightness == Brightness.light ? Colors.black54 : Colors.white54;
    return Scaffold(
      drawer: Platform.isIOS
          ? Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
              ),
              child:
                  SettingsDrawer(controller: controller, iconColor: iconColor),
            )
          : null,
      body: Stack(
        children: <Widget>[
          Graph(this.controller),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Appbar(controller: controller),
          ),
          OnBoarding(isMobileScreen ? 'draw something' : 'draw something'),
        ],
      ),
    );
  }
}

class OnBoarding extends StatefulWidget {
  final String content;

  OnBoarding(this.content);

  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  double opacity = 1;

  @override
  void initState() {
    Timer(Duration(seconds: 3), () => setState(() => opacity = 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(seconds: 1),
      opacity: opacity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.black54,
          child: Text(
            widget.content,
            style: GoogleFonts.raleway(
                color: Colors.white, fontWeight: FontWeight.w200),
          ),
        ),
      ),
    );
  }
}

class Graph extends StatelessWidget {
  final GraphController controller;

  Graph(this.controller);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.data.keyLabel == ' ') controller.freeze();
      },
      child: StreamBuilder<Color>(
          initialData: Colors.black,
          stream:
              controller.config$.map<Color>((Config c) => c.backgroundColor),
          builder: (context, snapshot) {
            return Container(
              constraints: BoxConstraints.expand(),
              color: snapshot.data ?? Colors.black,
              child: _buildCanvasStack(size),
            );
          }),
    );
  }

  Stack _buildCanvasStack(Size size) {
    return Stack(
      children: <Widget>[
        StreamBuilder<List<List<Node>>>(
          stream: controller.polygon$,
          builder: (context, snapshot) => BackgroundCanvas(
            freezedNodes: snapshot.data ?? [],
            size: size,
          ),
        ),
        LiveCanvas(size: size, controller: controller),
      ],
    );
  }
}

class LiveCanvas extends StatefulWidget {
  final Size size;
  final GraphController controller;

  const LiveCanvas({
    Key key,
    @required this.size,
    @required this.controller,
  }) : super(key: key);

  @override
  _LiveCanvasState createState() => _LiveCanvasState();
}

class _LiveCanvasState extends State<LiveCanvas> with TickerProviderStateMixin {
  AnimationController anim;
  Offset autoPoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    anim = AnimationController(vsync: this, duration: Duration(seconds: 1))
      ..addListener(() {
        widget.controller.update(widget.size);
        if (widget.controller.nodes.isEmpty) anim.stop();
      })
      ..forward()
      ..repeat();
    super.initState();
  }

  double nextX;
  double nextY;

  void _generative(position) {
    var perlinNoise = PerlinNoise();
    var noise = perlinNoise.getPerlin2(position.dx, position.dy);
    var noise2 = perlinNoise.getPerlin2(position.dy, position.dx);

    nextX = position.dx + (noise * position.dx);
    nextY = position.dy + (noise2 * position.dy);

    widget.controller.addPoint(Offset(nextX, nextY));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onHover: widget.controller.config.applyForce
            ? (event) {
                widget.controller.addPoint(event.localPosition);
                if (widget.controller.generative)
                  _generative(event.localPosition);
                anim
                  ..forward()
                  ..repeat();
              }
            : null,
        onEnter: (event) {
          widget.controller.addPoint(event.localPosition);
          if (widget.controller.generative) _generative(event.localPosition);
          anim
            ..forward()
            ..repeat();
        },
        child: GestureDetector(
            onTap: widget.controller.freeze,
            onPanUpdate: (event) {
              widget.controller.addPoint(event.localPosition);
              if (widget.controller.generative)
                _generative(event.localPosition);
              anim
                ..forward()
                ..repeat();
            },
            onPanEnd: widget.controller.config.applyForce
                ? null
                : (_) => widget.controller.freeze(),
            child: AnimatedBuilder(
              animation: anim,
              builder: (c, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: widget.size,
                    painter: LivePainter(widget.controller.nodes),
                  ),
                );
              },
            )));
  }
}

class LivePainter extends CustomPainter {
  List<Node> nodes;

  LivePainter(this.nodes);

  static final Paint dummyRectPaint = Paint()
    ..color = Color.fromARGB(0, 255, 255, 255)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, dummyRectPaint);

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.offset.dy < size.height) node.draw(canvas);

      if (i > 0) {
        // final l = Line([nodes[i - 1], nodes[i]]);
        // l.draw(canvas);
      }

      if (i > 2) {
        final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
        final r = Polygon(
          [nodes[i - 1], nodes[i]],
          previousPoints: [prevR.points[1], prevR.points[2]],
          fillColor: nodes[i].color,
          strokeColor: nodes[i].strokeColor,
          size: size,
          generative: nodes[i].generative,
        );
        r.draw(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(LivePainter oldDelegate) {
    return true;
  }
}

class BackgroundCanvas extends StatelessWidget {
  final List<List<Node>> freezedNodes;
  final Size size;

  const BackgroundCanvas({Key key, this.freezedNodes, this.size})
      : super(key: key);

  get src => null;

  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: globalKey,
      child: CustomPaint(
        size: size,
        isComplex: true,
        willChange: false,
        painter: BackgroundPainter(freezedNodes),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  List<List<Node>> polygons;

  BackgroundPainter(this.polygons);

  @override
  void paint(Canvas canvas, Size size) {
    var bg = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset(0, 0) & Size(size.width, size.height), bg);

    polygons.forEach(
      (nodes) {
        for (int i = 0; i < nodes.length; i++) {
          if (i > 2) {
            final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
            final r = Polygon(
              [nodes[i - 1], nodes[i]],
              previousPoints: [prevR.points[1], prevR.points[2]],
              fillColor: nodes[i].color,
              strokeColor: nodes[i].strokeColor,
              size: size,
              generative: nodes[i].generative,
            );
            r.draw(canvas);
          }
        }
      },
    );
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}

class Appbar extends StatefulWidget {
  final GraphController controller;

  const Appbar({Key key, this.controller}) : super(key: key);

  @override
  _AppbarState createState() => _AppbarState();
}

class _AppbarState extends State<Appbar> {
  OverlayEntry _currentEntry;

  @override
  void dispose() {
    if (_currentEntry != null) {
      _currentEntry.remove();
      _currentEntry = null;
    }
    super.dispose();
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  void _updateEntry(Future<OverlayEntry> entry) async {
    _clearOverlay();
    if (entry != null) _currentEntry = await entry;

    setState(() {});
  }

  void _clearOverlay() {
    if (_currentEntry != null) {
      _currentEntry.remove();
      _currentEntry = null;
    }
  }

  Color _genIconColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = MediaQuery.of(context).size.width <= 900;
    final controller = widget.controller;
    return StreamBuilder<Config>(
      initialData: Config(),
      stream: controller.config$,
      builder: (c, snapshot) {
        final config = snapshot.data ?? Config();
        final luminance = config.backgroundColor.computeLuminance();
        final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
        final iconColor =
            brightness == Brightness.light ? Colors.black54 : Colors.white54;
        return Container(
          color: Color(0x50333333),
          height: 70,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (Platform.isIOS)
                  IconButton(
                    icon: Icon(Icons.menu, color: iconColor),
                    onPressed: _openDrawer,
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                ),
                SettingsBar(
                  direction: Axis.horizontal,
                  config: config,
                  controller: controller,
                ),
                Row(
                  children: <Widget>[
                    Tooltip(
                      message: 'Undo',
                      child: IconButton(
                        icon: Icon(Icons.undo, color: iconColor),
                        onPressed: controller.undo,
                      ),
                    ),
                    Tooltip(
                      message: 'Clear',
                      child: IconButton(
                        icon: Icon(Icons.clear, color: iconColor),
                        /* onPressed: () {
                          setState(() {
                            //widget.controller.clear;
                            widget.controller.applyForce = true;
                          });
                        }, */
                        onPressed: controller.clear,
                      ),
                    ),
                    Tooltip(
                      message: 'Generative',
                      child: IconButton(
                          icon: Icon(Icons.graphic_eq, color: _genIconColor),
                          onPressed: () {
                            setState(() {
                              if (_genIconColor == Colors.grey) {
                                _genIconColor = Colors.tealAccent;
                                //_currentEntry = null;
                                widget.controller.generative = true;
                              } else {
                                _genIconColor = Colors.grey;
                                //_currentEntry = null;
                                widget.controller.generative = false;
                              }
                            });
                          }),
                    ),
                    ColorSelector(
                      color: config.fillColor,
                      brightness: brightness,
                      label: '',
                      onColorSelection: (c) {
                        _currentEntry = null;
                        widget.controller.fillColor = c;
                      },
                      onOpenOverlay: (entry) => _updateEntry(entry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ColorSelector extends StatefulWidget {
  final Color color;

  final String label;

  final Brightness brightness;

  final ValueChanged<Color> onColorSelection;
  final ValueChanged<Future<OverlayEntry>> onOpenOverlay;

  const ColorSelector({
    Key key,
    @required this.color,
    @required this.brightness,
    @required this.label,
    this.onColorSelection,
    this.onOpenOverlay,
  }) : super(key: key);

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Future<OverlayEntry> colorPicker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (widget.color != Colors.transparent)
          InkWell(
            onTap: () {
              if (colorPicker != null) {
                widget.onOpenOverlay(null);
                colorPicker = null;
                setState(() {});
              } else {
                colorPicker = _openColorPicker(context);
                widget.onOpenOverlay(colorPicker);
              }
            },
            child: Container(
              margin: EdgeInsets.all(8),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                color: widget.color,
              ),
            ),
          ),
      ],
    );
  }

  Future<OverlayEntry> _openColorPicker(BuildContext context) async {
    final renderer = context.findRenderObject() as RenderBox;
    final left =
        renderer.size.bottomLeft(renderer.localToGlobal(Offset.zero)).dx;

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _buildColorPicker(
        context,
        left,
        MediaQuery.of(context).size.width,
        () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
    return overlayEntry;
  }

  Widget _buildColorPicker(
    BuildContext context,
    double left,
    double width,
    VoidCallback onSelect,
  ) =>
      Positioned(
        top: 70.0,
        right: 18.0,
        //left: min(max(left - 80, 0), width - 200),
        child: _ColorPickerGrid(
          currentColor: widget.color,
          onSelect: () {
            onSelect();
            colorPicker = null;
            setState(() {});
          },
          onColorSelection: (c) {
            widget.onColorSelection(c);
            colorPicker = null;
            setState(() {});
          },
        ),
      );
}

class _ColorPickerGrid extends StatefulWidget {
  final ValueChanged<Color> onColorSelection;
  final VoidCallback onSelect;
  final Color currentColor;

  const _ColorPickerGrid({
    Key key,
    this.onColorSelection,
    this.onSelect,
    this.currentColor,
  }) : super(key: key);

  @override
  __ColorPickerGridState createState() => __ColorPickerGridState();
}

class __ColorPickerGridState extends State<_ColorPickerGrid> {
  Color currentColor;

  @override
  void initState() {
    currentColor = widget.currentColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      child: Material(
        color: Color(0x50333333),
        child: MouseRegion(
          onExit: (_) => widget.onSelect(),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 1,
            children: [...Colors.accents, Colors.white, Colors.black]
                .map((c) => InkWell(
                      onTap: () {
                        widget.onSelect();
                        widget.onColorSelection(c);
                      },
                      child: Container(
                        margin: EdgeInsets.all(
                            c.value == currentColor.value ? 4 : 8),
                        width: c.value == currentColor.value ? 8 : 18,
                        height: c.value == currentColor.value ? 8 : 18,
                        color: c,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class SettingsBar extends StatefulWidget {
  final Axis direction;
  final Config config;
  final GraphController controller;

  const SettingsBar(
      {Key key, this.direction = Axis.vertical, this.config, this.controller})
      : super(key: key);

  @override
  _SettingsBarState createState() => _SettingsBarState();
}

class _SettingsBarState extends State<SettingsBar> {
  OverlayEntry _currentEntry;

  @override
  void dispose() {
    if (_currentEntry != null) {
      _currentEntry.remove();
      _currentEntry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: widget.direction,
      crossAxisAlignment: widget.direction == Axis.vertical
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
    );
  }
}

Future<void> _save() async {
  RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
  ui.Image image = await boundary.toImage();
  ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  Uint8List pngBytes = byteData.buffer.asUint8List();

  if (!(await Permission.storage.status.isGranted))
    await Permission.storage.request();

  final result = await ImageGallerySaver.saveImage(Uint8List.fromList(pngBytes),
      quality: 100, name: "canvas_image");
  print(result);
}

Future<void> _hideTools() async {}

class SettingsDrawer extends StatefulWidget {
  final GraphController controller;

  final Color iconColor;

  SettingsDrawer({Key key, this.controller, this.iconColor}) : super(key: key);

  @override
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            StreamBuilder<bool>(
                initialData: true,
                stream: widget.controller.config$
                    .map((c) => c.strokeColor != Colors.transparent),
                builder: (context, snapshot) {
                  return Column(
                    children: <Widget>[],
                  );
                }),
            TextButton(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'export',
                        style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w300),
                      ))),
              onPressed: () {
                setState(() {
                  _save();
                });
              },
            ),
            /* TextButton(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'hide tools',
                        style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w300),
                      ))),
              onPressed: () {
                setState(() {
                  _hideTools();
                });
              },
            ), */
          ],
        ),
      ),
    );
  }
}
