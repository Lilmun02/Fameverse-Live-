begin;

-- Sep 27 owner decision: Fameverse launches on 70/30. Do not advertise or
-- silently enable a temporary 80/20 beta split that would later be reduced.
update public.fameverse_economy_config
set creator_share_bps = 7000,
    platform_share_bps = 3000,
    updated_at = now()
where id = true;

-- Fail the migration instead of silently accepting an unexpected config row.
do $$
begin
  if not exists (
    select 1
    from public.fameverse_economy_config
    where id = true
      and coins_per_usd = 100
      and creator_share_bps = 7000
      and platform_share_bps = 3000
  ) then
    raise exception 'Fameverse economy config must remain 100 coins per USD and 70/30';
  end if;
end;
$$;

commit;
