script_name("locator")
script_author("qrlk")
script_version("15.06.2020")
script_description("Локатор машин для угонщиков")

local inicfg = require "inicfg"
local dlstatus = require("moonloader").download_status

color = 0x7ef3fa
settings =
    inicfg.load(
    {
        locator = {
            enable = true,
            bubble = false,
            antiwarning = true,
            startmessage = true,
            autoupdate = true,
            key = 90
        }
    },
    "locator"
)
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(100)
    end
    transponder_thread = lua_thread.create(transponder)

    if settings.locator.autoupdate then
        update(
            "http://qrlk.me/dev/moonloader/locator/stats.php",
            "[" .. string.upper(thisScript().name) .. "]: ",
            "http://qrlk.me/sampvk",
            "locatorlog"
        )
        openchangelog("locatorlog", "http://qrlk.me/sampvk")
    end

    if settings.locator.startmessage then
        sampAddChatMessage("locator v" .. thisScript().version .. " активирован! /locator - menu. Автор: qrlk.", color)
    end

    sampRegisterChatCommand(
        "locator",
        function()
            lua_thread.create(
                function()
                    updateMenu()
                    submenus_show(
                        mod_submenus_sa,
                        "{348cb2}locator v." .. thisScript().version,
                        "Выбрать",
                        "Закрыть",
                        "Назад"
                    )
                end
            )
        end
    )
    wait(-1)
end

function updateMenu()
    mod_submenus_sa = {
        {
            title = "Информация о скрипте",
            onclick = function()
                sampShowDialog(
                    0,
                    "{7ef3fa}/locator v." .. thisScript().version .. ' - информация о мо',
                    "{00ff66}Locator{ffffff}\n{ffffff}Поиск машин для автоугона с помощью сервера.",
                    "Окей"
                )
            end
        },
        {
            title = " ", 
        },
        {
            title = "{00ff66}Настройки",
            submenu = {
                {
                    title = "Вкл/выкл автообновление: " .. tostring(settings.locator.enable),
                    onclick = function()
                        settings.locator.autoupdate = not settings.locator.autoupdate
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = "Вкл/выкл сообщение при старте: " .. tostring(settings.locator.startmessage),
                    onclick = function()
                        settings.locator.startmessage = not settings.locator.startmessage
                        inicfg.save(settings, "locator")
                    end
                }
            }
        }
    }
end
function transponder()
    while true do
        wait(3000)
        if getActiveInterior() == 0 and sampGetCurrentServerAddress() == "185.169.134.11" then
            request_table = {}
            request_table["vehicles"] = {}
            if doesCharExist(playerPed) then
                _res, _id = sampGetPlayerIdByCharHandle(playerPed)
                if _res then
                    for k, v in pairs(getAllVehicles()) do
                        if doesVehicleExist(v) then
                            _res, _id = sampGetVehicleIdByCarHandle(v)
                            if _res then
                                _x, _y, _z = getCarCoordinates(v)
                                table.insert(
                                    request_table["vehicles"],
                                    {
                                        id = _id,
                                        type = "vehicle",
                                        pos = {
                                            x = _x,
                                            y = _y,
                                            z = _z
                                        },
                                        heading = getCarHeading(v),
                                        health = getCarHealth(v),
                                        model = getCarModel(v),
                                        occupied = doesCharExist(getDriverOfCar(v)),
                                        locked = getCarDoorLockStatus(v)
                                    }
                                )
                            end
                        end
                    end
                end
            end
            downloadUrlToFile("http://192.168.1.76:46547/" .. encodeJson(request_table))
            sampAddChatMessage("Запрос отправлен", -1)
        end
    end
