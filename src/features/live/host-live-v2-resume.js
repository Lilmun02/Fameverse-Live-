// Host Live V2 foreground compositor repair.
//
// iOS/WebKit may preserve a stale video layer rectangle after camera flips or
// returning from another app. The stream lifecycle remains owned by useLiveMedia;
// this module never clears or replaces srcObject. It only forces the already
// active V2 layer to reflow and resume playback inside the canonical full-screen
// stage.

function reassertHostLiveV2Stage() {
  if (document.visibilityState === 'hidden') return

  window.requestAnimationFrame(() => {
    const shell = document.querySelector('.fv2-host-live')
    const stage = shell?.querySelector('.fv2-stage')
    const activeVideo = stage?.querySelector('.fv2-video.is-active')
    if (!shell || !stage || !activeVideo) return

    // Force WebKit to recompute the existing full-canvas layer after foreground.
    void shell.getBoundingClientRect()
    void stage.getBoundingClientRect()
    void activeVideo.getBoundingClientRect()

    activeVideo.play().catch(() => {})
  })
}

function onVisibilityChange() {
  if (document.visibilityState === 'visible') reassertHostLiveV2Stage()
}

document.addEventListener('visibilitychange', onVisibilityChange)
window.addEventListener('pageshow', reassertHostLiveV2Stage)
window.addEventListener('focus', reassertHostLiveV2Stage)

export { reassertHostLiveV2Stage }
