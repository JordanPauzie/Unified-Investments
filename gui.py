import tkinter as tk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from visualization import Visualization
from coinbase_module import CoinbaseBalance
from schwab_module import SchwabBalance

class PortfolioApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Unified Investments")
        self.root.geometry("2000x1000")

        self.coin = CoinbaseBalance()
        self.schwab = SchwabBalance()
        self.plots = Visualization(self.coin, self.schwab)

        self.canvas = None

        self.setup_ui()

    def setup_ui(self):
        self.plot_frame = tk.Frame(self.root)
        self.plot_frame.pack(fill=tk.BOTH, expand=True)

        self.plot_frame.columnconfigure(0, weight=1)
        self.plot_frame.columnconfigure(1, weight=2) 
        self.plot_frame.rowconfigure(0, weight=1)

        self.left_frame = tk.Frame(self.plot_frame)
        self.left_frame.grid(row=0, column=0, padx=0, pady=0, sticky="nsew")

        self.right_frame = tk.Frame(self.plot_frame)
        self.right_frame.grid(row=0, column=1, padx=0, pady=0, sticky="nsew")
        self.right_frame.rowconfigure(0, weight=1)
        self.right_frame.rowconfigure(1, weight=1)
        self.right_frame.columnconfigure(0, weight=1)

        self.top_right_frame = tk.Frame(self.right_frame)
        self.top_right_frame.grid(row=0, column=0, sticky="nsew")

        self.bottom_right_frame = tk.Frame(self.right_frame)
        self.bottom_right_frame.grid(row=1, column=0, sticky="nsew")

        self.show_plot(self.plots.portfolio_breakdown_pie_chart(), self.left_frame)
        self.show_plot(self.plots.plot_asset_table(), self.top_right_frame)
        self.show_plot(self.plots.display_total_portfolio_performance(), self.bottom_right_frame)

        overlay_button = tk.Button(
            self.left_frame, 
            text="Refresh Chart", 
            font=("monospace", 15), 
            command=self.refresh
        )

        overlay_button.place(relx=0.95, rely=0.05, anchor="ne")

    def refresh(self):
        self.coin = CoinbaseBalance()
        self.schwab = SchwabBalance()
        self.plots = Visualization(self.coin, self.schwab)
        
        for frame in [self.left_frame, self.top_right_frame, self.bottom_right_frame]:
            for widget in frame.winfo_children():
                widget.destroy()

        self.show_plot(self.plots.portfolio_breakdown_pie_chart(), self.left_frame)
        self.show_plot(self.plots.plot_asset_table(), self.top_right_frame)
        self.show_plot(self.plots.display_total_portfolio_performance(), self.bottom_right_frame)

        overlay_button = tk.Button(
            self.left_frame, 
            text="Refresh Charts", 
            font=("monospace", 15), 
            command=self.refresh
        )

        overlay_button.place(relx=0.95, rely=0.05, anchor="ne")

    def show_plot(self, fig, frame):
        canvas = FigureCanvasTkAgg(fig, master=frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True, padx=0, pady=0)

    def show_pie_chart(self):
        fig = self.plots.portfolio_breakdown_pie_chart()
        self.show_plot(fig)

    def show_asset_table(self):
        fig = self.plots.plot_asset_table()
        self.show_plot(fig)

    def show_performance(self):
        fig = self.plots.display_total_portfolio_performance()
        self.show_plot(fig)

def main():
    root = tk.Tk()
    app = PortfolioApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()