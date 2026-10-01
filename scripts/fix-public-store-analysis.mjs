import fs from 'node:fs';

const path = 'native/flutter_v1/lib/features/profile/fame_coin_store_screen.dart';
let source = fs.readFileSync(path, 'utf8');

const block = `  Map<String, dynamic> _firstRow(dynamic raw) {\n    if (raw is List && raw.isNotEmpty && raw.first is Map) {\n      return Map<String, dynamic>.from(raw.first as Map);\n    }\n    if (raw is Map) return Map<String, dynamic>.from(raw);\n    return const {};\n  }\n\n`;

if (source.includes(block)) {
  source = source.replace(block, '');
  fs.writeFileSync(path, source);
}

console.log('Public store dead helper removed.');
