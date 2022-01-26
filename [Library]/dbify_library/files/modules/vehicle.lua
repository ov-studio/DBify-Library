----------------------------------------------------------------
--[[ Resource: DBify Library
     Files: modules: vehicle.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Vehicle Module ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

dbify["vehicle"] = {
    __connection__ = {
        table = "server_vehicles",
        keyColumn = "id"
    },

    fetchAll = function(keyColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        return dbify.postgres.table.fetchContents(dbify.vehicle.__connection__.table, keyColumns, callback, ...)
    end,

    create = function(callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not callback or (type(callback) ~= "function") then return false end
        dbify.postgres.__connection__.instance:query(function(queryHandler, arguments)
            local callbackReference = callback
            local _, _, vehicleID = vEngine.db:poll(queryHandler, 0)
            local result = vehicleID or false
            if callbackReference and (type(callbackReference) == "function") then
                callbackReference(result, arguments)
            end
        end, {{...}}, "INSERT INTO `??` (`??`) VALUES(NULL)", dbify.vehicle.__connection__.table, dbify.vehicle.__connection__.keyColumn)
        return true
    end,

    delete = function(vehicleID, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") then return false end
        return dbify.vehicle.getData(vehicleID, {dbify.vehicle.__connection__.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if result then
                result = dbify.postgres.__connection__.instance:exec("DELETE FROM `??` WHERE `??`=?", dbify.vehicle.__connection__.table, dbify.vehicle.__connection__.keyColumn, vehicleID)
                if callbackReference and (type(callbackReference) == "function") then
                    callbackReference(result, arguments)
                end
            else
                if callbackReference and (type(callbackReference) == "function") then
                    callbackReference(false, arguments)
                end
            end
        end, ...)
    end,

    setData = function(vehicleID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.set(dbify.vehicle.__connection__.table, dataColumns, {
            {dbify.vehicle.__connection__.keyColumn, vehicleID}
        }, callback, ...)
    end,

    getData = function(vehicleID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.get(dbify.vehicle.__connection__.table, dataColumns, {
            {dbify.vehicle.__connection__.keyColumn, vehicleID}
        }, true, callback, ...)
    end
}


-----------------------
--[[ Event Helpers ]]--
-----------------------

addEventHandler("onAssetStart", function()
    if not dbify.postgres.__connection__.instance then return false end
    dbify.postgres.__connection__.instance:exec("CREATE TABLE IF NOT EXISTS `??` (`??` INT AUTO_INCREMENT PRIMARY KEY)", dbify.vehicle.__connection__.table, dbify.vehicle.__connection__.keyColumn)
end)