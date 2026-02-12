# OpenMW BookWorm (Director's Cut)

A modern, immersive lore-tracking and library management mod for **OpenMW 0.50+ (Revision 47d78e0)**. Designed specifically for the *I Heart Vanilla DC* mod list, BookWorm allows you to build a comprehensive digital library of every tome and letter you discover in Vvardenfell without cluttering your physical inventory.

## 🚀 Key Features

*   **Remote Reading UI**: Open and read any book or letter directly from your library interface using a "Ghost Object" system.
*   **Real-Time Search**: Integrated search bar in the library UI. Use **Backspace** to filter titles instantly by keywords.
*   **Alphabetical Indexing**: Smart "The/A/An" prefix handling—*The Lusty Argonian Maid* is correctly indexed under **L**, not **T**.
*   **Intelligent Inventory Reversion**: Automatically detects and reverts "Take" actions from the UI to prevent item duplication via inventory snapshots.
*   **Async World Scanner**: An optimized, non-blocking raycasting system that alerts you when looking at a "New Discovery" in the world.
*   **Thematic UI**: A paginated interface using `tx_menubook.dds` with dynamic category coloring (Combat, Magic, Stealth, and Lore).
*   **Collection Progression**: Tracks completion percentages for each skill category based on the game's total book records.
*   **Audio Immersion**: Seamlessly synchronized vanilla sound effects for opening, closing, and searching, with specific cues for skill raises.
*   **External Export**: Shift+K/L commands to export your entire reading history directly to the `openmw.log`.
*   **Customizable controls**: You can set page item count and most controls in the Options - Scripts menu.

## 🛠 Technical Implementation (OpenMW 0.50 Lua)

*   **Async Rendering Rays**: Uses `nearby.asyncCastRenderingRay` to identify targets without impacting frame rates.
*   **Inventory Snapshots**: Uses `Actor.inventory:countOf` to maintain data integrity during remote UI sessions.
*   **State Encapsulation**: Modular logic architecture ensuring `player.lua` remains clean while specialized handlers manage UI, Input, and Remote objects.
*   **Ghost Object Lifecycle**: Global-to-Local event bus manages the creation and safe deletion of transient `world.createObject` targets.
*   **Input Capture**: Specialized `onKeyPress` handling to block engine UI keys (like Journal) during active search input.

## ⌨️ Default Controls

*   **[ K ]**: Toggle **Tomes** Library (Books).
*   **[ L ]**: Toggle **Letters** Library (Scrolls and Notes).
*   **[ I ] / [ O ]**: Previous / Next Page.
*   **[ Backspace ]**: Initiate or modify **Search**.
*   **[ Enter ]**: Finalize search and return to navigation.
*   **[ Shift + K/L ]**: Export collection to `openmw.log`.
*   **[ Left Click ]**: Read a book remotely from the list.

## 📂 Project Structure

```text
scripts/BookWorm/
├── global.lua            # Global ghosting logic & inventory reconciliation
├── player.lua            # Main entry point & event distribution
├── settings.lua          # Allow custom controls using Options-Scripts menu
├── scanner.lua           # Async raycasting & vision logic
├── scanner_controller.lua # Throttling & scan concurrency management
├── state_manager.lua     # Database scanning & save/load persistence
├── ui_library.lua        # UI rendering, search visuals, & templates
├── ui_handler.lua        # Mode transition & container scanning logic
├── input_handler.lua     # Window toggling, filtering, & pagination
├── remote_manager.lua    # Ghost object state & audio suppression
├── transition_handler.lua # Seamless Menu/Inventory escape logic
├── reader.lua            # Marking logic & trackable guards
├── inventory_scanner.lua # Container & Barter notification logic
└── utils.lua             # Skill categories, blacklists, & color palette
