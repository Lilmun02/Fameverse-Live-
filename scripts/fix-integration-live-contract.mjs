import fs from 'node:fs'

const path = 'native/flutter_v1/test/live_gift_and_owner_payout_contract_test.dart'
const source = fs.readFileSync(path, 'utf8')
const startMarker = `      expect(\n        viewer,\n        isNot(contains("if (_canRefill) ...[`
const nextMarker = `      expect(viewer, contains('canRefill: _canRefill'));`
const start = source.indexOf(startMarker)
const next = source.indexOf(nextMarker, start)

if (start < 0 || next < 0) {
  throw new Error('Generated viewer gift-gate assertion did not match the locked repair contract.')
}

const repaired = `${source.slice(0, start)}      expect(viewer, isNot(contains("if (_canRefill) ...[")));\n${source.slice(next)}`
fs.writeFileSync(path, repaired)
console.log('Normalized Live gift-gate regression assertion.')
