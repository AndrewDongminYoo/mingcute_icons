// 🎯 Dart imports:
import 'dart:io';
import 'dart:typed_data';

// 📦 Package imports:
import 'package:flutter_test/flutter_test.dart';

/// Reads each style independently because both fonts share codepoints.
Set<int> _cssCodepoints(String style) {
  final content = File('assets/mingcute.css').readAsStringSync();
  final pattern = RegExp(
    '\\.mgc-[^:\\s]+-core-$style::before\\s*\\{'
    r'[^}]*?content:\s*"\\([0-9a-fA-F]+)"',
  );
  return pattern
      .allMatches(content)
      .map((match) => int.parse(match.group(1)!, radix: 16))
      .toSet();
}

/// Extracts codepoints from the generated `lib/flutter_mingcute.dart`.
Set<int> _dartCodepoints(String fontFamily) {
  final content = File('lib/flutter_mingcute.dart').readAsStringSync();
  final pattern = RegExp(
    r"IconData\(\s*0x([0-9A-Fa-f]+),\s*fontFamily: '"
    "${RegExp.escape(fontFamily)}'",
  );
  return pattern
      .allMatches(content)
      .map((match) => int.parse(match.group(1)!, radix: 16))
      .toSet();
}

/// Parses the `cmap` table of a bundled TTF and returns the set of
/// codepoints covered by its format 4 and format 12 subtables.
Set<int> _fontCodepoints(String fontPath) {
  final bytes = File(fontPath).readAsBytesSync();
  final data = ByteData.sublistView(bytes);

  final numTables = data.getUint16(4);
  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final recordOffset = 12 + i * 16;
    final tag = String.fromCharCodes(
      bytes.sublist(recordOffset, recordOffset + 4),
    );
    if (tag == 'cmap') {
      cmapOffset = data.getUint32(recordOffset + 8);
      break;
    }
  }
  if (cmapOffset == null) {
    throw StateError('cmap table not found in $fontPath');
  }

  final numSubtables = data.getUint16(cmapOffset + 2);
  final coverage = <int>{};
  for (var i = 0; i < numSubtables; i++) {
    final recordOffset = cmapOffset + 4 + i * 8;
    final subtableOffset = cmapOffset + data.getUint32(recordOffset + 4);
    final format = data.getUint16(subtableOffset);

    if (format == 4) {
      final segCountX2 = data.getUint16(subtableOffset + 6);
      final segCount = segCountX2 ~/ 2;
      final endCodeOffset = subtableOffset + 14;
      final startCodeOffset = endCodeOffset + segCountX2 + 2;
      final idDeltaOffset = startCodeOffset + segCountX2;
      final idRangeOffset = idDeltaOffset + segCountX2;
      for (var seg = 0; seg < segCount; seg++) {
        final endCode = data.getUint16(endCodeOffset + seg * 2);
        final startCode = data.getUint16(startCodeOffset + seg * 2);
        if (startCode == 0xFFFF && endCode == 0xFFFF) continue;
        final delta = data.getInt16(idDeltaOffset + seg * 2);
        final rangeOffset = data.getUint16(idRangeOffset + seg * 2);
        for (var cp = startCode; cp <= endCode; cp++) {
          var glyph = rangeOffset == 0
              ? (cp + delta) & 0xFFFF
              : data.getUint16(
                  idRangeOffset + seg * 2 + rangeOffset + (cp - startCode) * 2,
                );
          if (rangeOffset != 0 && glyph != 0) {
            glyph = (glyph + delta) & 0xFFFF;
          }
          if (glyph != 0) coverage.add(cp);
        }
      }
    } else if (format == 12) {
      final nGroups = data.getUint32(subtableOffset + 12);
      for (var g = 0; g < nGroups; g++) {
        final groupOffset = subtableOffset + 16 + g * 12;
        final startCharCode = data.getUint32(groupOffset);
        final endCharCode = data.getUint32(groupOffset + 4);
        final startGlyph = data.getUint32(groupOffset + 8);
        for (var cp = startCharCode; cp <= endCharCode; cp++) {
          if (startGlyph + cp - startCharCode != 0) coverage.add(cp);
        }
      }
    }
  }
  return coverage;
}

void main() {
  for (final style in ['filled', 'regular']) {
    final fontFamily = style == 'filled'
        ? 'Mingcute Core Filled'
        : 'Mingcute Core Regular';
    final fontPath = style == 'filled'
        ? 'assets/mingcute.ttf'
        : 'assets/mingcute_line.ttf';
    test('$style CSS, Dart and font codepoints are consistent', () {
      final cssCodepoints = _cssCodepoints(style);
      final dartCodepoints = _dartCodepoints(fontFamily);
      final fontCodepoints = _fontCodepoints(fontPath);

      // Guards against a silently changed CSS format making the regex match
      // nothing.
      expect(cssCodepoints, isNotEmpty);
      expect(cssCodepoints.length, greaterThan(1000));

      final missingFromCss = dartCodepoints.difference(cssCodepoints);
      expect(
        missingFromCss,
        isEmpty,
        reason:
            'Dart codepoints missing from assets/mingcute.css: '
            '${missingFromCss.map((cp) => '0x${cp.toRadixString(16)}')}',
      );

      final missingFromDart = cssCodepoints.difference(dartCodepoints);
      expect(
        missingFromDart,
        isEmpty,
        reason:
            'CSS codepoints missing from the generated MingCuteIcons class: '
            '${missingFromDart.map((cp) => '0x${cp.toRadixString(16)}')}',
      );

      final missingFromFont = cssCodepoints.difference(fontCodepoints);
      expect(
        missingFromFont,
        isEmpty,
        reason:
            'CSS codepoints not covered by $fontPath cmap: '
            '${missingFromFont.map((cp) => '0x${cp.toRadixString(16)}')}',
      );
    });
  }
}
