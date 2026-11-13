import { expect, test } from '@playwright/test'

test('StrictMode checks access once; section changes refetch data without remounting the gate', async ({ page })=>{
  let accesses=0
  const reads=[]
  await page.route('https://**/*',route=>route.abort())
  await page.route('**/api/owner/control',route=>{
    accesses++
    return route.fulfill({json:{authorized:true,mode:'owner-access'}})
  })
  await page.route('**/api/owner/console',route=>{
    reads.push(route.request().postDataJSON().section)
    return route.fulfill({json:{authorized:true,items:[],users:1,live:0}})
  })
  await page.goto('/tests/fixtures/owner.html')
  await expect(page.getByText('Public profiles',{exact:true})).toBeVisible()
  for(const section of ['users','live','moderation','gifts','finance','funding','reports','badges','support','policy','system','audit']){
    await page.locator('.fv-oc-sidebar a[href="/owner/'+section+'"]').click()
    await expect.poll(()=>reads.at(-1)).toBe(section)
    await expect(page.locator('.fv-oc-loading')).toHaveCount(0)
  }
  expect(accesses).toBe(1)
  expect(reads).toHaveLength(13)
})

test('a stalled secure access check ends with a retryable unavailable state', async ({ page })=>{
  await page.clock.install()
  await page.route('https://**/*',route=>route.abort())
  let attempts=0
  await page.route('**/api/owner/control',()=>{attempts++})
  await page.goto('/tests/fixtures/owner.html')
  await page.clock.fastForward(100)
  await expect.poll(()=>attempts).toBe(1)
  await page.clock.fastForward(10000)
  await expect(page.getByRole('heading',{name:'Access unavailable',exact:true})).toBeVisible()
  await expect(page.getByText('The secure owner check timed out. Retry to verify access again.',{exact:true})).toBeVisible()
  await expect(page.locator('.fv-oc-shell')).toHaveCount(0)
  await page.getByRole('button',{name:'Retry secure access'}).click()
  await page.clock.fastForward(100)
  await expect.poll(()=>attempts).toBe(2)
})
