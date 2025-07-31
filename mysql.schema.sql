-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS gatorbait;

-- Use the database
USE gatorbait;

-- Create the audit log table if it doesn't exist
CREATE TABLE IF NOT EXISTS compliance_audit_log (
    name        VARCHAR(64) NOT NULL,
    email       VARCHAR(64) NOT NULL,
    department  VARCHAR(64),
    lastlogin   DATETIME NULL,
    numdays  	INT NOT NULL DEFAULT 0,
	created_days INT NOT NULL DEFAULT 0,
    run_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	created 	DATETIME DEFAULT NULL,
    type        TINYINT NOT NULL CHECK (type IN (0, 1, 2))
);

CREATE TABLE IF NOT EXISTS XREF (
    `key`   TINYINT NOT NULL PRIMARY KEY,
    `value` VARCHAR(64) NOT NULL
);

INSERT INTO XREF (`key`, `value`) VALUES
(0, 'Non-Compliant MFA Users'),
(1, 'Active Users Missing Office 365 Login > 90 Days'),
(2, 'Active Users Missing Office 365 Login > 180 Days');

 