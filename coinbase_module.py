import os
from dotenv import load_dotenv
from coinbase.rest import RESTClient

class CoinbaseBalance:
    def __init__(self):
        self.total_balance = [0, "USD"]
        self.assets = {}

        load_dotenv()
        
        api_key = os.getenv("PUBLIC")
        api_secret = os.getenv("PRIVATE")

        self.client = RESTClient(api_key=api_key, api_secret=api_secret)
        self.uuid = self.client.get_portfolios()["portfolios"][0]["uuid"]

        self.get_portfolio_data()

    def get_portfolio_data(self):
        breakdown = self.client.get_portfolio_breakdown(self.uuid)["breakdown"].to_dict()

        total_balance = breakdown["portfolio_balances"]["total_balance"]
    
        self.total_balance[0] = total_balance["value"]
        self.total_balance[1] = total_balance["currency"]

        spot = breakdown["spot_positions"]
        
        for asset in spot: 
            type = asset["asset"]
            self.assets[type] = asset["total_balance_crypto"]

    # Method for testing through terminal
    def display_data(self):
        print("Assets held in Coinbase:")

        for key, val in self.assets.items():
            print(val, key)

        print("Total portfolio value:", self.total_balance[0], self.total_balance[1])

# main() function for testing
if __name__ == '__main__':
    coin = CoinbaseBalance()
    coin.display_data()
    