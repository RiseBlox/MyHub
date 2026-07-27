local T = workspace:FindFirstChildOfClass("Terrain")
if not T then return warn("TerrainSaveInstance: No Terrain found") end
if not (gethiddenproperty and writefile) then return warn("TerrainSaveInstance: Missing gethiddenproperty or writefile") end

-- 1. Hidden voxel grids
local ok1, smooth = pcall(gethiddenproperty, T, "SmoothGrid")
local ok2, physics = pcall(gethiddenproperty, T, "PhysicsGrid")
if not (ok1 and ok2) then return warn("TerrainSaveInstance: Failed to read terrain grids") end

-- 2. Compact base64 fallback
local b64 = base64encode or function(d)
	local a = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	local r = {}
	for i = 1, #d, 3 do
		local x, y, z = d:byte(i, i + 2)
		local n = x * 65536 + (y or 0) * 256 + (z or 0)
		r[#r+1] = a:sub(math.floor(n/262144)%64+1, math.floor(n/262144)%64+1)
		r[#r+1] = a:sub(math.floor(n/4096)%64+1, math.floor(n/4096)%64+1)
		r[#r+1] = y and a:sub(math.floor(n/64)%64+1, math.floor(n/64)%64+1) or '='
		r[#r+1] = z and a:sub(n%64+1, n%64+1) or '='
	end
	return table.concat(r)
end

-- 3. MaterialColors blob (21 materials × 3 RGB + 6 header bytes)
local mats = {"Grass","Slate","Concrete","Brick","Sand","WoodPlanks","Rock","Glacier","Snow","Sandstone","Mud","Basalt","Ground","CrackedLava","Asphalt","Cobblestone","Ice","LeafyGrass","Salt","Limestone","Pavement"}
local c = {string.rep("\0", 6)}
for _, m in mats do
	local col = T:GetMaterialColor(Enum.Material[m])
	c[#c+1] = string.char(math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255))
end
local matColors = table.concat(c)

-- 4. Safe property reader (direct → gethiddenproperty fallback)
local function get(name)
	local ok, v = pcall(function() return T[name] end)
	if not ok and gethiddenproperty then ok, v = pcall(gethiddenproperty, T, name) end
	return ok and v or nil
end

-- 5. Gather every terrain property we care about
local props = {}
local function add(name, typeName)
	local v = get(name)
	if v ~= nil then props[#props+1] = {n=name, t=typeName, v=v} end
end

add("Decoration",       "bool")
add("IsSmooth",         "bool")
add("WaterColor",       "Color3")
add("WaterReflectance", "float")
add("WaterTransparency","float")
add("WaterWaveSize",    "float")
add("WaterWaveSpeed",   "float")
add("GrassLength",      "float")
add("AcquisitionMethod","string")
add("Anchored",         "bool")
add("CanCollide",       "bool")
add("Locked",           "bool")
add("CastShadow",       "bool")

-- 6. MaterialService 2022 toggle
local use2022 = false
pcall(function() use2022 = game:GetService("MaterialService").Use2022Materials end)

-- 7. Anti-overwrite file name
local id = game.PlaceId
local name = "Unknown"
pcall(function() name = game:GetService("MarketplaceService"):GetProductInfo(id).Name end)
name = name:gsub("[^%w _%-]", ""):gsub("%s+", " "):gsub("%s+$", ""):sub(1, 120)
local base = string.format("place %d %s [Terrain Only]", id, name)

local isfile = isfile or function() return false end
local file = base .. ".rbxlx"
local n = 1
while isfile(file) do file = string.format("%s (%d).rbxlx", base, n) n = n + 1 end

-- 8. XML helpers
local function bin(n, d) return string.format('<BinaryString name="%s"><![CDATA[%s]]></BinaryString>', n, d == "" and "" or b64(d)) end
local function tag(p)
	if p.t == "bool"   then return string.format('<bool name="%s">%s</bool>', p.n, p.v and "true" or "false") end
	if p.t == "float"  then return string.format('<float name="%s">%s</float>', p.n, tostring(p.v)) end
	if p.t == "Color3" then return string.format('<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>', p.n, p.v.R, p.v.G, p.v.B) end
	if p.t == "string" then return string.format('<string name="%s">%s</string>', p.n, tostring(p.v)) end
	return ""
end

-- 9. Assemble XML
local x = {
	'<roblox version="4">',
	'  <Item class="Workspace" referent="RBX0"><Properties><string name="Name">Workspace</string></Properties>',
	'    <Item class="Terrain" referent="RBX1"><Properties>',
	'      <string name="Name">Terrain</string>',
	'      ' .. bin("SmoothGrid", smooth),
	'      ' .. bin("PhysicsGrid", physics),
	'      ' .. bin("MaterialColors", matColors),
}
for _, p in props do x[#x+1] = '      ' .. tag(p) end
x[#x+1] = '    </Properties></Item>'
x[#x+1] = '  </Item>'
x[#x+1] = '  <Item class="MaterialService" referent="RBX2"><Properties>'
x[#x+1] = '    <string name="Name">MaterialService</string>'
x[#x+1] = '    <bool name="Use2022MaterialsXml">' .. (use2022 and "true" or "false") .. '</bool>'
x[#x+1] = '  </Properties></Item>'
x[#x+1] = '</roblox>'

writefile(file, table.concat(x, "\n"))
print(string.format("TerrainSaveInstance: Saved '%s' (%s bytes)", file, #table.concat(x, "\n")))