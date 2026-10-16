-- Fameverse policy v1 — REVIEW-ONLY STAGING SQL.
-- DO NOT execute against production until security/financial review and staged QA.
-- Database objects are server-authoritative and require authenticated user IDs.
-- Enabling policy versions and enforcing account restrictions are separate release gates.

BEGIN;

CREATE TABLE public.fv_policy_versions (
  version text PRIMARY KEY,
  terms_text text NOT NULL,
  community_text text NOT NULL,
  financial_text text NOT NULL,
  privacy_text text NOT NULL,
  effective_at timestamptz NOT NULL,
  active boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT nonblank_policy CHECK (length(trim(terms_text)) > 30 AND length(trim(financial_text)) > 30)
);
CREATE UNIQUE INDEX fv_one_active_policy ON public.fv_policy_versions (active) WHERE active;

CREATE TABLE public.fv_policy_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  version text NOT NULL REFERENCES public.fv_policy_versions(version),
  accepted_at timestamptz NOT NULL DEFAULT now(),
  acceptance_method text NOT NULL DEFAULT 'in_app_checkbox' CHECK (acceptance_method = 'in_app_checkbox'),
  UNIQUE(user_id, version)
);

CREATE TABLE public.fv_account_owner_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewer_note text NOT NULL DEFAULT ''
);
CREATE TABLE public.fv_account_links (
  group_id uuid NOT NULL REFERENCES public.fv_account_owner_groups(id) ON DELETE CASCADE,
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
  verified_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  verified_at timestamptz NOT NULL DEFAULT now(),
  evidence_reference text,
  PRIMARY KEY(group_id, user_id)
);
-- Enforce at most two verified accounts per owner group even during concurrent inserts.
CREATE FUNCTION public.fv_enforce_two_account_limit() RETURNS trigger
LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $fn$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.group_id::text, 0));
  IF (SELECT count(*) FROM public.fv_account_links WHERE group_id = NEW.group_id) >= 2 THEN
    RAISE EXCEPTION 'Maximum two Fameverse accounts per verified person';
  END IF;
  RETURN NEW;
END;
$fn$;
CREATE TRIGGER fv_max_two_accounts BEFORE INSERT ON public.fv_account_links
FOR EACH ROW EXECUTE FUNCTION public.fv_enforce_two_account_limit();

CREATE TABLE public.fv_account_standing (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'good_standing'
    CHECK (status IN ('good_standing','under_investigation','financially_restricted','suspended','pending_termination','permanently_banned')),
  restrict_gifts boolean NOT NULL DEFAULT false,
  restrict_payouts boolean NOT NULL DEFAULT false,
  reason_code text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.fv_violation_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  kind text NOT NULL CHECK (kind IN ('dispute_fraud','chargeback_abuse','refund_abuse','stolen_payment','gift_abuse','payout_abuse','account_circumvention','other')),
  status text NOT NULL DEFAULT 'under_review' CHECK (status IN ('under_review','substantiated','dismissed','appealed','resolved')),
  provider_event_reference text,
  evidence_reference text,
  facts_summary text NOT NULL DEFAULT '',
  owner_decision text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  opened_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);
CREATE TABLE public.fv_enforcement_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  case_id uuid REFERENCES public.fv_violation_cases(id) ON DELETE SET NULL,
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.fv_policy_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_policy_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_account_owner_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_account_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_account_standing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_violation_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fv_enforcement_audit ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.fv_policy_versions, public.fv_policy_acceptances,
  public.fv_account_owner_groups, public.fv_account_links,
  public.fv_account_standing, public.fv_violation_cases,
  public.fv_enforcement_audit FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.fv_policy_versions TO authenticated;
GRANT SELECT ON public.fv_policy_acceptances TO authenticated;
GRANT SELECT ON public.fv_account_standing TO authenticated;
CREATE POLICY fv_read_published_terms ON public.fv_policy_versions FOR SELECT TO authenticated USING (active);
CREATE POLICY fv_read_own_acceptances ON public.fv_policy_acceptances FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
CREATE POLICY fv_read_own_standing ON public.fv_account_standing FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
-- No untrusted user role can directly create or alter policy, moderation or financial standing records.

