import { expect, test } from '@playwright/test'

test.beforeEach(async ({ page }) => {
  await page.route('https://**/*', route => route.abort())
  await page.route('**/api/owner/control', route => route.fulfill({ json: { authorized: true, mode: 'owner-access' } }))
})

for (const status of [401, 403]) {
  test(`a non-JSON ${status} clears private records on navigation`, async ({ page }) => {
    const reads = []
    await page.route('**/api/owner/console', async route => {
      const body = route.request().postDataJSON()
      reads.push(body.section)
      if (body.section === 'users') return route.fulfill({ status, contentType: 'text/plain', body: 'Revoked' })
      return route.fulfill({ json: { authorized: true, users: 9381, live: 2, overview: {} } })
    })
    await page.goto('/tests/fixtures/owner.html')
    await expect(page.getByText('9,381', { exact: true })).toBeVisible()
    await page.locator('a[href="/owner/users"]').first().click()
    await expect(page.getByRole('heading', { name: 'Owner dashboard locked' })).toBeVisible()
    await expect(page.getByText('9,381', { exact: true })).toHaveCount(0)
    await expect(page.getByRole('complementary', { name: 'Owner Command Center sections' })).toHaveCount(0)
    expect(reads).toEqual(['overview', 'users'])
  })

  test(`a non-JSON ${status} action response locks the workspace`, async ({ page }) => {
    await page.route('**/api/owner/console', route => {
      const body = route.request().postDataJSON()
      if (body.action === 'preview_action') return route.fulfill({ status, contentType: 'text/plain', body: 'Revoked' })
      return route.fulfill({ json: { authorized: true, items: [{ id: '22222222-2222-4222-8222-222222222222', username: 'private-member' }] } })
    })
    await page.goto('/tests/fixtures/owner.html?section=users')
    await page.getByRole('button', { name: 'Warn member', exact: true }).click()
    await page.getByLabel('Reason and supporting context').fill('Review the reported account incident.')
    await page.getByRole('button', { name: 'Validate in preview' }).click()
    await expect(page.getByRole('heading', { name: 'Owner dashboard locked' })).toBeVisible()
    await expect(page.getByText('private-member', { exact: true })).toHaveCount(0)
    await expect(page.getByRole('dialog')).toHaveCount(0)
  })
}
