----------------------------------------------------------------
--[[ Resource: DBify Library
     Script: utilities: server.lua
     Author: vStudio
     Developer(s): Tron
     DOC: 26/01/2022
     Desc: Server Sided Utilities ]]--
----------------------------------------------------------------


---------------------------------------
--[[ Function: Fetches File's Data ]]--
---------------------------------------

function fetchFileData(filePath)

    if not filePath or not fileExists(filePath) then return false end
    local file = fileOpen(filePath, true)
    if not file then return false end

    local fileData = fileRead(file, fileGetSize(file))
    fileClose(file)
    return fileData

end