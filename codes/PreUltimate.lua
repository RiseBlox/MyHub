local ussiprepass = loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/SIPrePass.luau", true))()

local Options = {
    mode = "optimized",
    DecompileTimeout = -1,
    DecompileIgnore = {},
    SaveBytecode = true,
    IsolateLocalPlayer = true,
    RemovePlayerCharacters = false,
    NilInstances = true,
    SafeMode = true,
    ReadMe = false,
    IgnoreList = {},
    RiskyServicesDisabled = {},
}

local PrepassOptions = {
    RequestsPerMinute = 1495,
    MaxInFlight       = 30,
    ApiUrl            = "https://api.lua.expert/decompile",
    Verbose           = true,
    SkipPrepass       = true,
    SkipSaveInstance  = false,
    UssiRepoURL       = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/",
    UssiScript        = "SIUltimate",
}

ussiprepass(Options, PrepassOptions)