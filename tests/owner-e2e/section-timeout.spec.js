import { expect, test } from '@playwright/test'
test('stalled private read ends with an empty retryable error and Retry makes a fresh authorized read',async({page})=>{
 await page.clock.install()
 await page.route('https://**/*',r=>r.abort())
 await page.route('**/api/owner/control',r=>r.fulfill({json:{authorized:true,mode:'owner-access'}}))
 let reads=0
 await page.route('**/api/owner/console',r=>{
  reads++
  if(reads>1)return r.fulfill({json:{authorized:true,items:[{id:'22222222-2222-4222-8222-222222222222',username:'verified-member'}]}})
 })
 await page.goto('/tests/fixtures/owner.html?section=users')
 await page.clock.fastForward(200)
 await expect.poll(()=>reads).toBe(1)
 await page.clock.fastForward(10000)
 await expect(page.getByText('The protected section read timed out. Retry to verify access again.',{exact:false})).toBeVisible()
 await expect(page.locator('.fv-oc-record')).toHaveCount(0)
 await page.getByRole('button',{name:'Retry',exact:true}).click()
 await page.clock.fastForward(100)
 await expect(page.getByText('verified-member',{exact:true})).toBeVisible()
 expect(reads).toBe(2)
})
