---@generic modbus_request #general function to request value(s) from register
---@param address number#address of register
---@param size number#number of register to request
function modbus_request(address, size)
    size = size or 1
    gre.send_event_data('modbus_r', '2u1 addr 2u1 size', {
        addr = address,
        size = size
    }, gBackendChannel)
    --    echo('sending '..dump({address}))
end

---@generic modbus_post #general function to post value
---@param address number#address of register
---@param size number#number of register to post
---@param data string#data to post
function modbus_post(address, size, data)
    gre.send_event_data('modbus_p', '2u1 addr 2u1 regi_size 1s0 value', {
        addr = address,
        regi_size = size,
        value = data
    }, gBackendChannel)
end

-- TODO

---@type table : to store the address of the register, using path as key 
action_register_map = {}

---@generic value_add_sub #general function for sub and add by one
---@param mapargs table#table of arguements from UI
function value_add_sub(mapargs)
    local new_value = gre.get_value("original_value") or '0'
    local manipulation_type = mapargs.type
    local path = mapargs.path
    local max = mapargs.max
    local min = mapargs.min

    if manipulation_type == 'sub' or '-' then
        if new_value - 1 < min then
            new_value = new_value
        else
            new_value = new_value - 1
        end
    else
        if new_value + 1 > max then
            new_value = new_value
        else
            new_value = new_value + 1
        end
    end

    gre.send_event_data('modbus_p', '2u1 addr 2u1 regi_size 1s0 value', {
        addr = action_register_map[path],
        regi_size = 1,
        value = new_value
    }, gBackendChannel)

    echo("event data posted via add/sub: " .. dump(mapargs))
end

---@generic value_enter_post #general function for post value entered by keypad to register
---@param mapargs table#table of arguements from UI
function value_enter_post(mapargs)
    local path = gre.get_value("target_path")
    local new_value = gre.get_value(path)

    gre.send_event_data('modbus_p', '2u1 addr 2u1 regi_size 1s0 value', {
        addr = action_register_map[path],
        regi_size = 1,
        value = new_value
    }, gBackendChannel)

    echo("event data posted via keypad: " .. dump(mapargs))
end

-- END TODO

---@generic modbus_return #general function recieved events
---@param mapargs table#table of data of the event
function modbus_return(mapargs)
    local splited_data = split(mapargs.context_event_data.modbus_read_data, ',')
    -- display
    echo(dump(splited_data))
    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. splited_data[2])
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. (splited_data[3]))
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'raw data: ' .. dump(splited_data))
    -- end of display
    homescreenupdate() -- update screen
    modbus_return_execute(splited_data) -- execute/data analysis
end

---@generic dump #table to string for echo to print
---@param o table#target table
---@return string
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

---@generic split #split string to table
---@param s string#string to split
---@param delimiter string# string to split by
---@return table
function split(s, delimiter)
    result = {};
    for match in (s .. delimiter):gmatch('(.-)' .. delimiter) do
        table.insert(result, match);
    end
    return result;
end

