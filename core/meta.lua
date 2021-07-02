local metadata = (...)

if not metadata.mod then
	return
end

local title = metadata.mod

if metadata.version then
	title = title .. ' v' .. metadata.version
end

local function raiseError(msg)
	print('[' .. metadata.mod .. '] ' .. msg)
	error(msg, 2)
end

local function parseSemVer(version)
	return tonumber((tostring(version):gsub('^v?(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip)
		return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
	end))) or 0
end

local function requireFramework(requiredVerSpec)
	local currentVerSpec = GetVersion():gsub('^v', '')
	local currentVer = parseSemVer(currentVerSpec)
	local requiredVer = parseSemVer(requiredVerSpec)

	if currentVer < requiredVer then
		raiseError(('Cyber Engine Tweaks v%s required (v%s detected)'):format(requiredVerSpec, currentVerSpec))
	end
end

if metadata.framework then
	requireFramework(metadata.framework)
end
