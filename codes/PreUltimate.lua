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
} -- USI options, docs: https://github.com/RiseBlox/UltimateSaveInstance/wiki/Options-reference

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
    UssiScript        = "SIUltimate",
}

ussiprepass(Options, PrepassOptions)