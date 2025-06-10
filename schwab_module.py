import os
from dotenv import load_dotenv
from coinbase.rest import RESTClient

class SchwabBalance:
    def __init__(self):
        self.total_balance = [0, "USD"]
        self.assets = {}

        # WIP

    def get_portfolio_data(self):
        return
        # WIP

    # Method for testing through terminal
    def display_data(self):
        return
        # WIP

# main() function for testing
if __name__ == '__main__':
    coin = SchwabBalance()
    coin.display_data()