SELECT DISTINCT DATE(run_date) AS report_date
FROM compliance_audit_log
ORDER BY report_date DESC
LIMIT 2;



select * 
from 
compliance_audit_log
where date(run_date) = '2025-07-12'
and type = 0