if (test-path C:\Apps\OpenMW_Mods\Gameplay\BookWorm ) { remove-item -Recurse C:\Apps\OpenMW_Mods\Gameplay\BookWorm }

copy-item -recurse .\BookWorm C:\Apps\OpenMW_Mods\Gameplay\

if (test-path "C:\Users\zerac\Documents\My Games\OpenMW\openmw.log") { remove-item "C:\Users\zerac\Documents\My Games\OpenMW\openmw.log" }