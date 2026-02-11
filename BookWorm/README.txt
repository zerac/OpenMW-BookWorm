================================================================================
                                  BOOKWORM
                       The Scholar's Companion for OpenMW
================================================================================
Version: 1.0.0
Author: zerac
Category: User Interface / Gameplay
Requirement: OpenMW 0.50.0 (Revision 47d78e0) or newer
Incompatible: Vanilla Morrowind (Engine), MWSE (Lua)

--- OVERVIEW ---
BookWorm is a modern, Lua-powered library system for Morrowind. It turns the 
act of collecting and reading into a progression-based experience. Every lore 
book, rare tome, and personal letter you find is tracked, categorized, and 
stored in a searchable interface.

Developed and tested exclusively on the "I Heart Vanilla: Director's Cut" 
mod pack to ensure 100% compatibility with official DLCs, quest items, 
and vanilla-plus enhancements.

--- KEY FEATURES ---
* SMART SCANNER: Automatic notifications when you find new reading material 
  on tables, in containers, or in merchant inventories.
* THE LIBRARY: Open your collection anywhere using [K] (Tomes) or [L] (Letters).
* DYNAMIC SEARCH: Use [Backspace] in the UI to search titles in real-time.
* SKILL TRACKING: Tomes are color-coded by skill category (Combat, Magic, Stealth).
* REMOTE READING: Re-read any tracked book instantly through the UI without 
  carrying the physical weight or needing the item in your inventory.
* DATA EXPORT: Press [Shift + K/L] to dump your entire reading list to your 
  'openmw.log'—perfect for completionists tracking their 100% run.

--- CONTROLS ---
[K]             Open / Close Tome Library
[L]             Open / Close Letter/Note Library
[I] / [O]       Previous / Next Page
[Backspace]     Initiate/Modify Search String (inside Library)
[Enter]         Finalize Search (inside Library)
[Shift + K/L]   Export current list to OpenMW Log

--- INSTALLATION ---
1. Manual Installation:
   - Extract the 'BookWorm' folder to your OpenMW 'Data Files' or mod directory.
   - Ensure the structure is: [Mod Folder]/BookWorm.omwscripts
   - In the OpenMW Launcher, navigate to the 'Data Files' tab.
   - Check the box for 'BookWorm.omwscripts'.

2. OpenMW.cfg (Advanced):
   - Add the data path: data="C:/Path/To/Your/Mods/BookWorm"
   - Registration is handled automatically by the .omwscripts file.

--- COMPATIBILITY & STABILITY ---
* Optimized for I Heart Vanilla DC: Includes a built-in blacklist for quest 
  papers (like Caius Cosades' package) to keep your library immersion-friendly.
* Performance Safe: The world scanner uses asynchronous raycasting and 
  throttling to ensure 0% impact on your frame rate.
* Save-Safe: Does not alter vanilla records or your save file's 'content' list.

--- CREDITS & THANKS ---
* The OpenMW Team for the 0.50.0 Lua API.
* The authors of 'I Heart Vanilla: Director's Cut' for the testing baseline.
* Bethesda Game Studios for the original lore.

--- LICENSE & PERMISSIONS ---
This work is licensed under the GNU GPLv3. 
You are free to modify, distribute, and build upon this mod, provided that 
all derivative works are also licensed under the GPLv3 and provide 
attribution to the original author. 

See the included LICENSE file for the full text of the license.
