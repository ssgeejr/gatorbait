SELECT 
	name, email, department, created, created_days, lastlogin, numdays
FROM 
	gatorbait.compliance_audit_log
where
	date(run_date) = '2025-08-01'
    and type = 0
order by created_days desc

	and lastlogin is not null
    
    
ORDER BY run_date DESC
LIMIT 10;
    
    
#select * from XREF


X_delete
FROM 
	gatorbait.compliance_audit_log
where
	date(run_date) = '2025-08-01'
    
    
    commit;