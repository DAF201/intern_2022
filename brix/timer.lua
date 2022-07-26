timed_callback_functions = {}
registered_function = {}
start_time = os.date('%S')
time_counter = 0

-- finially work on this stupid thing
function callback_register(name, func, interval, arg1, arg2, arg3)
    if registered_function[name] == nil then
        timed_callback_functions[#timed_callback_functions + 1] = {name, interval, func}
        registered_function[name] = {arg1, arg2, arg3}
        return true
    end
    return nil
end

function callback_unregister(function_name)
    local counter = 1
    for key, value in pairs(timed_callback_functions) do
        if value[1] == function_name then
            table.remove(timed_callback_functions, counter)
            registered_function[function_name] = nil 
            echo('unregistering ' .. function_name)
        end
        counter = counter + 1
    end
end

function clock()
            time_counter = time_counter + 1
            if #timed_callback_functions == 0 then
            else
                for i = 1, #timed_callback_functions, 1 do
                    local function_name = timed_callback_functions[i][1]
                    if timed_callback_functions[i][2] == 0 then
                        break
                    end
                    if time_counter % timed_callback_functions[i][2] == 0 then
                        local statu, error = pcall(timed_callback_functions[i][3],
                            registered_function[function_name][1], registered_function[function_name][2],
                            registered_function[function_name][3])
                        -- print("executing " .. function_name)
                        if not statu then
                            echo("error: " .. timed_callback_functions[i][1])
                            echo(error)
                        end
                    end
                end
            end
        end
