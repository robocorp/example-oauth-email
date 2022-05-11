# E-mail authorization with OAuth2 flow

## Setup

1. First, you need to register an app which will act on behalf of your account. With
   Google (GMail), just go to [Cloud Credentials](https://console.cloud.google.com/apis/credentials)
   and click "+ CREATE CREDENTIALS" -> "OAuth client ID". (you have to configure the
   *Consent Screen* beforehand)
2. Make a copy of the [vault.yaml](./devdata/vault.yaml) somewhere safe and change the
   following keys:
   - `username`: Your e-mail address
   - `client_id`: Your app client ID (taken from above)
   - `client_secret`: Your app client secret (taken from above)
   - `refresh_token`: You can leave it like that since this will be overridden by the
     robot
3. Change the `RPA_SECRET_FILE` path in the [env.json](./devdata/env.json) in order to
   point to your secrets *.yaml* file above.

You can replace steps 2 & 3 by connecting to Control Room's Vault and creating & using
the secrets from there.

## Robot run

Run in VSCode or rcc the following tasks in order:
1. `Init OAuth Flow`: Opens a browser window for you to authenticate and finally
   getting the authorization code which has to be placed in the dialog asking for it.
   (now you should see your brand new `refresh_token` updated and set in the Vault;
   keep it private as this it's like a password which grants access into your e-mail)
2. `Send Email By Token`: Sends a test e-mail to yourself given the credentials
   configured in Vault. This step can be fully automated as once the `refresh_token` is
   set, it remains available until you revoke it.

## Remarks

- This example currently works for GMail only but can be easily adapted to work with
  other providers as well.
- Learn more about [OAuth2](https://developers.google.com/identity/protocols/oauth2).
- You can bypass the flow (less secure way) by using an [App Password](https://robocorp.com/docs/development-guide/email/sending-emails-with-gmail-smtp#configuration-of-the-gmail-account).
  (can be used if *2-Step-Verification* is turned **ON**)
