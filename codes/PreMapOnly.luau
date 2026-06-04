local ussiprepass = loadstring(game:HttpGet("https://gitlab.com/centerepic/ussiprepass/-/raw/main/main.luau", true))()

local Options = {}

local PrepassOptions = {
    RequestsPerMinute = 1475,
    MaxInFlight       = 30,
    ApiUrl            = "https://api.lua.expert/decompile",
    Verbose           = true,
    SkipPrepass       = false,
    SkipSaveInstance  = false,
    UssiRepoURL       = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/",
    UssiScript        = "SIMapOnly",
}

ussiprepass(Options, PrepassOptions)