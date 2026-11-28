local ussiprepass = loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/SIPrePass.luau", true))()

local Options = {
    mode = "optimized",
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
} -- USSI options, docs: https://phoriah.codeberg.page/UniversalSynSaveInstance/api/UniversalSynSaveInstance

local PrepassOptions = {
    RequestsPerMinute  = 495, -- the lua.expert v2 limit is 500 requests per minute
    MaxInFlight        = 30,
    ApiUrl             = "https://api.lua.expert/v1/decompile",
    DecompilerOptions  = nil, -- lua.expert v2 options, see https://blog.lua.expert/posts/v2/
    IgnoreCache        = true, -- ignore saved results, but still save new ones
    CacheFolder        = "ussiprepass_cache",
    CacheExpirySeconds = 7 * 24 * 60 * 60,
    Verbose            = true,
    SkipPrepass        = false, -- skip cache warm-up, go straight to USSI
    SkipSaveInstance   = false, -- run only the prepass, don't call USSI
    UssiRepoURL       = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/codes/",
    UssiScript        = "SILuau",
}

ussiprepass(Options, PrepassOptions)