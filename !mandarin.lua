local pui           = require("gamesense/pui")

local vector        = require("vector")

local clipboard     = require("gamesense/clipboard")

local base64        = require("gamesense/base64")

local ffi           = require("ffi")

local http          = require('gamesense/http')

local pui           = require('gamesense/pui')

local aa_func       = require('gamesense/antiaim_funcs')

local trace         = require('gamesense/trace')

local csgo_weapons  = require('gamesense/csgo_weapons')

local steamworks    = require('gamesense/steamworks')

local localize      = require('gamesense/localize')

local chat          = require('gamesense/chat')

---

local lua = {
    username = "admin",
    build = "Beta",
}

local menu_r, menu_g, menu_b, menu_a = ui.get(ui.reference("MISC", "Settings", "Menu color"))
local lua_color = string.format("\a%02X%02X%02X%02X", menu_r, menu_g, menu_b, menu_a)

---

function startup()
    local logo = {
    " ",
    "Welcome back, " .. lua.username .. "!",
    "You're using Aurora " .. lua.build,
    " ",
    }
    client.exec("clear")
    client.exec("con_filter_enable 1")
    client.color_log(255, 255, 255, "Aurora Beta \0")
    client.color_log(151, 144, 146, "· https://discord.gg/Ed9kxZjYf")
    for _, line in pairs(logo) do
        client.color_log(151, 144, 146, line)
    end
end
startup()

