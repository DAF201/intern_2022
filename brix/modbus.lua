--this ugly thing worked...
init_ready_flags = { -- use the all function to check if fully init
    ['40003'] = false,
    ['40004'] = false,
    ['40005'] = false,
    ['UVC4_version'] = false
}
function modbus_send(address)
    gre.send_event_data('modbus_r', '2u1 addr 2u1 size', {
        addr = address,
        size = 1
    }, gBackendChannel)
end

function modbus_return(mapargs)
    local splited_data = split(mapargs.context_event_data.modbus_read_data, ',')
    --    echo(dump(splited_data))
    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. splited_data[2])
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. tobin(splited_data[3]))
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'raw data: ' .. splited_data[3])

    modbus_return_excute(splited_data)
    if gre.env('active_screen') == 'Home_Screen' then
        home_screen_update()
        echo('updating screen')
    end

end

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

function all(tab)
    for k, v in pairs(tab) do
        if v == false then
            return false
        end
    end
    return true
end

UVC4_version = '1234567890'
UVC4_version_flag = {false, false, false, false, false}
UVC4_name_table = {}

function update_UVC4_version()
    data_app["uvc4version"] = ''
    for k, v in pairs(UVC4_name_table) do
        data_app["uvc4version"] = data_app["uvc4version"] .. v
    end
    gre.set_value("TEXT_BACKGROUND.bg.line7", data_app["uvc4version"])
    UVC4_name_table = {}
    return
end

function modbus_return_excute(splited_data)
    if splited_data[1] == '40003' then
        data_app['barrelcount'] = tonumber(tobin(splited_data[3]), 2)
        callback_unregister('modbus_send_40003')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'barrel count')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
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
        return
    end

    if splited_data[1] == '40007' then
        return
    end

    if splited_data[1] == '40008' then
        -- TODO find where is the power thing of barrel and such things
        local data = splited_data[3]
        if tonumber(tobin(splited_data[3]):sub(5, 5), 2) == 0 then
            data_app['co2'] = 1
        else
            data_app['co2'] = 0
        end

        if tonumber(tobin(splited_data[3]):sub(4, 4), 2) then
            data_app['h2o'] = 1
        else
            data_app['h2o'] = 0
        end

        if tonumber(tobin(splited_data[3]):sub(6, 6), 2) then
            data_app['pressurecutout'] = 1
        else
            data_app['pressurecutout'] = 0
        end
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'CO2 H2O Pressure')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'repeating, interval:4')
        return
    end

    -- UVC4_version = '1234567890'
    -- UVC4_version_flag = { false, false, false, false, false }
    -- UVC4_name_table = {}

    if splited_data[1] == '40051' then
        UVC4_name_table[1] = string.char(tonumber(tobin(splited_data[3]):sub(9, 16), 2))
        UVC4_name_table[2] = string.char(tonumber(tobin(splited_data[3]):sub(1, 8), 2))
        UVC4_version_flag[1] = true
        callback_unregister('modbus_send_40051')
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC_V_12')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        if all(UVC4_version_flag) then
            update_UVC4_version()
        end
        return
    end

    if splited_data[1] == '40052' then
        UVC4_name_table[3] = string.char(tonumber(tobin(splited_data[3]):sub(9, 16), 2))
        UVC4_name_table[4] = string.char(tonumber(tobin(splited_data[3]):sub(1, 8), 2))
        UVC4_version_flag[2] = true
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC_V_34')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        callback_unregister('modbus_send_40052')
        if all(UVC4_version_flag) then
            update_UVC4_version()
        end
        return
    end

    if splited_data[1] == '40053' then
        UVC4_name_table[5] = string.char(tonumber(tobin(splited_data[3]):sub(9, 16), 2))
        UVC4_name_table[6] = string.char(tonumber(tobin(splited_data[3]):sub(1, 8), 2))
        UVC4_version_flag[3] = true
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC_V_56')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        callback_unregister('modbus_send_40053')
        if all(UVC4_version_flag) then
            update_UVC4_version()
        end
        return
    end

    if splited_data[1] == '40054' then
        UVC4_name_table[7] = string.char(tonumber(tobin(splited_data[3]):sub(9, 16), 2))
        UVC4_name_table[8] = string.char(tonumber(tobin(splited_data[3]):sub(1, 8), 2))
        UVC4_version_flag[4] = true
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC_V_78')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        callback_unregister('modbus_send_40054')
        if all(UVC4_version_flag) then
            update_UVC4_version()
        end
        return
    end

    if splited_data[1] == '40055' then
        UVC4_name_table[9] = string.char(tonumber(tobin(splited_data[3]):sub(9, 16), 2))
        UVC4_name_table[10] = string.char(tonumber(tobin(splited_data[3]):sub(1, 8), 2))
        UVC4_version_flag[5] = true
        gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'UVC_V_90')
        gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'one time')
        callback_unregister('modbus_send_40055')
        if all(UVC4_version_flag) then
            update_UVC4_version()
        end
        return
    end

    -- default

    gre.set_value('TEXT_BACKGROUND.bg.line1', 'register: ' .. splited_data[1])
    gre.set_value('TEXT_BACKGROUND.bg.line2', 'size: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line3', 'binary data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line4', 'hex data: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line5', 'target: ' .. 'unknown')
    gre.set_value('TEXT_BACKGROUND.bg.line6', 'callback type: ' .. 'unknown')

end