end
--------------------------------------------------------------------------------
------------------------------------UPDATE--------------------------------------
--------------------------------------------------------------------------------
--автообновление в обмен на статистику использования
function update(php, prefix, url, komanda)
    komandaA = komanda
    local dlstatus = require("moonloader").download_status
    local json = getWorkingDirectory() .. "\\" .. thisScript().name .. "-version.json"
    if doesFileExist(json) then
        os.remove(json)
    end
    local ffi = require "ffi"
    ffi.cdef [[
      int __stdcall GetVolumeInformationA(
              const char* lpRootPathName,
              char* lpVolumeNameBuffer,
              uint32_t nVolumeNameSize,
              uint32_t* lpVolumeSerialNumber,
              uint32_t* lpMaximumComponentLength,
              uint32_t* lpFileSystemFlags,
              char* lpFileSystemNameBuffer,
              uint32_t nFileSystemNameSize
      );
      ]]
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    serial = serial[0]
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local nickname = sampGetPlayerNickname(myid)
    if thisScript().name == "ADBLOCK" then
        if mode == nil then
            mode = "unsupported"
        end
        php =
            php ..
            "?id=" ..
                serial ..
                    "&n=" ..
                        nickname ..
                            "&i=" ..
                                sampGetCurrentServerAddress() ..
                                    "&m=" .. mode .. "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    elseif thisScript().name == "pisser" then
        php =
            php ..
            "?id=" ..
                serial ..
                    "&n=" ..
                        nickname ..
                            "&i=" ..
                                sampGetCurrentServerAddress() ..
                                    "&m=" ..
                                        tostring(data.options.stats) ..
                                            "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    else
        php =
            php ..
            "?id=" ..
                serial ..
                    "&n=" ..
                        nickname ..
                            "&i=" ..
                                sampGetCurrentServerAddress() ..
                                    "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version
    end
    downloadUrlToFile(
        php,
        json,
        function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                if doesFileExist(json) then
                    local f = io.open(json, "r")
                    if f then
                        local info = decodeJson(f:read("*a"))
                        if info.stats ~= nil then
                            stats = info.stats
                        end
                        updatelink = info.updateurl
                        updateversion = info.latest
                        if info.changelog ~= nil then
                            changelogurl = info.changelog
                        end
                        f:close()
                        os.remove(json)
                        if updateversion ~= thisScript().version then
                            lua_thread.create(
                                function(prefix, komanda)
                                    local dlstatus = require("moonloader").download_status
                                    local color = -1
                                    sampAddChatMessage(
                                        (prefix ..
                                            "Обнаружено обновление. Пытаюсь обновиться c " ..
                                                thisScript().version .. " на " .. updateversion),
                                        color
                                    )
                                    wait(250)
                                    downloadUrlToFile(
                                        updatelink,
                                        thisScript().path,
                                        function(id3, status1, p13, p23)
                                            if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                                                print(string.format("Загружено %d из %d.", p13, p23))
                                            elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                                print("Загрузка обновления завершена.")
                                                if komandaA ~= nil then
                                                    sampAddChatMessage(
                                                        (prefix ..
                                                            "Обновление завершено! Подробнее об обновлении - /" ..
                                                                komandaA .. "."),
                                                        color
                                                    )
                                                end
                                                goupdatestatus = true
                                                lua_thread.create(
                                                    function()
                                                        wait(500)
                                                        thisScript():reload()
                                                    end
                                                )
                                            end
                                            if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                                                if goupdatestatus == nil then
                                                    sampAddChatMessage(
                                                        (prefix ..
                                                            "Обновление прошло неудачно. Запускаю устаревшую версию.."),
                                                        color
                                                    )
                                                    update = false
                                                end
                                            end
                                        end
                                    )
                                end,
                                prefix
                            )
                        else
                            update = false
                            print("v" .. thisScript().version .. ": Обновление не требуется.")
                        end
                    end
                else
                    print(
                        "v" ..
                            thisScript().version ..
                                ": Не могу проверить обновление. Смиритесь или проверьте самостоятельно на " .. url
                    )
                    update = false
                end
            end
        end
    )
    while update ~= false do
        wait(100)
    end
end

function openchangelog(komanda, url)
    sampRegisterChatCommand(
        komanda,
        function()
            lua_thread.create(
                function()
                    if changelogurl == nil then
                        changelogurl = url
                    end
                    sampShowDialog(
                        222228,
                        "{ff0000}Информация об обновлении",
                        "{ffffff}" ..
                            thisScript().name ..
                                " {ffe600}собирается открыть свой changelog для вас.\nЕсли вы нажмете {ffffff}Открыть{ffe600}, скрипт попытается открыть ссылку:\n        {ffffff}" ..
                                    changelogurl ..
                                        "\n{ffe600}Если ваша игра крашнется, вы можете открыть эту ссылку сами.",
                        "Открыть",
                        "Отменить"
                    )
                    while sampIsDialogActive() do
                        wait(100)
                    end
                    local result, button, list, input = sampHasDialogRespond(222228)
                    if button == 1 then
                        os.execute('explorer "' .. changelogurl .. '"')
                    end
                end
            )
        end
    )
end
--------------------------------------------------------------------------------
--------------------------------------3RD---------------------------------------
--------------------------------------------------------------------------------
-- made by FYP
function submenus_show(menu, caption, select_button, close_button, back_button)
    select_button, close_button, back_button = select_button or "Select", close_button or "Close", back_button or "Back"
    prev_menus = {}
    function display(menu, id, caption)
        local string_list = {}
        for i, v in ipairs(menu) do
            table.insert(string_list, type(v.submenu) == "table" and v.title .. "  >>" or v.title)
        end
        sampShowDialog(
            id,
            caption,
            table.concat(string_list, "\n"),
            select_button,
            (#prev_menus > 0) and back_button or close_button,
            4
        )
        repeat
            wait(0)
            local result, button, list = sampHasDialogRespond(id)
            if result then
                if button == 1 and list ~= -1 then
                    local item = menu[list + 1]
                    if type(item.submenu) == "table" then -- submenu
                        table.insert(prev_menus, {menu = menu, caption = caption})
                        if type(item.onclick) == "function" then
                            item.onclick(menu, list + 1, item.submenu)
                        end
                        return display(item.submenu, id + 1, item.submenu.title and item.submenu.title or item.title)
                    elseif type(item.onclick) == "function" then
                        local result = item.onclick(menu, list + 1)
                        if not result then
                            return result
                        end
                        return display(menu, id, caption)
                    end
                else -- if button == 0
                    if #prev_menus > 0 then
                        local prev_menu = prev_menus[#prev_menus]
                        prev_menus[#prev_menus] = nil
                        return display(prev_menu.menu, id - 1, prev_menu.caption)
                    end
                    return false
                end
            end
        until result
    end
    return display(menu, 31337, caption or menu.title)
end
