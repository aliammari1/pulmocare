import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/screens/entry_view.dart';

void main() {
  testWidgets('shows PulmoCare role choices', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EntryView()));

    expect(find.text('PulmoCare'), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Radiologist'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
  });
}
