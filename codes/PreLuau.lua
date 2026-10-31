local ussiprepass = loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/SIPrePass.luau", true))()

local Options = {
    mode = "full",
    SafeMode = true,
    ReadMe = false,
    SaveBytecode = true,
    DecompileTimeout = -1,
    BytecodeTimeout = -1,
    DecompileIgnore = {},
    IsolateLocalPlayer = true,
    SavePlayerCharacters = true,
    NilInstances = true,
    IgnoreList = {},
    RiskyServicesDisabled = {},
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