export function registerFameversePwaUpdates() {
  if (!('serviceWorker' in navigator)) return

  let registration = null
  let reloading = false
  const pendingKey = 'fameverse-pwa-update-pending'

  const liveIsActive = () => Boolean(document.querySelector('.mobile-live-shell.is-live'))

  const showNotice = (mode) => {
    let notice = document.querySelector('[data-fameverse-update-notice]')
    if (!notice) {
      notice = document.createElement('div')
      notice.dataset.fameverseUpdateNotice = 'true'
      notice.className = 'fv-update-notice'
      notice.setAttribute('role', 'status')
      notice.setAttribute('aria-live', 'polite')
      notice.innerHTML = '<span class="fv-update-dot" aria-hidden="true"></span><div><strong></strong><small></small></div>'
      document.body.appendChild(notice)
    }

    const title = notice.querySelector('strong')
    const detail = notice.querySelector('small')
    if (mode === 'deferred') {
      title.textContent = 'Fameverse update ready'
      detail.textContent = 'It will install automatically after this Live ends.'
      notice.dataset.mode = 'deferred'
    } else {
      title.textContent = 'Updating Fameverse'
      detail.textContent = 'Restarting into the newest version…'
      notice.dataset.mode = 'applying'
    }
  }

  const markPending = () => {
    sessionStorage.setItem(pendingKey, '1')
    showNotice(liveIsActive() ? 'deferred' : 'applying')
  }

  const applyPendingUpdate = () => {
    if (reloading || sessionStorage.getItem(pendingKey) !== '1') return
    if (liveIsActive()) {
      showNotice('deferred')
      return
    }

    reloading = true
    showNotice('applying')
    sessionStorage.removeItem(pendingKey)
    window.setTimeout(() => window.location.reload(), 450)
  }

  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!navigator.serviceWorker.controller) return
    markPending()
    applyPendingUpdate()
  })

  const watchRegistration = (nextRegistration) => {
    nextRegistration?.addEventListener('updatefound', () => {
      const worker = nextRegistration.installing
      if (!worker) return

      worker.addEventListener('statechange', () => {
        if (worker.state !== 'installed' || !navigator.serviceWorker.controller) return
        markPending()
      })
    })
  }

  window.addEventListener('load', async () => {
    try {
      registration = await navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
      watchRegistration(registration)
      await registration.update()
      applyPendingUpdate()
    } catch {}
  })

  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState !== 'visible') return
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      if (registration) watchRegistration(registration)
      await registration?.update()
    } catch {}
    applyPendingUpdate()
  })

  window.addEventListener('online', async () => {
    try {
      registration ||= await navigator.serviceWorker.getRegistration()
      await registration?.update()
    } catch {}
    applyPendingUpdate()
  })

  const liveObserver = new MutationObserver(() => {
    if (sessionStorage.getItem(pendingKey) === '1') applyPendingUpdate()
  })

  liveObserver.observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: ['class'],
  })
}
