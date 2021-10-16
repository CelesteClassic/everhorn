import tkinter as tk
from tkinter import filedialog
import argparse
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("type")
    args=parser.parse_args()
    root = tk.Tk()
    root.withdraw()

    if args.type == "open":
        file_path = filedialog.askopenfilename(filetypes=[("pico-8 cart", "*.p8")])
    else:
        file_path = filedialog.asksaveasfilename(defaultextension='.p8',filetypes=[("pico-8 cart", "*.p8")])
    if file_path is None:
        print(0,"no path")
    else:
        print(1,file_path)

if __name__=="__main__":
    main()

