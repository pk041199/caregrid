-- Demo organization and user setup for CareGrid
-- Run this after setup_auth_rpcs.sql if the demo organization/user records are missing.

INSERT INTO public.organizations (id, name, code, slug, is_active)
VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'Demo Organization',
  'demo-org',
  'demo-organization',
  TRUE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.organization_users (
  organization_id,
  user_id,
  full_name,
  email,
  password_hash,
  role,
  is_active
)
VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'demo-field',
  'Demo Field Worker',
  'demo.field@caregrid.local',
  crypt('demo123', gen_salt('bf')),
  'field_worker',
  TRUE
)
ON CONFLICT (organization_id, user_id) DO NOTHING;

INSERT INTO public.organization_users (
  organization_id,
  user_id,
  full_name,
  email,
  password_hash,
  role,
  is_active
)
VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'demo-doctor',
  'Demo Doctor',
  'demo.doctor@caregrid.local',
  crypt('demo123', gen_salt('bf')),
  'doctor',
  TRUE
)
ON CONFLICT (organization_id, user_id) DO NOTHING;

INSERT INTO public.organization_users (
  organization_id,
  user_id,
  full_name,
  email,
  password_hash,
  role,
  is_active
)
VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'demo-patient',
  'Demo Patient',
  'demo.patient@caregrid.local',
  crypt('demo123', gen_salt('bf')),
  'patient',
  TRUE
)
ON CONFLICT (organization_id, user_id) DO NOTHING;
