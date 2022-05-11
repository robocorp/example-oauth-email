"""Helper library for initializing the OAuth2 flow and getting the tokens.

Module inspired from: https://github.com/google/gmail-oauth2-tools/wiki/OAuth2DotPyRunThrough
"""


import base64
import json
import urllib.parse as urlparse
import urllib.request as urlrequest


def _parse_url(url, *, params):
    parts = list(urlparse.urlsplit(url))
    parts[3] = urlparse.urlencode(params)  # adds query params
    return urlparse.urlunsplit(parts)

def _post_data(url, *, params):
    data = urlrequest.urlopen(url, urlparse.urlencode(params).encode()).read()
    return json.loads(data)


def generate_permission_url(client_id):
    auth_url = "https://accounts.google.com/o/oauth2/auth"
    params = {
        "client_id": client_id,
        "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
        "scope": "https://mail.google.com",
        "response_type": "code",
    }
    return _parse_url(auth_url, params=params)


def authorize_and_get_refresh_token(client_id, client_secret, *, auth_code):
    token_url = "https://accounts.google.com/o/oauth2/token"
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
        "code": auth_code,
        "grant_type": "authorization_code",
    }
    return _post_data(token_url, params=params)["refresh_token"]


def generate_oauth2_string(client_id, client_secret, *, refresh_token, username):
    token_url = "https://accounts.google.com/o/oauth2/token"
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }
    access_token = _post_data(token_url, params=params)["access_token"]
    auth_string = f"user={username}\1auth=Bearer {access_token}\1\1"
    return base64.b64encode(auth_string.encode()).decode()
