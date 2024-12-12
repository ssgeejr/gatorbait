CREATE TABLE IF NOT EXISTS gator (
    gatorid INT AUTO_INCREMENT PRIMARY KEY,
    displayname VARCHAR(64) DEFAULT '',
    email VARCHAR(64) DEFAULT '',
    department VARCHAR(64) DEFAULT '',
    isadmin VARCHAR(64) DEFAULT '',
    mfaenabled VARCHAR(64) DEFAULT ''
);