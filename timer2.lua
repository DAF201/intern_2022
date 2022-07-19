timed_callback_functions = {}
registered_function = {}
start_time = os.date('%S')
time_counter = 0

function callback_register(name, func, interval, ...)
    if registered_function[name] == nil then
        timed_callback_functions[#timed_callback_functions + 1] = {name, interval, func}
        registered_function[name] = {...}
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
                    local function_name = timed_callback_functions[i][1]
                    if time_counter % timed_callback_functions[i][2] == 0 then
                        if not pcall(timed_callback_functions[i][3], table.unpack(registered_function[function_name])) then
                            print("error: " .. timed_callback_functions[i][1])
                        end
                    end
                end
            end

        end

    end

end

function test(string_data)
    print(string_data)
end

callback_register('test', test, 2, 'this is a test')
clock()
