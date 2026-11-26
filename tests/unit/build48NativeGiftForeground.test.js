import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'

const source = readFileSync(
  new URL('../../native/flutter_v1/lib/features/live/native_live_components.dart', import.meta.url),
  'utf8',
)
const nativeOverlay = source.split('class NativeGiftOverlay extends StatefulWidget')[1]
  ?.split('class NativeGiftTray extends StatefulWidget')[0] ?? ''
const lightweight = nativeOverlay.split('Widget _lightweightGift(')[1]
  ?.split('Widget _senderOverlay(')[0] ?? ''
const premium = nativeOverlay.split('Widget _largeNativeGift(')[1]
  ?.split('@override\n  Widget build')[0] ?? ''

describe('Build 48 approved native gift foreground presentation', () => {
  it('renders small gifts with real sender identity and without painted frames', () => {
    expect(lightweight).toContain('playback.sender} sent')
    expect(lightweight).toContain('BoxConstraints(maxWidth: 260)')
    expect(lightweight).toContain('TextDecoration.none')
    expect(lightweight).not.toContain('BoxDecoration(')
    expect(lightweight).not.toContain('RadialGradient(')
  })

  it('presents premium gifts without dark cards, backplates, or bungee animation', () => {
    expect(premium).toContain('_senderOverlay(playback)')
    expect(premium).not.toContain('RadialGradient(')
    expect(premium).not.toContain('BoxShape.circle')
    expect(premium).toContain('Curves.easeOutCubic')
    expect(premium).not.toContain('Curves.easeOutBack')
  })

  it('keeps cinematic gifts bounded and foreground-only without loading subtitles', () => {
    expect(nativeOverlay).toContain("Key('cinematic-gift-presentation-")
    expect(nativeOverlay).toContain('width: size.width * .88')
    expect(nativeOverlay).toContain('height: size.height * .58')
    expect(nativeOverlay).toContain('child: VideoPlayer(controller)')
    expect(nativeOverlay).not.toContain('Premium gift media could not load')
    expect(nativeOverlay).not.toContain('Preparing the original premium gift animation')
    expect(nativeOverlay).not.toContain('BoxDecoration(')
    expect(nativeOverlay).not.toContain('0xE617101F')
    expect(nativeOverlay).toContain('TextDecoration.none')
    expect(nativeOverlay).toContain('widget.onFinished?.call()')
  })
})
