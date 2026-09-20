import { expect, test } from '@playwright/test'

// Geometry fixtures exercise the production CSS cascade. They do not claim
// physical camera, audio, network, or co-host acceptance.
test.use({ serviceWorkers: 'block' })

async function mountHost(page) {
  await page.goto('/', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible()
  await page.evaluate(() => {
    const shell = globalThis.document.createElement('section')
    shell.className = 'fv2-host-live'
    shell.dataset.liveContractFixture = 'true'
    shell.innerHTML = `<div class="fv2-stage">
      <video class="fv2-video is-active is-mirrored"></video>
      <video class="fv2-video"></video>
    </div>`
    globalThis.document.body.appendChild(shell)
  })
}

async function switchSlot(page, index) {
  await page.locator('.fv2-video').evaluateAll((videos, active) => {
    videos.forEach((video, i) => video.classList.toggle('is-active', i === active))
  }, index)
}

async function expectFullCanvas(page) {
  const viewport = page.viewportSize()
  for (const video of await page.locator('.fv2-video').all()) {
    const box = await video.boundingBox()
    expect(box).not.toBeNull()
    expect(Math.abs(box.x)).toBeLessThanOrEqual(1)
    expect(Math.abs(box.y)).toBeLessThanOrEqual(1)
    expect(Math.abs(box.width - viewport.width)).toBeLessThanOrEqual(1)
    expect(Math.abs(box.height - viewport.height)).toBeLessThanOrEqual(1)
    const styles = await video.evaluate((node) => {
      const style = globalThis.getComputedStyle(node)
      return { fit: style.objectFit, display: style.display, transform: style.transform }
    })
    expect(styles.fit).toBe('cover')
    expect(styles.display).toBe('block')
    expect(styles.transform).not.toBe('none')
  }
}

for (const viewport of [{ width: 390, height: 844 }, { width: 412, height: 915 }]) {
  test(`V2 camera slots retain full canvas through flips and co-host cleanup at ${viewport.width}px`, async ({ page }) => {
    await page.setViewportSize(viewport)
    await mountHost(page)
    for (const slot of [0, 1, 0, 1]) {
      await switchSlot(page, slot)
      await expectFullCanvas(page)
    }

    await page.locator('.fv2-host-live').evaluate((shell) => {
      shell.classList.add('has-cohost')
      const guest = globalThis.document.createElement('div')
      guest.className = 'fv-cohost-video-tile'
      guest.innerHTML = '<video></video><span>Co-host</span>'
      shell.querySelector('.fv2-stage').appendChild(guest)
    })
    for (const slot of [0, 1]) {
      await switchSlot(page, slot)
      const host = await page.locator('.fv2-video.is-active').boundingBox()
      const guest = await page.locator('.fv-cohost-video-tile').boundingBox()
      expect(Math.abs(host.width - host.height)).toBeLessThanOrEqual(1.5)
      expect(Math.abs(guest.width - guest.height)).toBeLessThanOrEqual(1.5)
      expect(Math.abs(host.width - guest.width)).toBeLessThanOrEqual(1.5)
      expect(Math.abs(host.y - guest.y)).toBeLessThanOrEqual(1.5)
      expect(Math.abs(host.x + host.width - guest.x)).toBeLessThanOrEqual(2)
    }

    await page.locator('.fv2-host-live').evaluate((shell) => {
      shell.classList.remove('has-cohost')
      shell.querySelector('.fv-cohost-video-tile').remove()
    })
    await expectFullCanvas(page)
  })
}

test('app updates defer during V2 Live and resume after the room closes', async ({ page }) => {
  await mountHost(page)
  await page.evaluate(() => {
    globalThis.navigator.serviceWorker.dispatchEvent(new MessageEvent('message', {
      data: { type: 'FAMEVERSE_UPDATE_READY' },
    }))
  })
  const notice = page.locator('[data-fameverse-update-notice]')
  await expect(notice).toHaveAttribute('data-mode', 'deferred')
  await expect(notice).toContainText('after this Live ends')
  // Exceed the updater's 350ms restart timer: the active room must survive.
  await page.waitForTimeout(600)
  await expect(page.locator('.fv2-host-live')).toHaveCount(1)
  expect(await page.evaluate(() => globalThis.localStorage.getItem('fameverse-pwa-update-pending'))).toBe('1')
  await page.locator('.fv2-host-live').evaluate((shell) => shell.remove())
  await expect(notice).toHaveAttribute('data-mode', 'applying')
  await page.waitForURL(/fv-force-refresh=/)
})
