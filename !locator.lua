script_name("locator")
script_author("qrlk")
script_version("18.06.2020")
script_description("Локатор машин для угонщиков")

local inicfg = require "inicfg"
local dlstatus = require("moonloader").download_status

select_car_dialog = {}
vhinfo = {}
request_model = -1
request_model_last = -1
marker_placed = false
response_timestamp = 0
ser_active = "?"
ser_count = "?"
delay_start = os.time()
color = 0x7ef3fa

settings =
    inicfg.load(
    {
        locator = {
            startmessage = true,
            autoupdate = true
        },
        map = {
            sqr = false
        },
        transponder = {
            allow_occupied = true,
            allow_unlocked = false,
            catch_srp_start = true,
            catch_srp_stop = true,
            catch_srp_gz = true,
            delay = 5999
        },
        handler = {
            mark_coolest = true,
            mark_coolest_sound = true,
            clear_mark = true
        }
    },
    "locator"
)
no_sampev = false
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end

    while not isSampAvailable() do
        wait(100)
    end

    if settings.locator.autoupdate then
        update(
            "http://qrlk.me/dev/moonloader/locator/stats.php",
            "[" .. string.upper(thisScript().name) .. "]: ",
            "http://qrlk.me/sampvk",
            "locatorlog"
        )
        openchangelog("locatorlog", "http://qrlk.me/sampvk")
    end

    transponder_thread = lua_thread.create(transponder)

    init()
    register_chat_commands()

    if settings.locator.startmessage then
        sampAddChatMessage(
            "{348cb2}locator v" ..
                thisScript().version ..
                    " активирован! {7ef3fa}/locator - menu {348cb2}~~{7ef3fa} /locatedonate - задонатить на сервер. {348cb2}Автор: qrlk.me",
            0x7ef3fa
        )
        if no_sampev then
            sampAddChatMessage(
                "Модуль SAMP.Lua не был загружен. Захват чата отключён. {348cb2}Подробнее: https://www.blast.hk/threads/14624/",
                0xff0000
            )
        end
    end

    while true do
        wait(0)
        fastmap()
    end
end

