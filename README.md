# E-mail authorization with OAuth2 flow

With this example, you will learn how to send e-mails with GMail or Exchange. The
sending is the easy part, but since these providers started to disable the usage of
passwords, it is required now to do a more complex kind of authorization which relies
on tokens. And that's usually done through the OAuth2
[Authorization Code Grant](https://oauth.net/2/grant-types/authorization-code/) flow.

## Tasks

Before sending an e-mail to yourself with `Send Google/Microsoft Email`, you have to
place a token in the Vault with `Init Google/Microsoft OAuth` task first. This
initializer step is required once, then you can send as many e-mails you want with such
token already configured.

### Google (GMail)

1. `Init Google OAuth`: Authenticate user, authorize app and have the token generated
   automatically in the Vault.
2. `Send Google Email`: Send an e-mail to yourself with GMail.

### Microsoft (Exchange)

1. `Init Microsoft OAuth`: Authenticate user, authorize app and have the token
   generated automatically in the Vault.
2. `Send Microsoft Email`: Send an e-mail to yourself with Microsoft.

## Client app setup

You need to register an app which will act on behalf of your account. The app
(Client) is the entity sending e-mails instead of you (User). But you need to
authenticate yourself and authorize the app first in order to allow it to send
e-mails for you. For this, certain settings are required:

### Google (GMail)

1. You have to configure the *[Consent Screen](https://console.cloud.google.com/apis/credentials/consent)*
beforehand:
- Add a name and your e-mail address.
- Under "Your restricted scopes" add the `https://mail.google.com/` GMail API scope.
  (so you give the app full permissions on your mailbox)
- In order to see the scope above (client app permission), you have to enable the
  [Gmail API](https://console.cloud.google.com/marketplace/product/google/gmail.googleapis.com)
  first.
- Add as test users the e-mail addresses you want to allow to complete the flow. This
  is required as long as the app remains private & unpublished.

2. Now go to *[Cloud Credentials](https://console.cloud.google.com/apis/credentials)*
and click "+ CREATE CREDENTIALS" -> "OAuth client ID". And select the following:
- Application type: **Web application**
- Add redirect URI: `https://developers.google.com/oauthplayground`
- Take a note of the obtained client credentials as you'll need them later on.

Read more on client setup with Google:
- [Setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849?hl=en)
- [Migrate Google applications from using the deprecated out-of-band (OOB) workflow](https://support.datavirtuality.com/hc/en-us/community/posts/6854178746909-Migrate-Google-applications-from-using-the-deprecated-out-of-band-OOB-workflow)

### Microsoft (Exchange)

1. Create an Exchange Online [sandbox](https://learn.microsoft.com/en-us/office/developer-program/microsoft-365-developer-program-get-started)
   (or use your current tenant).
2. Then go to Azure Active Directory's [App registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
   page and follow [these](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
   app configuration instructions.
3. Ensure you created a "Web" app and have the following checked:
   - Is a *private* **single** or **multi-tenant** app.
   - The type of the application is **Web App**.
   - Redirect URI can be: `https://login.microsoftonline.com/common/oauth2/nativeclient`
   - Has at least the following permission(s) enabled:
     - **Delegated**: `EWS.AccessAsUser.All` (Office 365 Exchange Online)
       ![API Permissions](https://raw.githubusercontent.com/robocorp/example-oauth-email/master/docs/api-permissions.png)
   - A client secret has beed added. And take note of these credentials, as you need
     them later on.
4. Finally, enable **OAuth2** in the tenant and allow **Impersonation** on test users:
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
     - `<name>`s has to be unique.
   - Read more on EWS access and impersonation:
     - [Impersonation and EWS in Exchange](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/impersonation-and-ews-in-exchange)
     - [Configure impersonation](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/how-to-configure-impersonation)

## Vault setup

The client ID and client secret obtained above need to be stored securely in the Vault,
as they'll be used automatically by the robot in order to obtain the token. Also the
token itself needs an entry in the Vault so the robot can update its value in there.

### Online Control Room Vault

Create a secret called `email_oauth_google/microsoft` in Control Room's Vault with the
following entries (and make sure to connect **VSCode** to the online Vault afterwards):
- `client_id`: Your app client ID.
- `client_secret`: Your app client secret.
- `token`: You can leave it blank since this will be overridden by the robot.

### Local file based Vault

If you can't use the online cloud Vault:
1. Make a copy of the [vault.yaml](https://github.com/robocorp/example-oauth-email/blob/master/devdata/vault.yaml)
   in a safe place and update the keys as already instructed above at the online Vault
   step.
2. Change the `RPA_SECRET_FILE` env var path in the
   [env-local.json](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env-local.json)
   in order to make it point to your secrets *.yaml* file above. But that's not all, as:
   - Only [env.json](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env.json)
     is picked-up automatically by **VSCode**. So copy the content of the other inside
     this one if you really want to use the local Vault now.
   - With **rcc** you have to pass the preferred *env* file with `-e`.

## Robot run

Run with **VSCode** or **rcc** the following tasks in order:
1. `Init Google/Microsoft OAuth`: Opens a browser window for you to authenticate and
   finally getting a redirect response URL in the address bar. Once you get here, the
   browser closes and the token gets generated and updated in the Vault.
   - Based on the service you want to send the e-mail with, pick from the listed Work
     Items either **google** or **microsoft**. (and continue with the same in the next
     step)
     - Don't forget to configure your `username` (and optionally `tenant`) field in the
       Work Items *.json* file for either [google](https://github.com/robocorp/example-oauth-email/blob/master/devdata/work-items-in/google/work-items.json)
       or [microsoft](https://github.com/robocorp/example-oauth-email/blob/master/devdata/work-items-in/microsoft/work-items.json).
   - Now you should see your brand new `token` field updated and set in the Vault.
     (keep it private as this is like a password which grants access into your e-mail)
   - For convenience (copy-pasting local token into Control Room's Vault), run the bot
     with `TOKEN_AS_JSON=1` env var, so you get a string version of the entire token
     dictionary in your Vault local file. (look under this *env-local.json*
     [entry](https://github.com/robocorp/example-oauth-email/blob/master/devdata/env-local.json#L6)
     on how to enable it)
   - If by any chance you can't login in the opened & automated browser window, open
     that auth URL (which is also printed to console during the run) in your own
     browser and continue the flow from there. When you finish, copy-paste the final
     URL found in the address bar from this browser into the one opened automatically,
     then press Enter.
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