---@generic tobin #convert decimal to hex then to bin string
---@param x number #input number, decimal
---@return string
function tobin(x)
    ret = ''
    while x ~= 1 and x ~= 0 do
        ret = tostring(x % 2) .. ret
        x = math.modf(x / 2)
    end
    ret = tostring(x) .. ret
    while (#ret < 16) do
        ret = '0' .. ret
    end
    return ret
end

---@generic all #check if all value in table are true
---@param tab table #input table of boolean
---@return boolean
function all(tab)
    for k, v in pairs(tab) do
        if v == false then
            return false
        end
    end
    return true
end

---@type table #for those request only need to be recieved once
reciving_flags = {
    [40003] = false,
    [40004] = false,
    [40005] = false,
    [40046] = false,
    [40051] = false,
    [40056] = false,
    [40063] = false,
    [40068] = false,
    [40072] = false
}

---@generic modbus_return_execute #execute event #Crank does not work too well with table of function...
---@param splited_data table# table of splited data
function modbus_return_execute(splited_data)
    if splited_data[1] == '40003' then
        data_app['barrelcount'] = tonumber(tobin(splited_data[3]):sub(10, 12), 2)
        data_app['language'] = tonumber(tobin(splited_data[3]):sub(3, 7), 2)
        data_app['time_from_cloud'] = tonumber(tobin(splited_data[3]):sub(8, 8), 2)
        data_app['compressor'] = tonumber(tobin(splited_data[3]):sub(9, 9), 2)

        reciving_flags[40003] = true
        callback_unregister('modbus_request_40003')
        BarrelSetup() -- update barrel UI

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'barrel count')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        return
    end

    if splited_data[1] == '40004' then
        data_app['uvc4complete'] = tonumber(tobin(splited_data[3]):sub(12, 12), 2)
        data_app['uvc4failed'] = tonumber(tobin(splited_data[3]):sub(11, 11), 2)
        reciving_flags[40004] = true

        callback_unregister('modbus_request_40004')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC4 update')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        return
    end

    if splited_data[1] == '40005' then
        data_app['voltage'] = tonumber(tobin(splited_data[3]), 2)
        callback_unregister('modbus_request_40005')
        reciving_flags[40005] = true

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'Voltage')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        return
    end

    if splited_data[1] == '40006' then
        if splited_data[2] ~= '16' then
            return
        end

        if tonumber(tobin(splited_data[5]):sub(5, 5), 2) == 0 then -- 40008
            data_app['co2'] = 1
        else
            data_app['co2'] = 0
        end

        if tonumber(tobin(splited_data[5]):sub(4, 4), 2) == 0 then -- 40008
            data_app['h2o'] = 1
        else
            data_app['h2o'] = 0
        end

        if tonumber(tobin(splited_data[5]):sub(6, 6), 2) == 0 then -- 40008
            data_app['pressurecutout'] = 1
        else
            data_app['pressurecutout'] = 0
        end

        if tonumber(tobin(splited_data[3]), 2) then
            data_barrel_1["viscosity"] = tonumber(tobin(splited_data[3]), 2)
        end

        if tonumber(tobin(splited_data[4]), 2) then
            data_barrel_1["temp"] = tonumber(tobin(splited_data[4]), 2)
        end

        if tonumber(tobin(splited_data[6]), 2) then
            data_barrel_1["pressure_act"] = tonumber(tobin(splited_data[6]), 2)
        end

        if tonumber(tobin(splited_data[7]), 2) then
            data_barrel_2["viscosity"] = tonumber(tobin(splited_data[7]), 2)
        end

        if tonumber(tobin(splited_data[8]), 2) then
            data_barrel_2["temp"] = tonumber(tobin(splited_data[8]), 2)
        end

        if tonumber(tobin(splited_data[10]), 2) then
            data_barrel_2["pressure_act"] = tonumber(tobin(splited_data[10]), 2)
        end

        if tonumber(tobin(splited_data[11]), 2) then
            data_barrel_3["viscosity"] = tonumber(tobin(splited_data[11]), 2)
        end

        if tonumber(tobin(splited_data[12]), 2) then
            data_barrel_3["temp"] = tonumber(tobin(splited_data[12]), 2)
        end

        if tonumber(tobin(splited_data[14]), 2) then
            data_barrel_3["pressure_act"] = tonumber(tobin(splited_data[14]), 2)
        end

        if tonumber(tobin(splited_data[15]), 2) then
            data_barrel_4["viscosity"] = tonumber(tobin(splited_data[15]), 2)
        end

        if tonumber(tobin(splited_data[16]), 2) then
            data_barrel_4["temp"] = tonumber(tobin(splited_data[16]), 2)
        end

        if tonumber(tobin(splited_data[18]), 2) then
            data_barrel_4["pressure_act"] = tonumber(tobin(splited_data[18]), 2)
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'CO2 H2O Pressure')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'repeating, interval:4')

        return
    end

    if splited_data[1] == '40022' then
        if splited_data[2] ~= '16' then
            return
        end

        if tonumber(tobin(splited_data[3]), 2) then
            data_barrel_1["visc_hyst"] = tonumber(tobin(splited_data[3]), 2)
        end

        if tonumber(tobin(splited_data[4]), 2) then
            data_barrel_1["visc_cutout"] = tonumber(tobin(splited_data[4]), 2)
        end

        if tonumber(tobin(splited_data[5]), 2) then
            data_barrel_1["pressure_hyst"] = tonumber(tobin(splited_data[5]), 2)
        end

        if tonumber(tobin(splited_data[6]), 2) then
            data_barrel_1["pressure_set"] = tonumber(tobin(splited_data[6]), 2)
        end

        if tonumber(tobin(splited_data[7]), 2) then
            data_barrel_2["visc_hyst"] = tonumber(tobin(splited_data[7]), 2)
        end

        if tonumber(tobin(splited_data[8]), 2) then
            data_barrel_2["visc_cutout"] = tonumber(tobin(splited_data[8]), 2)
        end

        if tonumber(tobin(splited_data[9]), 2) then
            data_barrel_2["pressure_hyst"] = tonumber(tobin(splited_data[9]), 2)
        end

        if tonumber(tobin(splited_data[10]), 2) then
            data_barrel_2["pressure_set"] = tonumber(tobin(splited_data[10]), 2)
        end

        if tonumber(tobin(splited_data[11]), 2) then
            data_barrel_3["visc_hyst"] = tonumber(tobin(splited_data[11]), 2)
        end

        if tonumber(tobin(splited_data[12]), 2) then
            data_barrel_3["visc_cutout"] = tonumber(tobin(splited_data[12]), 2)
        end

        if tonumber(tobin(splited_data[13]), 2) then
            data_barrel_3["pressure_hyst"] = tonumber(tobin(splited_data[13]), 2)
        end

        if tonumber(tobin(splited_data[14]), 2) then
            data_barrel_3["pressure_set"] = tonumber(tobin(splited_data[14]), 2)
        end

        if tonumber(tobin(splited_data[15]), 2) then
            data_barrel_3["visc_hyst"] = tonumber(tobin(splited_data[15]), 2)
        end

        if tonumber(tobin(splited_data[16]), 2) then
            data_barrel_3["visc_cutout"] = tonumber(tobin(splited_data[16]), 2)
        end

        if tonumber(tobin(splited_data[17]), 2) then
            data_barrel_3["pressure_hyst"] = tonumber(tobin(splited_data[17]), 2)
        end

        if tonumber(tobin(splited_data[18]), 2) then
            data_barrel_3["pressure_set"] = tonumber(tobin(splited_data[18]), 2)
        end

        return
    end

    if splited_data[1] == '40046' then
        data_app["standbytempmax"] = tonumber(tobin(splited_data[3]):sub(1, 8), 2)
        data_app["standbytempmin"] = tonumber(tobin(splited_data[3]):sub(9, 16), 2)
        callback_unregister('modbus_request_40046')
        reciving_flags[40046] = true
        return
    end

    if splited_data[1] == '40047' then
        if splited_data[2] ~= '4' then
            return
        end

        data_barrel_1["servings"] = tonumber(tobin(splited_data[3]), 2)
        data_barrel_2["servings"] = tonumber(tobin(splited_data[4]), 2)
        data_barrel_3["servings"] = tonumber(tobin(splited_data[4]), 2)
        data_barrel_4["servings"] = tonumber(tobin(splited_data[5]), 2)
    end

    if splited_data[1] == '40051' then
        if splited_data[2] ~= '5' then
            return
        end

        local received_string = ''
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(9, 16), 2))
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(1, 8), 2))
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'UVC4 version: ' .. received_string)
        gre.set_value('TEXT_BACKGROUND.bg.line6', '')
        data_app['uvc4version'] = received_string
        callback_unregister('modbus_request_40051')
        reciving_flags[40051] = true

        return
    end

    if splited_data[1] == '40056' then
        if splited_data[2] ~= '7' then
            return
        end

        local received_string = ''
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(9, 16), 2))
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(1, 8), 2))
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'Model: ' .. received_string)
        gre.set_value('TEXT_BACKGROUND.bg.line6', '')
        data_app['model'] = received_string
        callback_unregister('modbus_request_40056')
        reciving_flags[40056] = true

        return

    end

    if splited_data[1] == '40063' then
        if splited_data[2] ~= '5' then
            return
        end

        local received_string = ''
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(9, 16), 2))
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(1, 8), 2))
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'BOM: ' .. received_string)
        gre.set_value('TEXT_BACKGROUND.bg.line6', '')
        data_app['bom'] = received_string
        callback_unregister('modbus_request_40063')
        reciving_flags[40063] = true

        return

    end

    if splited_data[1] == '40068' then
        if splited_data[2] ~= '4' then
            return
        end

        local received_string = ''
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(9, 16), 2))
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(1, 8), 2))
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'SN: ' .. received_string)
        gre.set_value('TEXT_BACKGROUND.bg.line6', '')
        data_app['serialnumber'] = received_string
        callback_unregister('modbus_request_40068')
        reciving_flags[40068] = true

        return

    end

    if splited_data[1] == '40072' then
        if splited_data[2] ~= '3' then
            return
        end

        local received_string = ''
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(9, 16), 2))
            received_string = received_string .. string.char(tonumber(tobin(splited_data[i]):sub(1, 8), 2))
        end

        gre.set_value('TEXT_BACKGROUND.bg.line5', 'Store ID: ' .. received_string)
        gre.set_value('TEXT_BACKGROUND.bg.line6', '')
        data_app['storeid'] = received_string
        callback_unregister('modbus_request_40072')
        reciving_flags[40072] = true

        return

    end

    if splited_data[1] == '40075' then
        if splited_data[2] ~= '4' then
            return
        end

        callback_unregister('modbus_request_40075')
        local barrel_counter = 1
        local data = tobin(splited_data[i])
        for i = 3, #splited_data, 1 do
            if i > #splited_data then
                break
            end

            _G['data_barrel_' .. tostring(barrel_counter)]['servings'] = data:sub(7, 7)
            _G['data_barrel_' .. tostring(barrel_counter)]['fan'] = data:sub(8, 8)
            _G['data_barrel_' .. tostring(barrel_counter)]['compressor'] = data:sub(9, 9)
            _G['data_barrel_' .. tostring(barrel_counter)]['beater motor'] = data:sub(10, 10)
            _G['data_barrel_' .. tostring(barrel_counter)]['liquid_s'] = data:sub(11, 11)
            _G['data_barrel_' .. tostring(barrel_counter)]['co2_s'] = data:sub(12, 12)
            _G['data_barrel_' .. tostring(barrel_counter)]['syrup_s'] = data:sub(13, 13)
            _G['data_barrel_' .. tostring(barrel_counter)]['h2o_s'] = data:sub(14, 14)
            _G['data_barrel_' .. tostring(barrel_counter)]['light'] = data:sub(15, 15)
            _G['data_barrel_' .. tostring(barrel_counter)]['defrost'] = data:sub(16, 16)
            barrel_counter = barrel_counter + 1
        end
        return
    end

    if splited_data[1] == '40084' then
        if splited_data[2] ~= '8' then
            return
        end

        local sec = tonumber(tobin(splited_data[3]), 2)
        local min = tonumber(tobin(splited_data[4]), 2)
        local hour = tonumber(tobin(splited_data[5]), 2)
        local date = tonumber(tobin(splited_data[6]), 2)
        local month = tonumber(tobin(splited_data[7]), 2)
        local year = tonumber(tobin(splited_data[8]), 2)
        local weekday = tonumber(tobin(splited_data[9]), 2)
        local year_date = tonumber(tobin(splited_data[10]), 2)

        os.execute(
            'timedatectl set-time "' .. year .. '-' .. month .. '-' .. date .. ' ' .. hour .. ':' .. min .. ':' .. sec)
        callback_unregister('modbus_request_40084')
    end

    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'hex data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'unknown')

end

