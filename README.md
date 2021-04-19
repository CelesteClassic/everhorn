# Everhorn
don't look here, it's not ready yet


**Everhorn** is a map editor for Celeste Classic mods that use [evercore](https://github.com/CelesteClassic/evercore) or are based on it.

![image](https://user-images.githubusercontent.com/25254726/115166301-29782400-a0bb-11eb-9b47-a78dc3e98f81.png)

# Install

Currently only 64-bit Windows is supported, Linux and Mac are possible but only if you beg me (@avi) for it - cross-platform stuff is pain.

1. Install [love2d](https://love2d.org/) (use installer)
2. Press the green Code button at the top of this page and download the .zip with the latest version
3. Extract the zip
4. Double-click `everhorn.bat` to run it

# How it works

Everhorn is a room-based editor, like Ahorn. To get started, you'll need a to get the [evercore](https://github.com/CelesteClassic/evercore) cart (Everhorn can open vanilla Celeste carts, but only in a very basic way, and can't save them). Next, you need to open up the code in it, find the place where `levels` and `mapdata` are defined and surround them in `--@begin` and `--@end` comments like this:

```lua
--@begin
levels={
  ...
}

mapdata={
  ...
}
--@end
```

*Everhorn* will now be able to locate this section (*'everhorn section'*) and **automatically** read the rooms from it and write it back. Note that you can create as many rooms as you want, however, *evercore* will actually load them into the normal PICO-8 map the moment you enter them. This means that you *must* place rooms within the boundaries of the map (shown as a grid), or you'll get fucky stuff (nothing permanent though, don't worry). However, you can simply stack rooms on top of each other and it will work fine.

# Usage

* **Ctrl+O** - **Open** (loads rooms and the spritesheet).
* **Ctrl+S**, **Ctrl+Shift+S** - **Save/Save As**. If file exists, only the code in the *everhorn section* will be updated. If you select a different file, a copy will be created based on the currently opened cart. So, if you need to move rooms from cart A to cart B (for example, to update the cart), open cart A, then save to cart B.
* **Ctrl+Z**, **Ctrl+Shift+Z** - **Undo/Redo**. Can undo pretty much anything (including something like deleting a room).
* **Middle click** pans camera, **Scroll** zooms in/out.
* **N** - **create** new room.
* **Alt+Left/Right Mouse Button** - **move** and **resize** rooms.
* **Up/Down, Ctrl+Up/Down** - **switch** between rooms and **reorder** them (can also click to switch).
* **R** - **rename** room.
* **Shift+Delete** - **delete** room.
* **Ctrl+Shift+C** - **copy** the entire room (it's text-based, so you can send it to someone directly).
* **Space** shows/hides the **tool panel** with the tools and the tileset. The tileset also includes 2 **autotiles**, which will automatically pick the right version of the tile based on it's neighbors. They are defined to match vanilla snow and ice (you can put any sprites instead, of course, and I can define more if needed).
* * **Brush** - left click to paint with the tile, right click to erase (tile 0)
* * **Rectangle** - same but in rectangles.
* * **Select** - basic selection tool, click and drag to select a rectangle, then you can move it, place it, copy or cut it with **Ctrl+C**, **Ctrl+X** and paste with **Ctrl+V**.
* **Tab** toggles **playtesting mode**. When it's enabled, saving a cart will also inject a line of code that spawns you right in the current room and disables music. (what's nice is that in PICO-8, you can press **Ctrl+R** to restart the cart and it will reload it as well!). Disabling the mode and saving will remove it.
