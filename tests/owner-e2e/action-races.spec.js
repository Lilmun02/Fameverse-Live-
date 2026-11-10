import { expect, test } from '@playwright/test'

test('duplicate submits coalesce and a late result cannot cross section navigation', async ({ page }) => {
  let finish
  const pending=new Promise(resolve=>{finish=resolve})
  let commands=0
  await page.route('https://**/*',route=>route.abort())
  await page.route('**/api/owner/control',route=>route.fulfill({json:{authorized:true,mode:'owner-access'}}))
  await page.route('**/api/owner/console',async route=>{
    const body=route.request().postDataJSON()
    if(body.action==='preview_action'){
      commands++
      await pending
      return route.fulfill({json:{authorized:true,id:'late-validation',operation:'warn',reason:body.reason,
        applied:false,recorded:false,mode:'preview',message:'Late validation response'}}).catch(()=>{})
    }
    return route.fulfill({json:{authorized:true,items:body.section==='users' ?
      [{id:'22222222-2222-4222-8222-222222222222',username:'reported-member'}] : [],users:1,live:0}})
  })
  await page.goto('/tests/fixtures/owner.html')
  await page.locator('a[href="/owner/users"]').first().click()
  await page.getByRole('button',{name:'Warn member',exact:true}).click()
  await page.getByLabel('Reason and supporting context').fill('Review the submitted incident evidence.')
  await page.locator('.fv-oc-form').evaluate(form=>{form.requestSubmit();form.requestSubmit()})
  await expect.poll(()=>commands).toBe(1)
  await expect(page.locator('#fv-oc-operation')).toBeDisabled()
  await page.goBack()
  await expect(page.getByRole('heading',{name:'Overview',exact:true})).toBeVisible()
  finish()
  // An aborted action may never emit requestfinished; verify through a fresh
  // section read after releasing the stale response rather than sleeping.
  await page.locator('a[href="/owner/audit"]').click()
  await expect(page.getByRole('heading',{name:'Current-page validation history'})).toBeVisible()
  await expect(page.locator('.fv-oc-history')).toHaveCount(0)
  await expect(page.getByText('Late validation response',{exact:true})).toHaveCount(0)
  expect(commands).toBe(1)
})
