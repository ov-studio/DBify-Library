----------------------------------------------------------------
--[[ Resource: DBify Library
     Files: modules: character.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Character Module ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

dbify["character"] = {
    __connection__ = {
        table = "user_characters",
        keyColumn = "id"
    },

    fetchAll = function(keyColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        return dbify.postgres.table.fetchContents(dbify.character.__connection__.table, keyColumns, callback, ...)
    end,

    create = function(callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not callback or (type(callback) ~= "function") then return false end
        dbQuery(function(queryHandler, arguments)
            local callbackReference = callback
            local _, _, characterID = vEngine.db:poll(queryHandler, 0)
            local result = characterID or false
            if callbackReference and (type(callbackReference) == "function") then
                callbackReference(result, arguments)
            end
        end, {{...}}, dbify.postgres.__connection__.instance, "INSERT INTO `??` (`??`) VALUES(NULL)", dbify.character.__connection__.table, dbify.character.__connection__.keyColumn)
        return true
    end,

    delete = function(characterID, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not characterID or (type(characterID) ~= "number") then return false end
        return dbify.character.getData(characterID, {dbify.character.__connection__.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if result then
                result = vEngine.db:exec(dbify.postgres.__connection__.instance, "DELETE FROM `??` WHERE `??`=?", dbify.character.__connection__.table, dbify.character.__connection__.keyColumn, characterID)
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

    setData = function(characterID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not characterID or (type(characterID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.set(dbify.character.__connection__.table, dataColumns, {
            {dbify.character.__connection__.keyColumn, characterID}
        }, callback, ...)
    end,

    getData = function(characterID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not characterID or (type(characterID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.get(dbify.character.__connection__.table, dataColumns, {
            {dbify.character.__connection__.keyColumn, characterID}
        }, true, callback, ...)
    end
}


-----------------------
--[[ Event Helpers ]]--
-----------------------

vEngine.event.on("onAssetStart", function()
    if not dbify.postgres.__connection__.instance then return false end
    vEngine.db:exec(dbify.postgres.__connection__.instance, "CREATE TABLE IF NOT EXISTS `??` (`??` INT AUTO_INCREMENT PRIMARY KEY)", dbify.character.__connection__.table, dbify.character.__connection__.keyColumn)
end)