-- Build 33 candidate: owner-reviewed gifter badge imports (NOT deployed automatically).
-- Draft transfer recognition: cap at Lv. 25, independent of real Fameverse spend.
-- Conversion is enforced by the backend after the owner explicitly approves proof.
-- Imported recognition is separate from coins sent, wallet balances and payouts.
begin;

create table if not exists public.badge_transfer_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source_platform text not null check (source_platform in ('tiktok', 'favorited', 'epic')),
  source_username text not null check (length(trim(source_username)) between 2 and 80),
  source_level integer not null check (source_level between 1 and 99),
  constraint badge_claim_tiktok_gifter_limit check (
    source_platform <> 'tiktok' or source_level <= 50
  ),
  evidence_path text not null check (length(evidence_path) between 42 and 240),
  status text not null default 'pending'
    check (status in ('pending','needs_info','rejected','approved')),
  approved_level integer check (approved_level between 1 and 99),
  reviewed_by uuid references public.profiles(id),
  review_note text,
  reviewed_at timestamptz,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint approved_claim_has_level check (
    (status = 'approved' and approved_level is not null)
    or (status <> 'approved' and approved_level is null)
  )
);

create unique index if not exists badge_claim_single_open_or_approved
on public.badge_transfer_claims (user_id)
where status in ('pending', 'needs_info', 'approved');

create unique index if not exists badge_claim_unique_approved_external_identity
on public.badge_transfer_claims (source_platform, lower(source_username))
where status = 'approved';

create index if not exists badge_claim_owner_queue
on public.badge_transfer_claims (status, submitted_at desc);

create table if not exists public.badge_imports (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  approved_level integer not null check (approved_level between 1 and 99),
  source_platform text not null check (source_platform in ('tiktok','favorited','epic')),
  source_claim_id uuid not null unique references public.badge_transfer_claims(id),
  approved_by uuid not null references public.profiles(id),
  approved_at timestamptz not null default now()
);

-- Private evidence: never use a public bucket for a source-app account recording.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'badge-transfer-proofs', 'badge-transfer-proofs', false, 52428800,
  array['video/mp4','video/quicktime','video/webm']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Proposed Fameverse policy. NOT reverse engineered from Echo or EPIC.
-- A badge from elsewhere is VERIFIED RECOGNITION, never purchased Fame Coins.
-- F = min(25, 5 + floor(source_level * 2 / 5)).
create or replace function public.calculate_badge_transfer_level(
  p_source_platform text,
  p_source_level integer
) returns integer
language plpgsql immutable
set search_path = public, pg_temp
as $
declare
  v_source text := lower(trim(coalesce(p_source_platform, '')));
begin
  if v_source not in ('tiktok','favorited','epic')
    or p_source_level is null
    or p_source_level not between 1 and 99
    or (v_source = 'tiktok' and p_source_level > 50) then
    raise exception 'Unsupported source badge level'
      using errcode = '22023';
  end if;
  return least(25, 5 + floor(p_source_level::numeric * 2 / 5)::integer);
end;
$;
revoke all on function public.calculate_badge_transfer_level(text, integer) from public, anon;
grant execute on function public.calculate_badge_transfer_level(text, integer) to authenticated;

create or replace function public._badge_transfer_is_owner()
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.account_roles
    where user_id = auth.uid() and role = 'owner'
  );
$$;
revoke all on function public._badge_transfer_is_owner() from public, anon;
grant execute on function public._badge_transfer_is_owner() to authenticated;

alter table public.badge_transfer_claims enable row level security;
alter table public.badge_imports enable row level security;

drop policy if exists "Members and owner can see badge claims" on public.badge_transfer_claims;
create policy "Members and owner can see badge claims"
on public.badge_transfer_claims for select to authenticated
using (user_id = (select auth.uid()) or public._badge_transfer_is_owner());

-- No client writes to claims/imports. RPCs below are the only mutation path.
revoke all on public.badge_transfer_claims from anon, authenticated;
grant select on public.badge_transfer_claims to authenticated;

drop policy if exists "Approved badge levels are visible" on public.badge_imports;
create policy "Approved badge levels are visible"
on public.badge_imports for select to authenticated using (true);
revoke all on public.badge_imports from anon, authenticated;
grant select on public.badge_imports to authenticated;

drop policy if exists "Badge proof uploader owns path" on storage.objects;
create policy "Badge proof uploader owns path"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'badge-transfer-proofs'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
drop policy if exists "Badge proofs readable by owner or uploader" on storage.objects;
create policy "Badge proofs readable by owner or uploader"
on storage.objects for select to authenticated
using (
  bucket_id = 'badge-transfer-proofs'
  and (
    (storage.foldername(name))[1] = (select auth.uid()::text)
    or public._badge_transfer_is_owner()
  )
);

create or replace function public.submit_badge_transfer_claim(
  p_source_platform text,
  p_source_username text,
  p_source_level integer,
  p_evidence_path text
) returns uuid
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_platform text := lower(trim(coalesce(p_source_platform, '')));
  v_username text := trim(coalesce(p_source_username, ''));
  v_path text := trim(coalesce(p_evidence_path, ''));
  v_existing public.badge_transfer_claims%rowtype;
  v_id uuid;
