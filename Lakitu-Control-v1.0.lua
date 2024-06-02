-- name: La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\ v1.0
-- description: \\#FFFF00\\[Lakitu Control]\\#dcdcdc\\\n\nAllows you to control Lakitu.\n\nCommands:\n\\#FF6400\\/lakitucontrol-toggle\n\\#FF6400\\/lakitucontrol-settings\\#dcdcdc\\\n\nIdea by: buttersgame\nHelp & Advice: cooliokid956\nMod by: tobbler_

local lm = gMarioStates[0]
local sCB, sConditions, sControlsDefault, sControls, sMovementMode = {}, {}, {}, {}, {}
local magX, magY, uYaw, lLength, uKeybind, init
local freeMove, renderSettings, renderInputs, keybinding, listening, buttonUp = false, false, false, false, false, true
local T, t, selectedSetting, wait, wait2, cossPitch = 0, 0, 0, 0, 0, 1
local TEX_CROSSHAIR = get_texture_info("generic_09000000")
lPitch, lYaw = 0, 0

-- sSettingsNames table, move_camera function, and variables lPitch and lYaw are not local, you may use scripts to manipulate them. --
-- Note: Most of the actions take place while the lakitu control is on.

-- Tables --
-- the lua favoured table
sCB = {
    {name = "A", val = A_BUTTON},
    {name = "B", val = B_BUTTON},
    {name = "Start", val = START_BUTTON},
    {name = "D-Pad Up", val = U_JPAD},
    {name = "D-Pad Down", val = D_JPAD},
    {name = "D-Pad Left", val = L_JPAD},
    {name = "D-Pad Right", val = R_JPAD},
    {name = "C-Up", val = U_CBUTTONS},
    {name = "C-Down", val = D_CBUTTONS},
    {name = "C-Left", val = L_CBUTTONS},
    {name = "C-Right", val = R_CBUTTONS},
    {name = "X", val = X_BUTTON},
    {name = "Y", val = Y_BUTTON},
    {name = "L", val = L_TRIG},
    {name = "R", val = R_TRIG},
    {name = "Z", val = Z_TRIG}
}
-- the tables that lua despises :))))
sConditions = {
    {cond = function() return lm.controller.buttonPressed &      A_BUTTON ~= 0 end, fn = function() sSettingsNames[selectedSetting].val = not sSettingsNames[selectedSetting].val end},
    {cond = function() return lm.controller.buttonPressed & L_JPAD+R_JPAD ~= 0 end, fn = function(dir) dir = dir or 0 sSettingsNames[selectedSetting].val = clampf(sSettingsNames[selectedSetting].val + 1 * dir, 0, 100) end},
    {cond = function() return lm.controller.buttonPressed & L_JPAD+R_JPAD ~= 0 end, fn = function(dir) dir = dir or 0 sSettingsNames[selectedSetting].val = (sSettingsNames[selectedSetting].val + 1 * dir)%(#sMovementMode + 1) end},
    {cond = function() return lm.controller.buttonDown    & L_JPAD+R_JPAD ~= 0 and T - wait2 > 0.2 end, fn = function(dir) dir = dir or 0 sSettingsNames[selectedSetting].val = clampf(sSettingsNames[selectedSetting].val + 1 * dir, -180, 180) wait2 = T end},
}

sSettingsNames = {
    [0] = { name = "Invert X", type = "boolean", stName = "invert_x", val = false, default = false, act = sConditions[1]},
    [1] = { name = "Invert Y", type = "boolean", stName = "invert_y", val = false, default = false, act = sConditions[1]},
    [2] = { name = "Mouse/Touch Look", type = "boolean", stName = "mouse_look", val = true, default = true, act = sConditions[1]},
    [3] = { name = "Crosshair", type = "boolean", stName = "crosshair", val = true, default = true, act = sConditions[1]},
    [4] = { name = "Movement Speed", type = "number", stName = "speed", val = 10, default = 10, act = sConditions[2]},
    [5] = { name = "Rotation sensitivity X", type = "number", stName = "angular_speed_x", val = 10, default = 10, act = sConditions[2]},
    [6] = { name = "Rotation sensitivity Y", type = "number", stName = "angular_speed_y", val = 10, default = 10, act = sConditions[2]},
    [7] = { name = "Field of View (FOV)", type = "number", stName = "fov", val = 0, default = 0, act = sConditions[4]},
    [8] = { name = "Movement Mode", type = "mode", stName = "movement_mode", val = 0, default = 0, act = sConditions[3]},
}
sControlsDefault = {
    [0] = { val = U_JPAD, name = "Move Font"},
    [1] = { val = D_JPAD, name = "Move Back"},
    [2] = { val = L_JPAD, name = "Move Left"},
    [3] = { val = R_JPAD, name = "Move Right"},
    [4] = { val = L_TRIG, name = "Move Up"},
    [5] = { val = R_TRIG, name = "Move Down"},
    [6] = { val = U_CBUTTONS, name = "Look Up"},
    [7] = { val = D_CBUTTONS, name = "Look Down"},
    [8] = { val = L_CBUTTONS, name = "Turn Left"},
    [9] = { val = R_CBUTTONS, name = "Turn Right"}
}

-- load settings from mod storage
sControls = {
    [0] = { val = sControlsDefault[0].val},
    [1] = { val = sControlsDefault[1].val},
    [2] = { val = sControlsDefault[2].val},
    [3] = { val = sControlsDefault[3].val},
    [4] = { val = sControlsDefault[4].val},
    [5] = { val = sControlsDefault[5].val},
    [6] = { val = sControlsDefault[6].val},
    [7] = { val = sControlsDefault[7].val},
    [8] = { val = sControlsDefault[8].val},
    [9] = { val = sControlsDefault[9].val},
}

local function sine1(num)
        return type(num) == "number" and (math.sin(math.rad(180 * num/100 - 90)) + 1) or 0
end

-- Given the relative values, adjusts the camera accordingly
function move_camera(facX, facY, facZ)
    local threshold = sine1(sSettingsNames[4].val)
    -- Update Lakitu's position
    gLakituState.pos.x = gLakituState.pos.x + facX * sine1(sSettingsNames[4].val)*10
    gLakituState.pos.y = gLakituState.pos.y + facY * sine1(sSettingsNames[4].val)*10
    gLakituState.pos.z = gLakituState.pos.z + facZ * sine1(sSettingsNames[4].val)*10
    -- Update the point he's staring at
    gLakituState.focus.x = gLakituState.focus.x + facX * sine1(sSettingsNames[4].val)*10
    gLakituState.focus.y = gLakituState.focus.y + facY * sine1(sSettingsNames[4].val)*10
    gLakituState.focus.z = gLakituState.focus.z + facZ * sine1(sSettingsNames[4].val)*10
end

sMovementMode = {
    [0] = {name = "Blender", setting = function(facX, facY, facZ) move_camera(facX, facY, facZ) end},
    [1] = {name = "Minecraft", setting = function(facX, facY, facZ) move_camera(facX, 0, facZ) end}
}

-- create save if nonexistent [and load] - Coolio May, 2024 (P.S. read about coordination sphere's usage in writing.)
for _, setting in pairs(sSettingsNames) do
    if mod_storage_load(setting.stName) == '' or not mod_storage_load(setting.stName) then
        if not mod_storage_save(setting.stName,tostring(setting.default)) then
            djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. setting.stName .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
        end
    end
    local val = mod_storage_load(setting.stName)
    if type(tonumber(val)) == 'number' then sSettingsNames[_].val = tonumber(val)
    elseif val == 'true' or val == 'false' then sSettingsNames[_].val = val == 'true'
    else sSettingsNames[_].val = setting.default
    end
end

for i, control in pairs(sControls) do
    if not tonumber(mod_storage_load("key_" .. i)) then
        if not mod_storage_save("key_" .. i, tostring(control.val)) then
            djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. "key_" .. i .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
        end
    end
    sControls[i].val = tonumber(mod_storage_load("key_" .. i)) or sControlsDefault[i].val
end

-- adjusts values according to setting
local dirX = sSettingsNames[0].val and -1 or 1
local dirY = sSettingsNames[1].val and -1 or 1
local vMouseLook = sSettingsNames[2].val and 1 or 0

local function limit_angle(a)
        return (a + 0x8000) % 0x10000 - 0x8000
end

--  Resolves Mario's movement angle to the camera when the camera is frozen in free camera mode (BETTERCAM), unnecessary for vanilla camera (The best).
--  This is ONLY for the FREECAM convenience.
local function free_cam_adjustment()
    local bb = atan2s(-lm.controller.rawStickY, lm.controller.rawStickX) -- Me when these exposed function aren't documented!!!

    -- initial yaw uYaw is constant for a lakitu cam session; delta yaw is added to bb ~~Roy of Great Britian~~ offsetted to match stick's angle to that of camera
    lm.controller.stickX = -lm.controller.stickMag * sins(bb + 0x8000 + lYaw - uYaw)
    lm.controller.stickY =  lm.controller.stickMag * coss(bb + 0x8000 + lYaw - uYaw)

--  before you suggest alt. methods, please do try them yourself and think of any potential breakage due to them. This is the safest of all I tried.
end

local function number_to_button(num)
    local pressed = '' -- Initial string
    local count = 0    -- Number of buttons pressed

    -- This unintended feature, works good while selecting keys
    if not num or num == 0 or type(num) ~= 'number' then
        return {string = 'Press Key', count = 0}
    end

    num = num or 0 -- just making sure
    -- Detecting buttons
    for _, button in ipairs(sCB) do
        if (num & button.val) ~= 0 then
            count = count + 1
            pressed = pressed == '' and button.name or pressed .. ' + ' .. button.name
        end
    end

    pressed = (pressed == '' and "Please Set Valid/Distinct Button(s)") or pressed
    return {string = pressed, count = count}
end

local function free_move()
    local prll = 16384 + lYaw
    facX, facY, facZ = facX or 0, facY or 0, facZ or 0

    if not renderSettings and not is_game_paused() then
        -- Movement of Camera Position. Made them separate to allow up left, down right and so forth
        -- For forward and backward respectively

        if (lm.controller.buttonDown & sControls[0].val) ~= 0 then
             facX = -sins(lYaw) * (sMovementMode[sSettingsNames[8].val].name == "Blender" and coss(lPitch) or 1)
             facZ = -coss(lYaw) * (sMovementMode[sSettingsNames[8].val].name == "Blender" and coss(lPitch) or 1)
             facY = sMovementMode[sSettingsNames[8].val].name == "Blender" and sins(lPitch) or 0
            sMovementMode[sSettingsNames[8].val].setting(facX, facY, facZ)
        end
        if (lm.controller.buttonDown & sControls[1].val) ~= 0 then
             facX = sins(lYaw) * (sMovementMode[sSettingsNames[8].val].name == "Blender" and coss(lPitch) or 1)
             facZ = coss(lYaw) * (sMovementMode[sSettingsNames[8].val].name == "Blender" and coss(lPitch) or 1)
             facY = sMovementMode[sSettingsNames[8].val].name == "Blender" and -sins(lPitch) or 0
            sMovementMode[sSettingsNames[8].val].setting(facX, facY, facZ)
        end
        -- This is for left and right movement respectively
        if (lm.controller.buttonDown & sControls[2].val) ~= 0 then
             facX = -sins(prll)
             facZ = -coss(prll)
            move_camera(facX, 0, facZ)
        end
        if (lm.controller.buttonDown & sControls[3].val) ~= 0 then
             facX = sins(prll)
             facZ = coss(prll)
            move_camera(facX, 0, facZ)
        end

        -- This is for vertical movement, up-down respectively
        if (lm.controller.buttonDown & sControls[4].val) ~= 0 then
                move_camera(0, 1, 0)
        elseif (lm.controller.buttonDown & sControls[5].val) ~= 0 then
                move_camera(0, -1, 0)
        end

    -- YAW AND PITCH
        if not sSettingsNames[2].val then -- If mouse look / touch look is disabled
            if (lm.controller.buttonDown & sControls[8].val) ~= 0 then
                lYaw = limit_angle(lYaw + 50 * sSettingsNames[5].val/100 * dirX)
            end
            if (lm.controller.buttonDown & sControls[9].val) ~= 0 then
                lYaw = limit_angle(lYaw - 50 * sSettingsNames[5].val/100 * dirX)
            end

            if (lm.controller.buttonDown & sControls[6].val) ~= 0 then
                lPitch = lPitch + 50 * sSettingsNames[6].val/100 * dirY -- Clamping is done below
            end
            if (lm.controller.buttonDown & sControls[7].val) ~= 0 then
                lPitch = lPitch - 50 * sSettingsNames[6].val/100 * dirY -- Clamping is done below
            end
            -- Through extStick / right stick
            magX = -lm.controller.extStickX
            magY = -lm.controller.extStickY
            if magX ~= 0 or magY ~= 0 then -- Disables the movement through keys if right stick is active
                lm.controller.buttonPressed = lm.controller.buttonPressed & ~sControls[6].val & ~sControls[7].val & ~sControls[8].val & ~sControls[9].val
                lm.controller.buttonDown = lm.controller.buttonDown & ~sControls[6].val & ~sControls[7].val & ~sControls[8].val & ~sControls[9].val
            end
        elseif sSettingsNames[2].val then -- If mouse look / touch look is enabled
            -- Through mouse
            magX = -djui_hud_get_raw_mouse_x()
            magY = djui_hud_get_raw_mouse_y()
        end

        -- Sets the yaw and pitch to the values generated above, either by buttons, stick, or mouse
        lYaw = limit_angle(lYaw + magX * sSettingsNames[5].val/100 * dirX)
        lPitch = clampf(lPitch - magY * sSettingsNames[6].val/100 * dirY, -16384, 16384)
    end
    djui_hud_set_mouse_locked(sSettingsNames[2].val and not is_game_paused())

    -- Appropriately sets the focus of the camera, such that it looks like the camera has rotated.
    cossPitch = (math.abs(coss(lPitch)) < 1e-16 and cossPitch or coss(lPitch))
    gLakituState.focus.x = gLakituState.pos.x - lLength * sins(lYaw) * cossPitch
    gLakituState.focus.z = gLakituState.pos.z - lLength * coss(lYaw) * cossPitch
    gLakituState.focus.y = gLakituState.pos.y + lLength * sins(lPitch)

    -- for other compatibilities
    gLakituState.yaw = lYaw
    lm.area.camera.yaw = lYaw
    vec3f_copy(gLakituState.curPos, gLakituState.pos)
    vec3f_copy(gLakituState.curFocus, gLakituState.focus)
end

-- Toggles LakituCam and sets the initial values
local function toggle_lakitucam()
    if not freeMove then
        -- All these values are set outside freeMove, such that some of these values stay static
        camera_freeze()
        -- calculated pitch
        lPitch = calculate_pitch(gLakituState.pos, gLakituState.focus)
        -- calculated yaw
        lYaw = limit_angle(32772 + calculate_yaw(gLakituState.pos, gLakituState.focus))
        -- to be initial yaw
        uYaw = lYaw
        -- distance between focus and lakitu pos
        lLength = gLakituState.focusDistance
        local movement_controls = '\nHover: \\#00FF88\\' .. number_to_button(sControls[0].val+sControls[1].val+sControls[2].val+sControls[3].val).string:gsub(" %+", ",")
        local vertical_controls = '\n\\#dcdcdc\\Elevate: \\#DDFF00\\' .. number_to_button(sControls[4].val+sControls[5].val).string:gsub(" %+", ",")
        local rotation_controls = ''
        if not sSettingsNames[2].val then
            rotation_controls = '\n\\#dcdcdc\\Observe: \\#FFAAFF\\' .. number_to_button(sControls[6].val+sControls[7].val+sControls[8].val+sControls[9].val).string:gsub(" %+", ",") .. ' \\#FFFFFF\\| \\#FF55FF\\Right Stick'
        else
            rotation_controls = '\n\\#dcdcdc\\Observe: With your \\#FF9955\\Mouse\\#dcdcdc\\ or \\#FFFF55\\Touchscreen.'
        end
        djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: Controlling Lakitu." .. movement_controls .. vertical_controls .. rotation_controls .. '\\#dcdcdc\\\nChange controls/inputs: \\#FFFFFF\\/lakitucontrol-settings\\#dcdcdc\\\nReset settings: \\#FFFFFF\\/lakitucontrol-zreset' )
    else
        camera_unfreeze()
        djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: No longer controlling Lakitu")
    end
    freeMove = not freeMove
    return true
end

-- This is for rendering the check box thing in the settings
local function check(tick, x, y)
    djui_hud_set_color(255, 255, 255, 200)
    djui_hud_render_rect(x, y, 12, 12)
    djui_hud_set_color(0, 0, 0, 200)
    djui_hud_render_rect(x + 1, y + 1, 10, 10)
    djui_hud_set_color(255, 255, 255, 200)
    if tick then
        djui_hud_render_rect(x + 2, y + 2, 8, 8)
    end
end

local function key_bind()
    -- Sets initial values on fn initiation
    if not listening then
        uKeybind = sControls[selectedSetting].val
        listening = true
        sControls[selectedSetting].val = 0
    end

    -- sets new key
    if lm.controller.buttonDown ~= 0 then
        sControls[selectedSetting].val = lm.controller.buttonDown or 0
    end

    -- kills the function
    local count = number_to_button(sControls[selectedSetting].val)
    if listening and count.count > 0 then
        if not mod_storage_save("key_" .. tostring(selectedSetting), tostring(sControls[selectedSetting].val)) then
            djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. "key_" .. tostring(selectedSetting) .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
        end
        uKeybind, keybinding, listening, wait = nil, false, false, T
    end

end

local function option_selector()
    -- kindly excuse me here
    local totalSettings = 0
    if (lm.controller.buttonPressed & A_BUTTON) ~= 0 then -- A BUTTON SAGA
        -- This is for the main settings page
        if not renderInputs then
            if     selectedSetting == 9 then renderInputs, selectedSetting = true, 0
            elseif selectedSetting == 10 then renderSettings, renderInputs, selectedSetting = false, false, 0
            end
        -- This is for the keybinds page
        elseif not keybinding and T - wait > 1 then -- This is for the inputs page only for 'A' button
            if   selectedSetting < 10 then buttonUp = false
            else renderInputs, selectedSetting = false, 0
            end
        end
    end

    if selectedSetting < (#sSettingsNames + 1) then
        local dir = lm.controller.buttonDown & L_JPAD ~= 0 and -1 or lm.controller.buttonDown & R_JPAD ~= 0 and 1 or 0
        if sSettingsNames[selectedSetting].act.cond() then
            sSettingsNames[selectedSetting].act.fn(dir)
        end
    end

    if (lm.controller.buttonPressed & B_BUTTON) ~= 0 then
        if not renderInputs and not keybinding then
            renderSettings, renderInputs, selectedSetting = false, false, 0
        elseif renderInputs and not keybinding and T - wait > 1 then
            renderInputs, selectedSetting = false, 0
        end
    end

    dirX = sSettingsNames[0].val and -1 or 1
    dirY = sSettingsNames[1].val and -1 or 1
    vMouseLook = sSettingsNames[2].val and 1 or 0
    -- Saving all the settings and set values
    if not keybinding and lm.controller.buttonPressed & A_BUTTON+R_JPAD+L_JPAD+B_BUTTON ~= 0 then
        local bool
        for _, setting in pairs(sSettingsNames) do
            if not mod_storage_save(setting.stName,tostring(setting.val)) then
                djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. setting.stName .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
            end
        end
    end

    -- The up-down keys in general
    totalSettings = renderInputs and #sControls + 2 or #sSettingsNames + 3
    if not keybinding then
        if (lm.controller.buttonPressed & U_JPAD) ~= 0 then
            selectedSetting = (selectedSetting - 1)%(totalSettings)
        elseif (lm.controller.buttonPressed & D_JPAD) ~= 0 then
            selectedSetting = (selectedSetting + 1)%(totalSettings)
        end
    end

end

local function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local sWidth = djui_hud_get_screen_width()
    local sHeight = djui_hud_get_screen_height()
    local cScale = 0.5
    djui_hud_set_color(0xFF, 0xFF, 0xFF, 200)
    if freeMove and sSettingsNames[3].val then
        djui_hud_render_texture(TEX_CROSSHAIR, (sWidth-TEX_CROSSHAIR.width * cScale)/2, (sHeight-TEX_CROSSHAIR.height * cScale)/2, cScale, cScale)
    end

    if renderSettings and not is_game_paused() then
        -- the settings panel
        local pWidth = 200
        local pHeight = 200 + 30
        local pHeight2 = 196 + 30
        local pWidth2 = 196
        local tScale = 0.4
        djui_hud_set_color(0, 0, 0, 100)
        djui_hud_render_rect((sWidth - pWidth)/2, (sHeight - pHeight)/2, pWidth, pHeight)
        djui_hud_set_color(0, 0, 0, 128)
        djui_hud_render_rect((sWidth - pWidth2)/2, (sHeight - pHeight2)/2, pWidth2, pHeight2)

        -- Selector/Highlighter
        djui_hud_set_color(128 + 127*math.sin(math.rad(t) ), 128 + 127*math.cos(math.rad(t) ), 128 + 127*coss(gLakituState.yaw), 100 + 5 * selectedSetting * math.cos(t/2) )
        djui_hud_render_rect((sWidth - pWidth2)/2, (sHeight - pHeight2)/2 + 10 + 45 * selectedSetting * tScale, pWidth2, 16)

        djui_hud_set_color(255, 255, 255, 200)
        if not renderInputs then
            -- The settings buttons
            for i,v in pairs(sSettingsNames) do
                local altitude = (sHeight - pHeight2)/2 + 12 + 45 * i * tScale
                djui_hud_print_text(v.name, (sWidth - pWidth2)/2 + 12, altitude, tScale)
                if v.type == "boolean" then
                    check(v.val, (sWidth + pWidth2)/2 - 22, altitude)
                elseif v.type == "mode" then
                    djui_hud_print_text(sMovementMode[v.val].name, ( ( (sWidth + pWidth2)/2 - 52 + djui_hud_measure_text("<") * tScale ) + ( (sWidth + pWidth2)/2 - 7 ) - djui_hud_measure_text(sMovementMode[v.val].name)*tScale )/2, altitude, tScale)
                elseif v.type == "number" then
                    djui_hud_print_text(string.format("% 3.f",v.val), ( ( (sWidth + pWidth2)/2 - 32 + djui_hud_measure_text("<") * tScale ) + ( (sWidth + pWidth2)/2 - 7 ) - djui_hud_measure_text(string.format("% 3.f",v.val))*tScale )/2, altitude, tScale)
                end
            end

            djui_hud_print_text("Inputs >", (sWidth - pWidth2)/2 + 12, (sHeight - pHeight2)/2 + 10 + 45*9 * tScale, tScale)
            djui_hud_print_text("< Back", (sWidth - pWidth2)/2 + 5, (sHeight - pHeight2)/2 + 10 + 45*10 * tScale, tScale)

            djui_hud_set_color(255, 255, 255, 255)
            local bottomLine="[D-PAD]    [B]-Save & Exit    [A]-Select/Toggle"
            djui_hud_print_text(bottomLine, (sWidth - djui_hud_measure_text(bottomLine)*0.43 )/2, (sHeight - pHeight2)/2 + 10 + 45*11 * tScale, 0.43)

            -- Show '< ... >' with appropriate length on appropriate settings
            if selectedSetting < #sSettingsNames+1 then
                if sSettingsNames[selectedSetting].type == "number" or sSettingsNames[selectedSetting].type == "mode" then
                    if sSettingsNames[selectedSetting].type == "mode" then val = 20 else val = 0 end
                    djui_hud_print_text("<", (sWidth + pWidth2)/2 - 32 - val, (sHeight - pHeight2)/2 + 10 + 45 * selectedSetting * tScale, tScale)
                    djui_hud_print_text(">", (sWidth + pWidth2)/2 - 7, (sHeight - pHeight2)/2 + 10 + 45 * selectedSetting * tScale, tScale)
                end
            end

        else
            -- The input buttons
            djui_hud_print_text("< Back", (sWidth - pWidth2)/2 + 5, (sHeight - pHeight2)/2 + 10 + 450 * tScale, tScale)
            for i,v in pairs(sControls) do
                djui_hud_print_text(sControlsDefault[i].name, (sWidth - pWidth2)/2 + 12, (sHeight - pHeight2)/2 + 10 + 45 * i * tScale, tScale)
                djui_hud_print_text(number_to_button(v.val).string, (sWidth + pWidth2)/2 - djui_hud_measure_text(number_to_button(v.val).string) * tScale - 10, (sHeight - pHeight2)/2 + 10 + 45 * i * tScale, tScale)
            end
            -- listen for keys
            if keybinding then
                key_bind()
            end
        end
        option_selector()
    end
end

local function timer()
    T = T + 0.1
    t = (T)%(360)
    -- This is for the A button in the inputs tab
    if not buttonUp and lm.controller.buttonDown == 0 and lm.controller.buttonPressed == 0 then
        buttonUp = true
        keybinding = true
    end
end

local function main(m)
    if renderSettings then
        lm.freeze = 1
        lm.controller.stickMag = 0
    end
    if freeMove then
        camera_freeze()
        free_move()
        if camera_config_is_free_cam_enabled() then free_cam_adjustment() end
        set_override_fov(sSettingsNames[7].val)
        set_override_far(65535)
    else
        set_override_fov(0)
    end
end

local function reset()
    local false_message = ''
    -- mod storage saving & loading settings
    for _, setting in pairs(sSettingsNames) do
        if not mod_storage_save(setting.stName,tostring(setting.default)) then
            djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. setting.stName .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
            false_message = ' for this session'
        end
        local val = mod_storage_load(setting.stName)
        if type(tonumber(val)) == 'number' then
            sSettingsNames[_].val = tonumber(val)
        elseif val == 'true' or val == 'false' then
            sSettingsNames[_].val = val == 'true'
        else
            sSettingsNames[_].val = setting.default
        end
    end
    -- determination
    dirX = sSettingsNames[0].val and -1 or 1
    dirY = sSettingsNames[1].val and -1 or 1
    vMouseLook = sSettingsNames[2].val and 1 or 0

    -- Saving and loading the default key bindings from the mod storage
    for i = 0, #sControls do
        if not mod_storage_save("key_" .. tostring(i), tostring(sControlsDefault[i].val)) then
            djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. "key_" .. tostring(i) .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
            false_message = ' for this session'
        end
        sControls[i].val = tonumber(mod_storage_load("key_" .. i)) or sControlsDefault[i].val
    end

    djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: All settings have been reset" .. false_message .. '.')
    return true
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_BEFORE_MARIO_UPDATE, main)
hook_event(HOOK_UPDATE, timer)

hook_chat_command("lakitucontrol", "\\#FFFF00\\[Lakitu Control]\\#00FF00\\ Toggles Lakitu Control", toggle_lakitucam)
hook_chat_command("lakitucontrol-settings", "\\#FFFF00\\[Lakitu Control]\\#00FF00\\ Lakitu Control settings", function()
    if not renderSettings then
        renderSettings = true
    else
        local bool
        for _, setting in pairs(sSettingsNames) do
            if not mod_storage_save(setting.stName,tostring(setting.val)) then
                djui_chat_message_create("[La\\#FFFF00\\kitu Cont\\#00FF00\\rol\\#dcdcdc\\]: \\#FF0000\\ERROR:\\#dcdcdc\\ Setting \\#FFFFFF\\" .. setting.stName .. "\\#dcdcdc\\ could not be saved.\n\\#FFAAAA\\Please check the mod storage file of this mod.")
            end
        end
        renderSettings, renderInputs, keybinding = false, false, false
    end
    return true
end)
hook_chat_command("lakitucontrol-zreset", "\\#FFFF00\\[Lakitu Control]\\#FF5A5A\\ Reset all settings", reset)

--1044018293985509447--723015866308100116--446899904372277268--
