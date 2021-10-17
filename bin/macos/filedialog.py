from __future__ import print_function
import tkinter as tk
from tkinter import filedialog
import argparse
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("type")
    args=parser.parse_args()
    root = tk.Tk()
    root.withdraw()
    root.lift()
    root.wm_attributes("-topmost",True)
    root.after_idle(root.call, 'wm', 'attributes', '.', '-topmost', False)

    if args.type == "open":
        file_path = filedialog.askopenfilename(filetypes=[("pico-8 cart", "*.p8")])
    else:
        file_path = filedialog.asksaveasfilename(defaultextension='.p8',filetypes=[("pico-8 cart", "*.p8")])
    if not file_path:
        print(0,"no path")
    else:
        print(1,file_path)

if __name__=="__main__":
    main()

