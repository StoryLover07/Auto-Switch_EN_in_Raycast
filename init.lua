local raycastBundleID = "com.raycast.macos"
local englishSourceID = "com.apple.keylayout.ABC"

local previousInputSource = nil
local raycastWasActive = false

local function switchToEnglish()
    previousInputSource = hs.keycodes.currentSourceID()
    hs.keycodes.currentSourceID(englishSourceID)
end

local function restorePreviousInputSource()
    if previousInputSource then
        hs.keycodes.currentSourceID(previousInputSource)
        previousInputSource = nil
    end
end

local function isRaycastFrontmost()
    local app = hs.application.frontmostApplication()
    if not app then
        return false
    end

    return app:bundleID() == raycastBundleID
end

local function activateRaycastMode()
    if not raycastWasActive then
        switchToEnglish()
        raycastWasActive = true
    end
end

local function deactivateRaycastMode()
    if raycastWasActive then
        restorePreviousInputSource()
        raycastWasActive = false
    end
end

-- Raycast v2 can present as a panel without a normal window, so window filters
-- may miss open/close transitions. Track the frontmost app by bundle ID instead.
local appWatcher = hs.application.watcher.new(function()
    hs.timer.doAfter(0.05, function()
        if isRaycastFrontmost() then
            activateRaycastMode()
        else
            deactivateRaycastMode()
        end
    end)
end)

appWatcher:start()
