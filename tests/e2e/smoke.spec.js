import { expect, test } from '@playwright/test'

test('Fameverse boots past the static splash without page errors', async ({ page }) => {
  const pageErrors = []
  page.on('pageerror', (error) => pageErrors.push(error.message))

  await page.goto('/', { waitUntil: 'domcontentloaded' })

  await expect(page).toHaveTitle(/Fameverse Live/)
  await expect(page.locator('#root .boot-splash')).toHaveCount(0, { timeout: 15000 })
  await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
  expect(pageErrors).toEqual([])
})
