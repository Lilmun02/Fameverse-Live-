export function isRunningStandalone() {
  return window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone === true
}

export function loadCoins() {
  const saved = Number(localStorage.getItem('fameverse-owner-test-coins'))
  return Number.isFinite(saved) && saved >= 0 ? saved : 10000
}
