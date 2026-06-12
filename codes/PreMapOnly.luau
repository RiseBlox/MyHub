local ussiprepass = loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/SIPrePass.luau", true))()

local Options = {
    ReadMe = false,
    ShutdownWhenDone = true,
    mode = "full",
    timeout = -1,
    SaveBytecode = true,
    DecompileIgnore = {},
    IgnoreList = {},
    TreatUnionsAsParts = false
}

local PrepassOptions = {
    RequestsPerMinute = 1495,
    MaxInFlight       = 30,
    ApiUrl            = "https://api.lua.expert/decompile",
    Verbose           = true,
    SkipPrepass       = false,
    SkipSaveInstance  = false,
    UssiRepoURL       = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/",
    UssiScript        = "SIMapOnly",
}

ussiprepass(Options, PrepassOptions)