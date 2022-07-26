VarLoader = require('VariableLoader')

PupLoader = require('PowerupLoader')

ConfigLoader = require('ConfigurationLoader')

modbus_event_functions = require('modbusdata')

json = require('json')

sned_event = require('modbus_event')

time = require('timer')

gBackendChannel = 'BrixChannelOut'

local gTargetFirmware
local gTargetSerial
local gTargetStore_ID
local gTargetBOM
local gTargetDevice_Conditions
local gDateTme
local gDateTimeR
local gTargetuvcVersion
local triggerB1Defrost = false
local triggerB2Defrost = false
local triggerB3Defrost = false
local triggerB4Defrost = false
local cBarrelNumber
local cBarrelStatus
local cBarrelMode

-- Erro info
local gModbusTotalError = 0
local gModbusWriteError = 0
local gModbusReadError = 0
local gModbusContinueCount = 0
local gModbusStatus = 0
local gInitData = 1

--- @param gre#context mapargs
function CBInit(mapargs)

    -- When power up need load saved powerup.csv file to setup UI
    -- All thw values save to powerup[], powerup[] defined in modbusdata.lua
    -- See powerup.csv for details
    local attrs = {}
    local powerup_attrs = {}
    powerup_attrs.textDB = gre.APP_ROOT .. '/configurations/powerup.csv'

    print('****************** BRIX UI ***************************')
    print(data_app['uiversion'])

    PowerUp = PupLoader.CreateLoader(powerup_attrs)

    -- English is the application's base design language so we don't have
    -- to perform any loading initially. If we start with a different language
    -- then we should use loadOnInit to set those initial values.
    if (powerup[1] == 1) then
        attrs.language = 'english'
    elseif (powerup[1] == 2) then
        attrs.language = 'german'
    elseif (powerup[1] == 3) then
        attrs.language = 'french'
    elseif (powerup[1] == 4) then
        attrs.language = 'spanish'
    elseif (powerup[1] == 5) then
        attrs.language = 'danish'
    elseif (powerup[1] == 6) then
        attrs.language = 'swedish'
    elseif (powerup[1] == 7) then
        attrs.language = 'dutch'
    elseif (powerup[1] == 8) then
        attrs.language = 'italian'
    elseif (powerup[1] == 9) then
        attrs.language = 'portuguese'
    elseif (powerup[1] == 10) then
        attrs.language = 'polish'
    elseif (powerup[1] == 11) then
        attrs.language = 'russian'
    elseif (powerup[1] == 12) then
        attrs.language = 'japanese'
    elseif (powerup[1] == 13) then
        attrs.language = 'simplified_chinese'
    else
        attrs.language = 'english'
    end

    attrs.language = 'english'
    -- attrs.loadOnInit = true
    local config_attrs = {}

    -- print('CBInit')

    attrs.textDB = gre.APP_ROOT .. '/translations/translations.csv'
    attrs.attributeDB = gre.APP_ROOT .. '/translations/attribute_db.csv'

    Translation = VarLoader.CreateLoader(attrs)

    config_attrs.textDB = gre.APP_ROOT .. '/configurations/configurations.csv'
    -- attrs.attributeDB = gre.APP_ROOT .. '/translations/attribute_db.csv'

    Configuration = ConfigLoader.CreateLoader(config_attrs)
end

--- @param gre#context mapargs
function CBLoadLanguage(mapargs)
    loaded = Translation:setLanguage(mapargs.language)
end

function echo(string)
    print(string)
    os.execute('echo ' .. string .. '>/dev/ttySC0')
end

-- function gre_event_test()
--    while (1) do
--    local ev = gre.receive_event('BrixChannelIn')
--        echo(ev.name)
--    end
-- end

function AppStart(mpargs)
    os.execute('sleep 5')

    os.execute('ifconfig eth0 192.168.1.222 netmask 255.255.255.0')
    gre.timer_set_interval(clock,1000)

    --        print(_VERSION)

    local dk_data = {}

    -- print('App Start')

    -- Set all the defaults from hardcoded values
    InitValues(mpargs)

    -- Get the values of locally saved variabes from the powerup.csv file
    PowerupValue()
    updateTime()
    -- Timer to update time and date on screen
    callback_register('updateTime', updateTime, 1) -- miliseconds - every half second

    -- Trigger the power saver on off animation based on the saved values so it is correct on the screen
    power_save_anim_init()

    -- Timer to check the defrost times
    --  callback_register('defrostCheck',defrostCheck, 60) -- miliseconds - every minute -
    -- we can not allow this to trigger less ore more than once a minute but it must trigger every minute

    -- Timer to check beep status
    callback_register('beepSilenceCheck', beepSilenceCheck, 60) -- miliseconds - every minute - 

    -- Set initial values into the UI controls
    DispayCurrentStandbyTemp();
    DisplayPowerSaver()
    DisplayCompressorTimes()

    -- Get the UVC4 version
    --  idval_str = callback_register('RequestVersion',RequestVersion, 2)

    -- This call puts the BOM, SN, Model, UVC4 Version, Store Id into the UI elements
    SetSystemInfo()

    -- Get the brix_backend version
    if (is_dev == 0) then
        idval_bac = callback_register('RequestBrixBackendVersion', RequestBrixBackendVersion, 1)
    end

    -- Get the voltage
    idval_vol = callback_register('RequestVoltage', RequestVoltage, 1)

    -- If this is a development install, auto close the init screen so the UI does not get stuck there
    -- print(is_dev)
    if is_dev ~= 0 then
        print('init dev')
        idval_init = callback_register('initEndTest', initEndTest, 4)
    end

    --  test_json=io.open('config.json','r')
    --  io.input(test_json)
    --  string_json=io.read('*all')
    --  io.close(test_json)
    --  print(string_json)

    --  test_json_table=json.parse(string_json)
    --  test_json_table.language = '1'

    --  new_test_json_table=json.stringify(test_json_table)
    --  config_file=io.open('config.json','w')
    --  io.output(config_file)
    --  io.write(new_test_json_table)
    --  io.close(config_file)

    --  print(test_json_table.language)

    --    gre.thread_create(gre_event_test)

    ---- fifo is too slow

    --    gre.thread_create(fifo_read)

    --  callback_register('echo', echo, 1, '1 s test')
    callback_register('modbus_send_40003', modbus_send, 1, 40003)-- homescreen info
    callback_register('modbus_send_40004', modbus_send, 2, 40004)-- dont change the time of 40003-4000
    callback_register('modbus_send_40005', modbus_send, 2, 40005)
    callback_register('modbus_send_40006', modbus_send, 4, 40006,4)

    callback_register('modbus_send_40051', modbus_send, 3, 40051, 5)--backend info like serial number and such things
    callback_register('modbus_send_40056', modbus_send, 3, 40056, 7)
    callback_register('modbus_send_40063', modbus_send, 3, 40063, 5)
    callback_register('modbus_send_40068', modbus_send, 3, 40068, 4)
    callback_register('modbus_send_40072', modbus_send, 3, 40072, 3)
    callback_register('modbus_send_40075', modbus_send, 3, 40075, 4)
    --    callback_register('screen',current_screen,4)
    --    callback_register('modbus_send_40012', modbus_send, 5, 40012)--remaining parts of barrel seems not yet finished

    --  gre.timer_set_interval(test_send,1000)
end

function current_screen()
    echo(gre.env('active_screen'))
end

function fifo_read()
    test = io.open('/opt/middleby/brix/modbus_up', 'r')
    if test == nil then
        echo('file empty')
    end
    io.input(test)
    while 1 do
        string_value = io.read(4)
        if string_value ~= nil then
            echo('modbus data is : ' .. string_value)
        else
            echo('file is temporary empty')
        end
    end
    io.close(test)
end

