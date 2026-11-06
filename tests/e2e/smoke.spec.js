import { expect, test } from '@playwright/test'

test('public browser boots into the Fameverse coin store without page errors', async ({ page }) => {
  const pageErrors = []
  page.on('pageerror', (error) => pageErrors.push(error.message))

  await page.goto('/', { waitUntil: 'domcontentloaded' })

  await expect(page).toHaveTitle(/Fameverse Live/)
  await expect(page.locator('#root .boot-splash')).toHaveCount(0, { timeout: 15000 })
  await expect(page.getByRole('heading', { name: /Make every moment/ })).toBeVisible()
  await expect(page.getByText('Sign in before checkout')).toBeVisible()
  expect(pageErrors).toEqual([])
})

test('coin store deep link renders directly', async ({ page }) => {
  await page.goto('/coins', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Fame Coins' })).toBeVisible({ timeout: 15000 })
})

test('password recovery deep link renders its reset form', async ({ page }) => {
  await page.goto('/reset-password', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Set a new password' })).toBeVisible({ timeout: 15000 })
  await expect(page.getByLabel('New password')).toBeVisible()
})
