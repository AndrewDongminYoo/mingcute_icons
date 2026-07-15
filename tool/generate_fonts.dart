// ignore_for_file: avoid_print, avoid_catches_without_on_clauses, document_ignores

import 'dart:convert';
import 'dart:io';

const _fallbackLucideStaticVersion = '0.575.0';
const _requestTimeout = Duration(seconds: 12);

String _resolvePackageVersion(String packageJsonPath, String fallbackVersion) {
  final packageJson = File(packageJsonPath);
  if (packageJson.existsSync()) {
    final decoded =
        jsonDecode(packageJson.readAsStringSync()) as Map<String, dynamic>;
    final version = decoded['version'];
    if (version is String && version.isNotEmpty) {
      return version;
    }
  }
  return fallbackVersion;
}

String _flagValue(List<String> args, String name, String fallback) {
  final prefix = '--$name=';
  var value = fallback;
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      final parsed = arg.substring(prefix.length);
      if (parsed.isNotEmpty) value = parsed;
    }
  }
  return value;
}

String _toCamelCase(String name) {
  // Icon sets differ in word separators (- vs _) and letter case
  // (MingCute has names like ABS_fill); normalize to lowerCamelCase.
  final parts = name.split(RegExp('[-_]')).where((p) => p.isNotEmpty).toList();
  final camel =
      parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join();
  // Dart identifiers cannot start with a digit (Bootstrap Icons has names
  // like "1-circle"); prefix those.
  return camel.startsWith(RegExp('[0-9]')) ? 'icon$camel' : camel;
}

String _toReadableName(String name) => name.replaceAll(RegExp('[-_]'), ' ');

