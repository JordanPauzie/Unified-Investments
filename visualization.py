import pandas as pd
import matplotlib.pyplot as plt

from coinbase_module import CoinbaseBalance 
from schwab_module import SchwabBalance 

def generate_pie(coinbase, schwab):
    cb_balance = coinbase.total_balance()
    sb_balance = schwab.total_balance()

    



df = pd.DataFrame({'mass': [3, 4.87 , 5.97], 'radius': [2439.7, 6051.8, 6378.1]}, index=['Mercury', 'Venus', 'Earth'])
plot = df.plot.pie(y='mass', figsize=(5, 5))

plt.show()

print("hello world")