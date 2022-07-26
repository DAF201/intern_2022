function modbus_send(address, size)
    size = size or 1
    gre.send_event_data('modbus_r', '2u1 addr 2u1 size', {
        addr = address,
        size = size
    }, gBackendChannel)
    echo('sending modbus event to register: ' .. tostring(address))
end

--- @param gre#context mapargs
function modbus_return(mapargs)
    local splited_data = split(mapargs.context_event_data.modbus_read_data, ',')
    --    echo(dump(splited_data))
    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. splited_data[2])
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. (splited_data[3]))
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'raw data: ' .. dump(splited_data))

    modbus_return_execute(splited_data)

end

-- check what was returned, and call the right function for it, tab:table

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

function split(s, delimiter)
    result = {};
    for match in (s .. delimiter):gmatch('(.-)' .. delimiter) do
        table.insert(result, match);
    end
    return result;
end

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

function modbus_return_execute(splited_data)
    if splited_data[1] == '40003' then
        data_app['barrelcount'] = tonumber(tobin(splited_data[3]), 2)
        callback_unregister('modbus_send_40003')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'barrel count')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
--        home_screen_update()
        return
    end

    if splited_data[1] == '40004' then
        data_app['uvc4complete'] = tonumber(tobin(splited_data[3]):sub(12, 12), 2)
        data_app['uvc4failed'] = tonumber(tobin(splited_data[3]):sub(11, 11), 2)
        callback_unregister('modbus_send_40004')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC4 update')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        return
    end

    if splited_data[1] == '40005' then
        data_app['voltage'] = tonumber(tobin(splited_data[3]), 2)
        callback_unregister('modbus_send_40005')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'Voltage')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        return
    end

    if splited_data[1] == '40006' then 
        if tonumber(tobin(splited_data[5]):sub(5, 5), 2) == 0 then
            data_app['co2'] = 1
        else
            data_app['co2'] = 0
        end

        if tonumber(tobin(splited_data[5]):sub(4, 4), 2) then
            data_app['h2o'] = 1
        else
            data_app['h2o'] = 0
        end

        if tonumber(tobin(splited_data[5]):sub(6, 6), 2) then
            data_app['pressurecutout'] = 1
        else
            data_app['pressurecutout'] = 0
        end
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'CO2 H2O Pressure')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'repeating, interval:4')
        return
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
        callback_unregister('modbus_send_40051')
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
        callback_unregister('modbus_send_40056')
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
        callback_unregister('modbus_send_40063')
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
        callback_unregister('modbus_send_40068')
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
        callback_unregister('modbus_send_40072')
        return

    end

    if splited_data[1] == '40075' then
        if splited_data[2] ~= '4' then
            return
        end

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
    end

    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'hex data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'unknown')

end
