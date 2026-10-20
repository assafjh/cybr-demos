# Central Credential Provider
## Powershell scripts
1. `01-Install-IISFeatures.ps1` - Install required IIS features.
2. `02-CreateFolders.ps1` - Create installation folders.
3. `03-IIS-Enable-WindowsAuthentication.ps1` - Enable Windows Authentication on the CCP IIS application.
4. `04-GetAIMPassword-REST.ps1` - Account retrieval using a REST call (Windows PowerShell 5.1 and PowerShell 7+).
5. `05-GetPassword-SOAP.ps1` - Account retrieval using a SOAP call.
6. `06-GetCCPCredential-Module.ps1` - Account retrieval using the community [CredentialRetriever](https://github.com/pspete/CredentialRetriever) PowerShell module.
7. `07-Find-CCPObject.ps1` - Troubleshooting helper: finds accounts in a Safe using the community [psPAS](https://github.com/pspete/psPAS) module, shows the exact Object name to use in a CCP request, and checks that the AppID and the CCP Provider user are Safe members with Retrieve/List permissions. Supports PAM Self-Hosted and Privilege Cloud.

### Finding the CCP Object name
The CCP `Object` parameter must match the account's **Name** in the Vault exactly (not the username or address).

PAM Self-Hosted:
```powershell
.\07-Find-CCPObject.ps1 -PvwaUrl https://pvwa.corp.local -AuthType LDAP `
    -Safe "App-Safe" -Search "svc_postgres" `
    -AppID "MyApp" -ProviderUser "Prov_CCPSRV01"
```

Privilege Cloud:
```powershell
.\07-Find-CCPObject.ps1 -TenantSubdomain mycompany -Safe "App-Safe" -Search "svc_postgres"
```

`-AuthType` accepts `CyberArk` (default), `LDAP`, `RADIUS` or `Windows`.

## Bruno collection containing REST and SOAP example