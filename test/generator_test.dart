import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CSS without icon mappings fails instead of replacing the icon class',
    () async {
      final fixture = Directory.systemTemp.createTempSync('mingcute-empty-');
      addTearDown(() => fixture.deleteSync(recursive: true));
      final css = File('${fixture.path}/icons.css')
        ..writeAsStringSync('@import "core-filled.min.css";');
      final output = File('${fixture.path}/icons.dart')
        ..writeAsStringSync('keep existing icons');
      final result = await Process.run('dart', [
        'run',
        'tool/generate_fonts.dart',
        css.path,
        '--output=${output.path}',
      ]);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('No icon codepoints found'));
      expect(output.readAsStringSync(), 'keep existing icons');
    },
  );

  test(
    'scoped MingCute CSS keeps styles, legacy names and local previews',
    () async {
      final fixture = Directory.systemTemp.createTempSync(
        'mingcute-generator-',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      final css = File('${fixture.path}/icons.css')
        ..writeAsStringSync(r'''
.mgc-add-core-filled::before{font-family:"Mingcute Core Filled"!important;content:"\e006"}
.mgc-add-core-regular::before{font-family:"Mingcute Core Regular"!important;content:"\e006"}
.mgc-barcode-sca-core-filled::before{font-family:"Mingcute Core Filled"!important;content:"\e100"}
.mgc-computer-camer-core-regular::before{font-family:"Mingcute Core Regular"!important;content:"\e101"}
.mgc-docment-core-filled::before{font-family:"Mingcute Core Filled"!important;content:"\e102"}
.mgc-rada-core-regular::before{font-family:"Mingcute Core Regular"!important;content:"\e103"}
.mgc-chinese-knot-core-filled::before{font-family:"Mingcute Core Filled"!important;content:"\e104"}
''');
      const svg =
          '<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0h1"/></svg>';
      for (final entry in {
        'core-filled': ['add', 'barcode-sca', 'docment', 'chinese-knot'],
        'core-regular': ['add', 'computer-camer', 'rada'],
      }.entries) {
        final dir = Directory('${fixture.path}/${entry.key}')..createSync();
        for (final name in entry.value) {
          File('${dir.path}/$name.svg').writeAsStringSync(svg);
        }
      }
      final output = File('${fixture.path}/icons.dart');
      final result = await Process.run('dart', [
        'run',
        'tool/generate_fonts.dart',
        css.path,
        '--inline-svg',
        '--svg-dir=${fixture.path}',
        '--npm-package=@mingcute/svg',
        '--font-family=MingCute',
        '--font-package=flutter_mingcute',
        '--class-name=MingCuteIcons',
        '--css-prefix=mgc-',
        '--output=${output.path}',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final generated = output.readAsStringSync();
      expect(
        generated,
        contains(
          "IconData addFill = IconData(0xE006, fontFamily: 'Mingcute Core Filled'",
        ),
      );
      expect(
        generated,
        contains(
          "IconData addLine = IconData(0xE006, fontFamily: 'Mingcute Core Regular'",
        ),
      );
      for (final name in [
        'barcodeScanFill',
        'computerCameraLine',
        'documentFill',
        'radarLine',
        'chinesKnotFill',
      ]) {
        expect(generated, contains('IconData $name ='));
      }
      expect('data:image/svg+xml;base64,'.allMatches(generated), hasLength(7));
      expect(generated, contains(base64.encode(utf8.encode(svg))));
    },
  );
}
