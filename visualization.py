import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 
import os

from dotenv import load_dotenv
from coinbase_module import CoinbaseBalance 
from schwab_module import SchwabBalance 
from babel.numbers import get_currency_symbol

class Visualization:
    def __init__(self, coinbase, schwab):
        self.currency = coinbase.total_balance[1]
        self.cb_balance = coinbase.total_balance[0]
        self.sb_balance = schwab.total_balance[0]
        self.total_balance = float(self.cb_balance) + float(self.sb_balance)
        self.cb_cost_basis = coinbase.total_cost_basis[0]
        self.sb_cost_basis = schwab.total_cost_basis[0]
        self.total_cost_basis = self.cb_cost_basis + self.sb_cost_basis
        self.cb_assets = coinbase.assets
        self.sb_assets = schwab.assets
        self.total_unrealized_return = self.calculate_total_unrealized_return()

    # Helper function for initialization
    def calculate_total_unrealized_return(self):
        total_unrealized_return = 0

        for asset in self.cb_assets.values():
            unrealized_return = asset.unrealized_return

            if (asset.unrealized_return[1]):
                total_unrealized_return += unrealized_return[0]
            else:
                total_unrealized_return -= unrealized_return[0]

        for asset in self.sb_assets.values():
            total_unrealized_return += asset.unrealized_return

        return total_unrealized_return
    
    # Display table displaying total portfolio data and performance
    def display_total_portfolio_performance(self):
        load_dotenv()

        fig = plt.figure(figsize=(10, (len(self.cb_assets) + len(self.sb_assets))*0.5 + 1))

        total_unrealized_return = None
        percentage_change = abs(round((float(self.total_balance) - float(self.total_cost_basis)) / float(self.total_cost_basis) * 100, 2))

        if (self.total_unrealized_return < 0):
            total_unrealized_return = f"-${self.total_unrealized_return:,.2f} (-{percentage_change}%)"
        else:
            total_unrealized_return = f"${self.total_unrealized_return:,.2f} ({percentage_change}%)"

        table_data = [[
            f"${int(os.getenv("INITIAL")):,.2f}", # Initial investment is hardcoded because of API limitations
            f"${self.total_cost_basis:,.2f}",
            f"${self.total_balance:,.2f}",
            total_unrealized_return
        ]]

        ax = plt.gca()
        ax.axis("off")

        table = ax.table(
            cellText=table_data,
            colLabels=["Total Initial Investment", "Total Cost Basis", "Total Balance", "Total Unrealized Return"],
            cellLoc='center',
            loc='center'
        )

        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.3, 1.3)

        plt.tight_layout()
        
        return fig

    # Display table displaying individual asset data and respective market performance  
    def plot_asset_table(self):
        fig = plt.figure(figsize=(10, (len(self.cb_assets) + len(self.sb_assets))*0.5 + 1))

        table_data = []

        # Add data from Coinbase
        for key, val in self.cb_assets.items():
            unrealized_return = None
            percentage_change = abs(round((float(val.curr_value) - float(val.cost_basis)) / float(val.cost_basis) * 100, 2))

            if (val.unrealized_return[1]):
                unrealized_return = f"${val.unrealized_return[0]:,.2f} ({percentage_change}%)"
            else:
                unrealized_return = f"${val.unrealized_return[0]:,.2f} (-{percentage_change}%)"

            table_data.append(
                [
                    key, 
                    f"{val.coin_value} {key}",
                    "N/A",
                    f"{get_currency_symbol(self.currency)}{float(val.curr_value):,.2f}",
                    f"{get_currency_symbol(self.currency)}{float(val.cost_basis):,.2f}",
                    unrealized_return
                ]
            )

        # Add data from Schwab
        for key, val in self.sb_assets.items():
            cost_basis = val.curr_value + val.unrealized_return
            unrealized_return = None
            percentage_change = abs(round((float(val.curr_value) - float(cost_basis)) / float(cost_basis) * 100, 2))

            if (val.unrealized_return >= 0):
                unrealized_return = f"${val.unrealized_return:,.2f} ({percentage_change}%)"
            else:
                unrealized_return = f"${val.unrealized_return:,.2f} (-{percentage_change}%)"

            table_data.append(
                [
                    key, 
                    f"N/A",
                    f"{val.asset_count}",
                    f"{get_currency_symbol(self.currency)}{float(val.curr_value):,.2f}",
                    f"{get_currency_symbol(self.currency)}{float(cost_basis):,.2f}",
                    unrealized_return
                ]
            )

        ax = plt.gca()
        ax.axis("off")

        table = ax.table(
            cellText=table_data,
            colLabels=["Asset", "Crypto Balance", "Number of Shares", "Fiat Balance", "Cost Basis", "Unrealized Return"],
            cellLoc='center',
            loc='center'
        )

        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.3, 1.3)

        plt.tight_layout()
        
        return fig

    # Display total portfolio value as pie chart alongside individual asset values
    def portfolio_breakdown_pie_chart(self):
        total_asset_values = []
        total_asset_indices = []
    
        for key, value in self.cb_assets.items():
            total_asset_indices.append(key)
            total_asset_values.append(value.curr_value)

        for key, value in self.sb_assets.items():
            total_asset_indices.append(key)
            total_asset_values.append(value.curr_value)

        fig = plt.figure(figsize=(3, 3))
        wedges, texts, autotexts = plt.pie(
            x=total_asset_values,
            labels=total_asset_indices,
            autopct='%1.2f%%',
            pctdistance=0.80,
            colors=sns.color_palette('Set2'),
            startangle=90,
            counterclock=False,
            textprops={'fontsize': 10, 'fontfamily': 'monospace'}
        )

        centre_circle = plt.Circle((0, 0), 0.65, fc='white')
        plt.gca().add_artist(centre_circle)
        plt.title("Assets", fontsize=10, fontfamily='monospace')
        plt.tight_layout()
        
        return fig

# main() function for testing
if __name__ == '__main__':
    coin = CoinbaseBalance()
    schwab = SchwabBalance()

    count = 0

    while (count >= 0):
        if (count != 0):
            n = input("Refresh? (Y/N) \n")
        else:
            n = "Y"

        if (n == "Y"):
            schwab.get_portfolio_data()

            plots = Visualization(coin, schwab)
            
            fig1 = plots.portfolio_breakdown_pie_chart()
            fig2 = plots.plot_asset_table()
            fig3 = plots.display_total_portfolio_performance()

            fig1.show()
            fig2.show()
            fig3.show()

            count += 1
        elif (n == "N"):
            count = -1

    input("Press Enter to close all plots...")