function register_chat_commands()
    sampRegisterChatCommand(
        "locator",
        function()
            lua_thread.create(
                function()
                    updateMenu()
                    wait(100)
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

    sampRegisterChatCommand(
        "ugon",
        function()
            lua_thread.create(legacy_edith_front)
        end
    )

    sampRegisterChatCommand(
        "locatedonate",
        function()
            os.execute('explorer "http://qrlk.me/donatelocator"')
        end
    )

    sampRegisterChatCommand(
        "locate",
        function(vh)
            if vh == "" then
                request_model = -1
                addOneOffSound(0.0, 0.0, 0.0, 1053)
            else
                if cars[string.lower(vh)] ~= nil then
                    request_model = cars[string.lower(vh)]
                    addOneOffSound(0.0, 0.0, 0.0, 1139)
                else
                    addOneOffSound(0.0, 0.0, 0.0, 1057)
                end
            end
        end
    )

    sampRegisterChatCommand(
        "locatelist",
        function()
            lua_thread.create(
                function()
                    submenus_show(
                        select_car_dialog,
                        "{348cb2}locator v." .. thisScript().version,
                        "Выбрать",
                        "Закрыть",
                        "Назад"
                    )
                end
            )
        end
    )
end
--------------------------------------------------------------------------------
-----------------------------------LOCATOR--------------------------------------
--------------------------------------------------------------------------------
cars = {
    ["-"] = -1,
    ["mesa"] = 500,
    ["hydra"] = 520,
    ["utility van"] = 552,
    ["petrol trailer"] = 584,
    ["fcr-900"] = 521,
    ["sentinel"] = 405,
    ["washington"] = 421,
    ["coach"] = 437,
    ["reefer"] = 453,
    ["sparrow"] = 469,
    ["baggage"] = 485,
    ["rc goblin"] = 501,
    ["nrg-500"] = 522,
    ["yosemite"] = 554,
    ["wayfarer"] = 586,
    ["hpv1000"] = 523,
    ["dumper"] = 406,
    ["bobcat"] = 422,
    ["cabbie"] = 438,
    ["tropic"] = 454,
    ["patriot"] = 470,
    ["dozer"] = 486,
    ["hotring racer a"] = 502,
    ["cement truck"] = 524,
    ["monster a"] = 556,
    ["hotdog"] = 588,
    ["towtruck"] = 525,
    ["firetruck"] = 407,
    ["mr whoopee"] = 423,
    ["stallion"] = 439,
    ["flatbed"] = 455,
    ["quad"] = 471,
    ["maverick"] = 487,
    ["hotring racer b"] = 503,
    ["fortune"] = 526,
    ["uranus"] = 558,
    ["freight box trailer (train)"] = 590,
    ["cadrona"] = 527,
    ["trashmaster"] = 408,
    ["bf injection"] = 424,
    ["rumpo"] = 440,
    ["yankee"] = 456,
    ["coastguard"] = 472,
    ["san news maverick"] = 488,
    ["bloodring banger"] = 504,
    ["fbi truck"] = 528,
    ["sultan"] = 560,
    ["andromada"] = 592,
    ["willard"] = 529,
    ["stretch"] = 409,
    ["hunter"] = 425,
    ["rc bandit"] = 441,
    ["caddy"] = 457,
    ["dinghy"] = 473,
    ["rancher"] = 489,
    ["rancher"] = 505,
    ["forklift"] = 530,
    ["elegy"] = 562,
    ["rc cam"] = 594,
    ["tractor"] = 531,
    ["manana"] = 410,
    ["premier"] = 426,
    ["romero"] = 442,
    ["solair"] = 458,
    ["hermes"] = 474,
    ["fbi rancher"] = 490,
    ["super gt"] = 506,
    ["combine harvester"] = 532,
    ["rc tiger"] = 564,
    ["police car (lspd)"] = 596,
    ["feltzer"] = 533,
    ["infernus"] = 411,
    ["enforcer"] = 427,
    ["packer"] = 443,
    ["topfun van"] = 459,
    ["sabre"] = 475,
    ["virgo"] = 491,
    ["elegant"] = 507,
    ["remington"] = 534,
    ["tahoma"] = 566,
    ["police car (lvpd)"] = 598,
    ["slamvan"] = 535,
    ["voodoo"] = 412,
    ["securicar"] = 428,
    ["monster"] = 444,
    ["skimmer"] = 460,
    ["rustler"] = 476,
    ["greenwood"] = 492,
    ["journey"] = 508,
    ["blade"] = 536,
    ["bandito"] = 568,
    ["picador"] = 600,
    ["freight (train)"] = 537,
    ["pony"] = 413,
    ["banshee"] = 429,
    ["admiral"] = 445,
    ["pcj-600"] = 461,
    ["zr-350"] = 477,
    ["jetmax"] = 493,
    ["bike"] = 509,
    ["brownstreak (train)"] = 538,
    ["streak trailer (train)"] = 570,
    ["alpha"] = 602,
    ["at400"] = 577,
    ["boxville"] = 609,
    ["tug"] = 583,
    ["baggage trailer b"] = 607,
    ["launch"] = 595,
    ["vortex"] = 539,
    ["mule"] = 414,
    ["predator"] = 430,
    ["squallo"] = 446,
    ["faggio"] = 462,
    ["walton"] = 478,
    ["hotring racer c"] = 494,
    ["mountain bike"] = 510,
    ["vincent"] = 540,
    ["mower"] = 572,
    ["glendale shit"] = 604,
    ["sadler shit"] = 605,
    ["phoenix"] = 603,
    ["s.w.a.t."] = 601,
    ["police ranger"] = 599,
    ["police car (sfpd)"] = 597,
    ["bullet"] = 541,
    ["cheetah"] = 415,
    ["bus"] = 431,
    ["seasparrow"] = 447,
    ["freeway"] = 463,
    ["regina"] = 479,
    ["sandking"] = 495,
    ["beagle"] = 511,
    ["clover"] = 542,
    ["sweeper"] = 574,
    ["baggage trailer a"] = 606,
    ["dodo"] = 593,
    ["article trailer 3"] = 591,
    ["club"] = 589,
    ["euros"] = 587,
    ["emperor"] = 585,
    ["landstalker"] = 400,
    ["ambulance"] = 416,
    ["rhino"] = 432,
    ["pizzaboy"] = 448,
    ["rc baron"] = 464,
    ["comet"] = 480,
    ["blista compact"] = 496,
    ["cropduster"] = 512,
    ["firetruck la"] = 544,
    ["tornado"] = 576,
    ["tug stairs trailer"] = 608,
    ["windsor"] = 555,
    ["bf-400"] = 581,
    ["savanna"] = 567,
    ["huntley"] = 579,
    ["stuntplane"] = 513,
    ["bravura"] = 401,
    ["leviathan"] = 417,
    ["barracks"] = 433,
    ["tram"] = 449,
    ["rc raider"] = 465,
    ["bmx"] = 481,
    ["police maverick"] = 497,
    ["tanker"] = 514,
    ["intruder"] = 546,
    ["dft-30"] = 578,
    ["farm trailer"] = 610,
    ["broadway"] = 575,
    ["dune"] = 573,
    ["kart"] = 571,
    ["freight flat trailer (train)"] = 569,
    ["roadtrain"] = 515,
    ["buffalo"] = 402,
    ["moonbeam"] = 418,
    ["hotknife"] = 434,
    ["article trailer 2"] = 450,
    ["glendale"] = 466,
    ["burrito"] = 482,
    ["boxville"] = 498,
    ["nebula"] = 516,
    ["cargobob"] = 548,
    ["stafford"] = 580,
    ["flash"] = 565,
    ["raindance"] = 563,
    ["stratum"] = 561,
    ["jester"] = 559,
    ["monster b"] = 557,
    ["majestic"] = 517,
    ["linerunner"] = 403,
    ["esperanto"] = 419,
    ["article trailer"] = 435,
    ["turismo"] = 451,
    ["oceanic"] = 467,
    ["camper"] = 483,
    ["benson"] = 499,
    ["buccaneer"] = 518,
    ["sunrise"] = 550,
    ["newsvan"] = 582,
    ["nevada"] = 553,
    ["merit"] = 551,
    ["tampa"] = 549,
    ["primo"] = 547,
    ["hustler"] = 545,
    ["shamal"] = 519,
    ["perenniel"] = 404,
    ["taxi"] = 420,
    ["previon"] = 436,
    ["speeder"] = 452,
    ["sanchez"] = 468,
    ["marquis"] = 484,
    ["sadler"] = 543
}
keys = {}
for k, v in pairs(cars) do
    table.insert(keys, k)
end
table.sort(keys)
for k, v in pairs(keys) do
    table.insert(
        select_car_dialog,
        {
            title = v,
            onclick = function()
                request_model = cars[v]
                if request_model == -1 then
                    addOneOffSound(0.0, 0.0, 0.0, 1053)
                else
                    addOneOffSound(0.0, 0.0, 0.0, 1139)
                end
            end
        }
    )
end

function transponder()
    while true do
        wait(0)
        delay_start = os.time()
        wait(settings.transponder.delay)
        if getActiveInterior() == 0 then
            request_table = {}
            local ip, port = sampGetCurrentServerAddress()
            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            request_table["info"] = {
                server = ip .. ":" .. tostring(port),
                sender = sampGetPlayerNickname(myid),
                request = request_model,
                allow_occupied = settings.transponder.allow_occupied,
                allow_unlocked = settings.transponder.allow_unlocked
            }
            request_table["vehicles"] = {}
            if doesCharExist(playerPed) then
                -- игнорируем ту машину, которой пользуемся, чтобы не воровали нашу машину
                local ped_car = getCarCharIsUsing(playerPed)
                for k, v in pairs(getAllVehicles()) do
                    if v ~= ped_car then
                        if doesVehicleExist(v) then
                            _res, _id = sampGetVehicleIdByCarHandle(v)
                            if _res then
                                _x, _y, _z = getCarCoordinates(v)
                                table.insert(
                                    request_table["vehicles"],
                                    {
                                        id = _id,
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
            collecting_data = false
            wait_for_response = true
            local response_path = os.tmpname()
            down = false
            downloadUrlToFile(
                "http://locator.qrlk.me:46547/" .. encodeJson(request_table),
                response_path,
                function(id, status, p1, p2)
                    if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                        down = true
                    end
                    if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                        wait_for_response = false
                    end
                end
            )
            while wait_for_response do
                wait(10)
            end
            processing_response = true

            if down and doesFileExist(response_path) then
                local f = io.open(response_path, "r")
                if f then
                    local info = decodeJson(f:read("*a"))
                    if info == nil then
                        sampAddChatMessage(
                            "{ff0000}[" ..
                                string.upper(thisScript().name) ..
                                    "]: Был получен некорректный ответ от сервера. Работа скрипта завершена.",
                            0x348cb2
                        )
                        thisScript():unload()
                    else
                        if info.result == "ok" then
                            response_timestamp = info.timestamp
                            ser_active = info.active
                            ser_count = info.count
                            if info.response ~= nil then
                                if info.response == "no cars" then
                                    vhinfo = {}
                                    if settings.handler.clear_mark and marker_placed then
                                        removeWaypoint()
                                    end
                                else
                                    vhinfo = info.response
                                    if settings.handler.mark_coolest then
                                        mark_coolest_car()
                                    end
                                end
                            else
                                if settings.handler.clear_mark and marker_placed then
                                    removeWaypoint()
                                end
                            end
                        end
                        wait_for_response = false
                    end
                    f:close()
                    --setClipboardText(response_path)
                    os.remove(response_path)
                end
            else
                print(
                    "{ff0000}[" ..
                        string.upper(thisScript().name) ..
                            "]: Мы не смогли получить ответ от сервера. Возможно слишком много машин, проблема с интернетом, сервер упал или автор ТРАГИЧЕСКИ ПОГИБ.",
                    0x348cb2
                )
                print(
                    "{ff0000}[" ..
                        string.upper(thisScript().name) ..
                            "]: Если вы отключили автообновление, возможно поменялся айпи сервера. Включите его вручную в конфиге скрипта (папка config в ml).",
                    0x348cb2
                )
                print(
                    "{ff0000}[" ..
                        string.upper(thisScript().name) ..
                            "]: Если автор всё-таки кормит червей, возможно кто-то другой захостил у себя скрипт, погуглите.",
                    0x348cb2
                )
            end
            if doesFileExist(response_path) then
                os.remove(response_path)
            end
            processing_response = false
        end
    end
end

function count_next()
    if getActiveInterior() == 0 then
        local count = math.floor(settings.transponder.delay / 1000) - tonumber(os.time() - delay_start)
        if count >= 0 then
            return tostring(count) .. "c"
        elseif wait_for_response then
            return "WAITING FOR RESPONSE"
        elseif processing_response then
            return "PROCESSING RESPONSE"
        else
            return "PERFOMING REQUEST"
        end
    else
        return "выйди из инт"
    end
end

gz_squareStart = {}
gz_squareEnd = {}
gz_id = -1

if
    pcall(
        function()
            sampev = require "lib.samp.events"
            color_sampev = ""
        end
    )
 then
    function sampev.onCreateGangZone(zoneId, squareStart, squareEnd, color)
        if color == -1442840576 then
            gz_id = zoneId
            gz_squareStart = squareStart
            gz_squareEnd = squareEnd
        end
    end

    function sampev.onGangZoneDestroy(zoneId)
        if gz_id == zoneId then
            gz_squareStart = {}
            gz_squareEnd = {}
            gz_id = -1
        end
    end

    function sampev.onServerMessage(color, text)
        local car_to_steal = string.match(text, " Пригони нам тачку марки (.+), и мы тебе хорошо заплатим.")

        if settings.transponder.catch_srp_start and car_to_steal then
            if cars[string.lower(car_to_steal)] ~= nil then
                request_model = cars[string.lower(car_to_steal)]
                addOneOffSound(0.0, 0.0, 0.0, 1139)
            else
                request_model = -1
                addOneOffSound(0.0, 0.0, 0.0, 1057)
            end
        end

        if settings.transponder.catch_srp_stop then
            if
                text == " SMS: Ты меня огорчил!" or
                    text == " SMS: Слишком долго. Нам нужны хорошие автоугонщики, а не черепахи" or
                    text == " Отличная тачка. Будет нужна работа, приходи."
             then
                request_model = -1
                addOneOffSound(0.0, 0.0, 0.0, 1057)
            end
        end

        if text == " SMS: Это то что нам нужно, гони её на склад." then
            request_model_last = request_model
            request_model = -1
            if settings.handler.clear_mark and marker_placed then
                removeWaypoint()
            end
        end

        if text == " SMS: Как ты умудрился потерять эту машину?! Ищи новую!" then
            if request_model == -1 then
                request_model = request_model_last
            end
        end
    end
else
    color_sampev = "{FF0000}"
    no_sampev = true
end

--------------------------------------------------------------------------------
-------------------------------------MENU---------------------------------------
--------------------------------------------------------------------------------
function updateMenu()
    mod_submenus_sa = {
        {
            title = "Информация о скрипте",
            onclick = function()
                sampShowDialog(
                    0,
                    "{7ef3fa}/locator v." .. thisScript().version .. " - информация",
                    "{00ff66}Locator{ffffff}\n{ffffff}На многих РП серверах есть гринд миссии по угону машин на юга.\n\nЦель скрипта: построить сообщество угонщиков и упростить поиск машин.\n\nЮзеры скрипта передают на сервер инфу о всех машинах (кроме той в которой сидят).\nКогда вам это нужно, вы сможете запрашивать координаты нужной вам машины.\nЧем больше людей пользуются скриптом, тем он больше его польза.\n\nИспользования скрипта бесплатно, код открыт, сервер оплачивается донатами.\n\nРезультат можно увидеть в диалоговом окне, можно поставить метку на самый подходящий вариант.\n\nТак же наглядно увидеть на fastmap: L-ALT + Ь(M), а так же на zoommap L-ALT + Б(,).\nНа первой внизу есть статусбар, а на второй стрелками можно перемещаться по карте.\nНа второй можно изменить режим на квадраты, нажав K (когда активен zoommap).\nЗеленый цвет - закрытая машина, серый - открытая, красный - занятая.\n\nОбязательно загляните в настройки, там много чего полезного.\n\n{ffcc00}Доступные команды:\n{00ccff}/locator{ffffff} - меню скрипта.\n{00ccff}/locate [название] {ffffff}- выбор цели. Без [название] = сброс.\n{00ccff}/locatelist {ffffff}- диалог выбора машины.\n{00ccff}/ugon {ffffff}- отчёт о поиске, ставит метку на самый подходящий вариант.",
                    "Окей"
                )
            end
        },
        {
            title = " "
        },
        {
            title = "{AAAAAA}Функции"
        },
        {
            title = "Выбрать машину для поиска",
            onclick = function()
                submenus_show(
                    select_car_dialog,
                    "{348cb2}locator v." .. thisScript().version,
                    "Выбрать",
                    "Закрыть",
                    "Назад"
                )
            end
        },
        {
            title = "Отчёт о поиске",
            onclick = function()
                lua_thread.create(legacy_edith_front)
            end
        },
        {
            title = " "
        },
        {
            title = "{00ff66}Настройки",
            submenu = {
                {
                    title = "{AAAAAA}Настройки скрипта"
                },
                {
                    title = "Вкл/выкл автообновление: " .. tostring(settings.locator.autoupdate),
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
                },
                {
                    title = " "
                },
                {
                    title = "{AAAAAA}Настройки интеграций с проектами"
                },
                {
                    title = color_sampev ..
                        "[SRP | SAMP.Lua]: Ловить начало угона и автоматом запрашивать машину: " ..
                            tostring(settings.transponder.catch_srp_start),
                    onclick = function()
                        settings.transponder.catch_srp_start = not settings.transponder.catch_srp_start
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = color_sampev ..
                        "[SRP | SAMP.Lua]: Ловить конец угона и автоматом отменять запрос: " ..
                            tostring(settings.transponder.catch_srp_stop),
                    onclick = function()
                        settings.transponder.catch_srp_stop = not settings.transponder.catch_srp_stop
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = color_sampev ..
                        "[SRP | SAMP.Lua]: Ловить черный квадрат где 'наши парни видели': " ..
                            tostring(settings.transponder.catch_srp_gz),
                    onclick = function()
                        settings.transponder.catch_srp_gz = not settings.transponder.catch_srp_gz
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = " "
                },
                {
                    title = "{AAAAAA}Настройки запроса"
                },
                {
                    title = "Запрашивать занятые автомобили: " .. tostring(settings.transponder.allow_occupied),
                    onclick = function()
                        settings.transponder.allow_occupied = not settings.transponder.allow_occupied
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = "Запрашивать открытые автомобили (фильтр на т/с фракций): " ..
                        tostring(settings.transponder.allow_unlocked),
                    onclick = function()
                        settings.transponder.allow_unlocked = not settings.transponder.allow_unlocked
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = "Задержка между запросами: " .. tostring(settings.transponder.delay) .. " мс",
                    submenu = {
                        {
                            title = "999 мс",
                            onclick = function()
                                settings.transponder.delay = 999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "1999 мс",
                            onclick = function()
                                settings.transponder.delay = 1999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "2999 мс",
                            onclick = function()
                                settings.transponder.delay = 2999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "3999 мс",
                            onclick = function()
                                settings.transponder.delay = 3999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "4999 мс",
                            onclick = function()
                                settings.transponder.delay = 4999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "5999 мс",
                            onclick = function()
                                settings.transponder.delay = 5999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "6999 мс",
                            onclick = function()
                                settings.transponder.delay = 6999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "7999 мс",
                            onclick = function()
                                settings.transponder.delay = 7999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "8999 мс",
                            onclick = function()
                                settings.transponder.delay = 8999
                                inicfg.save(settings, "locator")
                            end
                        },
                        {
                            title = "9999 мс",
                            onclick = function()
                                settings.transponder.delay = 9999
                                inicfg.save(settings, "locator")
                            end
                        }
                    }
                },
                {
                    title = " "
                },
                {
                    title = "{AAAAAA}Настройки обработки ответа"
                },
                {
                    title = "Отмечать маркером самую лучший вариант для угона: " ..
                        tostring(settings.handler.mark_coolest),
                    onclick = function()
                        settings.handler.mark_coolest = not settings.handler.mark_coolest
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = "Отмечать звуком, когда маркер ставится по новым координатам: " ..
                        tostring(settings.handler.mark_coolest_sound),
                    onclick = function()
                        settings.handler.mark_coolest_sound = not settings.handler.mark_coolest_sound
                        inicfg.save(settings, "locator")
                    end
                },
                {
                    title = "Убирать поставленный скриптом маркер когда это необходимо: " ..
                        tostring(settings.handler.clear_mark),
                    onclick = function()
                        settings.handler.clear_mark = not settings.handler.clear_mark
                        inicfg.save(settings, "locator")
                    end
                }
            }
        },
        {
            title = " "
        },
        {
            title = "{AAAAAA}Донат"
        },
        {
            title = "Донат на сервер",
            onclick = function()
                os.execute('explorer "http://qrlk.me/donatelocator"')
            end
        },
        {
            title = " "
        },
        {
            title = "{AAAAAA}Ссылки"
        },
        {
            title = "Github",
            onclick = function()
                os.execute('explorer "http://github.com/qrlk/locator"')
            end
        },
        {
            title = "Сайт автора",
            onclick = function()
                os.execute('explorer "http://qrlk.me/"')
            end
        },
        {
            title = "Подписывайтесь на группу ВКонтакте!",
            onclick = function()
                os.execute('explorer "http://qrlk.me/sampvk"')
            end
        }
    }
end
--------------------------------------------------------------------------------
------------------------------------LEGACY--------------------------------------
--------------------------------------------------------------------------------
function legacy_edith_front()
    local x, y = getCharCoordinates(playerPed)
    local str = "{00ff66}Без водителя:{ffffff}\n"
    local first = false
    table.sort(vhinfo, sort)
    for k, v in pairs(vhinfo) do
        if v["occupied"] == false then
            if not first then
                str = str .. "{7ef3fa}"
                placeWaypoint(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"])
                marker_placed = true
            end
            str =
                str ..
                "* " ..
                    kvadrat1(v["pos"]["x"], v["pos"]["y"]) ..
                        " || Расстояние: " ..
                            math.floor(getDistanceBetweenCoords2d(x, y, v["pos"]["x"], v["pos"]["y"])) ..
                                "m  || " ..
                                    carsids[v["model"]] ..
                                        " || " ..
                                            v["health"] ..
                                                " hp. Занята: " ..
                                                    toanime(v["occupied"]) ..
                                                        ". X: " ..
                                                            math.floor(v["pos"]["x"]) ..
                                                                ". Y:" ..
                                                                    math.floor(v["pos"]["y"]) ..
                                                                        ". Z:" ..
                                                                            math.floor(v["pos"]["z"]) ..
                                                                                ". Видели: " ..
                                                                                    tostring(
                                                                                        math.floor(
                                                                                            response_timestamp -
                                                                                                v["timestamp"]
                                                                                        )
                                                                                    ) ..
                                                                                        " сек назад\n"
            if not first then
                str = str .. "{ffffff}"
                first = true
            end
        end
    end

    str = str .. "\n{00ff66}С водителем:{ffffff}\n"
    for k, v in pairs(vhinfo) do
        if v["occupied"] == true then
            if not first then
                str = str .. "{7ef3fa}"
                placeWaypoint(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"])
                marker_placed = true
            end
            str =
                str ..
                "* " ..
                    kvadrat1(v["pos"]["x"], v["pos"]["y"]) ..
                        " || Расстояние: " ..
                            math.floor(getDistanceBetweenCoords2d(x, y, v["pos"]["x"], v["pos"]["y"])) ..
                                "m  || " ..
                                    carsids[v["model"]] ..
                                        " || " ..
                                            v["health"] ..
                                                " hp. Занята: " ..
                                                    toanime(v["occupied"]) ..
                                                        ". X: " ..
                                                            math.floor(v["pos"]["x"]) ..
                                                                ". Y:" ..
                                                                    math.floor(v["pos"]["y"]) ..
                                                                        ". Z:" ..
                                                                            math.floor(v["pos"]["z"]) ..
                                                                                ". Видели: " ..
                                                                                    tostring(
                                                                                        math.floor(
                                                                                            response_timestamp -
                                                                                                v["timestamp"]
                                                                                        )
                                                                                    ) ..
                                                                                        " сек назад\n"
            if not first then
                str = str .. "{ffffff}"
                first = true
            end
        end
    end
    if first then
        str = str .. "\n\n{e5ff00}Выделенная машина отмечена на карте меткой (waypoint).{ffffff}"
    end
    sampShowDialog(9123, "LOCATOR: отчёт о поиске " .. tostring(carsids[request_model]), str, "Ясно")
end

marker_last_x = 0
marker_last_y = 0

function mark_coolest_car()
    local x, y = getCharCoordinates(playerPed)
    local first = false
    table.sort(vhinfo, sort)
    for k, v in pairs(vhinfo) do
        if v["occupied"] == false then
            if not first then
                placeWaypoint(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"])
                marker_placed = true
                if v["pos"]["x"] ~= marker_last_x or v["pos"]["y"] ~= marker_last_y then
                    if settings.handler.mark_coolest_sound then
                        addOneOffSound(0.0, 0.0, 0.0, 1139)
                    end
                end
                marker_last_x = v["pos"]["x"]
                marker_last_y = v["pos"]["y"]
            end

            if not first then
                first = true
            end
        end
    end

    for k, v in pairs(vhinfo) do
        if v["occupied"] == true then
            if not first then
                placeWaypoint(v["pos"]["x"], v["pos"]["y"], v["pos"]["z"])
                marker_placed = true
                if v["pos"]["x"] ~= marker_last_x or v["pos"]["y"] ~= marker_last_y then
                    if settings.handler.mark_coolest_sound then
                        addOneOffSound(0.0, 0.0, 0.0, 1139)
                    end
                end
                marker_last_x = v["pos"]["x"]
                marker_last_y = v["pos"]["y"]
            end

            if not first then
                first = true
            end
        end
    end
end

function toanime(bool)
    if bool then
        return "аниме"
    else
        return "не аниме"
    end
end

function kvadrat1(X, Y)
    local KV = {
        [1] = "А",
        [2] = "Б",
        [3] = "В",
        [4] = "Г",
        [5] = "Д",
        [6] = "Ж",
        [7] = "З",
        [8] = "И",
        [9] = "К",
        [10] = "Л",
        [11] = "М",
        [12] = "Н",
        [13] = "О",
        [14] = "П",
        [15] = "Р",
        [16] = "С",
        [17] = "Т",
        [18] = "У",
        [19] = "Ф",
        [20] = "Х",
        [21] = "Ц",
        [22] = "Ч",
        [23] = "Ш",
        [24] = "Я"
    }
    X = math.ceil((X + 3000) / 250)
    if X < 10 then
        X = "0" .. tostring(X)
    end
    Y = math.ceil((Y * -1 + 3000) / 250)
    Y = KV[Y]
    local KVX = (Y .. "-" .. X)
    return KVX
end

carsids = {
    [-1] = "Не задана",
    [400] = "Landstalker",
    [401] = "Bravura",
    [402] = "Buffalo",
    [403] = "Linerunner",
    [404] = "Perenniel",
    [405] = "Sentinel",
    [406] = "Dumper",
    [407] = "Firetruck",
    [408] = "Trashmaster",
    [409] = "Stretch",
    [410] = "Manana",
    [411] = "Infernus",
    [412] = "Voodoo",
    [413] = "Pony",
    [414] = "Mule",
    [415] = "Cheetah",
    [416] = "Ambulance",
    [417] = "Leviathan",
    [418] = "Moonbeam",
    [419] = "Esperanto",
    [420] = "Taxi",
    [421] = "Washington",
    [422] = "Bobcat",
    [423] = "Mr Whoopee",
    [424] = "BF Injection",
    [425] = "Hunter",
    [426] = "Premier",
    [427] = "Enforcer",
    [428] = "Securicar",
    [429] = "Banshee",
    [430] = "Predator",
    [431] = "Bus",
    [432] = "Rhino",
    [433] = "Barracks",
    [434] = "Hotknife",
    [435] = "Article Trailer",
    [436] = "Previon",
    [437] = "Coach",
    [438] = "Cabbie",
    [439] = "Stallion",
    [440] = "Rumpo",
    [441] = "RC Bandit",
    [442] = "Romero",
    [443] = "Packer",
    [444] = "Monster",
    [445] = "Admiral",
    [446] = "Squallo",
    [447] = "Seasparrow",
    [448] = "Pizzaboy",
    [449] = "Tram",
    [450] = "Article Trailer 2",
    [451] = "Turismo",
    [452] = "Speeder",
    [453] = "Reefer",
    [454] = "Tropic",
    [455] = "Flatbed",
    [456] = "Yankee",
    [457] = "Caddy",
    [458] = "Solair",
    [459] = "Topfun Van",
    [460] = "Skimmer",
    [461] = "PCJ-600",
    [462] = "Faggio",
    [463] = "Freeway",
    [464] = "RC Baron",
    [465] = "RC Raider",
    [466] = "Glendale",
    [467] = "Oceanic",
    [468] = "Sanchez",
    [469] = "Sparrow",
    [470] = "Patriot",
    [471] = "Quad",
    [472] = "Coastguard",
    [473] = "Dinghy",
    [474] = "Hermes",
    [475] = "Sabre",
    [476] = "Rustler",
    [477] = "ZR-350",
    [478] = "Walton",
    [479] = "Regina",
    [480] = "Comet",
    [481] = "BMX",
    [482] = "Burrito",
    [483] = "Camper",
    [484] = "Marquis",
    [485] = "Baggage",
    [486] = "Dozer",
    [487] = "Maverick",
    [488] = "SAN News Maverick",
    [489] = "Rancher",
    [490] = "FBI Rancher",
    [491] = "Virgo",
    [492] = "Greenwood",
    [493] = "Jetmax",
    [494] = "Hotring Racer C",
    [495] = "Sandking",
    [496] = "Blista Compact",
    [497] = "Police Maverick",
    [498] = "Boxville",
    [499] = "Benson",
    [500] = "Mesa",
    [501] = "RC Goblin",
    [502] = "Hotring Racer A",
    [503] = "Hotring Racer B",
    [504] = "Bloodring Banger",
    [505] = "Rancher",
    [506] = "Super GT",
    [507] = "Elegant",
    [508] = "Journey",
    [509] = "Bike",
    [510] = "Mountain Bike",
    [511] = "Beagle",
    [512] = "Cropduster",
    [513] = "Stuntplane",
    [514] = "Tanker",
    [515] = "Roadtrain",
    [516] = "Nebula",
    [517] = "Majestic",
    [518] = "Buccaneer",
    [519] = "Shamal",
    [520] = "Hydra",
    [521] = "FCR-900",
    [522] = "NRG-500",
    [523] = "HPV1000",
    [524] = "Cement Truck",
    [525] = "Towtruck",
    [526] = "Fortune",
    [527] = "Cadrona",
    [528] = "FBI Truck",
    [529] = "Willard",
    [530] = "Forklift",
    [531] = "Tractor",
    [532] = "Combine Harvester",
    [533] = "Feltzer",
    [534] = "Remington",
    [535] = "Slamvan",
    [536] = "Blade",
    [537] = "Freight (Train)",
    [538] = "Brownstreak (Train)",
    [539] = "Vortex",
    [540] = "Vincent",
    [541] = "Bullet",
    [542] = "Clover",
    [543] = "Sadler",
    [544] = "Firetruck LA",
    [545] = "Hustler",
    [546] = "Intruder",
    [547] = "Primo",
    [548] = "Cargobob",
    [549] = "Tampa",
    [550] = "Sunrise",
    [551] = "Merit",
    [552] = "Utility Van",
    [553] = "Nevada",
    [554] = "Yosemite",
    [555] = "Windsor",
    [556] = "Monster A",
    [557] = "Monster B",
    [558] = "Uranus",
    [559] = "Jester",
    [560] = "Sultan",
    [561] = "Stratum",
    [562] = "Elegy",
    [563] = "Raindance",
    [564] = "RC Tiger",
    [565] = "Flash",
    [566] = "Tahoma",
    [567] = "Savanna",
    [568] = "Bandito",
    [569] = "Freight Flat Trailer (Train)",
    [570] = "Streak Trailer (Train)",
    [571] = "Kart",
    [572] = "Mower",
    [573] = "Dune",
    [574] = "Sweeper",
    [575] = "Broadway",
    [576] = "Tornado",
    [577] = "AT400",
    [578] = "DFT-30",
    [579] = "Huntley",
    [580] = "Stafford",
    [581] = "BF-400",
    [582] = "Newsvan",
    [583] = "Tug",
    [584] = "Petrol Trailer",
    [585] = "Emperor",
    [586] = "Wayfarer",
    [587] = "Euros",
    [588] = "Hotdog",
    [589] = "Club",
    [590] = "Freight Box Trailer (Train)",
    [591] = "Article Trailer 3",
    [592] = "Andromada",
    [593] = "Dodo",
    [594] = "RC Cam",
    [595] = "Launch",
    [596] = "Police Car (LSPD)",
    [597] = "Police Car (SFPD)",
    [598] = "Police Car (LVPD)",
    [599] = "Police Ranger",
    [600] = "Picador",
    [601] = "S.W.A.T.",
    [602] = "Alpha",
    [603] = "Phoenix",
    [604] = "Glendale Shit",
    [605] = "Sadler Shit",
    [606] = "Baggage Trailer A",
    [607] = "Baggage Trailer B",
    [608] = "Tug Stairs Trailer",
    [609] = "Boxville",
    [610] = "Farm Trailer"
}

function sort(a, b)
    local x, y = getCharCoordinates(playerPed)
    getDistanceBetweenCoords2d(x, y, a["pos"]["x"], a["pos"]["y"])
    return getDistanceBetweenCoords2d(x, y, a["pos"]["x"], a["pos"]["y"]) <
        getDistanceBetweenCoords2d(x, y, b["pos"]["x"], b["pos"]["y"])
end
--------------------------------------------------------------------------------
--------------------------------------GMAP--------------------------------------
--------------------------------------------------------------------------------
active = false
mapmode = 1
modX = 2
modY = 2

function dn(nam)
    file = getGameDirectory() .. "\\moonloader\\resource\\locator\\" .. nam
    if not doesFileExist(file) then
        downloadUrlToFile("https://raw.githubusercontent.com/qrlk/locator/master/resource/locator/" .. nam, file)
    end
end

function init()
    if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource") then
        createDirectory(getGameDirectory() .. "\\moonloader\\resource")
    end
    if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource\\locator") then
        createDirectory(getGameDirectory() .. "\\moonloader\\resource\\locator")
    end
    dn("waypoint.png")
    dn("matavoz.png")
    dn("pla.png")

    for i = 1, 16 do
        dn(i .. ".png")
        dn(i .. "k.png")
    end

    player = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/pla.png")
    matavoz = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/matavoz.png")
    font = renderCreateFont("Impact", 8, 4)
    font10 = renderCreateFont("Impact", 10, 4)
    font12 = renderCreateFont("Impact", 12, 4)

    resX, resY = getScreenResolution()
    m1 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/1.png")
    m2 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/2.png")
    m3 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/3.png")
    m4 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/4.png")
    m5 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/5.png")
    m6 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/6.png")
    m7 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/7.png")
    m8 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/8.png")
    m9 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/9.png")
    m10 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/10.png")
    m11 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/11.png")
    m12 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/12.png")
    m13 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/13.png")
    m14 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/14.png")
    m15 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/15.png")
    m16 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/16.png")
    m1k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/1k.png")
    m2k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/2k.png")
    m3k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/3k.png")
    m4k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/4k.png")
    m5k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/5k.png")
    m6k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/6k.png")
    m7k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/7k.png")
    m8k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/8k.png")
    m9k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/9k.png")
    m10k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/10k.png")
    m11k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/11k.png")
    m12k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/12k.png")
    m13k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/13k.png")
    m14k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/14k.png")
    m15k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/15k.png")
    m16k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/locator/16k.png")
    if resX > 1024 and resY >= 1024 then
        bX = (resX - 1024) / 2
        bY = (resY - 1024) / 2
        size = 1024
    elseif resX > 720 and resY >= 720 then
        bX = (resX - 720) / 2
        bY = (resY - 720) / 2
        size = 720
    else
        bX = (resX - 512) / 2
        bY = (resY - 512) / 2
        size = 512
    end
end

function fastmap()
    if not sampIsChatInputActive() and isKeyDown(0xA4) then
        while isKeyDown(77) or isKeyDown(188) do
            wait(0)

            x, y = getCharCoordinates(playerPed)
            if not sampIsChatInputActive() and wasKeyPressed(0x4B) then
                settings.map.sqr = not settings.map.sqr
                inicfg.save(settings, "locator")
            end
            if isKeyDown(77) then
                mapmode = 0
            elseif isKeyDown(188) or mapmode ~= 0 then
                mapmode = getMode(modX, modY)
                if wasKeyPressed(0x25) then
                    if modY > 1 then
                        modY = modY - 1
                    end
                elseif wasKeyPressed(0x27) then
                    if modY < 3 then
                        modY = modY + 1
                    end
                elseif wasKeyPressed(0x26) then
                    if modX < 3 then
                        modX = modX + 1
                    end
                elseif wasKeyPressed(0x28) then
                    if modX > 1 then
                        modX = modX - 1
                    end
                end
            end
            if mapmode == 0 or mapmode == -1 then
                renderDrawTexture(m1, bX, bY, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m2, bX + size / 4, bY, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m3, bX + 2 * (size / 4), bY, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m4, bX + 3 * (size / 4), bY, size / 4, size / 4, 0, 0xFFFFFFFF)

                renderDrawTexture(m5, bX, bY + size / 4, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m6, bX + size / 4, bY + size / 4, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m7, bX + 2 * (size / 4), bY + size / 4, size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m8, bX + 3 * (size / 4), bY + size / 4, size / 4, size / 4, 0, 0xFFFFFFFF)

                renderDrawTexture(m9, bX, bY + 2 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m10, bX + size / 4, bY + 2 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m11, bX + 2 * (size / 4), bY + 2 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m12, bX + 3 * (size / 4), bY + 2 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)

                renderDrawTexture(m13, bX, bY + 3 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m14, bX + size / 4, bY + 3 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m15, bX + 2 * (size / 4), bY + 3 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawTexture(m16, bX + 3 * (size / 4), bY + 3 * (size / 4), size / 4, size / 4, 0, 0xFFFFFFFF)
                renderDrawBoxWithBorder(bX, bY + size - size / 42, size, size / 42, -1, 2, -2)

                renderFontDrawText(
                    font10,
                    string.format(
                        "UPD: %s || Текущая цель: %s   Найдено: %s   Активных источников: %s   Машин в базе: %s",
                        count_next(),
                        carsids[request_model],
                        #vhinfo,
                        ser_active,
                        ser_count
                    ),
                    bX,
                    bY + size - size / 45,
                    0xFF00FF00
                )

                if size == 1024 then
                    iconsize = 16
                end
                if size == 720 then
                    iconsize = 12
                end
                if size == 512 then
                    iconsize = 10
                end
            else
                if size == 1024 then
                    iconsize = 32
                end
                if size == 720 then
                    iconsize = 24
                end
                if size == 512 then
                    iconsize = 16
                end
            end
            if mapmode == 1 then
                if settings.map.sqr then
                    renderDrawTexture(m9k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m13k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m14k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m9, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m13, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m14, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 2 then
                if settings.map.sqr then
                    renderDrawTexture(m10k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m14k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m15k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m10, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m14, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m15, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 3 then
                if settings.map.sqr then
                    renderDrawTexture(m11k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m12k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m15k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m16k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m11, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m12, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m15, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m16, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 4 then
                if settings.map.sqr then
                    renderDrawTexture(m5k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m9k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m5, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m9, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 5 then
                if settings.map.sqr then
                    renderDrawTexture(m6k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m6, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m10, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 6 then
                if settings.map.sqr then
                    renderDrawTexture(m7k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m8k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m12k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m7, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m8, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m11, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m12, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 7 then
                if settings.map.sqr then
                    renderDrawTexture(m1k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m2k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m5k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m1, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m2, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m5, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 8 then
                if settings.map.sqr then
                    renderDrawTexture(m2k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m3k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m2, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m3, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m6, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            if mapmode == 9 then
                if settings.map.sqr then
                    renderDrawTexture(m3k, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m4k, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7k, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m8k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                else
                    renderDrawTexture(m3, bX, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m4, bX + size / 2, bY, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m7, bX, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                    renderDrawTexture(m8, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, 0xFFFFFFFF)
                end
            end
            --renderDrawTexture(matavoz, getX(0), getY(0), 16, 16, 0, - 1)
            if getQ(x, y, mapmode) or mapmode == 0 then
                renderDrawTexture(player, getX(x), getY(y), iconsize, iconsize, -getCharHeading(playerPed), -1)
            end
            if settings.transponder.catch_srp_gz and (getQ(gz_squareStart["x"], gz_squareEnd["y"], mapmode) or mapmode == 0) then
                if gz_squareStart["x"] ~= nil and gz_squareEnd["y"] ~= nil then
                    renderDrawBox(
                        getX(gz_squareStart["x"]) + iconsize / 2,
                        getY(gz_squareEnd["y"]) + iconsize / 2,
                        getX(gz_squareEnd["x"]) - getX(gz_squareStart["x"]),
                        getY(gz_squareStart["y"]) - getY(gz_squareEnd["y"]),
                        0x80FFFFFF
                    )
                end
            end

            for z, v1 in pairs(vhinfo) do
                if getQ(v1["pos"]["x"], v1["pos"]["y"], mapmode) or mapmode == 0 then
                    if v1["locked"] == 2 then
                        color = 0xFF00FF00
                    else
                        color = 0xFFdedbd2
                    end

                    if v1["occupied"] then
                        color = 0xFFFF0000
                    end

                    if response_timestamp - v1["timestamp"] > 2 then
                        if mapmode == 0 then
                            renderFontDrawText(
                                font,
                                string.format("%.0f?", response_timestamp - v1["timestamp"]),
                                getX(v1["pos"]["x"]) + 17,
                                getY(v1["pos"]["y"]) + 2,
                                color
                            )
                        else
                            renderFontDrawText(
                                font12,
                                string.format("%.0f?", response_timestamp - v1["timestamp"]),
                                getX(v1["pos"]["x"]) + 31,
                                getY(v1["pos"]["y"]) + 4,
                                color
                            )
                        end
                    end
                    if v1["health"] ~= nil then
                        if mapmode == 0 then
                            renderFontDrawText(
                                font,
                                v1["health"] .. " dl",
                                getX(v1["pos"]["x"]) - 30,
                                getY(v1["pos"]["y"]) + 2,
                                color
                            )
                        else
                            renderFontDrawText(
                                font12,
                                v1["health"] .. " dl",
                                getX(v1["pos"]["x"]) - string.len(v1["health"] .. " dl") * 9.4,
                                getY(v1["pos"]["y"]) + 4,
                                color
                            )
                        end
                    end
                    renderDrawTexture(
                        matavoz,
                        getX(v1["pos"]["x"]),
                        getY(v1["pos"]["y"]),
                        iconsize,
                        iconsize,
                        -v1["heading"] + 90,
                        -1
                    )
                end
            end
        end
    end
end

function getMode(x, y)
    if x == 1 then
        if y == 1 then
            return 1
        end
        if y == 2 then
            return 2
        end
        if y == 3 then
            return 3
        end
    end
    if x == 2 then
        if y == 1 then
            return 4
        end
        if y == 2 then
            return 5
        end
        if y == 3 then
            return 6
        end
    end
    if x == 3 then
        if y == 1 then
            return 7
        end
        if y == 2 then
            return 8
        end
        if y == 3 then
            return 9
        end
    end
end

function getQ(x, y, mp)
    if mp == 1 then
        if x <= 0 and y <= 0 then
            return true
        end
    end
    if mp == 2 then
        if x >= -1500 and x <= 1500 and y <= 0 then
            return true
        end
    end
    if mp == 3 then
        if x >= 0 and y <= 0 then
            return true
        end
    end
    if mp == 4 then
        if x <= 0 and y >= -1500 and y <= 1500 then
            return true
        end
    end
    if mp == 5 then
        if x >= -1500 and x <= 1500 and y >= -1500 and y <= 1500 then
            return true
        end
    end

    if mp == 6 then
        if x >= 0 and y >= -1500 and y <= 1500 then
            return true
        end
    end

    if mp == 7 then
        if x <= 0 and y >= 0 then
            return true
        end
    end
    if mp == 8 then
        if x >= -1500 and x <= 1500 and y >= 0 then
            return true
        end
    end
    if mp == 9 then
        if x >= 0 and y >= 0 then
            return true
        end
    end
    return false
end

function getX(x)
    if mapmode == 0 then
        x = math.floor(x + 3000)
        return bX + x * (size / 6000) - iconsize / 2
    end
    if mapmode == 3 or mapmode == 9 or mapmode == 6 then
        return bX - iconsize / 2 + math.floor(x) * (size / 3000)
    end
    if mapmode == 1 or mapmode == 7 or mapmode == 4 then
        return bX - iconsize / 2 + math.floor(x + 3000) * (size / 3000)
    end
    if mapmode == 2 or mapmode == 8 or mapmode == 5 then
        return bX - iconsize / 2 + math.floor(x + 1500) * (size / 3000)
    end
end

function getY(y)
    if mapmode == 0 then
        y = math.floor(y * -1 + 3000)
        return bY + y * (size / 6000) - iconsize / 2
    end
    if mapmode == 7 or mapmode == 9 or mapmode == 8 then
        return bY + size - iconsize / 2 - math.floor(y) * (size / 3000)
    end
    if mapmode == 1 or mapmode == 3 or mapmode == 2 then
        return bY + size - iconsize / 2 - math.floor(y + 3000) * (size / 3000)
    end
    if mapmode == 4 or mapmode == 5 or mapmode == 6 then
        return bY + size - iconsize / 2 - math.floor(y + 1500) * (size / 3000)
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
