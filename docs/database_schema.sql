-- CareGrid Site-Based Healthcare Platform - Database Schema
-- Run this in the Supabase SQL editor to initialize the backend for the app.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==================== ORGANIZATIONS & USERS ====================

CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  code VARCHAR(50) UNIQUE,
  slug VARCHAR(100) UNIQUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organization_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id VARCHAR(100) NOT NULL,
  full_name VARCHAR(200) NOT NULL,
  email VARCHAR(255),
  password_hash TEXT NOT NULL,
  role VARCHAR(50) DEFAULT 'field_worker',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS orgs_select_policy ON organizations;
CREATE POLICY orgs_select_policy ON organizations
  FOR SELECT TO anon, authenticated
  USING (is_active = TRUE);

DROP POLICY IF EXISTS org_users_select_policy ON organization_users;
CREATE POLICY org_users_select_policy ON organization_users
  FOR SELECT TO anon, authenticated
  USING (is_active = TRUE);

DROP FUNCTION IF EXISTS verify_org_user_login_v2(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION verify_org_user_login_v2(
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
  FROM organization_users AS ou
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

CREATE OR REPLACE FUNCTION forgot_org_user_password_v1(
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
  UPDATE organization_users
  SET password_hash = crypt(p_new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE organization_id = p_org_id
    AND is_active = TRUE
    AND (user_id = p_identifier OR email = p_identifier);

  GET DIAGNOSTICS updated_rows = ROW_COUNT;
  RETURN updated_rows > 0;
END;
$$;

INSERT INTO organizations (id, name, code, slug, is_active)
VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'Demo Organization',
  'demo-org',
  'demo-organization',
  TRUE
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO organization_users (
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

CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organization_users_organization_id ON organization_users(organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_users_user_id ON organization_users(user_id);

-- ==================== FIELD/HDSS MODULE ====================

CREATE TABLE IF NOT EXISTS field_grids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  grid_code VARCHAR(50) NOT NULL,
  state VARCHAR(100),
  district VARCHAR(100),
  mandal VARCHAR(100),
  village VARCHAR(100),
  status VARCHAR(20) DEFAULT 'active',
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, grid_code)
);

CREATE TABLE IF NOT EXISTS families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grid_id UUID NOT NULL REFERENCES field_grids(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  family_id VARCHAR(50) NOT NULL,
  family_head_name VARCHAR(200) NOT NULL,
  address TEXT,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, family_id)
);

CREATE TABLE IF NOT EXISTS family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  full_name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  relation VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ==================== CLINIC MODULE ====================

CREATE TABLE IF NOT EXISTS clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  clinic_name VARCHAR(200) NOT NULL,
  clinic_code VARCHAR(50),
  address TEXT,
  contact_number VARCHAR(20),
  status VARCHAR(20) DEFAULT 'active',
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clinic_visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  visit_date DATE NOT NULL,
  form_id VARCHAR(100),
  status VARCHAR(20) DEFAULT 'completed',
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ==================== ANGANWADI MODULE ====================

CREATE TABLE IF NOT EXISTS anganwadis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  anganwadi_name VARCHAR(200) NOT NULL,
  anganwadi_code VARCHAR(50),
  village VARCHAR(100),
  supervisor VARCHAR(200),
  worker_name VARCHAR(200),
  status VARCHAR(20) DEFAULT 'active',
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS anganwadi_children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anganwadi_id UUID NOT NULL REFERENCES anganwadis(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  child_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  parent_name VARCHAR(200),
  muac_measurement DECIMAL(5,2),
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  nutrition_status VARCHAR(50),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, child_id)
);

CREATE TABLE IF NOT EXISTS anganwadi_adolescents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anganwadi_id UUID NOT NULL REFERENCES anganwadis(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  adolescent_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  school_status VARCHAR(50),
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  bmi DECIMAL(5,2),
  menstrual_status VARCHAR(50),
  ifa_supplementation BOOLEAN,
  deworming_status VARCHAR(50),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, adolescent_id)
);

CREATE TABLE IF NOT EXISTS anganwadi_mothers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anganwadi_id UUID NOT NULL REFERENCES anganwadis(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  mother_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  dob DATE,
  pregnancy_status VARCHAR(50),
  number_of_children INTEGER,
  contraceptive_use VARCHAR(50),
  nutrition_status VARCHAR(50),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, mother_id)
);

-- ==================== SCHOOL MODULE ====================

CREATE TABLE IF NOT EXISTS schools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  school_name VARCHAR(200) NOT NULL,
  school_code VARCHAR(50),
  management_type VARCHAR(50),
  location TEXT,
  status VARCHAR(20) DEFAULT 'active',
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  student_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  class_name VARCHAR(20),
  section VARCHAR(20),
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  bmi DECIMAL(5,2),
  vision_status VARCHAR(50),
  hearing_status VARCHAR(50),
  hemoglobin DECIMAL(5,2),
  dental_status VARCHAR(50),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, student_id)
);