begin
  if v_user is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  if v_platform not in ('tiktok','favorited','epic') then
    raise exception 'Unsupported source platform' using errcode = '22023';
  end if;
  if length(v_username) not between 2 and 80 or v_username !~ '^[[:alnum:]_.@-]+$' then
    raise exception 'Enter the source account username' using errcode = '22023';
  end if;
  -- Source-specific validation also rejects impossible TikTok gifter grades.
  perform public.calculate_badge_transfer_level(v_platform, p_source_level);
  if v_path !~ ('^' || v_user::text || '/[A-Za-z0-9_-]+[.](mp4|mov|webm)$') then
    raise exception 'Proof must be uploaded to your private account folder' using errcode = '22023';
  end if;
  if not exists (
    select 1 from storage.objects o
    where o.bucket_id = 'badge-transfer-proofs' and o.name = v_path
    and o.created_at > now() - interval '30 days'
    and coalesce((o.metadata->>'size')::bigint, 0) <= 52428800
    and coalesce(o.metadata->>'mimetype','') in (
      'video/mp4','video/quicktime','video/webm'
    )
  ) then
    raise exception 'Upload a valid private video recording first' using errcode = '22023';
  end if;
  if exists (select 1 from public.badge_imports where user_id = v_user) then
    raise exception 'This account already has an approved badge transfer' using errcode = '23505';
  end if;

  -- Lock the user's profile to serialize simultaneous submissions.
  perform 1 from public.profiles where id = v_user for update;
  if not found then raise exception 'Profile is required' using errcode = '42501'; end if;

  select * into v_existing from public.badge_transfer_claims
  where user_id = v_user and status in ('pending','needs_info','approved')
  order by submitted_at desc limit 1 for update;

  if found and v_existing.status <> 'needs_info' then
    raise exception 'Your previous badge transfer is already waiting or approved' using errcode = '23505';
  end if;

  if v_existing.id is not null then
    update public.badge_transfer_claims
    set source_platform = v_platform, source_username = v_username,
        source_level = p_source_level, evidence_path = v_path, status = 'pending',
        reviewed_by = null, review_note = null, reviewed_at = null,
        updated_at = now(), submitted_at = now()
    where id = v_existing.id
    returning id into v_id;
  else
    insert into public.badge_transfer_claims (
      user_id,source_platform,source_username,source_level,evidence_path
    ) values (v_user,v_platform,v_username,p_source_level,v_path)
    returning id into v_id;
  end if;
  return v_id;
end;
$$;
revoke all on function public.submit_badge_transfer_claim(text,text,integer,text) from public, anon;
grant execute on function public.submit_badge_transfer_claim(text,text,integer,text) to authenticated;

create or replace function public.owner_review_badge_transfer(
  p_claim_id uuid,
  p_decision text,
  p_approved_level integer default null,
  p_note text default null
) returns integer
language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_owner uuid := auth.uid();
  v_claim public.badge_transfer_claims%rowtype;
  v_decision text := lower(trim(coalesce(p_decision,'')));
  v_note text := left(trim(coalesce(p_note,'')), 1000);
  v_transfer_level integer;
begin
  if v_owner is null or not public._badge_transfer_is_owner() then
    raise exception 'Owner review is required' using errcode = '42501';
  end if;
  if v_decision not in ('approved','rejected','needs_info') then
    raise exception 'Unknown review decision' using errcode = '22023';
  end if;

  select * into v_claim
  from public.badge_transfer_claims
  where id = p_claim_id for update;
  if not found then raise exception 'Badge transfer claim not found' using errcode = '22023'; end if;
  if v_claim.status <> 'pending' then
    raise exception 'Claim has already been reviewed; refresh the queue' using errcode = '23505';
  end if;

  if v_decision = 'approved' then
    v_transfer_level := public.calculate_badge_transfer_level(
      v_claim.source_platform, v_claim.source_level
    );
    -- Never accept arbitrary inflated levels from a modified web client.
    if p_approved_level is not null and p_approved_level <> v_transfer_level then
      raise exception 'Transfer level is calculated by the Fameverse policy'
        using errcode = '22023';
    end if;
    if exists (select 1 from public.badge_imports where user_id = v_claim.user_id) then
      raise exception 'A badge has already been imported for this user' using errcode = '23505';
    end if;
    -- Unique approved account identity prevents reusing another person's proof.
    update public.badge_transfer_claims
    set status = 'approved', approved_level = v_transfer_level,
        reviewed_by = v_owner, reviewed_at = now(), review_note = v_note,
        updated_at = now()
    where id = v_claim.id;

    -- Same transaction: owner approval immediately becomes public badge identity.
    insert into public.badge_imports (
      user_id,approved_level,source_platform,source_claim_id,approved_by
    ) values (
      v_claim.user_id,v_transfer_level,v_claim.source_platform,v_claim.id,v_owner
    );
    return v_transfer_level;
  end if;

  update public.badge_transfer_claims
  set status = v_decision, approved_level = null,
      reviewed_by = v_owner, reviewed_at = now(), review_note = v_note,
      updated_at = now()
  where id = v_claim.id;
  return null;
end;
$$;
revoke all on function public.owner_review_badge_transfer(uuid,text,integer,text) from public, anon;
grant execute on function public.owner_review_badge_transfer(uuid,text,integer,text) to authenticated;

commit;
