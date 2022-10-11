*** Settings ***
Documentation       Send e-mail with Google or Microsoft in a more secure way.
...                 (check devdata/vault.yaml for secrets example)

Library    Collections
Library    OAuth2  # robot internal library for the Authorization Code flow
Library    RPA.Browser.Selenium
Library    RPA.Dialogs
Library    RPA.Email.ImapSmtp    smtp_server=smtp.gmail.com    imap_server=imap.gmail.com
Library    RPA.Robocorp.Vault
Library    RPA.RobotLogListener
Library    RPA.Robocorp.WorkItems

Suite Setup    Secrets Setup


*** Variables ***
${SECRETS}


*** Keywords ***
Secrets Setup
    @{protected} =    Create List    Authorize And Get Token
    ...    Generate Google Oauth2 String    Set To Dictionary
    Register Protected Keywords    ${protected}

    ${secret_name} =    Get Work Item Variable    secret_name
    ${secrets} =    Get Secret    ${secret_name}
    Set Global Variable    ${SECRETS}    ${secrets}
    Import Library    RPA.Email.Exchange
    ...    vault_name=${secret_name}    vault_token_key=token


*** Tasks ***
Init OAuth Flow
    &{config} =    Get Work Item Variables
    ${url} =    Generate Permission Url    ${SECRETS}[client_id]
    ...    provider=${config}[provider]    tenant=${config}[tenant]
    Log To Console    Permission URL: ${url}
    Open Available Browser    ${url}

    Add heading       Enter authorization code
    Add text input    code    label=Code
    ${result} =    Run dialog
    ${token} =    Authorize And Get Token    ${SECRETS}[client_id]
    ...    ${SECRETS}[client_secret]    auth_code=${result.code}
    ...    provider=${config}[provider]    tenant=${config}[tenant]
    Set To Dictionary    ${SECRETS}    token    ${token}
    Set Secret    ${SECRETS}
    Log    The refresh token was just saved in the Vault. (keep it private)


Send Google Email
    ${username} =    Get Work Item Variable    username

    # Once the password is generated, you can use it for one hour, then you'll have to
    #  generate a new one. (as it expires)
    ${password} =    Generate Google Oauth2 String
    ...    ${SECRETS}[client_id]    ${SECRETS}[client_secret]
    ...    token=${SECRETS}[token]    username=${username}
    # Log To Console    Password: ${password}  # don't leak it

    RPA.Email.ImapSmtp.Authorize    account=${username}    password=${password}
    ...    is_oauth=${True}

    RPA.Email.ImapSmtp.Send Message    sender=${username}    recipients=${username}
    ...    subject=E-mail sent through the OAuth2 flow
    ...    body=I hope you find this flow easy to understand and use. (keep the refresh token private at all times)


Send Microsoft Email
    ${username} =    Get Work Item Variable    username

    RPA.Email.Exchange.Authorize    ${username}
    ...    autodiscover=${False}    server=outlook.office365.com
    # ...    password=${SECRETS}[password]
    # Uncomment the password above and remove the lines below when doing basic auth
    #  with an "App Password" on MFA enabled accounts.
    # ...    access_type=IMPERSONATION  # app impersonates the user (to send on its behalf)
    ...    is_oauth=${True}  # use the OAuth2 auth code flow
    ...    client_id=${SECRETS}[client_id]  # app ID
    ...    client_secret=${SECRETS}[client_secret]  # app password
    # The entire token structure auto refreshes when it expires.
    ...    token=${SECRETS}[token]  # token dict (access, refresh, scopes etc.)

    RPA.Email.Exchange.Send Message    recipients=${username}
    ...    subject=OAuth2 Exchange message from RPA robot
    ...    body=Congrats! You're using Modern Authentication.
    ...    save=${True}
