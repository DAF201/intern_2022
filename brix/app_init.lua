function echo(string)
    print(string)
    os.execute("echo " .. string .. '>/dev/ttySC0')
end

-- function gre_event_test()
--    while (1) do
--    local ev = gre.receive_event("BrixChannelIn")
--        echo(ev.name)
--    end
-- end

function AppStart(mpargs)

    os.execute("ifconfig eth0 192.168.1.222 netmask 255.255.255.0")
    gre.thread_create(clock)

    --        print(_VERSION)

    local dk_data = {}

    -- print("App Start")

    -- Set all the defaults from hardcoded values
    InitValues(mpargs)

    -- Get the values of locally saved variabes from the powerup.csv file
    PowerupValue()
    updateTime()
    -- Timer to update time and date on screen
    callback_register("updateTime", updateTime, 1) -- miliseconds - every half second

    -- Trigger the power saver on off animation based on the saved values so it is correct on the screen
    power_save_anim_init()

    -- Timer to check the defrost times
    --  callback_register("defrostCheck",defrostCheck, 60) -- miliseconds - every minute -
    -- we can not allow this to trigger less ore more than once a minute but it must trigger every minute

    -- Timer to check beep status
    callback_register("beepSilenceCheck", beepSilenceCheck, 60) -- miliseconds - every minute - 

    -- Set initial values into the UI controls
    DispayCurrentStandbyTemp();
    DisplayPowerSaver()
    DisplayCompressorTimes()

    -- Get the UVC4 version
    --  idval_str = callback_register("RequestVersion",RequestVersion, 2)

    -- This call puts the BOM, SN, Model, UVC4 Version, Store Id into the UI elements
    SetSystemInfo()

    -- Get the brix_backend version
    if (is_dev == 0) then
        idval_bac = callback_register("RequestBrixBackendVersion", RequestBrixBackendVersion, 1)
    end

    -- Get the voltage
    idval_vol = callback_register("RequestVoltage", RequestVoltage, 1)

    -- If this is a development install, auto close the init screen so the UI does not get stuck there
    -- print(is_dev)
    if is_dev ~= 0 then
        print("init dev")
        idval_init = callback_register("initEndTest", initEndTest, 4)
    end

    --  test_json=io.open("config.json","r")
    --  io.input(test_json)
    --  string_json=io.read("*all")
    --  io.close(test_json)
    --  print(string_json)

    --  test_json_table=json.parse(string_json)
    --  test_json_table.language = "1"

    --  new_test_json_table=json.stringify(test_json_table)
    --  config_file=io.open("config.json","w")
    --  io.output(config_file)
    --  io.write(new_test_json_table)
    --  io.close(config_file)

    --  print(test_json_table.language)

    --    gre.thread_create(gre_event_test)

    ---- fifo is too slow

    --    gre.thread_create(fifo_read)

    --  callback_register('echo', echo, 1, "1 s test")
    callback_register('modbus_send_40003', modbus_send, 1, 40003) -- dont change the time of 40003-40008
    callback_register('modbus_send_40004', modbus_send, 2, 40004) -- getting info for home screen
    callback_register('modbus_send_40005', modbus_send, 2, 40005) -- will be removed after the first reciving
    callback_register('modbus_send_40008', modbus_send, 4, 40008)

    callback_register('modbus_send_40051', modbus_send, 5, 40051) -- UVC4 version 
    callback_register('modbus_send_40052', modbus_send, 5, 40052)
    callback_register('modbus_send_40053', modbus_send, 5, 40053)
    callback_register('modbus_send_40054', modbus_send, 5, 40054)
    callback_register('modbus_send_40055', modbus_send, 5, 40055)
    --    callback_register('screen',current_screen,4)
    --    callback_register('modbus_send_40012', modbus_send, 5, 40012)--remaining parts of barrel seems not yet finished

    --  gre.timer_set_interval(test_send,1000)
end

function current_screen()
    echo(gre.env('active_screen'))
end

function fifo_read()
    test = io.open("/opt/middleby/brix/modbus_up", "r")
    if test == nil then
        echo("file empty")
    end
    io.input(test)
    while 1 do
        string_value = io.read(4)
        if string_value ~= nil then
            echo("modbus data is : " .. string_value)
        else
            echo("file is temporary empty")
        end
    end
    io.close(test)
end
