import fs from 'node:fs';

const path = 'native/flutter_v1/lib/features/profile/owner_control_center_build23.dart';
let source = fs.readFileSync(path, 'utf8');

const broken = "Example: record $10 and Fameverse shows $10 available in the Reward Reserve.";
const fixed = "Example: record \\$10 and Fameverse shows \\$10 available in the Reward Reserve.";

if (!source.includes(fixed)) {
  const count = source.split(broken).length - 1;
  if (count !== 1) {
    throw new Error(`owner finance copy: expected one broken target, found ${count}`);
  }
  source = source.replace(broken, fixed);
  fs.writeFileSync(path, source);
}

console.log('Owner finance dollar example is Dart-safe.');
