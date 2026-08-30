const GIFT_BALANCE_STORAGE_KEY = 'fameverse-owner-test-coins'
const DEFAULT_GIFT_BALANCE = 10000

function isValidBalance(value) {
  return Number.isSafeInteger(value) && value >= 0
}

export function loadGiftBalance() {
  try {
    const raw = localStorage.getItem(GIFT_BALANCE_STORAGE_KEY)
    if (raw == null) return DEFAULT_GIFT_BALANCE
    if (raw.trim() === '') return 0

    const saved = Number(raw)
    return isValidBalance(saved) ? saved : 0
  } catch {
    return 0
  }
}

export function persistGiftBalance(balance) {
  if (!isValidBalance(balance)) return false

  try {
    localStorage.setItem(GIFT_BALANCE_STORAGE_KEY, String(balance))
    return true
  } catch {
    return false
  }
}

export function addGiftBalance(balance, amount) {
  if (!isValidBalance(balance) || !isValidBalance(amount)) return null
  const nextBalance = balance + amount
  return isValidBalance(nextBalance) ? nextBalance : null
}

export function giftTotalCost(gift) {
  return isValidBalance(gift?.cost) ? gift.cost : null
}

export function canAffordGift(balance, totalCost) {
  return isValidBalance(balance) && isValidBalance(totalCost) && balance >= totalCost
}

export function deductGiftCost(balance, totalCost) {
  if (!canAffordGift(balance, totalCost)) return null
  return balance - totalCost
}
