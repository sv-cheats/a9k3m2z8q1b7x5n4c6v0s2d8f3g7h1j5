local pui           = require("gamesense/pui")
local vector        = require("vector")
local clipboard     = require("gamesense/clipboard")
local base64        = require("gamesense/base64")
local ffi           = require("ffi")
local http          = require('gamesense/http')
local aa_func       = require('gamesense/antiaim_funcs')
local trace         = require('gamesense/trace')
local csgo_weapons  = require('gamesense/csgo_weapons')
local steamworks    = require('gamesense/steamworks')
local localize      = require('gamesense/localize')
local chat          = require('gamesense/chat')
local surface       = require('gamesense/surface')
local images        = require('gamesense/images')
local Session = {}
Session.__index = Session

function Session.new(username, build)
    return setmetatable({
        username = username or "unknown",
        build    = build    or "release",
    }, Session)
end

function Session:display()       return self.username end
function Session:display_upper() return self.username:upper() end
function Session:tag()           return string.format("[%s] %s", self.build, self.username) end

local lua = Session.new(_G.harmony_username or "admin", "Beta")
local menu_r, menu_g, menu_b, menu_a = ui.get(ui.reference("MISC", "Settings", "Menu color"))
local lua_color = string.format("\a%02X%02X%02X%02X", menu_r, menu_g, menu_b, menu_a)

local avatar_texture = nil
local avatar_loaded  = false
local avatar_size    = 16
local reference = {
    rage = {
        aimbot = {
            enabled = { pui.reference('rage', 'aimbot', 'enabled') },
            target_hitbox = pui.reference('rage', 'aimbot', 'target hitbox'),
            minimum_damage = pui.reference('rage', 'aimbot', 'minimum damage'),
            minimum_damage_override = { pui.reference('rage', 'aimbot', 'minimum damage override') },
            minimum_hitchance = pui.reference('rage', 'aimbot', 'minimum hit chance'),
            double_tap = { pui.reference('rage', 'aimbot', 'double tap') },
            double_tap_limit = pui.reference('rage', 'aimbot', 'double tap fake lag limit'),
            force_body = pui.reference('rage', 'aimbot', 'force body aim'),
            force_safe = pui.reference('rage', 'aimbot', 'force safe point'),
            auto_scope = pui.reference('rage', 'aimbot', 'automatic scope')
        },

        other = {
            quickpeek = { pui.reference('rage', 'other', 'quick peek assist') },
            quickpeek_assist_mode = { pui.reference('rage', 'other', 'quick peek assist mode') },
            quickpeek_assist_distance = pui.reference('rage', 'other', 'quick peek assist distance'),
            fake_duck = pui.reference('rage', 'other', 'duck peek assist'),
            log_spread = pui.reference('rage', 'other', 'log misses due to spread'),
        },

        ps = { pui.reference('misc', 'miscellaneous', 'ping spike') },
        log_hit = pui.reference('misc', 'miscellaneous', 'log damage dealt'),
        log_purchases = pui.reference('misc', 'miscellaneous', 'log weapon purchases')
    },

    antiaim = {
        angles = {
            enabled = pui.reference('aa', 'anti-aimbot angles', 'enabled'),
            pitch = { pui.reference('aa', 'anti-aimbot angles', 'pitch') },
            yaw = { pui.reference('aa', 'anti-aimbot angles', 'yaw') },
            yaw_base = pui.reference('aa', 'anti-aimbot angles', 'yaw base'),
            yaw_jitter = { pui.reference('aa', 'anti-aimbot angles', 'yaw jitter') },
            body_yaw = { pui.reference('aa', 'anti-aimbot angles', 'body yaw') },
            fs_body_yaw = pui.reference('aa', 'anti-aimbot angles', 'freestanding body yaw'),
            edge_yaw = pui.reference('aa', 'anti-aimbot angles', 'edge yaw'),
            freestanding = { pui.reference('aa', 'anti-aimbot angles', 'freestanding') },
            roll = pui.reference('aa', 'anti-aimbot angles', 'roll')
        },
        fakelag = {
            enabled = pui.reference('aa', 'fake lag', 'enabled'),
            amount = pui.reference('aa', 'fake lag', 'amount'),
            variance = pui.reference('aa', 'fake lag', 'variance'),
            limit = pui.reference('aa', 'fake lag', 'limit')
        },
        other = {
            on_shot_anti_aim = { pui.reference('aa', 'other', 'on shot anti-aim') },
            slow_motion = { pui.reference('aa', 'other', 'slow motion') },
            fake_peek = { pui.reference('aa', 'other', 'fake peek') },
            leg_movement = pui.reference('aa', 'other', 'leg movement')
        }
    },

    visuals = {
        scope = pui.reference('visuals', 'effects', 'remove scope overlay'),
        thirdperson = pui.reference('visuals', 'effects', 'force third person (alive)')
    },

    misc = {
        miscellaneous = {
            override_zoom_fov = pui.reference('misc', 'miscellaneous', 'override zoom fov'),
            draw_console_output = pui.reference('misc', 'miscellaneous', 'draw console output')
        },

        settings = {
            menu_color = pui.reference('misc', 'settings', 'menu color'),
            anti_untrusted = pui.reference('misc', 'settings', 'anti-untrusted')
        },

        movement = {
            air_strafe = pui.reference('misc', 'movement', 'air strafe')
        }
    },

    playerlist = {
        players = pui.reference('Players', 'Players', 'Player list'),
        force_body = pui.reference('Players', 'Adjustments', 'Force body yaw'),
        force_body_value = pui.reference('Players', 'Adjustments', 'Force body yaw value'),
        reset = pui.reference('Players', 'Players', 'Reset all')
    }
} do
    defer(function ()
        pui.traverse(reference, function (ref)
            ref:override()
            ref:set_enabled(true)
            if ref.hotkey then ref.hotkey:set_enabled(true) end
        end)
    end)

    reference.antiaim.angles.yaw[2]:depend({reference.antiaim.angles.yaw[1], 666}, {reference.antiaim.angles.yaw[2], 666})
    reference.antiaim.angles.pitch[2]:depend({reference.antiaim.angles.pitch[1], 666}, {reference.antiaim.angles.pitch[2], 666})
    reference.antiaim.angles.yaw_jitter[1]:depend({reference.antiaim.angles.yaw[1], 666}, {reference.antiaim.angles.yaw[2], 666})
    reference.antiaim.angles.yaw_jitter[2]:depend({reference.antiaim.angles.yaw[1], 666}, {reference.antiaim.angles.yaw[2], 666}, {reference.antiaim.angles.yaw_jitter[1], 666}, {reference.antiaim.angles.yaw_jitter[2], 666})
    reference.antiaim.angles.body_yaw[2]:depend({reference.antiaim.angles.body_yaw[1], 666})
    reference.antiaim.angles.fs_body_yaw:depend({reference.antiaim.angles.body_yaw[1], 666})
    pui.traverse(reference.antiaim.angles, function (ref)
        ref:depend({reference.antiaim.angles.enabled, 666})
        if ref.hotkey then ref.hotkey:depend({reference.antiaim.angles.enabled, 666}) end
    end)
