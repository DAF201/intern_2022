--this ugly thing worked...
function modbus_send(address)
	gre.send_event_data("modbus_r", "2u1 addr 2u1 size", {
		addr = address,
		size = 1
	}, gBackendChannel)
end

--- @param gre#context mapargs
function modbus_return(mapargs)
	local splited_data = split(mapargs.context_event_data.modbus_read_data, ',')
	--    echo(dump(splited_data))
	gre.set_value("TEXT_BACKGROUND.bg.line1", splited_data[1])
	gre.set_value("TEXT_BACKGROUND.bg.line2", splited_data[2])
	gre.set_value("TEXT_BACKGROUND.bg.line3", tobin(splited_data[3]))

	modbus_return_excute(splited_data)


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
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match);
	end
	return result;
end

function tobin(x)
	ret = ""
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

function modbus_return_excute(splited_data)
	if splited_data[1] == '40003' then
		data_app["barrelcount"] = tonumber(tobin(splited_data[3]), 2)
		callback_unregister('modbus_send_40003')
		return
	end

	if splited_data[1] == "40004" then
		data_app['uvc4complete'] = tonumber(tobin(splited_data[3]):sub(12, 12), 2)
		data_app["uvc4failed"] = tonumber(tobin(splited_data[3]):sub(11, 11), 2)
		callback_unregister('modbus_send_40004')
	end

	if splited_data[1] == "40005" then
		data_app["voltage"] = tonumber(tobin(splited_data[3], 2))
		callback_unregister('modbus_send_40005')
		return
	end

	if splited_data[1] == "40006" then
	end

	if splited_data[1] == "40007" then
	end

	if splited_data[1] == "40008" then
		-- TODO find where is the power thing of barrel and such things
		if tonumber(tobin(splited_data[3], 2):sub(5, 5)) == 0 then
			data_app["co2"] = 1
		else
			data_app["co2"] = 0
		end

		if tonumber(tobin(splited_data[3], 2):sub(4, 4)) then
			data_app["h2o"] = 1
		else
			data_app["h2o"] = 0
		end

		if tonumber(tobin(splited_data[3], 2):sub(6, 6)) then
			data_app["pressurecutout"] = 1
		else
			data_app["pressurecutout"] = 0
		end
		callback_unregister('modbus_send_40008')
		return
	end
end
