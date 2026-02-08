# 📚 BookWorm for OpenMW

A modern, lightweight library management and book-tracking mod built specifically for the **OpenMW 0.50+** Lua API. **BookWorm** allows scholars of Vvardenfell to track their reading progress, discover rare skill books through environmental scanning, and maintain a persistent personal library.

## 🌟 Key Features

*   **Environmental Shelf Scanner:** Automatically identifies books in the world as you look at them using advanced dot-product vector math.
*   **Rare Book Detection:** Instantly notifies you if a book on a shelf contains a skill increase, playing a unique "rare" discovery sound.
*   **Dynamic Library UI:** A custom, paginated book interface (using `tx_menubook.dds`) that categorizes your read collection into Combat, Magic, Stealth, and Lore.
*   **Smart Save/Load:** Includes a "time-travel" safety filter that ensures your reading history stays synchronized with your character's timeline during save loads.
*   **Scholar's Export:** Export your entire reading history (including timestamps and skill types) directly to the `openmw.log` with a simple hotkey.

## 🛠️ Modular Architecture

The mod is split into specialized Lua modules for maximum performance and easy maintenance:
*   **player.lua**: The central event controller.
*   **global.lua**: Handles inventory-use events and item registration.
*   **scanner.lua**: Dedicated spatial detection and camera math.
*   **ui_library.lua**: Handles all visual layouts and UI construction.
*   **state_manager.lua**: Manages data persistence, loading filters, and logging.
*   **utils.lua**: Contains skill maps, color definitions, and naming helpers.

## ⌨️ Controls

*   **[K]**: Open/Close Personal Library.
*   **[I] / [O]**: Navigate Library pages (with audio feedback).
*   **[Shift + K]**: Export library data to `openmw.log`.

## 📦 Installation

1. Copy the `scripts` folder into your OpenMW `Data Files` directory or a dedicated mod folder.
2. Register the mod in your `openmw.cfg` or via the [OpenMW Launcher](https://openmw.org):
   `content=BookWorm.omwscripts` (if using a manifest file) or ensure the scripts are properly pathed.
3. Ensure you are running **OpenMW 0.50** or newer.

## 🔗 Resources

*   [OpenMW Lua API Documentation](https://openmw.readthedocs.io)
*   [Modding-OpenMW.com](https://modding-openmw.com)
