# E-mail authorization with OAuth2 flow

## Setup

1. First, you need to register an app which will act on behalf of your account.

   ### Google (GMail)

   Go to [Cloud Credentials](https://console.cloud.google.com/apis/credentials)
   and click "+ CREATE CREDENTIALS" -> "OAuth client ID" (Desktop app). You have to
   configure the *Consent Screen* beforehand:
   - During the configuration don't forget to add the `https://mail.google.com/` GMail
     API scope. (so you give the app full permissions on your mailbox)
   - If you can't find the scope, enable
     [Gmail API](https://console.cloud.google.com/marketplace/product/google/gmail.googleapis.com)
     for being able to use the e-mail scope (app permission) from above.

   ### Microsoft (Exchange Outlook)

   Create an Exchange Online sandbox (or use your current tenant), then go to Azure
   AD's [App registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
   and follow [these](https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth)
   instructions. Make sure you checked the following:
   - The type of the application is a "Web App".
     - Redirect URI can be: `https://login.microsoftonline.com/common/oauth2/nativeclient`
   - It is a multi-tenant app. ("Accounts in any organizational directory" is checked)
   - Has at least the following permissions enabled:
     - `EWS.AccessAsUser.All` (Microsoft Graph)
     - `full_access_as_app` (Office 365 Exchange Online)
   - **OAuth2** and **Impersonation** are enabled:
     - From an Administrator PowerShell console, install [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/2.0.5)
       module.
     - `Import-Module ExchangeOnlineManagement`
     - `Connect-ExchangeOnline -UserPrincipalName <e-mail>`
     - `Set-OrganizationConfig -OAuth2ClientProfileEnabled $true`
       - Check status with: `Get-OrganizationConfig | Format-Table Name,OAuth* -Auto`
     - `New-ManagementRoleAssignment -name:impersonationAssignmentName -Role:ApplicationImpersonation -User:<e-mail>`

2. Create a secret called `email_oauth_google/microsoft` in Control Room's Vault with
   the following entries (and make sure to connect **VSCode** to the online secrets
   vault first):
   - `client_id`: Your app client ID (obtained at step **1.**)
   - `client_secret`: Your app client secret (obtained at step **1.**)
   - `token`: You can leave it blank since this will be overridden by the robot

### Using the local vault

If you don't want to use the online cloud Vault:
1. Make a copy of the [vault.yaml](./devdata/vault.yaml) in a safe place and update the
   keys as already instructed above at the online Vault step.
2. Change the `RPA_SECRET_FILE` env var path in the
   [local-env.json](./devdata/local-env.json) in order to make it point to your secrets
   *.yaml* file above. (then rename this file to *env.json* if you want it picked up
   automatically by **VSCode**)

## Robot run

Run with **VSCode** or **rcc** the following tasks in order:
1. `Init OAuth Flow`: Opens a browser window for you to authenticate and finally
   getting the authorization code which has to be placed in the dialog asking for it.
   (now you should see your brand new `token` field updated and set in the Vault;
   keep it private as this is like a password which grants access into your e-mail)
   - Based on the client you want to send the mail with, pick from the listed Work
     Items either **google** or **microsoft**. (and continue with the same in the next
     step)
     - Don't forget to configure your `username` (and optionally `tenant`) field in the
       Work Items *.json* file for either [google](./devdata/work-items-in/google/work-items.json)
       or [microsoft](./devdata/work-items-in/microsoft/work-items.json).
   - With Google, you'll see the auth code displayed in the browser window, whether
     with Microsoft you'll find it in the address bar.
2. `Send Google/Microsoft Email`: Sends a test e-mail to yourself given the credentials
   configured in Vault. This step can be fully automated, as once the `token` is set,
   it remains available until you revoke it (or removing the app).

## Remarks

- Access token lifetime:
  - With Google, the access token (OAuth2 string as e-mail `password`) remains valid
    for **1h**, after that you have to get a new one by calling again the
    `Generate Google Oauth2 String` keyword. (doesn't have auto-refresh capability)
  - With Microsoft, the token refreshes itself when it expires and is automatically
    updated into Vault as well.
- Learn more about OAuth2:
  - [Google](https://developers.google.com/identity/protocols/oauth2)
  - [Microsoft](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
- You can bypass the flow (less secure way) by using an **App Password** (can be used
  if *2-Step-Verification* is turned **ON** only):
  - [Google](https://robocorp.com/docs/development-guide/email/sending-emails-with-gmail-smtp#configuration-of-the-gmail-account)
  - [Microsoft](https://support.microsoft.com/en-gb/account-billing/manage-app-passwords-for-two-step-verification-d6dc8c6d-4bf7-4851-ad95-6d07799387e9)
