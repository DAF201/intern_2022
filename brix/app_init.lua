---@generic echo function #to display something on linux terminal/serial port
---@param string string #string to print
function echo(string)
    print(string)
    os.execute('echo ' .. string .. '>/dev/ttySC0')
end

-- reciving test
-- function gre_event_test()
--    while (1) do
--    local ev = gre.receive_event('BrixChannelIn')
--        echo(ev.name)
--    end
-- end

---@generic AppStart function #start up function of the system
function AppStart(mpargs)
    -- set the ip 
    os.execute('ifconfig eth0 192.168.1.222 netmask 255.255.255.0')
    -- set clock to start
    gre.timer_set_interval(clock, 1000)

    -- NOT mine

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

    -- END of NOT mine

    --  fifo test and jsonfy test
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

    --  callback register test
    --  callback_register('echo', echo, 1, '1 s test')

    callback_register('modbus_request_40003', modbus_request, 1, 40003) -- homescreen info registers
    callback_register('modbus_request_40004', modbus_request, 2, 40004) -- dont change the time of 40003-40005
    callback_register('modbus_request_40005', modbus_request, 2, 40005)

    callback_register('modbus_request_40046', modbus_request, 2, 40046) -- temperature range (looks like the register is not returning correct data)

    callback_register('modbus_request_40051', modbus_request, 4, 40051, 5) -- backend info like serial number and such things registers
    callback_register('modbus_request_40056', modbus_request, 4, 40056, 7)
    callback_register('modbus_request_40063', modbus_request, 4, 40063, 5)
    callback_register('modbus_request_40068', modbus_request, 4, 40068, 4)
    callback_register('modbus_request_40072', modbus_request, 4, 40072, 3)
    callback_register('modbus_request_40075', modbus_request, 5, 40075, 4)

    callback_register('init_statu', init_statu, 5) -- init finish check

end

function init_statu() -- init check
    --    echo(dump(reciving_flags)) --init flags
    if all(reciving_flags) then
        callback_unregister('init_statu')
        local dk_data = {};
        dk_data = gre.get_layer_attrs('commFailLayer')
        dk_data['hidden'] = 1
        gre.set_layer_attrs('commFailLayer', dk_data)--hide the init screen

        -- staring the remaining register requests(which will not stop by themselves)
        callback_register('modbus_request_40022', modbus_request, 3, 40022, 16) -- hystersis and cutout data
        callback_register('modbus_request_40006', modbus_request, 3, 40006, 16) -- reading the values suach as the temperature and pressure
        callback_register('modbus_request_40047', modbus_request, 3, 40047, 4) -- serving counter of barrels
    end
end

---@generic fifo_read function # read fifo to get event #too slow and abandoned
function fifo_read() -- test use, for fifo
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
        -- case balabala :break
    end
    io.close(test)
end
