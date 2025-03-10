import 'package:flutter/material.dart';

class MedicalReport {
  final String id;
  final String title;
  final String content;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Annotation> annotations;

  MedicalReport({
    required this.id,
    required this.title,
    this.content = '',
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.annotations = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    return MedicalReport(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      annotations: json['annotations'] != null
          ? (json['annotations'] as List)
              .map((i) => Annotation.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'annotations': annotations.map((e) => e.toJson()).toList(),
    };
  }
}

class Annotation {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final int color;

  Annotation({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      color: json['color'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
    };
  }

  Color get uiColor {
    final a = (color >> 24) & 0xff;
    final r = (color >> 16) & 0xff;
    final g = (color >> 8) & 0xff;
    final b = color & 0xff;
    return Color.fromARGB(a, r, g, b);
  }
}

class DrawingPoint {
  final double x;
  final double y;
  final int color;
  final double strokeWidth;

  DrawingPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.strokeWidth,
  });

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      x: json['x'] ?? 0.0,
      y: json['y'] ?? 0.0,
      color: json['color'] ?? Colors.black.value,
      strokeWidth: json['strokeWidth'] ?? 3.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'color': color,
      'strokeWidth': strokeWidth,
    };
  }
}
