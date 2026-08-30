const GIFT_BALANCE_STORAGE_KEY = 'fameverse-owner-test-coins'
const DEFAULT_GIFT_BALANCE = 10000
const ALLOWED_GIFT_QUANTITIES = new Set([1, 5, 10])

export function loadGiftBalance() {
  const saved = Number(localStorage.getItem(GIFT_BALANCE_STORAGE_KEY))
  return Number.isFinite(saved) && saved >= 0 ? saved : DEFAULT_GIFT_BALANCE
}

export function persistGiftBalance(balance) {
  localStorage.setItem(GIFT_BALANCE_STORAGE_KEY, String(balance))
  return balance
}

export function addGiftBalance(balance, amount) {
  return balance + amount
}

export function normalizeGiftQuantity(quantity) {
  return ALLOWED_GIFT_QUANTITIES.has(quantity) ? quantity : 1
}

export function giftTotalCost(gift, quantity) {
  return gift.cost * normalizeGiftQuantity(quantity)
}

export function canAffordGift(balance, totalCost) {
  return balance >= totalCost
}

export function deductGiftCost(balance, totalCost) {
  return balance - totalCost
}
