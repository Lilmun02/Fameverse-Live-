import { expect, test } from '@playwright/test'

async function mountContractFixture(page, shellClass, hostMarkup) {
  await page.evaluate(({ shellClass, hostMarkup }) => {
    globalThis.document.querySelector('[data-cohost-contract-fixture]')?.remove()
    const shell = globalThis.document.createElement('section')
    shell.dataset.cohostContractFixture = 'true'
    shell.className = shellClass
    shell.innerHTML = `
      <div class="live-video-surface fam-live-video-surface">
        ${hostMarkup}
        <div class="fv-cohost-video-tile"><video></video><span>Co-host</span></div>
      </div>
    `
    globalThis.document.body.appendChild(shell)
  }, { shellClass, hostMarkup })
}

async function expectSquarePair(page, hostSelector) {
  const host = page.locator(`[data-cohost-contract-fixture] ${hostSelector}`)
  const guest = page.locator('[data-cohost-contract-fixture] .fv-cohost-video-tile')

  const hostBox = await host.boundingBox()
  const guestBox = await guest.boundingBox()
  expect(hostBox).not.toBeNull()
  expect(guestBox).not.toBeNull()

  expect(Math.abs(hostBox.width - hostBox.height)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(guestBox.width - guestBox.height)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(hostBox.width - guestBox.width)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(guestBox.x - (hostBox.x + hostBox.width))).toBeLessThanOrEqual(2)
  expect(hostBox.height).toBeLessThan(page.viewportSize().height * 0.6)
  expect(guestBox.height).toBeLessThan(page.viewportSize().height * 0.6)
}

test.beforeEach(async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await page.goto('/', { waitUntil: 'domcontentloaded' })
  await expect(page.locator('#root .boot-splash')).toHaveCount(0, { timeout: 15000 })
})

test('host co-host layout renders two equal square boxes side by side', async ({ page }) => {
  await mountContractFixture(
    page,
    'mobile-live-shell fam-live-shell is-live has-cohost',
    '<video class="host-video immersive-video active"></video>',
  )
  await expectSquarePair(page, '.host-video.active')
})

test('viewer co-host layout renders two equal square boxes side by side', async ({ page }) => {
  await mountContractFixture(
    page,
    'fv-viewer-live has-cohost',
    '<video class="fv-viewer-live-video"></video>',
  )
  await expectSquarePair(page, '.fv-viewer-live-video')
})
