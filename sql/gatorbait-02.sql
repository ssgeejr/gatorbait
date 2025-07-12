use gatorbait


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



