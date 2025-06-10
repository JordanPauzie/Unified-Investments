import os
from dotenv import load_dotenv
from coinbase.rest import RESTClient

class SchwabBalance:
    def __init__(self):
        self._total_balance = [0, "USD"]
        self._assets = {}

        # WIP

    def get_portfolio_data(self):
        return
        # WIP

    @property
    def total_balance(self):
        return self._total_balance

    @property
    def assets(self):
        return self._assets

    # Method for testing through terminal
    def display_data(self):
        return
        # WIP

# main() function for testing
if __name__ == '__main__':
    coin = SchwabBalance()
    coin.display_data()