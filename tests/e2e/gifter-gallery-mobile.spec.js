import { expect, test } from '@playwright/test'

test.use({ viewport: { width: 390, height: 844 } })

test('Gifter Badge QA gallery stays inside the mobile viewport', async ({ page }) => {
  await page.goto('/?badge-gallery=1', { waitUntil: 'domcontentloaded' })

  await expect(page.getByRole('heading', { name: 'Gifter Badge Gallery' })).toBeVisible()

  const cards = page.locator('.fv-gifter-gallery-grid article')
  await expect(cards).toHaveCount(9)

  const { viewportWidth, documentWidth } = await page.evaluate(() => ({
    viewportWidth: globalThis.innerWidth,
    documentWidth: globalThis.document.documentElement.scrollWidth,
  }))
  expect(documentWidth).toBeLessThanOrEqual(viewportWidth + 1)

  const cardBoxes = await cards.evaluateAll((elements) => elements.map((element) => {
    const rect = element.getBoundingClientRect()
    return { left: rect.left, right: rect.right, width: rect.width }
  }))

  for (const box of cardBoxes) {
    expect(box.left).toBeGreaterThanOrEqual(-1)
    expect(box.right).toBeLessThanOrEqual(viewportWidth + 1)
    expect(box.width).toBeGreaterThan(0)
  }

  expect(Math.abs(cardBoxes[0].left - cardBoxes[1].left)).toBeLessThanOrEqual(1)
})