CREATE FUNCTION public.fv_get_policy_requirement() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE selected public.fv_policy_versions%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
  SELECT * INTO selected FROM public.fv_policy_versions WHERE active LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'Fameverse policy is not yet published'; END IF;
  RETURN jsonb_build_object(
    'version',selected.version,'terms',selected.terms_text,
    'community',selected.community_text,'financial',selected.financial_text,
    'privacy',selected.privacy_text,'accepted',
    EXISTS (SELECT 1 FROM public.fv_policy_acceptances
            WHERE user_id = auth.uid() AND version = selected.version)
  );
END;
$fn$;

CREATE FUNCTION public.fv_accept_current_policy() RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE v text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
  SELECT version INTO v FROM public.fv_policy_versions WHERE active FOR SHARE;
  IF v IS NULL THEN RAISE EXCEPTION 'Fameverse policy is not yet published'; END IF;
  INSERT INTO public.fv_policy_acceptances(user_id,version)
    VALUES (auth.uid(),v) ON CONFLICT (user_id,version) DO NOTHING;
  RETURN jsonb_build_object('accepted',true,'version',v);
END;
$fn$;

-- This is a read-only helper; DOES NOT automatically change money permissions.
-- Each authoritative gift/payout RPC must be separately reviewed and wired to check it.
CREATE FUNCTION public.fv_financial_permissions() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE s record;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
  SELECT status,restrict_gifts,restrict_payouts INTO s
  FROM public.fv_account_standing WHERE user_id = auth.uid();
  RETURN jsonb_build_object(
    'standing',coalesce(s.status,'good_standing'),
    'can_gift',NOT coalesce(s.restrict_gifts,false),
    'can_payout',NOT coalesce(s.restrict_payouts,false)
  );
END;
$fn$;

REVOKE ALL ON FUNCTION public.fv_get_policy_requirement() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.fv_accept_current_policy() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.fv_financial_permissions() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.fv_get_policy_requirement() TO authenticated;
GRANT EXECUTE ON FUNCTION public.fv_accept_current_policy() TO authenticated;
GRANT EXECUTE ON FUNCTION public.fv_financial_permissions() TO authenticated;

INSERT INTO public.fv_policy_versions
 (version,terms_text,community_text,financial_text,privacy_text,effective_at,active)
VALUES (
 '2026-10-15-v1',
 'Fameverse Live Terms of Service. Each person may operate at most two accounts. Users may not evade suspensions, impersonate others, manipulate rewards or exploit platform services. Accounts determined to exceed this limit after reliable identity review may face restrictions. Similar usernames, shared devices or IP addresses alone are not proof of ownership. Serious confirmed misconduct may lead to suspension or termination, with documented review.',
 'Fameverse Community Standards. Do not harass, threaten, dox, impersonate to defraud, scam, misuse gifts, exploit creator rewards, or circumvent safety restrictions. Moderation decisions are documented and subject to review.',
 'Fameverse Financial Protection Policy. Fraudulent purchases, stolen payment methods, deliberately dishonest chargebacks, repeated intentional refund abuse, gift/earnings manipulation and payout fraud are prohibited. A lawful refund or good-faith billing dispute is not automatically fraud. Credible evidence of financial abuse may lead to a documented investigation and proportionate temporary restrictions on affected gift sending or payouts. Permanent bans require review of substantiated serious misconduct. Legitimate undisputed earnings remain accounted for and applicable payment/legal obligations still apply.',
 'Fameverse Privacy Notice. Fameverse stores account identity, policy version/acceptance timestamps, verified account links, violation case statuses, security evidence references, and administrative enforcement records to administer the service and prevent fraud. Sensitive records are limited to authorized personnel. Applicable retention, appeal and account-deletion rights remain in effect; consent records may be retained only where lawfully permitted.',
 '2026-10-15T00:00:00Z', false
);

COMMIT;
-- Separate, owner-approved rollout after counsel/QA: SET active=true, enable clients,
-- verify RPCs and compliance controls, then wire authoritative gift/payout
-- checks with dedicated regression tests. No active policy is created by this script.
