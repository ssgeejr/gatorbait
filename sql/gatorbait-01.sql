SELECT 
	* 
FROM 
	gatorbait.compliance_audit_log
where
	date(run_date) = '2025-07-31'
	and lastlogin is not null
    and type = 0
ORDER BY run_date DESC
LIMIT 10;
    
    
#select * from XREF


X_delete
FROM 
	gatorbait.compliance_audit_log
where
	date(run_date) = '2025-07-31'
    
    
    commit;