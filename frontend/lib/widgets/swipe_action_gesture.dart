import 'package:flutter/material.dart';

class SwipeActionGesture extends StatefulWidget {
  final Widget child;
  final Function() onSwipeLeft;
  final Function() onSwipeRight;
  final Color leftColor;
  final Color rightColor;
  final IconData leftIcon;
  final IconData rightIcon;

  const SwipeActionGesture({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.leftColor = Colors.red,
    this.rightColor = Colors.green,
    this.leftIcon = Icons.delete,
    this.rightIcon = Icons.check,
  });

  @override
  State<SwipeActionGesture> createState() => _SwipeActionGestureState();
}

class _SwipeActionGestureState extends State<SwipeActionGesture> {
  double _dragExtent = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          _buildBackground(),
          _buildSlideableChild(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final dragValue = _dragExtent.abs() / context.size!.width;
    final color = _dragExtent > 0 ? widget.rightColor : widget.leftColor;
    final icon = _dragExtent > 0 ? widget.rightIcon : widget.leftIcon;
    final alignment = _dragExtent > 0
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;

    return Container(
      color: color.withAlpha((dragValue * 255).round()),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(
            icon,
            color: Colors.white.withAlpha((dragValue * 255).round()),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideableChild() {
    return Transform.translate(
      offset: Offset(_dragExtent, 0),
      child: widget.child,
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragExtent = 0;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent =
          _dragExtent.clamp(-context.size!.width, context.size!.width);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final threshold = context.size!.width * 0.4;
    if (_dragExtent.abs() > threshold) {
      if (_dragExtent > 0) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    }
    setState(() {
      _dragExtent = 0;
    });
  }
}
