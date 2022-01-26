----------------------------------------------------------------
--[[ Resource: DBify Library
     Files: modules: inventory.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Inventory Module ]]--
----------------------------------------------------------------


-------------------
--[[ Variables ]]--
-------------------

dbify["inventory"] = {
    __connection__ = {
        table = "server_inventories",
        keyColumn = "id",
        itemFormat = {
            counter = "amount",
            content = {
                data = {},
                property = {
                    amount = 0
                }
            }
        }
    },

    fetchAll = function(keyColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        return dbify.postgres.table.fetchContents(dbify.inventory.__connection__.table, keyColumns, callback, ...)
    end,

    ensureItems = function(items, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not items or (type(items) ~= "table") or not callback or (type(callback) ~= "function") then return false end
        dbify.postgres.__connection__.instance:query(function(queryHandler, arguments)
            local callbackReference = callback
            local result = vEngine.db:poll(queryHandler, 0)
            local itemsToBeAdded, itemsToBeDeleted = {}, {}
            if result and (#result > 0) then
                for i, j in ipairs(result) do
                    local columnName = j["COLUMN_NAME"]
                    local itemIndex = string.gsub(columnName, "item_", "", 1)
                    if not arguments[1].items[itemIndex] then
                        table.insert(itemsToBeDeleted, columnName)
                    end
                end
            end
            for i, j in pairs(arguments[1].items) do
                table.insert(itemsToBeAdded, "item_"..i)
            end
            arguments[1].items = itemsToBeAdded
            if #itemsToBeDeleted > 0 then
                dbify.postgres.column.delete(dbify.inventory.__connection__.table, itemsToBeDeleted, function(result, arguments)
                    if result then
                        for i, j in ipairs(arguments[1].items) do
                            dbify.postgres.column.isValid(dbify.inventory.__connection__.table, j, function(isValid, arguments)
                                local callbackReference = callback
                                if not isValid then
                                    dbify.postgres.__connection__.instance:exec("ALTER TABLE `??` ADD COLUMN `??` TEXT", dbify.inventory.__connection__.table, arguments[1])
                                end
                                if arguments[2] then
                                    if callbackReference and (type(callbackReference) == "function") then
                                        callbackReference(true, arguments[2])
                                    end
                                end
                            end, j, ((i >= #arguments[1].items) and arguments[2]) or false)
                        end
                    else
                        local callbackReference = callback
                        if callbackReference and (type(callbackReference) == "function") then
                            callbackReference(result, arguments[2])
                        end
                    end
                end, arguments[1], arguments[2])
            else
                for i, j in ipairs(arguments[1].items) do
                    dbify.postgres.column.isValid(dbify.inventory.__connection__.table, j, function(isValid, arguments)
                        local callbackReference = callback
                        if not isValid then
                            dbify.postgres.__connection__.instance:exec("ALTER TABLE `??` ADD COLUMN `??` TEXT", dbify.inventory.__connection__.table, arguments[1])
                        end
                        if arguments[2] then
                            if callbackReference and (type(callbackReference) == "function") then
                                callbackReference(true, arguments[2])
                            end
                        end
                    end, j, ((i >= #arguments[1].items) and arguments[2]) or false)
                end
            end
        end, {{{
            items = items
        }, {...}}}, dbify.postgres.__connection__.instance, "SELECT `column_name` FROM information_schema.columns WHERE `table_schema`=? AND `table_name`=? AND `column_name` LIKE 'item_%'", dbify.postgres.__connection__.databaseName, dbify.inventory.__connection__.table)
        return true
    end,

    create = function(callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not callback or (type(callback) ~= "function") then return false end
        dbify.postgres.__connection__.instance:query(function(queryHandler, arguments)
            local callbackReference = callback
            local _, _, inventoryID = vEngine.db:poll(queryHandler, 0)
            local result = inventoryID or false
            if callbackReference and (type(callbackReference) == "function") then
                callbackReference(result, arguments)
            end
        end, {{...}}, "INSERT INTO `??` (`??`) VALUES(NULL)", dbify.inventory.__connection__.table, dbify.inventory.__connection__.keyColumn)
        return true
    end,

    delete = function(inventoryID, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not inventoryID or (type(inventoryID) ~= "number") then return false end
        return dbify.inventory.getData(inventoryID, {dbify.inventory.__connection__.keyColumn}, function(result, arguments)
            local callbackReference = callback
            if result then
                result = dbify.postgres.__connection__.instance:exec("DELETE FROM `??` WHERE `??`=?", dbify.inventory.__connection__.table, dbify.inventory.__connection__.keyColumn, inventoryID)
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

    setData = function(inventoryID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not inventoryID or (type(inventoryID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.set(dbify.inventory.__connection__.table, dataColumns, {
            {dbify.inventory.__connection__.keyColumn, inventoryID}
        }, callback, ...)
    end,

    getData = function(inventoryID, dataColumns, callback, ...)
        if not dbify.postgres.__connection__.instance then return false end
        if not inventoryID or (type(inventoryID) ~= "number") or not dataColumns or (type(dataColumns) ~= "table") or (#dataColumns <= 0) then return false end
        return dbify.postgres.data.get(dbify.inventory.__connection__.table, dataColumns, {
            {dbify.inventory.__connection__.keyColumn, inventoryID}
        }, true, callback, ...)
    end,

    item = {
        __utilities__ = {
            pushnpop = function(inventoryID, items, processType, callback, ...)
                if not dbify.postgres.__connection__.instance then return false end
                if not inventoryID or (type(inventoryID) ~= "number") or not items or (type(items) ~= "table") or (#items <= 0) or not processType or (type(processType) ~= "string") or ((processType ~= "push") and (processType ~= "pop")) then return false end
                return dbify.inventory.fetchAll({
                    {dbify.inventory.__connection__.keyColumn, inventoryID},
                }, function(result, arguments)
                    if result then
                        result = result[1]
                        for i, j in ipairs(arguments[1].items) do
                            j[1] = "item_"..tostring(j[1])
                            j[2] = math.max(0, tonumber(j[2]) or 0)
                            local prevItemData = result[(j[1])]
                            prevItemData = (prevItemData and fromJSON(prevItemData)) or false
                            prevItemData = (prevItemData and prevItemData.data and (type(prevItemData.data) == "table") and prevItemData.item and (type(prevItemData.item) == "table") and prevItemData) or false
                            if not prevItemData then
                                prevItemData = dbify.table.clone(dbify.inventory.__connection__.itemFormat.content, true)
                            end
                            prevItemData.property[(dbify.inventory.__connection__.itemFormat.counter)] = j[2] + (math.max(0, tonumber(prevItemData.property[(dbify.inventory.__connection__.itemFormat.counter)]) or 0)*((arguments[1].processType == "push" and 1) or -1))
                            arguments[1].items[i][2] = toJSON(prevItemData)
                        end
                        dbify.inventory.setData(arguments[1].inventoryID, arguments[1].items, function(result, arguments)
                            local callbackReference = callback
                            if callbackReference and (type(callbackReference) == "function") then
                                callbackReference(result, arguments)
                            end
                        end, arguments[2])
                    else
                        local callbackReference = callback
                        if callbackReference and (type(callbackReference) == "function") then
                            callbackReference(false, arguments[2])
                        end
                    end
                end, {
                    inventoryID = inventoryID,
                    items = items,
                    processType = processType
                }, {...})
            end,

            property_setnget = function(inventoryID, items, properties, processType, callback, ...)
                if not dbify.postgres.__connection__.instance then return false end
                if not inventoryID or (type(inventoryID) ~= "number") or not items or (type(items) ~= "table") or (#items <= 0) or not properties or (type(properties) ~= "table") or (#properties <= 0) or not processType or (type(processType) ~= "string") or ((processType ~= "set") and (processType ~= "get")) then return false end
                for i, j in ipairs(items) do
                    items[i] = "item_"..tostring(j)
                end
                return dbify.inventory.getData(inventoryID, items, function(result, arguments)
                    local callbackReference = callback
                    if result then
                        local properties = {}
                        for i, j in pairs(result) do
                            j = (j and fromJSON(j)) or false
                            j = (j and j.data and (type(j.data) == "table") and j.property and (type(j.property) == "table") and j) or false
                            if arguments[1].processType == "set" then
                                if not j then
                                    j = dbify.table.clone(dbify.inventory.__connection__.itemFormat.content, true)
                                end
                                for k, v in ipairs(arguments[1].properties) do
                                    v[1] = tostring(v[1])
                                    if v[1] == dbify.inventory.__connection__.itemFormat.counter then
                                        v[2] = math.max(0, tonumber(v[2]) or j.property[(v[1])])
                                    end
                                    j.property[(v[1])] = v[2]
                                end
                                table.insert(properties, {i, toJSON(j)})
                            else
                                local itemIndex = string.gsub(i, "item_", "", 1)
                                properties[itemIndex] = {}
                                if j then
                                    for k, v in ipairs(arguments[1].properties) do
                                        v = tostring(v)
                                        properties[itemIndex][v] = j.property[v]
                                    end
                                end
                            end
                        end
                        if arguments[1].processType == "set" then
                            dbify.inventory.setData(arguments[1].inventoryID, properties, function(result, arguments)
                                local callbackReference = callback
                                if callbackReference and (type(callbackReference) == "function") then
                                    callbackReference(result, arguments)
                                end
                            end, arguments[2])
                        else
                            if callbackReference and (type(callbackReference) == "function") then
                                callbackReference(properties, arguments[2])
                            end
                        end
                    else
                        if callbackReference and (type(callbackReference) == "function") then
                            callbackReference(false, arguments[2])
                        end
                    end
                end, {
                    inventoryID = inventoryID,
                    properties = properties,
                    processType = processType
                }, {...})
            end,

            data_setnget = function(inventoryID, items, datas, processType, callback, ...)
                if not dbify.postgres.__connection__.instance then return false end
                if not inventoryID or (type(inventoryID) ~= "number") or not items or (type(items) ~= "table") or (#items <= 0) or not datas or (type(datas) ~= "table") or (#datas <= 0) or not processType or (type(processType) ~= "string") or ((processType ~= "set") and (processType ~= "get")) then return false end
                for i, j in ipairs(items) do
                    items[i] = "item_"..tostring(j)
                end
                return dbify.inventory.getData(inventoryID, items, function(result, arguments)
                    local callbackReference = callback
                    if result then
                        local datas = {}
                        for i, j in pairs(result) do
                            j = (j and fromJSON(j)) or false
                            j = (j and j.data and (type(j.data) == "table") and j.property and (type(j.property) == "table") and j) or false
                            if arguments[1].processType == "set" then
                                if not j then
                                    j = dbify.table.clone(dbify.inventory.__connection__.itemFormat.content, true)
                                end
                                for k, v in ipairs(arguments[1].datas) do
                                    j.data[tostring(v[1])] = v[2]
                                end
                                table.insert(datas, {i, toJSON(j)})
                            else
                                local itemIndex = string.gsub(i, "item_", "", 1)
                                datas[itemIndex] = {}
                                if j then
                                    for k, v in ipairs(arguments[1].datas) do
                                        v = tostring(v)
                                        datas[itemIndex][v] = j.data[v]
                                    end
                                end
                            end
                        end
                        if arguments[1].processType == "set" then
                            dbify.inventory.setData(arguments[1].inventoryID, datas, function(result, arguments)
                                local callbackReference = callback
                                if callbackReference and (type(callbackReference) == "function") then
                                    callbackReference(result, arguments)
                                end
                            end, arguments[2])
                        else
                            if callbackReference and (type(callbackReference) == "function") then
                                callbackReference(datas, arguments[2])
                            end
                        end
                    else
                        if callbackReference and (type(callbackReference) == "function") then
                            callbackReference(false, arguments[2])
                        end
                    end
                end, {
                    inventoryID = inventoryID,
                    datas = datas,
                    processType = processType
                }, {...})
            end
        },

        add = function(inventoryID, items, callback, ...)
            return dbify.inventory.item.__utilities__.pushnpop(inventoryID, items, "push", callback, ...)
        end,

        remove = function(inventoryID, items, callback, ...)
            return dbify.inventory.item.__utilities__.pushnpop(inventoryID, items, "pop", callback, ...)
        end,

        setProperty = function(inventoryID, items, properties, callback, ...)        
            return dbify.inventory.item.__utilities__.property_setnget(inventoryID, items, properties, "set", callback, ...)
        end,

        getProperty = function(inventoryID, items, properties, callback, ...)        
            return dbify.inventory.item.__utilities__.property_setnget(inventoryID, items, properties, "get", callback, ...)
        end,

        setData = function(inventoryID, items, datas, callback, ...)        
            return dbify.inventory.item.__utilities__.data_setnget(inventoryID, items, datas, "set", callback, ...)
        end,

        getData = function(inventoryID, items, datas, callback, ...)        
            return dbify.inventory.item.__utilities__.data_setnget(inventoryID, items, datas, "get", callback, ...)
        end
    }
}


-----------------------
--[[ Event Helpers ]]--
-----------------------

vEngine.event.on("onAssetStart", function()
    if not dbify.postgres.__connection__.instance then return false end
    dbify.postgres.__connection__.instance:exec("CREATE TABLE IF NOT EXISTS `??` (`??` INT AUTO_INCREMENT PRIMARY KEY)", dbify.inventory.__connection__.table, dbify.inventory.__connection__.keyColumn)
end)