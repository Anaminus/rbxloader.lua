# rbxload.lua

Downloads ROBLOX builds using a command-line interface.

## Arguments

rbxload.lua accepts the following arguments:

1. The directory to download to. Defaults to the current directory.
2. The domain to download from. Defaults to `roblox.com`.
3. The build type to download.
	- If `studio`, then the latest studio version is downloaded.
	- If `player`, then the latest player version is downloaded. This is
	  the default.
	- A specific version hash may be given instead. This takes the form of
	  `version-<hash>`, where `<hash>` is a series of hexadecimal digits.

## Examples

```
lua rbxload.lua
lua rbxload.lua . roblox.com player
lua rbxload.lua %temp%/roblox/gt5/ gametest1.robloxlabs.com studio
lua rbxload.lua C:/roblox/gt5/ gametest5.robloxlabs.com version-1a2b3c4d5e6f7890
```

## Dependencies

- [LuaFileSystem][lfs]
- [LuaSocket][lsocket]
- [LuaZip][lzip]

[lfs]: http://keplerproject.github.io/luafilesystem/
[lsocket]: http://w3.impa.br/%7Ediego/software/luasocket/
[lzip]: http://www.keplerproject.org/luazip/
