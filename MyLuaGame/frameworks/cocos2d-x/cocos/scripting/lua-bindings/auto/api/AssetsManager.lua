
--------------------------------
-- @module AssetsManager
-- @extend Node
-- @parent_module cc

--------------------------------
-- 
-- @function [parent=#AssetsManager] getMicroUrl 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] setPackageUrl 
-- @param self
-- @param #char packageUrl
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] setLocalSearchPath 
-- @param self
-- @param #bool inMain
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] seccessOver 
-- @param self
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] isMicroPackage 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getVersionFileUrl 
-- @param self
-- @return char#char ret (return value: char)
        
--------------------------------
--  @brief Sets connection time out in seconds
-- @function [parent=#AssetsManager] setConnectionTimeout 
-- @param self
-- @param #unsigned int timeout
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getPatchMinVersion 
-- @param self
-- @return int#int ret (return value: int)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] checkUpdate 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getPatchVersion 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getMicroPath 
-- @param self
-- @return string#string ret (return value: string)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] resetSomething 
-- @param self
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
--  @brief Gets connection time out in secondes
-- @function [parent=#AssetsManager] getConnectionTimeout 
-- @param self
-- @return unsigned int#unsigned int ret (return value: unsigned int)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] isMicroPackageDownloaded 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] setStoragePath 
-- @param self
-- @param #char storagePath
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] isOpen 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getStoragePath 
-- @param self
-- @return char#char ret (return value: char)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] update 
-- @param self
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] setVersionFileUrl 
-- @param self
-- @param #char versionFileUrl
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] setPatchMinVersion 
-- @param self
-- @param #int patchMinV
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getPackageUrl 
-- @param self
-- @return char#char ret (return value: char)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] create 
-- @param self
-- @param #char packageUrl
-- @param #char versionFileUrl
-- @param #char storagePath
-- @param #function errorCallback
-- @param #function progressCallback
-- @param #function successCallback
-- @return AssetsManager#AssetsManager ret (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] getInstance 
-- @param self
-- @return AssetsManager#AssetsManager ret (return value: cc.AssetsManager)
        
--------------------------------
-- 
-- @function [parent=#AssetsManager] AssetsManager 
-- @param self
-- @return AssetsManager#AssetsManager self (return value: cc.AssetsManager)
        
return nil
