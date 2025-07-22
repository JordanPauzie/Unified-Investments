import json
import os

from coinbase_module import CoinbaseBalance
from schwab_module import SchwabBalance
from babel.numbers import get_currency_symbol
from dotenv import load_dotenv
from pathlib import Path

def main():
    load_dotenv()

    coin = CoinbaseBalance()
    schwab = SchwabBalance()

    schwab.get_portfolio_data()

    currency = coin.total_balance[1]

    # Helper function for total unrealized return
    def calculate_total_unrealized_return(cb_assets, sb_assets):
        total_unrealized_return = 0

        for asset in cb_assets.values():
            unrealized_return = asset.unrealized_return

            if (asset.unrealized_return[1]):
                total_unrealized_return += unrealized_return[0]
            else:
                total_unrealized_return -= unrealized_return[0]

        for asset in sb_assets.values():
            total_unrealized_return += asset.unrealized_return

        return total_unrealized_return
    
    total_unrealized_return = calculate_total_unrealized_return(coin.assets, schwab.assets)

    # Organize data for table displaying total portfolio data and performance
    portfolio_data = {
        "initial_investment": float(os.getenv("INITIAL")),
        "total_cost_basis": float(coin.total_cost_basis[0]) + float(schwab.total_cost_basis[0]),
        "total_balance": float(coin.total_balance[0]) + float(schwab.total_balance[0]),
        "total_unrealized_return": total_unrealized_return
    }

    # Organize data for display table displaying individual asset data and respective market performance
    assets = []

    for key, val in coin.assets.items():
        unrealized_return = None
        percentage_change = abs(round((float(val.curr_value) - float(val.cost_basis)) / float(val.cost_basis) * 100, 2))
        
        if (val.unrealized_return[1]):
            unrealized_return = f"${val.unrealized_return[0]:,.2f} ({percentage_change}%)"
        else:
            unrealized_return = f"${val.unrealized_return[0]:,.2f} (-{percentage_change}%)"

        assets.append(
            [
                key,
                f"{val.coin_value} {key}",
                "N/A",
                f"{get_currency_symbol(currency)}{float(val.curr_value):,.2f}",
                f"{get_currency_symbol(currency)}{float(val.cost_basis):,.2f}",
                unrealized_return
            ]
        )

    for key, val in schwab.assets.items():
        cost_basis = val.curr_value + val.unrealized_return
        unrealized_return = None
        percentage_change = abs(round((float(val.curr_value) - float(cost_basis)) / float(cost_basis) * 100, 2))

        if (val.unrealized_return >= 0):
                unrealized_return = f"${val.unrealized_return:,.2f} ({percentage_change}%)"
        else:
            unrealized_return = f"${val.unrealized_return:,.2f} (-{percentage_change}%)"

        assets.append(
            [
                key,
                f"N/A",
                f"{val.asset_count}",
                f"{get_currency_symbol(currency)}{float(val.curr_value):,.2f}",
                f"{get_currency_symbol(currency)}{float(cost_basis):,.2f}",
                unrealized_return
            ]
        )

    # Organize data for pie chart
    pie_chart = {
        "labels": [],
        "values": []
    }

    for key, val in coin.assets.items():
        pie_chart["labels"].append(key)
        pie_chart["values"].append(float(val.curr_value))

    for key, val in schwab.assets.items():
        pie_chart["labels"].append(key)
        pie_chart["values"].append(float(val.curr_value))

    # Combine everything into one JSON
    output = {
        "portfolio_data": portfolio_data,
        "assets": assets,
        "pie_chart": pie_chart
    }

    script_dir = Path(__file__).resolve().parent
    json_path = script_dir / "visualization_data.json"

    with open(json_path, "w") as f:
        json.dump(output, f, indent=2)

if __name__ == "__main__":
    main()