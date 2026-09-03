import { describe, expect, it } from 'vitest'
import { videoConstraints } from '../../src/utils/media.js'

describe('videoConstraints', () => {
  it('defaults to the user-facing camera', () => {
    expect(videoConstraints()).toEqual({
      facingMode: { ideal: 'user' },
      width: { ideal: 1280 },
      height: { ideal: 720 },
    })
  })

  it('preserves an environment-facing camera request', () => {
    expect(videoConstraints('environment').facingMode).toEqual({ ideal: 'environment' })
  })
})
