*** Settings ***
Documentation       Send an e-mail with Google or Microsoft in a more secure way.
...                 (check devdata/vault.yaml for learning about the secrets structure)

Library    Collections
Library    RPA.Browser.Selenium
Library    RPA.Dialogs
Library    RPA.Email.ImapSmtp
# Change these servers when working with other providers.
...    smtp_server=smtp.gmail.com    imap_server=imap.gmail.com    provider=google
Library    RPA.Robocorp.Vault
Library    RPA.Robocorp.WorkItems
Library    RPA.RobotLogListener

Suite Setup    Secrets Setup


*** Variables ***
# Global secrets object pulled from the Vault and stored back into the Vault on token
#  updates.
${SECRETS}


*** Keywords ***
Secrets Setup
    @{protected} =    Create List    Set To Dictionary
    Register Protected Keywords    ${protected}

    # Based on the input Work Item data (google/microsoft), decide what Vault to use
    #  and import the `Exchange` library with such a Vault set. This information is
    #  important for the library in order to know where to update the newly obtained
    #  token during auto-refresh (handled internally).
    ${secret_name} =    Get Work Item Variable    secret_name
    ${secrets} =    Get Secret    ${secret_name}
    Set Global Variable    ${SECRETS}    ${secrets}

    ${tenant} =    Get Work Item Variable    tenant
    Import Library    RPA.Email.Exchange
    ...    vault_name=${secret_name}    vault_token_key=token    tenant=${tenant}


Init Any OAuth Flow
    [Documentation]    Start the OAuth2 flow by generating a permission URL, which the
    ...    user has to surf in order to authenticate itself and authorize the app to
    ...    send e-mails on its behalf.
    [Arguments]    ${generate_oauth_url}    ${get_oauth_token}

    ${url} =    Run Keyword    ${generate_oauth_url}    ${SECRETS}[client_id]
    Log To Console    Start the OAuth2 flow: ${url}
    Open Available Browser    ${url}

    Add heading       Enter response URL
    Add text input    url    label=URL
    ${result} =    Run dialog
    ${token} =    Run Keyword    ${get_oauth_token}    ${SECRETS}[client_secret]
    ...    ${result.url}
    Set To Dictionary    ${SECRETS}    token    ${token}
    Set Secret    ${SECRETS}
    Log    The new token was just updated in the Vault. (keep it private)


*** Tasks ***
Init Google OAuth
    Init Any OAuth Flow
    ...    RPA.Email.ImapSmtp.Generate OAuth URL
    ...    RPA.Email.ImapSmtp.Get OAuth Token


Init Microsoft OAuth
    Init Any OAuth Flow
    ...    RPA.Email.Exchange.Generate OAuth URL
    ...    RPA.Email.Exchange.Get OAuth Token


Send Google Email
    [Documentation]    TODO

    ${username} =    Get Work Item Variable    username

    # Once the password is generated, you can use it for one hour, then you'll have to
    #  generate a new one after a token refresh. (as it expires)
    ${token} =    RPA.Email.ImapSmtp.Refresh OAuth Token    ${SECRETS}[client_id]
    ...    ${SECRETS}[client_secret]    ${SECRETS}[token]
    Set To Dictionary    ${SECRETS}    token    ${token}
    Set Secret    ${SECRETS}
    Log    The refreshed token was just updated in the Vault. (keep it private)
    ${password} =    RPA.Email.ImapSmtp.Generate OAuth String    ${username}
    ...    ${SECRETS}[token][access_token]

    RPA.Email.ImapSmtp.Authorize    account=${username}
    # ...    password=${SECRETS}[password]
    # Uncomment the `password` line above and remove the lines below when doing basic
    #  auth with an "App Password" on MFA enabled accounts.
    ...    is_oauth=${True}    password=${password}

    RPA.Email.ImapSmtp.Send Message    sender=${username}    recipients=${username}
    ...    subject=E-mail sent through the OAuth2 flow
    ...    body=I hope you find this flow easy to understand and use. (keep the refresh token private at all times)


Send Microsoft Email
    [Documentation]    Send an e-mail with Office365 Exchange. Since password isn't an
    ...    option anymore, the authorization can be made through the OAuth2 flow only,
    ...    meaning you have to provide the Client credentials and a token.

    ${username} =    Get Work Item Variable    username

    RPA.Email.Exchange.Authorize    ${username}
    ...    autodiscover=${False}    server=outlook.office365.com
    # ...    access_type=IMPERSONATION  # app impersonates the user (to send on its behalf)
    ...    is_oauth=${True}  # use the OAuth2 auth code flow
    ...    client_id=${SECRETS}[client_id]  # app ID
    ...    client_secret=${SECRETS}[client_secret]  # app password
    # The entire token structure auto-refreshes when it expires.
    ...    token=${SECRETS}[token]  # token dict (access, refresh, scope etc.)

    RPA.Email.Exchange.Send Message    recipients=${username}
    ...    subject=OAuth2 Exchange message from RPA robot
    ...    body=Congrats! You're using Modern Authentication.
    ...    save=${True}
