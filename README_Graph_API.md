## ✅ Recommended: Use a **Client Credential Flow** via App Registration

This avoids user interaction and bypasses MFA entirely — perfect for non-interactive jobs.

### 🔐 Summary of What You Need:

1. **Azure App Registration**
2. **Client Secret** (or Certificate)
3. **API Permissions (Application type, not Delegated)**
4. **PowerShell login using `Connect-MgGraph -ClientId -TenantId -ClientSecret`**

---

## ✅ Step-by-Step Setup (Admin Required)

### 1. **Create an App Registration**

* Go to: **Azure Portal → Azure Active Directory → App registrations**
* Click **"New registration"**
* Name it: `GatorBaitAutomation`
* Supported account types: **Single tenant**
* Redirect URI: leave empty or set to `http://localhost` (not used here)

Take note of:

* **Application (client) ID**
* **Directory (tenant) ID**

---

### 2. **Create a Client Secret**

* App → **Certificates & secrets** → **New client secret**
* Save the **secret value** immediately (you won’t see it again)

---

### 3. **Assign API Permissions**

Under **API permissions**, add:

* `Microsoft Graph → Application permissions`:

  * `User.Read.All`
  * `Directory.Read.All`
  * `AuditLog.Read.All` *(or others based on your needs)*

Then:

* Click **"Grant admin consent"**

---

## ✅ PowerShell Auth Using App Credentials

Once configured, update your script with this:

```powershell
$clientId     = "<APP_CLIENT_ID>"
$tenantId     = "<DIRECTORY_TENANT_ID>"
$clientSecret = "<YOUR_CLIENT_SECRET>"

$secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $secureSecret

Connect-MgGraph -TenantId $tenantId -ClientId $clientId -ClientSecret $secureSecret
```

> You do **not** need `-Credential` here — Graph knows how to interpret client credentials.

---

### ✅ No MFA? No Problem.

* MFA applies only to **user logins**
* This method uses **app identity** → **bypasses all MFA rules**

---

## 🧠 Optional: Secure the Client Secret

Instead of hardcoding, store the secret in:

* An **environment variable**
* An **encrypted file** (e.g., GPG or DPAPI)
* A **Linux secrets store** (e.g., `pass`, `vault`, AWS Secrets Manager)

