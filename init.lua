-- Raycast Input Source Switcher
-- Raycast v2's main search UI is a system overlay, not a normal macOS
-- window, so hs.window.filter/frontmost-window detection can miss it.
-- Hammerspoon owns command-space instead and tracks that overlay session.

local raycastSearchURL = "raycast://"
local englishSourceID = "com.apple.keylayout.ABC"

-- Capture command-space in Hammerspoon so Raycast's overlay session can be
-- tracked even though it is not exposed as a normal macOS window.
local raycastHotkeyKey = "space"

if globalFilter then
    pcall(function() globalFilter:unsubscribeAll() end)
    globalFilter = nil
end

if raycastWatcher then
    pcall(function() raycastWatcher:stop() end)
    raycastWatcher = nil
end

if raycastHotkey then
    pcall(function() raycastHotkey:delete() end)
    raycastHotkey = nil
end

if raycastCommandSpaceWatcher then
    pcall(function() raycastCommandSpaceWatcher:stop() end)
    raycastCommandSpaceWatcher = nil
end

if raycastForceEnglishTimer then
    pcall(function() raycastForceEnglishTimer:stop() end)
    raycastForceEnglishTimer = nil
end

if raycastEnglishTimers then
    for _, timer in ipairs(raycastEnglishTimers) do
        pcall(function() timer:stop() end)
    end
    raycastEnglishTimers = nil
end

if raycastDismissWatcher then
    pcall(function() raycastDismissWatcher:stop() end)
    raycastDismissWatcher = nil
end

local restoreSourceID = nil
local raycastSearchActive = false
raycastEnglishTimers = {}

local function stopEnglishTimers()
    for _, timer in ipairs(raycastEnglishTimers) do
        timer:stop()
    end

    raycastEnglishTimers = {}
end

local function switchToEnglishInputSource()
    if hs.keycodes.currentSourceID() ~= englishSourceID then
        hs.keycodes.currentSourceID(englishSourceID)
    end
end

local function scheduleEnglishSwitch(delay)
    local timer = hs.timer.doAfter(delay, switchToEnglishInputSource)
    table.insert(raycastEnglishTimers, timer)
end

local function primeRaycastEnglishInputSource()
    stopEnglishTimers()
    switchToEnglishInputSource()

    -- The Raycast v2 overlay can finish appearing just after the URL event.
    -- Keep this correction window short so the search box can still be changed
    -- manually with the Korean/English key.
    scheduleEnglishSwitch(0.04)
    scheduleEnglishSwitch(0.1)
end

local function restoreInputSource()
    if restoreSourceID then
        hs.keycodes.currentSourceID(restoreSourceID)
    end

    restoreSourceID = nil
end

local function finishRaycastSearch()
    if not raycastSearchActive then
        return
    end

    raycastSearchActive = false
    stopEnglishTimers()
    restoreInputSource()
end

local function finishRaycastSearchSoon()
    hs.timer.doAfter(0.08, finishRaycastSearch)
end

local function openRaycastSearch()
    hs.urlevent.openURL(raycastSearchURL)
end

local function beginRaycastSearch()
    if raycastSearchActive then
        hs.eventtap.keyStroke({}, "escape", 0)
        finishRaycastSearchSoon()
        return
    end

    restoreSourceID = hs.keycodes.currentSourceID()
    raycastSearchActive = true
    openRaycastSearch()
    primeRaycastEnglishInputSource()
end

local function hasOnlyRaycastHotkeyModifiers(flags)
    return flags.cmd == true
        and flags.alt ~= true
        and flags.ctrl ~= true
        and flags.shift ~= true
end

local function isRaycastHotkeyEvent(event)
    if event:getType() ~= hs.eventtap.event.types.keyDown then
        return false
    end

    local keyCode = event:getKeyCode()
    local keyName = hs.keycodes.map[keyCode]
    local flags = event:getFlags()

    return keyName == raycastHotkeyKey and hasOnlyRaycastHotkeyModifiers(flags)
end

local function handleRaycastHotkeyEvent(event)
    if not isRaycastHotkeyEvent(event) then
        return false
    end

    if event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 1 then
        return true
    end

    beginRaycastSearch()
    return true
end

local function startRaycastHotkeyWatcher()
    if raycastCommandSpaceWatcher then
        raycastCommandSpaceWatcher:stop()
    end

    raycastCommandSpaceWatcher = hs.eventtap.new({
        hs.eventtap.event.types.keyDown,
    }, handleRaycastHotkeyEvent)

    raycastCommandSpaceWatcher:start()
end

-- The overlay does not reliably emit window/app focus events, so infer close
-- from the user actions that dismiss Raycast search and then restore the source.
local function handleDismissEvent(event)
    if not raycastSearchActive then
        return false
    end

    local eventType = event:getType()
    if eventType == hs.eventtap.event.types.keyDown then
        local keyCode = event:getKeyCode()
        local keyName = hs.keycodes.map[keyCode]

        if keyName == "escape" or keyName == "return" or keyName == "padenter" then
            finishRaycastSearchSoon()
        end
    elseif eventType == hs.eventtap.event.types.leftMouseDown
        or eventType == hs.eventtap.event.types.rightMouseDown then
        finishRaycastSearchSoon()
    end

    return false
end

local function startDismissWatcher()
    if raycastDismissWatcher then
        raycastDismissWatcher:stop()
    end

    raycastDismissWatcher = hs.eventtap.new({
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.leftMouseDown,
        hs.eventtap.event.types.rightMouseDown,
    }, handleDismissEvent)

    raycastDismissWatcher:start()
end

startRaycastHotkeyWatcher()
startDismissWatcher()

print("[Raycast Switcher] Overlay-safe command-space watcher started.")
