# Shell

When running commands:

- Prefer bash: `bash -lc '…'`
- Do not emit PowerShell (`Get-ChildItem`, `Set-Location`).
- Do not emit cmd (`dir`, `cd /d`).
- From repo root: `ls`, `git status`, `npx hated-wow-mcp …`

# Sources

- All source code is found in ./src.
- ./gulpfile.js is used to create the AddOn structure and move to WoW folders as needed.
- ./package.json specifies many values used to generate the final .TOC
- ./src/libs/Ace3 contains the Ace3 library components used in this project.

# Work

- Use wow_api_search
- Use wow_lua_lint on the files you change

# Ace3

This addon uses embedded Ace3 under libs/Ace3.
Rules:

- Prefer Ace3 over raw CreateFrame/RegisterEvent when a library already covers it.
- Before writing Ace3 calls, read the matching file under libs/Ace3 (AceAddon-3.0.lua, AceEvent-3.0.lua, AceDB-3.0.lua, etc.).
- Obtain libraries only via LibStub("Name-3.0"). Do not invent globals like AceAddon.
- Embed mixins in NewAddon(...), e.g. "AceEvent-3.0", "AceConsole-3.0", "AceDB-3.0".
- TOC must list each Ace XML/Lua file before our addon files.
- wow_lua_lint does not know Ace3. Ignore "unknown API" on LibStub/Ace methods. Still run it for Blizzard APIs.
- Do not replace Ace3 with Blizzard Settings unless asked.
