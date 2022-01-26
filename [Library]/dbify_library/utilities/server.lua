----------------------------------------------------------------
--[[ Resource: DBify Library
     Script: utilities: server.lua
     Server: -
     Author: OvileAmriam
     Developer: Aviril
     DOC: 09/10/2021 (OvileAmriam)
     Desc: Server Sided Utilities ]]--
----------------------------------------------------------------


-----------------
--[[ Imports ]]--
-----------------

local imports = {
    fileExists = fileExists,
    fileOpen = fileOpen,
    fileRead = fileRead,
    fileGetSize = fileGetSize,
    fileClose = fileClose
}


---------------------------------------
--[[ Function: Fetches File's Data ]]--
---------------------------------------

function fetchFileData(filePath)

    if not filePath or not imports.fileExists(filePath) then return false end
    local file = imports.fileOpen(filePath, true)
    if not file then return false end

    local fileData = imports.fileRead(file, imports.fileGetSize(file))
    imports.fileClose(file)
    return fileData

end