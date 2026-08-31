/* Fameverse — Pocket Comet (15) — Frame 4 look */
export const PocketComet = Object.freeze({
  id: 'fv_pocket_comet_15',
  coins: 15,
  duration: 4.5,
  watermark: 'FAMEVERSE LIVE',
})

export function drawPocketCometFrame4(ctx, w, h, t = 2.95) {
  const g = ctx.createLinearGradient(0, 0, 0, h)
  g.addColorStop(0, '#020617')
  g.addColorStop(0.45, '#0b1b3a')
  g.addColorStop(1, '#06101f')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, w, h)

  const stars = [
    [0.42 * w, 0.38 * h],
    [0.58 * w, 0.34 * h],
    [0.52 * w, 0.48 * h],
  ]

  ctx.strokeStyle = 'rgba(180,140,255,0.55)'
  ctx.lineWidth = Math.max(1.2, w * 0.003)
  ctx.beginPath()
  ctx.moveTo(...stars[0])
  ctx.lineTo(...stars[1])
  ctx.lineTo(...stars[2])
  ctx.closePath()
  ctx.stroke()

  ctx.fillStyle = '#ffd478'
  stars.forEach(([x, y]) => {
    ctx.beginPath()
    ctx.arc(x, y, Math.max(2.4, w * 0.008), 0, Math.PI * 2)
    ctx.fill()
  })

  const cx = (stars[0][0] + stars[1][0] + stars[2][0]) / 3
  const cy = (stars[0][1] + stars[1][1] + stars[2][1]) / 3
  const loopT = ((t - 2.55) / 0.85) % 1
  const ang = -0.6 + loopT * Math.PI * 2
  const px = cx + Math.cos(ang) * w * 0.16
  const py = cy + Math.sin(ang) * h * 0.07

  ctx.save()
  ctx.globalCompositeOperation = 'lighter'
  ctx.strokeStyle = 'rgba(90,168,255,0.65)'
  ctx.lineWidth = w * 0.012
  ctx.beginPath()
  ctx.ellipse(cx, cy + h * 0.02, w * 0.22, h * 0.09, -0.35, 0, Math.PI * 2)
  ctx.stroke()

  const burst = ctx.createRadialGradient(cx, cy + h * 0.06, 0, cx, cy + h * 0.06, w * 0.18)
  burst.addColorStop(0, '#fff6c8')
  burst.addColorStop(0.2, '#ffd15a')
  burst.addColorStop(0.45, '#b48cff')
  burst.addColorStop(1, 'rgba(90,168,255,0)')
  ctx.fillStyle = burst
  ctx.beginPath()
  ctx.arc(cx, cy + h * 0.06, w * 0.18, 0, Math.PI * 2)
  ctx.fill()

  const core = ctx.createRadialGradient(px, py, 0, px, py, w * 0.05)
  core.addColorStop(0, '#fff6c8')
  core.addColorStop(0.4, '#ffd15a')
  core.addColorStop(1, 'rgba(61,224,255,0)')
  ctx.fillStyle = core
  ctx.beginPath()
  ctx.arc(px, py, w * 0.05, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()

  const pillW = Math.min(220, w * 0.62)
  const pillH = Math.max(28, h * 0.036)
  const pillX = (w - pillW) / 2
  const pillY = h - pillH - h * 0.04
  ctx.fillStyle = 'rgba(8,10,18,0.55)'
  ctx.beginPath()
  if (ctx.roundRect) ctx.roundRect(pillX, pillY, pillW, pillH, pillH / 2)
  else ctx.rect(pillX, pillY, pillW, pillH)
  ctx.fill()
  ctx.fillStyle = '#fff'
  ctx.font = `700 ${Math.max(11, w * 0.034)}px system-ui, sans-serif`
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillText('FAMEVERSE LIVE', w / 2, pillY + pillH / 2)
}

export function startPocketCometAnimation(canvas, durationMs = 4500) {
  const ctx = canvas.getContext('2d')
  if (!ctx) return () => {}

  let frameId = null
  let stopped = false
  const startedAt = performance.now()

  const render = (now) => {
    if (stopped) return
    const rect = canvas.getBoundingClientRect()
    const width = Math.max(1, rect.width)
    const height = Math.max(1, rect.height)
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    const pixelWidth = Math.round(width * dpr)
    const pixelHeight = Math.round(height * dpr)

    if (canvas.width !== pixelWidth || canvas.height !== pixelHeight) {
      canvas.width = pixelWidth
      canvas.height = pixelHeight
    }

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    const elapsedMs = now - startedAt
    const loopTime = 2.55 + ((elapsedMs / 1000) % 0.85)
    drawPocketCometFrame4(ctx, width, height, loopTime)

    if (elapsedMs < durationMs) frameId = window.requestAnimationFrame(render)
  }

  frameId = window.requestAnimationFrame(render)
  return () => {
    stopped = true
    if (frameId != null) window.cancelAnimationFrame(frameId)
  }
}
