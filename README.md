# Roblox Data Flag Module
This module was designed to aid developers in storing simple data regarding individual players without having to worry about the overhead of dealing with the DataStore service. This module exposes easy to use functions that do the heavy lifting for the developer.

## Methods

### readFlagForUserID(userId,flag,ignoreCache)
This method is used to read a flag for a player. Argument userId must be a string value, flag must also be a string value. ignoreCache is an optional boolean argument, if it is true, then the method will always attempt to take the latest data from the DataStore service.

### readFlagForPlayer(player,flag,ignoreCache)
This method is just a wrapper for readFlagForUserID. Argument player must be a player object.

### pushCache()
This method is used to save all of the changes waiting to be made in the cache. It takes no arguments.

## Example Usage
```lua
local dataFlagModule = require(path.to.module.here.DataFlagModule)

-- Retrieve a player's flag
game.Players.PlayerAdded:connect(function(player)
  local data,success = dataFlagModule.readFlagForPlayer(player,"money")
  if success then
    print("Player has $"..(data or 0))
  else
    print("Couldn't get player's money!")
  end
end)

-- Edit a player's flag
function givePlayerMoney(player,amount)
  local currentAmount,success = dataFlagModule.readFlagForPlayer(player,"money")
  if success then
    local newAmount = (currentAmount or 0) + amount
    dataFlagModule.writeFlagForPlayer(player,"money",newAmount)
  end
end

-- Save a player's flag
game.Players.PlayerRemoving:connect(function(player)
  print("Saving all player data..")
  dataFlagModule.pushCache()
  print("Data saved :)")
end)
```
