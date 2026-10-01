import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buoi06_multimedia/main.dart';

void main() {
  testWidgets('App loads exercise directory smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MultimediaHubApp());

    // Verify directory screen is loaded
    expect(find.text('BÀI 06: MULTIMEDIA'), findsOneWidget);
    expect(find.text('Bài tập 1: Media Picker App'), findsOneWidget);
    expect(find.text('Bài tập 2: Photo Capture & Preview'), findsOneWidget);
    expect(find.text('Bài tập 3: SMS & Contacts Reader'), findsOneWidget);
  });
}
