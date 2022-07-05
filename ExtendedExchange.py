import functools

from RPA.Email.Exchange import Exchange
from RPA.Robocorp.Vault import Vault
from exchangelib.services import common as exchangelib_common
from exchangelib.util import post_ratelimited


vault = Vault()


def extended_post_ratelimited(protocol, session, *args, **kwargs):
    session.post = functools.partial(
        session.post,
        client_id=protocol.credentials.client_id,
        client_secret=protocol.credentials.client_secret,
    )
    return post_ratelimited(protocol, session, *args, **kwargs)

exchangelib_common.post_ratelimited = extended_post_ratelimited


class ExtendedExchange(Exchange):

    def __init__(self, *args, secret_name, **kwargs):
        super().__init__(*args, **kwargs)
        self._secret_name = secret_name

    def on_token_refresh(self, token):
        super().on_token_refresh(token)
        secret = vault.get_secret(self._secret_name)
        secret["token"] = dict(token)
        vault.set_secret(secret)
