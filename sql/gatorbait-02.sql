select a.name,DATE_FORMAT(a.run_date, '%m/%d/%y') as lastLogin,a.numdays,b.value from  compliance_audit_log a, XREF b
where a.type = b.key


-- SELECT DATE_FORMAT(run_date, '%m/%d/%y') AS formatted_date from  compliance_audit_log

-- TRUNCATE TABLE compliance_audit_log;



