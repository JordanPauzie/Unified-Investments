import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns 

from coinbase_module import CoinbaseBalance 
from schwab_module import SchwabBalance 
from babel.numbers import get_currency_symbol

class Visualization:
    def __init__(self, coinbase, schwab):
        self.currency = coinbase.total_balance[1]
        self.cb_balance = coinbase.total_balance[0]
        self.sb_balance = schwab.total_balance[0]
        self.total_balance = float(self.cb_balance) + float(self.sb_balance)
        self.cb_assets = coinbase.assets
        self.sb_assets = schwab.assets

    # Plot total portfolio value as pie chart alongside individual asset values
    def portfolio_breakdown_pie_chart(self):
        total_asset_values = []
        total_asset_indices = []
        
        for key, value in self.cb_assets.items():
            total_asset_indices.append(key)
            total_asset_values.append(value.curr_value)

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 8), gridspec_kw={'width_ratios': [2, 1]})

        wedges, texts, autotexts = ax1.pie(
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

        ax1.add_artist(centre_circle)
        
        ax1.set_title("Assets", fontsize=16, fontfamily='monospace')

        table_data = [
            ["Total Balance", get_currency_symbol(self.currency) + f"{self.total_balance:,.2f}"]
        ]

        for key, val in self.cb_assets.items():
            table_data.append([key, f"${val.curr_value:,.2f}"])

        ax2.axis("off")

        table = ax2.table(
            cellText=table_data,
            colLabels=["Asset", "Value (" + self.currency + ")"],
            cellLoc='left',
            loc='center'
        )

        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.2, 1.2)

        plt.tight_layout()
        plt.show()

# main() function for testing
if __name__ == '__main__':
    coin = CoinbaseBalance()
    schwab = SchwabBalance()
    plots = Visualization(coin, schwab)
    
    plots.portfolio_breakdown_pie_chart()