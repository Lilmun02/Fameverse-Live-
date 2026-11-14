revoke select on table public.account_roles from anon;

drop function if exists public.get_my_fameverse_identity();
create function public.get_my_fameverse_identity()
returns table(
  user_id uuid,
  username text,
  display_name text,
  bio text,
  avatar_url text,
  role text
)
language sql
stable
security invoker
set search_path to 'public', 'pg_temp'
as $function$
  select
    p.id as user_id,
    p.username,
    p.display_name,
    coalesce(p.bio, '') as bio,
    p.avatar_url,
    lower(trim(r.role)) as role
  from public.profiles p
  left join public.account_roles r on r.user_id = p.id
  where p.id = auth.uid()
  limit 1;
$function$;

revoke all on function public.get_my_fameverse_identity() from public, anon;
grant execute on function public.get_my_fameverse_identity() to authenticated;
