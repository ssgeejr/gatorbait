INSERT INTO compliance_audit_log (name, email, department, lastlogin, numdays, type, run_date)
SELECT
    name,
    email,
    department,
    lastlogin,
    numdays,
    type,
    run_date - INTERVAL 7 DAY
FROM compliance_audit_log
WHERE DATE(run_date) = '2025-07-11'



DELETE FROM compliance_audit_log
WHERE DATE(run_date) = '2025-07-04'
  AND type = 0
LIMIT 3;
DELETE FROM compliance_audit_log
WHERE DATE(run_date) = '2025-07-04'
  AND type = 2
LIMIT 11;
DELETE FROM compliance_audit_log
WHERE DATE(run_date) = '2025-07-04'
  AND type = 2
LIMIT 4;

SELECT * FROM compliance_audit_log
WHERE DATE(run_date) = '2025-07-04'
  AND type = 0
LIMIT 3;