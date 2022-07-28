---@type table #table for registering functions and record functions registered
timed_callback_functions = {}
registered_function = {}
---@type number #time counter #add one per sec
time_counter = 0

---@generic callback_register # registering a function to the time table
---@param name string # an unque string name for parameter finding and unregistering 
---@param func function # function address
---@param interval number #the interval of calling the function, min and smallest unit are one
---@param args any #arg1 arg2 arg3 optional... parameter used when call the function
---@return boolean
function callback_register(name, func, interval, arg1, arg2, arg3)
    if registered_function[name] == nil then
        timed_callback_functions[#timed_callback_functions + 1] = {name, interval, func}
        registered_function[name] = {arg1, arg2, arg3}
        return true
    end
    return false
end

---@generic callback_unregister #unregister an function from time table #unregistered function will not be called by timer 
---@param function_name string # the unique name of the function
---@return boolean
function callback_unregister(function_name)
    local counter = 1
    for key, value in pairs(timed_callback_functions) do
        if value[1] == function_name then
            table.remove(timed_callback_functions, counter)
            registered_function[function_name] = nil
            echo('unregistering ' .. function_name)
            return true
        end
        counter = counter + 1
    end
    return false
end

--- @generic clock #clock that call the registered functions by time and registered interval
--- @generic detail # I tried C theading and the coroutine # unfortunately Crank does not support coroutine and the extra threading will seriously influence the preformance of the system
--- @generic detail # Also the system build-in timer may cause data error if there are too many of them
--- @generic detail # therefore I make a clock function called by system timer per sec to run other functions that need a callback by time
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
                local statu, error = pcall(timed_callback_functions[i][3], registered_function[function_name][1],
                    registered_function[function_name][2], registered_function[function_name][3])
                if not statu then
                    echo("error: " .. timed_callback_functions[i][1])
                    echo(error)
                end
            end
        end
    end
end
