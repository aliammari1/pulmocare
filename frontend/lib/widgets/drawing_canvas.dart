import 'package:flutter/material.dart';

class CanvasPoint {
  final Offset offset;
  final Paint paint;

  CanvasPoint({
    required this.offset,
    required this.paint,
  });
}

class DrawingCanvas extends StatefulWidget {
  final bool isEnabled;
  final List<CanvasPoint> points;
  final Function(List<CanvasPoint>)? onDrawingComplete;
  final double strokeWidth;
  final Color strokeColor;

  const DrawingCanvas({
    super.key,
    this.isEnabled = true,
    this.points = const [],
    this.onDrawingComplete,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<CanvasPoint> _points = [];
  final double _appBarHeight = 56.0; // Made final

  @override
  void initState() {
    super.initState();
    _points = widget.points;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset point = box.globalToLocal(details.globalPosition);
          point = Offset(point.dx, point.dy - _appBarHeight);

          final paint = Paint()
            ..color = widget.strokeColor
            ..strokeWidth = widget.strokeWidth
            ..strokeCap = StrokeCap.round;

          _points = List.from(_points)
            ..add(CanvasPoint(offset: point, paint: paint));
        });
      },
      onPanEnd: (details) {
        setState(() {
          _points = List.from(_points)
            ..add(CanvasPoint(offset: Offset.infinite, paint: Paint()));
        });
        widget.onDrawingComplete?.call(_points);
      },
      child: CustomPaint(
        painter: DrawingPainter(points: _points),
        size: Size.infinite,
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<CanvasPoint> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i + 1].offset != Offset.infinite) {
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
