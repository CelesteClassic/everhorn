# Everhorn
**DESPITE MY BEST EFFORTS THERE MAY BE BUGS, CONSIDER THIS A BETA AT THIS POINT**

**Everhorn** is a map editor for Celeste Classic mods that use [Evercore](https://github.com/CelesteClassic/evercore) or a compatible level system.

![image](https://user-images.githubusercontent.com/25254726/115297327-c0e58180-a164-11eb-960a-832990c192fc.png)

# How it works

Everhorn is a room-based editor, like Ahorn. While it is able to open and save vanilla Celeste carts, splitting them into 16x16 rooms, its true power is revealed when using [Evercore](https://github.com/CelesteClassic/evercore), which is able to load maps from variables `levels` and `mapdata`, located in the second code tab. To get started with an *evercore*-based cart, you need to open up the code in it, find the place where `levels` and `mapdata` are defined and surround them in `--@begin` and `--@end` comments like this:

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

*Everhorn* will now be able to locate this section (*'Everhorn section'*) and **automatically** read `levels` and `mapdata` from it and write them back. Note that you can create as many rooms as you want, however, *Evercore* will actually load them into the normal PICO-8 map the moment you enter them. This means that you *must* place rooms within the boundaries of the map (shown as a grid), or you'll get fucky stuff (nothing permanent though, don't worry). However, you can simply stack rooms on top of each other and it will work fine.

# Install

Currently only 64-bit Windows is supported; it is possible to support Linux and Mac but only if you really beg me (@avi) for it - cross-platform stuff is pain.

Go to the Releases section at the top of the page.

# Usage

* **Ctrl+O** - **Open** (loads rooms and the spritesheet).
* **Ctrl+S**, **Ctrl+Shift+S** - **Save/Save As**. If file exists, only the code in the *Everhorn section* will be updated. If you select a different file, a copy will be created based on the currently opened cart. So, if you need to move rooms from cart A to cart B (for example, to update the cart), open cart A, then save to cart B.
* **Ctrl+R** - **reload** the spritesheet from the currently opened cart.
* **Ctrl+Z**, **Ctrl+Shift+Z** - **Undo/Redo**. Can undo pretty much anything (including something like deleting a room).
* **Middle click** pans camera, **Scroll** zooms in/out.
* **N** - **create** new room.
* **Alt+Left/Right Mouse Button** - **move** and **resize** rooms.
* **Up/Down, Ctrl+Up/Down** - **switch** between rooms and **reorder** them (can also click to switch).
* **R** - **rename** room. (I was told that in newleste.p8, room don't have titles; this will work as room options instead)
* **Shift+Delete** - **delete** room.
* **Ctrl+Shift+C** - **copy** the entire room (it's text-based, so you can send it to someone directly).
* **Space** shows/hides the **tool panel** with the tools and the tileset. The tileset also includes 3 **autotiles**, which will automatically pick the right version of the tile based on it's neighbors, both when drawing and erasing. They are defined to match vanilla snow, ice, and dirt (you can put any other sprites instead, of course, and I can define more if needed).
* * **Brush** - **left click** to paint with the tile, **right click** to erase (tile 0)
* * **Rectangle** - same but in rectangles.
* * **Select** - basic selection tool, click and drag to select a rectangle, then you can move it, place it, copy or cut it with **Ctrl+C**, **Ctrl+X** and paste with **Ctrl+V**.
* **Tab** toggles **playtesting mode**. When it's enabled, saving a cart will also inject a line of code that spawns you right in the current room and disables music. (conveniently, in PICO-8 you can press **Ctrl+R** to restart the cart and it will reload the map as well!). Press Tab again to enable **2 dashes**.
* **CTRL+H** - shows/hides **garbage tiles** on the tool panel
