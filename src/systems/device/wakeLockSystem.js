export async function acquireScreenWakeLock(currentLock) {
  if (!navigator.wakeLock?.request || document.visibilityState !== 'visible') return currentLock || null
  if (currentLock && !currentLock.released) return currentLock

  try {
    return await navigator.wakeLock.request('screen')
  } catch {
    return currentLock || null
  }
}

export async function releaseScreenWakeLock(lock) {
  if (!lock || lock.released) return
  try { await lock.release() } catch {}
}
