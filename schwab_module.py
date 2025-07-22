import os
import base64
import requests
import pandas
import webbrowser

from dotenv import load_dotenv
from loguru import logger

class Asset:
    def __init__(self, asset):
        self._type = asset["instrument"]["type"]
        self._asset_count = asset["longQuantity"]
        self._curr_value = asset["marketValue"]
        self._cost_average = asset["averagePrice"]
        self._unrealized_return = asset["longOpenProfitLoss"]

    @property
    def type(self):
        return self._type
    
    @property
    def asset_count(self):
        return self._asset_count

    @property
    def curr_value(self):
        return self._curr_value
    
    @property
    def cost_average(self):
        return self._cost_average
    
    @property
    def unrealized_return(self):
        return self._unrealized_return

class InitializeAPI:
    def __init__(self):
        load_dotenv()

        self._app_key = os.getenv("APP_KEY")
        self._app_secret = os.getenv("SECRET")
        self._callback = os.getenv("CALLBACK")

    def construct_init_auth_url(self):
        auth_url = f"https://api.schwabapi.com/v1/oauth/authorize?client_id={self._app_key}&redirect_uri={self._callback}"

        logger.info("Click to authenticate:")
        logger.info(auth_url)

        return self._app_key, self._app_secret, auth_url

    def construct_headers_and_payload(self, returned_url, app_key, app_secret):
        callback = os.getenv("CALLBACK")

        response_code = f"{returned_url[returned_url.index('code=') + 5: returned_url.index('%40')]}@"

        credentials = f"{app_key}:{app_secret}"
        base64_credentials = base64.b64encode(credentials.encode("utf-8")).decode("utf-8")

        headers = {
            "Authorization": f"Basic {base64_credentials}",
            "Content-Type": "application/x-www-form-urlencoded",
        }

        payload = {
            "grant_type": "authorization_code",
            "code": response_code,
            "redirect_uri": callback,
        }

        return headers, payload

    def retrieve_tokens(self, headers, payload) -> dict:
        init_token_response = requests.post(
            url="https://api.schwabapi.com/v1/oauth/token",
            headers=headers,
            data=payload,
        )

        init_tokens_dict = init_token_response.json()

        return init_tokens_dict

    def auth_request_tokens(self):
        app_key, app_secret, cs_auth_url = self.construct_init_auth_url()
        webbrowser.open(cs_auth_url)

        logger.info("Paste Returned URL:")
        returned_url = input()

        init_token_headers, init_token_payload = self.construct_headers_and_payload(
            returned_url, app_key, app_secret
        )

        init_tokens_dict = self.retrieve_tokens(
            headers=init_token_headers, payload=init_token_payload
        )

        return init_tokens_dict

    def get_hash(self, tokens):
        response = requests.get(
            "https://api.schwabapi.com/trader/v1/accounts/accountNumbers", headers={"Authorization": f"Bearer {tokens["access_token"]}"}
        )

        response_frame = pandas.json_normalize(response.json())

        return response_frame["hashValue"].iloc[0]
    
    def refresh_tokens(self, tokens):
        logger.info("Initializing...")

        refresh_token = tokens["refresh_token"]

        payload = {
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        }
        headers = {
            "Authorization": f'Basic {base64.b64encode(f"{self._app_key}:{self._app_secret}".encode()).decode()}',
            "Content-Type": "application/x-www-form-urlencoded",
        }

        refresh_response = requests.post(
            url="https://api.schwabapi.com/v1/oauth/token",
            headers=headers,
            data=payload,
        )
        if refresh_response.status_code == 200:
            logger.info("Retrieved new tokens successfully using refresh token.")
        else:
            logger.error(
                f"Error refreshing access token: {refresh_response.text}"
            )
            return None

        refresh_token_dict = refresh_response.json()

        logger.debug(refresh_token_dict)

        logger.info("Token dict refreshed.")

        return refresh_token_dict

class SchwabBalance:
    def __init__(self):
        self._init = InitializeAPI()
        self._total_balance = [0, "USD"]
        self._total_cost_basis = [0, "USD"]
        self._assets = {}
        self._cash = 0
        self._tokens = self._init.auth_request_tokens()
        self._hash = self._init.get_hash(self._tokens)

    def get_portfolio_data(self):
        self._tokens = self._init.refresh_tokens(self._tokens)

        url = f"https://api.schwabapi.com/trader/v1/accounts/{self._hash}?fields=positions"

        headers = {
            "Authorization": f"Bearer {self._tokens["access_token"]}",
            "Accept": "application/json"
        }

        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            data = response.json()["securitiesAccount"]
            positions = data["positions"]
            balance = data["currentBalances"]

            self._assets = {}
            self._total_cost_basis[0] = 0

            for asset in positions:
                self._assets[asset["instrument"]["symbol"]] = Asset(asset)
                self._total_cost_basis[0] += asset["longOpenProfitLoss"]
            
            self._cash = balance["cashBalance"]
            self._total_balance[0] = balance["liquidationValue"]
            self._total_cost_basis[0] += self.total_balance[0]
        else:
            print(f"Error {response.status_code}: {response.text}")

        return

    @property
    def total_balance(self):
        return self._total_balance
    
    @property
    def total_cost_basis(self):
        return self._total_cost_basis

    @property
    def assets(self):
        return self._assets
    
    @property
    def cash(self):
        return self._cash
    
    # Method for testing through terminal
    def parse_positions(self, positions):
        print(f"POSITIONS")
        for asset in positions:
            print(f"BREAK")
            for key, value in asset.items():
                print(key, f":", value, "\n")
        return

    # Method for testing through terminal
    def display_data(self):
        print("Assets held in Schwab:")

        for key, val in self._assets.items():
            print(key, f":", val.type, val.asset_count, val.cost_average, val.curr_value, val.unrealized_return)

        print(f"Cash :", self.cash, self._total_balance[1])

        print("Total portfolio cost-basis:", self._total_cost_basis[0], self._total_cost_basis[1])

        print("Total portfolio value:", self._total_balance[0], self._total_balance[1])

        return

# main() function for testing
if __name__ == '__main__':
    port = SchwabBalance()
    port.get_portfolio_data()
    port.display_data()

    run = True

    while run:
        n = input("Refresh? (Y/N)")
        if (n == "Y"):
            port.get_portfolio_data()
            port.display_data()
        elif (n == "N"):
            run = False