end
local referencesth = {
    Fakelagcb = ui.reference("AA", "Fake Lag", "Enabled"),
    Fakelagcb_hk = select(2, ui.reference("AA", "Fake Lag", "Enabled")),
    flamount = ui.reference("AA", "Fake Lag", "Amount"),
    flvariance = ui.reference("AA", "Fake Lag", "Variance"),
    fllimit = ui.reference("AA", "Fake Lag", "Limit"),
    fake_peek = ui.reference("AA", "Other", "Fake peek"),
    fake_peek_hk = select(2, ui.reference("AA", "Other", "Fake peek")),
    lm = ui.reference("AA", "Other", "Leg movement"),
    aa_cb = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    slow_motion = ui.reference("AA", "Other", "Slow motion"),
    slow_motion_key = select(2, ui.reference("AA", "Other", "Slow motion")),
    onshot_aa = ui.reference("AA", "Other", "On shot anti-aim"),
    onshot_aa_key = select(2, ui.reference("AA", "Other", "On shot anti-aim")),
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch"),
    pitch_val = select(2, ui.reference("AA", "Anti-aimbot angles", "Pitch")),
    yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = ui.reference("AA", "Anti-aimbot angles", "Yaw"),
    yaw_val = select(2, ui.reference("AA", "Anti-aimbot angles", "Yaw")),
    jitter = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter"),
    jitter_val = select(2, ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")),
    body = ui.reference("AA", "Anti-aimbot angles", "Body Yaw"),
    body_val = select(2, ui.reference("AA", "Anti-aimbot angles", "Body Yaw")),
    freestand_body = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
    edge_yaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    freestanding = ui.reference("AA", "Anti-aimbot angles", "Freestanding"),
    freestanding_key = select(2, ui.reference("AA", "Anti-aimbot angles", "Freestanding")),
    roll = ui.reference("AA", "Anti-aimbot angles", "Roll"),
}

local elements = {}
local all_binds = {}
local buttons = {}
local is_element = function(ref)
    local a = false;
    for k,v in pairs(elements) do

        if k == ref or v == ref then a = true; end;
    end
    return a
end
local is_button = function(ref)
    local a = false;
    for k,v in pairs(buttons) do

        if k == ref or v == ref then a = true; end;
    end
    return a
end

local function build(tab, group, elem_type, name, ...)
    local formatted_name

    if name:sub(1, 1) == "\n" then
        local clean_name = name:sub(2)
        formatted_name = "\n" .. lua_color .. clean_name
    else
        formatted_name = lua_color .. name
    end

    local element = pui["new_" .. elem_type](tab, group, formatted_name, ...)

    table.insert(elements, element)
    if elem_type == "button" then
        table.insert(buttons, element)
    elseif elem_type == "hotkey" then
        all_binds[#all_binds + 1] = element
    end

    return element
end

function aa_combo(c, ...)    return build("AA", "Anti-aimbot angles", "combobox", c, ...) end
function aa_color(c, ...)    return build("AA", "Anti-aimbot angles", "color_picker", c, ...) end
function aa_button(c, ...)   return build("AA", "Anti-aimbot angles", "button", c, ...) end
function aa_slider(c, ...)   return build("AA", "Anti-aimbot angles", "slider", c, ...) end
function aa_checkbox(c)      return build("AA", "Anti-aimbot angles", "checkbox", c) end
function aa_multi(c, ...)    return build("AA", "Anti-aimbot angles", "multiselect", c, ...) end
function aa_list(c, ...)     return build("AA", "Anti-aimbot angles", "listbox", c, ...) end
function aa_textbox(c)       return build("AA", "Anti-aimbot angles", "textbox", c) end
function aa_label(c)         return build("AA", "Anti-aimbot angles", "label", c) end
function aa_hotkey(c, ...)   return build("AA", "Anti-aimbot angles", "hotkey", c, ...) end

function fakelag_list(c, ...)     return build("AA", "Fake lag", "listbox", c, ...) end
function fakelag_combo(c, ...)    return build("AA", "Fake lag", "combobox", c, ...) end
function fakelag_slider(c, ...)   return build("AA", "Fake lag", "slider", c, ...) end
function fakelag_color(c, ...)    return build("AA", "Fake lag", "color_picker", c, ...) end
function fakelag_checkbox(c)      return build("AA", "Fake lag", "checkbox", c) end
function fakelag_multi(c, ...)    return build("AA", "Fake lag", "multiselect", c, ...) end
function fakelag_label(c)         return build("AA", "Fake lag", "label", c) end
function fakelag_hotkey(c, ...)   return build("AA", "Fake lag", "hotkey", c, ...) end
function fakelag_button(c, ...)   return build("AA", "Fake lag", "button", c, ...) end
function fakelag_textbox(c)       return build("AA", "Fake lag", "textbox", c) end

function other_combo(c, ...)      return build("AA", "Other", "combobox", c, ...) end
function other_slider(c, ...)     return build("AA", "Other", "slider", c, ...) end
function other_color(c, ...)      return build("AA", "Other", "color_picker", c, ...) end
function other_checkbox(c)        return build("AA", "Other", "checkbox", c) end
function other_multi(c, ...)      return build("AA", "Other", "multiselect", c, ...) end
function other_label(c)           return build("AA", "Other", "label", c) end
function other_button(c, ...)     return build("AA", "Other", "button", c, ...) end
function other_textbox(c)         return build("AA", "Other", "textbox", c) end

local interface = {}
function interface.animate(a, b, f)
    if not a then return b or 0 end
    if not b or not f then return a end
    local dt = globals.frametime() or 0.016
    return a + (b - a) * (1 - math.exp(-f * dt))
end
seconds = 0
total_time = ""
serialized_time = ""
local conditions = {
    "Global",
    "Stand",
    "Move",
    "Crouch",
    "Crouch-move",
    "Air",
    "Air & Crouched",
    "Slow-Walk",
    "On Use"
}
local alternative_conditions = {}
for i = 1, #conditions do
    alternative_conditions[i] = lua_color .. '•\a9D9D9DFF  ' .. conditions[i]
end
local state = "Global"
local cfgs = {}
local cfg_text = 0
local cfg_list = 0
local cfg_key = "overflame_local::cfg"

local update_cfg = function()
    pcall(function()
        local db = database.read(cfg_key) or {}
        local names = {}
        for k,v in pairs(db) do
            table.insert(names,k)
        end
        ui.update(cfg_list, names)
        ui.set(menu.config.name,names[ui.get(menu.config.list) + 1])
    end)
end

local save_cfg = function()
    pcall(function()
        local db = database.read(cfg_key) or {}

        db[ui.get(cfg_text)] = export(true)

        cfgs = db
        database.write(cfg_key,cfgs)
        update_cfg()
    end)
end

local load_cfg = function()
    pcall(function()
        local db = database.read(cfg_key) or {}

        local cfg = db[ui.get(cfg_text)]

        import(cfg)
    end)
end

local delete_cfg = function()
    pcall(function()
        local db = database.read(cfg_key) or {}

        db[ui.get(cfg_text)] = nil

        database.write(db)
        update_cfg()
    end)
end
menu = {
    scary_mode = aa_checkbox("\aCDCDCDFFScary Mode"),
    tab = aa_combo("\n\aCDCDCDFFgroup", {"Home", "Anti-Aim's", "Features", "Presets"}),

    rage = {
        tab_sec = fakelag_combo("\n\aCDCDCDFFtype ", {"Statistics", "Other"}),
        aa_label(" "),
        other_section = {
            youtube = aa_button("\aFF1717FFYou\aCDCDCDFFTube Channel", function ()
                panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/@")
            end),
            discord = aa_button('\ab0ceffffDiscord \aCDCDCDFFServer', function ()
                panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/G33XGfRUVs")
            end),
        },
        statistics = {
            serialized_time = aa_label("\aCDCDCDFFTotal time: "),
            spacing_in_stat0 = aa_label(" "),
            ts_session = aa_label("\aCDCDCDFFThis session time: "),
            spacing_in_stat1 = aa_label(" "),
            enemy_killed = aa_label("\aCDCDCDFFEnemy killed: " .. lua_color .. "0"),
            spacing_in_stat2 = aa_label(" "),
            evaded_shots = aa_label("\aCDCDCDFFEvaded shots: " .. lua_color .. "0")
        },
        rage_section = {
            space = fakelag_label(" "),
            clantag = fakelag_checkbox("\aCDCDCDFFClantag"),
            trash_talk = {
                enable = fakelag_checkbox("\aCDCDCDFFTrash talk"),
                setting = {
                    work = fakelag_multi("\a323232FF \aCDCDCDFFEvents", {"On kill", "On death"}),
                    type = fakelag_combo("\a323232FF \aCDCDCDFFCategory", {"Advertise us", "Simple"}),
                },
            },
        },
    },
    aa = {
        category = fakelag_combo("\n  \aCDCDCDFF " .. lua_color .. "", {"Legacy", "Defensive", "Settings"}),
        type = fakelag_combo("\n  \a323232FF " .. lua_color .. "", {"Yaw", "Pitch", "Exploit", "Anti-Brute"}),
        fakelag_amount = fakelag_combo(" ", {"Dynamic", "Maximum", "Fluctuate"}),
        fakelag_variance = fakelag_slider(" \aCDCDCDFFVariance", 0,100,0,true,"%",1),
        fakelag_limit = fakelag_slider(" \aCDCDCDFFLimit", 1,15,15,true,"",1),
        manual_spacing = aa_label(" "),
        left_checkbox = aa_checkbox("\aCDCDCDFFManual " .. lua_color .. "» Left"),
        left_manual = aa_hotkey("Manual Left", true),
        right_checkbox = aa_checkbox("\aCDCDCDFFManual " .. lua_color .. "» Right"),
        right_manual = aa_hotkey("Manual Right", true),
        forward_checkbox = aa_checkbox("\aCDCDCDFFManual " .. lua_color .. "» Forward"),
        forward_manual = aa_hotkey("Manual Forward", true),
        backward_checkbox = aa_checkbox("\aCDCDCDFFManual " .. lua_color .. "» Backward"),
        backward_manual = aa_hotkey("Manual Backward", true),
        freestanding_checkbox = aa_checkbox("\aCDCDCDFFFreestanding"),
        freestanding_hotkey = aa_hotkey("Freestanding", true),
        space01 = aa_label(" "),
        safe_head = aa_multi("\aCDCDCDFFSafe Head", {"On Knife", "On Zeus", "On R8"}),
        warmup_aa = aa_combo("\aCDCDCDFFWarmup anti-aim", {"Off", "Nyanza", "Nyanza Beta", "Spin"}),
        preset = fakelag_slider(lua_color .."\n\aCDCDCDFFBuilder", 1, 3, 1, true, '', 1, {[1] = "Custom", [2] = "Jitter", [3] = "Dynamic"}),

        space_fl = fakelag_label(" "),
        space_aa = aa_label("\n "),
        label_state = fakelag_label(lua_color .."\aCDCDCDFFPlayer " .. lua_color .. "State"),
        state = fakelag_combo(" ", alternative_conditions),
        antibrute_l = aa_slider("\aCDCDCDFFLeft", 0, 60, 0,true,"°",1),
        antibrute_r = aa_slider("\aCDCDCDFFRight", 0, 60, 0,true,"°",1),
        antibrute_delay = aa_slider("\aCDCDCDFFDelay", 0, 3, 0,true,"t",1),
        space_fl2 = fakelag_label(" "),

        import = fakelag_button("\aCDCDCDFF Export Settings",function ()
            local state_name = ui.get(menu.aa.state)
            local tbl = menu.aa[state_name]
            if tbl then
                local config_data = {}
                local function collect(t, path)
                    path = path or ""
                    for k, v in pairs(t) do
                        local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
                        if is_element(v) then
                            local tp = ui.type(v)
                            if tp == "color_picker" then
                                config_data[p] = {ui.get(v)}
                            elseif tp == "multiselect" then
                                config_data[p] = ui.get(v)
                            elseif tp == "hotkey" then
                                local s, bt, kc = ui.get(v)
                                config_data[p] = {s, bt, kc}
                            elseif tp ~= "button" then
                                config_data[p] = {ui.get(v)}
                            end
                        elseif type(v) == "table" then
                            collect(v, p)
                        end
                    end
                end
                collect(tbl)
                clipboard.set(base64.encode(json.stringify(config_data)))
            end
        end),

        export = fakelag_button("\aCDCDCDFF Import Settings", function ()
            local state_name = ui.get(menu.aa.state)
            local tbl = menu.aa[state_name]
            if tbl then
                local ok, config_data = pcall(function()
                    return json.parse(base64.decode(clipboard.get()))
                end)
                if not ok or type(config_data) ~= "table" then return end
                local function apply(t, path)
                    path = path or ""
                    for k, v in pairs(t) do
                        local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
                        if is_element(v) then
                            local tp = ui.type(v)
                            local val = config_data[p]
                            if val ~= nil then
                                if tp == "color_picker" and type(val) == "table" and #val >= 4 then
                                    ui.set(v, val[1], val[2], val[3], val[4])
                                elseif tp == "multiselect" and type(val) == "table" then
                                    ui.set(v, table.unpack(val))
                                elseif tp == "hotkey" and type(val) == "table" and #val >= 2 then
                                    ui.set(v, htkob[val[2]] or "Always on")
                                elseif tp == "checkbox" then
                                    local setval = type(val) == "table" and val[1] or val
                                    if type(setval) == "boolean" then ui.set(v, setval) end
                                elseif tp ~= "button" and tp ~= "label" then
                                    local setval = type(val) == "table" and val[1] or val
                                    if setval ~= nil then pcall(ui.set, v, setval) end
                                end
                            end
                        elseif type(v) == "table" then
                            apply(v, p)
                        end
                    end
                end
                apply(tbl)
            end
        end),

        reset = fakelag_button("\aCDCDCDFF Reset Settings", function ()
            local state_name = ui.get(menu.aa.state)
            local tbl = menu.aa[state_name]
            if tbl then
                local reset_b64 = 'eyJ5YXcuYm9keV95YXdfdmFsdWVfciI6WzBdLCJ5YXcuZGVsYXkxIjpbMF0sInlhdy55YXdfZXh0cmFfZmxpY2siOlswXSwieWF3Lnlhd19jdXN0b20iOlswXSwiaGlkZGVuLnlhdy55YXdfdmFsdWVfbCI6WzBdLCJ5YXcuYm9keV95YXciOlsiT2ZmIl0sInlhdy55YXdfZXh0cmEiOnt9LCJ5YXcuc3BhY2UxIjpbIlx1MDAwN2I2NzM3OGZmICJdLCJ5YXcueWF3X3ZhbHVlX2wiOlswXSwiaGlkZGVuLnBpdGNoLnBvbG9za2EyIjpbIlx1MDAwN2I2NzM3OGZmICJdLCJ5YXcueWF3X2V4dHJhX3N3YXkiOlswXSwiaGlkZGVuLnlhdy55YXdfdmFsdWVfciI6WzBdLCJ5YXcueWF3IjpbIkJhY2t3YXJkIl0sInlhdy5scl9jaGVja2JveCI6W2ZhbHNlXSwiaGlkZGVuLnBpdGNoLnBvbG9za2EzIjpbIlx1MDAwN2I2NzM3OGZmICJdLCJoaWRkZW4ueWF3LnlhdyI6WyJDdXN0b20iXSwieWF3LmFkZF93YXlzIjpbZmFsc2VdLCJ5YXcueWF3X2ppdHRlcl92YWx1ZV9sIjpbMzddLCJ5YXcuZGVsYXkyIjpbMF0sImhpZGRlbi5waXRjaC5waXRjaCI6WyJEb3duIl0sInlhdy5ib2R5X3lhd19pbnZlcnRlciI6W2ZhbHNlXSwieWF3LmJvZHlfeWF3X3ZhbHVlX2wiOlszN10sInlhdy5zcGFjZSI6WyJcdTAwMDdiNjczNzhmZiAiXSwieWF3LmRlbGF5X3dheXMiOlsxXSwieWF3LnNwYWNlNSI6WyJcdTAwMDdiNjczNzhmZiAiXSwieWF3LmRlbGF5NSI6WzBdLCJ5YXcuZGVsYXk0IjpbMF0sImhpZGRlbi55YXcueWF3X2hpZGRlbiI6WyJcdTAwMDdiNjczNzhmZlxuRW5hYmxlIEhpZGRlbiBGaXJzdCJdLCJ5YXcubGFiZWxfc3dpdGNoIjpbIlx1MDAwN2I2NzM3OGZmXHUwMDA3Q0RDRENERkZEZWxheSJdLCJwaXRjaC5waXRjaCI6WyJEb3duIl0sInlhdy55YXdfaml0dGVyIjpbIk9mZiJdLCJ5YXcuZGVsYXlfbW9kZSI6WyJPbGQiXSwiZXhwbG9pdC5mb3JjZV9sY19sYWJlbCI6WyJcdTAwMDdiNjczNzhmZlx1MDAwN0NEQ0RDREZGRXhwbG9pdCJdLCJ5YXcueWF3X2ppdHRlcl92YWx1ZV9yIjpbLTI3XSwiaGlkZGVuLnlhdy5kZWxheSI6WzBdLCJ5YXcubGFiZWxfb2Zmc2V0IjpbIlx1MDAwN2I2NzM3OGZmXHUwMDA3Q0RDRENERkZPZmZzZXQiXSwieWF3LmRlbGF5MyI6WzBdLCJ5YXcueWF3X3ZhbHVlX3IiOlswXSwieWF3Lnlhd19leHRyYV9yYW5kb21pemUiOlswXSwiaGlkZGVuLnBpdGNoLnBpdGNoX3ZhbHVlIjpbODldLCJleHBsb2l0LmhpZGRlbiI6W2ZhbHNlXSwiaGlkZGVuLnlhdy55YXdfdmFsdWUiOlswXSwieWF3LnNwYWNlNCI6WyJcdTAwMDdiNjczNzhmZiAiXSwieWF3LmxhYmVsX2V4dHJhcyI6WyJcdTAwMDdiNjczNzhmZlx1MDAwN0NEQ0RDREZGQWRkLW9ucyJdLCJ5YXcuc3BhY2UzIjpbIlx1MDAwN2I2NzM3OGZmIl0sInBpdGNoLnBpdGNoX2xhYmVsIjpbIlx1MDAwN2I2NzM3OGZmXHUwMDA3Q0RDRENERkZQaXRjaCJdLCJleHBsb2l0LmZvcmNlX2xjIjpbIk9mZiJdLCJ5YXcubGFiZWxfYm9keV95YXciOlsiXHUwMDA3YjY3Mzc4ZmZcdTAwMDdDRENEQ0RGRkRlc3luYyJdLCJoaWRkZW4ucGl0Y2gucG9sb3NrYTEiOlsiXHUwMDA3YjY3Mzc4ZmZcdTAwMDdDRENEQ0RGRkRlZmVuc2l2ZSJdLCJ5YXcueWF3X2V4dHJhX3NwaW4iOlswXSwicGl0Y2gucGl0Y2hfdmFsdWUiOls4OV0sInlhdy5sYWJlbF9tb2RpZmllciI6WyJcdTAwMDdiNjczNzhmZlx1MDAwN0NEQ0RDREZGTW9kaWZpZXIiXX0='
                local ok, data = pcall(json.parse, base64.decode(reset_b64))
                if not ok then return end
                local function reset_apply(t)
                    for k, v in pairs(t) do
                        if is_element(v) then
                            local tp = ui.type(v)
                            if tp == "checkbox" then ui.set(v, false)
                            elseif tp == "slider" then pcall(ui.set, v, 0)
                            elseif tp ~= "button" and tp ~= "label" then
                                pcall(ui.set, v, ui.get(v))
                            end
                        elseif type(v) == "table" then
                            reset_apply(v)
                        end
                    end
                end
                reset_apply(tbl)
            end
        end),

    },
    features = {
        type = fakelag_combo("\n", {"Visuals", "Rage", "Miscellaneous"}),
        visuals = {
            crosshair           = aa_checkbox("\aCDCDCDFFCrosshair Indicator "),
            crosshair_type      = aa_combo("\n\aCDCDCDFFCrosshair Indicator Selection", {"Modern", "Simple"}),
            watermark_selection = aa_checkbox("\aCDCDCDFFWatermark"),
            watermark_type      = aa_multi("\n\aCDCDCDFFWatermark Selection", {"Watermark", "Brand Watermark", "Text Watermark"}),
            lwm_boxes_enabled   = aa_multi("\n\aCDCDCDFFLWM Boxes", {"Name", "FPS/MS", "Time", "Profile"}),
            custom_watermark    = other_checkbox("\aCDCDCDFFCustom Watermark"),
            prefix_label        = other_label("\aCDCDCDFFCustom Watermark Prefix"),
            custom_prefix       = other_textbox("\aCDCDCDFFCustom Watermark Prefix"),
            custom_prefix_color = other_color("\aCDCDCDFFCustom Watermark Prefix Color"),
            postfix_label       = other_label("\aCDCDCDFFCustom Watermark Postfix"),
            custom_postfix      = other_textbox("\aCDCDCDFFCustom Watermark Postfix"),
            custom_postfix_color        = other_color("\aCDCDCDFFCustom Watermark Postfix Color"),
            custom_prefix_animation     = other_combo("\aCDCDCDFFCustom Watermark Prefix Animation", {"Static", "Gradient", "Rainbow", "Chroma"}),
            custom_postfix_animation    = other_combo("\aCDCDCDFFCustom Watermark Postfix Animation", {"Static", "Gradient", "Rainbow", "Chroma"}),
            custom_prefix_speed         = other_slider("\aCDCDCDFFCustom Watermark Prefix Speed", 1,100,1,true, "",1),
            custom_postfix_speed        = other_slider("\aCDCDCDFFCustom Watermark Postfix Speed", 1,100,1,true, "",1),
            custom_step                 = other_slider("\aCDCDCDFFCustom Watermark Animation Step", 1,100, 25, true, "",1),
            custom_font                 = other_combo("\aCDCDCDFFCustom Watermark Flag", {"Nil","b"}),
            custom_size                 = other_combo("\aCDCDCDFFCustom Watermark Size", {"Nil","+", "-"}),

            manual_arrows        = aa_checkbox("\aCDCDCDFFManual Arrows"),
            manual_arrows_style  = aa_combo("\n\a323232FF \aCDCDCDFFArrow Style", {"Classic", "Rounded", "Simple", "Block"}),

            logs = aa_checkbox("\aCDCDCDFFEvent Logger"),

            aspect_ratio_enable = aa_checkbox("\aCDCDCDFFAspect Ratio"),
            aspect_ratio_value  = aa_slider("\n\a323232FF \aCDCDCDFFAspect ratio value", 80, 250, 178, true, " ", 0.01, {
                [125] = '5:4',
                [133] = '4:3',
                [150] = '3:2',
                [160] = '16:10',
                [178] = '16:9',
                [200] = '2:1'
            }),


            animations          = fakelag_multi("\aCDCDCDFFAnimation Breaker", {"Leaning", "Jitter Legs", "Earthquake"}),
        },
        miscellaneous = {
            airlag = aa_checkbox("\aCDCDCDFFAir-Teleport"),
            airlag_key = aa_hotkey("\a323232FF \aCDCDCDFFAir-Lag Key", true),
            airlag_ticks = aa_slider("\n\a323232FF \aCDCDCDFFAir-Lag Timer", 2, 16, 4,true, "t", 1),

            fastladder = aa_checkbox("\aCDCDCDFFFast Ladder"),
            anti_backstab = aa_checkbox("\aCDCDCDFFAnti-Backstab"),

            recharge = aa_checkbox("\aCDCDCDFFUnsafe DT Recharge"),
            jumpscout = aa_checkbox("\aCDCDCDFFImprove Jump-Scout"),
            aimtools = aa_checkbox("\aCDCDCDFFEnable ".. lua_color .. "Aim-tools"),
            correction = fakelag_checkbox("\aCDCDCDFFAnti-Aim " .. lua_color .. "Correction"),
            predict_enemies = fakelag_checkbox("" .. lua_color .. "Enemies \aCDCDCDFFPredict"),
        },
    },
    config = {
        fakelag_label(" "),
        fakelag_label("\aCDCDCDFFInformation "),
        fakelag_label(" "),
        fakelag_label("\aCDCDCDFFCreated by: "),
        fakelag_label(" "),
        fakelag_label("\aCDCDCDFFCreated at:"),
        aa_label(" "),
        list = aa_list("Presets", {}),

        labelka_other = other_label("\aCDCDCDFFCreate Preset"),
        space02 = other_label(" "),

        name = other_textbox("Name"),

        load = aa_button("\aCDCDCDFFLoad from " .. lua_color .. "local presets",function() load_cfg() end),

        save = other_button("\aCDCDCDFFCreate / Save",function() save_cfg() end),
        delete = other_button("\aCDCDCDFFDelete",function() delete_cfg() end),

        export = aa_button("\aCDCDCDFFExport",function() export(); end),
        import = aa_button("\aCDCDCDFFImport",function() import(clipboard.get()); end)
    }
}

    if ui.get(menu.features.visuals.aspect_ratio_enable) then
        local val = ui.get(menu.features.visuals.aspect_ratio_value) / 100
        client.set_cvar("r_aspectratio", val)
    else
        client.set_cvar("r_aspectratio", 0)
    end

function hexToRgb(hexString)
    local hex = hexString:gsub("^\\a", "a")
    local r = tonumber(hex:sub(2, 3), 16) or 0
    local g = tonumber(hex:sub(4, 5), 16) or 0
    local b = tonumber(hex:sub(6, 7), 16) or 0
    local a = tonumber(hex:sub(8, 9), 16) or 0

    return {r, g, b, a}
end

local function time(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if d > 0 then
        return string.format("%dd %dh %dm %ds", d, h, m, s)
    elseif h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

local lastUpdate = 0
local updateInterval = 1
client.set_event_callback("paint_ui", function()
  local currentTime = globals.realtime()
    if currentTime - lastUpdate >= updateInterval then
        lastUpdate = currentTime
        seconds = seconds + 1
        local db = database.read("time_lua_838383838") or {}
        db.seconds = (db.seconds or 0) + 1
        database.write("time_lua_838383838", db)
    end
    local db = database.read("time_lua_838383838") or {}
    total_time = time(db.seconds or 0)
    serialized_time = time(seconds)
    ui.set(menu.rage.statistics.ts_session, lua_color .. "\aCDCDCDFFThis session time: " .. lua_color .. tostring(serialized_time))
    ui.set(menu.rage.statistics.serialized_time, lua_color .. "\aCDCDCDFFTotal time: " .. lua_color .. tostring(total_time))
end)

ui.set_callback(menu.config.list, function(ref)
    local names = {}
    local db = database.read(cfg_key) or {}
    for k,v in pairs(db) do
        table.insert(names,k)
    end
    ui.set(menu.config.name,names[ui.get(menu.config.list) + 1])
end)
cfg_list = menu.config.list
cfg_text = menu.config.name
update_cfg()

function caesar_encrypt(text, shift)
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        local byte = char:byte()

        if byte >= 65 and byte <= 90 then
            result = result .. string.char((byte - 65 + shift) % 26 + 65)
        elseif byte >= 97 and byte <= 122 then
            result = result .. string.char((byte - 97 + shift) % 26 + 97)
        else
            result = result .. char
        end
    end
    return result
end

function caesar_decrypt(text, shift)
    return caesar_encrypt(text, 26 - shift)
end
local htkob = {
    [0] = "Always on",
    [1] = "On hotkey",
    [2] = "Toggle",
    [3] = "Off hotkey"
}

function import(config_string)
    local success, config_data = pcall(json.parse, config_string)
    if not success or type(config_data) ~= "table" then
        error("cfg error, unexpected error prob.")
    end

    local imported_count = 0

    local function apply_value(path, value_data)
        local element = menu
        for part in path:gmatch("[^.]+") do
            if element and type(element) == "table" then
                element = element[part]
            else
                return false
            end
        end

        if is_element(element) then
            local element_type = ui.type(element)

            if element_type == "color_picker" and type(value_data) == "table" and #value_data >= 4 then
                ui.set(element, value_data[1], value_data[2], value_data[3], value_data[4])
                imported_count = imported_count + 1
                return true
            elseif element_type == "multiselect" and type(value_data) == "table" then
                ui.set(element, value_data)
                imported_count = imported_count + 1
                return true
            elseif element_type == "hotkey" and type(value_data) == "table" and #value_data >= 3 then
                ui.set(element, htkob[value_data[2]])

                imported_count = imported_count + 1
                return true
            elseif type(value_data) == "table" and #value_data > 0 and element_type ~= "button" then
                ui.set(element, value_data[1])
                imported_count = imported_count + 1
                return true
            end
        end
        return false
    end

    local function process_config(data, current_path)
        current_path = current_path or ""

        for key, value in pairs(data) do
            local new_path = current_path .. (current_path == "" and key or "." .. key)

            if type(value) == "table" then
                if value[1] ~= nil then
                    apply_value(new_path, value)
                else
                    process_config(value, new_path)
                end
            else
                apply_value(new_path, {value})
            end
        end
    end

    process_config(config_data)
    return imported_count
end

local function count_table_keys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function export(return_as_string)
    return_as_string = return_as_string or false

    local config_data = {}

    local function collect_elements(menu_table, current_path)
        current_path = current_path or ""

        for key, item in pairs(menu_table) do
            if is_element(item) then
                local element_type = ui.type(item)

                if element_type == "color_picker" then
                    local r, g, b, a = ui.get(item)
                    config_data[current_path .. (current_path == "" and key or "." .. key)] = {r, g, b, a}
                elseif element_type == "multiselect" then
                    config_data[current_path .. (current_path == "" and key or "." .. key)] = ui.get(item)
                elseif element_type == "hotkey" then
                    local state, bind_type, key_code = ui.get(item)
                    config_data[current_path .. (current_path == "" and key or "." .. key)] = {state, bind_type, key_code}
                elseif element_type == "button" then

                else
                    config_data[current_path .. (current_path == "" and key or "." .. key)] = {ui.get(item)}
                end
            elseif type(item) == "table" and not is_element(item) then
                collect_elements(item, current_path .. (current_path == "" and key or "." .. key))
            end
        end
    end

    collect_elements(menu)

    local json_string = json.stringify(config_data)

    if return_as_string then
        return json_string
    else
        if clipboard and clipboard.set then
            clipboard.set(json_string)
        else
            print("Конфиг экспортирован")
        end
        return json_string
    end
end

ui.set_callback(menu.aa.left_checkbox,function(ref)
    if (ui.get(ref)) then
        ui.set(menu.aa.right_checkbox,false)
        ui.set(menu.aa.forward_checkbox,false)
        ui.set(menu.aa.backward_checkbox,false)
        ui.set(menu.aa.freestanding_checkbox,false)
    end
end)
ui.set_callback(menu.aa.right_checkbox,function(ref)
    if (ui.get(ref)) then
        ui.set(menu.aa.left_checkbox,false)
        ui.set(menu.aa.forward_checkbox,false)
        ui.set(menu.aa.backward_checkbox,false)
        ui.set(menu.aa.freestanding_checkbox,false)
    end
end)
ui.set_callback(menu.aa.forward_checkbox,function(ref)
    if (ui.get(ref)) then
        ui.set(menu.aa.right_checkbox,false)
        ui.set(menu.aa.left_checkbox,false)
        ui.set(menu.aa.backward_checkbox,false)
        ui.set(menu.aa.freestanding_checkbox,false)
    end
end)
ui.set_callback(menu.aa.backward_checkbox,function(ref)
    if (ui.get(ref)) then
        ui.set(menu.aa.right_checkbox,false)
        ui.set(menu.aa.forward_checkbox,false)
        ui.set(menu.aa.left_checkbox,false)
        ui.set(menu.aa.freestanding_checkbox,false)
    end
end)
ui.set_callback(menu.aa.freestanding_checkbox,function(ref)
    if (ui.get(ref)) then
        ui.set(menu.aa.right_checkbox,false)
        ui.set(menu.aa.forward_checkbox,false)
        ui.set(menu.aa.left_checkbox,false)
        ui.set(menu.aa.backward_checkbox,false)
    end
end)

ui.set_callback(menu.aa.preset, function(ref)
    local preset_name = ui.get(ref)
    apply_preset_to_all_states(preset_name)
end)

function extra_yaw(t, type, min, max)
    if type == "Spin" then
        local range = max - min
        return min + (t % range)
    elseif type == "Sway" then
        local range = max - min
        local period = range * 2
        local phase = t % period
        if phase > range then
            return max - (phase - range)
        else
            return min + phase
        end
    elseif type == "Randomize" then
        return math.random(min, max)
    elseif type == "Flick" then
        if t % 14 == 0 then
            return math.random(min, max)
        end
        return 0
    end
end
for k,v in pairs(alternative_conditions) do
    local a = {yaw = {}, pitch = {}, body_yaw = {}, settings = {}, hidden = {yaw = {}, pitch = {}, body_yaw = {}}, exploit = {}}

    a["yaw"]["yaw_custom"] = aa_slider("\n ", -180,180,0,true,"°",1)
    a["yaw"]["yaw_value_l"] = aa_slider("\n ", -180,180,0,true,"°",1)
    a["yaw"]["yaw_value_r"] = aa_slider("\n\a323232FF  \aCDCDCDFFRight Limit", -180,180,0,true,"°",1)
    a["yaw"]["space0"] = aa_label(" ")
    a["yaw"]["label_modifier"] = aa_label("\aCDCDCDFFYaw " .. lua_color .. "Jitter")
    a["yaw"]["yaw_jitter"] = aa_combo(" ", {"Off", "Offset", "Custom", "Skitter", "Center", "Ways"})
    a["yaw"]["jitter_lr_mode"]   = aa_checkbox("\n\naCDCDCDFFJitter \a323232FF» \aCDCDCDFFLeft/Right mode")
    a["yaw"]["yaw_jitter_value_l"] = aa_slider("\n\a323232FF \aCDCDCDFFLeft Limit", -180,180,0,true,"°",1)
    a["yaw"]["yaw_jitter_value_r"] = aa_slider("\n\a323232FF \aCDCDCDFFRight Limit", -180,180,0,true,"°",1)
    a["yaw"]["yaw_jitter_amount"]  = aa_slider("\n\a323232FF \aCDCDCDFFJitter Amount", 0,180,35,true,"°",1)
    a["yaw"]["jitter_random"]      = aa_slider("\aCDCDCDFFRandomization", 0,100,15,true,"%",1)
    a["yaw"]["xway_ways"] = aa_slider("\aCDCDCDFFModifier Ways", 2,8,3,true,"w",1)
    a["yaw"]["xway_angle"] = aa_slider("\n\a323232FF \aCDCDCDFFX-Way Angle", 0,180,115,true,"°",1)
    a["yaw"]["space1"] = aa_label(" ")
    a["yaw"]["label_body_yaw"] = aa_label("Body \aCDCDCDFFYaw")
    a["yaw"]["space2"] = aa_label(" ")
    a["yaw"]["body_yaw"] = aa_combo("\n ", {"Off", "Static", "L/R", "Sway"})
    a["yaw"]["body_yaw_value_l"] = aa_slider("\a323232FF \aCDCDCDFFLeft Limit", 0,60,0,true,"°",1)
    a["yaw"]["body_yaw_value_r"] = aa_slider("\a323232FF \aCDCDCDFFRight Limit", 0,60,0,true,"°",1)
    a["yaw"]["space3"] = aa_label("")
    a["yaw"]["label_extras"] = aa_label("\aCDCDCDFFAdd-ons")
    a["yaw"]["yaw_extra"] = aa_multi("\nYaw Extra", {"Spin", "Sway", "Randomize", "Flick"})
    a["yaw"]["yaw_extra_spin"] = aa_slider("\a323232FF \aCDCDCDFFYaw Spin", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_sway"] = aa_slider("\a323232FF \aCDCDCDFFYaw Sway", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_randomize"] = aa_slider("\a323232FF \aCDCDCDFFYaw Randomize", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_flick"] = aa_slider("\a323232FF \aCDCDCDFFYaw Flick", -180,180,0,true,"°",1)
    a["yaw"]["space4"] = aa_label(" ")
    a["yaw"]["label_switch"] = aa_label("\aCDCDCDFFDelay")
    a["yaw"]["delay_mode"] = aa_combo(" ", {"Old", "New"})
    a["yaw"]["delay_ways"] = aa_slider("\n\a323232FF \aCDCDCDFFWays", 1,5,0,true,"w",1)
    a["yaw"]["randomize_delay"] = aa_checkbox("\n\aCDCDCDFFDelay " .. lua_color .. "» \aCDCDCDFFRandomization mode")
    a["yaw"]["add_ways"] = aa_checkbox("\n\aCDCDCDFFDelay " .. lua_color .. "» \aCDCDCDFFWays")
    a["yaw"]["delay1"] = aa_slider("\na323232FF \aCDCDCDFFDelay Limit", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["delay2"] = aa_slider("\n\a323232FF \aCDCDCDFFDelay #2", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["delay3"] = aa_slider("\n\a323232FF \aCDCDCDFFDelay #3", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["delay4"] = aa_slider("\n\a323232FF \aCDCDCDFFDelay #4", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["delay5"] = aa_slider("\n\a323232FF \aCDCDCDFFDelay #5", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["randomize_delay_min"] = aa_slider("\n\a323232FF \aCDCDCDFFMin.", 0, 16, 0, true, "t", 1, {[0] = "OFF"})
    a["yaw"]["randomize_delay_max"] = aa_slider("\n\a323232FF \aCDCDCDFFMax.", 0, 16, 8, true, "t", 1, {[0] = "OFF"})
    a["yaw"]["space5"] = aa_label(" ")
    a["yaw"]["additions"] = other_multi("\n", {"Add-Ons"})
    a["yaw"]["space6"] = other_label(" ")
    a["yaw"]["inverterv2"] = other_checkbox("\aCDCDCDFFBody yaw " .. lua_color .. "» \aCDCDCDFFInvert ")
    a["yaw"]["lr_offset"] = other_checkbox("\aCDCDCDFFYaw " .. lua_color .. "» \aCDCDCDFFLeft - Right mode")

    a["hidden"]["yaw"]["yaw_hidden"] = aa_label("\aCDCDCDFFDefensive")
    a["hidden"]["yaw"]["yaw"] = aa_combo(" ", {"Custom", "L/R"})
    a["hidden"]["yaw"]["yaw_value"] = aa_slider("\n\a323232FF \aCDCDCDFFHidden Yaw Custom", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["yaw_value_l"] = aa_slider("\a323232FF \aCDCDCDFFAdd Left", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["yaw_value_r"] = aa_slider("\a323232FF \aCDCDCDFFAdd Right", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["delay"] = aa_slider("\a323232FF \aCDCDCDFFHidden Yaw Switch", 0,16,0,true,"t",1)

    a["pitch"]["pitch_label"] = aa_label("\aCDCDCDFFPitch")
    a["pitch"]["pitch"] = aa_combo(" ", {"Down", "Up", "Zero", "Random", "Custom"})
    a["pitch"]["pitch_value"] = aa_slider("\a323232FF \aCDCDCDFFPitch Custom", -89,89,89,true,"°",1,{[89]="Down", [-89]="Up",[0]="Zero"})
    a["hidden"]["pitch"]["poloska1"] = aa_label(" ")
    a["hidden"]["pitch"]["poloska2"] = aa_label("\aCDCDCDFFDefensive")
    a["hidden"]["pitch"]["pitch"] = aa_combo(" ", {"Down", "Up", "Zero", "Random", "Custom"})
    a["hidden"]["pitch"]["pitch_value"] = aa_slider("\a323232FF \aCDCDCDFFHidden Pitch Custom", -89,89,89,true,"°",1,{[89]="Down", [-89]="Up",[0]="Zero"})

    a["exploit"]["space8"]         = aa_label("\n ")
    a["exploit"]["force_lc_label"] = aa_label("\aCDCDCDFFDefensive")
    a["exploit"]["force_lc"]       = aa_combo("\nForce Break LC", {"Off", "14t", "8t"})
    a["exploit"]["hidden"]         = other_checkbox("Defensives \aCDCDCDFF» Enable")

    a["exploit"]["def_type_label"] = aa_label("\aCDCDCDFFDefensive System")
    a["exploit"]["def_type"]       = aa_combo("\nDefensive System", {"Hidden", "New"})
    a["new_def"] = {}
    a["new_def"]["sp0"]           = aa_label("  ")
    a["new_def"]["enable"]        = aa_label("\aCDCDCDFFNew Defensive")
    a["new_def"]["defensive_on"]  = aa_multi("\nWork on", {"Double tap", "Hide shots"})
    a["new_def"]["def_mode"]      = aa_combo("\nMode", {"On peek", "Always on"})
    a["new_def"]["sp1"]           = aa_label("  ")
    a["new_def"]["toggle_builder"]     = aa_checkbox("\aCDCDCDFFEnable Builder")
    a["new_def"]["duration"]           = aa_slider("\n\a323232FF \aCDCDCDFFDuration", 1, 15, 15, true, "t", 1, {[15] = "Maximum"})
    a["new_def"]["sp2"]                = aa_label("  ")
    a["new_def"]["yaw_label"]          = aa_label("\aCDCDCDFFYaw")
    a["new_def"]["yaw"]                = aa_combo("\nYaw Type", {"Off", "180", "Spin", "Distortion", "Sway", "Freestand"})
    a["new_def"]["speed"]              = aa_slider("\n\a323232FF \aCDCDCDFFYaw Speed",  1, 17, 4, true, "t")
    a["new_def"]["offset"]             = aa_slider("\n\a323232FF \aCDCDCDFFYaw Offset", -180, 180, 0, true, "°")
    a["new_def"]["yaw_left_right"]     = aa_checkbox("\n\aCDCDCDFFYaw \a323232FF» \aCDCDCDFFLeft/Right mode")
    a["new_def"]["left"]               = aa_slider("\n\a323232FF \aCDCDCDFFLeft",  -180, 180, 0, true, "°")
    a["new_def"]["right"]              = aa_slider("\n\a323232FF \aCDCDCDFFRight", -180, 180, 0, true, "°")
    a["new_def"]["yaw_generation"]     = aa_checkbox("\n\aCDCDCDFFYaw \a323232FF» \aCDCDCDFFGeneration")
    a["new_def"]["min_gen"]            = aa_slider("\n\a323232FF \aCDCDCDFFMin", -180, 180, -20, true, "°")
    a["new_def"]["max_gen"]            = aa_slider("\n\a323232FF \aCDCDCDFFMax",  -180, 180,  20, true, "°")
    a["new_def"]["sp3"]                = aa_label("  ")
    a["new_def"]["pitch_label"]        = aa_label("\aCDCDCDFFPitch")
    a["new_def"]["pitch_mode"]         = aa_combo("\nPitch Mode", {"Static", "Spin", "Sway", "Jitter", "Cycling", "Random"})
    a["new_def"]["pitch_speed"]        = aa_slider("\n\a323232FF \aCDCDCDFFPitch Speed", 1, 17, 2, true, "t")
    a["new_def"]["pitch_min_max"]      = aa_checkbox("\n\aCDCDCDFFPitch \a323232FF» \aCDCDCDFFMin/Max mode")
    a["new_def"]["pitch_height_based"] = aa_checkbox("\n\aCDCDCDFFPitch \a323232FF» \aCDCDCDFFHeight based")
    a["new_def"]["pitch"]              = aa_slider("\n\a323232FF \aCDCDCDFFPitch",     -89, 89, 0,  true, "°")
    a["new_def"]["pitch_min"]          = aa_slider("\n\a323232FF \aCDCDCDFFPitch Min", -89, 89, -30, true, "°")
    a["new_def"]["pitch_max"]          = aa_slider("\n\a323232FF \aCDCDCDFFPitch Max",  -89, 89, 30,  true, "°")
    a["new_def"]["sp4"]                = aa_label("  ")
    a["new_def"]["delay_label"]        = aa_label("\aCDCDCDFFDelay")
    a["new_def"]["delay"]              = aa_slider("\n\a323232FF \aCDCDCDFFBody Delay",     1, 34, 1,  true, "t", 1, {[1] = "OFF"})
    a["new_def"]["delay_min"]          = aa_slider("\n\a323232FF \aCDCDCDFFDelay Min",      1, 34, 1,  true, "t", 1, {[1] = "OFF"})
    a["new_def"]["delay_max"]          = aa_slider("\n\a323232FF \aCDCDCDFFDelay Max",      1, 34, 34, true, "t", 1, {[1] = "OFF"})
    a["new_def"]["freeze_chance"]      = aa_slider("\n\a323232FF \aCDCDCDFFFreeze Chance",  1, 100, 18, true, "%", 1)
    a["new_def"]["freeze_time"]        = aa_slider("\n\a323232FF \aCDCDCDFFFreeze Time",    1, 200, 30, true, "ms", 1)
    a["new_def"]["addons"]             = aa_multi("\nDelay \a323232FF» \aCDCDCDFFAdd-ons", {"Randomize Delay Ticks", "Freeze-Inverter"})

    menu.aa[v] = a
    local function hide_all(tbl)
        for _, el in pairs(tbl) do
            if type(el) == "number" then
                ui.set_visible(el, false)
            elseif type(el) == "table" then
                if is_element(el) then
                    el:set_visible(false)
                else
                    hide_all(el)
                end
            end
        end
    end
    hide_all(a)
end

local function depend_table(tbl, visible)
    if type(tbl) == 'table' then
        if is_element(tbl) then
            tbl:set_visible(visible)
        else
            for _, v in pairs(tbl) do
                depend_table(v, visible)
            end
        end

    elseif type(tbl) == 'number' then
        ui.set_visible(tbl, visible)
    end
end
local mouse_click = false
local mouse_hold = false
function rec(x, y, w, h, radius, r, g, b, a)
    radius = math.min(w/2, h/2, radius)
    renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
    renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
    renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
    renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
end
rec_outline = function(x, y, w, h, radius, thickness, color)
    radius = math.min(w/2, h/2, radius)
    local r, g, b, a = unpack(color)
    if radius == 1 then
        renderer.rectangle(x, y, w, thickness, r, g, b, a)
        renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
    else
        renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
        renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
        renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
        renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
        renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
        renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
        renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
    end
end
glow_module = function(x, y, w, h, width, rounding, accent)
    local thickness = 1
    local offset = 0
    local r, g, b, a = unpack(accent)
    for k = 0, width do
        if a * (k/width)^(1) > 5 then
            local accent = {r, g, b, a * (k/width)^(2)}
            rec_outline(x + (k - width - offset)*thickness, y + (k - width - offset) * thickness, w - (k - width - offset)*thickness*2, h + 1 - (k - width - offset)*thickness*2, rounding + thickness * (width - k + offset), thickness, accent)
        end
    end
end
function roundedBlur(x, y, width, height, radius)
    radius = math.min(width/2, height/2, radius)
    if not entity.get_local_player() or not entity.is_alive(entity.get_local_player()) then return end
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    renderer.blur(x + radius, y + radius, width - 2 * radius, height - 2 * radius)

    renderer.blur(x + radius, y, width - 2 * radius, radius)
    renderer.blur(x + radius, y + height - radius, width - 2 * radius, radius)
    renderer.blur(x, y + radius, radius, height - 2 * radius)
    renderer.blur(x + width - radius, y + radius, radius, height - 2 * radius)

    for i = 0, radius do
        for j = 0, radius do
            local dist = math.sqrt((radius - i) * (radius - i) + (radius - j) * (radius - j))
            if dist <= radius then
                renderer.blur(x + i, y + j, 1, 1)
            end
        end
    end

    for i = 0, radius do
        for j = 0, radius do
            local dist = math.sqrt(i * i + (radius - j) * (radius - j))
            if dist <= radius then
                renderer.blur(x + width - radius + i, y + j, 1, 1)
            end
        end
    end

    for i = 0, radius do
        for j = 0, radius do
            local dist = math.sqrt((radius - i) * (radius - i) + j * j)
            if dist <= radius then
                renderer.blur(x + i, y + height - radius + j, 1, 1)
            end
        end
    end

    for i = 0, radius do
        for j = 0, radius do
            local dist = math.sqrt(i * i + j * j)
            if dist <= radius then
                renderer.blur(x + width - radius + i, y + height - radius + j, 1, 1)
            end
        end
    end
end

math.randomseed(globals.tickcount())
local log_queue = {}
local log_height, log_spacing, log_lifetime = 30, 5, 5
local test_logs_added = false
logs = {
    add = function(text)
        local _, screen_h = client.screen_size()
        local h, m, s, ms = client.system_time()
        local create_time = h * 3600 + m * 60 + s + ms / 1000
        local side = math.random(0, 1) == 0 and -1 or 1
        table.insert(log_queue, {text, screen_h - 80, 0, false, create_time, "hit", side})
    end,

    add_typed = function(text, log_type)
        local _, screen_h = client.screen_size()
        local h, m, s, ms = client.system_time()
        local create_time = h * 3600 + m * 60 + s + ms / 1000
        local side = math.random(0, 1) == 0 and -1 or 1
        table.insert(log_queue, {text, screen_h - 80, 0, false, create_time, log_type or "hit", side})
    end,

    render = function()
        local screen_w, screen_h = client.screen_size()
        local h, m, s, ms = client.system_time()
        local current_time = h * 3600 + m * 60 + s + ms / 1000
        local realtime = globals.realtime()

        local colors = {
            hit     = {121, 174, 252},
            miss    = {255, 50, 50},
            warning = {255, 215, 0}
        }

        if ui.is_menu_open() and not test_logs_added then
            test_logs_added = true
            logs.add("Hit sm_metan in head for 296 damage")
            logs.add_typed("Harmed by ieoieoieo in stomach", "warning")
            logs.add_typed("Missed 1ga4 in stomach due to spread", "miss")
        end

        if not ui.is_menu_open() and test_logs_added then
            test_logs_added = false
            log_queue = {}
        end

        for i = #log_queue, 1, -1 do
            local v = log_queue[i]
            if not ui.is_menu_open() and (current_time - v[5] > log_lifetime) then
                v[4] = true
            end
            local should_hide = (#log_queue - i >= 6) or v[4]

            v[3] = interface.animate(v[3], should_hide and 0 or 1, 12)
        end

        local base_y = screen_h - 110
        local current_offset = 0

        for i = #log_queue, 1, -1 do
            local v = log_queue[i]
            if v[3] <= 0.001 then goto continue end

            local ease_io = v[3] < 0.5 and 2 * v[3] * v[3] or 1 - math.pow(-2 * v[3] + 2, 2) / 2
            local fast_fade = math.pow(v[3], 1.8)
            local move_ease = 1 - math.pow(1 - v[3], 3)

            local pad, gap, block_h = 10, 4, 24
            local label_text = "overflame"
            local log_type = v[6] or "hit"
            local theme_clr = colors[log_type] or colors.hit
            local fly_direction = v[7] or 1

            local label_w = renderer.measure_text("b", label_text)
            local block1_w = pad + label_w + pad
            local msg_w = renderer.measure_text("", v[1])
            local block2_w = pad + msg_w + pad
            local total_w = block1_w + gap + block2_w

            local target_y = base_y - current_offset
            v[2] = interface.animate(v[2], target_y, 10)
            current_offset = current_offset + (block_h + log_spacing + 5) * ease_io

            local alpha = math.floor(255 * fast_fade)

            local x_offset = (1 - move_ease) * 500 * fly_direction
            local center_x = (screen_w / 2) + x_offset

            local x1 = math.floor(center_x - total_w / 2)
            local x2 = x1 + block1_w + gap
            local render_y = math.floor(v[2] - 13)
            local text_y = math.floor(v[2] - 5)

            local function draw_log_block(bx, bw, bh)
                if alpha < 5 then return end

                roundedBlur(bx, render_y, bw, bh, 4)
                rec(bx, render_y, bw, bh, 4, 20, 20, 20, alpha)

                rec_outline(bx, render_y, bw, bh, 4, 1, {10, 10, 10, alpha})
                rec_outline(bx + 1, render_y + 1, bw - 2, bh - 2, 4, 1, {55, 55, 55, alpha})

                local pulse = math.sin(realtime * 4) * 0.5 + 0.5
                local pa = math.floor(alpha * (0.4 + 0.6 * pulse))
                renderer.gradient(bx + 6, render_y + bh - 2, (bw - 12) / 2, 2, theme_clr[1], theme_clr[2], theme_clr[3], 0, theme_clr[1], theme_clr[2], theme_clr[3], pa, true)
                renderer.gradient(bx + 6 + (bw - 12) / 2, render_y + bh - 2, (bw - 12) / 2, 2, theme_clr[1], theme_clr[2], theme_clr[3], pa, theme_clr[1], theme_clr[2], theme_clr[3], 0, true)
            end

            draw_log_block(x1, block1_w, block_h)
            draw_log_block(x2, block2_w, block_h)

            if alpha > 10 then

                local gx = x1 + pad
                for ci = 1, #label_text do
                    local ch = label_text:sub(ci, ci)
                    local wave = math.sin(realtime * 3 + ci * 0.3) * 0.5 + 0.5
                    local r = math.floor(theme_clr[1] + (255 - theme_clr[1]) * wave)
                    local g = math.floor(theme_clr[2] + (255 - theme_clr[2]) * wave)
                    local b = math.floor(theme_clr[3] + (255 - theme_clr[3]) * wave)
                    renderer.text(gx, text_y - 2, r, g, b, alpha, "b", 0, ch)
                    gx = gx + renderer.measure_text("b", ch)
                end

                renderer.text(x2 + pad, text_y - 2, 215, 215, 215, alpha, "", 0, v[1])
            end

            ::continue::
        end

        for i = #log_queue, 1, -1 do
            if log_queue[i][3] <= 0.001 then table.remove(log_queue, i) end
        end
    end,
}

function click(x,y,w,h)
    local mouse_x, mouse_y = ui.mouse_position()
    local ret = {false,false,false}
    if (mouse_x >= x and mouse_y >= y and mouse_x <= x + w and mouse_y <= y + h) then
        ret[3] = true
        if (mouse_hold) then
            ret[2] = true
        end
        if (mouse_click) then
            ret[1] = true
            mouse_click = false
        end
    end
    return ret
end
for k,v in pairs(referencesth) do
    ui.set_visible(v, false)
end
contains = function(tbl, arg)
    for index, value in next, tbl do
        if value == arg then
            return true end
        end
    return false
end
client.set_event_callback("shutdown", function()
    for k,v in pairs(referencesth) do
        ui.set_visible(v, true)
    end
end)
local mleft = false;
local mright = false
local mforward = false
local mbackward = false
local fs = false

local anim_b = 0
local anim_e = 0
local anim_t = 0
local anim_a = 0

local anim_b_active = false
local anim_e_active = false
local anim_t_active = false
local anim_a_active = false

local function hsl_to_rgb(h, s, l)
    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
    end
    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end
function hsv_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return r, g, b
end
function darker(color1, percent)
    return {r = color1.r * percent / 100, g = color1.g * percent / 100, b = color1.b * percent / 100, a = color1.a}
end
local animation_time1 =0
local animation_time12 =0
function utf8_chars(text)
    local chars = {}
    for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, char)
    end
    return chars
end
function rgbToHex(r, g, b, a)
    r = math.max(0, math.min(255, r))
    g = math.max(0, math.min(255, g))
    b = math.max(0, math.min(255, b))
    a = math.max(0, math.min(255, a))
    return string.format("\a%02X%02X%02X%02X", r, g, b, a)
end
function animate_custom1(text, speed, color, type)
    animation_time12 = animation_time12 + globals.absoluteframetime() * (speed or 1)

    if type == "Static" then
        return rgbToHex(color.r, color.g, color.b, color.a) .. text
    elseif type == "Gradient" or type == "Chroma" then
        local chars = utf8_chars(text)
        local result = ""

        for i, char in ipairs(chars) do
            if type == "Gradient" then
                local offset = (i - 1) * (ui.get(menu.features.visuals.custom_step) / 100)
                local time = animation_time12 + offset
                local t = (math.sin(time * math.pi * 2) + 1) / 2
                local r = math.floor(math.max(0, darker(color,40).r) * (1 - t) + color.r * t)
                local g = math.floor(math.max(0, darker(color,40).g) * (1 - t) + color.g * t)
                local b = math.floor(math.max(0, darker(color,40).b) * (1 - t) + color.b * t)
                local colour = string.format("\a%02X%02X%02X%02X", r, g, b, color.a)
                result = result .. colour .. char
            else
                local hue = (animation_time12 * 0.5 + i * (ui.get(menu.features.visuals.custom_step) / 100)) % 1
                local r, g, b = hsl_to_rgb(hue, 1, 0.5)
                result = result .. string.format("\a%02X%02X%02X%02X%s", r, g, b, color.a, char)
            end
        end
        return result
    elseif type == "Rainbow" then
        local hue = (animation_time12 * 0.1) % 1
        local r, g, b = hsv_to_rgb(hue, 1, 1)
        local hex = string.format("\a%02X%02X%02X%02X", r * 255, g * 255, b * 255, color.a)

        return hex .. text
    else
        return "\a" .. color .. text
    end
end
function animate_custom(text, speed, color, type)
    animation_time1 = animation_time1 + globals.absoluteframetime() * (speed or 1)

    if type == "Static" then
        return rgbToHex(color.r, color.g, color.b, color.a) .. text
    elseif type == "Gradient" or type == "Chroma" then
        local chars = utf8_chars(text)
        local result = ""

        for i, char in ipairs(chars) do
            if type == "Gradient" then
                local offset = (i - 1) * (ui.get(menu.features.visuals.custom_step) / 100)
                local time = animation_time1 + offset
                local t = (math.sin(time * math.pi * 2) + 1) / 2
                local r = math.floor(math.max(0, darker(color,40).r) * (1 - t) + color.r * t)
                local g = math.floor(math.max(0, darker(color,40).g) * (1 - t) + color.g * t)
                local b = math.floor(math.max(0, darker(color,40).b) * (1 - t) + color.b * t)
                local colour = string.format("\a%02X%02X%02X%02X", r, g, b, color.a)
                result = result .. colour .. char
            else
                local hue = (animation_time1 * 0.5 + i * (ui.get(menu.features.visuals.custom_step) / 100)) % 1
                local r, g, b = hsl_to_rgb(hue, 1, 0.5)
                result = result .. string.format("\a%02X%02X%02X%02X%s", r, g, b, color.a, char)
            end
        end
        return result
    elseif type == "Rainbow" then
        local hue = (animation_time1 * 0.1) % 1
        local r, g, b = hsv_to_rgb(hue, 1, 1)
        local hex = string.format("\a%02X%02X%02X%02X", r * 255, g * 255, b * 255, color.a)

        return hex .. text
    else
        return "\a" .. color .. text
    end
end

local dragging_system = {
    draggings = {},
    active_drag = nil,
    drag_offset_x = 0,
    drag_offset_y = 0,
    snap_threshold = 10,
    dragging_alpha = 0.7,
    menu_open = false,
    initial_positions = {}
}

function dragging_system.create_drag(x, y, w, h, name)
    local drag = {
        x = x, y = y,
        w = w, h = h,
        name = name or "",
        visible = true,
        drag_type = "regular",
        magnet_to = {}
    }
    table.insert(dragging_system.draggings, drag)
    dragging_system.initial_positions[#dragging_system.draggings] = {x = x, y = y}
    return drag
end

function dragging_system.create_text_drag(x, y, w, h, name)
    local drag = {
        x = x, y = y,
        w = w, h = h,
        name = name or "",
        visible = true,
        drag_type = "text",
        magnet_to = {}
    }
    table.insert(dragging_system.draggings, drag)
    dragging_system.initial_positions[#dragging_system.draggings] = {x = x, y = y}
    return drag
end

function dragging_system.set_width(drag, width)
    if drag then drag.w = width end
end

function dragging_system.set_height(drag, height)
    if drag then drag.h = height end
end

function dragging_system.is_visible(drag, state)
    if drag then drag.visible = state end
end
local function draw_magnet_line(x1, y1, x2, y2, r, g, b, a, alpha_mult)
    local final_a = a * (alpha_mult or 1)
    if final_a > 1 then
        renderer.line(x1, y1, x2, y2, r, g, b, final_a)
    end
end
local bg_alpha = 0
local menu_open_anim = 0

local function handle_snapping(drag, realtime)
    local screen_w, screen_h = client.screen_size()

    drag.snap_storage = drag.snap_storage or {}

    local function update_line(id, x1, y1, x2, y2)
        if not drag.snap_storage[id] then
            drag.snap_storage[id] = { alpha = 0, snap_time = realtime, is_snapped = true }
        end
        local s = drag.snap_storage[id]
        s.is_snapped = true
        s.x1, s.y1, s.x2, s.y2 = x1, y1, x2, y2
    end

    local screen_centers = {
        {x = screen_w * 0.25, y = screen_h * 0.5},
        {x = screen_w * 0.5, y = screen_h * 0.5},
        {x = screen_w * 0.75, y = screen_h * 0.5},
        {x = screen_w * 0.5, y = screen_h * 0.25},
        {x = screen_w * 0.5, y = screen_h * 0.75}
    }

    for i, center in ipairs(screen_centers) do
        if math.abs(drag.x + drag.w/2 - center.x) < dragging_system.snap_threshold then
            drag.x = center.x - drag.w/2
            update_line("center_x_" .. i, center.x, 0, center.x, screen_h)
        end
        if math.abs(drag.y + drag.h/2 - center.y) < dragging_system.snap_threshold then
            drag.y = center.y - drag.h/2
            update_line("center_y_" .. i, 0, center.y, screen_w, center.y)
        end
    end

    for i, other in pairs(dragging_system.draggings) do
        if other ~= drag and other.visible then
            if math.abs(drag.x - other.x) < dragging_system.snap_threshold then
                drag.x = other.x
                update_line("left_" .. i, drag.x, math.min(drag.y, other.y), drag.x, math.max(drag.y + drag.h, other.y + other.h))
            end
            if math.abs(drag.y - other.y) < dragging_system.snap_threshold then
                drag.y = other.y
                update_line("top_" .. i, math.min(drag.x, other.x), drag.y, math.max(drag.x + drag.w, other.x + other.w), drag.y)
            end
            if math.abs(drag.x + drag.w - (other.x + other.w)) < dragging_system.snap_threshold then
                drag.x = other.x + other.w - drag.w
                update_line("right_" .. i, drag.x + drag.w, math.min(drag.y, other.y), drag.x + drag.w, math.max(drag.y + drag.h, other.y + other.h))
            end
            if math.abs(drag.y + drag.h - (other.y + other.h)) < dragging_system.snap_threshold then
                drag.y = other.y + other.h - drag.h
                update_line("bottom_" .. i, math.min(drag.x, other.x), drag.y + drag.h, math.max(drag.x + drag.w, other.x + other.w), drag.y + drag.h)
            end
        end
    end

    drag.x = math.max(0, math.min(screen_w - drag.w, drag.x))
    drag.y = math.max(0, math.min(screen_h - drag.h, drag.y))
end

local overflame_beta_ref = nil

local font_ctx_menu = {
    open     = false,
    x        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    w        = 110,
    item_h   = 22,
}
local pos_ctx_menu = {
    open     = false,
    x        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    w        = 110,
    item_h   = 22,
}

local drag_ctx_menu = {
    open     = false,
    drag     = nil,
    x        = 0,
    y        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    items    = {"Default", "Custom"},
    w        = 140,
    item_h   = 22,
}
local reorder_ctx_menu = {
    open     = false,
    drag     = nil,
    x        = 0,
    y        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    items    = {"Reorder Boxes", "Boxes"},
    w        = 140,
    item_h   = 22,
}
local boxes_submenu = {
    open     = false,
    closing  = false,
    x        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    w        = 130,
    item_h   = 22,
    items    = {"Name", "FPS/MS", "Time", "Profile"},
}
local arrow_ctx_menu = {
    open     = false,
    x        = 0,
    anim     = 0,
    open_up  = false,
    anchor_y = 0,
    items    = {"Classic", "Rounded", "Simple", "Block"},
    w        = 120,
    item_h   = 22,
}
local drag_rmb_held = false

local lwm
local lwm_box_order     = {1, 2, 3, 4}
local lwm_reorder_mode  = false
local lwm_drag_slot     = nil
local lwm_drag_offset_x = 0
local lwm_drag_offset_y = 0
local lwm_lmb_held      = false
local lwm_block_drag    = false
local lwm_slot_x        = {0, 0, 0, 0}
local lwm_slot_w        = {0, 0, 0, 0}
local lwm_slot_h        = 0
local lwm_slot_y        = 0
local lwm_anim_x        = {nil, nil, nil, nil}
local prev_mouse_down = false

function dragging_system.render()
    local screen_w, screen_h = client.screen_size()
    local mouse_x, mouse_y = ui.mouse_position()
    local mouse_down = client.key_state(1)
    local mouse_just_clicked = mouse_down and not prev_mouse_down
    local mouse_rmb  = client.key_state(2)
    local realtime = globals.realtime()

    if not mouse_down then lwm_block_drag = false end

    if not ui.is_menu_open() then
        dragging_system.active_drag = nil
        drag_ctx_menu.open    = false
        reorder_ctx_menu.open = false
        arrow_ctx_menu.open   = false
        boxes_submenu.open    = false
        bg_alpha = 0
        menu_open_anim = interface.animate(menu_open_anim, 0, 10)
        if menu_open_anim > 0.01 then
        else
            return
        end
    else
        menu_open_anim = interface.animate(menu_open_anim, 1, 10)
    end

    bg_alpha = interface.animate(bg_alpha, dragging_system.active_drag and 1 or 0, 10)
    if bg_alpha > 0.01 then
        renderer.rectangle(0, 0, screen_w, screen_h, 0, 0, 0, 140 * bg_alpha)
    end

    if not mouse_down then
        dragging_system.active_drag = nil
    end

    for _, drag in pairs(dragging_system.draggings) do
        if drag.snap_storage then
            for _, s in pairs(drag.snap_storage) do
                s.is_snapped = false
            end
        end
    end

    if dragging_system.active_drag and mouse_down then
        dragging_system.active_drag.x = mouse_x - dragging_system.drag_offset_x
        dragging_system.active_drag.y = mouse_y - dragging_system.drag_offset_y
        if dragging_system.active_drag.lock_x ~= nil then
            dragging_system.active_drag.x = dragging_system.active_drag.lock_x
        end
        if dragging_system.active_drag.lock_y ~= nil then
            dragging_system.active_drag.y = dragging_system.active_drag.lock_y
        end
        handle_snapping(dragging_system.active_drag, realtime)
    else
        for _, drag in pairs(dragging_system.draggings) do
            if drag.visible then
                if mouse_x >= drag.x and mouse_x <= drag.x + drag.w and
                   mouse_y >= drag.y and mouse_y <= drag.y + drag.h then
                    if mouse_down and not dragging_system.active_drag and not drag_ctx_menu.open and not reorder_ctx_menu.open and not reorder_ctx_menu.closing and not lwm_block_drag then
                        if not (drag == lwm and lwm_reorder_mode) then
                            dragging_system.active_drag = drag
                            dragging_system.drag_offset_x = mouse_x - drag.x
                            dragging_system.drag_offset_y = mouse_y - drag.y
                        end
                    end
                    if mouse_rmb and not drag_rmb_held then
                        local over_overflame = overflame_beta_ref and overflame_beta_ref.visible and
                            mouse_x >= overflame_beta_ref.x and mouse_x <= overflame_beta_ref.x + overflame_beta_ref.w and
                            mouse_y >= overflame_beta_ref.y and mouse_y <= overflame_beta_ref.y + overflame_beta_ref.h + 24
                        if drag ~= overflame_beta_ref and not over_overflame then
                            local already_open = (drag_ctx_menu.open and drag_ctx_menu.drag == drag)
                                or (arrow_ctx_menu.open and drag == arrow_drag)
                            if already_open then
                                drag_ctx_menu.open    = false; drag_ctx_menu.closing    = true
                                reorder_ctx_menu.open = false; reorder_ctx_menu.closing = true
                                arrow_ctx_menu.open   = false; arrow_ctx_menu.closing   = true
                            else
                            local screen_w, screen_h = client.screen_size()
                            local in_lower = drag.y + drag.h / 2 > screen_h / 2
                            if drag == arrow_drag then
                                arrow_ctx_menu.w        = math.max(90, drag.w)
                                local ax = math.min(drag.x, screen_w - arrow_ctx_menu.w - 2)
                                arrow_ctx_menu.open     = true
                                arrow_ctx_menu.closing  = false
                                arrow_ctx_menu.x        = ax
                                arrow_ctx_menu.open_up  = in_lower
                                arrow_ctx_menu.anchor_y = in_lower and drag.y or (drag.y + drag.h + 4)
                                arrow_ctx_menu.anim     = 0
                            else
                                if drag == lwm then
                                    local half = math.max(90, math.floor((drag.w - 4) / 2))
                                    drag_ctx_menu.w    = half
                                    reorder_ctx_menu.w = half
                                else
                                    drag_ctx_menu.w = math.max(90, drag.w)
                                end
                                local cx = math.min(drag.x, screen_w - drag_ctx_menu.w - 2)
                                drag_ctx_menu.items    = {"Default", "Custom"}
                                drag_ctx_menu.open     = true
                                drag_ctx_menu.closing  = false
                                drag_ctx_menu.drag     = drag
                                drag_ctx_menu.x        = cx
                                drag_ctx_menu.open_up  = in_lower
                                drag_ctx_menu.anchor_y = in_lower and drag.y or (drag.y + drag.h + 4)
                                drag_ctx_menu.anim     = 0
                                if drag == lwm then
                                    reorder_ctx_menu.open     = true
                                    reorder_ctx_menu.closing  = false
                                    reorder_ctx_menu.drag     = drag
                                    reorder_ctx_menu.x        = cx + drag_ctx_menu.w + 4
                                    reorder_ctx_menu.open_up  = in_lower
                                    reorder_ctx_menu.anchor_y = in_lower and drag.y or (drag.y + drag.h + 4)
                                    reorder_ctx_menu.anim     = 0
                                else
                                    reorder_ctx_menu.open    = false
                                    reorder_ctx_menu.closing = false
                                end
                            end
                            end -- else (not already_open)
                        end
                    end
                end
            end
        end
    end
    drag_rmb_held = mouse_rmb
    prev_mouse_down = mouse_down

    for i, drag in pairs(dragging_system.draggings) do
        if drag.visible or (drag.visible_anim and drag.visible_anim > 0.01) or (drag == arrow_drag) then
            local is_visible = drag.visible
            drag.visible_anim = interface.animate(drag.visible_anim or (is_visible and 1 or 0), is_visible and 1 or 0, 10)
            local box_alpha = drag.visible_anim

            if drag.snap_storage then
                for id, s in pairs(drag.snap_storage) do
                    local target = 0

                    if s.is_snapped then
                        local snap_lifetime = (drag == arrow_drag) and 9999 or 5
                        if realtime - s.snap_time <= snap_lifetime then
                            target = 1
                        end
                    else
                        s.snap_time = realtime
                    end

                    s.alpha = interface.animate(s.alpha, target, 12)

                    if s.alpha > 0.005 then
                        renderer.line(s.x1, s.y1, s.x2, s.y2, 255, 255, 255, 45 * s.alpha)
                    end
                end
            end

            rec(drag.x, drag.y, drag.w, drag.h, 4, 255, 255, 255, 100 * dragging_system.dragging_alpha * box_alpha * menu_open_anim)
            local target_alpha = (dragging_system.active_drag == drag) and 0 or 1

            drag.text_alpha = interface.animate(drag.text_alpha, target_alpha, 10)

            if drag.name and drag.name ~= "" and drag.text_alpha > 0.01 then
                local text_w, text_h = renderer.measure_text(nil, drag.name)

                local text_y
                if drag.label_bottom then
                    text_y = drag.y + drag.h + 10
                else
                    text_y = drag.y - text_h - 5
                end

                local screen_limit = math.max(1, screen_w - drag.w)
                local ratio = math.max(0, math.min(1, drag.x / screen_limit))

                local min_x = drag.x + (text_w / 2)
                local max_x = drag.x + drag.w - (text_w / 2)

                local dynamic_x = min_x + (max_x - min_x) * ratio

                renderer.text(dynamic_x, text_y, 255, 255, 255, 255 * drag.text_alpha * box_alpha * menu_open_anim, "c", 0, drag.name)
            end
        end
    end

    if bg_alpha < 0.2 then
        local screen_centers = {
            {x = screen_w * 0.25, y = screen_h * 0.5},
            {x = screen_w * 0.5, y = screen_h * 0.5},
            {x = screen_w * 0.75, y = screen_h * 0.5},
            {x = screen_w * 0.5, y = screen_h * 0.25},
            {x = screen_w * 0.5, y = screen_h * 0.75}
        }
        for _, center in ipairs(screen_centers) do
            rec(center.x - 2, center.y - 2, 4, 4, 2, 255, 255, 255, 100 * (1 - bg_alpha) * menu_open_anim)
        end
    end

    rec(10, 10, 100, 25, 4, 16, 16, 16, math.floor(255 * menu_open_anim))
    rec_outline(10,     10,     100,    25,     5, 1, {8,  8,  8,  math.floor(200 * menu_open_anim)})
    rec_outline(10 + 1, 10 + 1, 100 - 2, 25 - 2, 5, 1, {50, 50, 50, math.floor(200 * menu_open_anim)})
    renderer.text(20, 17, 255, 255, 255, math.floor(255 * menu_open_anim), "b", 0, "Reset Draggings")

    if mouse_x >= 10 and mouse_x <= 110 and mouse_y >= 10 and mouse_y <= 35 and mouse_down then
        for i, drag in pairs(dragging_system.draggings) do
            local initial = dragging_system.initial_positions[i]
            if initial then drag.x, drag.y = initial.x, initial.y end
        end
    end

    if drag_ctx_menu.open or drag_ctx_menu.closing then
        local ctx    = drag_ctx_menu
        local clr    = {menu_r or 121, menu_g or 174, menu_b or 252}
        local pad_x  = 10
        local pad_y  = 5
        local total_h = pad_y * 2 + #ctx.items * ctx.item_h

        if not ctx.open then
            ctx.anim = interface.animate(ctx.anim, 0, 14)
            if ctx.anim < 0.01 then ctx.closing = false end
        else
            ctx.anim = interface.animate(ctx.anim, 1, 16)
        end

        local alpha    = math.floor(255 * ctx.anim)
        local render_h = total_h
        local slide    = math.floor((1 - ctx.anim) * total_h)
        local bx = ctx.x
        local by
        if ctx.open_up then
            by = ctx.anchor_y - total_h - 4 + slide
        else
            by = ctx.anchor_y + slide
        end

        for gi = 4, 1, -1 do
            local ga = math.floor(20 * (1 - gi / 4) * ctx.anim)
            rec_outline(bx - gi, by - gi, ctx.w + gi * 2, render_h + gi * 2, 5 + gi, 1, {clr[1], clr[2], clr[3], ga})
        end

        rec(bx, by, ctx.w, render_h, 4, 16, 16, 16, alpha)
        rec_outline(bx,     by,     ctx.w,     render_h,     4, 1, {8,  8,  8,  alpha})
        rec_outline(bx + 1, by + 1, ctx.w - 2, render_h - 2, 4, 1, {50, 50, 50, alpha})

        local lw = ctx.w - pad_x * 2
        renderer.gradient(bx + pad_x,          by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], 0,   clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), true)
        renderer.gradient(bx + pad_x + lw / 2, by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), clr[1], clr[2], clr[3], 0,   true)

        local _, th = renderer.measure_text("b", "A")

        for i, name in ipairs(ctx.items) do
            local iy = by + pad_y + (i - 1) * ctx.item_h
            if iy + ctx.item_h > by + render_h then break end

            local item_hovered = ctx.open and mouse_x >= bx and mouse_x <= bx + ctx.w
                and mouse_y >= iy and mouse_y <= iy + ctx.item_h
            local is_default = false
            if ctx.drag then
                for idx, d in pairs(dragging_system.draggings) do
                    if d == ctx.drag then
                        local init = dragging_system.initial_positions[idx]
                        if init then
                            is_default = (math.abs(d.x - init.x) < 2 and math.abs(d.y - init.y) < 2)
                        end
                        break
                    end
                end
            end
            local active = (i == 1 and is_default) or (i == 2 and not is_default)

            if active then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, clr[1], clr[2], clr[3], math.floor(28 * ctx.anim))
                renderer.gradient(bx+3, iy+4,                    2, (ctx.item_h-8)/2, clr[1],clr[2],clr[3],0,     clr[1],clr[2],clr[3],alpha, false)
                renderer.gradient(bx+3, iy+4+(ctx.item_h-8)/2,   2, (ctx.item_h-8)/2, clr[1],clr[2],clr[3],alpha, clr[1],clr[2],clr[3],0,     false)
            elseif item_hovered then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, 255, 255, 255, math.floor(10 * ctx.anim))
            end

            local tr = active and clr[1] or (item_hovered and 230 or 150)
            local tg = active and clr[2] or (item_hovered and 230 or 150)
            local tb = active and clr[3] or (item_hovered and 230 or 150)

            local label_y = iy + math.floor((ctx.item_h - th) / 2)
            renderer.text(bx + pad_x + 6, label_y, tr, tg, tb, alpha, "b", 0, name)

            if item_hovered and mouse_down then
                if name == "Default" and ctx.drag then
                    for idx, d in pairs(dragging_system.draggings) do
                        if d == ctx.drag then
                            local init = dragging_system.initial_positions[idx]
                            if init then d.x, d.y = init.x, init.y end
                            break
                        end
                    end
                    if ctx.drag == lwm then lwm_reorder_mode = false end
                elseif name == "Custom" and ctx.drag == lwm then
                    lwm_reorder_mode = false
                end
                drag_ctx_menu.open = false; drag_ctx_menu.closing = true
                reorder_ctx_menu.open = false; reorder_ctx_menu.closing = true
            end
        end

        local outside = not (mouse_x >= bx and mouse_x <= bx + ctx.w
            and mouse_y >= by and mouse_y <= by + total_h)
        local over_reorder = reorder_ctx_menu.open and
            mouse_x >= reorder_ctx_menu.x and mouse_x <= reorder_ctx_menu.x + reorder_ctx_menu.w
        if outside and not over_reorder and mouse_down then
            drag_ctx_menu.open = false; drag_ctx_menu.closing = true
            reorder_ctx_menu.open = false; reorder_ctx_menu.closing = true
        end
    end

    if reorder_ctx_menu.open or reorder_ctx_menu.closing then
        local ctx    = reorder_ctx_menu
        local clr    = {menu_r or 121, menu_g or 174, menu_b or 252}
        local pad_x  = 10
        local pad_y  = 5
        local items  = {"Reorder Boxes", "Boxes"}
        local total_h = pad_y * 2 + #items * ctx.item_h

        if not ctx.open then
            ctx.anim = interface.animate(ctx.anim, 0, 14)
            if ctx.anim < 0.01 then ctx.closing = false end
        else
            ctx.anim = interface.animate(ctx.anim, 1, 16)
        end

        local alpha    = math.floor(255 * ctx.anim)
        local render_h = total_h
        local slide    = math.floor((1 - ctx.anim) * total_h)
        local bx = ctx.x
        local by
        if ctx.open_up then
            by = ctx.anchor_y - total_h - 4 + slide
        else
            by = ctx.anchor_y + slide
        end

        for gi = 4, 1, -1 do
            local ga = math.floor(20 * (1 - gi / 4) * ctx.anim)
            rec_outline(bx - gi, by - gi, ctx.w + gi * 2, render_h + gi * 2, 5 + gi, 1, {clr[1], clr[2], clr[3], ga})
        end

        rec(bx, by, ctx.w, render_h, 4, 16, 16, 16, alpha)
        rec_outline(bx,     by,     ctx.w,     render_h,     4, 1, {8,  8,  8,  alpha})
        rec_outline(bx + 1, by + 1, ctx.w - 2, render_h - 2, 4, 1, {50, 50, 50, alpha})

        local lw = ctx.w - pad_x * 2
        renderer.gradient(bx + pad_x,          by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], 0,   clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), true)
        renderer.gradient(bx + pad_x + lw / 2, by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), clr[1], clr[2], clr[3], 0,   true)

        local _, th = renderer.measure_text("b", "A")

        for i, name in ipairs(items) do
            local iy = by + pad_y + (i - 1) * ctx.item_h
            if iy + ctx.item_h > by + render_h then break end

            local item_hovered = ctx.open and mouse_x >= bx and mouse_x <= bx + ctx.w
                and mouse_y >= iy and mouse_y <= iy + ctx.item_h

            local active = (name == "Reorder Boxes" and lwm_reorder_mode)

            if active then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, clr[1], clr[2], clr[3], math.floor(28 * ctx.anim))
                renderer.gradient(bx+3, iy+4,                    2, (ctx.item_h-8)/2, clr[1],clr[2],clr[3],0,     clr[1],clr[2],clr[3],alpha, false)
                renderer.gradient(bx+3, iy+4+(ctx.item_h-8)/2,   2, (ctx.item_h-8)/2, clr[1],clr[2],clr[3],alpha, clr[1],clr[2],clr[3],0,     false)
            elseif item_hovered then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, 255, 255, 255, math.floor(10 * ctx.anim))
            end

            local tr = active and clr[1] or (item_hovered and 230 or 150)
            local tg = active and clr[2] or (item_hovered and 230 or 150)
            local tb = active and clr[3] or (item_hovered and 230 or 150)

            local label_y = iy + math.floor((ctx.item_h - th) / 2)
            renderer.text(bx + pad_x + 6, label_y, tr, tg, tb, alpha, "b", 0, name)

            if name == "Boxes" then
                local arrow_sym = "›"
                local aw = renderer.measure_text("b", arrow_sym)
                renderer.text(bx + ctx.w - pad_x - aw - 2, label_y, tr, tg, tb, alpha, "b", 0, arrow_sym)

                if item_hovered and ctx.open and mouse_just_clicked then
                    if not boxes_submenu.open then
                        local sw, sh = client.screen_size()
                        boxes_submenu.open     = true
                        boxes_submenu.closing  = false
                        boxes_submenu.x        = bx + ctx.w + 4
                        boxes_submenu.open_up  = ctx.open_up
                        boxes_submenu.anchor_y = ctx.anchor_y
                        boxes_submenu.anim     = boxes_submenu.anim or 0
                        if boxes_submenu.x + boxes_submenu.w > sw - 2 then
                            boxes_submenu.x = bx - boxes_submenu.w - 4
                        end
                    end
                end
            end

            if item_hovered and mouse_down then
                if name == "Reorder Boxes" and ctx.drag == lwm then
                    lwm_reorder_mode = not lwm_reorder_mode
                    lwm_block_drag = true
                end
                if name ~= "Boxes" then
                    reorder_ctx_menu.open = false; reorder_ctx_menu.closing = true
                    drag_ctx_menu.open = false; drag_ctx_menu.closing = true
                    boxes_submenu.open = false; boxes_submenu.closing = true
                end
            end
        end

        local over_reorder = mouse_x >= bx and mouse_x <= bx + ctx.w and mouse_y >= by and mouse_y <= by + total_h
        local sub_bx = boxes_submenu.x
        local sub_by_approx = ctx.open_up and (ctx.anchor_y - (pad_y*2 + 4*ctx.item_h) - 4) or ctx.anchor_y
        local over_submenu = boxes_submenu.open and
            mouse_x >= sub_bx and mouse_x <= sub_bx + boxes_submenu.w and
            mouse_y >= sub_by_approx - 40 and mouse_y <= sub_by_approx + (pad_y*2 + 4*ctx.item_h) + 40

        if not over_reorder and not over_submenu and ctx.open then
            boxes_submenu.open = false; boxes_submenu.closing = true
        end

        local outside = not over_reorder
        if outside and not over_submenu and mouse_down then
            reorder_ctx_menu.open = false; reorder_ctx_menu.closing = true
            drag_ctx_menu.open = false; drag_ctx_menu.closing = true
            boxes_submenu.open = false; boxes_submenu.closing = true
        end
    end

    if boxes_submenu.open or boxes_submenu.closing then
        local ctx   = boxes_submenu
        local clr   = {menu_r or 121, menu_g or 174, menu_b or 252}
        local pad_x = 10
        local pad_y = 5
        local items = {"Name", "FPS/MS", "Time", "Profile"}
        local total_h = pad_y * 2 + #items * ctx.item_h

        if not ctx.open then
            ctx.anim = interface.animate(ctx.anim, 0, 14)
            if ctx.anim < 0.01 then ctx.closing = false end
        else
            ctx.anim = interface.animate(ctx.anim, 1, 16)
        end

        local alpha   = math.floor(255 * ctx.anim)
        local slide   = math.floor((1 - ctx.anim) * total_h)
        local bx = ctx.x
        local by
        if ctx.open_up then
            by = ctx.anchor_y - total_h - 4 + slide
        else
            by = ctx.anchor_y + slide
        end

        for gi = 4, 1, -1 do
            local ga = math.floor(20 * (1 - gi / 4) * ctx.anim)
            rec_outline(bx - gi, by - gi, ctx.w + gi * 2, total_h + gi * 2, 5 + gi, 1, {clr[1], clr[2], clr[3], ga})
        end

        rec(bx, by, ctx.w, total_h, 4, 16, 16, 16, alpha)
        rec_outline(bx,     by,     ctx.w,     total_h,     4, 1, {8,  8,  8,  alpha})
        rec_outline(bx + 1, by + 1, ctx.w - 2, total_h - 2, 4, 1, {50, 50, 50, alpha})

        local lw = ctx.w - pad_x * 2
        renderer.gradient(bx + pad_x,          by + total_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], 0,   clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), true)
        renderer.gradient(bx + pad_x + lw / 2, by + total_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), clr[1], clr[2], clr[3], 0,   true)

        local _, th = renderer.measure_text("b", "A")
        local cur_boxes = (menu.features and menu.features.visuals and menu.features.visuals.lwm_boxes_enabled)
            and ui.get(menu.features.visuals.lwm_boxes_enabled) or {}

        for i, name in ipairs(items) do
            local iy = by + pad_y + (i - 1) * ctx.item_h
            local item_hovered = ctx.open and mouse_x >= bx and mouse_x <= bx + ctx.w
                and mouse_y >= iy and mouse_y <= iy + ctx.item_h

            local enabled = false
            for _, v in ipairs(cur_boxes) do
                if v == name then enabled = true; break end
            end

            local cb_size = 10
            local cb_x = bx + pad_x + 2
            local cb_y = iy + math.floor((ctx.item_h - cb_size) / 2)

            if enabled then
                rec(cb_x, cb_y, cb_size, cb_size, 2, clr[1], clr[2], clr[3], math.floor(200 * ctx.anim))
                renderer.line(cb_x + 2, cb_y + 5, cb_x + 4, cb_y + 7, 255, 255, 255, alpha)
                renderer.line(cb_x + 4, cb_y + 7, cb_x + 8, cb_y + 3, 255, 255, 255, alpha)
            else
                rec_outline(cb_x, cb_y, cb_size, cb_size, 2, 1, {80, 80, 80, alpha})
            end

            if item_hovered then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, 255, 255, 255, math.floor(8 * ctx.anim))
            end

            local label_y = iy + math.floor((ctx.item_h - th) / 2)
            local tr = enabled and clr[1] or (item_hovered and 200 or 120)
            local tg = enabled and clr[2] or (item_hovered and 200 or 120)
            local tb = enabled and clr[3] or (item_hovered and 200 or 120)
            renderer.text(bx + pad_x + cb_size + 8, label_y, tr, tg, tb, alpha, "b", 0, name)

            if item_hovered and mouse_just_clicked then
                local new_sel = {}
                if enabled then
                    for _, v in ipairs(cur_boxes) do
                        if v ~= name then table.insert(new_sel, v) end
                    end
                else
                    for _, v in ipairs(cur_boxes) do table.insert(new_sel, v) end
                    table.insert(new_sel, name)
                end
                if #new_sel == 0 then
                    new_sel = {name}
                end
                pcall(function() ui.set(menu.features.visuals.lwm_boxes_enabled, table.unpack(new_sel)) end)
            end
        end

        local over_sub = mouse_x >= bx and mouse_x <= bx + ctx.w and mouse_y >= by and mouse_y <= by + total_h
        local over_reorder_menu = reorder_ctx_menu.open and
            mouse_x >= reorder_ctx_menu.x and mouse_x <= reorder_ctx_menu.x + reorder_ctx_menu.w
        if not over_sub and not over_reorder_menu and mouse_down then
            boxes_submenu.open = false; boxes_submenu.closing = true
        end
    end


    if arrow_ctx_menu.open or arrow_ctx_menu.closing then
        local ctx   = arrow_ctx_menu
        local clr   = {menu_r or 121, menu_g or 174, menu_b or 252}
        local pad_x = 10
        local pad_y = 5
        local total_h = pad_y * 2 + #ctx.items * ctx.item_h

        if not ctx.open then
            ctx.anim = interface.animate(ctx.anim, 0, 14)
            if ctx.anim < 0.01 then ctx.closing = false end
        else
            ctx.anim = interface.animate(ctx.anim, 1, 16)
        end

        local alpha    = math.floor(255 * ctx.anim)
        local render_h = total_h
        local slide    = math.floor((1 - ctx.anim) * total_h)
        local bx = ctx.x
        local by = ctx.open_up and (ctx.anchor_y - total_h - 4 + slide) or (ctx.anchor_y + slide)

        for gi = 4, 1, -1 do
            local ga = math.floor(20 * (1 - gi / 4) * ctx.anim)
            rec_outline(bx - gi, by - gi, ctx.w + gi * 2, render_h + gi * 2, 5 + gi, 1, {clr[1], clr[2], clr[3], ga})
        end
        rec(bx, by, ctx.w, render_h, 4, 16, 16, 16, alpha)
        rec_outline(bx,     by,     ctx.w,     render_h,     4, 1, {8,  8,  8,  alpha})
        rec_outline(bx + 1, by + 1, ctx.w - 2, render_h - 2, 4, 1, {50, 50, 50, alpha})

        local lw = ctx.w - pad_x * 2
        renderer.gradient(bx + pad_x,          by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], 0, clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), true)
        renderer.gradient(bx + pad_x + lw / 2, by + render_h - 2, lw / 2, 2,
            clr[1], clr[2], clr[3], math.floor(100 * ctx.anim), clr[1], clr[2], clr[3], 0, true)

        local _, th = renderer.measure_text("b", "A")
        local style_sym = {Classic = "«»", Rounded = "⮜⮞", Simple = "<>", Block = "◀▶"}
        local cur_style = ui.get(menu.features.visuals.manual_arrows_style)

        for i, name in ipairs(ctx.items) do
            local iy = by + pad_y + (i - 1) * ctx.item_h
            if iy + ctx.item_h > by + render_h then break end

            local item_hovered = ctx.open and mouse_x >= bx and mouse_x <= bx + ctx.w
                and mouse_y >= iy and mouse_y <= iy + ctx.item_h
            local active = (name == cur_style)

            if active then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, clr[1], clr[2], clr[3], math.floor(28 * ctx.anim))
                renderer.gradient(bx + 3, iy + 4,                    2, (ctx.item_h - 8) / 2, clr[1], clr[2], clr[3], 0,     clr[1], clr[2], clr[3], alpha, false)
                renderer.gradient(bx + 3, iy + 4 + (ctx.item_h-8)/2, 2, (ctx.item_h - 8) / 2, clr[1], clr[2], clr[3], alpha, clr[1], clr[2], clr[3], 0,     false)
            elseif item_hovered then
                rec(bx + 3, iy + 1, ctx.w - 6, ctx.item_h - 2, 3, 255, 255, 255, math.floor(10 * ctx.anim))
            end

            local tr = active and clr[1] or (item_hovered and 230 or 150)
            local tg = active and clr[2] or (item_hovered and 230 or 150)
            local tb = active and clr[3] or (item_hovered and 230 or 150)
            local label_y = iy + math.floor((ctx.item_h - th) / 2)
            renderer.text(bx + pad_x + 6, label_y, tr, tg, tb, alpha, "b", 0, name)

            local sym = style_sym[name] or ""
            local sw = renderer.measure_text("", sym)
            renderer.text(bx + ctx.w - pad_x - sw, label_y,
                active and clr[1] or 100,
                active and clr[2] or 100,
                active and clr[3] or 100,
                math.floor((active and 220 or 120) * ctx.anim), "", 0, sym)

            if item_hovered and mouse_down then
                ui.set(menu.features.visuals.manual_arrows_style, name)
                arrow_ctx_menu.open = false; arrow_ctx_menu.closing = true
            end
        end

        local outside = not (mouse_x >= bx and mouse_x <= bx + ctx.w
            and mouse_y >= by and mouse_y <= by + total_h)
        if outside and mouse_down then
            arrow_ctx_menu.open = false; arrow_ctx_menu.closing = true
        end
    end