function defrostCheck()

    local timeNow = 0
    -- Get the time of day in minutes
    -- Get the clock value from the OS
    local defrostminute = tonumber(os.date('%M'))
    local defrosthour = tonumber(os.date('%H'))
    -- print( oshour )
    -- print( osminute )

    timeNow = (60 * defrosthour) + defrostminute

    if ((data_barrel_1['defrost1'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T1')
    elseif ((data_barrel_1['defrost2'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T2')
    elseif ((data_barrel_1['defrost3'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T3')
    elseif ((data_barrel_1['defrost4'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T4')
    elseif ((data_barrel_1['defrost5'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T5')
    elseif ((data_barrel_1['defrost6'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T6')
    elseif ((data_barrel_1['defrost7'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T7')
    elseif ((data_barrel_1['defrost8'] - timeNow) == 0) then
        triggerB1Defrost = true
        print('Defrost *** B1 T8')
    end

    if ((data_barrel_2['defrost1'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T1')
    elseif ((data_barrel_2['defrost2'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T2')
    elseif ((data_barrel_2['defrost3'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T3')
    elseif ((data_barrel_2['defrost4'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T4')
    elseif ((data_barrel_2['defrost5'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T5')
    elseif ((data_barrel_2['defrost6'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T6')
    elseif ((data_barrel_2['defrost7'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T7')
    elseif ((data_barrel_2['defrost8'] - timeNow) == 0) then
        triggerB2Defrost = true
        print('Defrost *** B2 T8')
    end

    if ((data_barrel_3['defrost1'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T1')
    elseif ((data_barrel_3['defrost2'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T2')
    elseif ((data_barrel_3['defrost3'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T3')
    elseif ((data_barrel_3['defrost4'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T4')
    elseif ((data_barrel_3['defrost5'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T5')
    elseif ((data_barrel_3['defrost6'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T6')
    elseif ((data_barrel_3['defrost7'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T7')
    elseif ((data_barrel_3['defrost8'] - timeNow) == 0) then
        triggerB3Defrost = true
        print('Defrost *** B3 T8')
    end

    if ((data_barrel_4['defrost1'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost2'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost3'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost4'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost5'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost6'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost7'] - timeNow) == 0) then
        triggerB4Defrost = true
    elseif ((data_barrel_4['defrost8'] - timeNow) == 0) then
        triggerB4Defrost = true
    end

    triggerDefrost()

    -- print('defrost Check')
    -- print('data_app[powersavermode] == ')
    -- print(data_app['powersavermode'])

    -- Power saver check
    -- If power saver mode is on then we can send the power saver on off message
    if (data_app['powersavermode'] == '1') then
        if ((data_app['powersaverstart'] - timeNow) == 0) then
            print('Trigger power saver start')
            -- triggerPowerSaverStart()
            SetPowerSaverModeOn()
        elseif ((data_app['powersaverend'] - timeNow) == 0) then
            print('Trigger power saver end')
            -- triggerPowerSaverEnd()
            SetPowerSaverModeOff()
        end
    end
end

function SetPowerSaverModeOn()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 6013
    }, gBackendChannel)
end

function SetPowerSaverModeOff()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 6014
    }, gBackendChannel)
end

function triggerDefrost()
    -- Send the mode change request for each barrel that is triggered
    -- Since there may be more than one and we can't send mutiple requests back to back,
    -- I made this inot a functon that can be called back.
    -- so we can handle more than one triggering at the same time
    -- So it will take 4 minutes for all 4 to trigger which may be ok

    cBarrelMode = 6

    if (triggerB1Defrost) then
        print('triggerB1Defrost')
        data_barrel_1['mode'] = cBarrelMode
        cBarrelStatus = data_barrel_1['status']
        cBarrelNumber = 1
        triggerB1Defrost = false
        SendBarrelDeforostConditions()
    elseif (triggerB2Defrost) then
        print('triggerB2Defrost')
        data_barrel_2['mode'] = cBarrelMode
        cBarrelStatus = data_barrel_2['status']
        cBarrelNumber = 2
        triggerB2Defrost = false
        SendBarrelDeforostConditions()
    elseif (triggerB3Defrost) then
        print('triggerB3Defrost')
        data_barrel_3['mode'] = cBarrelMode
        cBarrelStatus = data_barrel_3['status']
        cBarrelNumber = 3
        triggerB3Defrost = false
        SendBarrelDeforostConditions()
    elseif (triggerB4Defrost) then
        print('triggerB4Defrost')
        data_barrel_4['mode'] = cBarrelMode
        cBarrelStatus = data_barrel_4['status']
        cBarrelNumber = 4
        triggerB4Defrost = false
        SendBarrelDeforostConditions()
    end
end

function triggerPowerSaverStart()
    -- print('Power Saver Start')
    sendPowerSaverStart(1)
end

function sendPowerSaverStart(barrel)
    local barrelStatus
    local barrelMode = 7
    if barrel == 1 then
        gre.set_value('homescreen_layer.b1ModeButton_control.text', 'Standby')
        gre.set_value('current_conditions_layer.B1Mode_control.text', 'Standby')
        data_barrel_1['mode'] = 7
        BarrelStatus = data_barrel_1['status']
    elseif barrel == 2 then
        gre.set_value('homescreen_layer.b2ModeButton_control.text', 'Standby')
        gre.set_value('current_conditions_layer.B2Mode_control.text', 'Standby')
        data_barrel_2['mode'] = 7
        BarrelStatus = data_barrel_2['status']
    elseif barrel == 3 then
        gre.set_value('homescreen_layer.b3ModeButton_control.text', 'Standby')
        gre.set_value('current_conditions_layer.B3Mode_control.text', 'Standby')
        data_barrel_3['mode'] = 7
        BarrelStatus = data_barrel_3['status']
    elseif barrel == 4 then
        gre.set_value('homescreen_layer.b4ModeButton_control.text', 'Standby')
        gre.set_value('current_conditions_layer.B4Mode_control.text', 'Standby')
        data_barrel_4['mode'] = 7
        BarrelStatus = data_barrel_4['status']
    end
    gre.send_event_data('brixui_out_barrel_conditions', '1u1 barrel_number 1u1 status 1u1 mode', {
        barrel_number = barrel,
        status = barrelStatus,
        mode = barrelMode
    }, gBackendChannel)
    -- print('Barrel mode sent out')
end

function triggerPowerSaverEnd()
    -- print('Power Saver End')
    sendPowerSaverEnd(1)
end

function sendPowerSaverEnd(barrel)
    local barrelStatus
    local barrelMode = 10
    if barrel == 1 then
        gre.set_value('homescreen_layer.b1ModeButton_control.text', 'Off')
        gre.set_value('current_conditions_layer.B1Mode_control.text', 'Off')
        data_barrel_1['mode'] = 10
        barrelStatus = data_barrel_1['status']
    elseif barrel == 2 then
        gre.set_value('homescreen_layer.b2ModeButton_control.text', 'Off')
        gre.set_value('current_conditions_layer.B2Mode_control.text', 'Off')
        data_barrel_2['mode'] = 10
        barrelStatus = data_barrel_2['status']
    elseif barrel == 3 then
        gre.set_value('homescreen_layer.b3ModeButton_control.text', 'Off')
        gre.set_value('current_conditions_layer.B3Mode_control.text', 'Off')
        data_barrel_3['mode'] = 10
        barrelStatus = data_barrel_3['status']
    elseif barrel == 4 then
        gre.set_value('homescreen_layer.b4ModeButton_control.text', 'Off')
        gre.set_value('current_conditions_layer.B4Mode_control.text', 'Off')
        data_barrel_4['mode'] = 10
        barrelStatus = data_barrel_4['status']
    end
    gre.send_event_data('brixui_out_barrel_conditions', '1u1 barrel_number 1u1 status 1u1 mode', {
        barrel_number = barrel,
        status = barrelStatus,
        mode = barrelMode
    }, gBackendChannel)
    print('Barrel mode endsent out')

end

function sendBeep()
    -- print('Beep')
    os.execute('./opt/middleby/brix/beep.sh')
end

function beepSilenceCheck()
    if data_app['beepsilence'] == 1 then
        beep_silence_minute_counter = beep_silence_minute_counter + 1
    else
        beep_silence_minute_counter = 0
    end

    if beep_silence_minute_counter >= 5 then
        data_app['beepsilence'] = 0
    end
end

function SendBarrelDeforostConditions()
    gre.send_event_data('brixui_out_barrel_conditions', '1u1 barrel_number 1u1 status 1u1 mode', {
        barrel_number = cBarrelNumber,
        status = cBarrelStatus,
        mode = cBarrelMode
    }, gBackendChannel)
    -- print('Barrel Conditions sent out')
end

function updateTime()
    -- Show date time on the screen in the right format
    -- data_app['milirarytime'] == 0 12 hours  data_app['milirarytime'] == 1 24 hours
    if (data_app['milirarytime'] == '1') then
        --    print('24h')
        if (data_app['dateformat'] - 1 == 0) then
            --      print('form 1')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%m/%d/%Y %H:%M'))
        elseif (data_app['dateformat'] - 2 == 0) then
            --      print('form 2')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%d/%m/%Y %H:%M'))
        elseif (data_app['dateformat'] - 3 == 0) then
            --      print('form 3')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%Y/%m/%d %H:%M'))
        end
    else
        --    print('12h')
        if (data_app['dateformat'] - 1 == 0) then
            --      print('form 1')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%m/%d/%Y %I:%M%p'))
        elseif (data_app['dateformat'] - 2 == 0) then
            --      print('form 2')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%d/%m/%Y %I:%M%p'))
        elseif (data_app['dateformat'] - 3 == 0) then
            --      print('form 3')
            gre.set_value('bottomnavigation_layer.time_button_control.text', os.date('%Y/%m/%d %I:%M%p'))
        end
    end

    -- Get the clock value from the OS
    osday = tonumber(os.date('%d'))
    -- print( osday )
    osmonth = tonumber(os.date('%m'))
    -- print( osmonth )
    osyear = tonumber(os.date('%Y'))
    -- print( osyear )
    oshour = tonumber(os.date('%H'))
    -- print( oshour )
    osminute = tonumber(os.date('%M'))
    -- print( osminute )

    -- print('Why?')
    -- todo is this something that should be done?
    -- data_app['ampm']=0
    -- if(oshour>12) then
    -- data_app['ampm']=1
    -- end

    if (data_app['milirarytime'] == '1') then
        data_app['hour'] = oshour
    else
        if (oshour > 12) then
            data_app['hour'] = oshour - 12
        else
            data_app['hour'] = oshour
        end
    end

    data_app['minute'] = osminute
    data_app['day'] = osday
    data_app['month'] = osmonth
    data_app['year'] = osyear

    -- print(data_app['hour'])
    -- print(data_app['minute'])
    -- print(data_app['day'])
    -- print(data_app['month'])
    -- print(data_app['year'])
    -- print(data_app['ampm'])

    -- Every Hour send the time to the UVC4
    hour_counter = hour_counter + 1
    if hour_counter >= 7200 then
        hour_counter = 0
        SentEpochTime()
    end

    -- If the beep is not silenced
    if data_app['beepsilence'] == 0 then
        -- If there is a fault
        -- if faultHighLow + faultH20 + faultC02 + faultB1S + faultB2S + faultB3S + faultB4S > 0 then
        if data_app['faultcount'] == 1 then
            beep_counter = beep_counter + 1
            -- Every 2 seconds
            if beep_counter > 3 then
                sendBeep()
                -- print('beeping')
                beep_counter = 0
            end
        end
    end

end

--- @param gre#context mapargs
function ToggleBarrelSettingsMenu(mapargs)
    local settingsOpen = gre.get_value('MgrMenuBarrelSettingsOpen')
    if settingsOpen == 1 then

        -- gre.set_value('MgrMenuBarrelSettingsOpen',false);
        gre.set_value(
            'left_navigation_service_menu_layer.menu_items_group.barrelsettings_control.barrelsettings_closed_alpha', 0)
        gre.set_value(
            'left_navigation_service_menu_layer.menu_items_group.barrelsettings_control.barrelsettings_control_open_alpha',
            255)

    else
        -- gre.set_value('MgrMenuBarrelSettingsOpen',true);
        gre.set_value(
            'left_navigation_service_menu_layer.menu_items_group.barrelsettings_control.barrelsettings_closed_alpha',
            255)
        gre.set_value(
            'left_navigation_service_menu_layer.menu_items_group.barrelsettings_control.barrelsettings_control_open_alpha',
            0)
    end
end

function NextBarrel(mpargs)
    local barrel = gre.get_value('Home_Screen.nModeButtonSelected')
    local barerlMode = 0;
    barrel = barrel + 1
    if barrel == 5 then
        barrel = 1
    end
    gre.set_value('Home_Screen.nModeButtonSelected', barrel)

    -- Now change the text on the top of the screen to match
    if barrel == 1 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 1 Mode')
        barrelMode = gre.get_value('nBarrel1Mode')
    elseif barrel == 2 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 2 Mode')
        barrelMode = gre.get_value('nBarrel2Mode')
    elseif barrel == 3 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 3 Mode')
        barrelMode = gre.get_value('nBarrel3Mode')
    elseif barrel == 4 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 4 Mode')
        barrelMode = gre.get_value('nBarrel4Mode')
    end

    if barrelMode == 1 then -- Auto
        gre.set_value('modeButtons_layer.off_control.alpha', '0')
        gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
        gre.set_value('modeButtons_layer.Auto_control.alpha', '255')
        gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
    elseif barrelMode == 2 then -- Prime
        gre.set_value('modeButtons_layer.off_control.alpha', '0')
        gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
        gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
        gre.set_value('modeButtons_layer.Prime_control.alpha', '255')
    elseif barrelMode == 3 then -- Beater
        gre.set_value('modeButtons_layer.off_control.alpha', '0')
        gre.set_value('modeButtons_layer.Beater_control.alpha', '255')
        gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
        gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
    elseif barrelMode == 0 then -- Off
        gre.set_value('modeButtons_layer.off_control.alpha', '255')
        gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
        gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
        gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
    end
end

function PreviousBarrel(mpargs)
    local barrel = gre.get_value('Home_Screen.nModeButtonSelected')
    barrel = barrel - 1
    if barrel == 0 then
        barrel = 4
    end
    gre.set_value('Home_Screen.nModeButtonSelected', barrel)

    -- Now change the text on the top of the screen to match
    if barrel == 1 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 1 Mode')
    elseif barrel == 2 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 2 Mode')
    elseif barrel == 3 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 3 Mode')
    elseif barrel == 4 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 4 Mode')
    end
end

function OpenHomeScreenPost(mpargs)

end

function commsFail()
    local dk_data = {};

    if (data_app['commFail'] == '0') then
        dk_data = gre.get_layer_attrs('commFailLayer')
        if (dk_data ~= nil) then
            dk_data['hidden'] = 1
            gre.set_layer_attrs('commFailLayer', dk_data)

        end
    else
        dk_data = gre.get_layer_attrs('commFailLayer')
        if (dk_data ~= nil) then
            gre.set_value('commFailLayer.modal_window_group.modal_background.text',
                'Communications with\nControl Board\nFailed')
            dk_data['hidden'] = 0;
            gre.set_layer_attrs('commFailLayer', dk_data)

            if (idval_str ~= nil) then
                gre.timer_clear_interval(idval_str)
                idval_str = nil
            end
            if (idval_i ~= nil) then
                gre.timer_clear_interval(idval_i)
                idval_i = nil
            end
            if (idval_t ~= nil) then
                gre.timer_clear_interval(idval_t)
                idval_t = nil
            end
            if (idval_cs ~= nil) then
                gre.timer_clear_interval(idval_cs)
                idval_cs = nil
            end
            if (idval_qcs ~= nil) then
                gre.timer_clear_interval(idval_qcs)
                idval_qcs = nil
            end
            if (idval_vol ~= nil) then
                gre.timer_clear_interval(idval_vol)
                idval_vol = nil
            end
            if (idval_bac ~= nil) then
                gre.timer_clear_interval(idval_bac)
                idval_bac = nil
            end
        end
    end
end

-- Send a command to the MODBUS app
-- All commands are numbers
-- The app knows what data to request from the UVC4 based on the command number
function RequestCommand(mpargs)
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 100
    }, gBackendChannel)
    print('Request Command sent out')
end

function RequestBrixBackendVersion(mpargs)
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 10
    }, gBackendChannel)
    print('Request brix_backend version sent out')
end

function CBUpdateError(mpargs)
    local ev_data = mpargs.context_event_data

    gModbusTotalError = ev_data.total_error
    gModbusWriteError = ev_data.write_error
    gModbusReadError = ev_data.read_error
    gModbusContinueCount = ev_data.count
    gModbusStatus = ev_data.status

    if gModbusStatus == 1 then
        data_app['commFail'] = '1'
    elseif gModbusStatus == 0 then
        data_app['commFail'] = '0'
    end
    commsFail()
end

function TestButton()
    -- if(data_app['commFail'] == '0') then
    -- data_app['commFail'] = '1'
    -- else
    -- data_app['commFail'] = '0'
    -- end
    -- commsFail()
    -- gre.timer_set_interval(1000,updatefail)
    -- CBUpdateError(mpargs)

    -- Testing
    -- if data_app['pressurecutout'] == 1 then
    -- if data_app['beepsilence']==0 then
    -- data_app['beepsilence']=1
    -- data_app['pressurecutout'] = 0
    -- else
    -- data_app['beepsilence']=0
    -- data_app['pressurecutout'] = 1
    -- end

end

function updatefail()
    -- print('timer updatefail')
    if (data_app['commFail'] == '0') then
        data_app['commFail'] = '1'
    else
        data_app['commFail'] = '0'
    end
    commsFail()
end

function CBUpdateData10(mpargs)
    local ev_data = mpargs.context_event_data
    local app_backend
    app_backend = ev_data.backend_ver

    if (app_backend > 101) then
        data_app['backendver'] = ev_data.backend_ver
        SetSystemInfo()
        data_app['backendver_flag'] = 1
    else
        data_app['backendver_flag'] = 0
    end

    if (data_app['backendver_flag'] == 1) then
        gre.timer_clear_interval(idval_bac)
        idval_bac = nil
    end
end

function DisplayTargetData100()
    local data = {}
    gTimeoutID = nil

    --  data['system_info_layer.card_system_info_group.firmware_control.text'] = string.format('V%06d', gTargetFirmware)
    --  gre.set_data(data)
    --  data['system_info_layer.card_system_info_group.info_Control_BOM.text'] = string.format('BOM%04d', gTargetBOM)
    --  gre.set_data(data)
    --  data['system_info_layer.card_system_info_group.info_SerialNumber.text'] = string.format('SN%05d', gTargetSerial)
    --  gre.set_data(data)

    -- data['bottomnavigation_layer.time_button_control.text'] = string.format('06/28/2021\n %02d:%02d:%02d', gTargetTemp_h, gTargetTemp_m, gTargetTemp_s)
    -- gre.set_data(data)

end

function CBUpdateData50(mpargs)
    local ev_data = mpargs.context_event_data

    local barrel = ev_data.barrel_number
    local modbus_barerlMode = ev_data.mode
    local current_barerlMode

    print('CBUpdateData50')

    gre.set_value('Home_Screen.nModeButtonSelected', barrel)

    -- Now change the text on the top of the screen to match
    if barrel == 1 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 1 Mode')
        current_barrelMode = gre.get_value('nBarrel1Mode')
    elseif barrel == 2 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 2 Mode')
        current_barrelMode = gre.get_value('nBarrel2Mode')
    elseif barrel == 3 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 3 Mode')
        current_barrelMode = gre.get_value('nBarrel3Mode')
    elseif barrel == 4 then
        gre.set_value('modeButtons_layer.background_group.B1_Mode.text', 'Barrel 4 Mode')
        current_barrelMode = gre.get_value('nBarrel4Mode')
    end

    if modbus_barrelMode == current_barrelMode then
        if modbus_barrelMode == 1 then -- Auto
            gre.set_value('modeButtons_layer.off_control.alpha', '0')
            gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
            gre.set_value('modeButtons_layer.Auto_control.alpha', '255')
            gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
        elseif modbus_barrelMode == 2 then -- Prime
            gre.set_value('modeButtons_layer.off_control.alpha', '0')
            gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
            gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
            gre.set_value('modeButtons_layer.Prime_control.alpha', '255')
        elseif modbus_barrelMode == 3 then -- Beater
            gre.set_value('modeButtons_layer.off_control.alpha', '0')
            gre.set_value('modeButtons_layer.Beater_control.alpha', '255')
            gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
            gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
        elseif modbus_barrelMode == 0 then -- Off
            gre.set_value('modeButtons_layer.off_control.alpha', '255')
            gre.set_value('modeButtons_layer.Beater_control.alpha', '0')
            gre.set_value('modeButtons_layer.Auto_control.alpha', '0')
            gre.set_value('modeButtons_layer.Prime_control.alpha', '0')
        end
    end

    print('Receive Data 50 from Modbus')

end

function CBUpdateData90(mpargs)
    local ev_data = mpargs.context_event_data

    data_app['compressor'] = ev_data.compressor
    data_app['barrelcount'] = ev_data.barrel_count
    data_app['faultcount'] = ev_data.fault
    data_app['pressurecutout'] = ev_data.pressure_cutout
    data_app['co2'] = ev_data.co2_pressure
    data_app['h2o'] = ev_data.h2o_pressure

    SetMachineLevelFaultIndicators()

    -- print('Receive Data 90 from Modbus')

end

function CBUpdateData100(mpargs)
    local ev_data = mpargs.context_event_data

    gTargetFirmware = ev_data.firmware
    gTargetSerial = ev_data.serial
    gTargetStore_ID = ev_data.store_id
    gTargetBOM = ev_data.bom
    gTargetDevice_Conditions = ev_data.device_conditions

    data_app['bom'] = string.format('BOM%.4d', gTargetBOM)
    data_app['serialnumber'] = string.format('SN%.5d', gTargetSerial)
    data_app['uiversion'] = string.format('V%.5d', gTargetFirmware)
    data_app['storeid'] = string.format('SID%.4d', gTargetStore_ID)

    data_app['h2o'] = bit.band(gTargetDevice_Conditions, 0x1)
    data_app['co2'] = bit.band(bit.rshift(gTargetDevice_Conditions, 1), 0x1)
    data_app['pressurecutout'] = bit.band(bit.rshift(gTargetDevice_Conditions, 2), 0x1)
    data_app['barrelcount'] = bit.band(bit.rshift(gTargetDevice_Conditions, 4), 0x3)

    data_app['language'] = bit.band(bit.rshift(gTargetDevice_Conditions, 7), 0x7)
    -- data_app['powersavermode'] = bit.band(bit.rshift(gTargetDevice_Conditions, 10), 0x1)
    data_app['dateformat'] = bit.band(bit.rshift(gTargetDevice_Conditions, 11), 0x1)
    data_app['units'] = bit.band(bit.rshift(gTargetDevice_Conditions, 12), 0x1)

    DisplayTargetData100()

    -- print('Receive Data 100 from Modbus')
    -- printf('Serial Number: %06d',gTargetSerial)

end

function CBUpdateData200(mpargs)
    local ev_data = mpargs.context_event_data

    data_barrel_1['viscosity'] = ev_data.barrel_1_viscosity
    data_barrel_1['temp'] = ev_data.barrel_1_temp / 10.0

    data_barrel_2['viscosity'] = ev_data.barrel_2_viscosity
    data_barrel_2['temp'] = ev_data.barrel_2_temp / 10.0

    data_barrel_3['viscosity'] = ev_data.barrel_3_viscosity
    data_barrel_3['temp'] = ev_data.barrel_3_temp / 10.0

    data_barrel_4['viscosity'] = ev_data.barrel_4_viscosity
    data_barrel_4['temp'] = ev_data.barrel_4_temp / 10.0

    data_barrel_1['status'] = ev_data.barrel_1_status
    data_barrel_1['mode'] = ev_data.barrel_1_mode
    data_barrel_2['status'] = ev_data.barrel_2_status
    data_barrel_2['mode'] = ev_data.barrel_2_mode
    data_barrel_3['status'] = ev_data.barrel_3_status
    data_barrel_3['mode'] = ev_data.barrel_3_mode
    data_barrel_4['status'] = ev_data.barrel_4_status
    data_barrel_4['mode'] = ev_data.barrel_4_mode

    SetBarrel1Values()
    SetBarrel2Values()
    SetBarrel3Values()
    SetBarrel4Values()

    -- print('Receive Data 200 from Modbus')

end

function SettingsButtonPressAction(mpargs)
    local dk_data = {};

    -- print('SettingsButtonPressAction')

    -- Only do anything when this button is pressed if we are on the home screen
    if (data_app['currentscreen'] == 0) then
        dk_data = gre.get_layer_attrs('numKeyboard_layer');
        dk_data['hidden'] = 0;
        gre.set_layer_attrs('numKeyboard_layer', dk_data)

        dk_data = gre.get_layer_attrs('passcode_layer');
        dk_data['hidden'] = 0;
        gre.set_layer_attrs('passcode_layer', dk_data)

        data_app['mmKeypadType'] = '0'
        -- else
        -- print('SettingsButtonPressAction denied')
    end
end

function ServiceAccordianBarrelSettings(mpargs)
    local dk_data = {};

    if (data_app['accordianbarrelsettings'] == 0) then
        gre.animation_trigger('accordian_barrel_settings')
        data_app['accordianbarrelsettings'] = 1
    else
        gre.animation_trigger('accordian_barrel_settings_reversed')
        data_app['accordianbarrelsettings'] = 0

        dk_data = gre.get_layer_attrs('viscosity_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('viscosity_layer', dk_data)

        dk_data = gre.get_layer_attrs('pressure_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('pressure_layer', dk_data)

        dk_data = gre.get_layer_attrs('standby_temp_range_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('standby_temp_range_layer', dk_data)

        dk_data = gre.get_layer_attrs('power_saver_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('power_saver_layer', dk_data)

        gre.animation_trigger('viscosity_activate_reversed')
        gre.animation_trigger('Pressure_activate_reversed')
        gre.animation_trigger('Standby_temp_activate_reversed')
        gre.animation_trigger('power_saver_activate_reversed')

    end
end

function ServiceAccordianMachineSettings(mpargs)
    local dk_data = {};

    if (data_app['accordianmachinesettings'] == 0) then
        gre.animation_trigger('accordian_machine_settings')
        data_app['accordianmachinesettings'] = 1
    else
        gre.animation_trigger('accordian_machine_settings_reversed')
        data_app['accordianmachinesettings'] = 0

        gre.animation_trigger('configuration_activate_reversed')
        gre.animation_trigger('temp_scale_activate_reversed')
        gre.animation_trigger('Compressor_activate_reversed')
        gre.animation_trigger('program_defrost_activate_reversed')
        gre.animation_trigger('fan_hold_activate_reversed')
        gre.animation_trigger('left_nav_language_select_reversed')
        gre.animation_trigger('save_restore_activate_reversed')
        gre.animation_trigger('update_firmware_activate_reversed')

        dk_data = gre.get_layer_attrs('Configuration_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('Configuration_layer', dk_data)

        dk_data = gre.get_layer_attrs('temp_scale_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('temp_scale_layer', dk_data)

        dk_data = gre.get_layer_attrs('Compressor_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('Compressor_layer', dk_data)

        dk_data = gre.get_layer_attrs('program_defrost_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('program_defrost_layer', dk_data)

        dk_data = gre.get_layer_attrs('fan_hold_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('fan_hold_layer', dk_data)

        dk_data = gre.get_layer_attrs('Language_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('Language_layer', dk_data)

        dk_data = gre.get_layer_attrs('save_restore_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('save_restore_layer', dk_data)

        dk_data = gre.get_layer_attrs('update_firmware_UVC4_UI_layer');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('update_firmware_UVC4_UI_layer', dk_data)

    end
end

function ServiceAccordianDiagnosticsSettings(mpargs)
    local dk_data = {};

    if (data_app['accordiandiagnostics'] == 0) then
        gre.animation_trigger('accordian_diagnostics')
        data_app['accordiandiagnostics'] = 1
    else
        gre.animation_trigger('accordian_diagnostics_reversed')
        data_app['accordiandiagnostics'] = 0

        gre.animation_trigger('manualcontrol_activate_reversed')
        gre.animation_trigger('currentstatus_activate_reversed')

        dk_data = gre.get_layer_attrs('current_status_layer2');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('current_status_layer2', dk_data)

        dk_data = gre.get_layer_attrs('manual_control_layer1');
        dk_data['hidden'] = 1;
        gre.set_layer_attrs('manual_control_layer1', dk_data)

    end
end

function RequestResetFaults()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 6010
    }, gBackendChannel)
end

function RequestVersion()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 5155
    }, gBackendChannel)
end

function CBUpdateData5155(mpargs)
    local ev_data = mpargs.context_event_data
    local app_uvcversion
    app_uvcversion = ev_data.uvc4_version

    print('UVC4 Version Received')

    -- if(string.match(app_uvcversion,'UVC4')) then
    if (app_uvcversion ~= nil) then
        data_app['uvc4version'] = ev_data.uvc4_version
        data_app['uvc4version_flag'] = 1
    else
        data_app['uvc4version_flag'] = 0
    end

    if (data_app['uvc4version_flag'] == 1) then
        gre.timer_clear_interval(idval_str)
        idval_str = nil
        idval_str = gre.timer_set_interval(RequestModel, 400)
    end
end

function RequestModel()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 5662
    }, gBackendChannel)
end

function RequestBOM()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 6367
    }, gBackendChannel)

end

function RequestSN()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 6871
    }, gBackendChannel)
    -- print('Serial Number Requested')
end

function RequestCounter(mpargs)
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 4750
    }, gBackendChannel)
end

function RequestStoreId()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 7274
    }, gBackendChannel)
    print('Store ID Requested')
end

function RequestStandbyTemp()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 3434
    }, gBackendChannel)
    print('Standby Temp Requested')
end

function CBUpdateData3434(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_app['standbytempmax'] = ev_data.standby_temp_max
        data_app['standbytempmin'] = ev_data.standby_temp_min

        DispayCurrentStandbyTemp()

        SetCurrentStandbyTemp()

    elseif (Initflag == 0) then
        local diff_standbytempmax
        local diff_standbytempmin

        diff_standbytempmax = ev_data.standby_temp_max - data_app['standbytempmax']
        diff_standbytempmin = ev_data.standby_temp_min - data_app['standbytempmin']

        if (diff_standbytempmax == 0 and diff_standbytempmin == 0) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendCompressorVerify, 900)
        end
    end
end

function CBUpdateData37372(mpargs)
    local ev_data = mpargs.context_event_data

    data_app['uvc4complete'] = ev_data.uvc4_complete
    data_app['uvc4failed'] = ev_data.uvc4_failed

    print('37372 Firmware update response')
    print(data_app['uvc4complete'])
    print(data_app['uvc4failed'])

    print(ev_data.uvc4_complete)
    print(ev_data.uvc4_failed)
end

function RequestCompressor()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 4243
    }, gBackendChannel)
    print('Compressor delay Requested')
end

function CBUpdateData4243(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_app['compressorondelay'] = ev_data.ondelay
        data_app['holdofftime'] = ev_data.offdelay

        DisplayCompressorTimes()

        setCompressorTimes()

    elseif (Initflag == 0) then

        local diff_ondelay
        local diff_offdelay

        diff_ondelay = ev_data.ondelay - data_app['compressorondelay']
        diff_offdelay = ev_data.offdelay - data_app['holdofftime']

        if (diff_ondelay == 0 and diff_offdelay == 0) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendFanHoldVerify, 900)
        end

    end

end

function RequestFanHoldTime()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 4444
    }, gBackendChannel)
    print('Fan Hold Time Requested')
end

function CBUpdateData4444(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then
        data_app['fanholdtime'] = ev_data.fanhold_time

        DisplayFanHoldTime()

        setFanHoldTime()

    elseif (Initflag == 0) then
        local diff_fanholdtime

        diff_fanholdtime = ev_data.fanhold_time - data_app['fanholdtime']
        if (diff_fanholdtime == 0) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendBarrelSettingsVerify1, 900)
        end

    end

end

-- function CBUpdateData7274(mpargs)
--  local ev_data = mpargs.context_event_data
--  data_app['storeid'] = ev_data.storeid

--  SetSystemInfo()
-- end

function SetSystemInfo()

    print('Set System Info')
    local data = {}
    gTimeoutID = nil

    gre.set_value('topnavigation_layer.Header_Bar.text', data_app['model'])
    gre.set_value('system_info_layer.Label_System_Information.text',
        'System Information - ' .. data_app['uiversion'] .. ' - ' .. data_app['backendver'])
    gre.set_value('system_info_layer.card_system_info_group.info_Model.text', data_app['model'])

    gre.set_value('system_info_layer.card_system_info_group.info_Control_BOM.text', data_app['bom'])
    gre.set_value('system_info_layer.card_system_info_group.info_SerialNumber.text', data_app['serialnumber'])
    gre.set_value('system_info_layer.card_system_info_group.firmware_control.text', data_app['uvc4version'])

    gre.set_value('configurationBOM_input.configuration_Input_BOM_group.input_active_control.text',
        data_app['bom'] .. '_')
    gre.set_value('configuration_SERIAL_NUMBER_input.configuration_Input_serial_number_group.input_active_control.text',
        data_app['serialnumber'] .. '_')
    gre.set_value('configuration_STORE_ID_input.configuration_Input_serial_number_group1.input_active_control.text',
        data_app['storeid'] .. '_')

    gre.set_value('Configuration_layer.BOM_control.text', data_app['bom'])
    gre.set_value('Configuration_layer.SerialNumber_control.text', data_app['serialnumber'])
    gre.set_value('Configuration_layer.StoreID_control.text', data_app['storeid'])

    -- Version on udpate screen
    gre.set_value('update_firmware_UVC4_UI_layer.FirmwareCard_group.V1_14r00_English_553.text', data_app['uvc4version'])

    RequestServings()
end

function RequestServings()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 4750
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData4750(mpargs)
    local ev_data = mpargs.context_event_data

    data_barrel_1['servings'] = ev_data.b1_count
    data_barrel_2['servings'] = ev_data.b2_count
    data_barrel_3['servings'] = ev_data.b3_count
    data_barrel_4['servings'] = ev_data.b4_count

    gre.set_value('counters_layer.b1_count_group.b1_count.text', data_barrel_1['servings']);
    gre.set_value('counters_layer.b2_count_group.b2_count.text', data_barrel_2['servings']);
    gre.set_value('counters_layer.b3_count_group.b3_count.text', data_barrel_3['servings']);
    gre.set_value('counters_layer.b4_count_group.b4_count.text', data_barrel_4['servings']);
    totalservings = data_barrel_1['servings'] + data_barrel_2['servings'] + data_barrel_3['servings'] +
                        data_barrel_4['servings']
    gre.set_value('counters_layer.total_servings_group.34_467.text', totalservings)

end

--- @param gre#context mapargs
function CBUpdateData5662(mpargs)
    local ev_data = mpargs.context_event_data
    local app_uvcmodel
    app_uvcmodel = ev_data.model

    -- if(string.match(app_uvcmodel,'UVC4')) then
    if (app_uvcmodel ~= nil) then
        data_app['model'] = ev_data.model
        data_app['model_flag'] = 1
    else
        data_app['model_flag'] = 0
    end

    if (data_app['model_flag'] == 1) then
        gre.timer_clear_interval(idval_str)
        idval_str = nil
        idval_str = gre.timer_set_interval(RequestBOM, 400)
    end
end

--- @param gre#context mapargs
function CBUpdateData6367(mpargs)
    local ev_data = mpargs.context_event_data
    local app_bom
    app_bom = ev_data.bom

    if (Initflag == 1) then
        -- if(string.match(app_bom,'BOM')) then
        if (app_bom ~= nil) then
            data_app['bom'] = ev_data.bom
            data_app['bom_flag'] = 1
        else
            data_app['bom_flag'] = 0
        end

        if (data_app['bom_flag'] == 1) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(RequestSN, 400)
        end
    elseif (Initflag == 0) then

        if (app_bom == old_compare_str) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendSerialVerify, 900)
        end
    end
end

--- @param gre#context mapargs
function CBUpdateData6871(mpargs)
    local ev_data = mpargs.context_event_data
    local app_serial
    app_serial = ev_data.serialnumber

    if (Initflag == 1) then
        -- if(string.match(app_serial,'SN')) then
        if (app_serial ~= nil) then
            data_app['serialnumber'] = ev_data.serialnumber
            data_app['serialnumber_flag'] = 1
        else
            data_app['serialnumber_flag'] = 0
        end

        if (data_app['serialnumber_flag'] == 1) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(RequestStoreId, 400)
        end

    elseif (Initflag == 0) then

        if (app_serial == old_compare_str) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendStoreIdVerify, 900)
        end
    end
end

function initEndTest()
    local dk_data = {};
    -- print('initEndTest')
    dk_data = gre.get_layer_attrs('commFailLayer')
    gre.set_value('commFailLayer.modal_window_group.modal_background.text', 'Communications with Control Board Failed')
    dk_data['hidden'] = 1
    gre.set_layer_attrs('commFailLayer', dk_data)
    --  gre.timer_clear_interval(idval_init)
    idval_init = nil

    if is_dev == 1 then
        -- JumpToSN()
        -- If serial number is default, force the user to change it
        if data_app['serialnumber'] == 'SN1234' then
            JumpToSN()
        else
            -- If the date is wrong, force them to change it
            if data_app['year'] < 2022 then
                init_sn = 1
                data_app['currentscreen'] = 1
                gre.send_event('SHOW_MANAGER_MENU')
            end
        end

    end
end

--- receive Store ID, When InitFlag == 0 save to data_app['storeid']. when InitFlag == 1 verify received StoreID and data_app['storeid']
function CBUpdateData7274(mpargs)
    local ev_data = mpargs.context_event_data
    local app_storeid
    app_storeid = ev_data.storeid

    if (Initflag == 1) then
        -- if(string.match(app_storeid,'SD')) then
        if (app_storeid ~= nil) then
            data_app['storeid'] = ev_data.storeid
            SetSystemInfo()
            data_app['storeid_flag'] = 1
        else
            data_app['storeid_flag'] = 0
        end

        if (data_app['storeid_flag'] == 1) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            -- idval_str = gre.timer_set_interval(RequestBrixBackendVersion,400)

            -- Close the initializing screen
            local dk_data = {};
            dk_data = gre.get_layer_attrs('commFailLayer')
            gre.set_value('commFailLayer.modal_window_group.modal_background.text',
                'Communications with Control Board Failed')
            dk_data['hidden'] = 1
            gre.set_layer_attrs('commFailLayer', dk_data)
            if idval_init ~= nil then
                gre.timer_clear_interval(idval_init)
                idval_init = nil
            end

            -- If serial number is default, force the user to change it

            if data_app['serialnumber'] == 'K0000000' then
                JumpToSN()
            else
                -- If the date is wrong, force them to change it
                if data_app['year'] < 2022 then
                    -- if(true) then
                    init_sn = 1
                    data_app['currentscreen'] = 1
                    gre.send_event('SHOW_MANAGER_MENU')
                end
            end
        end

    elseif (Initflag == 0) then

        if (app_storeid == old_compare_str) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendStandbyTempVerify, 900)
        end
    end

    -- if(InitFlag == 0) then
    --  data_app['storeid'] = ev_data.storeid
    --  SetSystemInfo()
    -- else
    --  if(data_app['storeid'] == ev_data.storeid) then

    --  else
    --    SendStoreIdVerify()
    --  end

    -- end

end

function RequestBarrelSettings1()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 912
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData0912(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_barrel_1['visc_hyst'] = ev_data.vis_hys
        data_barrel_1['visc_cutout'] = ev_data.vis_cutout
        data_barrel_1['pressure_hyst'] = ev_data.pre_hys
        data_barrel_1['pressure_set'] = ev_data.set_pressure

    elseif (Initflag == 0) then
        local diff_vis_hyst
        local diff_vis_cutout
        local diff_pres_hyst
        local diff_pres_set

        diff_vis_hyst = ev_data.vis_hys - data_barrel_1['visc_hyst']
        diff_vis_cutout = ev_data.vis_cutout - data_barrel_1['visc_cutout']
        diff_pres_hyst = ev_data.pre_hys - data_barrel_1['pressure_hyst']
        diff_pres_set = ev_data.set_pressure - data_barrel_1['pressure_set']

        if ((diff_vis_hyst == 0) and (diff_vis_cutout == 0) and (diff_pres_hyst == 0) and (diff_pres_set == 0)) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendBarrelSettingsVerify2, 900)
        end
    end
    -- SetSystemInfo()
    -- gre.get_value('viscosity_layer.b1_buttons_group1.input_hysteresis_control.text')
end

function RequestBarrelSettings2()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 1619
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData1619(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_barrel_2['visc_hyst'] = ev_data.vis_hys
        data_barrel_2['visc_cutout'] = ev_data.vis_cutout
        data_barrel_2['pressure_hyst'] = ev_data.pre_hys
        data_barrel_2['pressure_set'] = ev_data.set_pressure

    elseif (Initflag == 0) then
        local diff_vis_hyst
        local diff_vis_cutout
        local diff_pres_hyst
        local diff_pres_set

        diff_vis_hyst = ev_data.vis_hys - data_barrel_2['visc_hyst']
        diff_vis_cutout = ev_data.vis_cutout - data_barrel_2['visc_cutout']
        diff_pres_hyst = ev_data.pre_hys - data_barrel_2['pressure_hyst']
        diff_pres_set = ev_data.set_pressure - data_barrel_2['pressure_set']

        if ((diff_vis_hyst == 0) and (diff_vis_cutout == 0) and (diff_pres_hyst == 0) and (diff_pres_set == 0)) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendBarrelSettingsVerify3, 900)
        end
    end
end

function RequestBarrelSettings3()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 2326
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData2326(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_barrel_3['visc_hyst'] = ev_data.vis_hys
        data_barrel_3['visc_cutout'] = ev_data.vis_cutout
        data_barrel_3['pressure_hyst'] = ev_data.pre_hys
        data_barrel_3['pressure_set'] = ev_data.set_pressure

    elseif (Initflag == 0) then
        local diff_vis_hyst
        local diff_vis_cutout
        local diff_pres_hyst
        local diff_pres_set

        diff_vis_hyst = ev_data.vis_hys - data_barrel_3['visc_hyst']
        diff_vis_cutout = ev_data.vis_cutout - data_barrel_3['visc_cutout']
        diff_pres_hyst = ev_data.pre_hys - data_barrel_3['pressure_hyst']
        diff_pres_set = ev_data.set_pressure - data_barrel_3['pressure_set']

        if ((diff_vis_hyst == 0) and (diff_vis_cutout == 0) and (diff_pres_hyst == 0) and (diff_pres_set == 0)) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            idval_str = gre.timer_set_interval(SendBarrelSettingsVerify4, 400)
        end
    end
end

function RequestBarrelSettings4()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 3033
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData3033(mpargs)
    local ev_data = mpargs.context_event_data

    if (Initflag == 1) then

        data_barrel_4['visc_hyst'] = ev_data.vis_hys
        data_barrel_4['visc_cutout'] = ev_data.vis_cutout
        data_barrel_4['pressure_hyst'] = ev_data.pre_hys
        data_barrel_4['pressure_set'] = ev_data.set_pressure

    elseif (Initflag == 0) then
        local diff_vis_hyst
        local diff_vis_cutout
        local diff_pres_hyst
        local diff_pres_set

        diff_vis_hyst = ev_data.vis_hys - data_barrel_4['visc_hyst']
        diff_vis_cutout = ev_data.vis_cutout - data_barrel_4['visc_cutout']
        diff_pres_hyst = ev_data.pre_hys - data_barrel_4['pressure_hyst']
        diff_pres_set = ev_data.set_pressure - data_barrel_4['pressure_set']

        if ((diff_vis_hyst == 0) and (diff_vis_cutout == 0) and (diff_pres_hyst == 0) and (diff_pres_set == 0)) then
            gre.timer_clear_interval(idval_str)
            idval_str = nil
            Initflag = 1
        end
    end
end

--- @param gre#context mapargs
function CBUpdateData7578(mpargs)
    local ev_data = mpargs.context_event_data
    -- data_barrel_1['status'] = ev_data.b1_status
    -- data_barrel_2['status'] = ev_data.b2_status
    -- data_barrel_3['status'] = ev_data.b3_status
    -- data_barrel_4['status'] = ev_data.b4_status

    data_barrel_1['cs_defrost'] = ev_data.b1_defro
    data_barrel_1['cs_light'] = ev_data.b1_light
    data_barrel_1['cs_h2o_s'] = ev_data.b1_h2o_s
    data_barrel_1['cs_syrup_s'] = ev_data.b1_syr_s
    data_barrel_1['cs_co2_s'] = ev_data.b1_co2_s
    data_barrel_1['cs_liquid_s'] = ev_data.b1_liq_s
    data_barrel_1['cs_beater motor'] = ev_data.b1_bea_m
    data_barrel_1['cs_compressor'] = ev_data.b1_comp
    data_barrel_1['cs_fan'] = ev_data.b1_fan
    data_barrel_1['cs_h2ob_s'] = ev_data.b1_h2ob

    data_barrel_2['cs_defrost'] = ev_data.b2_defro
    data_barrel_2['cs_light'] = ev_data.b2_light
    data_barrel_2['cs_h2o_s'] = ev_data.b2_h2o_s
    data_barrel_2['cs_syrup_s'] = ev_data.b2_syr_s
    data_barrel_2['cs_co2_s'] = ev_data.b2_co2_s
    data_barrel_2['cs_liquid_s'] = ev_data.b2_liq_s
    data_barrel_2['cs_beater motor'] = ev_data.b2_bea_m
    data_barrel_2['cs_compressor'] = ev_data.b2_comp
    data_barrel_2['cs_fan'] = ev_data.b2_fan
    data_barrel_2['cs_h2ob_s'] = ev_data.b2_h2ob

    data_barrel_3['cs_defrost'] = ev_data.b3_defro
    data_barrel_3['cs_light'] = ev_data.b3_light
    data_barrel_3['cs_h2o_s'] = ev_data.b3_h2o_s
    data_barrel_3['cs_syrup_s'] = ev_data.b3_syr_s
    data_barrel_3['cs_co2_s'] = ev_data.b3_co2_s
    data_barrel_3['cs_liquid_s'] = ev_data.b3_liq_s
    data_barrel_3['cs_beater motor'] = ev_data.b3_bea_m
    data_barrel_3['cs_compressor'] = ev_data.b3_comp
    data_barrel_3['cs_fan'] = ev_data.b3_fan
    data_barrel_3['cs_h2ob_s'] = ev_data.b3_h2ob

    data_barrel_4['cs_defrost'] = ev_data.b4_defro
    data_barrel_4['cs_light'] = ev_data.b4_light
    data_barrel_4['cs_h2o_s'] = ev_data.b4_h2o_s
    data_barrel_4['cs_syrup_s'] = ev_data.b4_syr_s
    data_barrel_4['cs_co2_s'] = ev_data.b4_co2_s
    data_barrel_4['cs_liquid_s'] = ev_data.b4_liq_s
    data_barrel_4['cs_beater motor'] = ev_data.b4_bea_m
    data_barrel_4['cs_compressor'] = ev_data.b4_comp
    data_barrel_4['cs_fan'] = ev_data.b4_fan
    data_barrel_4['cs_h2ob_s'] = ev_data.b4_h2ob
    -- SetSystemInfo()
end

--- @param gre#context mapargs
function CBUpdateData7982(mpargs)
    local ev_data = mpargs.context_event_data
    data_barrel_1['pressure_act'] = ev_data.b1_pressure
    data_barrel_2['pressure_act'] = ev_data.b2_pressure
    data_barrel_3['pressure_act'] = ev_data.b3_pressure
    data_barrel_4['pressure_act'] = ev_data.b4_pressure
    -- SetSystemInfo()

    SetBarrel1Values()
    SetBarrel2Values()
    SetBarrel3Values()
    SetBarrel4Values()

end

function SavePowerupCSV()
    local powerup_attrs = {}
    local pre_power = {}
    powerup_attrs.textDB = gre.APP_ROOT .. '/configurations/powerup.csv'
    local pupfile = io.open(powerup_attrs.textDB, 'w')

    if (pupfile == nil) then
        return nil, string.format('Can not access database file %s', powerup_attrs.textDB)
    end

    -- SavePowerupValue(mpargs)
    pre_power[1] = data_app['language']
    pre_power[2] = data_app['milirarytime']
    pre_power[3] = data_app['dateformat']
    pre_power[4] = data_app['powersaverstart']
    pre_power[5] = data_app['powersaverend']
    pre_power[6] = data_app['units']
    pre_power[7] = data_barrel_1['defrost1']
    pre_power[8] = data_barrel_1['defrost2']
    pre_power[9] = data_barrel_1['defrost3']
    pre_power[10] = data_barrel_1['defrost4']
    pre_power[11] = data_barrel_1['defrost5']
    pre_power[12] = data_barrel_1['defrost6']
    pre_power[13] = data_barrel_1['defrost7']
    pre_power[14] = data_barrel_1['defrost8']
    pre_power[15] = data_barrel_2['defrost1']
    pre_power[16] = data_barrel_2['defrost2']
    pre_power[17] = data_barrel_2['defrost3']
    pre_power[18] = data_barrel_2['defrost4']
    pre_power[19] = data_barrel_2['defrost5']
    pre_power[20] = data_barrel_2['defrost6']
    pre_power[21] = data_barrel_2['defrost7']
    pre_power[22] = data_barrel_2['defrost8']
    pre_power[23] = data_barrel_3['defrost1']
    pre_power[24] = data_barrel_3['defrost2']
    pre_power[25] = data_barrel_3['defrost3']
    pre_power[26] = data_barrel_3['defrost4']
    pre_power[27] = data_barrel_3['defrost5']
    pre_power[28] = data_barrel_3['defrost6']
    pre_power[29] = data_barrel_3['defrost7']
    pre_power[30] = data_barrel_3['defrost8']
    pre_power[31] = data_barrel_4['defrost1']
    pre_power[32] = data_barrel_4['defrost2']
    pre_power[33] = data_barrel_4['defrost3']
    pre_power[34] = data_barrel_4['defrost4']
    pre_power[35] = data_barrel_4['defrost5']
    pre_power[36] = data_barrel_4['defrost6']
    pre_power[37] = data_barrel_4['defrost7']
    pre_power[38] = data_barrel_4['defrost8']
    pre_power[39] = data_app['powersavermode']
    pre_power[40] = data_app['control_temp_enable']

    for i = 1, 40 do
        pupfile:write(pre_power[i])
        if (i ~= 40) then
            pupfile:write(',')
        end
    end
    pupfile:write('\n')
    pupfile:close()

    print('Saved Powerup csv file')

    -- os.execute('sync')

end

function SaveConfigCSV(mpargs)
    local config_attrs = {}
    local pre_data = {}
    config_attrs.textDB = gre.APP_ROOT .. '/configurations/configurations.csv'
    local configfile = io.open(config_attrs.textDB, 'w')

    if (configfile == nil) then
        return nil, string.format('Can not access database file %s', config_attrs.textDB)
    end

    -- SaveConfigValue(mpargs)

    pre_data[1] = data_app['bom']
    pre_data[2] = data_app['serialnumber']
    pre_data[3] = data_app['storeid']
    pre_data[4] = data_app['standbytempmin']
    pre_data[5] = data_app['standbytempmax']
    pre_data[6] = data_app['compressorondelay']
    pre_data[7] = data_app['holdofftime']
    pre_data[8] = data_app['fanholdtime']
    pre_data[9] = data_barrel_1['visc_hyst']
    pre_data[10] = data_barrel_1['visc_cutout']
    pre_data[11] = data_barrel_1['pressure_hyst']
    pre_data[12] = data_barrel_1['pressure_set']
    pre_data[13] = data_barrel_2['visc_hyst']
    pre_data[14] = data_barrel_2['visc_cutout']
    pre_data[15] = data_barrel_2['pressure_hyst']
    pre_data[16] = data_barrel_2['pressure_set']
    pre_data[17] = data_barrel_3['visc_hyst']
    pre_data[18] = data_barrel_3['visc_cutout']
    pre_data[19] = data_barrel_3['pressure_hyst']
    pre_data[20] = data_barrel_3['pressure_set']
    pre_data[21] = data_barrel_4['visc_hyst']
    pre_data[22] = data_barrel_4['visc_cutout']
    pre_data[23] = data_barrel_4['pressure_hyst']
    pre_data[24] = data_barrel_4['pressure_set']

    for i = 1, 24 do
        configfile:write(pre_data[i])
        if (i ~= 24) then
            configfile:write(',')
        end
    end
    configfile:write('\n')
    configfile:close()

    print('Saved Configurations csv file')

    os.execute('sync')

end

function UpdateUIInfo()

    gre.set_value('system_info_layer.card_system_info_group.info_Control_BOM.text', data_app['bom'])
    gre.set_value('system_info_layer.card_system_info_group.info_SerialNumber.text', data_app['serialnumber'])

    gre.set_value('Configuration_layer.BOM_control.text', data_app['bom'])
    gre.set_value('Configuration_layer.SerialNumber_control.text', data_app['serialnumber'])
    gre.set_value('Configuration_layer.StoreID_control.text', data_app['storeid'])

    gre.set_value('configurationBOM_input.configuration_Input_BOM_group.input_active_control.text', data_app['bom'])
    gre.set_value('configuration_SERIAL_NUMBER_input.configuration_Input_serial_number_group.input_active_control.text',
        data_app['serialnumber'])
    gre.set_value('configuration_STORE_ID_input.configuration_Input_serial_number_group1.input_active_control.text',
        data_app['storeid'])

    SetCurrentStandbyTemp()
    DispayCurrentStandbyTemp()

    setCompressorTimes()
    DisplayCompressorTimes()

    setFanHoldTime(mapargs)
    DisplayFanHoldTime()

    DispayCurrentViscosity()
    DispayCurrentPressure()

end

function RestoreConfigUI(mpargs)
    local config_attrs = {}
    config_attrs.textDB = gre.APP_ROOT .. '/configurations/configurations.csv'
    ReConfiguration = ConfigLoader.CreateLoader(config_attrs)

    -- Initflag == 1 normal status  Initflag == 0 start save default value data to modbus server(UVC4) and verify it
    Initflag = 0
    RestoreConfigValue(mpargs)

    UpdateUIInfo()

    print('Restore Configurations to UI')

    -- SendBOM()
    -- SendBOMVerify()
    -- Start send BOM and Verify
    idval_str = nil
    idval_str = gre.timer_set_interval(SendBOMVerify, 900)

    -- print('Sent BOM to Brix_Backend then through modbus to UVC4 board!')

    -- SendSerial()

    -- print('Sent Serial Number to Brix_Backend then through modbus to UVC4 board!')

    -- SendStoreId()

    -- print('Sent Store ID to Brix_Backend then through modbus to UVC4 board!')

    -- SendStandbyTemp()

    -- print('Sent Standby Temp Max/Min to Brix_Backend then through modbus to UVC4 board!')

    -- SendCompressor()

    -- print('Sent Compressor Delay/Hold Time to Brix_Backend then through modbus to UVC4 board!')

    -- SendFanHold()

    -- print('Sent Fan Hold Time to Brix_Backend then through modbus to UVC4 board!')

    -- SendBarrelSettings(1)

    -- print('Sent Barrel 1 Settings to Brix_Backend then through modbus to UVC4 board!')

    -- SendBarrelSettings(2)

    -- print('Sent Barrel 2 Settings to Brix_Backend then through modbus to UVC4 board!')

    -- SendBarrelSettings(3)

    -- print('Sent Barrel 3 Settings to Brix_Backend then through modbus to UVC4 board!')

    -- SendBarrelSettings(4)

    -- print('Sent Barrel 4 Settings to Brix_Backend then through modbus to UVC4 board!')

end

function RequestVoltage()
    gre.send_event_data('brixui_request_command', '2u1 brixui_command', {
        brixui_command = 8383
    }, gBackendChannel)
end

--- @param gre#context mapargs
function CBUpdateData8383(mpargs)

    local ev_data = mpargs.context_event_data
    local app_linevoltage = ev_data.line_voltage
    if (app_linevoltage ~= nil) then
        data_app['voltage'] = ev_data.line_voltage
        data_app['voltage_flag'] = 1
        SetVoltage()
    else
        data_app['voltage_flag'] = 0
    end

    if (data_app['voltage_flag'] == 1) then
        gre.timer_clear_interval(idval_vol)
        idval_vol = nil
    end
end

function SetVoltage()

    -- Add the voltage to the current conditions text
    ccTest = gre.get_value('current_conditions_layer.Current_Conditions.text')
    gre.set_value('current_conditions_layer.Current_Conditions.text', ccTest ..
        '                                                                     ' .. data_app['voltage'])

end

function SentEpochTime()
    --  local epoch_second;
    --  epoch_second = os.time()
    --  print(epoch_second)
    --  gre.send_event_data (
    --    'brixui_epoch_time',
    --    '4u1 epoch_time',
    --    {epoch_time = epoch_second},
    --    gBackendChannel
    --  )
    --
    --  print('Epoch Time Sent')

    SendTimetoUVC4()
end

function SendTimetoUVC4()
    local sec16 = os.date('%S')
    local min16 = os.date('%M')
    local hour16 = os.date('%H')
    local day16 = os.date('%d')
    local mon16 = os.date('%m')
    local year16 = os.date('%Y')
    local dow16 = os.date('%w')
    local doy16 = 0

    print('UVC4 Time')
    print(sec16)
    print(min16)
    print(hour16)
    print(day16)
    print(mon16)
    print(year16)
    print(dow16)
    print(doy16)

    gre.send_event_data('brixui_uvc4_time',
        '2u1 uvc4_sec 2u1 uvc4_min 2u1 uvc4_hour 2u1 uvc4_day 2u1 uvc4_month 2u1 uvc4_year 2u1 uvc4_dow 2u1 uvc4_doy',
        {
            uvc4_sec = sec16,
            uvc4_min = min16,
            uvc4_hour = hour16,
            uvc4_day = day16,
            uvc4_month = mon16,
            uvc4_year = year16,
            uvc4_dow = dow16,
            uvc4_doy = doy16
        }, gBackendChannel)
end
