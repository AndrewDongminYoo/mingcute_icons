// Tests adapted from https://github.com/fluttercommunity/font_awesome_flutter/blob/master/test/fa_icon_test.dart
// Copyright 2014 The Flutter Authors. All rights reserved.

// 🎯 Dart imports:
import 'dart:ui' show PictureRecorder;

// 🐦 Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

// 🌎 Project imports:
import 'package:flutter_mingcute/flutter_mingcute.dart';

void main() {
  testWidgets('Converted font styles render distinct nonempty glyphs', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final pixels = <List<int>>[];
      for (final entry in {
        MingCuteIcons.home1Fill: 'assets/mingcute.ttf',
        MingCuteIcons.home1Line: 'assets/mingcute_line.ttf',
      }.entries) {
        final icon = entry.key;
        final loader = FontLoader(
          'packages/${icon.fontPackage}/${icon.fontFamily}',
        )..addFont(rootBundle.load(entry.value));
        await loader.load();
        final painter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              fontSize: 48,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final recorder = PictureRecorder();
        painter.paint(Canvas(recorder), Offset.zero);
        final picture = recorder.endRecording();
        final image = await picture.toImage(64, 64);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        expect(bytes.where((value) => value != 0), isNotEmpty);
        pixels.add(bytes.toList());
        image.dispose();
        picture.dispose();
        painter.dispose();
      }
      expect(pixels[0], isNot(orderedEquals(pixels[1])));
    });
  });

  testWidgets('Can set opacity for an Icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(color: Color(0xFF666666), opacity: 0.5),
          child: Icon(MingCuteIcons.addFill),
        ),
      ),
    );
    final text = tester.widget<RichText>(find.byType(RichText));

    // Color opacity is stored in 8-bit alpha; 0.5 rounds to 128/255 (0.50196..),
    // so exact 0.5 equality is flaky across framework/color internals.
    expect(text.text.style!.color!.r, closeTo(0.4, 1e-6));
    expect(text.text.style!.color!.g, closeTo(0.4, 1e-6));
    expect(text.text.style!.color!.b, closeTo(0.4, 1e-6));
    expect(text.text.style!.color!.a, closeTo(128 / 255, 1e-6));
  });

  testWidgets('Icon sizing - no theme, default size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Icon(MingCuteIcons.addFill)),
      ),
    );

    final renderObject = tester.renderObject<RenderBox>(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(24)));
  });

  testWidgets('Icon sizing - no theme, explicit size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Icon(MingCuteIcons.addFill, size: 96)),
      ),
    );

    final renderObject = tester.renderObject<RenderBox>(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(96)));
  });

  testWidgets('Icon sizing - sized theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 36),
            child: Icon(MingCuteIcons.addFill),
          ),
        ),
      ),
    );

    final renderObject = tester.renderObject<RenderBox>(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(36)));
  });

  testWidgets('Icon sizing - sized theme, explicit size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 36),
            child: Icon(MingCuteIcons.addFill, size: 48),
          ),
        ),
      ),
    );

    final renderObject = tester.renderObject<RenderBox>(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(48)));
  });

  testWidgets('Icon sizing - sizeless theme, default size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(),
            child: Icon(MingCuteIcons.addFill),
          ),
        ),
      ),
    );

    final renderObject = tester.renderObject<RenderBox>(find.byType(Icon));
    expect(renderObject.size, equals(const Size.square(24)));
  });

  testWidgets("Changing semantic label from null doesn't rebuild tree ", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Icon(MingCuteIcons.addFill)),
      ),
    );

    final richText1 = tester.element<Element>(find.byType(RichText));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Icon(MingCuteIcons.addFill, semanticLabel: 'a label'),
        ),
      ),
    );

    final richText2 = tester.element<Element>(find.byType(RichText));

    // Compare a leaf Element in the Icon subtree before and after changing the
    // semanticLabel to make sure the subtree was not rebuilt.
    expect(richText2, same(richText1));
  });
}
