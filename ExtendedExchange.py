from RPA.Email.Exchange import Exchange
from RPA.Robocorp.Vault import Vault


vault = Vault()


class ExtendedExchange(Exchange):

    def __init__(self, *args, secret_name, **kwargs):
        super().__init__(*args, **kwargs)
        self._secret_name = secret_name

    def on_token_refresh(self, token):
        super().on_token_refresh(token)
        secret = vault.get_secret(self._secret_name)
        secret["token"] = dict(token)
        vault.set_secret(secret)
