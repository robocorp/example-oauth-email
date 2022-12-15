*** Settings ***
Documentation       Send an e-mail with Google or Microsoft in a more secure way.
...                 (check devdata/vault.yaml for learning about the secrets structure)

Library    Collections
Library    RPA.Browser.Selenium
Library    RPA.Email.ImapSmtp
# Change these servers when working with other providers.
...    smtp_server=smtp.gmail.com    imap_server=imap.gmail.com    provider=google
Library    RPA.JSON
Library    RPA.Robocorp.Vault
Library    RPA.Robocorp.WorkItems
Library    RPA.RobotLogListener

Suite Setup    Secrets Setup


*** Variables ***
# Global secrets object pulled from the Vault and stored back into the Vault on token
#  updates. This is accessible from every task/keyword in the robot.
${SECRETS}


*** Keywords ***
Secrets Setup
    # Don't generate logs when manipulating the token. (as it is a secret)
    @{protected} =    Create List    Set To Dictionary    Token Dict From JSON
    ...    Token Dict To JSON
    Register Protected Keywords    ${protected}

    # Based on the input Work Item data (google/microsoft), decide what Vault to use
    #  and import the `Exchange` library with such a Vault set. This information is
    #  important for the library in order to know where to update the newly obtained
    #  token during auto-refresh (handled internally).
    ${secret_name} =    Get Work Item Variable    secret_name
    ${secrets} =    Get Secret    ${secret_name}
    Set Global Variable    ${SECRETS}    ${secrets}

    ${tenant} =    Get Work Item Variable    tenant  # required with Exchange only
    Import Library    RPA.Email.Exchange
    ...    vault_name=${secret_name}    vault_token_key=token    tenant=${tenant}


Token Dict To JSON
    [Documentation]    Serialize a token dictionary to its string form.
    [Arguments]    ${token}

    # If this env var is set to "1", then a string instead of the token dict will be
    #  placed in the Vault, so it can be copy-pasted with ease from your local secrets
    #  file to Control Room's Vault 'token' field value entry.
    # This is particularly useful if by security means you can't connect to the online
    #  Vault in VSCode nor using the Assistant.
    IF    "%{TOKEN_AS_JSON=0}" == "1"
        ${token} =    Convert JSON To String    ${token}
    END

    RETURN    ${token}


Token Dict From JSON
    [Documentation]    Deserialize a token dictionary from its string form.
    [Arguments]    ${token}

    # Just ensure we end up with a token dictionary no matter if we have a string or
    #  the actual object stored in the Vault.
    ${status}    ${resp} =    Run Keyword And Ignore Error
    ...    Convert String to JSON    ${token}
    IF    "${status}" == "PASS"
        RETURN    ${resp}
    END

    Log    Returning token as it is (object)
    RETURN    ${token}


Init Any OAuth Flow
    [Documentation]    Start the OAuth2 flow by generating a permission URL, which the
    ...    user has to surf in order to authenticate itself and authorize the app to
    ...    send e-mails on its behalf.
    [Arguments]    ${generate_oauth_url}    ${get_oauth_token}

    # Generates the initial OAuth2 URL in order to start the flow. With a keyword
    #  coming from the targeted library: ImapSmtp or Exchange.
    ${url} =    Run Keyword    ${generate_oauth_url}    ${SECRETS}[client_id]
    Log To Console    Start the OAuth2 flow: ${url}
    Open Available Browser    ${url}

    # Completes the OAuth2 flow by sending the response URL to the token retrieval
    #  keyword. The keyword comes from the targeted library: `ImapSmtp` or `Exchange`.
    Wait Until Location Contains    code=    timeout=300s
    ...    message=Please authenticate and accept the consent faster
    ${response_url} =    Get Location
    ${token} =    Run Keyword    ${get_oauth_token}    ${SECRETS}[client_secret]
    ...    ${response_url}

    # Sets the obtained token (as serialized string or object) in the Vault.
    ${token} =    Token Dict To JSON    ${token}
    Set To Dictionary    ${SECRETS}    token    ${token}
    Set Secret    ${SECRETS}
    Log    The new token was just updated in the Vault. (keep it private)


*** Tasks ***
Init Google OAuth
    [Documentation]    Do the OAuth2 flow and obtain a token for GMail e-mail sending.

    # Common logic with keywords coming from the `ImapSmtp` library.
    Init Any OAuth Flow
    ...    RPA.Email.ImapSmtp.Generate OAuth URL
    ...    RPA.Email.ImapSmtp.Get OAuth Token


Init Microsoft OAuth
    [Documentation]    Do the OAuth2 flow and obtain a token for Exchange e-mail
    ...    sending.

    # Common logic with keywords coming from the `Exchange` library.
    Init Any OAuth Flow
    ...    RPA.Email.Exchange.Generate OAuth URL
    ...    RPA.Email.Exchange.Get OAuth Token


Send Google Email
    [Documentation]    Send e-mail with GMail. Currently only App Passwords are allowed
    ...    for the basic/legacy flow and for the secure way, the OAuth2 flow usage is
    ...    encouraged, which implies Client (app) credentials and token usage.

    ${username} =    Get Work Item Variable    username
    ${token} =    Token Dict From JSON    ${SECRETS}[token]

    # Once the password is generated, you can use it for one hour, then you'll have to
    #  generate a new one after a token refresh. (as it expires)
    ${token} =    RPA.Email.ImapSmtp.Refresh OAuth Token    ${SECRETS}[client_id]
    ...    ${SECRETS}[client_secret]    ${token}
    ${token} =    Token Dict To JSON    ${token}
    Set To Dictionary    ${SECRETS}    token    ${token}
    Set Secret    ${SECRETS}
    Log    The refreshed token was just updated in the Vault. (keep it private)

    ${token} =    Token Dict From JSON    ${SECRETS}[token]
    ${password} =    RPA.Email.ImapSmtp.Generate OAuth String    ${username}
    ...    ${token}[access_token]
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
    ...    meaning you have to provide the Client (app) credentials and a token.

    ${username} =    Get Work Item Variable    username
    ${token} =    Token Dict From JSON    ${SECRETS}[token]

    RPA.Email.Exchange.Authorize    ${username}
    ...    autodiscover=${False}    server=outlook.office365.com
    # ...    access_type=IMPERSONATION  # app impersonates the user (to send on its behalf)
    ...    is_oauth=${True}  # use the OAuth2 auth code flow
    ...    client_id=${SECRETS}[client_id]  # app ID
    ...    client_secret=${SECRETS}[client_secret]  # app password
    # The entire token structure auto-refreshes when it expires.
    ...    token=${token}  # token dict (access, refresh, scope etc.)

    RPA.Email.Exchange.Send Message    recipients=${username}
    ...    subject=OAuth2 Exchange message from RPA robot
    ...    body=Congrats! You're using Modern Authentication.
    ...    save=${True}
