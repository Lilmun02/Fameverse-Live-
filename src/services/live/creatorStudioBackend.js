import { supabase } from '../supabase.js'

const DRAFT_FIELDS = 'title, goal, wishlist_gift_ids, updated_at'

function normalizeWishlist(values) {
  if (!Array.isArray(values)) return []
  return [...new Set(values.filter((value) => typeof value === 'string' && value.trim()).map((value) => value.trim()))].slice(0, 10)
}

function normalizeDraft({ title = '', goal = '', wishlistGiftIds = [] } = {}) {
  return {
    title: String(title || '').trim().slice(0, 120),
    goal: String(goal || '').trim().slice(0, 280),
    wishlistGiftIds: normalizeWishlist(wishlistGiftIds),
  }
}

export async function loadCreatorLiveDraft(userId) {
  if (!userId) return { draft: null, error: null }

  const { data, error } = await supabase
    .from('creator_live_drafts')
    .select(DRAFT_FIELDS)
    .eq('user_id', userId)
    .maybeSingle()

  if (error) return { draft: null, error }
  if (!data) return { draft: normalizeDraft(), error: null }

  return {
    draft: normalizeDraft({
      title: data.title,
      goal: data.goal,
      wishlistGiftIds: data.wishlist_gift_ids,
    }),
    error: null,
  }
}

export async function saveCreatorLiveDraft({ userId, title, goal, wishlistGiftIds }) {
  if (!userId) return { draft: null, error: new Error('missing-user') }

  const draft = normalizeDraft({ title, goal, wishlistGiftIds })
  const { data, error } = await supabase
    .from('creator_live_drafts')
    .upsert({
      user_id: userId,
      title: draft.title,
      goal: draft.goal,
      wishlist_gift_ids: draft.wishlistGiftIds,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' })
    .select(DRAFT_FIELDS)
    .single()

  if (error) return { draft: null, error }

  return {
    draft: normalizeDraft({
      title: data?.title,
      goal: data?.goal,
      wishlistGiftIds: data?.wishlist_gift_ids,
    }),
    error: null,
  }
}
