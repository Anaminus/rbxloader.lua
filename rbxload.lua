--[[
rbxload.lua

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

	lua rbxload.lua
	lua rbxload.lua . roblox.com player
	lua rbxload.lua %temp%/roblox/gt5/ gametest1.robloxlabs.com studio
	lua rbxload.lua C:/roblox/gt5/ gametest5.robloxlabs.com version-1a2b3c4d5e6f7890

Dependencies:

- LuaSocket
- LuaFileSystem
- LuaZip

More Info:

	https://github.com/Anaminus/rbxload.lua

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

-- Open a file while creating any necessary directories.
local function dopen(name,...)
	local dir = ''
	name = path(name)
	for folder in name:gmatch("[^/]") do
		local f,m = io.open(name,'w')
		if f then
			f:close()
			return io.open(name,...)
		elseif m:match('No such file or directory') then
			dir = path(dir,folder)
			lfs.mkdir(dir)
		else
			return nil,m
		end
	end
	return nil,'Could not open file'
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
	{"shaders"           , [[shaders/]]};
	{"content-music"     , [[content/music/]]};
	{"content-sky"       , [[content/sky/]]};
	{"content-sounds"    , [[content/sounds/]]};
	{"content-fonts"     , [[content/fonts/]]};
	{"content-particles" , [[content/particles/]]};
	{"content-textures"  , [[content/textures/]]};
	{"content-textures2" , [[content/textures/]]};
	{"content-textures3" , [[PlatformContent/pc/textures/]]};
	{"BuiltInPlugins"    , [[BuiltInPlugins/]]};
	{"imageformats"      , [[imageformats/]]};
}

local function downloadVersion(version,domain,dir)
	for i = 1,#globalZip do
		local url = "http://setup." .. path(domain,version) .. '-' .. globalZip[i][1] .. '.zip'
		local zipData = assert(http.request(url))
		local f = assert(io.open('temp','wb'))
		f:write(zipData)
		f:flush()
		f:close()
		unzip('temp',path(dir or '',globalZip[i][2]))
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

local versionHash do
	if not arg[3] or arg[3]:lower() == 'player' then
		print("Getting latest Player version...")
		versionHash = http.request('http://setup.' .. path(base,'version'))
	elseif arg[3]:lower() == 'studio' then
		print("Getting latest Studio version...")
		versionHash = http.request('http://setup.' .. path(base,'versionQTStudio'))
	elseif arg[3]:match('^version%-%x+$') then
		versionHash = arg[3]
	else
		error("Unknown build type",0)
	end
end

local directory = path(arg[1] or '',version)

print("Downloading files...")
downloadVersion(
	versionHash,
	arg[2] or 'roblox.com',
	directory
)

print("Download finished. Files are located at")
print(directory)
