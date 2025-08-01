SELECT 
  a.name, 
  b.email, 
  MAX(b.created_days) AS max_created_days
FROM gatorbait.compliance_audit_log a
JOIN gatorbait.compliance_audit_log b 
  ON a.email = b.email
GROUP BY a.name, b.email
ORDER BY a.name;