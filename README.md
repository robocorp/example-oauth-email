# E-mail authorization with OAuth2 flow

## Setup

1. First, you need to register an app which will act on behalf of your account. The app
   (Client) is the entity sending e-mails instead of you (User). But you need to
   authenticate yourself and authorize the app first in order to allow it to send
   e-mails for you. For this, certain settings are required:

   ### Google (GMail)

   Go to *[Cloud Credentials](https://console.cloud.google.com/apis/credentials)*
   and click "+ CREATE CREDENTIALS" -> "OAuth client ID". Now select the following:
   - Application type: **Web application**
   - Add redirect URI: `https://developers.google.com/oauthplayground`

   Store the generated Client ID and secret safely in the Vault as `client_id` and
   `client_secret` fields.

   You have to configure the *[Consent Screen](https://console.cloud.google.com/apis/credentials/consent)*
   beforehand:
   - During the configuration don't forget to add the `https://mail.google.com/` GMail
     API scope. (so you give the app full permissions on your mailbox)
   - If you can't find the scope, enable
     [Gmail API](https://console.cloud.google.com/marketplace/product/google/gmail.googleapis.com)
     for being able to use the e-mail scope (app permission) from above.

   Read more on client setup with Google:
   - [Setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849?hl=en)
   - [Migrate Google applications from using the deprecated out-of-band (OOB) workflow](https://support.datavirtuality.com/hc/en-us/community/posts/6854178746909-Migrate-Google-applications-from-using-the-deprecated-out-of-band-OOB-workflow)

   ### Microsoft (Exchange Outlook)

   Create an Exchange Online sandbox (or use your current tenant), then go to Azure
   AD's [App registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
   and follow [these](https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth)
   app configuration instructions. Make sure you create a web app and have the
   following checked:
   - Is a *private* **single** or **multi-tenant** app.
   - The type of the application is **Web App**.
   - Redirect URI can be: `https://login.microsoftonline.com/common/oauth2/nativeclient`
   - Has at least the following permission(s) enabled:
     - **Delegated**: `EWS.AccessAsUser.All` (Office 365 Exchange Online)
       ![API Permissions](https://raw.githubusercontent.com/robocorp/example-oauth-email/master/docs/api-permissions.png)
   - **OAuth2** and **Impersonation** are enabled:
     - From an Administrator PowerShell console, install [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/2.0.5)
       module.
     - Login with the tenant Admin:
       - `Import-Module ExchangeOnlineManagement`
       - `Connect-ExchangeOnline -UserPrincipalName <e-mail>`
     - OAuth2 enabling:
       - `Set-OrganizationConfig -OAuth2ClientProfileEnabled $true`
       - Check status with: `Get-OrganizationConfig | Format-Table Name,OAuth* -Auto`
     - Impersonation for a specific account (in order to be able to let the app send
       e-mails with that account):
       - `New-ManagementRoleAssignment -name:<name> -Role:ApplicationImpersonation -User:<e-mail>`
       - `<name>`s have to be unique.
     - Read more on EWS access and impersonation:
       - [Impersonation and EWS in Exchange](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/impersonation-and-ews-in-exchange)
       - [Configure impersonation](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/how-to-configure-impersonation)

2. Create a secret called `email_oauth_google/microsoft` in Control Room's Vault with
   the following entries (and make sure to connect **VSCode** to the online secrets
   Vault first):
   - `client_id`: Your app client ID (obtained at step **1.**)
   - `client_secret`: Your app client secret (obtained at step **1.**)
   - `token`: You can leave it blank since this will be overridden by the robot

### Using the local vault

If you don't want to use the online cloud Vault:
1. Make a copy of the [vault.yaml](https://github.com/robocorp/example-oauth-email/blob/master/devdata/vault.yaml)
   in a safe place and update the keys as already instructed above at the online Vault
   step.
2. Change the `RPA_SECRET_FILE` env var path in the
   [env-local.json](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env-local.json)
   in order to make it point to your secrets *.yaml* file above.
   - Only [env.json](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env.json)
     is picked-up automatically by **VSCode**. So copy the content of the other inside
     this one if you really want to use the local Vault.
   - With **rcc** you have to pass the preferred *env* file with `-e`.

## Robot run

Run with **VSCode** or **rcc** the following tasks in order:
1. `Init Google/Microsoft OAuth`: Opens a browser window for you to authenticate and
   finally getting a redirect response URL in the address bar. This has to be placed
   manually by you in the dialog asking for it in order to complete the flow.
   - Now you should see your brand new `token` field updated and set in the Vault.
     (keep it private as this is like a password which grants access into your e-mail)
   - Based on the service you want to send the e-mail with, pick from the listed Work
     Items either **google** or **microsoft**. (and continue with the same in the next
     step)
     - Don't forget to configure your `username` (and optionally `tenant`) field in the
       Work Items *.json* file for either [google](https://github.com/robocorp/example-oauth-email/blob/master/devdata/work-items-in/google/work-items.json)
       or [microsoft](https://github.com/robocorp/example-oauth-email/blob/master/devdata/work-items-in/microsoft/work-items.json).
   - For convenience (copy-pasting local token into Control Room's Vault), run the bot
     with `TOKEN_AS_JSON=1` env var, so you get a string version of the entire token
     dictionary in your Vault local file. (look under this *env-local.json*
     [entry](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env-local.json#L6)
     on how to enable it)
   - This step is required to be run once, requires human intervention (attended) and
     once you get your token generated it will stay valid (by refreshing itself)
     indefinitely.
2. `Send Google/Microsoft Email`: Sends a test e-mail to yourself given the credentials
   configured in the Vault during the previous step.
   - This step can be fully automated and doesn't require the first step run each time.
     As once the `token` is set, it remains available until you revoke the refresh
     token or remove the app.

## Remarks

- Access token lifetime:
  - With Google, the access token (OAuth2 string as e-mail `password`) remains valid
    for **1h**, after that you have to get a new one by calling again the
    `Refresh OAuth Token` and `Generate OAuth String` keywords. (as it doesn't have
    auto-refresh capability, so you need to do it yourself in the bot)
  - With Microsoft, the token refreshes itself when it expires (internally handled by
    the library) and is automatically updated into the Vault as well.
- Learn more about OAuth2:
  - [Google](https://developers.google.com/identity/protocols/oauth2)
  - [Microsoft](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow)
- You can bypass the flow (less secure way) by using an **App Password** (can be used
  if *2-Step-Verification* is turned **ON** only):
  - [Google](https://robocorp.com/docs/development-guide/email/sending-emails-with-gmail-smtp#configuration-of-the-gmail-account)
  - [Microsoft](https://support.microsoft.com/en-gb/account-billing/manage-app-passwords-for-two-step-verification-d6dc8c6d-4bf7-4851-ad95-6d07799387e9)
    - App Passwords are disabled now with Microsoft, so the only option is the OAuth2
      flow.
