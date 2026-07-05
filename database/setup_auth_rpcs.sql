-- Supabase auth RPC definitions for CareGrid
-- Run this in the Supabase SQL editor for the project configured in lib/config/supabase_config.dart

DROP FUNCTION IF EXISTS public.verify_org_user_login_v2(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.verify_org_user_login_v2(
  p_org_id UUID,
  p_identifier TEXT,
  p_pwd TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_record RECORD;
BEGIN
  SELECT
    ou.user_id,
    ou.organization_id,
    ou.full_name,
    ou.role
  INTO v_record
  FROM public.organization_users AS ou
  WHERE ou.organization_id = p_org_id
    AND ou.is_active = TRUE
    AND (
      ou.user_id = p_identifier OR ou.email = p_identifier
    )
    AND ou.password_hash = crypt(p_pwd, ou.password_hash)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_record.user_id,
    'organization_id', v_record.organization_id,
    'full_name', v_record.full_name,
    'role', v_record.role
  );
END;
$$;

DROP FUNCTION IF EXISTS public.verify_org_user_login(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.verify_org_user_login(
  p_organization_id UUID,
  p_identifier TEXT,
  p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_record RECORD;
BEGIN
  SELECT
    ou.user_id,
    ou.organization_id,
    ou.full_name,
    ou.role
  INTO v_record
  FROM public.organization_users AS ou
  WHERE ou.organization_id = p_organization_id
    AND ou.is_active = TRUE
    AND (
      ou.user_id = p_identifier OR ou.email = p_identifier
    )
    AND ou.password_hash = crypt(p_password, ou.password_hash)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_record.user_id,
    'organization_id', v_record.organization_id,
    'full_name', v_record.full_name,
    'role', v_record.role
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.forgot_org_user_password_v1(
  p_org_id UUID,
  p_identifier TEXT,
  p_new_password TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  updated_rows INT;
BEGIN
  UPDATE public.organization_users
  SET password_hash = crypt(p_new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE organization_id = p_org_id
    AND is_active = TRUE
    AND (user_id = p_identifier OR email = p_identifier);

  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  RETURN updated_rows > 0;
END;
$$;
