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
    connection = {
        table = "server_vehicles",
        keyColumn = "id"
    },

    fetchAll = function(keyColumns, callback, ...)
        if not dbify.postgres.connection.instance then return false end
        return dbify.postgres.table.fetchContents(dbify.vehicle.connection.table, keyColumns, callback, ...)
    end,

    create = function(callback, ...)
        if not dbify.postgres.connection.instance then return false end
        if not callback or (type(callback) ~= "function") then return false end
        dbify.postgres.connection.instance:query(function(queryHandler, arguments)
            local callbackReference = callback
            local _, _, vehicleID = vEngine.db:poll(queryHandler, 0)
            local result = vehicleID or false
            if callbackReference and (type(callbackReference) == "function") then
                callbackReference(result, arguments)
            end
        end, {{...}}, "INSERT INTO `??` (`??`) VALUES(NULL)", dbify.vehicle.connection.table, dbify.vehicle.connection.keyColumn)
        return true
    end,

    delete = function(vehicleID, callback, ...)
        if not dbify.postgres.connection.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") then return false end
        return dbify.vehicle.getData(vehicleID, {dbify.vehicle.connection.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if result then
                result = dbify.postgres.connection.instance:exec("DELETE FROM `??` WHERE `??`=?", dbify.vehicle.connection.table, dbify.vehicle.connection.keyColumn, vehicleID)
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
        if not dbify.postgres.connection.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.set(dbify.vehicle.connection.table, dataColumns, {
            {dbify.vehicle.connection.keyColumn, vehicleID}
        }, callback, ...)
    end,

    getData = function(vehicleID, dataColumns, callback, ...)
        if not dbify.postgres.connection.instance then return false end
        if not vehicleID or (type(vehicleID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.get(dbify.vehicle.connection.table, dataColumns, {
            {dbify.vehicle.connection.keyColumn, vehicleID}
        }, true, callback, ...)
    end
}


-----------------------
--[[ Event Helpers ]]--
-----------------------

addEventHandler("onAssetStart", function()
    if not dbify.postgres.connection.instance then return false end
    dbify.postgres.connection.instance:exec("CREATE TABLE IF NOT EXISTS `??` (`??` INT AUTO_INCREMENT PRIMARY KEY)", dbify.vehicle.connection.table, dbify.vehicle.connection.keyColumn)
end)