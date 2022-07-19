timed_callback_functions = {}
registered_function = {}
start_time = os.date('%S')
time_counter = 0


function callback_register(name, func, interval)
	if registered_function[name] == nil then
		timed_callback_functions[#timed_callback_functions + 1] = { name, interval, func }
		registered_function[name] = interval
		return true
	end
	return nil
end

function clock()

	while 1 do
		now = os.date('%S')
		if now ~= start_time then
			start_time = now
			time_counter = time_counter + 1
			--            echo("one sec passed")
			if #timed_callback_functions == 0 then
			else
				for i = 1, #timed_callback_functions, 1 do
					if time_counter % timed_callback_functions[i][2] == 0 then
						if not pcall(timed_callback_functions[i][3]) then
							echo("error: " .. echo(timed_callback_functions[i][1]))
						end
					end
				end
			end

		end

	end

end

timed_callback_functions = {}
registered_function = {}
start_time = os.date('%S')
time_counter = 0


function callback_register(name, func, interval)
	if registered_function[name] == nil then
		timed_callback_functions[#timed_callback_functions + 1] = { name, interval, func }
		registered_function[name] = interval
		return true
	end
	return nil
end

function clock()

	while 1 do
		now = os.date('%S')
		if now ~= start_time then
			start_time = now
			time_counter = time_counter + 1

			if #timed_callback_functions == 0 then
			else
				for i = 1, #timed_callback_functions, 1 do
					if time_counter % timed_callback_functions[i][2] == 0 then
						if not pcall(timed_callback_functions[i][3]) then
							echo("error: " .. timed_callback_functions[i][1])
						end
					end
				end
			end

		end

	end

end
