================================================================================
                                  BOOKWORM
                       The Scholar's Companion for OpenMW
================================================================================
Version: 1.0.1
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

--- SETTINGS CONFIGURATION ---
BookWorm utilizes the native OpenMW 0.50.0 Script Settings interface. You 
can customize your library experience and notification behavior without 
ever leaving the game. 

To access these settings:
1. Press [ESC] to open the Main Menu.
2. Select 'Options' and navigate to the 'Scripts' tab.
3. Select 'BookWorm' from the left-hand menu.

Available Options:

[ USER INTERFACE ]
* ITEMS PER PAGE: Adjust how many titles appear in the list (5-50). Default: 20.

[ KEYBINDINGS ]
* OPEN TOMES: Set the key to open your Book Library. Default: [K].
* OPEN LETTERS: Set the key to open your Letter/Note Library. Default: [L].
* PREVIOUS/NEXT PAGE: Customize your navigation keys. Default: [I] and [O].

[ NOTIFICATIONS ]
* DISPLAY MESSAGES: Toggle the "New book discovered" corner notifications.
* ON-READING NOTIF: Show a message specifically when reading a book for the first time.
* THROTTLE INVENTORY: Prevents notification spam when picking up stacks or 
  multiple items quickly.
* NOTIFICATION SOUNDS: Toggle the audio cue played when finding new lore.
* RECOGNIZE SKILL BOOKS: Enable or disable specialized tracking for skill-up books.
* SHOW SKILL NAMES: Display the specific skill (e.g., "Acrobatics") in the notification.
* SKILL SOUNDS: Toggle the unique audio cue played when a skill book is discovered.

Note: Settings are stored in your global 'settings.cfg', meaning your 
preferences persist across all characters and save files.

--- L10N ---
Google translated, so please take with a small rock of salt. Feedback is welcome.
Currently includes: DE FR PL SV RU 

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
