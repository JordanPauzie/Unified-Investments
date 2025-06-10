import os
from dotenv import load_dotenv
from coinbase.rest import RESTClient

class Coin:
    def __init__(self, asset):
        self._coin_value = asset["total_balance_crypto"]
        self._curr_value = asset["total_balance_fiat"]
        self._cost_average = asset["average_entry_price"]["value"]
        self._cost_basis = asset["cost_basis"]["value"]
        self._allocation = asset["allocation"]

    @property
    def coin_value(self):
        return self._coin_value

    @property
    def curr_value(self):
        return self._curr_value
    
    @property
    def cost_average(self):
        return self._cost_average

    @property
    def cost_basis(self):
        return self._cost_basis
    
    @property
    def allocation(self):
        return self._allocation

class CoinbaseBalance:
    def __init__(self):
        self._total_balance = [0, "USD"]
        self._assets = {}

        load_dotenv()

        api_key = os.getenv("PUBLIC")
        api_secret = os.getenv("PRIVATE")

        self._client = RESTClient(api_key=api_key, api_secret=api_secret)
        self._uuid = self._client.get_portfolios()["portfolios"][0]["uuid"]

        self.get_portfolio_data()

    def get_portfolio_data(self):
        breakdown = self._client.get_portfolio_breakdown(self._uuid)["breakdown"].to_dict()

        total_balance = breakdown["portfolio_balances"]["total_balance"]

        self._total_balance[0], self._total_balance[1] = total_balance["value"], total_balance["currency"]

        for asset in breakdown["spot_positions"]:
            self._assets[asset["asset"]] = Coin(asset)

    @property
    def total_balance(self):
        return self._total_balance

    @property
    def assets(self):
        return self._assets

    # Method for testing through terminal
    def display_data(self):
        print("Assets held in Coinbase:")

        for key, val in self._assets.items():
            print(val, key)

        print("Total portfolio value:", self._total_balance[0], self._total_balance[1])

# main() function for testing
if __name__ == '__main__':
    coin = CoinbaseBalance()
    coin.display_data()
    