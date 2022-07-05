"""Helper library for initializing the OAuth2 flow and getting the tokens.

Module inspired from: https://github.com/google/gmail-oauth2-tools/wiki/OAuth2DotPyRunThrough
"""


import base64
import json
import urllib.parse as urlparse
import urllib.request as urlrequest

import jwt


PROVIDERS = {
    "google": {
        "auth_url": "https://accounts.google.com/o/oauth2/auth",
        "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
        "scope": "https://mail.google.com",
        "token_url": "https://accounts.google.com/o/oauth2/token",
    },
    "microsoft": {
        "auth_url": "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize",
        "redirect_uri": "https://login.microsoftonline.com/common/oauth2/nativeclient",
        "scope": "offline_access https://outlook.office365.com/.default",
        "token_url": "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token",
    },
}


def _parse_url(url, *, params):
    parts = list(urlparse.urlsplit(url))
    parts[3] = urlparse.urlencode(params)  # adds query params
    return urlparse.urlunsplit(parts)


def _post_data(url, *, params):
    data = urlrequest.urlopen(url, urlparse.urlencode(params).encode()).read()
    return json.loads(data)


def generate_permission_url(client_id, *, provider, tenant=None):
    config = PROVIDERS[provider]
    auth_url = config["auth_url"].format(tenant=tenant or "common")
    params = {
        "client_id": client_id,
        "redirect_uri": config["redirect_uri"],
        "scope": config["scope"],
        "response_type": "code",
    }
    return _parse_url(auth_url, params=params)


def authorize_and_get_token(
        client_id, client_secret, *, auth_code, provider, tenant=None
    ):
    config = PROVIDERS[provider]
    token_url = config["token_url"].format(tenant=tenant or "common")
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": config["redirect_uri"],
        "code": auth_code,
        "grant_type": "authorization_code",
    }
    token = _post_data(token_url, params=params)
    if provider == "microsoft":
        access_token = jwt.decode(
            token["access_token"], options={"verify_signature": False}
        )
        # Required by `exchangelib` in order to automatically trigger the token refresh
        #  when it expires. (otherwise "401 Unauthorized" is raised)
        token["expires_at"] = access_token["exp"]
    return token


def generate_google_oauth2_string(client_id, client_secret, *, token, username):
    token_url = PROVIDERS["google"]["token_url"]
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": token["refresh_token"],
        "grant_type": "refresh_token",
    }
    # FIXME: Instead of getting a new access token every time, just use the current
    #  access one until it expires. And refresh it with the long-lived refresh one
    #  when required only.
    access_token = _post_data(token_url, params=params)["access_token"]
    auth_string = f"user={username}\1auth=Bearer {access_token}\1\1"
    return base64.b64encode(auth_string.encode()).decode()
