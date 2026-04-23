local previousInputSource = nil

local function switchToEnglish()
    previousInputSource = hs.keycodes.currentSourceID()
    hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
end

local function restorePreviousInputSource()
    if previousInputSource then
        hs.keycodes.currentSourceID(previousInputSource)
        previousInputSource = nil
    end
end

local raycastFilter = hs.window.filter.new("Raycast")

raycastFilter:subscribe(hs.window.filter.windowCreated, function()
    switchToEnglish()
end)

raycastFilter:subscribe(hs.window.filter.windowDestroyed, function()
    restorePreviousInputSource()
end)