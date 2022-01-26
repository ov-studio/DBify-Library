----------------------------------------------------------------
--[[ Resource: DBify Library
     Script: handlers: bundler.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Bundler Handler ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

local bundlerData = false


---------------------------------------------
--[[ Functions: Fetches Imports/Database ]]--
---------------------------------------------

function fetchImports(recieveData)

    if not bundlerData then return false end

    if recieveData == true then
        return bundlerData
    else
        return [[
        local importList = call(getResourceFromName("]]..resourceName..[["), "fetchImports", true)
        for i = 1, #importList, 1 do
            loadstring(importList[i])()
        end
        ]]
    end

end

function fetchDatabase()

    return dbSettings.instance
    
end


-----------------------------------------
--[[ Event: On Client Resource Start ]]--
-----------------------------------------

addEventHandler("onAssetStart", function(resourceSource)

    dbSettings.instance = dbConnect("postgres", "dbname="..dbSettings.database..";host="..dbSettings.host..";port="..dbSettings.port..";charset=utf8;", dbSettings.username, dbSettings.password, dbSettings.options) or false

    local importedModules = {
        bundler = [[
            dbify = {}
        ]],
        modules = {
            postgres = fetchFileData("files/modules/postgres.lua")..[[
                resource = getResourceFromName("]]..resourceName..[[")
                dbify.postgres.__connection__.databaseName = "]]..dbSettings.database..[["
                dbify.postgres.__connection__.instance()
            ]],
            account = fetchFileData("files/modules/account.lua"),
            character = fetchFileData("files/modules/character.lua"),
            vehicle = fetchFileData("files/modules/vehicle.lua"),
            inventory = fetchFileData("files/modules/inventory.lua")
        }
    }

    bundlerData = {}
    table.insert(bundlerData, importedModules.bundler)
    table.insert(bundlerData, importedModules.modules.postgres)
    table.insert(bundlerData, importedModules.modules.account)
    table.insert(bundlerData, importedModules.modules.character)
    table.insert(bundlerData, importedModules.modules.vehicle)
    table.insert(bundlerData, importedModules.modules.inventory)

end)