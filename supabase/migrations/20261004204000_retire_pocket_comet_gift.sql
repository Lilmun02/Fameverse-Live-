begin;

-- Build 32 gift cleanup: retire Pocket Comet without deleting historical
-- gift events or ledger rows that may reference the old gift id.
update public.fameverse_gift_catalog
set active = false,
    updated_at = now()
where id = 'pocket-comet';

commit;