end

local function process_string1(text)
    local result, count = string.gsub(text, "%%([^%%]+)%%", function(middle)
        local random_chars = ""
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        for i = 1, #middle do
            local random_index = math.random(#chars)
            random_chars = random_chars .. chars:sub(random_index, random_index)
        end

        return random_chars
    end)

    return result
end

local cwm = dragging_system.create_drag(912, 50, 200, 30,   "This element is draggable!")
local bwm = dragging_system.create_drag(912, 50, 200, 30,   "This element is draggable!")
bwm.label_bottom = true
local _lwm_sw = select(1, client.screen_size()); lwm = dragging_system.create_drag(math.floor(_lwm_sw), 10, 200, 30, "This element is draggable!")
do
    local saved_order = pcall(function()
        local db = database.read("overflame_lwm_order")
        if db and type(db) == "table" and #db == 4 then
            lwm_box_order = db
        end
    end)
end
lwm.label_bottom = true
local xhair_wm = dragging_system.create_drag(960, 580, 80, 20, "This element is draggable!")
xhair_wm.lock_x = 960
local overflame_beta = dragging_system.create_drag(15, 500, 0, 0, "")
overflame_beta_ref = overflame_beta
overflame_beta.label_bottom = false

local arrow_drag = dragging_system.create_drag(890, 590, 80, 20, "")
arrow_drag.visible = false

local xhair_smooth_x = 960
local xhair_smooth_y = 580
local xhair_side_anim = 0

local arrow_anim_l   = 0
local arrow_anim_r   = 0
local arrow_offset_l = 0
local arrow_offset_r = 0

local lwm_last_tick = 0
local lua_maslo = 0.9
client.set_event_callback("paint_ui", function()
    local color = hexToRgb(lua_color)
    local is_open = ui.is_menu_open()
    local menu_x, menu_y = ui.menu_position()
    local menu_w, menu_h = ui.menu_size()
    local mouse_x, mouse_y = ui.mouse_position()
    local screen_w, screen_h = client.screen_size()
    dragging_system.render()
    if ui.get(menu.features.visuals.custom_watermark) then
        local x = cwm.x
        local y = cwm.y

        local a_f = ui.get(menu.features.visuals.custom_font) == "Nil" and "" or ui.get(menu.features.visuals.custom_font)
        local b_f = ui.get(menu.features.visuals.custom_size) == "Nil" and "" or ui.get(menu.features.visuals.custom_size)

        local c_f = a_f .. b_f

        local prefix = animate_custom(process_string1(ui.get(menu.features.visuals.custom_prefix)), ui.get(menu.features.visuals.custom_prefix_speed) / 10, {r = select(1,ui.get(menu.features.visuals.custom_prefix_color)), g = select(2,ui.get(menu.features.visuals.custom_prefix_color)), b = select(3,ui.get(menu.features.visuals.custom_prefix_color)), a = select(4,ui.get(menu.features.visuals.custom_prefix_color))}, ui.get(menu.features.visuals.custom_prefix_animation))
        local postfix = animate_custom1(process_string1(ui.get(menu.features.visuals.custom_postfix)), ui.get(menu.features.visuals.custom_postfix_speed) / 10, {r = select(1,ui.get(menu.features.visuals.custom_postfix_color)), g = select(2,ui.get(menu.features.visuals.custom_postfix_color)), b = select(3,ui.get(menu.features.visuals.custom_postfix_color)), a = select(4,ui.get(menu.features.visuals.custom_postfix_color))}, ui.get(menu.features.visuals.custom_postfix_animation))

        local pw = select(1, renderer.measure_text(c_f, prefix))
        local ph = select(2, renderer.measure_text(c_f, prefix))
        local qw = select(1, renderer.measure_text(c_f, postfix))
        local total_w = pw + qw + 8
        local total_h = ph + 8
        dragging_system.set_width(cwm, math.max(total_w, 20))
        dragging_system.set_height(cwm, math.max(total_h, 14))

        renderer.text(x + cwm.w / 2 - select(1,renderer.measure_text(c_f,postfix)) / 2, y + cwm.h / 2, 255,255,255,255, "c" .. c_f, 0, prefix)
        renderer.text(x + cwm.w / 2 - select(1,renderer.measure_text(c_f,postfix)) / 2 + select(1,renderer.measure_text(c_f,prefix)) / 2, y + cwm.h / 2 - select(2,renderer.measure_text(c_f,prefix)) / 2, 255,255,255,255, c_f, 0, postfix)
    end

    local wm_enabled = ui.get(menu.features.visuals.watermark_selection)
    cwm.visible = ui.get(menu.features.visuals.custom_watermark)
    lwm.visible = wm_enabled and contains(ui.get(menu.features.visuals.watermark_type), "Watermark")
    xhair_wm.visible = ui.get(menu.features.visuals.crosshair)
    overflame_beta.visible = wm_enabled and contains(ui.get(menu.features.visuals.watermark_type), "Text Watermark")

   if lwm.visible then
        if not lwm_boxes_initialized then
            lwm_boxes_initialized = true
            pcall(function()
                local cur = ui.get(menu.features.visuals.lwm_boxes_enabled)
                if not cur or #cur == 0 then
                    ui.set(menu.features.visuals.lwm_boxes_enabled, "Name", "FPS/MS", "Time", "Profile")
                end
            end)
        end

        local _sw, _sh = client.screen_size()
        if lwm.y + lwm.h > _sh then
            lwm.y = math.max(0, _sh - lwm.h - 10)
        end
        if lwm.x + lwm.w > _sw then
            lwm.x = math.max(0, _sw - lwm.w - 10)
        end

        local h, m, s = client.system_time()
        local time_str = string.format("%02d:%02d", h, m)
        local local_player = entity.get_local_player()
        local ping = math.floor(client.latency() * 1000)

        if not lwm_fps_smooth then lwm_fps_smooth = 60 end
        if not lwm_fps_timer then lwm_fps_timer = 0 end
        lwm_fps_timer = lwm_fps_timer + globals.frametime()
        if lwm_fps_timer >= 2 then
            lwm_fps_timer = 0
            lwm_fps_smooth = math.floor(1 / globals.frametime())
        end
        local fps = lwm_fps_smooth

        local pad     = 10
        local block_h = 24
        local gap     = 4
        local realtime = globals.realtime()
        local clr = {121, 174, 252}

        if not lwm_reveal then
            lwm_reveal = { timer = 0, index = 0, glitch_char = "", glitch_timer = 0, pause_timer = 0, direction = 1 }
        end
        local full_name   = "overflame"
        local glitch_chars = {"$", "/", ">", "#", "@", "!", "%", "&", "~", "?"}
        lwm_reveal.timer       = lwm_reveal.timer       + globals.frametime()
        lwm_reveal.glitch_timer = lwm_reveal.glitch_timer + globals.frametime()
        if lwm_reveal.glitch_timer >= 0.05 then
            lwm_reveal.glitch_timer = 0
            lwm_reveal.glitch_char  = glitch_chars[math.random(1, #glitch_chars)]
        end
        if lwm_reveal.timer >= 0.12 then
            lwm_reveal.timer = 0
            lwm_reveal.index = lwm_reveal.index + lwm_reveal.direction
            if lwm_reveal.index >= #full_name then
                lwm_reveal.index = #full_name
                lwm_reveal.pause_timer = lwm_reveal.pause_timer + 0.12
                if lwm_reveal.pause_timer >= 2.5 then
                    lwm_reveal.pause_timer = 0
                    lwm_reveal.direction   = -1
                end
            elseif lwm_reveal.index <= 0 then
                lwm_reveal.index = 0
                lwm_reveal.pause_timer = lwm_reveal.pause_timer + 0.12
                if lwm_reveal.pause_timer >= 0.8 then
                    lwm_reveal.pause_timer = 0
                    lwm_reveal.direction   = 1
                end
            end
        end
        local revealed      = full_name:sub(1, lwm_reveal.index)
        local glitch_suffix = (lwm_reveal.index < #full_name) and lwm_reveal.glitch_char or ""
        local name_label    = revealed .. glitch_suffix

        local nw         = renderer.measure_text("b", full_name)
        local block1_w   = pad + nw + pad

        local fps_label  = "fps"
        local ms_label   = "ms"
        local fps_val    = tostring(fps)
        local ms_val     = tostring(ping)
        local fw_val1    = renderer.measure_text("b", fps_val)
        local fw_lbl1    = renderer.measure_text("", fps_label)
        local fw_val2    = renderer.measure_text("b", ms_val)
        local fw_lbl2    = renderer.measure_text("", ms_label)
        local block2_w   = math.max(80, pad + fw_val1 + 3 + fw_lbl1 + pad + fw_val2 + 3 + fw_lbl2 + pad)

        local tw         = renderer.measure_text("b", time_str)
        local block3_w   = pad + tw + pad

        local total_w    = block1_w + gap + block2_w + gap + block3_w
        local _, th      = renderer.measure_text("", "A")

        dragging_system.set_height(lwm, block_h)

        local lx, ly = lwm.x, lwm.y

        local function draw_pulse_line(bx_, by_, bw_, bh_)
            local lx_ = bx_ + 6
            local lw_ = bw_ - 12
            local ly_ = by_ + bh_ - 2
            local pulse = math.sin(realtime * 4) * 0.5 + 0.5
            local a = math.floor(80 + 175 * pulse)
            renderer.gradient(lx_,           ly_, lw_ / 2, 2, clr[1], clr[2], clr[3], 0,   clr[1], clr[2], clr[3], a,   true)
            renderer.gradient(lx_ + lw_ / 2, ly_, lw_ / 2, 2, clr[1], clr[2], clr[3], a,   clr[1], clr[2], clr[3], 0,   true)
        end

        local function draw_block(bx_, by_, bw_, bh_)
            for gi = 6, 1, -1 do
                local ga = math.floor(40 * (1 - gi / 6))
                rec_outline(bx_ - gi, by_ - gi, bw_ + gi * 2, bh_ + gi * 2, 4 + gi, 1, {clr[1], clr[2], clr[3], ga})
            end
            rec(bx_, by_, bw_, bh_, 4, 20, 20, 20, 255)
            rec_outline(bx_,     by_,     bw_,     bh_,     4, 1, {10, 10, 10, 255})
            rec_outline(bx_ + 1, by_ + 1, bw_ - 2, bh_ - 2, 4, 1, {55, 55, 55, 255})
            rec_outline(bx_ + 2, by_ + 2, bw_ - 4, bh_ - 4, 4, 2, {30, 30, 30, 255})
            draw_pulse_line(bx_, by_, bw_, bh_)
        end

        local nick_text = lua:display()
        local nick_w = renderer.measure_text("b", nick_text)
        local block4_w = pad + nick_w + 4 + avatar_size + pad

        if not avatar_loaded then
            local lp = entity.get_local_player()
            if lp then
                avatar_loaded = true
                local steamid64 = entity.get_steam64(lp)
                avatar_texture = images.get_steam_avatar(steamid64)
            end
        end

        local boxes_enabled = ui.get(menu.features.visuals.lwm_boxes_enabled)
        local box_visible = {
            contains(boxes_enabled, "Name"),
            contains(boxes_enabled, "FPS/MS"),
            contains(boxes_enabled, "Time"),
            contains(boxes_enabled, "Profile"),
        }

        local all_block_widths = { block1_w, block2_w, block3_w, block4_w }

        local visible_slots = {}
        for slot = 1, 4 do
            local cid = lwm_box_order[slot]
            if box_visible[cid] then
                table.insert(visible_slots, slot)
            end
        end

        local ordered_widths = { block1_w, block2_w, block3_w, block4_w }
        for i = 1, 4 do
            ordered_widths[i] = all_block_widths[lwm_box_order[i]]
        end

        local real_total_w = 0
        local first_vis = true
        for slot = 1, 4 do
            local cid = lwm_box_order[slot]
            if box_visible[cid] then
                if not first_vis then real_total_w = real_total_w + gap end
                real_total_w = real_total_w + ordered_widths[slot]
                first_vis = false
            end
        end
        if real_total_w == 0 then real_total_w = block1_w end
        dragging_system.set_width(lwm, real_total_w)

        local cur_x = lx
        for slot = 1, 4 do
            local cid = lwm_box_order[slot]
            if box_visible[cid] then
                lwm_slot_x[slot] = cur_x
                lwm_slot_w[slot] = ordered_widths[slot]
                cur_x = cur_x + ordered_widths[slot] + gap
            else
                lwm_slot_x[slot] = lx
                lwm_slot_w[slot] = 0
            end
        end
        lwm_slot_h = block_h
        lwm_slot_y = ly

        if lwm_reorder_mode then
            local lmb = client.key_state(0x01)
            if not lwm_lmb_held and lmb and not drag_ctx_menu.open and not reorder_ctx_menu.open then
                for slot = 1, 4 do
                    if lwm_slot_w[slot] > 0 and mouse_x >= lwm_slot_x[slot] and mouse_x <= lwm_slot_x[slot] + lwm_slot_w[slot] and
                       mouse_y >= ly and mouse_y <= ly + block_h then
                        lwm_drag_slot     = slot
                        lwm_drag_offset_x = mouse_x - lwm_slot_x[slot]
                        lwm_drag_offset_y = mouse_y - ly
                        break
                    end
                end
            end
            if not lmb and lwm_drag_slot then
                local drop_slot = nil
                local min_dist  = math.huge
                for slot = 1, 4 do
                    if lwm_slot_w[slot] > 0 then
                    local sx = lwm_slot_x[slot] + lwm_slot_w[slot] / 2
                    local dist = math.abs(mouse_x - sx)
                    if dist < min_dist then
                        min_dist  = dist
                        drop_slot = slot
                    end
                    end
                end
                if drop_slot and drop_slot ~= lwm_drag_slot then
                    local tmp_anim = lwm_anim_x[lwm_drag_slot]
                    lwm_anim_x[lwm_drag_slot] = lwm_anim_x[drop_slot]
                    lwm_anim_x[drop_slot] = tmp_anim
                    local tmp = lwm_box_order[lwm_drag_slot]
                    lwm_box_order[lwm_drag_slot] = lwm_box_order[drop_slot]
                    lwm_box_order[drop_slot] = tmp
                    pcall(function() database.write("overflame_lwm_order", lwm_box_order) end)
                end
                lwm_drag_slot = nil
            end
            lwm_lmb_held = lmb
        else
            lwm_lmb_held = client.key_state(0x01)
        end

        for slot = 1, 4 do
            local content_id = lwm_box_order[slot]
            if not box_visible[content_id] then goto continue_slot end
            local bw = ordered_widths[slot]
            local is_dragging = lwm_reorder_mode and lwm_drag_slot == slot and client.key_state(0x01)

            local target_x = lwm_slot_x[slot]

            if lwm_reorder_mode and lwm_drag_slot and lwm_drag_slot ~= slot then
                local drop_slot = nil
                local min_dist2 = math.huge
                for s2 = 1, 4 do
                    if lwm_slot_w[s2] > 0 then
                    local sx2 = lwm_slot_x[s2] + lwm_slot_w[s2] / 2
                    local d2 = math.abs(mouse_x - sx2)
                    if d2 < min_dist2 then min_dist2 = d2; drop_slot = s2 end
                    end
                end
                if drop_slot == slot then
                    target_x = lwm_slot_x[lwm_drag_slot]
                end
            end

            if not lwm_anim_x[slot] then lwm_anim_x[slot] = target_x end

            local bx_
            if is_dragging then
                lwm_anim_x[slot] = mouse_x - lwm_drag_offset_x
                bx_ = lwm_anim_x[slot]
            else
                lwm_anim_x[slot] = interface.animate(lwm_anim_x[slot], target_x, 18)
                bx_ = lwm_anim_x[slot]
            end

            local by_ = is_dragging and (mouse_y - lwm_drag_offset_y) or ly

            draw_block(bx_, by_, bw, block_h)
            local cy2 = by_ + math.floor(block_h / 2 - th / 2)

            if content_id == 1 then
                local gx = bx_ + pad
                for ci = 1, #name_label do
                    local ch    = name_label:sub(ci, ci)
                    local wave  = math.sin(realtime * 3 + ci * 0.3) * 0.5 + 0.5
                    local r     = math.floor(clr[1] + (255 - clr[1]) * wave)
                    local g_col = math.floor(clr[2] + (255 - clr[2]) * wave)
                    local b2    = math.floor(clr[3] + (255 - clr[3]) * wave)
                    local is_g  = (ci == #name_label and glitch_suffix ~= "")
                    if is_g then
                        renderer.text(gx, cy2, 110, 110, 110, 180, "b", 0, ch)
                    else
                        renderer.text(gx, cy2, r, g_col, b2, 255, "b", 0, ch)
                    end
                    gx = gx + renderer.measure_text("b", ch)
                end

            elseif content_id == 2 then
                local div_x = bx_ + pad + fw_val1 + 3 + fw_lbl1 + math.floor(pad / 2)
                renderer.gradient(div_x, by_ + 4,                       1, math.floor(block_h/2)-4, clr[1],clr[2],clr[3],0,  clr[1],clr[2],clr[3],60, false)
                renderer.gradient(div_x, by_ + math.floor(block_h / 2), 1, math.floor(block_h/2)-4, clr[1],clr[2],clr[3],60, clr[1],clr[2],clr[3],0,  false)
                local tbx = bx_ + pad
                renderer.text(tbx,               cy2, 230, 230, 230, 255, "b", 0, fps_val)
                renderer.text(tbx + fw_val1 + 3, cy2, clr[1], clr[2], clr[3], 180, "", 0, fps_label)
                tbx = tbx + fw_val1 + 3 + fw_lbl1 + pad
                renderer.text(tbx,               cy2, 230, 230, 230, 255, "b", 0, ms_val)
                renderer.text(tbx + fw_val2 + 3, cy2, clr[1], clr[2], clr[3], 180, "", 0, ms_label)

            elseif content_id == 3 then
                local tx = bx_ + pad
                local hh_str = string.format("%02d", h)
                local mm_str = string.format(":%02d", m)
                local hw = renderer.measure_text("b", hh_str)
                renderer.text(tx,      cy2, 230, 230, 230, 255, "b", 0, hh_str)
                renderer.text(tx + hw, cy2, clr[1], clr[2], clr[3], 200, "b", 0, mm_str)

            elseif content_id == 4 then
                local av_y = by_ + math.floor((block_h - avatar_size) / 2)
                local gx = bx_ + pad
                local nick_str = nick_text
                for ci = 1, #nick_str do
                    local ch    = nick_str:sub(ci, ci)
                    local wave  = math.sin(realtime * 2.5 + ci * 0.4) * 0.5 + 0.5
                    local nr    = math.floor(clr[1] + (255 - clr[1]) * wave)
                    local ng    = math.floor(clr[2] + (255 - clr[2]) * wave)
                    local nb    = math.floor(clr[3] + (255 - clr[3]) * wave)
                    renderer.text(gx, cy2, nr, ng, nb, 255, "b", 0, ch)
                    gx = gx + renderer.measure_text("b", ch)
                end
                if avatar_texture then
                    local ax = bx_ + pad + nick_w + 4
                    local r2 = math.floor(avatar_size / 2)
                    avatar_texture:draw(ax, av_y, avatar_size, avatar_size, 255, 255, 255, 255)
                    -- hide square corners with bg-colored recs, then draw outline on top
                    local cr = 4
                    renderer.rectangle(ax,                    av_y,                    cr, cr, 20, 20, 20, 255)
                    renderer.rectangle(ax + avatar_size - cr, av_y,                    cr, cr, 20, 20, 20, 255)
                    renderer.rectangle(ax,                    av_y + avatar_size - cr, cr, cr, 20, 20, 20, 255)
                    renderer.rectangle(ax + avatar_size - cr, av_y + avatar_size - cr, cr, cr, 20, 20, 20, 255)
                    renderer.circle_outline(ax + r2, av_y + r2, 20, 20, 20, 255, r2 + 1, 0, 1, 3)
                end
            end
            ::continue_slot::
        end
    end
    if (lua_maslo > 0.01) then
        lua_maslo = interface.animate(lua_maslo, loggined and 0 or 1,2)
        rec(0,0,screen_w,screen_h,0,0,0,0,255*lua_maslo)
    end
    if (lua_maslo >0.9) then loggined = true end
    if mleft ~= ui.get(menu.aa.left_manual) then
        ui.set(menu.aa.left_checkbox, ui.get(menu.aa.left_manual))
    end
    if mright ~= ui.get(menu.aa.right_manual) then
        ui.set(menu.aa.right_checkbox, ui.get(menu.aa.right_manual))
    end
    if mforward ~= ui.get(menu.aa.forward_manual) then
        ui.set(menu.aa.forward_checkbox, ui.get(menu.aa.forward_manual))
    end
    if mbackward ~= ui.get(menu.aa.backward_manual) then
        ui.set(menu.aa.backward_checkbox, ui.get(menu.aa.backward_manual))
    end
    if fs ~= ui.get(menu.aa.freestanding_hotkey) then
        ui.set(menu.aa.freestanding_checkbox, ui.get(menu.aa.freestanding_hotkey))
    end

    mleft = ui.get(menu.aa.left_manual)
    mright = ui.get(menu.aa.right_manual)
    mforward = ui.get(menu.aa.forward_manual)
    mbackward = ui.get(menu.aa.backward_manual)
    fs = ui.get(menu.aa.freestanding_hotkey)
    reference.antiaim.angles.freestanding[1]:set(ui.get(menu.aa.freestanding_checkbox))
    reference.antiaim.angles.freestanding[1]:set_hotkey("Always On")
    if (not mouse_hold and client.key_state(0x01)) then
        mouse_click = true
    else
        mouse_click = false
    end

if not scope_anim_val then scope_anim_val = 0 end

if ui.get(menu.features.visuals.crosshair) then
    local xhair_type = ui.get(menu.features.visuals.crosshair_type)

    if xhair_type == "Modern" then
        local dt_on = reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1]:get_hotkey()
        local name = " overflame"
        local suffix = " "
        local realtime = globals.realtime()
        local frame_time = globals.frametime() * 10

        local clr = {
            main = {121, 174, 252},
            white = {255, 255, 255},
            gray = {150, 150, 150},
            inactive = {80, 80, 80}
        }

        local lp = entity.get_local_player()
        local is_scoped = false
        if lp and entity.is_alive(lp) then
            is_scoped = entity.get_prop(lp, "m_bIsScoped") == 1
        end

        scope_anim_val = interface.animate(scope_anim_val, is_scoped and 1 or 0, 10)

        local w1 = renderer.measure_text("b", name)
        local w2 = renderer.measure_text(nil, suffix)
        local total_w = w1 + 1 + w2

        dragging_system.set_width(xhair_wm, total_w)
        dragging_system.set_height(xhair_wm, 20)

        xhair_wm.x = screen_w / 2 - total_w / 2
        xhair_wm.lock_x = xhair_wm.x

        xhair_wm.label_bottom = (xhair_wm.y < screen_h / 2)

        local ls = math.min(globals.frametime() * 16, 1)
        xhair_smooth_y = xhair_smooth_y + (xhair_wm.y - xhair_smooth_y) * ls

        local center_x = screen_w / 2 + (scope_anim_val * 45)
        local y = xhair_smooth_y
        local is_upper_half = (y < screen_h / 2)

        xhair_side_anim = interface.animate(xhair_side_anim, is_upper_half and 0 or 1, 10)
        local side_t = xhair_side_anim

        if not crosshair_pulse then crosshair_pulse = 0 end
        crosshair_pulse = math.abs(math.sin(globals.curtime() * 2))

        if not dt_anim then dt_anim = 0 end
        dt_anim = interface.animate(dt_anim, dt_on and 1 or 0, 12)

        local current_state = "STAND"
        if lp and entity.is_alive(lp) then
            local flags = entity.get_prop(lp, "m_fFlags") or 0
            local vx, vy = entity.get_prop(lp, "m_vecVelocity")
            local speed = math.sqrt((vx or 0)^2 + (vy or 0)^2)
            local on_ground = bit.band(flags, 1) == 1
            local ducking = bit.band(flags, 4) == 4

            if not on_ground then
                current_state = ducking and "AIR & CROUCHED" or "AIR"
            elseif ducking then
                current_state = speed > 5 and "CROUCH-MOVE" or "CROUCH"
            elseif speed > 5 and speed < 100 then
                current_state = "SLOW-WALK"
            elseif speed >= 100 then
                current_state = "MOVE"
            end
        end

        if not state_anim_val then state_anim_val = {} end
        local state_list = {"STAND", "MOVE", "CROUCH", "CROUCH-MOVE", "AIR", "AIR & CROUCHED", "SLOW-WALK"}
        for _, s in ipairs(state_list) do
            state_anim_val[s] = interface.animate(state_anim_val[s], (current_state == s) and 1 or 0, 6)
        end

        local state_y = y + (1 - side_t) * 22 + side_t * (-6)
        for _, s in ipairs(state_list) do
            local anim = state_anim_val[s] or 0
            if anim > 0.01 then
                local sw = renderer.measure_text("c-", s)
                local sx = center_x - sw / 15
                local a = math.floor(255 * anim)
                local offset_y = math.floor((1 - anim) * 6)
                local dir = (1 - side_t) * (-1) + side_t * (1)
                renderer.text(sx, state_y + dir * offset_y, clr.main[1], clr.main[2], clr.main[3], a, "c-", 0, s)
            end
        end

        local overflame_x = center_x - total_w / 2
        local grad_x = overflame_x
        for ci = 1, #name do
            local ch = name:sub(ci, ci)
            local wave = math.sin(realtime * 3 + (ci * 0.3)) * 0.5 + 0.5
            local r = math.floor(clr.white[1] + (clr.main[1] - clr.white[1]) * wave)
            local g = math.floor(clr.white[2] + (clr.main[2] - clr.white[2]) * wave)
            local b = math.floor(clr.white[3] + (clr.main[3] - clr.white[3]) * wave)

            renderer.text(grad_x, y + 1, r, g, b, 255, "b", 0, ch)
            grad_x = grad_x + renderer.measure_text("b", ch)
        end

        renderer.text(overflame_x + w1 + 10, y + 2, clr.gray[1], clr.gray[2], clr.gray[3], 200, nil, 0, suffix)

        if dt_anim > 0.01 then
            local alpha = 255 * dt_anim
            local offset = 12 * dt_anim
            local dt_x = center_x - total_w / 30

            local dt_y_pos = y + (1 - side_t) * (-5 - offset) + side_t * (20 + offset)
            local text_y_offset = (1 - side_t) * 2 + side_t * (-2)
            local circle_y_offset = (1 - side_t) * 13 + side_t * (-13)
            local dots_y = y + (1 - side_t) * (-6) + side_t * 10

            renderer.text(dt_x, dt_y_pos + text_y_offset, clr.white[1], clr.white[2], clr.white[3], alpha, "c-", 0, "R A P I D")

            local glow_size = 2 + (crosshair_pulse * 2)
            renderer.circle_outline(dt_x, dt_y_pos + circle_y_offset, clr.main[1], clr.main[2], clr.main[3], alpha, glow_size, 0, 1, 1)

            for i = 1, 50 do
                local current_alpha = math.floor((60 / 50) * (50 - i) * dt_anim)
                if current_alpha > 0 then
                    renderer.circle_outline(center_x, dots_y, clr.main[1], clr.main[2], clr.main[3], current_alpha, i, 0, 1, 1)
                end
            end
        end

        local aa_current = ""
        if ui.get(menu.aa.freestanding_checkbox) then aa_current = "FREESTAND"
        elseif ui.get(menu.aa.left_checkbox) then aa_current = "MANUAL LEFT"
        elseif ui.get(menu.aa.right_checkbox) then aa_current = "MANUAL RIGHT"
        elseif ui.get(menu.aa.forward_checkbox) then aa_current = "MANUAL FWD"
        elseif ui.get(menu.aa.backward_checkbox) then aa_current = "MANUAL BACK" end

        if not aa_state_anim then aa_state_anim = {} end
        local aa_state_list = {"FREESTAND", "MANUAL LEFT", "MANUAL RIGHT", "MANUAL FWD", "MANUAL BACK", "DEF FLICK", "FAKE FLICK"}
        for _, s in ipairs(aa_state_list) do
            aa_state_anim[s] = interface.animate(aa_state_anim[s], (aa_current == s) and 1 or 0, 6)
        end

        local aa_y = y + (1 - side_t) * (-12) + side_t * 20
        for _, s in ipairs(aa_state_list) do
            local anim = aa_state_anim[s] or 0
            if anim > 0.01 then
                local sw = renderer.measure_text("c-", s)
                local sx = center_x - sw / 15
                local a = math.floor(210 * anim)
                local offset_y = math.floor((6.5 - anim) * 7)
                local dir = (1 - side_t) * (1) + side_t * (-1)
                renderer.text(sx, aa_y + dir * offset_y, clr.white[1], clr.white[2], clr.white[3], a, "c-", 0, s)
            end
        end

    elseif xhair_type == "Simple" then
        local dt_on = reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1]:get_hotkey()

        local clr = { main = {121, 174, 252}, white = {255, 255, 255} }

        local lp = entity.get_local_player()
        local is_scoped = false
        if lp and entity.is_alive(lp) then
            is_scoped = entity.get_prop(lp, "m_bIsScoped") == 1
        end

        scope_anim_val = interface.animate(scope_anim_val, is_scoped and 1 or 0, 10)

        local name = "overflame"
        local nw   = renderer.measure_text("b", name)
        local total_w = nw + 20
        local total_h = 24

        dragging_system.set_width(xhair_wm, total_w)
        dragging_system.set_height(xhair_wm, total_h)

        xhair_wm.x      = screen_w / 2 - total_w / 2
        xhair_wm.lock_x = xhair_wm.x
        xhair_wm.label_bottom = (xhair_wm.y < screen_h / 2)

        local ls = math.min(globals.frametime() * 16, 1)
        xhair_smooth_y = xhair_smooth_y + (xhair_wm.y - xhair_smooth_y) * ls

        local center_x = screen_w / 2 + (scope_anim_val * 45)
        local y        = xhair_smooth_y
        local is_upper_half = (y < screen_h / 2)

        xhair_side_anim = interface.animate(xhair_side_anim, is_upper_half and 0 or 1, 10)
        local side_t = xhair_side_anim

        if not crosshair_pulse then crosshair_pulse = 0 end
        crosshair_pulse = math.abs(math.sin(globals.curtime() * 2))

        if not dt_anim then dt_anim = 0 end
        dt_anim = interface.animate(dt_anim, dt_on and 1 or 0, 12)

        local name_y  = y + (1 - side_t) * 12
        local state_y = y + side_t * 12

        renderer.text(center_x - nw / 2, name_y, clr.main[1], clr.main[2], clr.main[3], 255, "b", 0, name)

        local current_state = "stand"
        if lp and entity.is_alive(lp) then
            local flags = entity.get_prop(lp, "m_fFlags") or 0
            local vx, vy = entity.get_prop(lp, "m_vecVelocity")
            local speed = math.sqrt((vx or 0)^2 + (vy or 0)^2)
            local on_ground = bit.band(flags, 1) == 1
            local ducking   = bit.band(flags, 4) == 4
            if not on_ground then
                current_state = "air"
            elseif ducking then
                current_state = "crouch"
            elseif speed > 5 and speed < 100 then
                current_state = "walk"
            elseif speed >= 100 then
                current_state = "move"
            end
        end

        local sw = renderer.measure_text("b", current_state)
        renderer.text(center_x - sw / 2, state_y, clr.white[1], clr.white[2], clr.white[3], 255, "b", 0, current_state)
    end
end

bwm.visible = ui.get(menu.features.visuals.watermark_selection) and contains(ui.get(menu.features.visuals.watermark_type), "Brand Watermark") and not ui.get(menu.features.visuals.custom_watermark)

if bwm.visible then
    local bx, by = bwm.x, bwm.y
    local clr = {
        main = {121, 174, 252},
        white = {255, 255, 255},
        gray = {150, 150, 150}
    }

    local name_text = "overflame"
    local user_text = lua:display_upper()

    local w1 = renderer.measure_text("b", name_text)
    local w2 = renderer.measure_text(nil, user_text)

    local total_w = w1 + 25 + w2
    local total_h = 24
    dragging_system.set_width(bwm, total_w)
    dragging_system.set_height(bwm, total_h)

    local glow_r, glow_g, glow_b = clr.main[1], clr.main[2], clr.main[3]
    local glow_radius = 40
    local glow_alpha = 60

    for i = 1, glow_radius do
        local alpha = math.floor((glow_alpha / glow_radius) * (glow_radius - i))
        if alpha > 0 then
            renderer.circle_outline(bx + total_w/2, by + total_h/2 + 4, glow_r, glow_g, glow_b, alpha, i, 0, 1, 1)
        end
    end

    local line_h = 12
    local line_x = bx + w1 + 12
    local line_y = by + (total_h / 2 - line_h / 2) + 4

    renderer.gradient(line_x, line_y, 1, line_h / 2, clr.main[1], clr.main[2], clr.main[3], 0, clr.main[1], clr.main[2], clr.main[3], 255, false)
    renderer.gradient(line_x, line_y + line_h / 2, 1, line_h / 2, clr.main[1], clr.main[2], clr.main[3], 255, clr.main[1], clr.main[2], clr.main[3], 0, false)

    renderer.text(line_x - 6, by + total_h/2.5, clr.white[1], clr.white[2], clr.white[3], 255, "rb", 0, name_text)

    renderer.text(line_x + 6, by + total_h/2.5, clr.gray[1], clr.gray[2], clr.gray[3], 200, "l", 0, user_text)

    local letters = { {char = "B", anim = anim_b}, {char = "E", anim = anim_e}, {char = "T", anim = anim_t}, {char = "A", anim = anim_a} }
    local beta_x = bx + total_w / 2 - 15
    local beta_y = by + total_h + -19

    for i, data in ipairs(letters) do
        local letter_x = beta_x + (i * 7)
        local l_alpha = math.floor(255 * (1 - data.anim))
        local l_y_offset = (10 * data.anim)

        renderer.text(letter_x, beta_y - l_y_offset, clr.main[1], clr.main[2], clr.main[3], l_alpha, "c-", 0, data.char)
    end

    if anim_b >= 0.99 then
        anim_b_active = false
        client.delay_call(0.1, function() anim_e_active = false end)
        client.delay_call(0.2, function() anim_t_active = false end)
        client.delay_call(0.3, function() anim_a_active = false end)
    elseif anim_b <= 0.01 then
        anim_b_active = true
        client.delay_call(0.1, function() anim_e_active = true end)
        client.delay_call(0.2, function() anim_t_active = true end)
        client.delay_call(0.3, function() anim_a_active = true end)
    end

    anim_b = interface.animate(anim_b, anim_b_active and 1 or 0, 2)
    anim_e = interface.animate(anim_e, anim_e_active and 1 or 0, 2)
    anim_t = interface.animate(anim_t, anim_t_active and 1 or 0, 2)
    anim_a = interface.animate(anim_a, anim_a_active and 1 or 0, 2)
end

    if (is_open) then
        local is_jitter = ui.get(menu.aa.preset) == "Jitter"
        local is_dynamic = ui.get(menu.aa.preset) == "Dynamic"
        for k,v in pairs(menu.aa) do
            if type(v) == "table" then
                local is_defensive = ui.get(menu.aa.category) == "Defensive"
                local is_legacy    = ui.get(menu.aa.category) == "Legacy"
                local base_yaw_cond = ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Yaw"

                depend_table(v.yaw,     base_yaw_cond and is_legacy and not is_jitter and not is_dynamic)

                if base_yaw_cond and is_legacy and (is_jitter or is_dynamic) then
                    ui.set_visible(v.yaw.yaw_custom, true)
                    ui.set_visible(v.yaw.space, true)
                end
                depend_table(v.pitch, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch")
                depend_table(v.body_yaw, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Desync")
                depend_table(v.settings, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

                for i = 1,5 do
                    depend_table(v.yaw["delay" .. i], is_legacy and not is_jitter and not is_dynamic and ui.get(v.yaw.delay_ways) >= i and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Yaw" and ui.get(menu.aa.state) == k)
                end

                depend_table(v.hidden.body_yaw, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Aim's")

                depend_table(v.yaw.yaw_value_l, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.lr_offset))
                depend_table(v.yaw.yaw_value_r, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.lr_offset))

                depend_table(v.yaw.delay_ways, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.add_ways))

                depend_table(v.yaw.yaw_extra,    is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.label_extras,  is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.space3,        is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.randomize_delay,     is_legacy and not is_jitter and not is_dynamic and base_yaw_cond)

                depend_table(v.yaw.randomize_delay_min, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.randomize_delay))
                depend_table(v.yaw.randomize_delay_max, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.randomize_delay))

                depend_table(v.yaw.delay1, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.delay_ways) >= 1 and not ui.get(v.yaw.randomize_delay))

                if is_jitter or is_dynamic then
                    depend_table(v.yaw.yaw_custom, base_yaw_cond and is_legacy)
                    depend_table(v.yaw.yaw,        false)
                else
                    depend_table(v.yaw.yaw_custom, is_legacy and base_yaw_cond and not ui.get(v.yaw.lr_offset))
                    depend_table(v.yaw.yaw,        is_legacy and base_yaw_cond and ui.get(v.yaw.lr_offset))
                end

                depend_table(v.yaw.space1, base_yaw_cond and (is_defensive or is_legacy) and not is_jitter and not is_dynamic)
                depend_table(v.yaw.yaw_jitter_value_l, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.yaw_jitter) ~= "Off" and ui.get(v.yaw.yaw_jitter) ~= "Ways")
                depend_table(v.yaw.yaw_jitter_value_r, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.yaw_jitter) ~= "Off" and ui.get(v.yaw.yaw_jitter) ~= "Ways")
                depend_table(v.yaw.xway_ways,  is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.yaw_jitter) == "Ways")
                depend_table(v.yaw.xway_angle, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.yaw_jitter) == "Ways")
                depend_table(v.pitch.pitch_value, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch" and ui.get(v.pitch.pitch) == "Custom")

                depend_table(v.yaw.body_yaw_value_l, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.body_yaw) ~= "Off")
                depend_table(v.yaw.body_yaw_value_r, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and ui.get(v.yaw.body_yaw) ~= "Off")

                depend_table(v.yaw.yaw_extra_spin,      is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Spin"))
                depend_table(v.yaw.yaw_extra_sway,      is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Sway"))
                depend_table(v.yaw.yaw_extra_randomize, is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Randomize"))
                depend_table(v.yaw.yaw_extra_flick,     is_legacy and not is_jitter and not is_dynamic and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Flick"))

                local in_exploit_tab = ui.get(menu.aa.state) == k
                and ui.get(menu.tab) == "Anti-Aim's"
                and ui.get(menu.aa.type) == "Exploit"

                depend_table(v.exploit.force_lc_label, in_exploit_tab)
                depend_table(v.exploit.force_lc,       in_exploit_tab)

                local in_def_cat = ui.get(menu.aa.state) == k
                and ui.get(menu.tab) == "Anti-Aim's"
                and ui.get(menu.aa.category) == "Defensive"

                local def_enabled   = ui.get(v.exploit.hidden)
                local is_new_system = v.exploit.def_type and ui.get(v.exploit.def_type) == "New"
                local is_old_system = v.exploit.def_type and ui.get(v.exploit.def_type) == "Hidden"

                depend_table(v.exploit.hidden,         in_def_cat)
                depend_table(v.exploit.def_type_label, in_def_cat and def_enabled)
                depend_table(v.exploit.def_type,       in_def_cat and def_enabled)

                local old_def_base  = in_def_cat and def_enabled and is_old_system
                local old_yaw_base  = old_def_base and ui.get(menu.aa.type) == "Yaw" and not is_jitter and not is_dynamic
                depend_table(v.hidden.yaw,             old_yaw_base)
                depend_table(v.hidden.yaw.yaw,         old_yaw_base)
                depend_table(v.hidden.yaw.yaw_value,   old_yaw_base and ui.get(v.hidden.yaw.yaw) == "Custom")
                depend_table(v.hidden.yaw.yaw_value_l, old_yaw_base and ui.get(v.hidden.yaw.yaw) == "L/R")
                depend_table(v.hidden.yaw.yaw_value_r, old_yaw_base and ui.get(v.hidden.yaw.yaw) == "L/R")
                depend_table(v.hidden.yaw.delay,       old_yaw_base and ui.get(v.hidden.yaw.yaw) == "L/R")

                local old_pitch_base = old_def_base and ui.get(menu.aa.type) == "Pitch"
                depend_table(v.hidden.pitch,             old_pitch_base)
                depend_table(v.hidden.pitch.pitch,       old_pitch_base)
                depend_table(v.hidden.pitch.pitch_value, old_pitch_base and ui.get(v.hidden.pitch.pitch) == "Custom")

                local nd = v.new_def
                if nd then
                    local nd_base = in_def_cat and def_enabled and is_new_system
                    local nd_builder = nd_base and nd.toggle_builder and ui.get(nd.toggle_builder)
                    local nd_yaw_on  = nd_builder and nd.yaw and ui.get(nd.yaw) ~= "Off"
                    local nd_lr      = nd_yaw_on  and nd.yaw_left_right and ui.get(nd.yaw_left_right)
                    local nd_gen     = nd_yaw_on  and nd.yaw_generation  and ui.get(nd.yaw_generation)
                    local nd_has_speed = nd_builder and nd.yaw and (ui.get(nd.yaw) == "Distortion" or ui.get(nd.yaw) == "Sway")
                    local nd_pitch_cust = nd_builder and not (nd.pitch_min_max and ui.get(nd.pitch_min_max)) and not (nd.pitch_height_based and ui.get(nd.pitch_height_based))
                    local nd_minmax  = nd_builder and nd.pitch_min_max and ui.get(nd.pitch_min_max)
                    local nd_rdm_delay = nd_builder and nd.addons and contains(ui.get(nd.addons), "Randomize Delay Ticks")
                    local nd_freeze  = nd_builder and nd.addons and contains(ui.get(nd.addons), "Freeze-Inverter")
                    local nd_speed_mode = nd_builder and nd.pitch_mode and (ui.get(nd.pitch_mode) ~= "Static" and ui.get(nd.pitch_mode) ~= "Random")

                    depend_table(nd.sp0,               nd_base)
                    depend_table(nd.enable,            nd_base)
                    depend_table(nd.defensive_on,      nd_base)
                    depend_table(nd.def_mode,          nd_base)
                    depend_table(nd.sp1,               nd_base)
                    depend_table(nd.toggle_builder,    nd_base)
                    depend_table(nd.duration,          nd_builder)
                    depend_table(nd.sp2,               nd_builder)
                    depend_table(nd.yaw_label,         nd_builder)
                    depend_table(nd.yaw,               nd_builder)
                    depend_table(nd.speed,             nd_has_speed)
                    depend_table(nd.offset,            nd_yaw_on and not nd_lr and not nd_gen)
                    depend_table(nd.yaw_left_right,    nd_yaw_on)
                    depend_table(nd.left,              nd_lr)
                    depend_table(nd.right,             nd_lr)
                    depend_table(nd.yaw_generation,    nd_yaw_on)
                    depend_table(nd.min_gen,           nd_gen)
                    depend_table(nd.max_gen,           nd_gen)
                    depend_table(nd.sp3,               nd_builder)
                    depend_table(nd.pitch_label,       nd_builder)
                    depend_table(nd.pitch_mode,        nd_builder)
                    depend_table(nd.pitch_speed,       nd_speed_mode)
                    depend_table(nd.pitch_min_max,     nd_builder and not (nd.pitch_height_based and ui.get(nd.pitch_height_based)))
                    depend_table(nd.pitch_height_based,nd_builder)
                    depend_table(nd.pitch,             nd_pitch_cust)
                    depend_table(nd.pitch_min,         nd_minmax and not (nd.pitch_height_based and ui.get(nd.pitch_height_based)))
                    depend_table(nd.pitch_max,         nd_minmax and not (nd.pitch_height_based and ui.get(nd.pitch_height_based)))
                    depend_table(nd.sp4,               nd_builder)
                    depend_table(nd.delay_label,       nd_builder)
                    depend_table(nd.delay,             nd_builder and not nd_rdm_delay)
                    depend_table(nd.delay_min,         nd_rdm_delay)
                    depend_table(nd.delay_max,         nd_rdm_delay)
                    depend_table(nd.freeze_chance,     nd_freeze)
                    depend_table(nd.freeze_time,       nd_freeze)
                    depend_table(nd.addons,            nd_builder)
                end

                local is_legacy_mode = is_legacy and not is_jitter and not is_dynamic
                local base_cond      = base_yaw_cond and is_legacy_mode

                local jitter_type = ui.get(v.yaw.yaw_jitter)
                local lr_mode     = ui.get(v.yaw.jitter_lr_mode)

                local show_lr_checkbox = (jitter_type == "Offset" or jitter_type == "Custom" or jitter_type == "Center")
                depend_table(v.yaw.jitter_lr_mode, base_cond and show_lr_checkbox)

                local show_amount = (jitter_type == "Offset" or jitter_type == "Custom" or jitter_type == "Center") and not lr_mode

                depend_table(v.yaw.yaw_jitter_amount, base_cond and show_amount)
                depend_table(v.yaw.jitter_random,     base_cond and show_amount and jitter_type == "Offset")

                local show_lr_sliders =
                    ((jitter_type == "Offset" or jitter_type == "Custom" or jitter_type == "Center") and lr_mode) or
                    (jitter_type == "Skitter")

                depend_table(v.yaw.yaw_jitter_value_l, base_cond and show_lr_sliders)
                depend_table(v.yaw.yaw_jitter_value_r, base_cond and show_lr_sliders)

                depend_table(v.yaw.xway_ways,  base_cond and jitter_type == "Ways")
                depend_table(v.yaw.xway_angle, base_cond and jitter_type == "Ways")
            else
                ui.set_visible(v, ui.get(menu.tab) == "Anti-Aim's")
            end
        end

        depend_table(menu.rage, ui.get(menu.tab) == "Home")
        depend_table(menu.features.visuals, ui.get(menu.tab) == "Features")
        depend_table(menu.config, ui.get(menu.tab) == "Presets")

        ui.set_visible(menu.rage.tab_sec, ui.get(menu.tab) == "Home")

        ui.set_visible(menu.features.type, ui.get(menu.tab) == "Features")

        local in_stat_subtab = ui.get(menu.tab) == "Home" and ui.get(menu.rage.tab_sec) == "Statistics"
        local in_other_subtab = ui.get(menu.tab) == "Home" and ui.get(menu.rage.tab_sec) == "Other"

        local in_misc_subtab = ui.get(menu.tab) == "Features" and ui.get(menu.features.type) == "Miscellaneous"
        local in_vis_subtab = ui.get(menu.tab) == "Features" and ui.get(menu.features.type) == "Visuals"
        local in_rage_subtab = ui.get(menu.tab) == "Features" and ui.get(menu.features.type) == "Rage"

        depend_table(menu.rage.statistics.serialized_time,  in_stat_subtab)
        depend_table(menu.rage.statistics.spacing_in_stat0, in_stat_subtab)
        depend_table(menu.rage.statistics.enemy_killed,     in_stat_subtab)
        depend_table(menu.rage.statistics.spacing_in_stat1, in_stat_subtab)
        depend_table(menu.rage.statistics.ts_session,       in_stat_subtab)
        depend_table(menu.rage.statistics.spacing_in_stat2, in_stat_subtab)
        depend_table(menu.rage.statistics.evaded_shots,     in_stat_subtab)

        depend_table(menu.rage.other_section.youtube,       in_other_subtab)
        depend_table(menu.rage.other_section.discord,       in_other_subtab)

        depend_table(menu.features.miscellaneous.recharge,         in_rage_subtab)
        depend_table(menu.features.miscellaneous.correction,       in_rage_subtab)
        depend_table(menu.features.miscellaneous.predict_enemies,  in_rage_subtab)
        depend_table(menu.features.miscellaneous.jumpscout,        in_rage_subtab)
        depend_table(menu.features.miscellaneous.aimtools,         in_rage_subtab)

        depend_table(menu.rage.rage_section.space,              in_other_subtab)
        depend_table(menu.rage.rage_section.clantag,            in_other_subtab)
        depend_table(menu.rage.rage_section.trash_talk.enable,  in_other_subtab)
        depend_table(menu.rage.rage_section.trash_talk.setting.work, in_other_subtab)
        depend_table(menu.rage.rage_section.trash_talk.setting.type, in_other_subtab)

        depend_table(menu.features.miscellaneous.airlag_key,    in_misc_subtab)
        depend_table(menu.features.miscellaneous.airlag_ticks,  in_misc_subtab)
        depend_table(menu.features.miscellaneous.airlag,        in_misc_subtab)
        depend_table(menu.features.miscellaneous.fastladder,    in_misc_subtab)
        depend_table(menu.features.miscellaneous.anti_backstab, in_misc_subtab)

        depend_table(menu.features.visuals.aspect_ratio_enable,     in_vis_subtab)
        depend_table(menu.features.visuals.aspect_ratio_value,      in_vis_subtab)

        depend_table(menu.features.visuals.crosshair,           in_vis_subtab)
        depend_table(menu.features.visuals.logs,                in_vis_subtab)
        depend_table(menu.features.visuals.manual_arrows,       in_vis_subtab)
        depend_table(menu.features.visuals.manual_arrows_style, in_vis_subtab and ui.get(menu.features.visuals.manual_arrows))
        depend_table(menu.features.visuals.custom_watermark,    in_vis_subtab)
        depend_table(menu.features.visuals.animations,          in_vis_subtab)
        depend_table(menu.features.visuals.watermark_selection,     in_vis_subtab)
        depend_table(menu.features.visuals.watermark_type,          in_vis_subtab)
        depend_table(menu.features.visuals.crosshair_type,          in_vis_subtab)
        depend_table(menu.features.visuals.crosshair,               in_vis_subtab)
        
        depend_table(menu.features.visuals.damage_indicator,        in_vis_subtab)

        local custom_wm_on = in_vis_subtab and ui.get(menu.features.visuals.custom_watermark)

        depend_table(menu.features.visuals.prefix_label,             custom_wm_on)
        depend_table(menu.features.visuals.custom_prefix,            custom_wm_on)
        depend_table(menu.features.visuals.custom_prefix_color,      custom_wm_on)
        depend_table(menu.features.visuals.postfix_label,            custom_wm_on)
        depend_table(menu.features.visuals.custom_postfix,           custom_wm_on)
        depend_table(menu.features.visuals.custom_postfix_color,     custom_wm_on)
        depend_table(menu.features.visuals.custom_prefix_animation,  custom_wm_on)
        depend_table(menu.features.visuals.custom_postfix_animation, custom_wm_on)
        depend_table(menu.features.visuals.custom_prefix_speed,      custom_wm_on)
        depend_table(menu.features.visuals.custom_postfix_speed,     custom_wm_on)
        depend_table(menu.features.visuals.custom_step,              custom_wm_on)
        depend_table(menu.features.visuals.custom_font,              custom_wm_on)
        depend_table(menu.features.visuals.custom_size,              custom_wm_on)

        depend_table(menu.features.miscellaneous.airlag_ticks,ui.get(menu.features.miscellaneous.airlag) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.miscellaneous.airlag_key  ,ui.get(menu.features.miscellaneous.airlag) and ui.get(menu.tab) == "Features")

        depend_table(menu.rage.rage_section.trash_talk.setting.work, ui.get(menu.rage.rage_section.trash_talk.enable) and ui.get(menu.tab) == "Home")
        depend_table(menu.rage.rage_section.trash_talk.setting.type, ui.get(menu.rage.rage_section.trash_talk.enable) and ui.get(menu.tab) == "Home")

        depend_table(menu.aa.antibrute_l, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")
        depend_table(menu.aa.antibrute_r, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")
        depend_table(menu.aa.antibrute_delay, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")

        depend_table(menu.aa.safe_head, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table(menu.aa.space01, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table(menu.aa.warmup_aa, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

        depend_table(menu.aa.state, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) ~= "Anti-Brute")

        depend_table(menu.aa.state,       ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")
        depend_table(menu.aa.label_state, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")
        depend_table(menu.aa.space_fl,    ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")
        depend_table(menu.aa.space_aa,    ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")
        depend_table(menu.aa.space_fl2,   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")

        depend_table({menu.aa.freestanding_hotkey,menu.aa.backward_manual,menu.aa.right_manual,menu.aa.left_manual,menu.aa.forward_manual},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table({menu.aa.freestanding_checkbox,menu.aa.backward_checkbox,menu.aa.right_checkbox,menu.aa.left_checkbox,menu.aa.forward_checkbox, menu.aa.manual_spacing},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table({menu.aa.fakelag_amount ,menu.aa.fakelag_variance ,menu.aa.fakelag_limit},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

        depend_table(menu.features.visuals.aspect_ratio_value, in_vis_subtab and ui.get(menu.features.visuals.aspect_ratio_enable))

        local crosshair_on = in_vis_subtab and ui.get(menu.features.visuals.crosshair)
        depend_table(menu.features.visuals.crosshair_type, crosshair_on)

        local wm_on = in_vis_subtab and ui.get(menu.features.visuals.watermark_selection)
        depend_table(menu.features.visuals.watermark_type, wm_on)
        depend_table(menu.features.visuals.lwm_boxes_enabled, wm_on and contains(ui.get(menu.features.visuals.watermark_type), "Watermark"))

    end

    if ui.get(menu.features.visuals.manual_arrows) then
        local style = ui.get(menu.features.visuals.manual_arrows_style)
        local sym_l, sym_r
        if     style == "Classic"  then sym_l, sym_r = "«", "»"
        elseif style == "Rounded"  then sym_l, sym_r = "⮜", "⮞"
        elseif style == "Simple"   then sym_l, sym_r = "<", ">"
        elseif style == "Block"    then sym_l, sym_r = "◀", "▶"
        else                            sym_l, sym_r = "«", "»"
        end

        local clr_r2, clr_g2, clr_b2 = menu_r or 121, menu_g or 174, menu_b or 252
        local is_left   = ui.get(menu.aa.left_checkbox)
        local is_right  = ui.get(menu.aa.right_checkbox)
        local menu_open = ui.is_menu_open()

        arrow_drag.visible = menu_open
        arrow_drag.lock_y  = screen_h / 2
        arrow_drag.y       = screen_h / 2
        dragging_system.set_width(arrow_drag, 20)
        dragging_system.set_height(arrow_drag, 20)

        local show_l = is_left  or menu_open
        local show_r = is_right or menu_open

        arrow_anim_l = interface.animate(arrow_anim_l, show_l and 1 or 0, 10)
        arrow_anim_r = interface.animate(arrow_anim_r, show_r and 1 or 0, 10)

        local box_cx = arrow_drag.x + 10
        local offset = box_cx - screen_w / 2

        local cy = screen_h / 2 + 12

        if not arrow_scope_anim then arrow_scope_anim = 0 end
        local lp = entity.get_local_player()
        local is_scoped = lp and entity.is_alive(lp) and entity.get_prop(lp, "m_bIsScoped") == 1
        arrow_scope_anim = interface.animate(arrow_scope_anim, is_scoped and 1 or 0, 10)
        local scope_offset = arrow_scope_anim * 12

        if arrow_anim_r > 0.001 then
            local a = math.floor(255 * arrow_anim_r)
            local rx = screen_w / 2 + math.abs(offset)
            renderer.text(rx, cy - 4 - scope_offset, clr_r2, clr_g2, clr_b2, a, "c+", 0, sym_r)
        end

        if arrow_anim_l > 0.001 then
            local a = math.floor(255 * arrow_anim_l)
            local lx = screen_w / 2 - math.abs(offset)
            renderer.text(lx, cy - 4 - scope_offset, clr_r2, clr_g2, clr_b2, a, "c+", 0, sym_l)
        end
    else
        arrow_drag.visible = false
    end
    logs.render()
    mouse_hold = client.key_state(0x01)
end)
getside = function(arg)
    local desyncbodyyaw = entity.get_prop(arg, "m_flPoseParameter", 11) * 120 - 60
    return desyncbodyyaw > 0 and 1 or -1
end
local nade_ticks = 0
can_desync = function(cmd)
    local me = entity.get_local_player()
    local weapon_ent = entity.get_player_weapon(me)
    if cmd.in_attack == 1 then
        local weapon = entity.get_classname(weapon_ent)
        if weapon:find("Grenade") then
            nade_ticks = globals.tickcount()
        else
            if math.max(entity.get_prop(weapon_ent, "m_flNextPrimaryAttack"), entity.get_prop(me, "m_flNextAttack")) - globals.tickinterval() - globals.curtime() < 0 then
                return false
            end
        end
    end
    local throw = entity.get_prop(weapon_ent, "m_fThrowTime")
    if nade_ticks + 15 == globals.tickcount() or (throw ~= nil and throw ~= 0) then
        cmd.force_defensive = false
        return false
    end
    if cmd.in_use == 1 then
        return false
    end
    if entity.get_prop(entity.get_game_rules(), "m_bFreezePeriod") == 1 then
        return false
    end
    if entity.get_prop(me, "m_MoveType") == 9 then
        return false
    end
    if entity.get_prop(me, "m_MoveType") == 10 then
        return false
    end
    return true
end
can_runaa = function(cmd)
    local me = entity.get_local_player()
    local weapon_ent = entity.get_player_weapon(me)
    if cmd.in_attack == 1 then
        local weapon = entity.get_classname(weapon_ent)
        if weapon:find("Grenade") then
            nade_ticks = globals.tickcount()
        else
            if math.max(entity.get_prop(weapon_ent, "m_flNextPrimaryAttack"), entity.get_prop(me, "m_flNextAttack")) - globals.tickinterval() - globals.curtime() < 0 then
                return false
            end
        end
    end
    local throw = entity.get_prop(weapon_ent, "m_fThrowTime")
    if nade_ticks + 15 == globals.tickcount() or (throw ~= nil and throw ~= 0) then
        cmd.force_defensive = false
        return false
    end
    if cmd.in_use == 1 then
        return false
    end
    return true
end
get_yaw = function(at_targets)
    local threat = client.current_threat()
    local _, yaw = client.camera_angles()
    if at_targets and threat then
        local pos =  vector(entity.get_origin(entity.get_local_player()))
        local epos = vector(entity.get_origin(threat))
        _, yaw = pos:to(epos):angles()
    end
    return yaw
end
run_fakelag = function(cmd)
    local dt = reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1]:get_hotkey()
    local os = reference.antiaim.other.on_shot_anti_aim[1]:get() and reference.antiaim.other.on_shot_anti_aim[1]:get_hotkey()
    local fd = reference.rage.other.fake_duck:get_hotkey()
    local limit = 13
    if fd then
        limit = 13
    elseif dt then
        limit = 1
    elseif os then
        limit = 1
    end
    local send_packet = true
    if cmd.chokedcommands < limit then
        send_packet = false
    end
    local command_dif = cmd.command_number - cmd.chokedcommands - globals.lastoutgoingcommand()
    send_packet = send_packet or cmd.no_choke or not cmd.allow_send_packet or command_dif ~= 1
    cmd.allow_send_packet = send_packet
    return send_packet
end
function normalize_angle(value, min, max)
    if value > max then
        return min + (value - max) % (max - min)
    elseif value < min then
        return max - (min - value) % (max - min)
    end
    return value
end
local ground_ticks = 0

on_use = function(cmd)

    local in_use = cmd.in_use == 1
    local me = entity.get_local_player()

    if not me or not entity.is_alive(me) then
        return
    end

    local weapon_ent = entity.get_player_weapon(me)

    if weapon_ent == nil then
        return
    end

    local weapon = csgo_weapons(weapon_ent)

    if weapon == nil then
        return
    end

    local local_pos     = vector(entity.get_origin(me))
    local in_bombzone   = entity.get_prop(me, "m_bInBombZone") > 0
    local holding_bomb  = weapon.type == "c4"

    local bomb_table    = entity.get_all("CPlantedC4")
    local bomb_planted  = #bomb_table > 0
    local bomb_distance = 100

    if bomb_planted then
        local bomb_entity = bomb_table[#bomb_table]
        local bomb_pos = vector(entity.get_origin(bomb_entity))
        bomb_distance = local_pos:dist(bomb_pos)
    end

    local defusing = bomb_distance < 62 and entity.get_prop(me, "m_iTeamNum") == 3

    if in_bombzone and holding_bomb or defusing then return end

	local from = vector(client.eye_position())
	local to = from + vector():init_from_angles(client.camera_angles()) * 1024

	local ray = trace.line(from, to, { skip = me, mask = "MASK_SHOT" })

    if not ray or ray.fraction > 1 or not ray.entindex then return end

    local ray_ent = pcall(function() entity.get_classname(ray.entindex) end) and entity.get_classname(ray.entindex) or nil

    if not ray_ent or ray_ent == nil then return end

    if ray_ent ~= "CWorld" and ray_ent ~= "CFuncBrush" and ray_ent ~= "CCSPlayer" then return end

    if in_use then
        cmd.in_use = 0
        return true
    end
end
local ground_ticks = 0

function get_player_state(e)
    local me    = entity.get_local_player()
    if not me then return "Stand" end

    local flags = entity.get_prop(me, "m_fFlags")
    if not flags then return "Stand" end

    local vel1, vel2, vel3 = entity.get_prop(me, 'm_vecVelocity')
    if not vel1 then return "Stand" end

    local speed = math.floor(math.sqrt(vel1 * vel1 + vel2 * vel2))
    local ducking       = e.in_duck == 1
    local use           = e.in_use == 1

    ground_ticks = bit.band(flags, 1) == 0 and 0 or (ground_ticks < 5 and ground_ticks + 1 or ground_ticks)

    local air           = ground_ticks < 5
    local walking       = speed >= 2
    local standing      = speed <= 1
    local slow_motion   = reference.antiaim.other.slow_motion[1]:get() and reference.antiaim.other.slow_motion[1]:get_hotkey()

    local state = "Slow-Walk"

    if use then
        state = "On Use"
    elseif air and ducking then
        state = "Air & Crouched"
    elseif air and not ducking then
        state = "Air"
    elseif slow_motion then
        state = "Slow-Walk"
    elseif ducking and walking then
        state = "Crouch-move"
    elseif ducking then
        state = "Crouch"
    elseif walking then
        state = "Move"
    elseif standing then
        state = "Stand"
    else
        state = "Stand"
    end

    return state
end
local side = false;
local ready = false;
local def_side = false;
local def_ready = false;
local nd_active_start = nil

local prev_sim = 0

sim_diff = function (lp)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then
        return 0
    end
    local current_simulation_time = math.floor(0.5 + (entity.get_prop(entity.get_local_player(), "m_flSimulationTime") / globals.tickinterval()))
    local diff = current_simulation_time - prev_sim
    prev_sim = current_simulation_time
    return diff
end

function generate_nya(e, left, right, settings)
    local jitter_type = ui.get(settings.yaw.yaw_jitter)
    if jitter_type == "Skitter" then
        local t = e.command_number % 3
        if t == 0 then return left
        elseif t == 1 then return right
        else return (left + right) / 2 end
    elseif jitter_type == "Center" then
        return side and left or right
    elseif jitter_type == "Ways" then
        local ways = math.max(2, ui.get(settings.yaw.xway_ways))
        local angle = ui.get(settings.yaw.xway_angle)
        local angle_step = angle / (ways - 1)
        local idx = e.command_number % ways
        return -angle / 2 + idx * angle_step
    end

    local left_spin = (side and 0 or e.command_number % 12)
    local random_right = (side and math.random(-6,6) or 0)
    local def_flick = (sim_diff()<=-1) and -math.random(-12,6) or 0
    return left_spin + random_right + (side and left or right)
end

local function make_odd(num)
    return math.floor(num) % 2 == 0 and math.floor(num) + 1 or math.floor(num)
end
local delay_switch = 1;
local dt_state = {false,0}
local cvar_maxticks = cvar.sv_maxusrcmdprocessticks
local native_GetClientEntity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")
local native_GetHighestEntityIndex = vtable_bind("client.dll", "VClientEntityList003", 6, "int(__thiscall*)(void*)")
local native_GetClientNetworkable = vtable_bind("client.dll", "VClientEntityList003", 0,
    "void*(__thiscall*)(void*, int)")
local native_GetClientClass = vtable_thunk(2, "void*(__thiscall*)(void*)")

ffi.cdef [[
    typedef struct {
        char pad0[0x18];
        float anim_update_timer;
        char pad1[0xC];
        float started_moving_time;
        float last_move_time;
        char pad2[0x10];
        float last_lby_time;
        char pad3[0x8];
        float run_amount;
        char pad4[0x10];
        void* entity;
        void* active_weapon;
        void* last_active_weapon;
        float last_client_side_animation_update_time;
        int  last_client_side_animation_update_framecount;
        float eye_timer;
        float eye_angles_y;
        float eye_angles_x;
        float goal_feet_yaw;
        float current_feet_yaw;
        float torso_yaw;
        float last_move_yaw;
        float lean_amount;
        char pad5[0x4];
        float feet_cycle;
        float feet_yaw_rate;
        char pad6[0x4];
        float duck_amount;
        float landing_duck_amount;
        char pad7[0x4];
        float current_origin[3];
        float last_origin[3];
        float velocity_x;
        float velocity_y;
        char pad8[0x4];
        float unknown_float1;
        char pad9[0x8];
        float unknown_float2;
        float unknown_float3;
        float unknown;
        float m_velocity;
        float jump_fall_velocity;
        float clamped_velocity;
        float feet_speed_forwards_or_sideways;
        float feet_speed_unknown_forwards_or_sideways;
        float last_time_started_moving;
        float last_time_stopped_moving;
        bool on_ground;
        bool hit_in_ground_animation;
        char pad10[0x4];
        float time_since_in_air;
        float last_origin_z;
        float head_from_ground_distance_standing;
        float stop_to_full_running_fraction;
        char pad11[0x4];
        float magic_fraction;
        char pad12[0x3C];
        float world_force;
        char pad13[0x1CA];
        float min_yaw;
        float max_yaw;
    } CAnimationState;

    typedef struct {
        char  pad_0000[20];
        int m_nOrder;
        int m_nSequence;
        float m_flPrevCycle;
        float m_flWeight;
        float m_flWeightDeltaRate;
        float m_flPlaybackRate;
        float m_flCycle;
        void *m_pOwner;
        char  pad_0038[4];
    } CAnimationLayer;
]]
entity.get_animstate = function(ent)
    local pointer = native_GetClientEntity(ent)
    if pointer then
        return ffi.cast("CAnimationState**", ffi.cast("char*", ffi.cast("void***", pointer)) + 0x9960)[0]
    end
    return
end

entity.get_animlayer = function(ent, layer)
    local pointer = native_GetClientEntity(ent)
    if pointer then
        return ffi.cast("CAnimationLayer**", ffi.cast("char*", ffi.cast(ffi.typeof("void***"), pointer)) + 0x2990)
            [0][layer]
    end
    return
end
local old_lean = 0
client.set_event_callback("pre_render", function()
    if (entity.get_local_player() and entity.is_alive(entity.get_local_player())) then
        if contains(ui.get(menu.features.visuals.animations), "Earthquake") then
            if (globals.tickcount() % 6 == 0) then
                old_lean = math.random(-100,100) / 100
            end
            entity.get_animlayer(entity.get_local_player(), 12).m_flWeight = old_lean
        end
        if contains(ui.get(menu.features.visuals.animations), "Leaning") then
            entity.get_animlayer(entity.get_local_player(), 12).m_flWeight = 1
        end
        if contains(ui.get(menu.features.visuals.animations), "Jitter Legs") then
            entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 0, globals.tickcount() % 4 > 1 and 0.5 or 1)
            reference.antiaim.other.leg_movement:set(globals.tickcount() % 3 == 0 and "Off" or "Always slide")
        end
    end
end)

local brute_l = 0
local brute_r = 0
local brute_d = 0
local bruted_last_time = globals.curtime()
local bruted = false
client.set_event_callback("setup_command", function(e)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local phys_state = get_player_state(e)

    local exact_key = lua_color .. '›\a9D9D9DFF  ' .. phys_state
    local settings = menu.aa[exact_key]

    if not settings then
        for key, val in pairs(menu.aa) do
            if type(key) == "string" and key:sub(-#phys_state) == phys_state then
                settings = val
                break
            end
        end
    end

    if not settings then
        for key, val in pairs(menu.aa) do
            if type(key) == "string" and key:find("Global") then
                settings = val
                break
            end
        end
    end

    if not settings then
        settings = menu.aa[stand_state_key]
    end

    if not settings then return end

    local h_settings = settings.hidden
    local fake_lag = run_fakelag(e)
    local target_yaw = get_yaw(true)
    local can_desyn = can_desync(e)
    local desync_side = getside(me)

    if ui.get(settings.exploit.force_lc) == "14t" then e.force_defensive = true; elseif ui.get(settings.exploit.force_lc) == "8t" then e.force_defensive = e.command_number % 8 ~= 0; end
    if bruted_last_time + 10 < globals.curtime() and bruted then
        brute_r = 0
        brute_l = 0
        brute_d = 0
        logs.add(" Switched antibrute due to timed out ")
        bruted_last_time = globals.curtime()
        bruted = false
    end
    if not can_desyn then
        return
    end

    local delay_ways = ui.get(settings.yaw.delay_ways) or 1
    if delay_ways < 1 then delay_ways = 1 end

    if delay_switch < 1 or delay_switch > delay_ways then
        delay_switch = 1
    end

    local final_delay = ui.get(settings.yaw["delay" .. delay_switch]) or 0

    if ui.get(settings.yaw.randomize_delay) then
        local min_val = ui.get(settings.yaw.randomize_delay_min)
        local max_val = ui.get(settings.yaw.randomize_delay_max)
        if min_val > max_val then min_val, max_val = max_val, min_val end
        final_delay = math.random(math.floor(min_val), math.floor(max_val))
    end

    if ui.get(settings.yaw.delay_mode) == "Old" then
        if (e.command_number % (final_delay + 2 + brute_d) == 0) then
            ready = true
        end

    elseif ui.get(settings.yaw.delay_mode) == "New" then
        if (globals.tickcount() % (final_delay + 2 + brute_d) == 0) then
            ready = true
        end
    end

    if (e.command_number % make_odd(ui.get(settings.hidden.yaw.delay) + 3) == 0) then def_ready = true; end
    local jitter_type = ui.get(settings.yaw.yaw_jitter)
    local nya = (jitter_type == "Custom" or jitter_type == "Skitter" or jitter_type == "Center" or jitter_type == "Ways") and generate_nya(e, ui.get(settings.yaw.yaw_jitter_value_l) + brute_l, ui.get(settings.yaw.yaw_jitter_value_r) + brute_r, settings) or 0
    if (fake_lag) then
        if (ready) then side = not side; ready = false; delay_switch = delay_switch + 1; end
        if (def_ready) then def_side = not def_side; def_ready = false; end
    end
    local manual = ui.get(menu.aa.left_checkbox) and -90 or (ui.get(menu.aa.right_checkbox) and 90 or (ui.get(menu.aa.forward_checkbox) and 180 or (ui.get(menu.aa.backward_checkbox) and 0 or 0)))
    if (not (reference.antiaim.angles.freestanding[1]:get() and reference.antiaim.angles.freestanding[1]:get_hotkey())) then
        if (fake_lag) then
            if (not ui.get(menu.aa.backward_checkbox)) then
                local yaw_lr = ui.get(settings.yaw.lr_offset) and (side and ui.get(settings.yaw.yaw_value_l) + brute_l or ui.get(settings.yaw.yaw_value_r) + brute_r) or 0

                local yaw_spin = (contains(ui.get(settings.yaw.yaw_extra), "Spin") and ui.get(settings.yaw.yaw_extra_spin) ~= 0) and (extra_yaw(e.command_number * 2, "Spin", -ui.get(settings.yaw.yaw_extra_spin), ui.get(settings.yaw.yaw_extra_spin))) or 0
                local yaw_sway = (contains(ui.get(settings.yaw.yaw_extra), "Sway") and ui.get(settings.yaw.yaw_extra_sway) ~= 0) and (extra_yaw(e.command_number * 2, "Sway", -ui.get(settings.yaw.yaw_extra_sway), ui.get(settings.yaw.yaw_extra_sway))) or 0
                local yaw_randomize = contains(ui.get(settings.yaw.yaw_extra), "Randomize") and (extra_yaw(e.command_number * 2, "Randomize", -ui.get(settings.yaw.yaw_extra_randomize), ui.get(settings.yaw.yaw_extra_randomize))) or 0
                local yaw_flick = contains(ui.get(settings.yaw.yaw_extra), "Flick") and (extra_yaw(e.command_number * 2, "Flick", -ui.get(settings.yaw.yaw_extra_flick), ui.get(settings.yaw.yaw_extra_flick))) or 0

                local offset = 0
                local jt = ui.get(settings.yaw.yaw_jitter)

                if jt == "Offset" or jt == "Custom" or jt == "Center" then
                    if ui.get(settings.yaw.jitter_lr_mode) then
                        offset = side and (ui.get(settings.yaw.yaw_jitter_value_l) + brute_l) or (ui.get(settings.yaw.yaw_jitter_value_r) + brute_r)
                    else

                        local amount = ui.get(settings.yaw.yaw_jitter_amount)
                        offset = side and amount or -amount
                    end

                    if jt == "Offset" then
                        local rand_pct = ui.get(settings.yaw.jitter_random) / 100
                        if rand_pct > 0 then
                            local random_offset = offset * (math.random() * 2 * rand_pct - rand_pct)
                            offset = offset + random_offset
                        end
                    end
                end

                local custom_yaw_offset = ui.get(settings.yaw.yaw_custom) or 0

                local down = ui.get(settings.pitch.pitch) == "Down" and 89 or 0
                local up = ui.get(settings.pitch.pitch) == "Up" and -89 or 0
                local zero = ui.get(settings.pitch.pitch) == "Zero" and 0 or 0
                local random = ui.get(settings.pitch.pitch) == "Random" and math.random(-89,89) or 0
                local custom = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0

            local def_enabled   = ui.get(settings.exploit.hidden)
            local def_type      = settings.exploit.def_type and ui.get(settings.exploit.def_type) or "Hidden"

            if def_enabled and def_type == "Hidden" then
                e.force_defensive = true
            end

            local is_in_def     = sim_diff() <= -1

            if def_enabled and def_type == "Hidden" and is_in_def then

                local yaw_custom = ui.get(settings.hidden.yaw.yaw) == "Custom" and ui.get(settings.hidden.yaw.yaw_value) or 0
                local yaw_lr_h   = ui.get(settings.hidden.yaw.yaw) == "L/R"
                                   and (def_side and ui.get(settings.hidden.yaw.yaw_value_l) + brute_l
                                                  or  ui.get(settings.hidden.yaw.yaw_value_r) + brute_r)
                                   or 0

                e.yaw = normalize_angle(
                    target_yaw + 180 + yaw_lr_h + yaw_spin + yaw_sway
                    + yaw_randomize + yaw_flick + offset + nya
                    + yaw_custom + custom_yaw_offset + manual,
                    -180, 180
                )

                local h = settings.hidden.pitch
                local hpitch = ui.get(h.pitch)
                local downd   = hpitch == "Down"   and  89 or 0
                local upd     = hpitch == "Up"     and -89 or 0
                local randomd = hpitch == "Random" and math.random(-89, 89) or 0
                local customd = hpitch == "Custom" and ui.get(h.pitch_value) or 0
                e.pitch = normalize_angle(downd + upd + randomd + customd, -89, 89)

            elseif def_enabled and def_type == "New" then

                local nd = settings.new_def
                if nd and ui.get(nd.toggle_builder) then
                    local dt_on = ui.get(nd.defensive_on)
                    local is_dt = reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1]:get_hotkey()
                    local is_hs = reference.antiaim.other.on_shot_anti_aim[1]:get() and reference.antiaim.other.on_shot_anti_aim[1]:get_hotkey()

                    local exploit_active = (contains(dt_on, "Double tap") and is_dt) or (contains(dt_on, "Hide shots") and is_hs and not is_dt)

local function is_enemy_visible()
    local enemies = entity.get_players(true)
    local me = entity.get_local_player()

    for i=1, #enemies do
        local ent = enemies[i]
        if not entity.is_dormant(ent) and entity.is_alive(ent) then

            local ex, ey, ez = entity.hitbox_position(ent, 0)

            if ex ~= nil and client.visible(ex, ey, ez) then
                return true
            end
        end
    end
    return false
end

                    local def_mode = ui.get(nd.def_mode)
                    local enemy_visible = is_enemy_visible()

                    local should_run = (def_mode == "Always on") or (def_mode == "On peek" and enemy_visible and exploit_active)

                    if should_run and is_in_def then
                        if nd_active_start == nil then
                            nd_active_start = globals.tickcount()
                        end
                    else
                        nd_active_start = nil
                    end

                    local ticks_active = nd_active_start and (globals.tickcount() - nd_active_start) or 0
                    local duration = ui.get(nd.duration)
                    local within_duration = (duration >= 15) or (ticks_active <= duration)

                    if def_mode == "Always on" then
                        e.force_defensive = true
                    elseif def_mode == "On peek" and enemy_visible and exploit_active then
                        e.force_defensive = true
                    end

                    if should_run and is_in_def and within_duration then

                        local pitch_mode = ui.get(nd.pitch_mode)
                        local raw_pitch  = ui.get(nd.pitch)

                        if ui.get(nd.pitch_height_based) then
                            local me       = entity.get_local_player()
                            local threat   = client.current_threat()
                            if threat then
                                local mpos = vector(entity.get_origin(me))
                                local epos = vector(entity.get_origin(threat))
                                local hdiff = math.ceil(mpos.z - epos.z)
                                raw_pitch = math.max(-89, math.min(89, hdiff * 0.6))
                            end
                        elseif ui.get(nd.pitch_min_max) then
                            local pmin = ui.get(nd.pitch_min)
                            local pmax = ui.get(nd.pitch_max)
                            if pitch_mode == "Static" then
                                raw_pitch = side and pmax or pmin
                            elseif pitch_mode == "Spin" then
                                raw_pitch = pmin + (e.command_number * ui.get(nd.pitch_speed)) % (pmax - pmin + 1)
                            elseif pitch_mode == "Sway" then
                                raw_pitch = pmin + math.abs(math.sin(globals.realtime() * ui.get(nd.pitch_speed) * 0.5)) * (pmax - pmin)
                            elseif pitch_mode == "Jitter" then
                                raw_pitch = e.command_number % 2 == 0 and pmax or pmin
                            elseif pitch_mode == "Cycling" then
                                raw_pitch = pmin + (e.command_number % (pmax - pmin + 1))
                            elseif pitch_mode == "Random" then
                                raw_pitch = math.random(pmin, pmax)
                            end
                        end
                        e.pitch = normalize_angle(raw_pitch, -89, 89)

                        local yaw_type = ui.get(nd.yaw)
                        local nd_offset = 0

                        if yaw_type == "Off" then
                            nd_offset = 0
                        elseif yaw_type == "180" then
                            nd_offset = 0
                        elseif yaw_type == "Spin" then
                            nd_offset = extra_yaw(e.command_number * 16, "Spin", -180, 180)
                        elseif yaw_type == "Distortion" or yaw_type == "Sway" then
                            local spd = ui.get(nd.speed)
                            local amp = ui.get(nd.offset) * 1.5
                            nd_offset = math.sin(globals.realtime() * spd) * amp
                        elseif yaw_type == "Freestand" then
                            local me     = entity.get_local_player()
                            local eye    = vector(client.eye_position())
                            local ang    = vector(client.camera_angles())
                            local td     = {left = 0, right = 0}
                            for i = ang.y - 120, ang.y + 120, 30 do
                                if i ~= ang.y then
                                    local rad  = math.rad(i)
                                    local px   = eye.x + 256 * math.cos(rad)
                                    local py   = eye.y + 256 * math.sin(rad)
                                    local fr   = client.trace_line(me, eye.x, eye.y, eye.z, px, py, eye.z)
                                    local side_name = i < ang.y and "left" or "right"
                                    td[side_name] = td[side_name] + fr
                                end
                            end
                            nd_offset = (td.left < td.right and -1 or 1) * math.abs(ui.get(nd.offset))
                        end

                        if ui.get(nd.yaw_left_right) then
                            nd_offset = side and ui.get(nd.left) or ui.get(nd.right)
                        elseif ui.get(nd.yaw_generation) then
                            nd_offset = math.random(ui.get(nd.min_gen), ui.get(nd.max_gen))
                        end

                        e.yaw = normalize_angle(
                            target_yaw + 180 + nd_offset
                            + yaw_spin + yaw_sway + yaw_randomize + yaw_flick
                            + offset + nya + custom_yaw_offset + manual,
                            -180, 180
                        )

                        local nd_addons = ui.get(nd.addons)
                        if contains(nd_addons, "Freeze-Inverter") then
                            local chance = ui.get(nd.freeze_chance)
                            if math.random(100) <= chance then
                                local freeze_ticks = math.floor(ui.get(nd.freeze_time) / (globals.tickinterval() * 1000))
                                if e.chokedcommands < freeze_ticks then
                                    e.allow_send_packet = false
                                end
                            end
                        end

                    else

                        e.yaw = normalize_angle(
                            target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway
                            + yaw_randomize + yaw_flick + offset + nya
                            + custom_yaw_offset + manual,
                            -180, 180
                        )
                        local down   = ui.get(settings.pitch.pitch) == "Down"   and  89 or 0
                        local up     = ui.get(settings.pitch.pitch) == "Up"     and -89 or 0
                        local rnd    = ui.get(settings.pitch.pitch) == "Random" and math.random(-89, 89) or 0
                        local cust   = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0
                        e.pitch = normalize_angle(down + up + rnd + cust, -89, 89)
                    end
                else

                    e.yaw = normalize_angle(
                        target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway
                        + yaw_randomize + yaw_flick + offset + nya
                        + custom_yaw_offset + manual,
                        -180, 180
                    )
                    local down   = ui.get(settings.pitch.pitch) == "Down"   and  89 or 0
                    local up     = ui.get(settings.pitch.pitch) == "Up"     and -89 or 0
                    local rnd    = ui.get(settings.pitch.pitch) == "Random" and math.random(-89, 89) or 0
                    local cust   = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0
                    e.pitch = normalize_angle(down + up + rnd + cust, -89, 89)
                end

            else

                e.yaw = normalize_angle(
                    target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway
                    + yaw_randomize + yaw_flick + offset + nya
                    + custom_yaw_offset + manual,
                    -180, 180
                )
                local down   = ui.get(settings.pitch.pitch) == "Down"   and  89 or 0
                local up     = ui.get(settings.pitch.pitch) == "Up"     and -89 or 0
                local rnd    = ui.get(settings.pitch.pitch) == "Random" and math.random(-89, 89) or 0
                local cust   = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0
                e.pitch = normalize_angle(down + up + rnd + cust, -89, 89)
            end
            else
                e.pitch = 89
                e.yaw = normalize_angle(get_yaw(false) + 180, -180,180)
            end
        elseif (ui.get(settings.yaw.body_yaw) ~= "Off") then
            if (not ui.get(menu.aa.backward_checkbox)) then
                local inverter = (ui.get(settings.yaw.inverterv2) and ui.get(settings.yaw.body_yaw_value_r) * 2 or -ui.get(settings.yaw.body_yaw_value_l) * 2)
                local inverter1 = (ui.get(settings.yaw.inverterv2) and -ui.get(settings.yaw.body_yaw_value_l) * 2 or ui.get(settings.yaw.body_yaw_value_r) * 2)

                local yaw_lr = ui.get(settings.yaw.lr_offset) and (side and ui.get(settings.yaw.yaw_value_l) + brute_l or ui.get(settings.yaw.yaw_value_r) + brute_r) or 0

                local yaw_spin = (contains(ui.get(settings.yaw.yaw_extra), "Spin") and ui.get(settings.yaw.yaw_extra_spin) ~= 0) and (extra_yaw(e.command_number * 2, "Spin", -ui.get(settings.yaw.yaw_extra_spin), ui.get(settings.yaw.yaw_extra_spin))) or 0
                local yaw_sway = (contains(ui.get(settings.yaw.yaw_extra), "Sway") and ui.get(settings.yaw.yaw_extra_sway) ~= 0) and (extra_yaw(e.command_number * 2, "Sway", -ui.get(settings.yaw.yaw_extra_sway), ui.get(settings.yaw.yaw_extra_sway))) or 0
                local yaw_randomize = contains(ui.get(settings.yaw.yaw_extra), "Randomize") and (extra_yaw(e.command_number * 2, "Randomize", -ui.get(settings.yaw.yaw_extra_randomize), ui.get(settings.yaw.yaw_extra_randomize))) or 0
                local yaw_flick = contains(ui.get(settings.yaw.yaw_extra), "Flick") and (extra_yaw(e.command_number * 2, "Flick", -ui.get(settings.yaw.yaw_extra_flick), ui.get(settings.yaw.yaw_extra_flick))) or 0

                local offset = 0
                local jt = ui.get(settings.yaw.yaw_jitter)

                if jt == "Offset" or jt == "Custom" or jt == "Center" then
                    if ui.get(settings.yaw.jitter_lr_mode) then
                        offset = side and (ui.get(settings.yaw.yaw_jitter_value_l) + brute_l) or (ui.get(settings.yaw.yaw_jitter_value_r) + brute_r)
                    else

                        local amount = ui.get(settings.yaw.yaw_jitter_amount)
                        offset = side and amount or -amount
                    end

                    if jt == "Offset" then
                        local rand_pct = ui.get(settings.yaw.jitter_random) / 100
                        if rand_pct > 0 then
                            local random_offset = offset * (math.random() * 2 * rand_pct - rand_pct)
                            offset = offset + random_offset
                        end
                    end
                end

                local body_yaw_val = ui.get(settings.yaw.body_yaw) == "Off" and 0 or
                    (ui.get(settings.yaw.body_yaw) == "Static" and inverter or
                    (ui.get(settings.yaw.body_yaw) == "L/R" and (side and inverter1 or inverter) or
                    (ui.get(settings.yaw.body_yaw) == "Sway" and extra_yaw(e.command_number * 8, "Sway", inverter1, inverter) or 0)))
                e.yaw = normalize_angle(target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway + yaw_randomize + yaw_flick + offset + nya  + body_yaw_val + manual, -180, 180)
                e.pitch = 90
            else
                e.yaw = normalize_angle(get_yaw(false) + 180, -180,180)
                e.pitch = 90
            end
        end
        reference.antiaim.angles.enabled:set(true)
        reference.antiaim.angles.pitch[1]:set("Down")
        reference.antiaim.angles.body_yaw[1]:set("Off")
        reference.antiaim.angles.yaw[1]:set("180")
        reference.antiaim.angles.yaw[2]:set(0)
        reference.antiaim.angles.yaw_jitter[1]:set("Off")
    else
        reference.antiaim.angles.enabled:set(true)
        reference.antiaim.angles.pitch[1]:set("Down")
        reference.antiaim.angles.body_yaw[1]:set("Static")
        reference.antiaim.angles.yaw[1]:set("180")
        reference.antiaim.angles.yaw[2]:set(0)
        reference.antiaim.angles.yaw_jitter[1]:set("Off")
        reference.antiaim.angles.body_yaw[2]:set((side and 1 or -1))
        e.force_defensive = true
    end
end)
client.set_event_callback("setup_command", function(e)
    reference.antiaim.fakelag.amount:set(ui.get(menu.aa.fakelag_amount))
    reference.antiaim.fakelag.variance:set(ui.get(menu.aa.fakelag_variance))
    reference.antiaim.fakelag.limit:set(ui.get(menu.aa.fakelag_limit))
    cvar_maxticks:set_int(16)
    if (ui.get(menu.features.miscellaneous.recharge) and not ui.get(menu.features.miscellaneous.airlag_key)) then
        if ((reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get()) ~= dt_state[1] and (reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get())) then
            dt_state[2] = globals.tickcount() + 14
        end
        reference.rage.aimbot.enabled[1]:set(globals.tickcount() > dt_state[2])
        dt_state[1] = (reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get())
    else
        if ((reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get()) ~= dt_state[1] and (reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get())) then
            dt_state[2] = globals.tickcount() + 14
        end
        reference.rage.aimbot.enabled[1]:set(true)
        if (ui.get(menu.features.miscellaneous.airlag) and ui.get(menu.features.miscellaneous.airlag_key) and (reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get())) then
            reference.rage.aimbot.enabled[1]:set(globals.tickcount() > dt_state[2])
            cvar_maxticks:set_int(19)
            if (globals.tickcount() % ui.get(menu.features.miscellaneous.airlag_ticks) == 0) then
                reference.rage.aimbot.double_tap[1]:set(false)
                e.force_defensive = false
            else
                reference.rage.aimbot.double_tap[1]:set(true)
                e.force_defensive = true
            end

            if (globals.tickcount() > dt_state[2] + 4) then dt_state[2] = globals.tickcount() + 14 end
        elseif ui.get(menu.features.miscellaneous.airlag) then
            reference.rage.aimbot.double_tap[1]:set(true)
        end
        dt_state[1] = (reference.rage.aimbot.double_tap[1]:get_hotkey() and reference.rage.aimbot.double_tap[1]:get())
    end
    if ui.is_menu_open() then
        e.in_attack = false
        e.in_attack2 = false
    end
    local no_enemy = false
    gamerulesproxy = entity.get_all("CCSGameRulesProxy")[1]
    local player_resource = entity.get_player_resource()

    if player_resource then
        local are_all_enemies_dead = true
        local enemy_found = false

        for i = 1, globals.maxplayers() do
            if entity.get_prop(player_resource, 'm_bConnected', i) == 1 then
                if entity.is_enemy(i) then
                    enemy_found = true
                    if entity.is_alive(i) then
                        are_all_enemies_dead = false
                        break
                    end
                end
            end
        end

        if not enemy_found or are_all_enemies_dead then
            no_enemy = true
        end
    end
    if contains(ui.get(menu.aa.safe_head), "On Zeus") then
        if client.current_threat() then
            local weapon = entity.get_player_weapon(entity.get_local_player())
            if weapon and (entity.get_classname(weapon) == "CWeaponTaser") then
                e.yaw = get_yaw(true) + 180
                e.pitch = 90
                e.force_defensive = true
            end
        end
    end
    if contains(ui.get(menu.aa.safe_head), "On Knife") then
        if client.current_threat() then
            local weapon = entity.get_player_weapon(entity.get_local_player())
            if weapon and (entity.get_classname(weapon) == "CKnife") then
                e.yaw = get_yaw(true) + 180
                e.pitch = 90
                e.force_defensive = true
            end
        end
    end
    if contains(ui.get(menu.aa.safe_head), "On R8") then
        if client.current_threat() then
            local weapon = entity.get_player_weapon(entity.get_local_player())
            if weapon and (weapon == 178) then
                e.yaw = get_yaw(true) + 180
                e.pitch = 90
                e.force_defensive = false
            end
        end
    end
    if (ui.get(menu.aa.warmup_aa) ~= "Off" and (entity.get_prop(gamerulesproxy,"m_bWarmupPeriod") == 1 or no_enemy or entity.get_prop(entity.get_game_rules(), "m_bFreezePeriod") == 1)) and can_runaa(e) and entity.get_prop(entity.get_local_player(),"m_MoveType") ~= 9 and entity.get_local_player() and entity.is_alive(entity.get_local_player()) then
        local spin = (ui.get(menu.aa.warmup_aa) == "Spin" and extra_yaw(e.command_number * 16, "Spin", -180,180) or 0)
        local Symphony = (ui.get(menu.aa.warmup_aa) == "Nyanza" and extra_yaw(e.command_number * 5, "Sway", -190,190) or 0)
        local Symphonyb = (ui.get(menu.aa.warmup_aa) == "Nyanza Beta" and extra_yaw(e.command_number * 5, "Sway", -190,190) or 0)
        e.yaw = normalize_angle(spin + Symphony + Symphonyb,-180,180)

        if (ui.get(menu.aa.warmup_aa) == "Spin") then e.pitch = 0 end
        if (ui.get(menu.aa.warmup_aa) == "Nyanza Beta") then e.pitch = math.max(-90,math.min(Symphonyb / 190 * 90,90)) end
        reference.antiaim.fakelag.limit:set(1)
    end
    if ui.get(menu.features.miscellaneous.fastladder) then
        if entity.get_prop(entity.get_local_player(),"m_MoveType") == 9 and entity.get_local_player() and entity.is_alive(entity.get_local_player()) and can_runaa(e) then
            if e.sidemove == 0 then
                e.yaw = e.yaw + 45;
            end;
            if e.in_forward and e.sidemove < 0 then
                e.yaw = e.yaw + 90;
            end;
            if e.in_back and e.sidemove > 0 then
                e.yaw = e.yaw + 90;
            end;
            e.in_moveleft = e.in_back;
            e.in_moveright = e.in_forward;
            if e.pitch < 0 then
                e.pitch = -45;
            end;
        end
    end
end)
vector3_distance = function(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
end
closest_point_on_ray = function(tx, ty, tz, startx, starty, startz, endx, endy, endz)
    local tox, toy, toz = tx - startx, ty - starty, tz - startz
    local dirx, diry, dirz = endx - startx, endy - starty, endz - startz
    local length = math.sqrt(dirx^2 + diry^2 + dirz^2)
    dirx, diry, dirz = dirx / length, diry / length, dirz / length
    local range_along = dirx * tox + diry * toy + dirz * toz
    if range_along < 0 then
        return startx, starty, startz
    end
    if range_along > length then
        return endx, endy, endz
    end
    return startx + dirx * range_along, starty + diry * range_along, startz + dirz * range_along
end
local evaded_shots_count = 0
client.set_event_callback("bullet_impact", function(e)
    local me = entity.get_local_player()
    if entity.is_alive(me) then
        if bruted_last_time < globals.curtime() then
            local ent = client.userid_to_entindex(e.userid)
            if not entity.is_dormant(ent) and entity.is_enemy(ent) then

                local headx, heady, headz = entity.hitbox_position(me, 0)
                local eyex, eyey, eyez = entity.get_origin(ent)
                eyez = eyez + 64
                local x, y, z = closest_point_on_ray(headx, heady, headz, eyex, eyey, eyez, e.x, e.y, e.z)
                if vector3_distance(x, y, z, headx, heady, headz) < 88 then
                    bruted_last_time = globals.curtime() + 0.250
                    bruted = true

                    brute_l = math.random(-ui.get(menu.aa.antibrute_l), 0)
                    brute_r = math.random(0,ui.get(menu.aa.antibrute_r))
                    brute_d = math.random(0,ui.get(menu.aa.antibrute_delay))

                    logs.add("Evaded "..entity.get_player_name(ent):lower().."'s shot ")
                    evaded_shots_count = evaded_shots_count + 1
                    ui.set(menu.rage.statistics.evaded_shots, "" .. lua_color .. "\aCDCDCDFFEvaded shots: " .. lua_color .. "" .. tostring(evaded_shots_count))
                end
            end
        end
    end
end)

local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "null", "gear"}

local last_aim_data = {
    backtrack = 0,
    hitgroup = 0,
    damage = 0,
    hit_chance = 0,
    target = nil
}

local function get_script_color()
    local c = hexToRgb(lua_color)
    return c[1], c[2], c[3]
end

client.set_event_callback("aim_fire", function(e)
    last_aim_data = {
        backtrack = globals.tickcount() - e.tick,
        hitgroup = e.hitgroup,
        damage = e.damage,
        hit_chance = e.hit_chance,
        target = e.target
    }
end)

client.set_event_callback("aim_miss", function(e)
    local r, g, b = get_script_color()
    local victim_name = entity.get_player_name(e.target)
    local wanted_group = hitgroup_names[last_aim_data.hitgroup + 1] or "?"
    local reason = e.reason == "?" and "unknown" or e.reason

    if logs.add_typed then
        logs.add_typed("Missed " .. victim_name:lower() .. " in " .. wanted_group .. " due to " .. reason, "miss")
    end

    client.color_log(255, 255, 255, "missed \0")
    client.color_log(r, g, b, string.format("%s \0", victim_name:lower()))
    client.color_log(255, 255, 255, "in \0")
    client.color_log(r, g, b, string.format("%s \0", wanted_group))
    client.color_log(255, 255, 255, "due to \0")
    client.color_log(r, g, b, string.format("%s \0", reason))
    client.color_log(255, 255, 255, "/ estimated damage - \0")
    client.color_log(r, g, b, string.format("%d \0", last_aim_data.damage))
    client.color_log(255, 255, 255, string.format("[hc: %d%% / bt: %dt]", math.ceil(last_aim_data.hit_chance), last_aim_data.backtrack))
end)

client.set_event_callback("player_hurt", function(e)
    local attacker = client.userid_to_entindex(e.attacker)
    if attacker ~= entity.get_local_player() then return end

    local victim = client.userid_to_entindex(e.userid)
    local victim_name = entity.get_player_name(victim)
    local damage = e.dmg_health
    local health = e.health
    local hitgroup = e.hitgroup
    local group = hitgroup_names[hitgroup + 1] or "?"

    local r, g, b = get_script_color()
    local weapon = e.weapon

    local action = "hit"
    if health <= 0 then
        action = "killed"
    elseif weapon == "hegrenade" then
        action = "naded"
    elseif weapon == "inferno" or weapon == "molotov" then
        action = "burned"
    elseif weapon == "knife" then
        action = "knifed"
    elseif weapon == "taser" then
        action = "zeused"
    end

    if logs.add then
        local log_text
        if action == "killed" then

            log_text = "Killed " .. victim_name:lower()
        else

            log_text = action:gsub("^%l", string.upper) .. " " .. victim_name:lower() .. " in " .. group .. " for " .. damage .. " damage"
        end
        logs.add(log_text)
    end

    if health > 0 then
        client.color_log(255, 255, 255, string.format("%s \0", action))
        client.color_log(r, g, b, string.format("%s \0", victim_name:lower()))
        client.color_log(255, 255, 255, "in \0")
        client.color_log(r, g, b, string.format("%s \0", group))
        client.color_log(255, 255, 255, "for \0")
        client.color_log(r, g, b, string.format("%d \0", damage))
        client.color_log(255, 255, 255, "damage / hp remaining - \0")
        client.color_log(r, g, b, string.format("%d \0", health))

        if last_aim_data.target == victim then
            local wanted_group = hitgroup_names[last_aim_data.hitgroup + 1] or "?"
            if hitgroup ~= last_aim_data.hitgroup then
                client.color_log(255, 255, 255, string.format("[hc: %d%% / bt: %dt / mismatched %s for %d dmg]",
                    last_aim_data.hit_chance, last_aim_data.backtrack, wanted_group, last_aim_data.damage))
            else
                client.color_log(255, 255, 255, string.format("[hc: %d%% / bt: %dt]",
                    last_aim_data.hit_chance, last_aim_data.backtrack))
            end
        else
            client.color_log(255, 255, 255, "")
        end
    else
        client.color_log(255, 255, 255, "killed \0")
        client.color_log(r, g, b, string.format("%s \0", victim_name:lower()))
        client.color_log(255, 255, 255, "in \0")
        client.color_log(r, g, b, string.format("%s \0", group))

        if last_aim_data.target == victim then
            client.color_log(255, 255, 255, string.format("[hc: %d%% / bt: %dt]",
                last_aim_data.hit_chance, last_aim_data.backtrack))
        else
            client.color_log(255, 255, 255, "")
        end
    end
end)

local clan_tag_spammer do
    local clan_tag_prev = ''
    local enabled_prev = false
    local sequence = {
        '               ',
        'o              ',
        'ov#            ',
        'ove$           ',
        'over!?         ',
        'overf@         ',
        'overfl*        ',
        'overfla#       ',
        'overflam$      ',
        'overflame!     ',
        ' overflame     ',
        '  overflame    ',
        '   overflame   ',
        '    overflame  ',
        '     overflame ',
        '      overflam#',
        '       overfl* ',
        '        overf@ ',
        '         over! ',
        '          ove$ ',
        '           ov# ',
        '            o  ',
        '               ',
    }

    local function clan_tag_anim()
        local tickinterval = globals.tickinterval()
        local tickcount = globals.tickcount() + math.floor(client.latency() / globals.tickinterval() + .5)
        local i = math.floor(tickcount / math.floor(0.2 / tickinterval + .5)) % #sequence + 1
        return sequence[i]
    end

    local function clan_tag_original()
        local clanid = cvar.cl_clanid.get_int()
        if clanid == 0 then return '\0' end
        local clan_count = steamworks.ISteamFriends.GetClanCount()
        for i = 0, clan_count do
            local group_id = steamworks.ISteamFriends.GetClanByIndex(i)
            if group_id == clanid then
                return steamworks.ISteamFriends.GetClanTag(group_id)
            end
        end
    end

    local function on_paint()
        local enabled = ui.get(menu.rage.rage_section.clantag)
        if enabled then
            local local_player = entity.get_local_player()
            local clan_tag = clan_tag_anim()

            if local_player ~= nil and globals.tickcount() % 2 == 0 or (not entity.is_alive(local_player)) and globals.tickcount() % 2 == 0 then
                if clan_tag ~= clan_tag_prev then
                    client.set_clan_tag(clan_tag)
                    clan_tag_prev = clan_tag
                end
            end
        elseif enabled_prev then
            client.set_clan_tag(clan_tag_original())
        end

        enabled_prev = enabled
    end

    local function on_run_command(e)
        if ui.get(menu.rage.rage_section.clantag) and e.chokedcommands == 0 then
            on_paint()
        end
    end

    client.set_event_callback('paint', on_paint)
    client.set_event_callback('run_command', on_run_command)
end

local trash_talk do
    local phrases = {
        simple = {
            {"1", 1.0}
        },

        kill = {

            {"⛧ BLOODYSTAR.COM", 0.2},
            {"в следующий раз сначала прицелься", 0.2, "а потом стреляй", 1.0},
            {"⛧ Ä§MÖÐÈÚ§ £ÚÇK§ ÚR §ÖÚL", 0.2},
            {"๖໐p_๖_3คk໐hē ¢๖นh9i_๖_3คr໐hē", 0.2},
            {"𝐝𝐞𝐥𝐞𝐭𝐞 𝐮𝐫 𝐬𝐡𝐢𝐭 𝐜𝐡𝐞𝐚𝐭", 0.2},
            {"1", 1.0},
            {"gê† rê§† §lðwmð", 0.2},
            {"ĐØⱠ฿₳Ɇ฿ ĐɆ₮Ɇ₵₮Ɇ0", 0.2},
            {"(っ◔◡◔)っ ♥ heil hitler ♥", 0.2},
            {"ⲙⲩⲭⲁⲙⲙⲁⲇⲥⲟⳝυⲣ ⲫⲁύⳅⲟⲃ", 0.2, "м̻͓̞͇̮͒̎͂͛ͣ͑ͪ̈͋у̳̬̙͚ͭͪͬͫ͐͂ͧ̃̎́̃ͬͬ͐̿ͦͬ̚х͓̫͎̮̘͓̦͇̝̜̜̻͎͚̘̎ͨ̍̿ͪͨ͐ͮͩ̅̚а̠͉̥̣͙̻͆͌̆̀̀́̈̉ͪ̊͐̽͊ͨ̍̚м͈̫̱͙̲͇͚̳̣̟̝̟̝̯̠͑́ͮͯ̾͑̚ͅм͖̫͖͔͚̥͈̖͉̖̗͇̦̹͓̬͍̳ͫ̂͂̇̇а̗̗̟̣ͧ̔͛̎͛̎ͩ͊ͣ͐͋͂̚д̬̱͔̭̬͎̪͕̪̹̱̣͈̭͕͑̈́̽ͮ̽ͥ͛͆̔̒̃ͩс̘͔̱̬̟͕̊̑̀̀̒̀͋ͧ͆́̏̿̆ͧ̃о̟̣̞͔̳͙͉̲̥͐̒̊͛ͩ̑ͬͥ̓̂̉̆̄ͤ̉͑̽͐̿б̠̤̫͙̯̰̱̻͙̬̙̯̣͚̬̳̗ͫ̑̒̉̍̋̇̔ͭ̃̐͋͛ͪ̚и̘̥͕̗̲̥̗̪͇̹͎̜̭̲̤̺̜̟̋͑͐͒ͪ̓̒̌ͥ̑ͯͮ͌̒ͯͥ̀́̎р̺̰͕͙͇͉̣̪̜̭̰̝͙̖͕̗͎̜ͮ̈̎ͫ͛̆̚ ͍̙̫͎͉͔̰̬̼͙̓ͤ̿̅͊́̅̔ф̪͇̤̤̒͆̀́̊̉ͯ̉ͪͪа̥͓͈̟̜̣͍͚͚̫̲̦̤͚͕̦̥͖̳̄̔̾ͧ̐̏̉͋̋͂̌ͤ͆й̼̮̼̙̩̲̳̠̺͍͍̼ͭ͑͋ͣ͐͂͋̉͒ͦͬͨͮ̓̚ͅз͍̗͖͍̠̟͚͎̣̺͔̺̰̙̹͕͔̎̍͒̓̂ͫ͒̈́͌͗̿͋̍ͫ̉̈ͨͯͅо̦͔͇̤̤͉̦̞̳̩̦̝̜̘̦͉̰̰̾̿͛̃̋͑͐͆̄ͅв͍̲̲̦͇̹̻̼̖̠̻͚̱̺ͮ̈́͌̋̽̍̓̓͑͋̚ͅ", 0.2},
            {"смешные моменты хвх", 1.0}
        },

        death = {
            {"НУ ОВТ ДОЛБАЕБ БЛЯЬ", 3, "НУ ВОТ ЫТ СУКА КАК ДЕЛАЕШЬ ТОЭ", 2.5, "НУ ПРОСТО МРАЩОТА", 1.8, "ТИУПАЯ", 2},
            {"да ебать твою мать", 1, "ты как сука это", 2, "даелаешь", 3}
        }
    }

    local phrase_count = {
        simple = 0,
        kill = 0,
        death = 0
    }

    local function say_phrases (phrase_table)
        local current_delay = 0
        for i = 1, #phrase_table, 2 do
            local message = phrase_table[i]
            local delay = phrase_table[i+1] or 3

            current_delay = current_delay + delay
            client.delay_call(current_delay, function ()
                client.exec(('say %s'):format(message))
            end)
        end
    end

    local killed_enemies = 0

    local function on_player_death (e)

        local player, victim, attacker = entity.get_local_player(), client.userid_to_entindex(e.userid), client.userid_to_entindex(e.attacker)
        if not player or not victim or not attacker then
            return
        end
        if attacker == player and victim ~= player then
            killed_enemies = killed_enemies + 1
            ui.set(menu.rage.statistics.enemy_killed, "\aCDCDCDFFEnemy killed: " .. lua_color .. "" .. tostring(killed_enemies))
        end
        if not ui.get(menu.rage.rage_section.trash_talk.enable) then
            return
        end

        if attacker == player and victim ~= player then
            phrase_count.simple = (phrase_count.simple % #phrases.simple) + 1
            phrase_count.kill = (phrase_count.kill % #phrases.kill) + 1
        elseif victim == player and attacker ~= player then
            phrase_count.death = (phrase_count.death % #phrases.death) + 1
        end

        local selected_phrases = {
            simple = phrases.simple[phrase_count.simple],
            kill = phrases.kill[phrase_count.kill],
            death = phrases.death[phrase_count.death]
        }

        local trash_type = ui.get(menu.rage.rage_section.trash_talk.setting.type)
        local work_selections = ui.get(menu.rage.rage_section.trash_talk.setting.work)

        if contains(work_selections, 'On kill') and attacker == player and victim ~= player then
            say_phrases(trash_type == 'Simple' and selected_phrases.simple or selected_phrases.kill)
        elseif contains(work_selections, 'On death') and victim == player and attacker ~= player then
            say_phrases(selected_phrases.death)
        end
    end

    client.set_event_callback('player_death', on_player_death)
end

local jitter_offset = 0
local body_offset_l = 0
local body_offset_r = 0
local last_update_time = 0

local function is_any_enemy_visible()
    local enemies = entity.get_players(true)
    for _, ent in ipairs(enemies) do
        if entity.is_alive(ent) and not entity.is_dormant(ent) then
            return true
        end
    end
    return false
end

local function update_dynamic_aa()
    local preset = ui.get(menu.aa.preset)
    local state_name = ui.get(menu.aa.state)
    local st = menu.aa[state_name]
    local global = menu.aa[ lua_color .. '›\a9D9D9DFF  Stand']

    if not st or not st.yaw or not global or not global.yaw then
        return
    end

    if preset == 2 then
        ui.set(st.yaw.yaw_jitter, "Offset")
        ui.set(st.yaw.yaw_jitter_value_l, -35)
        ui.set(st.yaw.yaw_jitter_value_r, 35)

        if st.yaw.add_addons then ui.set(st.yaw.add_addons, false) end
        ui.set(st.yaw.yaw_extra, {})

    elseif preset == 3 then
        local any_visible = is_any_enemy_visible()

        if any_visible then
            local cur_time = globals.curtime()

            if cur_time - last_update_time > math.random(12, 35) / 100 then
                last_update_time = cur_time
                jitter_offset = math.random(-4, 4)
                body_offset_l = math.random(-9, 6)
                body_offset_r = math.random(-6, 9)
            end

            ui.set(global.yaw.yaw_jitter, "Offset")
            ui.set(global.yaw.yaw_jitter_value_l, -10 + jitter_offset)
            ui.set(global.yaw.yaw_jitter_value_r,  10 + jitter_offset)

            ui.set(global.yaw.body_yaw, "Static")
            ui.set(global.yaw.body_yaw_value_l, math.min(60, 55 + body_offset_l))
            ui.set(global.yaw.body_yaw_value_r, math.min(60, 55 + body_offset_r))
        else
            ui.set(global.yaw.yaw_jitter, "Off")
            ui.set(global.yaw.body_yaw, "Static")
            ui.set(global.yaw.body_yaw_value_l, 0)
            ui.set(global.yaw.body_yaw_value_r, 0)
        end
    end
end

ui.set_callback(menu.aa.preset, update_dynamic_aa)
ui.set_callback(menu.aa.state, function()
    client.delay_call(0.03, update_dynamic_aa)
end)

client.set_event_callback("setup_command", function()
    if ui.get(menu.aa.preset) == 3 then
        update_dynamic_aa()
    end
end)

client.delay_call(0.2, update_dynamic_aa)

client.set_event_callback("paint", function()
    local enabled = ui.get(menu.features.miscellaneous.predict_enemies)

    if enabled then
        cvar.cl_interpolate:set_int(0)
        cvar.cl_interp_ratio:set_int(1)

        cvar.cl_interp:set_float(0)
    else

        cvar.cl_interpolate:set_int(1)
        cvar.cl_interp_ratio:set_int(2)

    end
end)

client.set_event_callback("shutdown", function()
    cvar.cl_interpolate:set_int(1)
    cvar.cl_interp_ratio:set_int(2)
end)

local hitchance_ref = ui.reference("RAGE", "Aimbot", "Minimum hit chance")

client.set_event_callback("paint", function()
    if not menu.rage or not menu.features.miscellaneous.correction then return end

    local enabled = ui.get(menu.features.miscellaneous.correction)

    if enabled then
        local lp = entity.get_local_player()
        if not lp or not entity.is_alive(lp) then return end

        local weapon_ent = entity.get_player_weapon(lp)
        if weapon_ent == nil then return end

        local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
        local weapon_id = bit.band(weapon_idx, 0xFFFF)

        if weapon_id == 9 or weapon_id == 40 then
            ui.set(hitchance_ref, 100)
        end
    end
end)

local mouse_hold_right = false
local beta_font_mode = 1
local beta_font_modes = {" ", "b", "c-"}
local beta_font_names = {"Normal", "Bold", "Small"}
local overflame_beta_anim = 0

client.set_event_callback("paint_ui", function()
    local wm_active = contains(ui.get(menu.features.visuals.watermark_type), "Text Watermark") and ui.get(menu.features.visuals.watermark_selection)
    overflame_beta_anim = interface.animate(overflame_beta_anim, wm_active and 1 or 0, 10)

    do
        local font = beta_font_modes[beta_font_mode]
        local text1 = "Overflame"
        local text2 = " / " .. lua:display()
        local w1 = renderer.measure_text(font, text1)
        local w2 = renderer.measure_text(font, text2)
        dragging_system.set_width(overflame_beta, w1 + w2 + 10)
        dragging_system.set_height(overflame_beta, 19)
    end

    if overflame_beta_anim < 0.01 then
        font_ctx_menu.open = false
        pos_ctx_menu.open  = false
        return
    end

    if not contains(ui.get(menu.features.visuals.watermark_type), "Text Watermark") then
        font_ctx_menu.open = false; font_ctx_menu.closing = true
        pos_ctx_menu.open  = false; pos_ctx_menu.closing  = true
    end

    if not ui.is_menu_open() then
        font_ctx_menu.open = false; font_ctx_menu.closing = true
        pos_ctx_menu.open  = false; pos_ctx_menu.closing  = true
    end

    local x, y   = overflame_beta.x, overflame_beta.y
    local font   = beta_font_modes[beta_font_mode]
    local mx, my = ui.mouse_position()

    local text1     = "Overflame"
    local text2     = " / " .. lua:display()
    local w1        = renderer.measure_text(font, text1)
    local w2        = renderer.measure_text(font, text2)
    local full_width = w1 + w2
    local height    = 24
    local _, th     = renderer.measure_text(font, "A")

    dragging_system.set_width(overflame_beta, full_width + 10)
    dragging_system.set_height(overflame_beta, height - 5)

    local center_x = x + (overflame_beta.w - full_width) / 2
    local text_y   = y + math.floor((height - th) / 2) - 1

    local fa = math.floor(255 * overflame_beta_anim)
    local fa200 = math.floor(200 * overflame_beta_anim)
    renderer.text(center_x,      text_y, menu_r, menu_g, menu_b, fa,   font, 0, text1)
    renderer.text(center_x + w1, text_y, 200,    200,    200,    fa200, font, 0, text2)

    local hovered = mx >= x and mx <= x + overflame_beta.w and my >= y and my <= y + height

    if hovered and ui.is_menu_open() and client.key_state(0x02) and not mouse_hold_right then
        local sw, sh   = client.screen_size()
        local both_w   = font_ctx_menu.w + pos_ctx_menu.w + 4
        local open_x   = math.min(x, sw - both_w - 2)
        local in_lower_half = (y + height / 2) > (sh / 2)
        local open_up = in_lower_half
        local anch
        if open_up then
            anch = y
        else
            anch = y + height + 4
        end
        if not font_ctx_menu.open and not pos_ctx_menu.open then
            font_ctx_menu.open     = true
            font_ctx_menu.x        = open_x
            font_ctx_menu.open_up  = open_up
            font_ctx_menu.anchor_y = anch
            font_ctx_menu.anim     = 0

            pos_ctx_menu.open      = true
            pos_ctx_menu.x         = open_x + font_ctx_menu.w + 4
            pos_ctx_menu.open_up   = open_up
            pos_ctx_menu.anchor_y  = anch
            pos_ctx_menu.anim      = 0
        else
            font_ctx_menu.open = false; font_ctx_menu.closing = true
            pos_ctx_menu.open  = false; pos_ctx_menu.closing  = true
        end
    end

    mouse_hold_right = client.key_state(0x02)
end)
local color do
local create_color, create_color_object, Color do
    Color = {} do
        function Color:clone()
            return create_color_object(
                self.r, self.g, self.b, self.a
            )
        end

        function Color:to_hex()
            return ('%02X%02X%02X%02X'):format(self.r, self.g, self.b, self.a)
        end

        function Color:as_hex(hex_value)
            local r, g, b, a = hex_value:match('(%x%x)(%x%x)(%x%x)(%x%x)')

            return create_color_object(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16))
        end

        function Color:lerp(color_target, weight)
            return create_color_object(
                c_math.lerp(self.r, color_target.r, weight),
                c_math.lerp(self.g, color_target.g, weight),
                c_math.lerp(self.b, color_target.b, weight),
                c_math.lerp(self.a, color_target.a, weight)
            )
        end

        function Color:grayscale(ratio)
            return create_color_object(
                self.r * ratio,
                self.g * ratio,
                self.b * ratio,
                self.a
            )
        end

        function Color:alpha_modulate(alpha, modulate)
            return create_color_object(
                self.r,
                self.g,
                self.b,
                modulate and self.a*alpha or alpha
            )
        end

        function Color:unpack()
            return self.r, self.g, self.b, self.a
        end
    end

    function create_color_object(self, ...)
        local args = {...}

        if type(self) == 'number' then
            table.insert(args, 1, self)
        end

        if type(args[1]) == 'table' then
            if args[1][1] then
                args = args[1]
            else
                args = {args[1].r, args[1].g, args[1].b, args[1].a}
            end
        end

        if type(args[1]) == 'string' then
            return setmetatable({
                r = 255, g = 255, b = 255, a = 255
            }, {
                __index = Color
            }):as_hex(args[1])
        end

        return setmetatable({
            r = args[1] or 255,
            g = args[2] or 255,
            b = args[3] or 255,
            a = args[4] or 255
        }, {
            __index = Color
        })
    end

    local stock_colors = {} do
        stock_colors.raw_green = create_color_object(0, 255, 0);
        stock_colors.raw_red = create_color_object(255, 0, 0);

        stock_colors.red = create_color_object(255, 0, 50);
        stock_colors.white = create_color_object();
        stock_colors.gray = create_color_object(200, 200, 200);
        stock_colors.green = create_color_object(143, 194, 21);
        stock_colors.sea = create_color_object(59, 208, 182);
        stock_colors.blue = create_color_object(95, 156, 204);
        stock_colors.pink = create_color_object(209, 101, 145);
        stock_colors.yellow = create_color_object(233, 213, 2);
        stock_colors.purplish = create_color_object(193, 144, 252);

        stock_colors.onshot = create_color_object(100, 148, 237, 255);
        stock_colors.freestanding = create_color_object(132, 195, 16, 255);
        stock_colors.edge = create_color_object(209, 159, 230, 255);
        stock_colors.fixik = create_color_object('00FFCBFF');

        stock_colors.string_to_color_array = (function (str)
            local arr =  {}
            local match, mend = str:find('\a')

            if not match then
                arr[#arr+1] = str
            else
                while match do
                    local prmatch = match
                    local prend = mend

                    match, mend = str:find('\a', match+1)

                    if match == nil then
                        arr[#arr+1] = str:sub(prend, #str)

                        break
                    else
                        arr[#arr+1] = str:sub(prmatch, match-1)
                    end
                end
            end

            local cnt = 0
            local out = {}

            for i=1, #arr do
                for hex_col, s in arr[i]:gmatch('\a(%x%x%x%x%x%x%x%x)(.+)') do
                    out[#out+1] = {
                        color = create_color(hex_col),
                        text = s
                    };

                    cnt = cnt + 1
                end
            end

            if cnt == 0 then
                out[#out+1] = {
                    color = create_color('FFFFFFFF'),
                    text = str
                }
            end

            return out
        end)

        stock_colors.animated_text = (function (text, speed, color_start, color_end, alpha)
            local first = color_start and create_color(color_start.r, color_start.g, color_start.b, alpha) or create_color(255, 200, 255, alpha)
            local second = color_end and create_color(color_end.r, color_end.g, color_end.b, alpha) or create_color(100, 100, 100, alpha)

            local res = ""

            for idx = 1, #text + 1 do
                local letter = text:sub(idx, idx)

                local alpha1 = (idx - 1) / (#text - 1)
                local m_speed = globals.realtime() * ((50 / 25) or 1.0)
                local m_factor = m_speed % math.pi

                local c_speed = speed or 1
                local m_sin = math.sin(m_factor * c_speed + (alpha1 or 0))
                local m_abs = math.abs(m_sin)
                local clr = first:lerp(second, m_abs)

                res = ("%s\a%s%s"):format(res, clr:to_hex(), letter)
            end

            return res
        end)
    end

    create_color = setmetatable(stock_colors, {
        __call = create_color_object
    })
end

color = create_color
end

local c_math do
c_math = {} do
    c_math.min = (function (a, b)
        return a > b and b or a
    end)

    c_math.max = (function (a, b)
        return a > b and a or b
    end)

    c_math.abs = (function (a)
        return a > 0 and a or -a
    end)

    c_math.round = (function (a)
        return math.floor(a+0.5)
    end)

    c_math.normalize_yaw = (function (a)
        while a > 180 do
            a = a - 360
        end

        while a < -180 do
            a = a + 360
        end

        return a
    end)

    c_math.clamp = (function (v, min, max)
        if v > max then
            return max
        end

        if v < min then
            return min
        end

        return v
    end)

    c_math.random = (function (min, max)
        return client.random_int(min, max)
    end)

    c_math.randomf = (function (min, max)
        return min + (max-min)*math.random()
    end)

    c_math.lerp = (function (a, b, v)
        return a + (b - a) * v
    end)

    c_math.extrapolate = (function (ent, origin, ticks)
        local tickinterval = globals.tickinterval()

        local sv_gravity = cvar.sv_gravity:get_float() * tickinterval
        local sv_jump_impulse = cvar.sv_jump_impulse:get_float() * tickinterval

        local p_origin, prev_origin = origin, origin

        local velocity = vector(entity.get_prop(ent, 'm_vecVelocity'))
        local gravity = velocity.z > 0 and -sv_gravity or sv_jump_impulse

        for i=1, ticks do
            prev_origin = p_origin
            p_origin = vector(
                p_origin.x + (velocity.x * tickinterval),
                p_origin.y + (velocity.y * tickinterval),
                p_origin.z + (velocity.z+gravity) * tickinterval
            )

            local fraction = client.trace_line(-1,
                prev_origin.x, prev_origin.y, prev_origin.z,
                p_origin.x, p_origin.y, p_origin.z
            )

            if fraction <= 0.99 then
                return prev_origin
            end
        end

        return p_origin
    end)
end
end

custom_output = {} do
local list = {}

client.set_event_callback("paint_ui", function (ctx)
    if #list == 0 then
        return
    end

    local hs = select(2, renderer.measure_text("b", 'A'))
    local x, y, size = 8, 5, hs

    local ft = globals.frametime()

    for i=#list, 1, -1 do
        local notify = list[i]

        if notify then
            notify.m_time = notify.m_time - ft

            if notify.m_time <= 0.0 then
                notify.m_anim_alpha = c_math.lerp(notify.m_anim_alpha, 0.0, ft * 10.0)
                if notify.m_anim_alpha < 0.005 then
                    table.remove(list, i)
                end
            else
                notify.m_anim_alpha = c_math.lerp(notify.m_anim_alpha, 1.0, ft * 10.0)
            end
        end
    end

    if #list == 0 then
        return
    end

    while #list > 8 do
        table.remove(list, 1)
    end

    for i=1, #list do
        local notify = list[i]
        local current_alpha = notify.m_anim_alpha

        if current_alpha > 0 then
            local txt = notify.m_text
            local slist = color.string_to_color_array(string.format('\a%s%s', notify.m_color:to_hex(), txt))

            local w_o = 0
            local animated_x = x - (30 * (1.0 - current_alpha))

            for j=1, #slist do
                local obj = slist[j]

                obj.text = obj.text:gsub('\1', '')

                local this_w = renderer.measure_text("b", obj.text)

                renderer.text(animated_x + w_o, y, obj.color.r, obj.color.g, obj.color.b, current_alpha * 255.0, "b", 0, obj.text)

                w_o = w_o + this_w
            end

            y = y + (size * current_alpha)
        end
    end
end)

local skip_line

function custom_output.output(output)
    local text_to_draw = output.text

    local clr = color(output.r, output.g, output.b, output.a)

    if text_to_draw:find('\0') then
        text_to_draw = text_to_draw:sub(1, #text_to_draw-1)
    end

    if skip_line then
        if list[#list] then
            list[#list].m_text = string.format('%s%s', list[#list].m_text, string.format('\a%s%s', clr:to_hex(), text_to_draw))
        else
            list[#list+1] = {
                m_text = text_to_draw,
                m_color = clr,
                m_time = 8.0,
                m_anim_alpha = 0.0
            }
        end

        skip_line = false
    else
        for str in text_to_draw:gmatch('([^\n]+)') do
            list[#list+1] = {
                m_text = str,
                m_color = clr,
                m_time = 8.0,
                m_anim_alpha = 0.0
            }
        end
    end

    local has_ignore_newline = output.text:find('\0')

    if has_ignore_newline ~= nil then
        skip_line = true
    end
end
end
client.set_event_callback('output', custom_output.output)
local function render_wm_ctx(ctx, items, mx, my, is_font)
    if not ctx.open then
        if not ctx.closing then return end
        ctx.anim = interface.animate(ctx.anim, 0, 14)
        if ctx.anim < 0.01 then
            ctx.closing = false
            return
        end
    else
        ctx.closing = false
    end

    local clr     = {menu_r or 121, menu_g or 174, menu_b or 252}
    local pad_x   = 10
    local pad_y   = 5
    local item_h  = ctx.item_h
    local w       = ctx.w
    local total_h = pad_y * 2 + #items * item_h

    if ctx.open then
        ctx.anim = interface.animate(ctx.anim, 1, 16)
    end

    local alpha    = math.floor(255 * ctx.anim)
    local render_h = total_h
    local slide    = math.floor((1 - ctx.anim) * total_h)
    local bx       = ctx.x
    local by
    if ctx.open_up then
        by = ctx.anchor_y - total_h - 4 + slide
    else
        by = ctx.anchor_y + slide
    end

    for gi = 4, 1, -1 do
        local ga = math.floor(20 * (1 - gi / 4) * ctx.anim)
        rec_outline(bx-gi, by-gi, w+gi*2, render_h+gi*2, 5+gi, 1, {clr[1],clr[2],clr[3],ga})
    end
    rec(bx, by, w, render_h, 4, 16, 16, 16, alpha)
    rec_outline(bx,     by,     w,     render_h,     4, 1, {8,  8,  8,  alpha})
    rec_outline(bx + 1, by + 1, w - 2, render_h - 2, 4, 1, {50, 50, 50, alpha})

    local lw = w - pad_x * 2
    renderer.gradient(bx+pad_x,        by+render_h-2, lw/2, 2, clr[1],clr[2],clr[3],0,   clr[1],clr[2],clr[3],math.floor(100*ctx.anim), true)
    renderer.gradient(bx+pad_x+lw/2,   by+render_h-2, lw/2, 2, clr[1],clr[2],clr[3],math.floor(100*ctx.anim), clr[1],clr[2],clr[3],0, true)

    local _, th = renderer.measure_text("b", "A")

    for i, name in ipairs(items) do
        local iy = by + pad_y + (i - 1) * item_h
        if iy + item_h > by + render_h then break end

        local hov = ctx.open and mx >= bx and mx <= bx+w and my >= iy and my <= iy+item_h
        local active
        if is_font then
            active = (i == beta_font_mode)
        else
            local is_default = false
            for idx, d in pairs(dragging_system.draggings) do
                if d == overflame_beta then
                    local init = dragging_system.initial_positions[idx]
                    if init then
                        is_default = (math.abs(d.x - init.x) < 2 and math.abs(d.y - init.y) < 2)
                    end
                    break
                end
            end
            active = (i == 1 and is_default) or (i == 2 and not is_default)
        end

        if hov and not active then
            rec(bx+3, iy+1, w-6, item_h-2, 3, 255, 255, 255, math.floor(10*ctx.anim))
        end
        if active then
            rec(bx+3, iy+1, w-6, item_h-2, 3, clr[1],clr[2],clr[3], math.floor(28*ctx.anim))
            renderer.gradient(bx+3, iy+4,                2, (item_h-8)/2, clr[1],clr[2],clr[3],0,     clr[1],clr[2],clr[3],alpha, false)
            renderer.gradient(bx+3, iy+4+(item_h-8)/2,   2, (item_h-8)/2, clr[1],clr[2],clr[3],alpha, clr[1],clr[2],clr[3],0,     false)
        end

        local tr = active and clr[1] or (hov and 230 or 150)
        local tg = active and clr[2] or (hov and 230 or 150)
        local tb = active and clr[3] or (hov and 230 or 150)
        renderer.text(bx+pad_x+8, iy+math.floor((item_h-th)/2), tr, tg, tb, alpha, "b", 0, name)

        if is_font then
            local pf = beta_font_modes[i]
            local pw, ph = renderer.measure_text(pf, "Aa")
            renderer.text(bx+w-pad_x-pw, iy+math.floor((item_h-ph)/2),
                clr[1],clr[2],clr[3], math.floor((active and 200 or 70)*ctx.anim), pf, 0, "Aa")
        end

        if hov and client.key_state(0x01) then
            if is_font then
                beta_font_mode = i
                font_ctx_menu.open = false
                font_ctx_menu.closing = true
            else
                if name == "Default" then
                    for idx, d in pairs(dragging_system.draggings) do
                        if d == overflame_beta then
                            local init = dragging_system.initial_positions[idx]
                            if init then d.x, d.y = init.x, init.y end
                            break
                        end
                    end
                end
                pos_ctx_menu.open = false
                pos_ctx_menu.closing = true
            end
        end
    end

    local outside = not (mx >= bx and mx <= bx+w and my >= by and my <= by+total_h)
    if outside and client.key_state(0x01) then
        ctx.open = false
        ctx.closing = true
    end
end

client.set_event_callback("paint_ui", function()
    if not ui.is_menu_open() then return end
    local mx, my = ui.mouse_position()
    render_wm_ctx(font_ctx_menu, beta_font_names, mx, my, true)
    render_wm_ctx(pos_ctx_menu,  {"Default","Custom"}, mx, my, false)
end)

local texture_timer = 0
local show_scream = false
local img_data = nil
local img_width, img_height = 500, 500

local countdown_time = 30.0
local countdown_active = false
local sound_timer = 0

local timer_positions = {}

local horror_sounds = {
    "playvol ambient/creatures/chicken_death_02 1.0",
    "playvol ui/deathnotice 1.0",
    "playvol ui/beep22 1.0",
    "playvol training/light_on 1.0",
    "playvol music/stinger_01 1.0",
    "playvol ui/pan_chimes_01 1.0",
    "playvol ui/buttonrollover 1.0"
}

http.get("https://i.ibb.co.com/Fqr7PqL/screamer.png", function(success, response)
    if success and response.status == 200 then
        img_data = renderer.load_rgba(response.body, img_width, img_height)
    end
end)

client.set_event_callback("paint", function()
    if not ui.get(menu.scary_mode) then
        show_scream = false
        countdown_active = false
        timer_positions = {}
        return
    end

    local current_time = globals.curtime()
    local screen_w, screen_h = client.screen_size()

    if not countdown_active then
        countdown_time = current_time + 30.0
        countdown_active = true
        sound_timer = current_time
        timer_positions = {
            { x = screen_w / 2, y = 40, flags = "cb+" }
        }
    end

    local time_left = countdown_time - current_time

    if time_left <= 0 then
        client.exec("quit")
        return
    end

    if current_time >= sound_timer then
        client.exec("playvol training/countdown 1.0")
        sound_timer = current_time + 1.0
    end

    local text_timer = string.format("00:%02d:%02d", math.floor(time_left), math.floor((time_left % 1) * 100))

    local seconds_passed = math.floor(30.0 - time_left) + 1
    if seconds_passed > 30 then seconds_passed = 30 end

    while #timer_positions < seconds_passed do
        table.insert(timer_positions, {
            x = math.random(50, screen_w - 150),
            y = math.random(50, screen_h - 50),
            flags = math.random(1, 2) == 1 and "c+" or "b"
        })
    end

    for i = 1, #timer_positions do
        local pos = timer_positions[i]
        local alpha = math.random(150, 255)
        renderer.text(pos.x, pos.y, 255, 0, 0, alpha, pos.flags, 0, text_timer)
    end

    if not show_scream then
        if math.random(1, 400) == 1 then
            client.exec("volume 1.0")
            client.exec("snd_musicvolume 1.0")
            
            for i = 1, 10 do
                local random_sound = horror_sounds[math.random(1, #horror_sounds)]
                client.exec(random_sound)
            end
            
            rand_x = math.random(0, math.max(0, screen_w - img_width))
            rand_y = math.random(0, math.max(0, screen_h - img_height))
            
            texture_timer = current_time + 0.8
            show_scream = true
        end
    else
        if current_time > texture_timer then
            show_scream = false
        else
            renderer.rectangle(0, 0, screen_w, screen_h, 220, 0, 0, 160)
            if img_data then
                local s_x = math.random(0, math.max(0, screen_w - img_width))
                local s_y = math.random(0, math.max(0, screen_h - img_height))
                renderer.texture(img_data, s_x, s_y, img_width, img_height, 255, 255, 255, 255)
            end
        end
    end
end)