const ALLOWED_GIFT_QUANTITIES = new Set([1, 5, 10])

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
