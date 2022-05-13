# E-mail authorization with OAuth2 flow

## Setup

1. First, you need to register an app which will act on behalf of your account. With
   Google (GMail), just go to
   [Cloud Credentials](https://console.cloud.google.com/apis/credentials)
   and click "+ CREATE CREDENTIALS" -> "OAuth client ID". (you have to configure the
   *Consent Screen* beforehand)
   - During the configuration don't forget to add the `https://mail.google.com/` GMail
     API scope. (so you give the app full permissions on your mailbox)
   - If you can't find the scope, enable
     [Gmail API](https://console.cloud.google.com/marketplace/product/google/gmail.googleapis.com)
     for being able to use the e-mail scope (app permission) from above.
2. Create a secret called `email_oauth` in Control Room's Vault with the following
   entries (and make sure to connect **VSCode** to the online secrets vault):
   - `username`: Your e-mail address
   - `client_id`: Your app client ID (obtained at step **1.**)
   - `client_secret`: Your app client secret (obtained at step **1.**)
   - `refresh_token`: You can leave it blank since this will be overridden by the robot

### Using the local vault

If you don't want to use the online cloud Vault:
1. Make a copy of the [vault.yaml](./devdata/vault.yaml) in a safe place and update the
   keys as already instructed at the online Vault step.
2. Change the `RPA_SECRET_FILE` env var path in the
   [local-vault-env.json](./devdata/local-vault-env.json)
   in order to make it point to your secrets *.yaml* file above. (rename the file to
   *env.json* if you want it picked up automatically by **VSCode**)

## Robot run

Run in **VSCode** or **rcc** the following tasks in order:
1. `Init OAuth Flow`: Opens a browser window for you to authenticate and finally
   getting the authorization code which has to be placed in the dialog asking for it.
   (now you should see your brand new `refresh_token` updated and set in the Vault;
   keep it private as this it's like a password which grants access into your e-mail)
2. `Send Email By Token`: Sends a test e-mail to yourself given the credentials
   configured in Vault. This step can be fully automated, as once the `refresh_token`
   is set, it remains available until you revoke it.

## Remarks

- This example currently works for GMail only but can be easily adapted to work with
  other providers as well.
  - With Google, the access token (OAuth2 string as e-mail `password`) remains valid
    for **1h**, after that you have to get a new one by calling again the
    `Generate Oauth2 String` keyword.
- Learn more about [OAuth2](https://developers.google.com/identity/protocols/oauth2).
- You can bypass the flow (less secure way) by using an
  [App Password](https://robocorp.com/docs/development-guide/email/sending-emails-with-gmail-smtp#configuration-of-the-gmail-account).
  (can be used if *2-Step-Verification* is turned **ON**)
