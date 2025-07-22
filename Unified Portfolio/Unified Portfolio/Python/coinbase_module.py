import os

from dotenv import load_dotenv
from coinbase.rest import RESTClient

class Coin:
    def __init__(self, asset):
        self._coin_value = asset["total_balance_crypto"]
        self._curr_value = asset["total_balance_fiat"]
        self._cost_average = asset["average_entry_price"]["value"]
        self._cost_basis = asset["cost_basis"]["value"]

        diff = self._curr_value - float(self.cost_basis)

        if (diff < 0):
            self._unrealized_return = [abs(diff), False]
        else:
            self._unrealized_return = [diff, True]

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
    def unrealized_return(self):
        return self._unrealized_return

class CoinbaseBalance:
    def __init__(self):
        self._total_balance = [0, "USD"]
        self._total_cost_basis = [0, "USD"]
        self._assets = {}
        self._cash = 0

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
            if (not asset["is_cash"]):
                self._assets[asset["asset"]] = Coin(asset)
            else:
                self._cash = asset["total_balance_fiat"]
            self._total_cost_basis[0] += float(asset["cost_basis"]["value"])

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
    def display_data(self):
        print("Assets held in Coinbase:")

        for key, val in self._assets.items():
            print(val.coin_value, val.curr_value, val.cost_average, val.cost_basis, key)

        print(self.cash)

        print("Total portfolio value:", self._total_balance[0], self._total_balance[1])

# main() function for testing
if __name__ == '__main__':
    coin = CoinbaseBalance()
    coin.display_data()
    