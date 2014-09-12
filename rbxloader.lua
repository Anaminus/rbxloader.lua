--[[
rbxloader.lua

Downloads ROBLOX builds using a command-line interface.

Arguments:

1. The directory to download to. Defaults to the current directory.
2. The domain to download from. Defaults to `roblox.com`.
3. The build type to download.
	- If `studio`, then the latest studio version is downloaded.
	- If `player`, then the latest player version is downloaded. This is
	  the default.
	- A specific version hash may be given instead. This takes the form of
	  `version-<hash>`, where `<hash>` is a series of hexadecimal digits.

Examples:

	lua rbxloader.lua
	lua rbxloader.lua . roblox.com player
	lua rbxloader.lua %temp%/roblox/gt5/ gametest1.robloxlabs.com studio
	lua rbxloader.lua C:/roblox/gt5/ gametest5.robloxlabs.com version-1a2b3c4d5e6f7890

Dependencies:

- LuaSocket
- LuaFileSystem
- LuaZip

More Info:

	https://github.com/Anaminus/rbxloader.lua

]]

local http = require 'socket.http'
local lfs = require 'lfs'
local zip = require 'zip'

-- combines strings, separated by forward slashes.
local function path(...)
	local a = {...}
	local p = a[1] or ''
	for i = 2,#a do
		p = p .. '/' .. a[i]
	end
	return p:gsub('[\\/]+','/')
end

-- Open a file after creating any necessary directories.
local function dopen(name,...)
	local f = io.open(name,...)
	if f then
		return f
	end

	local function d(s)
		s = s:match('^(.+)/')
		if s then
			d(s)
			lfs.mkdir(s)
		end
	end
	d(name)

	return io.open(name,...)
end

-- Unzip the contents of a zip file into a directory.
local function unzip(zipfilename,dir)
	local zipfile = zip.open(zipfilename)
	if zipfile then
		for data in zipfile:files() do
			local filename = data.filename
			if filename:sub(-1,-1) ~= '/' then
				local zfile = assert(zipfile:open(filename))
				local file = assert(dopen(path(dir,filename),'wb'))
				file:write(zfile:read('*a'))
				file:flush()
				file:close()
				zfile:close()
			end
		end
		zipfile:close()
	end
end

local globalZip = {
	-- zip name            download location
	{"RobloxApp"         , [[]]};
	{"RobloxStudio"      , [[]]};
	{"RobloxProxy"       , [[]]};
	{"NPRobloxProxy"     , [[]]};
	{"Libraries"         , [[]]};
	{"redist"            , [[]]};
	{"shaders"           , [[shaders]]};
	{"content-music"     , [[content/music]]};
	{"content-sky"       , [[content/sky]]};
	{"content-sounds"    , [[content/sounds]]};
	{"content-scripts"   , [[content/scripts]]};
	{"content-fonts"     , [[content/fonts]]};
	{"content-particles" , [[content/particles]]};
	{"content-textures"  , [[content/textures]]};
	{"content-textures2" , [[content/textures]]};
	{"content-textures3" , [[PlatformContent/pc/textures]]};
	{"BuiltInPlugins"    , [[BuiltInPlugins]]};
	{"imageformats"      , [[imageformats]]};
}

local function downloadVersion(version,domain,dir)
	for i = 1,#globalZip do
		local url = 'http://setup.' .. path(domain,version .. '-' .. globalZip[i][1] .. '.zip')
		local zipData = assert(http.request(url))
		local f = assert(io.open('temp','wb'))
		f:write(zipData)
		f:flush()
		f:close()
		unzip('temp',path(dir or '.',globalZip[i][2]))
	end
	os.remove('temp')

	-- AppSettings
	local f = assert(io.open(path(dir,'AppSettings.xml'),'w'))
	f:write([[<?xml version="1.0" encoding="UTF-8"?>
	<Settings>
		<ContentFolder>content</ContentFolder>
		<BaseUrl>http://www.]] .. domain .. [[</BaseUrl>
	</Settings>
	]])
	f:flush()
	f:close()
end

local domain = arg[2] or 'roblox.com'

local versionHash do
	if not arg[3] or arg[3]:lower() == 'player' then
		print("Getting latest Player version...")
		versionHash = http.request('http://setup.' .. path(domain,'version'))
	elseif arg[3]:lower() == 'studio' then
		print("Getting latest Studio version...")
		versionHash = http.request('http://setup.' .. path(domain,'versionQTStudio'))
	elseif arg[3]:match('^version%-%x+$') then
		versionHash = arg[3]
	end
	if not versionHash then
		error("Unknown version",0)
	end
end

local directory = path(arg[1] or '.',versionHash)

print("Downloading files...")
local stamp = os.clock()
downloadVersion(
	versionHash,
	domain,
	directory
)

print("Download finished (took " .. os.clock()-stamp .. " seconds). Files are located at")
print(directory)
