assert(getscriptbytecode, "executor does not support getscriptbytecode")

local HttpRequest = request or http_request
assert(HttpRequest, "executor does not support an http request function")

local cloneref = cloneref or function(o) return o end

local game = cloneref(game)
local workspace = cloneref(workspace)

local HttpService = cloneref(game:GetService("HttpService"))
local RunService = cloneref(game:GetService("RunService"))

local CoreContainers = {}
for _, ServiceName in next, { "CoreGui", "CorePackages", "RobloxReplicatedStorage", "RobloxLocalReplicatedStorage" } do
    local Ok, Service = pcall(game.GetService, game, ServiceName)
    if Ok and Service then
        CoreContainers[#CoreContainers + 1] = cloneref(Service)
    end
end

local function IsCoreInstance(o)
    for _, Container in next, CoreContainers do
        local Ok, Res = pcall(function() return o == Container or o:IsDescendantOf(Container) end)
        if Ok and Res then return true end
    end
    local OkLocked, Locked = pcall(function() return o.RobloxLocked end)
    if OkLocked and Locked then return true end
    return false
end

local Config = {
    -- The v2 endpoint documents a limit of 500 requests per minute.
    RequestsPerMinute = 480,
    MaxInFlight = 30,
    RequestTimeout = 20,
    ApiUrl  = "https://api.lua.expert/v1/decompile",
    DecompilerOptions = nil, -- Optional v2 options, merged by the server.
    IgnoreCache = false,
    CacheFolder = "ussiprepass_cache",
    CacheExpirySeconds = 7 * 24 * 60 * 60,
    Verbose = true,
}

local DefaultConfig = {}
for k, v in next, Config do
    DefaultConfig[k] = v
end

local function Base64Encode(Data)
    if base64_encode then return base64_encode(Data) end
    local B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return ((Data:gsub(".", function(x)
        local R, Byte = "", x:byte()
        for i = 8, 1, -1 do
            R = R .. (Byte % 2 ^ i - Byte % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return R
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local C = 0
        for i = 1, 6 do
            C = C + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
        end
        return B:sub(C + 1, C + 1)
    end) .. ({ "", "==", "=" })[#Data % 3 + 1])
end

local WriteFile  = writefile  or write_file
local ReadFile   = readfile   or read_file
local DeleteFile = delfile    or del_file or remove_file
local MakeFolder = makefolder or make_folder

local TWO32 = 4294967296
local FnvPrimeA = 16777619
local FnvPrimeB = 16777259
local BitXor    = bit32 and bit32.bxor

local function Xor32(A, B)
    if BitXor then
        return BitXor(A, B)
    end
    return (A + B) % TWO32
end

local function Mul32(A, B)
    local AL, AH = A % 65536, math.floor(A / 65536)
    local BL, BH = B % 65536, math.floor(B / 65536)
    return (AL * BL + ((AH * BL + AL * BH) % 65536) * 65536) % TWO32
end

-- Two independent FNV-1a accumulators give a 64-bit key from one pass.
local function HashPairBytes(Data)
    local A, B = 2166136261, 84696351
    local Byte = string.byte
    local N = #Data
    local i = 1

    while i + 7 <= N do
        local b1, b2, b3, b4, b5, b6, b7, b8 = Byte(Data, i, i + 7)
        A = Mul32(Xor32(A, b1), FnvPrimeA)
        B = Mul32(Xor32(B, b1), FnvPrimeB)
        A = Mul32(Xor32(A, b2), FnvPrimeA)
        B = Mul32(Xor32(B, b2), FnvPrimeB)
        A = Mul32(Xor32(A, b3), FnvPrimeA)
        B = Mul32(Xor32(B, b3), FnvPrimeB)
        A = Mul32(Xor32(A, b4), FnvPrimeA)
        B = Mul32(Xor32(B, b4), FnvPrimeB)
        A = Mul32(Xor32(A, b5), FnvPrimeA)
        B = Mul32(Xor32(B, b5), FnvPrimeB)
        A = Mul32(Xor32(A, b6), FnvPrimeA)
        B = Mul32(Xor32(B, b6), FnvPrimeB)
        A = Mul32(Xor32(A, b7), FnvPrimeA)
        B = Mul32(Xor32(B, b7), FnvPrimeB)
        A = Mul32(Xor32(A, b8), FnvPrimeA)
        B = Mul32(Xor32(B, b8), FnvPrimeB)
        i += 8
    end

    while i <= N do
        local b = Byte(Data, i)
        A = Mul32(Xor32(A, b), FnvPrimeA)
        B = Mul32(Xor32(B, b), FnvPrimeB)
        i += 1
    end

    return A, B
end

-- buffer.readu32 folds four bytes per call, which removes most of the
-- per-byte interpreter overhead of the string.byte path.
local BufferLib = buffer
local UseBufferHash = type(BufferLib) == "table"
    and type(BufferLib.fromstring) == "function"
    and type(BufferLib.len) == "function"
    and type(BufferLib.readu32) == "function"
    and type(BufferLib.readu8) == "function"

local function HashPairWords(Data)
    local Buf = BufferLib.fromstring(Data)
    local N = BufferLib.len(Buf)
    local A, B = 2166136261, 84696351
    local i = 0

    while i + 15 < N do
        local w1 = BufferLib.readu32(Buf, i)
        local w2 = BufferLib.readu32(Buf, i + 4)
        local w3 = BufferLib.readu32(Buf, i + 8)
        local w4 = BufferLib.readu32(Buf, i + 12)
        A = Mul32(Xor32(A, w1), FnvPrimeA)
        B = Mul32(Xor32(B, w1), FnvPrimeB)
        A = Mul32(Xor32(A, w2), FnvPrimeA)
        B = Mul32(Xor32(B, w2), FnvPrimeB)
        A = Mul32(Xor32(A, w3), FnvPrimeA)
        B = Mul32(Xor32(B, w3), FnvPrimeB)
        A = Mul32(Xor32(A, w4), FnvPrimeA)
        B = Mul32(Xor32(B, w4), FnvPrimeB)
        i += 16
    end

    while i + 3 < N do
        local w = BufferLib.readu32(Buf, i)
        A = Mul32(Xor32(A, w), FnvPrimeA)
        B = Mul32(Xor32(B, w), FnvPrimeB)
        i += 4
    end

    while i < N do
        local b = BufferLib.readu8(Buf, i)
        A = Mul32(Xor32(A, b), FnvPrimeA)
        B = Mul32(Xor32(B, b), FnvPrimeB)
        i += 1
    end

    return A, B
end

local HashPair = HashPairBytes
if UseBufferHash then
    HashPair = HashPairWords
end

local function HashString(Data)
    local A, B = HashPair(Data)
    return ("%08x%08x"):format(A, B)
end

local function CanonicalValue(Value)
    local Kind = type(Value)
    if Kind == "string" or Kind == "number" or Kind == "boolean" then
        return Kind .. ":" .. tostring(Value)
    end
    local Ok, Encoded = pcall(HttpService.JSONEncode, HttpService, Value)
    return Kind .. ":" .. (Ok and tostring(Encoded) or "?")
end

-- Sorted key list makes the signature stable across runs.
local function OptionsSignature(Options)
    if type(Options) ~= "table" then
        return "defaults"
    end
    local Keys = {}
    for Key in next, Options do
        if type(Key) == "string" then
            Keys[#Keys + 1] = Key
        end
    end
    if #Keys == 0 then
        return "defaults"
    end
    table.sort(Keys)
    local Parts = {}
    for i = 1, #Keys do
        local Key = Keys[i]
        Parts[i] = Key .. "=" .. CanonicalValue(Options[Key])
    end
    return table.concat(Parts, "\1")
end

local FileCacheState
local FileCacheFolder
local FileCacheWarned = false

local function FileCacheReady()
    if FileCacheState == nil then
        FileCacheState = WriteFile ~= nil and ReadFile ~= nil
    end
    if not FileCacheState then
        return false
    end
    if FileCacheFolder ~= Config.CacheFolder then
        if MakeFolder then
            pcall(MakeFolder, Config.CacheFolder) -- Fails when the folder already exists.
        end
        FileCacheFolder = Config.CacheFolder
    end
    return true
end

local function CachePath(Key)
    return Config.CacheFolder .. "/" .. Key .. ".json"
end

-- A 200 response can still carry an empty body or a proxy error page.
local function IsUsableSource(Body)
    if type(Body) ~= "string" then
        return false
    end
    if not Body:find("%S") then
        return false
    end
    if Body:match("^%s*<") then
        return false
    end
    return true
end

local function ReadCacheEntry(Key)
    if not FileCacheReady() then
        return nil
    end
    local Path = CachePath(Key)
    local Ok, Raw = pcall(ReadFile, Path)
    if not Ok or type(Raw) ~= "string" or Raw == "" then
        return nil
    end

    local Decoded, Entry = pcall(HttpService.JSONDecode, HttpService, Raw)
    local Created = Decoded and type(Entry) == "table" and tonumber(Entry.created)
    local Source = type(Entry) == "table" and Entry.source
    if not Created or not IsUsableSource(Source) then
        if DeleteFile then pcall(DeleteFile, Path) end
        return nil
    end
    if os.time() - Created >= Config.CacheExpirySeconds then
        if DeleteFile then pcall(DeleteFile, Path) end
        return nil
    end
    return Source
end

local function WriteCacheEntry(Key, Source)
    if not FileCacheReady() then
        return
    end
    local Ok, Payload = pcall(HttpService.JSONEncode, HttpService, { created = os.time(), source = Source })
    if not Ok then
        return
    end
    local Written, WriteError = pcall(WriteFile, CachePath(Key), Payload)
    if not Written and not FileCacheWarned and Config.Verbose then
        FileCacheWarned = true
        warn("[prepass] cannot write the cache: " .. tostring(WriteError))
    end
end

local MemoryCache = {}
local KeyByBytecode = {}

local function CacheKey(Bytecode)
    local OptionsKey = HashString(OptionsSignature(Config.DecompilerOptions))
    return HashString(Bytecode) .. "-" .. OptionsKey:sub(1, 8)
end

-- The prepass and the decompile hook both key the same bytecode. Reuse the
-- computed key so each unique script is hashed once per session.
local function CacheKeyFor(Bytecode)
    local Key = KeyByBytecode[Bytecode]
    if not Key then
        Key = CacheKey(Bytecode)
        KeyByBytecode[Bytecode] = Key
    end
    return Key
end

local function LookupCached(Key)
    local Hit = MemoryCache[Key]
    if Hit then
        return Hit
    end
    if Config.IgnoreCache then
        return nil
    end
    Hit = ReadCacheEntry(Key)
    if Hit then
        MemoryCache[Key] = Hit
    end
    return Hit
end

local function StoreCached(Key, Source)
    MemoryCache[Key] = Source
    WriteCacheEntry(Key, Source)
end

-- os.clock() is a monotonic wall clock in Luau (QueryPerformanceCounter,
-- mach_absolute_time, CLOCK_MONOTONIC), despite the docs calling it CPU time.
local NextSlot = 0

local function AcquireRateSlot()
    local MinGap = 60 / Config.RequestsPerMinute
    local Now = os.clock()
    local MySlot = NextSlot > Now and NextSlot or Now
    NextSlot = MySlot + MinGap
    local Delay = MySlot - Now
    if Delay > 0 then
        task.wait(Delay)
    end
end

local function DecompileViaAPI(Bytecode)
    local EncodedOk, EncodedScript = pcall(Base64Encode, Bytecode)
    if not EncodedOk then
        return false, tostring(EncodedScript)
    end

    local RequestBody = { script = EncodedScript }
    if type(Config.DecompilerOptions) == "table" and next(Config.DecompilerOptions) then
        RequestBody.decompilerOptions = Config.DecompilerOptions
    end

    local BodyOk, Body = pcall(HttpService.JSONEncode, HttpService, RequestBody)
    if not BodyOk then
        return false, tostring(Body)
    end

    -- Take the slot after encoding, so the request leaves on the slot time.
    AcquireRateSlot()

    local Settled, Result = false, nil
    task.spawn(function()
        local Ok, Res = pcall(HttpRequest, {
            Url = Config.ApiUrl,
            Method = "POST",
            Headers = { ["content-type"] = "application/json" },
            Body = Body,
        })
        if not Settled then
            Settled = true
            Result = { Ok = Ok, Res = Res }
        end
    end)

    local Deadline = os.clock() + Config.RequestTimeout
    while not Settled and os.clock() < Deadline do
        task.wait(0.05)
    end

    if not Settled then
        Settled = true
        return false, "timeout"
    end

    if not Result.Ok then
        return false, tostring(Result.Res)
    end
    local Response = Result.Res
    if type(Response) ~= "table" or Response.StatusCode ~= 200 then
        local Detail = type(Response) == "table" and Response.Body or Response
        return false, tostring(Detail)
    end
    if not IsUsableSource(Response.Body) then
        return false, "unusable response body"
    end
    return true, Response.Body
end

local function RunPool(Items, Worker)
    local Total = #Items
    if Total == 0 then return end
    local NextIndex, Done = 1, 0

    -- A cached item never yields, so chaining task.spawn from one item to the
    -- next nests C calls per item and overflows the C stack. Loop instead.
    local function RunWorker()
        while true do
            local i = NextIndex
            if i > Total then return end
            NextIndex = i + 1

            local Ok, Err = pcall(Worker, Items[i])
            if not Ok and Config.Verbose then
                warn(("[prepass] worker error: %s"):format(tostring(Err)))
            end
            Done += 1
        end
    end

    for _ = 1, math.max(1, math.min(Config.MaxInFlight, Total)) do
        task.spawn(RunWorker)
    end
    while Done < Total do
        task.wait()
    end
end

local function ResolveName(o)
    local Ok, Name = pcall(function() return o:GetFullName() end)
    if Ok and type(Name) == "string" and Name ~= "" then
        return Name
    end
    local Ok2, Short = pcall(function() return o.Name end)
    return (Ok2 and Short) or "<unknown>"
end

local function GatherUniqueScripts()
    local Objs = {}
    for _, o in next, game:GetDescendants() do
        if o:IsA("LuaSourceContainer") and not IsCoreInstance(o) then
            local IsServer = o:IsA("Script") and (o.RunContext == Enum.RunContext.Legacy or o.RunContext == Enum.RunContext.Server)
            if not IsServer then
                Objs[#Objs + 1] = cloneref(o)
            end
        end
    end

    if getloadedmodules then
        local OkM, Mods = pcall(getloadedmodules)
        if OkM and type(Mods) == "table" then
            for _, m in next, Mods do
                if not IsCoreInstance(m) then
                    Objs[#Objs + 1] = cloneref(m)
                end
            end
        end
    end

    local Seen, Unique = {}, {}
    for _, o in next, Objs do
        local Ok, Bc = pcall(getscriptbytecode, o)
        if Ok and type(Bc) == "string" and Bc ~= "" and not Seen[Bc] then
            Seen[Bc] = true
            Unique[#Unique + 1] = { Bytecode = Bc, Name = ResolveName(o) }
        end
    end
    return Unique
end

local NoOpUi = { Update = function() end, Destroy = function() end }

local function CreateProgressUI(Total)
    if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then
        return NoOpUi
    end

    local State = { Done = 0, Dispatched = 0, Name = "" }
    local Objects = {}
    local Connection

    local Ok = pcall(function()
        local Camera = workspace.CurrentCamera and cloneref(workspace.CurrentCamera)
        local Viewport = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
        local BarWidth, BarHeight = 420, 14
        local BarX = math.floor((Viewport.X - BarWidth) / 2)
        local BarY = 24

        local function Square(Color, Filled, Thickness)
            local S = Drawing.new("Square")
            S.Color = Color
            S.Filled = Filled
            S.Thickness = Thickness or 1
            S.Visible = true
            Objects[#Objects + 1] = S
            return S
        end

        local Bg = Square(Color3.fromRGB(20, 20, 20), true)
        Bg.Size = Vector2.new(BarWidth, BarHeight)
        Bg.Position = Vector2.new(BarX, BarY)
        Bg.Transparency = 0.85

        local DispatchedFill = Square(Color3.fromRGB(200, 160, 60), true)
        DispatchedFill.Size = Vector2.new(0, BarHeight)
        DispatchedFill.Position = Vector2.new(BarX, BarY)
        DispatchedFill.Transparency = 0.55

        local CompletedFill = Square(Color3.fromRGB(80, 180, 90), true)
        CompletedFill.Size = Vector2.new(0, BarHeight)
        CompletedFill.Position = Vector2.new(BarX, BarY)

        local Border = Square(Color3.fromRGB(220, 220, 220), false, 1)
        Border.Size = Vector2.new(BarWidth, BarHeight)
        Border.Position = Vector2.new(BarX, BarY)

        local function Text(Size, Color)
            local T = Drawing.new("Text")
            T.Size = Size
            T.Color = Color
            T.Center = true
            T.Outline = true
            T.Visible = true
            T.Text = ""
            Objects[#Objects + 1] = T
            return T
        end

        local Progress = Text(14, Color3.fromRGB(255, 255, 255))
        Progress.Position = Vector2.new(Viewport.X / 2, BarY + BarHeight + 4)
        Progress.Text = ("0 / %d"):format(Total)

        local Name = Text(13, Color3.fromRGB(200, 200, 200))
        Name.Position = Vector2.new(Viewport.X / 2, BarY + BarHeight + 22)

        Connection = RunService.RenderStepped:Connect(function()
            CompletedFill.Size = Vector2.new(BarWidth * (State.Done / Total), BarHeight)
            DispatchedFill.Size = Vector2.new(BarWidth * (State.Dispatched / Total), BarHeight)
            Progress.Text = ("%d / %d"):format(State.Done, Total)
            local Display = State.Name
            if #Display > 80 then
                Display = "..." .. Display:sub(-77)
            end
            Name.Text = Display
        end)
    end)

    if not Ok then
        if Connection then pcall(function() Connection:Disconnect() end) end
        for _, d in next, Objects do
            pcall(function() d:Remove() end)
        end
        return NoOpUi
    end

    return {
        Update = function(_, Done, Dispatched, ScriptName)
            State.Done = Done
            State.Dispatched = Dispatched
            if ScriptName then State.Name = ScriptName end
        end,
        Destroy = function()
            if Connection then pcall(function() Connection:Disconnect() end) end
            for _, d in next, Objects do
                pcall(function() d:Remove() end)
            end
        end,
    }
end

local function Prepass()
    local Unique = GatherUniqueScripts()
    -- Start the largest requests first so the last dispatch is not the slowest.
    table.sort(Unique, function(a, b) return #a.Bytecode > #b.Bytecode end)
    local Total = #Unique
    if Config.Verbose then
        print(("[prepass] %d unique scripts"):format(Total))
    end
    if Total == 0 then return end

    local Ui = CreateProgressUI(Total)
    local Cached, Fetched, Failed, Completed, Dispatched = 0, 0, 0, 0, 0

    RunPool(Unique, function(Item)
        Dispatched += 1
        Ui:Update(Completed, Dispatched, Item.Name)

        local Key = CacheKeyFor(Item.Bytecode)
        if LookupCached(Key) then
            Cached += 1
        else
            local Ok, Body = DecompileViaAPI(Item.Bytecode)
            if Ok then
                StoreCached(Key, Body)
                Fetched += 1
            else
                Failed += 1
                if Config.Verbose then
                    warn(("[prepass] decompile failed for %s: %s"):format(Item.Name, tostring(Body)))
                end
            end
        end

        Completed += 1
        Ui:Update(Completed, Dispatched, Item.Name)
    end)

    Ui:Destroy()

    if Config.Verbose then
        print(("[prepass] %d scripts: %d from cache, %d fetched, %d failed"):format(
            Total, Cached, Fetched, Failed))
    end
end

local HookInstalled = false
local function InstallDecompileHook()
    if HookInstalled then return end
    HookInstalled = true

    local OldDecompile = getgenv().decompile
    getgenv().decompile = function(Scr)
        local Ok, Bc = pcall(getscriptbytecode, Scr)
        if Ok and type(Bc) == "string" and Bc ~= "" then
            local Key = CacheKeyFor(Bc)
            local Hit = LookupCached(Key)
            if Hit then
                return Hit
            end

            if OldDecompile then
                return OldDecompile(Scr)
            end

            local Good, Body = DecompileViaAPI(Bc)
            if Good then
                StoreCached(Key, Body)
                return Body
            end
            local Reason = tostring(Body):gsub("%s+", " "):sub(1, 200)
            return "-- decompile failed: " .. Reason
        end

        if OldDecompile then
            return OldDecompile(Scr)
        end
        return "-- could not read script bytecode"
    end
end

return function(Options, PrepassOptions)
    PrepassOptions = PrepassOptions or {}
    local Fresh = {}
    for k, v in next, DefaultConfig do
        Fresh[k] = v
    end
    for k, v in next, PrepassOptions do
        Fresh[k] = v
    end
    Config = Fresh

    -- Keys depend on DecompilerOptions, so drop keys from an earlier call.
    KeyByBytecode = {}

    InstallDecompileHook()

    if not PrepassOptions.SkipPrepass then
        Prepass()
    end

    if PrepassOptions.SkipSaveInstance then
        return
    end

    local RepoURL = PrepassOptions.UssiRepoURL or "https://raw.githubusercontent.com/rbxlx/UniversalSynSaveInstance/main/"
    local ScriptName = PrepassOptions.UssiScript or "saveinstance"
    local synsaveinstance = loadstring(game:HttpGet(RepoURL .. ScriptName .. ".luau", true), ScriptName)()

    return synsaveinstance(Options or {})
end