-- ==================== WORKPLACE MODULE ====================

CREATE TABLE IF NOT EXISTS workplaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  workplace_name VARCHAR(200) NOT NULL,
  workplace_code VARCHAR(50),
  industry_type VARCHAR(100),
  location TEXT,
  status VARCHAR(20) DEFAULT 'active',
  created_by UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workplace_id UUID NOT NULL REFERENCES workplaces(id),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID,
  worker_id VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  occupation VARCHAR(100),
  job_role VARCHAR(100),
  years_of_exposure DECIMAL(4,1),
  work_schedule VARCHAR(50),
  respiratory_status VARCHAR(50),
  hearing_status VARCHAR(50),
  vision_status VARCHAR(50),
  blood_pressure VARCHAR(20),
  blood_glucose DECIMAL(5,2),
  bmi DECIMAL(5,2),
  ppe_usage BOOLEAN,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, worker_id)
);

-- ==================== UNIFIED BENEFICIARY REGISTRY ====================

CREATE TABLE IF NOT EXISTS master_beneficiaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  individual_id VARCHAR(50) NOT NULL,
  abha_number VARCHAR(50),
  abha_address VARCHAR(200),
  abha_verification_status VARCHAR(20) DEFAULT 'pending',
  abha_linked_mobile VARCHAR(20),
  aadhaar_number_encrypted TEXT,
  aadhaar_last_4 VARCHAR(4),
  aadhaar_verification_status VARCHAR(20) DEFAULT 'pending',
  aadhaar_linked_mobile VARCHAR(20),
  mobile_number VARCHAR(20),
  name VARCHAR(200) NOT NULL,
  dob DATE,
  gender VARCHAR(10),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, individual_id),
  UNIQUE(organization_id, abha_number),
  UNIQUE(organization_id, mobile_number)
);

CREATE TABLE IF NOT EXISTS site_beneficiary_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID NOT NULL REFERENCES master_beneficiaries(id),
  site_type VARCHAR(20) NOT NULL,
  site_id UUID NOT NULL,
  site_specific_id VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT site_beneficiary_unique UNIQUE(master_beneficiary_id, site_type, site_id)
);

-- ==================== UNIFIED FOLLOW-UP SYSTEM ====================

CREATE TABLE IF NOT EXISTS followups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  master_beneficiary_id UUID NOT NULL REFERENCES master_beneficiaries(id),
  site_type VARCHAR(20) NOT NULL,
  site_id UUID NOT NULL,
  form_id VARCHAR(100),
  follow_up_date DATE NOT NULL,
  status VARCHAR(20) DEFAULT 'planned',
  assigned_to UUID,
  assigned_to_name VARCHAR(200),
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  notes TEXT,
  UNIQUE(organization_id, master_beneficiary_id, site_type, form_id, follow_up_date)
);

-- ==================== INDEXES FOR PERFORMANCE ====================

CREATE INDEX IF NOT EXISTS idx_families_grid_id ON families(grid_id);
CREATE INDEX IF NOT EXISTS idx_families_organization_id ON families(organization_id);
CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_master_beneficiary_id ON family_members(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_clinic_visits_clinic_id ON clinic_visits(clinic_id);
CREATE INDEX IF NOT EXISTS idx_clinic_visits_master_beneficiary_id ON clinic_visits(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_anganwadi_children_anganwadi_id ON anganwadi_children(anganwadi_id);
CREATE INDEX IF NOT EXISTS idx_anganwadi_adolescents_anganwadi_id ON anganwadi_adolescents(anganwadi_id);
CREATE INDEX IF NOT EXISTS idx_anganwadi_mothers_anganwadi_id ON anganwadi_mothers(anganwadi_id);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_master_beneficiary_id ON students(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_workers_workplace_id ON workers(workplace_id);
CREATE INDEX IF NOT EXISTS idx_workers_master_beneficiary_id ON workers(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_site_beneficiary_links_master_beneficiary_id ON site_beneficiary_links(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_followups_master_beneficiary_id ON followups(master_beneficiary_id);
CREATE INDEX IF NOT EXISTS idx_followups_organization_id ON followups(organization_id);
CREATE INDEX IF NOT EXISTS idx_followups_follow_up_date ON followups(follow_up_date);
CREATE INDEX IF NOT EXISTS idx_followups_status ON followups(status);
CREATE INDEX IF NOT EXISTS idx_master_beneficiaries_aadhaar_last_4 ON master_beneficiaries(aadhaar_last_4);
CREATE INDEX IF NOT EXISTS idx_master_beneficiaries_mobile_number ON master_beneficiaries(mobile_number);
