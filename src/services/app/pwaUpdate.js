export function registerFameversePwaUpdates() {
  if (!('serviceWorker' in navigator)) return

  let registration = null
  let reloading = false
  const pendingKey = 'fameverse-pwa-update-pending'

  const liveIsActive = () => Boolean(document.querySelector('.mobile-live-shell.is-live'))

  const applyPendingUpdate = () => {
    if (reloading || liveIsActive()) return
    if (sessionStorage.getItem(pendingKey) !== '1') return
    reloading = true
    sessionStorage.removeItem(pendingKey)
    window.location.reload()
  }

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!navigator.serviceWorker.controller) return
    if (liveIsActive()) {
      sessionStorage.setItem(pendingKey, '1')
      return
    }
    reloading = true
    window.location.reload()
  })

  window.addEventListener('load', async () => {
    try {
      registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
      await registration.update()
      applyPendingUpdate()
    } catch {}
  })

  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState !== 'visible') return
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      await registration?.update()
    } catch {}
    applyPendingUpdate()
  })
}
