import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const source = readFileSync(
  new URL('../../native/flutter_v1/lib/features/live/native_live_components.dart', import.meta.url),
  'utf8',
)
const customAmount = source.split('Future<void> _customAmount() async {')[1]
  ?.split('  @override\n  Widget build(BuildContext context)')[0] ?? ''

describe('Build 48 gift quantity UI regression lock', () => {
  it('keeps +/- and preset changes synchronized with the actual quantity field', () => {
    expect(customAmount).toContain('GlobalKey<FormFieldState<String>>()')
    expect(customAmount).toContain("quantityFieldKey.currentState?.didChange('$next')")
    expect(customAmount).toContain("Key('gift-quantity-increase')")
    expect(customAmount).toContain("Key('gift-quantity-decrease')")
    expect(customAmount).toContain('key: quantityFieldKey')
    expect(customAmount).toContain('quantity = next')
    expect(customAmount).toContain('setQuantity(quantity + 1)')
    expect(customAmount).toContain('setQuantity(quantity - 1)')
    expect(customAmount).toContain('setQuantity(value)')
  })

  it('cannot submit a stale amount when the field contains invalid input', () => {
    expect(customAmount).toContain('setModalState(() => quantityValid = false)')
    expect(customAmount).toContain('onPressed: quantityValid')
    expect(customAmount).toContain('Navigator.of(context).pop(quantity)')
    expect(customAmount).not.toContain("initialValue: '$quantity'")
  })

  it('does not change server-side charging, receipts, or gift rendering code', () => {
    expect(source).toContain('final sent = await widget.onSend(gift, quantity)')
    expect(source).toContain('fvExpandGiftVisualCombo')
    expect(source).toContain('NativeGiftOverlay')
  })
})
