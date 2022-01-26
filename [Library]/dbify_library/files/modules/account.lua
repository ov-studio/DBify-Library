----------------------------------------------------------------
--[[ Resource: DBify Library
     Files: modules: account.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Account Module ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

dbify["account"] = {
    __connection__ = {
        table = "user_accounts",
        keyColumn = "name"
    },

    fetchAll = function(keyColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        return dbify.postgres.table.fetchContents(dbify.account.__connection__.table, keyColumns, callback, ...)
    end,

    create = function(accountName, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not accountName or (type(accountName) ~= "string") then return false end
        return dbify.account.getData(accountName, {dbify.account.__connection__.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if not result then
                result = vEngine.db:exec(dbify.postgres.__connection__.instance, "INSERT INTO `??` (`??`) VALUES(?)", dbify.account.__connection__.table, dbify.account.__connection__.keyColumn, accountName)
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

    delete = function(accountName, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not accountName or (type(accountName) ~= "string") then return false end
        return dbify.account.getData(accountName, {dbify.account.__connection__.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if result then
                result = vEngine.db:exec(dbify.postgres.__connection__.instance, "DELETE FROM `??` WHERE `??`=?", dbify.account.__connection__.table, dbify.account.__connection__.keyColumn, accountName)
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

    setData = function(accountName, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not accountName or (type(accountName) ~= "string") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.set(dbify.account.__connection__.table, dataColumns, {
            {dbify.account.__connection__.keyColumn, accountName}
        }, callback, ...)
    end,

    getData = function(accountName, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not accountName or (type(accountName) ~= "string") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.get(dbify.account.__connection__.table, dataColumns, {
            {dbify.account.__connection__.keyColumn, accountName}
        }, true, callback, ...)
    end
}


-----------------------
--[[ Event Helpers ]]--
-----------------------

vEngine.event.on("onAssetStart", function()
    if not dbify.postgres.__connection__.instance then return false end
    vEngine.db:exec(dbify.postgres.__connection__.instance, "CREATE TABLE IF NOT EXISTS `??` (`??` VARCHAR(100) PRIMARY KEY)", dbify.account.__connection__.table, dbify.account.__connection__.keyColumn)
    --TODO: LOOP THOUGH EXISTING PLAYERS AND FORCE CREATE AGAIN.
end)

vEngine.event.add("DBify-Library:onUserLogin", function(accountName)
    if not dbify.postgres.__connection__.instance then return false end
    dbify.account.create(accountName)
end)