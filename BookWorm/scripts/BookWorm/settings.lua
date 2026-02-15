-- scripts/BookWorm/settings.lua
--[[
    BookWorm for OpenMW
    Copyright (C) 2026 [zerac]

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org>.
--]]

local I = require('openmw.interfaces')

-- Match the vanilla omw/input/settings.lua pattern
I.Settings.registerPage({
    key = "BookWorm",
    l10n = "BookWorm", 
    name = "BookWorm",
    description = "Library Management Settings"
})

I.Settings.registerGroup({
    key = "Settings_BookWorm_UI",
    page = "BookWorm",
    l10n = "BookWorm",
    name = "Interface Settings",
    permanentStorage = true, -- Matches vanilla requirement for MENU context
    order = 1,
    settings = {
        {
            key = "itemsPerPage",
            name = "Items Per Page",
            description = "Number of books displayed per page.",
            type = "number",
            default = 20,
            renderer = "number",
            argument = { min = 5, max = 50, step = 1 },
            order = 1
        },
    }
})

I.Settings.registerGroup({
    key = "Settings_BookWorm_Keys",
    page = "BookWorm",
    l10n = "BookWorm",
    name = "Controls",
    permanentStorage = true, -- Matches vanilla requirement for MENU context
    order = 2,
    settings = {
        {
            key = "openTomesKey",
            name = "Open Tomes Library",
            description = "Key to open the Tomes menu (default: K).",
            type = "string",
            default = "k",
            renderer = "textLine",
            order = 1
        },
        {
            key = "openLettersKey",
            name = "Open Letters Library",
            description = "Key to open the Letters menu (default: L).",
            type = "string",
            default = "l",
            renderer = "textLine",
            order = 2
        },
        {
            key = "prevPageKey",
            name = "Previous Page",
            description = "Key for previous page (default: I).",
            type = "string",
            default = "i",
            renderer = "textLine",
            order = 3
        },
        {
            key = "nextPageKey",
            name = "Next Page",
            description = "Key for next page (default: O).",
            type = "string",
            default = "o",
            renderer = "textLine",
            order = 4
        }
    }
})