# OpenMW BookWorm (Director's Cut)

A modern, immersive lore-tracking and library management mod for **OpenMW 0.50+**. Designed specifically for the *I Heart Vanilla DC* mod list, BookWorm allows you to build a comprehensive digital library of every tome and letter you discover in Vvardenfell without cluttering your physical inventory.

## 🚀 Key Features

*   **Remote Reading UI**: Open and read any book or letter directly from your library interface using a "Ghost Object" system.
*   **Intelligent Inventory Reversion**: Automatically detects and reverts "Take" actions from the UI to prevent item duplication, even when interacting with existing item stacks.
*   **Lore Scanner**: A dot-product based vision system that alerts you when looking at a "New Discovery" (unread book or rare tome) in the world.
*   **Thematic UI**: A paginated, high-resolution interface using vanilla textures with dynamic category coloring (Combat, Magic, Stealth, and Lore).
*   **Skill Book Identification**: Automatically highlights and categorizes books that provide skill increases.
*   **Audio Immersion**: Integrated vanilla sound effects for opening, closing, and flipping pages, including specific cues for skill raises.
*   **External Export**: Shift+K/L commands to export your entire reading history directly to the `openmw.log` for external reference.

## 🛠 Technical Implementation (OpenMW 0.50 Lua)

*   **Inventory Delta Logic**: Uses `Actor.inventory:countOf` snapshots to maintain inventory integrity during remote UI sessions.
*   **Ghost Object Management**: Utilizes `world.createObject` to generate transient UI targets that are safely garbage-collected upon UI closure.
*   **Stack-Safety**: Implements strict `parentContainer` and `count` validation to ensure engine merges during "Take" actions do not cause Lua state crashes.
*   **Simulation Time Persistence**: Saves reading timestamps using `core.getSimulationTime()` for accurate cross-save lore tracking.

## ⌨️ Controls

*   **[ K ]**: Toggle **Tomes** Library (Books).
*   **[ L ]**: Toggle **Letters** Library (Scrolls and Notes).
*   **[ I ] / [ O ]**: Previous / Next Page.
*   **[ Shift + K/L ]**: Export collection to `openmw.log`.
*   **[ Left Click ]**: Read a book remotely from the list.

## 📂 Project Structure

```text
scripts/BookWorm/
├── global.lua        # Ghosting logic & inventory stack cleanup
├── player.lua        # Event hub, scanner throttling, & UI state
├── scanner.lua       # Dot-product target acquisition
├── state_manager.lua # Save/Load persistence & log exporting
├── ui_library.lua    # OpenMW.UI rendering & widget templates
├── input_handler.lua # Window toggling & pagination logic
└── utils.lua         # Skill mapping, color palette, & filters
