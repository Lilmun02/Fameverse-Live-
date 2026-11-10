import { expect, test } from '@playwright/test'

const caseId = '55555555-5555-4555-8555-555555555555'
const subject = '66666666-6666-4666-8666-666666666666'

test.beforeEach(async ({ page }) => {
  await page.route('https://**/*', route => route.abort())
  await page.route('**/api/owner/control', route => route.fulfill({ json: { authorized:true,mode:'owner-access' } }))
})

test('support shows actual intake and preserves the case across audit navigation and Back', async ({ page }) => {
  const reads=[]
  await page.route('**/api/owner/console', route => {
    const body=route.request().postDataJSON();reads.push(body)
    const items=body.section==='support' ? [{
      id:'22222222-2222-4222-8222-222222222222',user_id:subject,category:'account',
      message:'Please investigate my account. <script>bad()</script>',created_at:'2026-11-10T12:00:00Z',
      case:{id:caseId,case_type:'support',status:'under_review',summary:'Account access investigation',updated_at:'2026-11-10T12:00:00Z'},
    }] : [{id:'77777777-7777-4777-8777-777777777777',actor_user_id:subject,case_id:caseId,
      section:'support',operation:'review_support',target_type:'profile',target_id:subject,
      reason:'Reviewed the submitted account evidence.',outcome:'rejected',created_at:'2026-11-10T12:00:00Z'}]
    return route.fulfill({json:{authorized:true,items,total:1}})
  })
  await page.goto('/tests/fixtures/owner.html?section=support')
  await expect(page.getByText('Please investigate my account. <script>bad()</script>',{exact:true})).toBeVisible()
  await page.getByRole('link',{name:'Audit for this case',exact:true}).click()
  await expect(page).toHaveURL(new RegExp('/owner/audit\\?caseId='+caseId))
  await expect(page.getByText('review_support · rejected',{exact:true})).toBeVisible()
  await expect(page.getByText('Reviewed the submitted account evidence.',{exact:true})).toBeVisible()
  expect(reads.at(-1)).toMatchObject({section:'audit',caseId,page:0})
  await page.goBack()
  await expect(page.getByText('Account access investigation',{exact:true})).toBeVisible()
  expect(reads.at(-1)).toMatchObject({section:'support',caseId:''})
  expect(reads).toHaveLength(3)
})

for (const section of ['support','audit','moderation']) {
  test(`${section} remains unavailable when the staged backend is absent`, async ({ page }) => {
    await page.route('**/api/owner/console', route => route.fulfill({json:{authorized:true,
      availability:'requires_isolated_backend',message:'Protected storage is not deployed.'}}))
    await page.goto('/tests/fixtures/owner.html?section='+section)
    await expect(page.getByText('Protected storage is not deployed.',{exact:true})).toBeVisible()
    await expect(page.locator('.fv-oc-record')).toHaveCount(0)
  })
}

test('moderation renders case identity and subject links, never a profile as a case',async({page})=>{
  await page.route('**/api/owner/console',route=>route.fulfill({json:{authorized:true,source:'protected_owner_cases',total:1,
    items:[{id:caseId,subject_user_id:subject,source_feedback_id:'22222222-2222-4222-8222-222222222222',
      case_type:'appeal',status:'under_review',summary:'Review the account appeal',created_at:'2026-11-10T12:00:00Z'}]}}))
  await page.goto('/tests/fixtures/owner.html?section=moderation')
  await expect(page.getByText('Review the account appeal',{exact:true})).toBeVisible()
  await expect(page.getByText('appeal · under_review',{exact:true})).toBeVisible()
  await expect(page.getByRole('link',{name:'Subject profile · '+subject})).toHaveAttribute('href','/profile/'+subject)
  await expect(page.getByRole('link',{name:'Audit for this case',exact:true})).toHaveAttribute('href','/owner/audit?caseId='+caseId)
  await expect(page.getByLabel('Search case summaries')).toBeVisible()
})