String _normalizeDirPath(String path) {
  if (path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

File? _findLocalSvgFile(String name, List<String> svgDirs) {
  for (final dir in svgDirs) {
    final normalizedDir = _normalizeDirPath(dir);
    // Some sets mix letter case between CSS names and SVG filenames
    // (MingCute: .mgc_TV_tower_fill vs tv_tower_fill.svg).
    for (final candidate in {name, name.toLowerCase()}) {
      final file = File('$normalizedDir/$candidate.svg');
      if (file.existsSync()) {
        return file;
      }
    }
  }
  return null;
}

String _svgDataUriFromContent(String svgContent) {
  final normalizedSvg = svgContent.trim();
  final base64Svg = base64.encode(utf8.encode(normalizedSvg));
  return 'data:image/svg+xml;base64,$base64Svg';
}

Future<String?> _loadSvgDataUri(
  HttpClient client,
  String name,
  List<String> svgDirs,
  String baseUrl,
  String fallbackUrl,
) async {
  final localSvgFile = _findLocalSvgFile(name, svgDirs);
  if (localSvgFile != null) {
    final svg = localSvgFile.readAsStringSync();
    return _svgDataUriFromContent(svg);
  }

  final urls = <String>[
    '$baseUrl/$name.svg',
    if (fallbackUrl.isNotEmpty) '$fallbackUrl/$name.svg',
  ];

  for (final url in urls) {
    try {
      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(_requestTimeout);
      final response = await request.close().timeout(_requestTimeout);

      if (response.statusCode != HttpStatus.ok) {
        continue;
      }

      final bytes = await response
          .fold<List<int>>(<int>[], (buffer, chunk) {
            buffer.addAll(chunk);
            return buffer;
          })
          .timeout(_requestTimeout);

      final svg = utf8.decode(bytes);
      return _svgDataUriFromContent(svg);
    } catch (_) {
      continue;
    }
  }

  return null;
}

Future<Map<String, String>> _buildSvgDataUriMap(
  List<String> names,
  List<String> svgDirs,
  String baseUrl,
  String fallbackUrl,
) async {
  final client = HttpClient();
  client.connectionTimeout = _requestTimeout;
  final result = <String, String>{};
  var failed = 0;

  try {
    const batchSize = 8;

    for (var i = 0; i < names.length; i += batchSize) {
      final end = (i + batchSize < names.length) ? i + batchSize : names.length;
      final batch = names.sublist(i, end);

      final fetched = await Future.wait(
        batch.map((name) async {
          final dataUri = await _loadSvgDataUri(
            client,
            name,
            svgDirs,
            baseUrl,
            fallbackUrl,
          );
          return (name: name, dataUri: dataUri);
        }),
      );

      for (final item in fetched) {
        if (item.dataUri != null) {
          result[item.name] = item.dataUri!;
        } else {
          failed++;
        }
      }

      final processed = end;
      print(
        'Fetched SVG previews: ${result.length}/${names.length} (processed $processed, failed $failed)',
      );
    }
  } finally {
    client.close(force: true);
  }

  return result;
}

const _usage =
    'Usage: dart run tool/generate_fonts.dart <path-to-css> [--inline-svg] '
    '[--svg-dir=path] [--npm-package=name] [--font-family=name] '
    '[--font-package=name] [--class-name=name] [--css-prefix=prefix] '
    '[--docs-url=url] [--output=path] [--svg-fallback-url=url]';

const _knownFlagPrefixes = <String>[
  '--svg-dir=',
  '--npm-package=',
  '--font-family=',
  '--font-package=',
  '--class-name=',
  '--css-prefix=',
  '--docs-url=',
  '--output=',
  '--svg-fallback-url=',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print(_usage);
    exit(1);
  }

  for (final arg in args) {
    if (arg == '--inline-svg') continue;
    if (arg.startsWith('--') && !_knownFlagPrefixes.any(arg.startsWith)) {
      print('Unknown flag: $arg\n\n$_usage');
      exit(1);
    }
  }

  final inlineSvg = args.contains('--inline-svg');
  final svgDirArgs = args
      .where((arg) => arg.startsWith('--svg-dir='))
      .map((arg) => arg.substring('--svg-dir='.length))
      .where((arg) => arg.isNotEmpty)
      .toList();

  final npmPackage = _flagValue(args, 'npm-package', 'lucide-static');
  final isLucideStatic = npmPackage == 'lucide-static';
  final fontFamily = _flagValue(args, 'font-family', 'Lucide');
  final fontPackage = _flagValue(args, 'font-package', 'lucide_icons');
  final className = _flagValue(args, 'class-name', 'LucideIcons');
  final cssPrefix = _flagValue(args, 'css-prefix', 'icon-');
  final docsUrl = _flagValue(args, 'docs-url', 'https://lucide.dev/icons/');
  final outputPath = _flagValue(args, 'output', './lib/lucide_icons.dart');

  final defaultSvgDir = './node_modules/$npmPackage/icons';
  final svgDirs = svgDirArgs.isEmpty ? <String>[defaultSvgDir] : svgDirArgs;

  final fallbackVersion = isLucideStatic
      ? _fallbackLucideStaticVersion
      : 'latest';
  final npmVersion = _resolvePackageVersion(
    './node_modules/$npmPackage/package.json',
    fallbackVersion,
  );
  final iconBaseUrl = 'https://unpkg.com/$npmPackage@$npmVersion/icons';
  // Per-icon SVG URL tried when both the local dirs and the unpkg base URL
  // miss (some sets, e.g. Codicons, only publish per-icon SVGs on GitHub).
  final svgFallbackUrl = _flagValue(
    args,
    'svg-fallback-url',
    isLucideStatic
        ? 'https://raw.githubusercontent.com/lucide-icons/lucide/main/icons'
        : '',
  );
  final cssPath = args.firstWhere(
    (arg) => !arg.startsWith('--'),
    orElse: () => '',
  );

  if (cssPath.isEmpty) {
    print('CSS path not provided');
    exit(1);
  }

  final cssFile = File(cssPath);

  if (!cssFile.existsSync()) {
    print('CSS file not found: $cssPath');
    exit(1);
  }

  final content = cssFile.readAsStringSync();
  // :{1,2} — lucide uses ::before, MingCute :before. The semicolon after
  // content is optional (Codicons omits it) and [^}]* tolerates extra
  // declarations after content (MingCute adds color:). The name group
  // excludes whitespace so multi-part descendant rules like
  // ".mgc_loading_3_fill .path1:before" are skipped — an IconData can only
  // hold a single codepoint, not stacked glyph layers.
  final pattern = RegExp(
    '\\.${RegExp.escape(cssPrefix)}'
    r'([^:\s]+):{1,2}before\s*\{\s*content:\s*"\\([0-9a-fA-F]+)";?[^}]*\}',
  );
  final matches = pattern.allMatches(content);
  final names = matches.map((match) => match.group(1)!).toList();
  if (inlineSvg) {
    final existingSvgDirs = svgDirs
        .where((dir) => Directory(dir).existsSync())
        .toList();
    if (existingSvgDirs.isEmpty) {
      print(
        'No local SVG directory found. Falling back to remote SVG sources.',
      );
    } else {
      print('Using local SVG directories first: ${existingSvgDirs.join(', ')}');
    }
  }
  final svgDataUris = inlineSvg
      ? await _buildSvgDataUriMap(names, svgDirs, iconBaseUrl, svgFallbackUrl)
      : <String, String>{};

  final generatedOutput = <String>[
    '// 🐦 Flutter imports:\n',
    "import 'package:flutter/widgets.dart';\n\n",
    '// THIS FILE IS AUTOMATICALLY GENERATED!\n\n',
    'class $className {',
  ];

  final seenNames = <String>{};
  for (final match in matches) {
    final name = match.group(1)!;
    final camelName = _toCamelCase(name);
    if (!seenNames.add(camelName)) continue;

    final hex = match.group(2)!.toUpperCase();
    final readableName = _toReadableName(name);

    final inlinePreview = svgDataUris[name];
    if (inlinePreview != null) {
      generatedOutput.add(
        '\n  /// [![]($inlinePreview)]($docsUrl$name)\n',
      );
    } else {
      generatedOutput.add(
        '\n  /// [![]($iconBaseUrl/$name.svg)]($docsUrl$name)\n',
      );
    }
    generatedOutput.add('  /// $fontFamily icon named "$readableName".\n');
    generatedOutput.add(
      "  static const IconData $camelName = IconData(0x$hex, fontFamily: '$fontFamily', fontPackage: '$fontPackage');\n",
    );
  }

  generatedOutput.add('}\n');

  final output = File(outputPath);
  output.writeAsStringSync(generatedOutput.join());
  print('Generated ${matches.length} icons at ${output.path}');
}
