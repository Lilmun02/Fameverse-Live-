import { expect, test } from '@playwright/test'
const room='22222222-2222-4222-8222-222222222222'
const user='33333333-3333-4333-8333-333333333333'
test.beforeEach(async ({ page }) => {
  await page.route('https://**/*', route=>route.abort())
  await page.route('**/api/owner/control', route=>route.fulfill({json:{authorized:true,mode:'owner-access'}}))
})
test('switching live controls uses the room for end and the member for mute', async ({ page }) => {
  const commands=[]
  await page.route('**/api/owner/console', route=>{
    const body=route.request().postDataJSON()
    if(body.action==='preview_action'){
      commands.push(body)
      return route.fulfill({json:{authorized:true,id:'fixture-validation',...body,applied:false,recorded:false,mode:'preview',message:'Validation only'}})
    }
    return route.fulfill({json:{authorized:true,items:[{id:room,host_user_id:user,title:'Live fixture'}]}})
  })
  await page.goto('/tests/fixtures/owner.html?section=live')
  await page.getByRole('button',{name:'Kick from live',exact:true}).click()
  const target=page.getByLabel('Target user / room / request ID')
  await expect(target).toHaveValue(user)
  await page.locator('#fv-oc-operation').selectOption('end_live')
  await expect(target).toHaveValue(room)
  await page.getByLabel('Reason and supporting context').fill('Review the broadcast incident evidence.')
  await page.getByRole('button',{name:'Validate in preview'}).click()
  await expect(page.locator('.fv-oc-notice').filter({hasText:'Validation only'})).toBeVisible()
  expect(commands[0]).toMatchObject({operation:'end_live',targetId:room})
  await page.locator('#fv-oc-operation').selectOption('mute_live')
  await expect(target).toHaveValue(user)
})
test('finance fraud review does not treat the payout request as a member', async ({ page })=>{
  await page.route('**/api/owner/console',route=>route.fulfill({json:{authorized:true,items:[{payout_id:room,user_id:user}]}}))
  await page.goto('/tests/fixtures/owner.html?section=finance')
  await page.getByRole('button',{name:'Hold payout for review',exact:true}).click()
  const target=page.getByLabel('Target user / room / request ID')
  await expect(target).toHaveValue(room)
  await page.locator('#fv-oc-operation').selectOption('review_fraud')
  await expect(target).toHaveValue(user)
})