---

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

    reference.antiaim.angles.yaw[2]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488})
    reference.antiaim.angles.pitch[2]:depend({reference.antiaim.angles.pitch[1], 1488}, {reference.antiaim.angles.pitch[2], 1488})
    reference.antiaim.angles.yaw_jitter[1]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488})
    reference.antiaim.angles.yaw_jitter[2]:depend({reference.antiaim.angles.yaw[1], 1488}, {reference.antiaim.angles.yaw[2], 1488}, {reference.antiaim.angles.yaw_jitter[1], 1488}, {reference.antiaim.angles.yaw_jitter[2], 1488})
    reference.antiaim.angles.body_yaw[2]:depend({reference.antiaim.angles.body_yaw[1], 1488})
    reference.antiaim.angles.fs_body_yaw:depend({reference.antiaim.angles.body_yaw[1], 1488})
    pui.traverse(reference.antiaim.angles, function (ref)
        ref:depend({reference.antiaim.angles.enabled, 1488})
        if ref.hotkey then ref.hotkey:depend({reference.antiaim.angles.enabled, 1488}) end
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

---

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

---

function aa_combo(c, n)
    local element = pui.new_combobox("AA", "Anti-aimbot angles", lua_color .. c, n)
    table.insert(elements, element)
    return element
end
function aa_color(c, n)
    local element = pui.new_color_picker("AA", "Anti-aimbot angles", lua_color .. c, n)
    table.insert(elements, element)
    return element
end
function aa_button(c, n)
    local element = pui.new_button("AA", "Anti-aimbot angles", lua_color .. c, n)
    table.insert(elements, element)
    table.insert(buttons, element)
    return element
end

function aa_slider(c, a, b, c1, d, e, f, g)
    local element = pui.new_slider("AA", "Anti-aimbot angles", lua_color .. c, a, b, c1, d, e, f, g)
    table.insert(elements, element)
    return element
end

function aa_checkbox(c)
    local element = pui.new_checkbox("AA", "Anti-aimbot angles", lua_color .. c)
    table.insert(elements, element)
    return element
end

function aa_multi(c, n)
    local element = pui.new_multiselect("AA", "Anti-aimbot angles", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function aa_list(c, n)
    local element = pui.new_listbox("AA", "Anti-aimbot angles", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function aa_textbox(c)
    local element = pui.new_textbox("AA", "Anti-aimbot angles", lua_color .. c)
    table.insert(elements, element)
    return element
end

function aa_label(c)
    local element = pui.new_label("AA", "Anti-aimbot angles", lua_color .. c)
    table.insert(elements, element)
    return element
end
function aa_hotkey(c, a)
    local element = pui.new_hotkey("AA", "Anti-aimbot angles", lua_color .. c, a)
    table.insert(elements, element)
    all_binds[#all_binds+1] = element
    return element
end

---

function fakelag_list(c, n)
    local element = pui.new_listbox("AA", "Fake lag", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function fakelag_combo(c, n)
    local element = pui.new_combobox("AA", "Fake lag", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function fakelag_slider(c, a, b, c1, d, e, f, g)
    local element = pui.new_slider("AA", "Fake lag", lua_color .. c, a, b, c1, d, e, f, g)
    table.insert(elements, element)
    return element
end

function fakelag_color(c, n)
    local element = pui.new_color_picker("AA", "Fake lag", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function fakelag_checkbox(c)
    local element = pui.new_checkbox("AA", "Fake lag", lua_color .. c)
    table.insert(elements, element)
    return element
end

function fakelag_multi(c, n)
    local element = pui.new_multiselect("AA", "Fake lag", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function fakelag_label(c)
    local element = pui.new_label("AA", "Fake lag", lua_color .. c)
    table.insert(elements, element)
    return element
end

function fakelag_hotkey(c, a)
    local element = pui.new_hotkey("AA", "Fake lag", lua_color .. c, a)
    table.insert(elements, element)
    all_binds[#all_binds+1] = element
    return element
end

function fakelag_button(c, n)
    local element = pui.new_button("AA", "Fake lag", lua_color .. c, n)
    table.insert(elements, element)
    table.insert(buttons, element)
    return element
end

function fakelag_textbox(c)
    local element = pui.new_textbox("AA", "Fake lag", lua_color .. c)
    table.insert(elements, element)
    return element
end


---

function other_button(c, n)
    local element = pui.new_button("AA", "Other", lua_color .. c, n)
    table.insert(elements, element)
    table.insert(buttons, element)
    return element
end

function other_combo(c, n)
    local element = pui.new_combobox("AA", "Other", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function other_slider(c, a, b, c1, d, e, f, g)
    local element = pui.new_slider("AA", "Other", lua_color .. c, a, b, c1, d, e, f, g)
    table.insert(elements, element)
    return element
end

function other_checkbox(c)
    local element = pui.new_checkbox("AA", "Other", lua_color .. c)
    table.insert(elements, element)
    return element
end

function other_multi(c, n)
    local element = pui.new_multiselect("AA", "Other", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

function other_label(c)
    local element = pui.new_label("AA", "Other", lua_color .. c)
    table.insert(elements, element)
    return element
end

function other_textbox(c)
    local element = pui.new_textbox("AA", "Other", lua_color .. c)
    table.insert(elements, element)
    return element
end

function other_color(c, n)
    local element = pui.new_color_picker("AA", "Other", lua_color .. c, n)
    table.insert(elements, element)
    return element
end

---
 

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
    "Default",
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
    alternative_conditions[i] = lua_color .. '›\a9D9D9DFF  ' .. conditions[i]
end
local state = "Global"
local cfgs = {}
local cfg_text = 0
local cfg_list = 0
local cfg_key = "aurora_local::cfg"

---

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

---

local function gradient_text(text)
    if #text == 0 then return "" end
    local result = ""
    local len = #text
    
    -- #adcbdb - rgb(173, 203, 219)
    -- #ffb3ed - rgb(255, 179, 237)

    local r1, g1, b1 = 175, 199, 227
    local r2, g2, b2 = 50,50,50
    
    for i = 1, len do
        local t = (len == 1) and 0 or ((i - 1) / (len - 1))
        
        local r = math.floor(r1 + (r2 - r1) * t + 0.5)
        local g = math.floor(g1 + (g2 - g1) * t + 0.5)
        local b = math.floor(b1 + (b2 - b1) * t + 0.5)
        
        result = result .. string.format("\a%02X%02X%02X%02X%s", r, g, b, 255, text:sub(i, i))
    end
    return result
end

local gradient   = gradient_text("Beta")

---

local tabs = {
    {
        nil, {
            " ",
            " "

        }
    },

    {
            " ", {
            " "
        }
    },

    {
            " ", {
            " "

        }
    },

    {
            " ", {
            " "
        }
    }
}

local listbox_items = {}
local header_to_first = {}

for _, tab in ipairs(tabs) do
    local header, subs = tab[1], tab[2]
    if header ~= nil then
        table.insert(listbox_items, header)
        header_to_first[header] = #listbox_items + 1 
    end
    for _, sub in ipairs(subs) do
        table.insert(listbox_items, (header ~= nil and "  " or "") .. sub) 
    end
end

local function get_tab_name()
    if not menu or not menu.tab then
        return ""
    end

    local idx = ui.get(menu.tab)
    if type(idx) ~= "number" or idx < 0 then
        return ""
    end

    local name = listbox_items[idx + 1]
    return name or ""
end


---


---

menu = {
    
    ---

    --changelog_label = fakelag_label("  Project \aCDCDCDFF/ Changelog "),

    --changelog_button = fakelag_button(" \aCDCDCDFFChangelog", function ()
    --    panorama.open('CSGOHud').SteamOverlayAPI.OpenExternalBrowserURL('https://discord.gg/96h3DkZW2T')
    --end),
    
    --changelog_tabs = fakelag_list("Tabbbs",  listbox_items, nil, false),

    ---

    lua_name = aa_label("Aurora  \a323232FF•  \aCDCDCDFFa powerful script"),
    tab_label = fakelag_label("\aCDCDCDFF●    \a323232FF•    \a323232FF•    \a323232FF• "),

    tab = aa_combo("\n\aCDCDCDFFAurora - group" ,{"Home", "Anti-Aim's", "Features", "Presets"}),

    ---

        rage = {
            --fakelag_label(lua_color .."  \a323232FF•  " .. lua_color .. ""),
            tab_sec = fakelag_combo("\n\aCDCDCDFFtype ",{"Statistics", "Other"}),

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
                    work = fakelag_multi("\a323232FF•  \aCDCDCDFFEvents", {"On kill", "On death"}),
                    type = fakelag_combo("\a323232FF•  \aCDCDCDFFCategory", {"Advertise us", "Simple"}),
                },
            },
        },
    },

    ---

    aa = {
        type = other_combo(lua_color .."\n  \a323232FF•  " .. lua_color .. "", {"Yaw", "Pitch", "Exploit", "Anti-Brute"}),

        category = fakelag_combo(lua_color .."\n  \aCDCDCDFF•  " .. lua_color .. "", {"Legacy", "Defensive", "Settings"}),

        fakelag_amount = fakelag_combo(" ", {"Dynamic", "Maximum", "Fluctuate"}),

        fakelag_variance = fakelag_slider("•  \aCDCDCDFFVariance", 0,100,0,true,"%",1),

        fakelag_limit = fakelag_slider("•  \aCDCDCDFFLimit", 1,15,15,true,"",1),

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

        --fakelag_label(lua_color .."  \a323232FF•  " .. lua_color .. ""),
        
        spacer111 = aa_label(" "),

        safe_head = aa_multi("\aCDCDCDFFSafe Head", {"On Knife", "On Zeus", "On R8"}), 

        warmup_aa = aa_combo("\aCDCDCDFFWarmup anti-aim", {"Off", "Nyanza", "Nyanza Beta", "Spin"}),


        exploits = other_multi("\aCDCDCDFFExploits", {"Extend Fakelag", "Defensive Flick", "Fake Flick"}),
        
        extendfakelag_slider = other_slider("\a323232FF\aCDCDCDFFAmount", 16, 32, 18, true, "t", 1),

        fake_flick = other_multi("\a323232FF" .. lua_color .. "Fake Flick \aCDCDCDFF» States", {"Standing", "Moving", "Slow-Walk", "In-Air"}),

        other_label(" "),

        import = other_button("\aCDCDCDFF Export Settings " .. lua_color .. "",function ()
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

        export = other_button("\aCDCDCDFF Import Settings  " .. lua_color .. "", function ()
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

        reset = other_button("\aCDCDCDFF Reset Settings " .. lua_color .. "",function ()
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

        preset = aa_slider(lua_color .."\n\aCDCDCDFFBuilder", 1, 3, 1, true, '', 1, {[1] = "Custom", [2] = "Jitter", [3] = "Dynamic"}),
        aa_label("\nspace"),
        label_state = aa_label(lua_color .."\aCDCDCDFFPlayer " .. lua_color .. "State"),
        state = aa_combo("\n  \aCDCDCDFFAnti-aim state", alternative_conditions),

        ---

        antibrute_l = aa_slider("\aCDCDCDFFLeft", 0, 60, 0,true,"°",1),
        antibrute_r = aa_slider("\aCDCDCDFFRight", 0, 60, 0,true,"°",1),
        antibrute_delay = aa_slider("\aCDCDCDFFDelay", 0, 3, 0,true,"t",1)
    },

    ---

    features = {

    --fakelag_label(lua_color .."  \a323232FF•  " .. lua_color .. "  \a323232FF•  " .. lua_color .. ""),

    type = fakelag_combo(" ", {"Visuals", "Rage", "Miscellaneous"}),
        visuals = {
            aa_label(" "),
            fakelag_label(" "),
            
            crosshair           = aa_checkbox("\aCDCDCDFFCrosshair Indicator "),
            crosshair_type      = aa_combo("\aCDCDCDFFCrosshair Indicator Selection", {"Modern", "Simple"}),
            watermark_selection = aa_checkbox("\aCDCDCDFFWatermark"),
            watermark_type      = aa_multi("\aCDCDCDFFWatermark Selection", {"Watermark", "Brand Watermark", "Text Watermark"}),
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

            logs = aa_checkbox("\aCDCDCDFFEvent Logger"),

            damage_indicator = aa_checkbox("\aCDCDCDFFMinimum Damage Indicator"),

            debug_panel = aa_checkbox("\aCDCDCDFFDebug Panel"),

            aspect_ratio_enable = aa_checkbox("\aCDCDCDFFAspect Ratio"),
            aspect_ratio_value  = aa_slider("\a323232FF•  \aCDCDCDFFAspect ratio value", 80, 250, 178, true, " ", 0.01, {
                [125] = '5:4', 
                [133] = '4:3', 
                [150] = '3:2', 
                [160] = '16:10', 
                [178] = '16:9', 
                [200] = '2:1'
            }),

            viewmodel_enable = aa_checkbox("\aCDCDCDFFViewmodel Changer"),
            viewmodel_in_scope = aa_checkbox("\a323232FF•  \aCDCDCDFFViewmodel in Scope"),
            viewmodel_fov = aa_slider("\a323232FF-  \aCDCDCDFFViewmodel FOV", 0, 120, 68, true, "°", 1),
            viewmodel_x = aa_slider("\a323232FF•  \aCDCDCDFFViewmodel X", -20, 20, 0, true, "u", 1),
            viewmodel_y = aa_slider("\a323232FF•  \aCDCDCDFFViewmodel Y", -20, 20, 0, true, "u", 1),
            viewmodel_z = aa_slider("\a323232FF•  \aCDCDCDFFViewmodel Z", -20, 20, 0, true, "u", 1),

            zoom_anim_enable = aa_checkbox("\aCDCDCDFFZoom Animation"),
            zoom_anim_speed  = aa_slider("\a323232FF•  \aCDCDCDFFZoom Speed", 1, 20, 8, true, "", 1),
            zoom_anim_fov    = aa_slider("\a323232FF•  \aCDCDCDFFZoom FOV", 20, 120, 40, true, "\xb0", 1),
--[[
            custom_scope_enable = aa_checkbox("\aCDCDCDFFCustom Scope"),
            custom_scope_size   = aa_slider("\a323232FF•  \aCDCDCDFFScope Size", 10, 120, 50, true, "px", 1),
            custom_scope_gap    = aa_slider("\a323232FF•  \aCDCDCDFFScope Gap", 0, 30, 8, true, "px", 1),
            custom_scope_thick  = aa_slider("\a323232FF•  \aCDCDCDFFScope Thickness", 1, 4, 1, true, "px", 1),
--]]

   animations          = fakelag_multi("\aCDCDCDFFAnimation Breaker", {"Leaning", "Jitter Legs", "Earthquake"}),
        },

        miscellaneous = {
            airlag = aa_checkbox("\aCDCDCDFFAir-Teleport"),
            airlag_key = aa_hotkey("\a323232FF•  \aCDCDCDFFAir-Lag Key", true),
            airlag_ticks = aa_slider("\a323232FF•  \aCDCDCDFFAir-Lag Timer", 2, 16, 4,true, "t", 1),

            fastladder = aa_checkbox("\aCDCDCDFFFast Ladder"),
            anti_backstab = aa_checkbox("\aCDCDCDFFAnti-Backstab"),

            recharge = aa_checkbox("\aCDCDCDFFUnsafe DT Recharge"),
            jumpscout = aa_checkbox("\aCDCDCDFFImprove Jump-Scout"),
            aimtools = aa_checkbox("\aCDCDCDFFEnable ".. lua_color .. "Aim-tools"),
            correction = fakelag_checkbox("\aCDCDCDFFAnti-Aim " .. lua_color .. "Correction"),
            predict_enemies = fakelag_checkbox("" .. lua_color .. "Enemies \aCDCDCDFFPredict"),
        },
    },

    ---

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
        SPACE = other_label(" "),

        name = other_textbox("Name"),

        load = aa_button("\aCDCDCDFFLoad from " .. lua_color .. "local presets",function() load_cfg() end),

        save = other_button("\aCDCDCDFFCreate / Save",function() save_cfg() end),
        delete = other_button("\aCDCDCDFFDelete",function() delete_cfg() end),

        export = aa_button("\aCDCDCDFFExport",function() export(); end),
        import = aa_button("\aCDCDCDFFImport",function() import(clipboard.get()); end)
    }
}


---

local current_vm    = { x = 0, y = 0, z = 0, fov = 68 }
local zoom_fov_val  = 0
local vm_reset_done = false

client.set_event_callback("paint", function()
    local lp       = entity.get_local_player()
    local is_alive = lp and entity.is_alive(lp)
    local is_scoped = is_alive and entity.get_prop(lp, "m_bIsScoped") == 1

    local vm_on = ui.get(menu.features.visuals.viewmodel_enable)
    if vm_on then
        local hide_in_scope = not ui.get(menu.features.visuals.viewmodel_in_scope)
        local should_hide   = hide_in_scope and is_scoped

        local target_x   = should_hide and 0  or ui.get(menu.features.visuals.viewmodel_x)
        local target_y   = should_hide and 0  or ui.get(menu.features.visuals.viewmodel_y)
        local target_z   = should_hide and 20 or ui.get(menu.features.visuals.viewmodel_z)
        local target_fov = should_hide and 0  or ui.get(menu.features.visuals.viewmodel_fov)

        current_vm.x   = interface.animate(current_vm.x,   target_x,   12)
        current_vm.y   = interface.animate(current_vm.y,   target_y,   12)
        current_vm.z   = interface.animate(current_vm.z,   target_z,   12)
        current_vm.fov = interface.animate(current_vm.fov, target_fov, 12)

        client.set_cvar("viewmodel_offset_x", current_vm.x)
        client.set_cvar("viewmodel_offset_y", current_vm.y)
        client.set_cvar("viewmodel_offset_z", current_vm.z)
        client.set_cvar("viewmodel_fov",      current_vm.fov)
        vm_reset_done = false
    elseif not vm_reset_done then
        client.set_cvar("viewmodel_offset_x", 0)
        client.set_cvar("viewmodel_offset_y", 0)
        client.set_cvar("viewmodel_offset_z", 0)
        client.set_cvar("viewmodel_fov",      68)
        vm_reset_done = true
    end

    if ui.get(menu.features.visuals.zoom_anim_enable) and is_alive then
        local speed      = ui.get(menu.features.visuals.zoom_anim_speed)
        local target_fov = ui.get(menu.features.visuals.zoom_anim_fov)
        local target_val = is_scoped and 1 or 0
        zoom_fov_val = interface.animate(zoom_fov_val, target_val, speed)
        local fov = 90 - zoom_fov_val * (90 - target_fov)
        reference.misc.miscellaneous.override_zoom_fov:set(math.floor(fov))
    else
        zoom_fov_val = 0
        reference.misc.miscellaneous.override_zoom_fov:set(0)
    end

    if ui.get(menu.features.visuals.aspect_ratio_enable) then
        local val = ui.get(menu.features.visuals.aspect_ratio_value) / 100
        client.set_cvar("r_aspectratio", val)
    else
        client.set_cvar("r_aspectratio", 0)
    end
end)
--[[
    local scope_on = ui.get(menu.features.visuals.custom_scope_enable)
    if scope_on then
        reference.visuals.scope:set(true)
    end
    if scope_on and is_scoped then
        local sw, sh = client.screen_size()
        local cx  = math.floor(sw / 2)
        local cy  = math.floor(sh / 2)
        local sz  = ui.get(menu.features.visuals.custom_scope_size)
        local gap = ui.get(menu.features.visuals.custom_scope_gap)
        local t   = ui.get(menu.features.visuals.custom_scope_thick)
        local r, g, b_c, a = 255, 255, 255, 200

        for i = 0, t - 1 do
            renderer.line(cx - sz - gap, cy - math.floor(t/2) + i, cx - gap, cy - math.floor(t/2) + i, r, g, b_c, a)
        end

        for i = 0, t - 1 do
            renderer.line(cx + gap, cy - math.floor(t/2) + i, cx + sz + gap, cy - math.floor(t/2) + i, r, g, b_c, a)
        end

        for i = 0, t - 1 do
            renderer.line(cx - math.floor(t/2) + i, cy - sz - gap, cx - math.floor(t/2) + i, cy - gap, r, g, b_c, a)
        end

        for i = 0, t - 1 do
            renderer.line(cx - math.floor(t/2) + i, cy + gap, cx - math.floor(t/2) + i, cy + sz + gap, r, g, b_c, a)
        end

        renderer.circle(cx, cy, r, g, b_c, a, 1, 0, 1)
    elseif not scope_on then
        reference.visuals.scope:set(false)
    end
end)

client.set_event_callback("shutdown", function()
    client.set_cvar("r_aspectratio", 0)
    client.set_cvar("viewmodel_offset_x", 0)
    client.set_cvar("viewmodel_offset_y", 0)
    client.set_cvar("viewmodel_offset_z", 0)
    client.set_cvar("viewmodel_fov", 68)
    client.set_cvar("fov_cs_debug", 0)
end)

--]]

---

function hexToRgb(hexString)
    local hex = hexString:gsub("^\\a", "a")
    local r = tonumber(hex:sub(2, 3), 16) or 0
    local g = tonumber(hex:sub(4, 5), 16) or 0 
    local b = tonumber(hex:sub(6, 7), 16) or 0
    local a = tonumber(hex:sub(8, 9), 16) or 0
    
    return {r, g, b, a}
end

---

do
    local letters = {"A","u","r","o","r","a"," ","B","e","t","a"}
    local color       = lua_color
    local suffix      = "  \a323232FF•  \aCDCDCDFFA powerful script."
    local speed       = 0.17
    local pause       = 1.6
    local total       = #letters
    local last_t      = 0
    local step        = 0

    client.set_event_callback("paint_ui", function()
        if not ui.is_menu_open() then return end

        local now     = globals.realtime()
        local elapsed = now - last_t

        local interval = (step == 0 or step == total) and pause or speed
        if elapsed >= interval then
            last_t = now
            if step < total then
                step = step + 1
            elseif step < total * 2 then
                step = step + 1
            else
                step = 0
            end
        end

        local visible
        if step <= total then
            visible = step
        else
            visible = total * 2 - step
        end

        local typed = ""
        for i = 1, visible do
            typed = typed .. color .. letters[i]
        end

        local cursor = ""
        if step == 0 or step == total then
            cursor = (math.floor(now / 0.5) % 2 == 0) and (color .. "_") or " "
        end

        local display = typed .. cursor .. suffix
        ui.set(menu.lua_name, display)
    end)
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

---
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


ui.set_callback(menu.tab, function(ref)
    local value = ui.get(menu.tab)
    if value == "Home" then
        ui.set(menu.tab_label, "\aCDCDCDFF●    \a323232FF•    •    •")
    elseif value == "Anti-Aim's" then
        ui.set(menu.tab_label, "\a323232FF•    \aCDCDCDFF●    \a323232FF•    \a323232FF•")
    elseif value == "Features" then
        ui.set(menu.tab_label, "\a323232FF•    \a323232FF•    \aCDCDCDFF●    \a323232FF•")
    elseif value == "Presets" then
        ui.set(menu.tab_label, "\a323232FF•    \a323232FF•    \a323232FF•    \aCDCDCDFF●")
    end
end)

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
                --if (value_data[3]) then
                --    ui.set(element, 0, value_data[3])
                --end
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
    --a["yaw"]["label_offset"] = aa_label("\aCDCDCDFF    Offset")
    a["yaw"]["yaw"] = aa_combo("\nYaw", {"Backward","L/R"})
    a["yaw"]["yaw_custom"] = aa_slider("\n•   \aCDCDCDFFCustom", -180,180,0,true,"°",1, {[0] = "Backward"})
    a["yaw"]["yaw_value_l"] = aa_slider("\a323232FF•   \aCDCDCDFFLeft Limit", -180,180,0,true,"°",1)
    a["yaw"]["yaw_value_r"] = aa_slider("\a323232FF•   \aCDCDCDFFRight Limit", -180,180,0,true,"°",1)

    a["yaw"]["space"] = aa_label(" ")

    a["yaw"]["label_modifier"] = aa_label("\aCDCDCDFFYaw " .. lua_color .. "Jitter")
    a["yaw"]["yaw_jitter"] = aa_combo("\nYaw Jitter", {"Off", "Offset", "Custom", "Skitter", "Center", "X-Way"})
    a["yaw"]["yaw_jitter_value_l"] = aa_slider("\a323232FF•  \aCDCDCDFFLeft Limit", -180,180,0,true,"°",1)
    a["yaw"]["yaw_jitter_value_r"] = aa_slider("\a323232FF•  \aCDCDCDFFRight Limit", -180,180,0,true,"°",1)
    a["yaw"]["xway_ways"] = aa_slider("\a323232FF•  \aCDCDCDFFX-Way Paths", 2,8,3,true,"w",1)
    a["yaw"]["xway_angle"] = aa_slider("\a323232FF•  \aCDCDCDFFX-Way Angle", 0,180,116,true,"°",1)

    a["yaw"]["space1"] = aa_label(" ")
    a["yaw"]["label_body_yaw"] = aa_label("Body \aCDCDCDFFYaw")
    a["yaw"]["body_yaw"] = aa_combo("\nDesync", {"Off", "Static", "L/R", "Sway"})
    -- body_yaw_inverter теперь управляется через additions multiselect
    a["yaw"]["body_yaw_value_l"] = aa_slider("\a323232FF•  \aCDCDCDFFLeft Limit", 0,60,0,true,"°",1)
    a["yaw"]["body_yaw_value_r"] = aa_slider("\a323232FF•  \aCDCDCDFFRight Limit", 0,60,0,true,"°",1)

    --a["yaw"]["space2"] = aa_label("\nspace")
    --a["yaw"]["label_roll"] = aa_label("\aCDCDCDFFExtended Angles")
    --a["yaw"]["rolls"] = aa_combo("\nExtended Angles type", {"Off", "On"})
    --a["yaw"]["roll_degree"] = aa_slider("•  \aCDCDCDFFDegree", -45,45,0,true,"°",1)

    a["yaw"]["space3"] = aa_label("")
    a["yaw"]["label_extras"] = aa_label("\aCDCDCDFFAdd-ons")
    a["yaw"]["yaw_extra"] = aa_multi("\nYaw Extra", {"Spin", "Sway", "Randomize", "Flick"})
    a["yaw"]["yaw_extra_spin"] = aa_slider("\a323232FF•  \aCDCDCDFFYaw Spin", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_sway"] = aa_slider("\a323232FF•  \aCDCDCDFFYaw Sway", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_randomize"] = aa_slider("\a323232FF•  \aCDCDCDFFYaw Randomize", -180,180,0,true,"°",1)
    a["yaw"]["yaw_extra_flick"] = aa_slider("\a323232FF•  \aCDCDCDFFYaw Flick", -180,180,0,true,"°",1)


    a["yaw"]["space4"] = aa_label(" ")
    a["yaw"]["label_switch"] = aa_label("\aCDCDCDFFDelay")

    
    a["yaw"]["delay_mode"] = aa_combo("\nYaw Switch Mode", {"Old", "New"})
    a["yaw"]["delay_ways"] = aa_slider("\a323232FF•  \aCDCDCDFFWays", 1,5,0,true,"w",1)
    
    a["yaw"]["delay1"] = aa_slider("\a323232FF•  \aCDCDCDFFDelay Limit", 0,16,0,true,"t",1,{[0] = "OFF"})
    a["yaw"]["delay2"] = aa_slider("\a323232FF•  \aCDCDCDFFDelay #2", 0,16,0,true,"t",1)
    a["yaw"]["delay3"] = aa_slider("\a323232FF•  \aCDCDCDFFDelay #3", 0,16,0,true,"t",1)
    a["yaw"]["delay4"] = aa_slider("\a323232FF•  \aCDCDCDFFDelay #4", 0,16,0,true,"t",1)
    a["yaw"]["delay5"] = aa_slider("\a323232FF•  \aCDCDCDFFDelay #5", 0,16,0,true,"t",1)
    a["yaw"]["randomize_delay_min"] = aa_slider("\a323232FF•  \aCDCDCDFFMin.", 0, 16, 0, true, "t", 1, {[0] = "OFF"})
    a["yaw"]["randomize_delay_max"] = aa_slider("\a323232FF•  \aCDCDCDFFMax.", 0, 16, 8, true, "t", 1, {[0] = "OFF"})
    a["yaw"]["space5"] = aa_label(" ")

    --a["yaw"]["lr_checkbox"] = aa_checkbox("Custom Offset » \aCDCDCDFFLeft - Right mode")
    a["yaw"]["additions"] = fakelag_multi("\n\aCDCDCDFFAdd-ons ", {"Add-Ons", "Offset", "Body-Yaw Inverter"})
    a["yaw"]["add_ways"] = fakelag_checkbox("\aCDCDCDFFDelay \a323232FF» \aCDCDCDFFWays")
    a["yaw"]["randomize_delay"] = fakelag_checkbox("\aCDCDCDFFDelay \a323232FF» \aCDCDCDFFRandomize")
    --a["yaw"]["add_addons"] = fakelag_checkbox("Additions » \aCDCDCDFFEnable  \a323232FF•  \aCDCDCDFFAdd-ons")
    --a["yaw"]["enable_offset"] = fakelag_checkbox("Offsets » \aCDCDCDFFEnable")

    a["hidden"]["yaw"]["yaw_hidden"] = aa_label("\aCDCDCDFFDefensive")
    a["hidden"]["yaw"]["yaw"] = aa_combo("\nHidden Yaw", {"Custom", "L/R"})
    a["hidden"]["yaw"]["yaw_value"] = aa_slider("\a323232FF•  \aCDCDCDFFHidden Yaw Custom", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["yaw_value_l"] = aa_slider("\a323232FF•  \aCDCDCDFFAdd Left", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["yaw_value_r"] = aa_slider("\a323232FF•  \aCDCDCDFFAdd Right", -180,180,0,true,"°",1)
    a["hidden"]["yaw"]["delay"] = aa_slider("\a323232FF•  \aCDCDCDFFHidden Yaw Switch", 0,16,0,true,"t",1)

    a["pitch"]["space6"] = aa_label("\nspace")
    a["pitch"]["pitch_label"] = aa_label("\aCDCDCDFFPitch")
    a["pitch"]["pitch"] = aa_combo("\nPitch", {"Down", "Up", "Zero", "Random", "Custom"})
    a["pitch"]["pitch_value"] = aa_slider("\a323232FF•  \aCDCDCDFFPitch Custom", -89,89,89,true,"°",1,{[89]="Down", [-89]="Up",[0]="Zero"})
    a["hidden"]["pitch"]["poloska1"] = aa_label(" ")
    a["hidden"]["pitch"]["poloska2"] = aa_label("\aCDCDCDFFDefensive")
    a["hidden"]["pitch"]["pitch"] = aa_combo("\nHidden Pitch", {"Down", "Up", "Zero", "Random", "Custom"})
    a["hidden"]["pitch"]["pitch_value"] = aa_slider("\a323232FF•  \aCDCDCDFFHidden Pitch Custom", -89,89,89,true,"°",1,{[89]="Down", [-89]="Up",[0]="Zero"})

    a["exploit"]["space7"] = aa_label("\nspace")
    a["exploit"]["force_lc_label"] = aa_label("\aCDCDCDFFDefensive")
    a["exploit"]["force_lc"] = aa_combo("\nForce Break LC", {"Off", "14t", "8t"})
    a["exploit"]["hidden"] = fakelag_checkbox("Defensives » \aCDCDCDFFEnable")

    menu.aa[v] = a
end
function depend_table(tbl, visibility)
    if (type(tbl) == "table") then
        for k, v in pairs(tbl) do
            if (type(v) == "table") then
                depend_table(v,visibility)
            else
                ui.set_visible(v,visibility)
            end
        end
    else
        ui.set_visible(tbl,visibility)
    end
end
local mouse_click = false
local mouse_hold = false
function rec(x, y, w, h, radius, r, g, b, a)
    radius = math.min(x/2, y/2, radius)
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

-- function rec(x, y, w, h, _, r, g, b, a)
--     renderer.rectangle(x, y, w, h, r, g, b, a)
-- end

-- rec_outline = function(x, y, w, h, _, thickness, color)
--     local r, g, b, a = unpack(color)
--     renderer.rectangle(x, y, w, thickness, r, g, b, a) -- Top
--     renderer.rectangle(x, y + h - thickness, w, thickness, r, g, b, a) -- Bottom
--     renderer.rectangle(x, y + thickness, thickness, h - thickness * 2, r, g, b, a) -- Left
--     renderer.rectangle(x + w - thickness, y + thickness, thickness, h - thickness * 2, r, g, b, a) -- Right
-- end
---
local log_queue = {}
local log_height = 30
local log_spacing = 5
local log_lifetime = 5
local test_logs_added = false

logs = {
    add = function(text)
        local _, screen_h = client.screen_size()
        screen_h = screen_h or 768
        local h, m, s, ms = client.system_time()
        local create_time = h * 3600 + m * 60 + s + ms / 1000
        table.insert(log_queue, {text, screen_h - 80, 0, false, create_time, "hit"})
    end,

    add_typed = function(text, log_type)
        local _, screen_h = client.screen_size()
        screen_h = screen_h or 768
        local h, m, s, ms = client.system_time()
        local create_time = h * 3600 + m * 60 + s + ms / 1000
        table.insert(log_queue, {text, screen_h - 80, 0, false, create_time, log_type or "hit"})
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
            logs.add_typed("Harmed by luxpheles in stomach", "warning")
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
            v[3] = interface.animate(v[3], should_hide and 0 or 1, 8)
        end

        local base_y = screen_h - 80
        local current_offset = 0

        for i = #log_queue, 1, -1 do
            local v = log_queue[i]
            if v[3] <= 0.01 then goto continue end

            local pad, gap, block_h = 10, 4, 24
            local label_text = "mandarin"
            local log_type = v[6] or "hit"
            local theme_clr = colors[log_type] or colors.hit

            local label_w = renderer.measure_text("b", label_text)
            local block1_w = pad + label_w + pad
            local msg_w = renderer.measure_text("", v[1])
            local block2_w = pad + msg_w + pad

            local target_y = base_y - current_offset
            v[2] = interface.animate(v[2], target_y, 10)
            current_offset = current_offset + (block_h + log_spacing + 5) * v[3]

            local alpha = math.floor(255 * v[3])
            local scale = v[3]
            local center_x = screen_w / 2
            
            local b1w_scaled = math.floor(block1_w * scale)
            local b2w_scaled = math.floor(block2_w * scale)
            local gap_scaled = math.floor(gap * scale)
            local total_w = b1w_scaled + gap_scaled + b2w_scaled
            
            local x1 = math.floor(center_x - total_w / 2)
            local x2 = x1 + b1w_scaled + gap_scaled
            local render_y = math.floor(v[2] - 13)
            local text_y = math.floor(v[2] - 5)

            local function draw_log_block(bx, bw, bh)
                for gi = 6, 1, -1 do
                    local ga = math.floor((alpha * 0.15) * (1 - gi / 6))
                    rec_outline(bx - gi, render_y - gi, bw + gi * 2, bh + gi * 2, 4 + gi, 1, {theme_clr[1], theme_clr[2], theme_clr[3], ga})
                end

                rec(bx, render_y, bw, bh, 4, 20, 20, 20, alpha)
                rec_outline(bx, render_y, bw, bh, 4, 1, {10, 10, 10, alpha})
                rec_outline(bx + 1, render_y + 1, bw - 2, bh - 2, 4, 1, {55, 55, 55, alpha})
                
                local lx, lw = bx + 6, bw - 12
                if lw > 2 then
                    local pulse = math.sin(realtime * 4) * 0.5 + 0.5
                    local pa = math.floor(alpha * (0.4 + 0.6 * pulse))
                    renderer.gradient(lx, render_y + bh - 2, lw / 2, 2, theme_clr[1], theme_clr[2], theme_clr[3], 0, theme_clr[1], theme_clr[2], theme_clr[3], pa, true)
                    renderer.gradient(lx + lw / 2, render_y + bh - 2, lw / 2, 2, theme_clr[1], theme_clr[2], theme_clr[3], pa, theme_clr[1], theme_clr[2], theme_clr[3], 0, true)
                end
            end

            draw_log_block(x1, b1w_scaled, block_h)
            draw_log_block(x2, b2w_scaled, block_h)

            if v[3] > 0.3 then
                local div_x = x1 + b1w_scaled + math.floor(gap_scaled / 2)
                renderer.gradient(div_x, render_y + 4, 1, 8, theme_clr[1], theme_clr[2], theme_clr[3], 0, theme_clr[1], theme_clr[2], theme_clr[3], 50, false)
                renderer.gradient(div_x, render_y + 12, 1, 8, theme_clr[1], theme_clr[2], theme_clr[3], 50, theme_clr[1], theme_clr[2], theme_clr[3], 0, false)

                local gx = x1 + math.floor(pad * scale)
                for ci = 1, #label_text do
                    local ch = label_text:sub(ci, ci)
                    local wave = math.sin(realtime * 3 + ci * 0.3) * 0.5 + 0.5
                    local r = math.floor(theme_clr[1] + (255 - theme_clr[1]) * wave)
                    local g = math.floor(theme_clr[2] + (255 - theme_clr[2]) * wave)
                    local b = math.floor(theme_clr[3] + (255 - theme_clr[3]) * wave)
                    renderer.text(gx, text_y - 2, r, g, b, alpha, "b", 0, ch)
                    gx = gx + renderer.measure_text("b", ch)
                end

                renderer.text(x2 + math.floor(pad * scale), text_y - 2, 215, 215, 215, alpha, "", 0, v[1])
            end

            ::continue::
        end

        for i = #log_queue, 1, -1 do
            if log_queue[i][3] <= 0.01 then table.remove(log_queue, i) end
        end
    end,
}
---

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

function dragging_system.render()
    local screen_w, screen_h = client.screen_size()
    local mouse_x, mouse_y = ui.mouse_position()
    local mouse_down = client.key_state(1)
    local realtime = globals.realtime()
    
    if not ui.is_menu_open() then
        dragging_system.active_drag = nil
        bg_alpha = 0
        return
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
        handle_snapping(dragging_system.active_drag, realtime)
    else
        for _, drag in pairs(dragging_system.draggings) do
            if drag.visible then
                if mouse_x >= drag.x and mouse_x <= drag.x + drag.w and
                   mouse_y >= drag.y and mouse_y <= drag.y + drag.h then
                    if mouse_down and not dragging_system.active_drag then
                        dragging_system.active_drag = drag
                        dragging_system.drag_offset_x = mouse_x - drag.x
                        dragging_system.drag_offset_y = mouse_y - drag.y
                    end
                end
            end
        end
    end

    for i, drag in pairs(dragging_system.draggings) do
        if drag.visible then

            if drag.snap_storage then
                for id, s in pairs(drag.snap_storage) do
                    local target = 0
                    
                    if s.is_snapped then
                        if realtime - s.snap_time <= 3 then
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

            rec(drag.x, drag.y, drag.w, drag.h, 4, 255, 255, 255, 100 * dragging_system.dragging_alpha)
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

                renderer.text(dynamic_x, text_y, 255, 255, 255, 255 * drag.text_alpha, "c", 0, drag.name)
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
            rec(center.x - 2, center.y - 2, 4, 4, 2, 255, 255, 255, 100 * (1 - bg_alpha))
        end
    end

    rec(10, 10, 100, 25, 5, 25, 25, 25, 200)
    renderer.text(20, 17, 255, 255, 255, 255, "b", 0, "Reset Draggings")
    
    if mouse_x >= 10 and mouse_x <= 110 and mouse_y >= 10 and mouse_y <= 35 and mouse_down then
        for i, drag in pairs(dragging_system.draggings) do
            local initial = dragging_system.initial_positions[i]
            if initial then drag.x, drag.y = initial.x, initial.y end
        end
    end
end

---

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

---

local cwm = dragging_system.create_drag(60, 500, 200, 30,   "This element is draggable!")
local bwm = dragging_system.create_drag(912, 50, 200, 30,   "This element is draggable!")
bwm.label_bottom = true
local lwm = dragging_system.create_drag(865, 1045, 200, 30, "This element is draggable!")
local xhair_wm = dragging_system.create_drag(960, 580, 80, 20, "This element is draggable!")
xhair_wm.lock_x = 960
local aurora_beta = dragging_system.create_drag(15, 500, 0, 0, "Right-click to change text font")
aurora_beta.label_bottom = true

local xhair_smooth_x = 960
local xhair_smooth_y = 580
local xhair_side_anim = 0 

---

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

---

    cwm.visible = ui.get(menu.features.visuals.custom_watermark)
    lwm.visible = contains(ui.get(menu.features.visuals.watermark_type), "Watermark")
    xhair_wm.visible = ui.get(menu.features.visuals.crosshair)
    aurora_beta.visible = contains(ui.get(menu.features.visuals.watermark_type), "Text Watermark")

---

   if lwm.visible then
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
        local full_name   = "mandarin"
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
        local block2_w   = pad + fw_val1 + 3 + fw_lbl1 + pad + fw_val2 + 3 + fw_lbl2 + pad

        local tw         = renderer.measure_text("b", time_str)
        local block3_w   = pad + tw + pad

        local total_w    = block1_w + gap + block2_w + gap + block3_w
        local _, th      = renderer.measure_text("", "A")

        dragging_system.set_width(lwm, total_w)
        dragging_system.set_height(lwm, block_h)

        local lx, ly = lwm.x, lwm.y
        local cy     = ly + math.floor(block_h / 2 - th / 2)

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

        local x1 = lx
        local x2 = lx + block1_w + gap
        local x3 = lx + block1_w + gap + block2_w + gap

        draw_block(x1, ly, block1_w, block_h)
        draw_block(x2, ly, block2_w, block_h)
        draw_block(x3, ly, block3_w, block_h)

        local div_x = x2 + pad + fw_val1 + 3 + fw_lbl1 + math.floor(pad / 2)
        renderer.gradient(div_x, ly + 4,       1, math.floor(block_h / 2) - 4, clr[1], clr[2], clr[3], 0,  clr[1], clr[2], clr[3], 60, false)
        renderer.gradient(div_x, ly + math.floor(block_h / 2), 1, math.floor(block_h / 2) - 4, clr[1], clr[2], clr[3], 60, clr[1], clr[2], clr[3], 0,  false)

        local gx = x1 + pad
        for ci = 1, #name_label do
            local ch    = name_label:sub(ci, ci)
            local wave  = math.sin(realtime * 3 + ci * 0.3) * 0.5 + 0.5
            local r     = math.floor(clr[1] + (255 - clr[1]) * wave)
            local g_col = math.floor(clr[2] + (255 - clr[2]) * wave)
            local b     = math.floor(clr[3] + (255 - clr[3]) * wave)
            local is_g  = (ci == #name_label and glitch_suffix ~= "")
            if is_g then
                renderer.text(gx, cy, 110, 110, 110, 180, "b", 0, ch)
            else
                renderer.text(gx, cy, r, g_col, b, 255, "b", 0, ch)
            end
            gx = gx + renderer.measure_text("b", ch)
        end

        local bx = x2 + pad
        renderer.text(bx,               cy, 230, 230, 230, 255, "b", 0, fps_val)
        renderer.text(bx + fw_val1 + 3, cy, clr[1], clr[2], clr[3], 180, "",  0, fps_label)
        bx = bx + fw_val1 + 3 + fw_lbl1 + pad
        renderer.text(bx,               cy, 230, 230, 230, 255, "b", 0, ms_val)
        renderer.text(bx + fw_val2 + 3, cy, clr[1], clr[2], clr[3], 180, "",  0, ms_label)

        local tx = x3 + pad
        local hh_str = string.format("%02d", h)
        local mm_str = string.format(":%02d", m)
        local hw = renderer.measure_text("b", hh_str)
        renderer.text(tx,      cy, 230, 230, 230, 255, "b", 0, hh_str)
        renderer.text(tx + hw, cy, clr[1], clr[2], clr[3], 200, "b", 0, mm_str)
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

---

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

---
if not scope_anim_val then scope_anim_val = 0 end

if ui.get(menu.features.visuals.crosshair) then
    local xhair_type = ui.get(menu.features.visuals.crosshair_type)

    if xhair_type == "Modern" then
        local dt_on = reference.rage.aimbot.double_tap[1]:get() and reference.rage.aimbot.double_tap[1]:get_hotkey()
        local name = " mandarin"
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

        local aurora_x = center_x - total_w / 2
        local grad_x = aurora_x
        for ci = 1, #name do
            local ch = name:sub(ci, ci)
            local wave = math.sin(realtime * 3 + (ci * 0.3)) * 0.5 + 0.5
            local r = math.floor(clr.white[1] + (clr.main[1] - clr.white[1]) * wave)
            local g = math.floor(clr.white[2] + (clr.main[2] - clr.white[2]) * wave)
            local b = math.floor(clr.white[3] + (clr.main[3] - clr.white[3]) * wave)
            
            renderer.text(grad_x, y + 1, r, g, b, 255, "b", 0, ch)
            grad_x = grad_x + renderer.measure_text("b", ch)
        end

        renderer.text(aurora_x + w1 + 10, y + 2, clr.gray[1], clr.gray[2], clr.gray[3], 200, nil, 0, suffix)

        if dt_anim > 0.01 then
            local alpha = 255 * dt_anim
            local offset = 12 * dt_anim
            local dt_x = center_x - total_w / 30

            local dt_y_pos = y + (1 - side_t) * (-5 - offset) + side_t * (20 + offset)
            local text_y_offset = (1 - side_t) * 2 + side_t * (-2)
            local circle_y_offset = (1 - side_t) * 13 + side_t * (-13)
            local dots_y = y + (1 - side_t) * (-6) + side_t * 10
            
            renderer.text(dt_x, dt_y_pos + text_y_offset, clr.white[1], clr.white[2], clr.white[3], alpha, "c-", 0, "D O U B L E  T A P")
            
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
        elseif ui.get(menu.aa.backward_checkbox) then aa_current = "MANUAL BACK"
        elseif contains(ui.get(menu.aa.exploits), "Defensive Flick") then aa_current = "DEF FLICK"
        elseif contains(ui.get(menu.aa.exploits), "Fake Flick") then aa_current = "FAKE FLICK" end

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

        local name = "mandarin"
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


bwm.visible = contains(ui.get(menu.features.visuals.watermark_type), "Brand Watermark") and not ui.get(menu.features.visuals.custom_watermark)

if bwm.visible then
    local bx, by = bwm.x, bwm.y
    local clr = {
        main = {121, 174, 252},
        white = {255, 255, 255},
        gray = {150, 150, 150}
    }

    local name_text = "mandarin"
    local user_text = lua.username:upper()
    
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

---

    if (is_open) then

        ---

        local is_jitter = ui.get(menu.aa.preset) == "Jitter" or ui.get(menu.aa.preset) == 2
        local is_dynamic = ui.get(menu.aa.preset) == "Dynamic" or ui.get(menu.aa.preset) == 3

        ---

        for k,v in pairs(menu.aa) do
            if type(v) == "table" then
                local is_defensive = ui.get(menu.aa.category) == "Defensive"
                local is_legacy    = ui.get(menu.aa.category) == "Legacy"
                local base_yaw_cond = ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Yaw"

                depend_table(v.yaw,     base_yaw_cond and is_legacy)
                depend_table(v.pitch, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch")
                depend_table(v.body_yaw, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Desync")
                depend_table(v.settings, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

                for i = 1,5 do
                    depend_table(v.yaw["delay" .. i], is_legacy and ui.get(v.yaw.delay_ways) >= i and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Yaw" and ui.get(menu.aa.state) == k)
                end

                depend_table(v.hidden.yaw, base_yaw_cond and is_defensive)
                depend_table(v.hidden.pitch, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch")
                depend_table(v.hidden.body_yaw, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Aim's")

                depend_table(v.yaw.yaw_value_l, is_legacy and base_yaw_cond and ui.get(v.yaw.yaw) == "L/R", (v.yaw.lr_checkbox))
                depend_table(v.yaw.yaw_value_r, is_legacy and base_yaw_cond and ui.get(v.yaw.yaw) == "L/R", (v.yaw.lr_checkbox))

                --depend_table(v.yaw.yaw_value_l, base_yaw_cond and is_legacy and ui.get(v.yaw.lr_checkbox))
                --depend_table(v.yaw.yaw_value_r, base_yaw_cond and is_legacy and ui.get(v.yaw.lr_checkbox))


                depend_table(v.yaw.delay_ways, is_legacy and base_yaw_cond and ui.get(v.yaw.add_ways))

                depend_table(v.yaw.yaw_extra,    is_legacy and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.label_extras,  is_legacy and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.space3,        is_legacy and base_yaw_cond and contains(ui.get(v.yaw.additions), "Add-Ons"))
                depend_table(v.yaw.randomize_delay,     is_legacy and base_yaw_cond)

                depend_table(v.yaw.randomize_delay_min, is_legacy and base_yaw_cond and ui.get(v.yaw.randomize_delay))
                depend_table(v.yaw.randomize_delay_max, is_legacy and base_yaw_cond and ui.get(v.yaw.randomize_delay))

                depend_table(v.yaw.delay1, is_legacy and base_yaw_cond and ui.get(v.yaw.delay_ways) >= 1 and not ui.get(v.yaw.randomize_delay))

                depend_table(v.yaw.yaw_custom, is_legacy and base_yaw_cond and not contains(ui.get(v.yaw.additions), "Offset"))
                depend_table(v.yaw.yaw,        is_legacy and base_yaw_cond and contains(ui.get(v.yaw.additions), "Offset"))



                depend_table(v.yaw.space1, base_yaw_cond and (is_defensive or is_legacy))
                depend_table(v.hidden.yaw.yaw_value_l, is_defensive and base_yaw_cond and ui.get(v.hidden.yaw.yaw) == "L/R" and ui.get(v.exploit.hidden))
                depend_table(v.hidden.yaw.yaw_value_r, is_defensive and base_yaw_cond and ui.get(v.hidden.yaw.yaw) == "L/R" and ui.get(v.exploit.hidden))
                depend_table(v.yaw.yaw_jitter_value_l, is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.yaw_jitter) ~= "Off" and ui.get(v.yaw.yaw_jitter) ~= "X-Way")
                depend_table(v.yaw.yaw_jitter_value_r, is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.yaw_jitter) ~= "Off" and ui.get(v.yaw.yaw_jitter) ~= "X-Way")
                depend_table(v.yaw.xway_ways, is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.yaw_jitter) == "X-Way")
                depend_table(v.yaw.xway_angle, is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.yaw_jitter) == "X-Way")


                depend_table(v.hidden.yaw.yaw_value, is_defensive and base_yaw_cond and ui.get(v.hidden.yaw.yaw) == "Custom" and ui.get(v.exploit.hidden))

                depend_table(v.hidden.yaw.delay, is_defensive and base_yaw_cond and ui.get(v.hidden.yaw.yaw) == "L/R" and ui.get(v.exploit.hidden))

                depend_table(v.hidden.yaw.yaw, is_defensive and base_yaw_cond and ui.get(v.exploit.hidden))
                
                --depend_table(v.yaw.roll_degree, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Yaw" and ui.get(v.yaw.rolls) == "On")

                depend_table(v.pitch.pitch_value, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch" and ui.get(v.pitch.pitch) == "Custom")
                depend_table(v.hidden.pitch.pitch_value, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch" and ui.get(v.hidden.pitch.pitch) == "Custom" and ui.get(v.exploit.hidden))
                depend_table(v.hidden.pitch.pitch, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Pitch" and ui.get(v.exploit.hidden))
                

                depend_table(v.yaw.body_yaw_value_l,  is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.body_yaw) ~= "Off")
                depend_table(v.yaw.body_yaw_value_r,  is_legacy and not is_jitter and base_yaw_cond and ui.get(v.yaw.body_yaw) ~= "Off")
                
                depend_table(v.yaw.yaw_extra_spin,      is_legacy and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Spin"))
                depend_table(v.yaw.yaw_extra_sway,      is_legacy and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Sway"))
                depend_table(v.yaw.yaw_extra_randomize, is_legacy and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Randomize"))
                depend_table(v.yaw.yaw_extra_flick,     is_legacy and base_yaw_cond and contains(ui.get(v.yaw.yaw_extra),"Flick"))

                depend_table(v.exploit, ui.get(menu.aa.state) == k and ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Exploit")


                -- hider v2 (Jitter)

                if is_jitter then   
                    ui.set_visible(v.yaw.space1, false)
                    ui.set_visible(v.yaw.additions, false)
                    -- Modifier
                    ui.set_visible(v.yaw.label_modifier, false)
                    ui.set_visible(v.yaw.yaw_jitter, false)
                    ui.set_visible(v.yaw.yaw_jitter_value_l, false)
                    ui.set_visible(v.yaw.yaw_jitter_value_r, false)
                    ui.set_visible(v.yaw.xway_ways, false)
                    ui.set_visible(v.yaw.xway_angle, false)
                    -- Desync
                    ui.set_visible(v.yaw.label_body_yaw, false)
                    ui.set_visible(v.yaw.body_yaw, false)
                    ui.set_visible(v.yaw.body_yaw_value_l, false)
                    ui.set_visible(v.yaw.body_yaw_value_r, false)
                    -- Add-ons
                    ui.set_visible(v.yaw.additions, false)
                    ui.set_visible(v.yaw.space3, false)
                    ui.set_visible(v.yaw.label_extras, false)
                    ui.set_visible(v.yaw.yaw_extra, false)
                    ui.set_visible(v.yaw.yaw_extra_spin, false)
                    ui.set_visible(v.yaw.yaw_extra_sway, false)
                    ui.set_visible(v.yaw.yaw_extra_randomize, false)
                    ui.set_visible(v.yaw.yaw_extra_flick, false)
                    -- Delay
                    ui.set_visible(v.yaw.space4, false)
                    ui.set_visible(v.yaw.label_switch, false)
                    ui.set_visible(v.yaw.delay_mode, false)
                    ui.set_visible(v.yaw.delay_ways, false)
                    ui.set_visible(v.yaw.delay1, false)
                    ui.set_visible(v.yaw.delay2, false)
                    ui.set_visible(v.yaw.delay3, false)
                    ui.set_visible(v.yaw.delay4, false)
                    ui.set_visible(v.yaw.delay5, false)
                    ui.set_visible(v.yaw.space5, false)
                    ui.set_visible(v.yaw.add_ways, false)
                end

                -- hider v3 (Dynamic)

                if is_dynamic then
                    ui.set_visible(v.yaw.space1, false)
                    ui.set_visible(v.yaw.additions, false)
                    -- Modifier
                    ui.set_visible(v.yaw.label_modifier, false)
                    ui.set_visible(v.yaw.yaw_jitter, false)
                    ui.set_visible(v.yaw.yaw_jitter_value_l, false)
                    ui.set_visible(v.yaw.yaw_jitter_value_r, false)
                    ui.set_visible(v.yaw.xway_ways, false)
                    ui.set_visible(v.yaw.xway_angle, false)
                    -- Desync
                    ui.set_visible(v.yaw.label_body_yaw, false)
                    ui.set_visible(v.yaw.body_yaw, false)
                    ui.set_visible(v.yaw.body_yaw_value_l, false)
                    ui.set_visible(v.yaw.body_yaw_value_r, false)
                    -- Add-ons
                    ui.set_visible(v.yaw.additions, false)
                    ui.set_visible(v.yaw.space3, false)
                    ui.set_visible(v.yaw.label_extras, false)
                    ui.set_visible(v.yaw.yaw_extra, false)
                    ui.set_visible(v.yaw.yaw_extra_spin, false)
                    ui.set_visible(v.yaw.yaw_extra_sway, false)
                    ui.set_visible(v.yaw.yaw_extra_randomize, false)
                    ui.set_visible(v.yaw.yaw_extra_flick, false)
                    -- Delay
                    ui.set_visible(v.yaw.space4, false)
                    ui.set_visible(v.yaw.label_switch, false)
                    ui.set_visible(v.yaw.delay_mode, false)
                    ui.set_visible(v.yaw.delay_ways, false)
                    ui.set_visible(v.yaw.delay1, false)
                    ui.set_visible(v.yaw.delay2, false)
                    ui.set_visible(v.yaw.delay3, false)
                    ui.set_visible(v.yaw.delay4, false)
                    ui.set_visible(v.yaw.delay5, false)
                    ui.set_visible(v.yaw.space5, false)
                    ui.set_visible(v.yaw.add_ways, false)
                end
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
        depend_table(menu.features.visuals.viewmodel_enable,        in_vis_subtab)
        depend_table(menu.features.visuals.viewmodel_in_scope,      in_vis_subtab)
        depend_table(menu.features.visuals.viewmodel_fov,           in_vis_subtab)
        depend_table(menu.features.visuals.viewmodel_x,  in_vis_subtab)
        depend_table(menu.features.visuals.viewmodel_y,  in_vis_subtab)
        depend_table(menu.features.visuals.viewmodel_z,  in_vis_subtab)
        depend_table(menu.features.visuals.zoom_anim_enable,   in_vis_subtab)
        depend_table(menu.features.visuals.zoom_anim_speed,    in_vis_subtab)
        depend_table(menu.features.visuals.zoom_anim_fov,      in_vis_subtab)
        --depend_table(menu.features.visuals.custom_scope_enable, in_vis_subtab)
        --depend_table(menu.features.visuals.custom_scope_size,   in_vis_subtab)
        --depend_table(menu.features.visuals.custom_scope_gap,    in_vis_subtab)
        --depend_table(menu.features.visuals.custom_scope_thick,  in_vis_subtab)
        depend_table(menu.features.visuals.crosshair,           in_vis_subtab)
        depend_table(menu.features.visuals.logs,                in_vis_subtab)
        depend_table(menu.features.visuals.custom_watermark,    in_vis_subtab)
        depend_table(menu.features.visuals.animations,          in_vis_subtab)
        depend_table(menu.features.visuals.watermark_selection,     in_vis_subtab)
        depend_table(menu.features.visuals.watermark_type,          in_vis_subtab)
        depend_table(menu.features.visuals.crosshair_type,          in_vis_subtab)
        depend_table(menu.features.visuals.crosshair,               in_vis_subtab)
        depend_table(menu.features.visuals.debug_panel,             in_vis_subtab)
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

        depend_table(menu.aa.extendfakelag_slider, contains(ui.get(menu.aa.exploits), "Extend Fakelag") and ui.get(menu.tab) == "Anti-Aim's")
        depend_table(menu.aa.fake_flick,           contains(ui.get(menu.aa.exploits), "Fake Flick") and ui.get(menu.tab) == "Anti-Aim's")

        depend_table(menu.features.miscellaneous.airlag_ticks,ui.get(menu.features.miscellaneous.airlag) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.miscellaneous.airlag_key  ,ui.get(menu.features.miscellaneous.airlag) and ui.get(menu.tab) == "Features")

        depend_table(menu.rage.rage_section.trash_talk.setting.work, ui.get(menu.rage.rage_section.trash_talk.enable) and ui.get(menu.tab) == "Home")
        depend_table(menu.rage.rage_section.trash_talk.setting.type, ui.get(menu.rage.rage_section.trash_talk.enable) and ui.get(menu.tab) == "Home")

        
        depend_table(menu.aa.antibrute_l, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")
        depend_table(menu.aa.antibrute_r, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")
        depend_table(menu.aa.antibrute_delay, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) == "Anti-Brute")

        depend_table(menu.aa.safe_head, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table(menu.aa.spacer111, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table(menu.aa.warmup_aa, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

        depend_table(menu.aa.state, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.type) ~= "Anti-Brute")

        depend_table(menu.aa.state, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")
        depend_table(menu.aa.label_state, ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) ~= "Settings")

        depend_table({menu.aa.freestanding_hotkey,menu.aa.backward_manual,menu.aa.right_manual,menu.aa.left_manual,menu.aa.forward_manual},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table({menu.aa.freestanding_checkbox,menu.aa.backward_checkbox,menu.aa.right_checkbox,menu.aa.left_checkbox,menu.aa.forward_checkbox, menu.aa.manual_spacing},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        depend_table({menu.aa.fakelag_amount ,menu.aa.fakelag_variance ,menu.aa.fakelag_limit},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")
        --depend_table({menu.aa.freestanding_checkbox,menu.aa.backward_checkbox,menu.aa.right_checkbox,menu.aa.left_checkbox,menu.aa.forward_checkbox},   ui.get(menu.tab) == "Anti-Aim's" and ui.get(menu.aa.category) == "Settings")

        depend_table(menu.features.visuals.aspect_ratio_value, ui.get(menu.features.visuals.aspect_ratio_enable) and ui.get(menu.tab) == "Features")

        depend_table(menu.features.visuals.viewmodel_in_scope, ui.get(menu.features.visuals.viewmodel_enable) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.visuals.viewmodel_fov, ui.get(menu.features.visuals.viewmodel_enable) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.visuals.viewmodel_x,   ui.get(menu.features.visuals.viewmodel_enable) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.visuals.viewmodel_y,   ui.get(menu.features.visuals.viewmodel_enable) and ui.get(menu.tab) == "Features")
        depend_table(menu.features.visuals.viewmodel_z,   ui.get(menu.features.visuals.viewmodel_enable) and ui.get(menu.tab) == "Features")

        local zoom_on  = ui.get(menu.features.visuals.zoom_anim_enable) and ui.get(menu.tab) == "Features"
        depend_table(menu.features.visuals.zoom_anim_speed,  zoom_on)
        depend_table(menu.features.visuals.zoom_anim_fov,    zoom_on)

        --local scope_on = ui.get(menu.features.visuals.custom_scope_enable) and ui.get(menu.tab) == "Features"
        --depend_table(menu.features.visuals.custom_scope_size,  scope_on)
        --depend_table(menu.features.visuals.custom_scope_gap,   scope_on)
        --depend_table(menu.features.visuals.custom_scope_thick, scope_on)
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
    elseif jitter_type == "X-Way" then
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
        local found_key = nil
        for key, _ in pairs(menu.aa) do
            if type(key) == "string" and key:find(phys_state) then
                if not found_key or #key > #found_key then
                    found_key = key
                end
            end
        end
        if found_key then settings = menu.aa[found_key] end
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

    local final_delay = ui.get(settings.yaw["delay" .. delay_switch]) or 0

    if ui.get(settings.yaw.randomize_delay) then
        local min_val = ui.get(settings.yaw.randomize_delay_min)
        local max_val = ui.get(settings.yaw.randomize_delay_max)
        if min_val > max_val then min_val, max_val = max_val, min_val end
        final_delay = math.random(math.floor(min_val), math.floor(max_val))
    end

    if ui.get(settings.yaw.delay_mode) == "Old" then
        if (delay_switch > ui.get(settings.yaw.delay_ways)) then delay_switch = 1 end
        if (e.command_number % (final_delay + 2 + brute_d) == 0) then ready = true end

    elseif ui.get(settings.yaw.delay_mode) == "New" then
        if (delay_switch > ui.get(settings.yaw.delay_ways)) then delay_switch = 1 end
        if (globals.tickcount() % (final_delay + 2 + brute_d) == 0) then ready = true end
    end
    if (e.command_number % make_odd(ui.get(settings.hidden.yaw.delay) + 3) == 0) then def_ready = true; end
    local jitter_type = ui.get(settings.yaw.yaw_jitter)
    local nya = (jitter_type == "Custom" or jitter_type == "Skitter" or jitter_type == "Center" or jitter_type == "X-Way") and generate_nya(e, ui.get(settings.yaw.yaw_jitter_value_l) + brute_l, ui.get(settings.yaw.yaw_jitter_value_r) + brute_r, settings) or 0
    if (fake_lag) then 
        if (ready) then side = not side; ready = false; delay_switch = delay_switch + 1; end
        if (def_ready) then def_side = not def_side; def_ready = false; end
    end
    local manual = ui.get(menu.aa.left_checkbox) and -90 or (ui.get(menu.aa.right_checkbox) and 90 or (ui.get(menu.aa.forward_checkbox) and 180 or (ui.get(menu.aa.backward_checkbox) and 0 or 0)))
    if (not (reference.antiaim.angles.freestanding[1]:get() and reference.antiaim.angles.freestanding[1]:get_hotkey())) then
        if (fake_lag) then
            if (not ui.get(menu.aa.backward_checkbox)) then
                local yaw_lr = ui.get(settings.yaw.yaw) == "L/R" and (side and ui.get(settings.yaw.yaw_value_l) + brute_l or ui.get(settings.yaw.yaw_value_r)) + brute_r or 0


                local yaw_spin = (contains(ui.get(settings.yaw.yaw_extra), "Spin") and ui.get(settings.yaw.yaw_extra_spin) ~= 0) and (extra_yaw(e.command_number * 2, "Spin", -ui.get(settings.yaw.yaw_extra_spin), ui.get(settings.yaw.yaw_extra_spin))) or 0
                local yaw_sway = (contains(ui.get(settings.yaw.yaw_extra), "Sway") and ui.get(settings.yaw.yaw_extra_sway) ~= 0) and (extra_yaw(e.command_number * 2, "Sway", -ui.get(settings.yaw.yaw_extra_sway), ui.get(settings.yaw.yaw_extra_sway))) or 0
                local yaw_randomize = contains(ui.get(settings.yaw.yaw_extra), "Randomize") and (extra_yaw(e.command_number * 2, "Randomize", -ui.get(settings.yaw.yaw_extra_randomize), ui.get(settings.yaw.yaw_extra_randomize))) or 0
                local yaw_flick = contains(ui.get(settings.yaw.yaw_extra), "Flick") and (extra_yaw(e.command_number * 2, "Flick", -ui.get(settings.yaw.yaw_extra_flick), ui.get(settings.yaw.yaw_extra_flick))) or 0
                
                local offset = ui.get(settings.yaw.yaw_jitter) == "Offset" and (side and ui.get(settings.yaw.yaw_jitter_value_l) + brute_l or ui.get(settings.yaw.yaw_jitter_value_r) + brute_r) or 0

                local custom_yaw_offset = ui.get(settings.yaw.yaw_custom) or 0
                
                local down = ui.get(settings.pitch.pitch) == "Down" and 89 or 0
                local up = ui.get(settings.pitch.pitch) == "Up" and -89 or 0
                local zero = ui.get(settings.pitch.pitch) == "Zero" and 0 or 0
                local random = ui.get(settings.pitch.pitch) == "Random" and math.random(-89,89) or 0
                local custom = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0

            if (sim_diff() <= -1 and ui.get(settings.exploit.hidden)) then
                local yaw_custom = ui.get(settings.hidden.yaw.yaw) == "Custom" and ui.get(settings.hidden.yaw.yaw_value) or 0
                local yaw_lr = ui.get(settings.hidden.yaw.yaw) == "L/R" and (def_side and ui.get(settings.hidden.yaw.yaw_value_l) + brute_l or ui.get(settings.hidden.yaw.yaw_value_r) + brute_r) or 0

                e.yaw = normalize_angle(target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway + yaw_randomize + yaw_flick + offset + nya + yaw_custom + custom_yaw_offset + manual, -180, 180)

                    local downd = ui.get(settings.hidden.pitch.pitch) == "Down" and 89 or 0
                    local upd = ui.get(settings.hidden.pitch.pitch) == "Up" and -89 or 0
                    local zerod = ui.get(settings.hidden.pitch.pitch) == "Zero" and 0 or 0
                    local randomd = ui.get(settings.hidden.pitch.pitch) == "Random" and math.random(-89,89) or 0
                    local customd = ui.get(settings.hidden.pitch.pitch) == "Custom" and ui.get(settings.hidden.pitch.pitch_value) or 0
                    e.pitch = normalize_angle(downd+upd+zerod+randomd+customd,-89,89)
                else
                    e.yaw = normalize_angle(target_yaw + 180 + yaw_lr + yaw_spin + yaw_sway + yaw_randomize + yaw_flick + offset + nya + custom_yaw_offset + manual, -180, 180)

                    local down = ui.get(settings.pitch.pitch) == "Down" and 89 or 0
                    local up = ui.get(settings.pitch.pitch) == "Up" and -89 or 0
                    local zero = ui.get(settings.pitch.pitch) == "Zero" and 0 or 0
                    local random = ui.get(settings.pitch.pitch) == "Random" and math.random(-89,89) or 0
                    local custom = ui.get(settings.pitch.pitch) == "Custom" and ui.get(settings.pitch.pitch_value) or 0
    
                    e.pitch = normalize_angle(down+up+zero+random+custom,-89,89)
                end
            else
                e.pitch = 89
                e.yaw = normalize_angle(get_yaw(false) + 180, -180,180)
            end
        elseif (ui.get(settings.yaw.body_yaw) ~= "Off") then
            if (not ui.get(menu.aa.backward_checkbox)) then
                local inverter = (contains(ui.get(settings.yaw.additions), "Body-Yaw Inverter") and ui.get(settings.yaw.body_yaw_value_r) * 2 or -ui.get(settings.yaw.body_yaw_value_l) * 2)
                local inverter1 = (contains(ui.get(settings.yaw.additions), "Body-Yaw Inverter") and -ui.get(settings.yaw.body_yaw_value_l) * 2 or ui.get(settings.yaw.body_yaw_value_r) * 2)

                local yaw_lr = ui.get(settings.yaw.yaw) == "L/R" and (side and ui.get(settings.yaw.yaw_value_l) + brute_l or ui.get(settings.yaw.yaw_value_r) + brute_r) or 0

                local yaw_spin = (contains(ui.get(settings.yaw.yaw_extra), "Spin") and ui.get(settings.yaw.yaw_extra_spin) ~= 0) and (extra_yaw(e.command_number * 2, "Spin", -ui.get(settings.yaw.yaw_extra_spin), ui.get(settings.yaw.yaw_extra_spin))) or 0
                local yaw_sway = (contains(ui.get(settings.yaw.yaw_extra), "Sway") and ui.get(settings.yaw.yaw_extra_sway) ~= 0) and (extra_yaw(e.command_number * 2, "Sway", -ui.get(settings.yaw.yaw_extra_sway), ui.get(settings.yaw.yaw_extra_sway))) or 0
                local yaw_randomize = contains(ui.get(settings.yaw.yaw_extra), "Randomize") and (extra_yaw(e.command_number * 2, "Randomize", -ui.get(settings.yaw.yaw_extra_randomize), ui.get(settings.yaw.yaw_extra_randomize))) or 0
                local yaw_flick = contains(ui.get(settings.yaw.yaw_extra), "Flick") and (extra_yaw(e.command_number * 2, "Flick", -ui.get(settings.yaw.yaw_extra_flick), ui.get(settings.yaw.yaw_extra_flick))) or 0
                
                local offset = ui.get(settings.yaw.yaw_jitter) == "Offset" and (side and ui.get(settings.yaw.yaw_jitter_value_l) + brute_l or ui.get(settings.yaw.yaw_jitter_value_r) + brute_r) or 0

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
local last_backtrack_ticks = 0
local last_aimed = ""
local last_predicted_damage
local eye = 0
local shot = 0
client.set_event_callback("bullet_impact", function(e)
    eye = vector(client.eye_position())
    shot = vector(e.x, e.y, e.z)
end)
local shot_pos = 0
local function aim_fire(e)
    last_aimed = hitgroup_names[e.hitgroup + 1] or 'null'
    last_backtrack_ticks = globals.tickcount() - e.tick
    last_predicted_damage = e.damage
    shot_pos = vector(e.x, e.y, e.z)
end
local function aim_miss(e)
    local color = hexToRgb(lua_color)
    local aim, shot = 
                (eye-shot_pos):angles(),
                (eye-shot):angles()

                spread_angle = string.format('%.2f',vector(aim-shot):length2d())
    local color = hexToRgb(lua_color)
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local hitchance = math.floor(e.hit_chance)
    if e.reason == "?" then e.reason = "unknown" end
    logs.add_typed("Missed " .. entity.get_player_name(e.target):lower() .. " in " .. group .. " due to " .. e.reason, "miss")

    client.color_log(250,100,100, string.format(
        " missed\0",
        entity.get_player_name(e.target), group, e.reason, hitchance, last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " shot at %s's %s due to\0",
        entity.get_player_name(e.target):lower(), group, e.reason, hitchance, last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(250,100,100, string.format(
        " %s\0",
        e.reason, hitchance, last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " - hc: \0",
        hitchance, last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(250,100,100, string.format(
        "%s%%\0",
        hitchance, last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " damage: \0",
        last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(250,100,100, string.format(
        "%s\0",
        last_predicted_damage, last_backtrack_ticks, spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " bt: \0",
        last_backtrack_ticks, spread_angle
    ))
    client.color_log(250,100,100, string.format(
        "%s\0",
        last_backtrack_ticks, spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " spread: \0",
        spread_angle
    ))
    client.color_log(250,100,100, string.format(
        "%s°\0",
        spread_angle
    ))
    client.color_log(255,255,255, string.format(
        " "
    ))
end
local function aim_hit(e)
    if not ui.get(menu.features.visuals.logs) then return end
    local aim, shot = 
                (eye-shot_pos):angles(),
                (eye-shot):angles()

                spread_angle = string.format('%.2f',vector(aim-shot):length2d())
    local color = hexToRgb(lua_color)
    local remaining_health = entity.get_prop(e.target, 'm_iHealth')
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    logs.add("Hit " .. entity.get_player_name(e.target):lower() .. " in " .. group .. " for " .. e.damage .. " damage")

    client.color_log(color[1],color[2],color[3],string.format(
        " registered\0"
    ))
    client.color_log(255,255,255,string.format(
        " shot at %s's %s for \0",
        entity.get_player_name(e.target):lower(), group
    ))
    client.color_log(color[1],color[2],color[3],string.format(
        "%d - %s\0",
        e.damage,
        last_predicted_damage
    ))
    client.color_log(255,255,255,string.format(
        " damage - hp: \0",
        entity.get_player_name(e.target), group, e.damage,
        last_predicted_damage, entity.get_prop(e.target, 'm_iHealth'), last_aimed, last_backtrack_ticks, spread_angle
    ))
    client.color_log(color[1],color[2],color[3],string.format(
        "%s\0",
        entity.get_prop(e.target, 'm_iHealth')
    ))
    client.color_log(255,255,255,string.format(
        " aimed: \0",
        entity.get_player_name(e.target), group, e.damage,
        last_predicted_damage, entity.get_prop(e.target, 'm_iHealth'), last_aimed, last_backtrack_ticks, spread_angle
    ))
    client.color_log(color[1],color[2],color[3],string.format(
        "%s\0",
        last_aimed
    ))
    client.color_log(255,255,255,string.format(
        " bt: \0",
        entity.get_player_name(e.target), group, e.damage,
        last_predicted_damage, entity.get_prop(e.target, 'm_iHealth'), last_aimed, last_backtrack_ticks, spread_angle
    ))
    client.color_log(color[1],color[2],color[3],string.format(
        "%s\0",
        last_backtrack_ticks
    ))
    client.color_log(255,255,255,string.format(
        " spread: \0",
        entity.get_player_name(e.target), group, e.damage,
        last_predicted_damage, entity.get_prop(e.target, 'm_iHealth'), last_aimed, last_backtrack_ticks, spread_angle
    ))
    client.color_log(color[1],color[2],color[3],string.format(
        "%s°\0",
        spread_angle
    ))
    client.color_log(255,255,255,string.format(
        " "
    ))
end
client.set_event_callback("aim_fire", aim_fire)
client.set_event_callback("aim_miss", aim_miss)
client.set_event_callback("aim_hit", aim_hit)

local clan_tag_spammer do
    local clan_tag_prev = ''
    local enabled_prev = false
    local sequence = {
        '                           ',
        'a                          ',
        'a|<                        ',
        'au$                        ',
        'aur><                      ',
        'auro|?>                    ',
        'auror#$                    ',
        'aurora$                    ',
        'aurora@.                   ',
        'aurora.l$                  ',
        'aurora.lu|<                ',
        ' aurora.lua                ',
        '  aurora.lua               ',
        '   aurora.lua              ',
        '    aurora.lua             ',
        '     aurora.lua            ',
        '      aurora.lua           ',
        '       ?urora.lua          ',
        '         $%rora.lua        ',
        '          $@<ora.lua       ',
        '           %8*#%.ra.lua    ',
        '            |<>|a.lua      ',
        '             |>O()#@lua    ',
        '              $*&!#ua      ',
        '               $*&!#u      ',
        '                !@E#!      ',
        '                 |><>|     ',
        '                           ',
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
            --{"хорошая попытка", 0.2, "можешь больше не стараться", 0.5},
            {"⛧ BLOODYSTAR.COM", 0.2},
            {"GΣƬ ЯΣKƬ ⛧ ΛƧMӨDΣЦƧ ЯIDΣƧ ЦЯ MӨM ƬӨПIGΉƬ 666 ƧΛᄃЯIFIᄃΣ ЦЯ KD ☥", 0.2, "1", 1.0},
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

---

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

---

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

---

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
        -- 9 - awp, 40 = scout
        if weapon_id == 9 or weapon_id == 40 then
            ui.set(hitchance_ref, 100)
        end
    end
end)

local mouse_hold_right = false
local beta_font_mode = 1
local beta_font_modes = {" ", "b", "c-"}

client.set_event_callback("paint_ui", function()
    if not contains(ui.get(menu.features.visuals.watermark_type), "Text Watermark") then 
        return 
    end

    local x, y = aurora_beta.x, aurora_beta.y
    local font = beta_font_modes[beta_font_mode]

    local text1 = "Aurora Beta"
    local text2 = " / " .. lua.username

    local w1 = renderer.measure_text(font, text1)
    local w2 = renderer.measure_text(font, text2)
    local full_width = w1 + w2

    local height = 24

    dragging_system.set_width(aurora_beta, full_width + 10)
    dragging_system.set_height(aurora_beta, height - 5)

    local center_x = x + (aurora_beta.w - full_width) / 2

    renderer.text(center_x, y + 3.5, 255, 255, 255, 255, font, 0, lua_color .. text1)

    renderer.text(center_x + w1, y + 3.5, 255, 255, 255, 255, font, 0, text2)

    local mx, my = ui.mouse_position()
    local hovered = mx >= x and mx <= x + aurora_beta.w and my >= y and my <= y + height

    if hovered and client.key_state(0x02) and not mouse_hold_right then
        beta_font_mode = beta_font_mode % #beta_font_modes + 1
    end

    mouse_hold_right = client.key_state(0x02)
end)




--[[
local aurora_overlay = {
    show = true,
    alpha = 0,
    base_alpha = 240,
    start_time = globals.realtime(),
    fade_in_speed = 4,
    fade_out_speed = 5,
    display_duration = 3.8,
    stage = "fade_in",
    text_anim_p = 0,
    bar_p = 0
}

local function OrganiqueLerp(start, vend, time)
    return start + (vend - start) * (1 - math.exp(-time * globals.frametime() * 7))
end

local function DrawVerticalGradient(x, y, w, h, r1, g1, b1, a1, r2, g2, b2, a2)
    renderer.gradient(x, y, w, h, r1, g1, b1, a1, r2, g2, b2, a2, false)
end

client.set_event_callback("paint_ui", function()
    if not aurora_overlay.show or aurora_overlay.stage == "finished" then return end

    local screen_w, screen_h = client.screen_size()
    local realtime = globals.realtime()
    local delta = realtime - aurora_overlay.start_time
    local frametime = globals.frametime()

    local target_alpha = 0
    
    if aurora_overlay.stage == "fade_in" then
        target_alpha = aurora_overlay.base_alpha
        aurora_overlay.alpha = math.min(aurora_overlay.base_alpha, aurora_overlay.alpha + frametime * aurora_overlay.fade_in_speed * 150)
        
        if aurora_overlay.alpha >= aurora_overlay.base_alpha - 1 then
            aurora_overlay.stage = "display"
            aurora_overlay.alpha = aurora_overlay.base_alpha
        end
        
    elseif aurora_overlay.stage == "display" then
        target_alpha = aurora_overlay.base_alpha
        aurora_overlay.alpha = aurora_overlay.base_alpha
        
        if delta > aurora_overlay.display_duration then
            aurora_overlay.stage = "fade_out"
        end
        
    elseif aurora_overlay.stage == "fade_out" then
        target_alpha = 0
        aurora_overlay.alpha = math.max(0, aurora_overlay.alpha - frametime * aurora_overlay.fade_out_speed * 150)
        
        if aurora_overlay.alpha <= 1 then
            aurora_overlay.stage = "finished"
            aurora_overlay.show = false
            return
        end
    end

    local a = aurora_overlay.alpha
    if a < 1 then return end

    local r, g, b = menu_r or 120, menu_g or 160, menu_b or 255
    local a_mult = a / 255

    DrawVerticalGradient(0, 0, screen_w, screen_h, 15, 15, 20, a * 0.9, 5, 5, 8, a * 0.98)

    renderer.rectangle(0, 0, screen_w, 2, r, g, b, a)
    
    DrawVerticalGradient(0, 2, screen_w, 80, r, g, b, a * 0.15, r, g, b, 0)

    local centerX = screen_w / 2
    local centerY = screen_h / 2

    local username = (lua.username or "User"):upper()
    local build = (lua.build or "PREMIUM"):upper()

    aurora_overlay.text_anim_p = OrganiqueLerp(aurora_overlay.text_anim_p, 1, 0.5)
    local text_y_offset = (1 - aurora_overlay.text_anim_p) * 25

    local logo_y = centerY - 60 + text_y_offset
    
    renderer.text(centerX, logo_y, r, g, b, a * 0.2, "bc", 0, "A U R O R A")
    renderer.text(centerX, logo_y - 1, 255, 255, 255, a, "bc", 0, "A U R O R A")

    local line_w = 40
    local line_y = logo_y + 15
    renderer.gradient(centerX - line_w, line_y, line_w, 1, r, g, b, 0, r, g, b, a, true)
    renderer.gradient(centerX, line_y, line_w, 1, r, g, b, a, r, g, b, 0, true)

    local info_y = line_y + 15
    local welcome_str = "W E L C O M E  B A C K ,"
    
    renderer.text(centerX, info_y, 200, 200, 200, a * 0.9, "c", 0, welcome_str)
    renderer.text(centerX, info_y + 18, r, g, b, a, "bc", 0, username)

    local build_y = centerY + 50 + text_y_offset
    renderer.text(centerX, build_y, 130, 130, 130, a * 0.7, "c", 0, "BUILD: " .. build)

    local bar_w = 260
    local bar_x = centerX - bar_w / 2
    local bar_y = centerY + 85 + text_y_offset
    
    local target_progress = math.min(1, delta / (aurora_overlay.display_duration - 0.2))
    aurora_overlay.bar_p = OrganiqueLerp(aurora_overlay.bar_p, target_progress, 0.4)

    renderer.rectangle(bar_x, bar_y, bar_w, 1, 40, 40, 45, a * 0.5)
    
    local current_bar_w = bar_w * aurora_overlay.bar_p
    renderer.gradient(bar_x, bar_y, current_bar_w, 1, r, g, b, a * 0.6, r, g, b, a, true)
    
    if aurora_overlay.bar_p > 0.01 and aurora_overlay.bar_p < 0.99 then
        renderer.rectangle(bar_x + current_bar_w - 1, bar_y - 1, 2, 3, 255, 255, 255, a * 0.8)
    end
end)
--]]
local debug_config = {
    x = 20,
    y = 350,
    w = 210,
    active = true
}

local function draw_debug_line(x, y, label, value, r, g, b, a)
    renderer.text(x, y, 220, 220, 220, a, "", 0, label .. ":")
    local spacing = renderer.measure_text("", label .. ": ")
    renderer.text(x + spacing, y, r, g, b, a, "b", 0, tostring(value))
end

client.set_event_callback("paint_ui", function()
    if not ui.get(menu.features.visuals.debug_panel)then return end

    local r, g, b = menu_r or 150, menu_g or 150, menu_b or 255
    local x, y = debug_config.x, debug_config.y
    local a = 255

    local h, m, s = client.system_time()
    local time_str = string.format("%02d:%02d:%02d", h, m, s)

    local local_player = entity.get_local_player()
    local pitch, yaw = 0, 0
    local current_condition = "Stand"

    if local_player ~= nil and entity.is_alive(local_player) then
        pitch, yaw = entity.get_prop(local_player, "m_angEyeAngles")
        
        local vx, vy, vz = entity.get_prop(local_player, "m_vecVelocity")
        local velocity = math.sqrt(vx*vx + vy*vy)
        local flags = entity.get_prop(local_player, "m_fFlags")
        
        if bit.band(flags, 1) == 0 then
            current_condition = "Air"
        elseif slow_motion then
            current_condition = "Slow"
        elseif velocity > 1.1 then
            current_condition = "Move"
        else
            current_condition = "Stand"
        end
    end

    local debug_items = {
        {"User", lua.username},
        {"Condition", current_condition},
        {"Pitch", string.format("%.1f", pitch)},
        {"Yaw", string.format("%.1f", yaw)},
        {"Time", time_str},
        {"FPS", math.floor(1 / globals.frametime())}
    }

    local line_h = 17
    local padding = 12
    local header_h = 30
    local total_h = #debug_items * line_h + header_h + 5

    renderer.text(x + padding, y + 8, 255, 255, 255, a, "b", 0, "AURORA BETA")

    local curr_y = y + header_h
    for i=1, #debug_items do
        draw_debug_line(x + padding, curr_y, debug_items[i][1], debug_items[i][2], r, g, b, a)
        curr_y = curr_y + line_h
    end

    local line_y = y + 26
    local line_w = debug_config.w - (padding * 2)
    local line_x = x + padding
    
    renderer.gradient(line_x, line_y, line_w / 2, 1, r, g, b, 0, r, g, b, a, true)
    renderer.gradient(line_x + line_w / 2, line_y, line_w / 2, 1, r, g, b, a, r, g, b, 0, true)

    if ui.is_menu_open() then
        local mouse_x, mouse_y = ui.mouse_position()
        if client.key_state(0x01) then 
            if mouse_x >= x and mouse_x <= x + debug_config.w and mouse_y >= y and mouse_y <= y + total_h then
                debug_config.x = mouse_x - (debug_config.w / 2)
                debug_config.y = mouse_y - 20
            end
        end
    end
end)