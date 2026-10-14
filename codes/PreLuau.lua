local ussiprepass = loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/SIPrePass.luau", true))()

local Options = {
    ReadMe = false,
    RiskyServicesDisabled = {},
    SafeMode = true,
    mode = "full",
    DecompileTimeout = -1,
    BytecodeTimeout = -1,
    SaveBytecode = true,
    DecompileIgnore = {},
    IgnoreList = {},
    NilInstances = true,
    IsolateLocalPlayer = true,
    SavePlayerCharacters = true,
}

local PrepassOptions = {
    RequestsPerMinute = 1495,
    MaxInFlight       = 30,
    ApiUrl            = "https://api.lua.expert/decompile",
    Verbose           = true,
    SkipPrepass       = false,
    SkipSaveInstance  = false,
    UssiRepoURL       = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/",
    UssiScript        = "SILuau",
}

ussiprepass(Options, PrepassOptions)