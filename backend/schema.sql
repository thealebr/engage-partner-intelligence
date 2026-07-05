PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS partners (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  canonical_name TEXT NOT NULL,
  normalized_name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS import_batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_owner TEXT NOT NULL,
  year INTEGER NOT NULL CHECK(year >= 2020),
  quarter INTEGER NOT NULL CHECK(quarter BETWEEN 1 AND 4),
  version INTEGER NOT NULL,
  engage_file TEXT NOT NULL,
  specialize_file TEXT NOT NULL,
  engage_sha256 TEXT NOT NULL,
  specialize_sha256 TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('complete','superseded')),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  imported_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(account_owner, year, quarter, version)
);
CREATE UNIQUE INDEX IF NOT EXISTS one_active_batch_per_period
ON import_batches(account_owner, year, quarter) WHERE is_active = 1;
CREATE TABLE IF NOT EXISTS partner_snapshots (
  batch_id INTEGER NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
  partner_id INTEGER NOT NULL REFERENCES partners(id),
  engagement_level TEXT NOT NULL,
  integrator_compliant INTEGER NOT NULL CHECK(integrator_compliant IN (0,1)),
  mssp_account INTEGER NOT NULL CHECK(mssp_account IN (0,1)),
  mssp_compliant INTEGER NOT NULL CHECK(mssp_compliant IN (0,1)),
  PRIMARY KEY(batch_id, partner_id)
);
CREATE TABLE IF NOT EXISTS specialization_snapshots (
  batch_id INTEGER NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
  partner_id INTEGER NOT NULL REFERENCES partners(id),
  sd_wan INTEGER NOT NULL DEFAULT 0,
  sase INTEGER NOT NULL DEFAULT 0,
  secure_networking_lan INTEGER NOT NULL DEFAULT 0,
  cloud_security INTEGER NOT NULL DEFAULT 0,
  secure_networking_firewall INTEGER NOT NULL DEFAULT 0,
  security_operations INTEGER NOT NULL DEFAULT 0,
  ot INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(batch_id, partner_id)
);


CREATE TABLE IF NOT EXISTS exam_import_batches (id INTEGER PRIMARY KEY AUTOINCREMENT,account_owner TEXT NOT NULL,year INTEGER NOT NULL,quarter INTEGER NOT NULL CHECK(quarter BETWEEN 1 AND 4),version INTEGER NOT NULL,source_file TEXT NOT NULL,source_sha256 TEXT NOT NULL,status TEXT NOT NULL CHECK(status IN ('complete','superseded')),is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),imported_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE(account_owner,year,quarter,version));
CREATE UNIQUE INDEX IF NOT EXISTS one_active_exam_batch_per_period ON exam_import_batches(account_owner,year,quarter) WHERE is_active=1;
CREATE TABLE IF NOT EXISTS exam_snapshots (batch_id INTEGER NOT NULL REFERENCES exam_import_batches(id) ON DELETE CASCADE,partner_id INTEGER NOT NULL REFERENCES partners(id),engagement_level TEXT NOT NULL,fcf INTEGER NOT NULL DEFAULT 0,fca INTEGER NOT NULL DEFAULT 0,fcp INTEGER NOT NULL DEFAULT 0,fcss INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(batch_id,partner_id));
CREATE TABLE IF NOT EXISTS compliance_requirements (model TEXT NOT NULL,engagement_level TEXT NOT NULL,certification TEXT NOT NULL,required_count INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(model,engagement_level,certification));
INSERT OR IGNORE INTO compliance_requirements VALUES
('INTEGRATOR','Select','FCF',1),('INTEGRATOR','Select','FCA',0),('INTEGRATOR','Select','FCP',1),('INTEGRATOR','Select','FCSS',0),('INTEGRATOR','Advanced','FCF',2),('INTEGRATOR','Advanced','FCA',1),('INTEGRATOR','Advanced','FCP',1),('INTEGRATOR','Advanced','FCSS',1),('INTEGRATOR','Expert','FCF',2),('INTEGRATOR','Expert','FCA',2),('INTEGRATOR','Expert','FCP',1),('INTEGRATOR','Expert','FCSS',2),('MSSP','Select','FCF',1),('MSSP','Select','FCA',0),('MSSP','Select','FCP',2),('MSSP','Select','FCSS',0),('MSSP','Advanced','FCF',2),('MSSP','Advanced','FCA',1),('MSSP','Advanced','FCP',1),('MSSP','Advanced','FCSS',2),('MSSP','Expert','FCF',2),('MSSP','Expert','FCA',2),('MSSP','Expert','FCP',1),('MSSP','Expert','FCSS',3);
