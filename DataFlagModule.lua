--[[
  MIT License

  Copyright (c) 2020 Saldor010

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]--

-- Change this datastore to something unique to your game preferably
local dataStore = game:GetService("DataStoreService"):GetDataStore("dataFlags")

local httpService = game:GetService("HttpService")
local module = {}
local writeCache = {}
local readCache = {}

local function styledWarn(t)
	warn("["..script.Parent.Name.."] "..t)
end

local function pushCache()
	for userId,data in pairs(writeCache) do
		-- Wrap the datastore request into a protected call
		local success, err = pcall(function()
			dataStore:UpdateAsync(userId,function(cookedData)
				if cookedData == nil then
					-- Initalize a new JSON datastructure for the player
					return httpService:JSONEncode(data)
				else
					-- Edit the pre-existing datastructure
					local rawData = httpService:JSONDecode(cookedData)
					for flag,value in pairs(data) do
						rawData[flag] = value
					end
					return httpService:JSONEncode(rawData)
				end
			end)
		end)
		
		-- If there was an error, warn the dev console.
		if err then
			styledWarn("Datastore error encountered: "..err)
		end
	end
	
	writeCache = {}
end

local function getFlagsFromDataStoreForUserId(userId)
	-- Wrap the datastore request into a protected call
	local rawData
	local success,err = pcall(function()
		--[[
			Grab the "cooked" JSON data from the datastore and turn it into
			a "raw" Lua table
		]]--
		local cookedData = dataStore:GetAsync(userId)
		if cookedData == nil then
			-- If the datastore has no registry for the player, return nil
			return nil
		end
		rawData = httpService:JSONDecode(cookedData)
	end)
	
	-- If there was an error, warn the dev console.
	if err then
		styledWarn("Datastore error encountered: "..err)
	end
	if success then
		--[[
			Our method contract specifies that a successful return value must
			be a table, so if the player has no initalized flags table, then
			return an empty table instead of nil
		]]--
		if rawData == nil then rawData = {} end
		--[[
			Save this data into the readCache for later accesses
		]]--
		readCache[userId] = rawData
		return rawData,true
	else
		return nil,false
	end
end

--[[
	This function will attempt to read all of the flags from the player's collection,
	it will return the raw Lua table containing all of the player's flags and true if 
	there were no datastore errors, nil and false if there were datastore errors. If
	ignoreCache is true, then this function will always attempt to grab from the data store.
]]--
function module.readAllFlagsForUserID(userId,ignoreCache)
	if readCache[userId] and not ignoreCache then
		for k,v in pairs(readCache[userId]) do
			print(tostring(k).." : "..tostring(v))
		end
		return readCache[userId],true
	else
		return getFlagsFromDataStoreForUserId(userId)
	end
end

--[[
	This function will attempt to read a flag from the player's collection, it
	will return the flag value and true if there were no datastore errors, nil and
	false if there were datastore errors. If ignoreCache is true, then this function
	will always attempt to grab from the data store.
]]--
function module.readFlagForUserID(userId,flag,ignoreCache)
	local rawData,success = module.readAllFlagsForUserID(userId,ignoreCache)
	if success then
		return rawData[flag],true
	else
		return nil,false
	end
end

--[[
	This function will attempt to write a flag to the player's collection, it
	will return true if there were no datastore errors, false if there were
	datastore errors. If ignoreCache is true, then this function will immediately
	push the changes to the data store (as well as any other changes waiting in
	the cache)
]]--
function module.writeFlagForUserID(userId,flag,value,ignoreCache)
	if writeCache[userId] == nil then
		writeCache[userId] = {}
	end
	if readCache[userId] == nil then
		readCache[userId] = {}
	end
	writeCache[userId][flag] = value
	readCache[userId][flag] = value
	if ignoreCache then
		pushCache()
	end
end

--[[
	This function will force all changes in the cache to update to the datastore
]]--
function module.pushCache()
	pushCache()
end

-- The following functions are wrappers for their userId driven counterparts
function module.readAllFlagsForPlayer(player,ignoreCache)
	local a,b = module.readAllFlagsForUserID(player.userId,ignoreCache)
	return a,b
end
function module.readFlagForPlayer(player,flag,ignoreCache)
	local a,b = module.readFlagForUserID(player.userId,flag,ignoreCache)
	return a,b
end
function module.writeFlagForPlayer(player,flag,value,ignoreCache)
	local a = module.writeFlagForUserID(player.userId,flag,value,ignoreCache)
	return a
end

return module
