use gatorbait

SELECT count(*) FROM gatorbait.compliance_audit_log
where type = 0
and date(run_date) = '2025-07-14'

#select * from XREF


select distinct(date(run_date)) FROM gatorbait.compliance_audit_log




ALTER TABLE compliance_audit_log
ADD COLUMN created DATETIME DEFAULT NULL AFTER department;


ALTER TABLE compliance_audit_log
ADD COLUMN created_days INT NOT NULL DEFAULT 0;

UPDATE compliance_audit_log
SET numdays = 0
WHERE numdays IS NULL;

ALTER TABLE compliance_audit_log
MODIFY COLUMN numdays INT NOT NULL DEFAULT 0;

select 
	a.name,
	DATE_FORMAT(a.run_date, '%m/%d/%y') as lastLogin,
	a.numdays,
	b.value 
from
	compliance_audit_log a, XREF b
where
	a.type = b.key
    
 SELECT DATE(MAX(run_date)) FROM compliance_audit_log;
 
SELECT name, email, department, lastlogin, numdays FROM compliance_audit_log WHERE run_date = '07/11/25' AND type = 0

SELECT name, email, department, lastlogin, numdays FROM compliance_audit_log WHERE DATE_FORMAT(run_date, '%m/%d/%y') =  '07/11/25' AND type = 0

-- SELECT DATE_FORMAT(run_date, '%m/%d/%y') AS formatted_date from  compliance_audit_log

SELECT max(DATE_FORMAT(run_date, '%m/%d/%y')) AS formatted_date from  compliance_audit_log

SELECT * from XREF where XREF.key = 0


-- TRUNCATE TABLE compliance_audit_log;



