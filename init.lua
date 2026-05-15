local englishSourceID = "com.apple.keylayout.ABC"
local previousInputSource = nil
local raycastWasActive = false
local hotkeyRef = nil

local function switchToEnglish()
    previousInputSource = hs.keycodes.currentSourceID()
    print("Switching to English. Previous: " .. (previousInputSource or "nil"))
    hs.keycodes.currentSourceID(englishSourceID)
end

local function restorePreviousInputSource()
    if previousInputSource then
        print("Restoring to: " .. previousInputSource)
        hs.keycodes.currentSourceID(previousInputSource)
        previousInputSource = nil
    end
end

-- Escape 키 감지 (Raycast를 Escape로 닫을 때 복원)
local escapeTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    if raycastWasActive then
        local keyCode = e:getKeyCode()
        if keyCode == 53 then -- Escape
            hs.timer.doAfter(0.1, function()
                restorePreviousInputSource()
                raycastWasActive = false
                print("Raycast closed via Escape.")
            end)
        end
    end
end)
escapeTap:start()

hotkeyRef = hs.hotkey.bind({"alt"}, "space", function()
    if not raycastWasActive then
        -- Raycast 열기
        switchToEnglish()
        raycastWasActive = true
        hotkeyRef:disable()
        hs.eventtap.keyStroke({"alt"}, "space")
        hs.timer.doAfter(0.3, function()
            hotkeyRef:enable()
        end)
    else
        -- Raycast 닫기 (두 번째 Option+Space)
        restorePreviousInputSource()
        raycastWasActive = false
        hotkeyRef:disable()
        hs.eventtap.keyStroke({"alt"}, "space")
        hs.timer.doAfter(0.3, function()
            hotkeyRef:enable()
        end)
    end
end)

print("Raycast input source hotkey started.")
