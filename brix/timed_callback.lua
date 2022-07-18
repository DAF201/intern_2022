--personal example
counter = 0
time_counter = 0
start_time = os.date('%S')
function_time_table = {}
registered_function = {}


function timer()
    table_empty = false
    while 1 do
        --if counter %2 ==1 give control to main
        if counter % 2 == 1 then
            coroutine.yield(c_timer)
        end
        -- print("timer running")


        --executing

        --update time
        now = os.date('%S')

        --one sec timer

        if now - start_time > 1 or start_time > now then
            if not next(function_time_table) then
                start_time = now
                time_counter = time_counter + 1
                -- print('1s passed, time passed is ' .. time_counter .. ' seconds' .. ', but the table is empty')
            else
                start_time = now
                time_counter = time_counter + 1

                --excute timed callback here
                -- print('1s passed, time passed is ' .. time_counter .. ' seconds')
                for i = 1, #function_time_table, 1 do
                    if time_counter % function_time_table[i][3] == 0 then
                        function_time_table[i][2]()
                    end
                end
                --end of timed callback
            end
        end

        --end of executing


        --resume main
        counter = counter + 1
        coroutine.resume(c_main)
    end
end

function register_callback(the_function, func_name, time_interval)
    if registered_function[the_function] == nil then
        register(the_function, time_interval, func_name)
        registered_function[the_function] = ''
    end
end

function register(...)
    for _, v in pairs { ... } do
        if type(v) == "string" then
            function_name = v
        else
            if type(v) == "function" then
                func = v
            else
                sec = v
            end
        end
    end
    function_time_table[#function_time_table + 1] = { function_name, func, sec }
end

function main()
    while 1 do
        --if counter %2 ==0 give control to timer
        if counter % 2 == 0 then
            coroutine.yield(c_main)
        end
        -- print("main running")


        --executing something

        --registering callback for functions
        register_callback(test, 'test', 1)
        register_callback(foo, 'foo', 3)
        --end of executing

        --give control to timer
        counter = counter + 1
        coroutine.resume(c_timer)
    end
end

function test()
    print("function test running" .. ' current time: ' .. time_counter)
end

function foo()
    print('function foo running' .. ' current time: ' .. time_counter)
end

c_main = coroutine.create(main)
c_timer = coroutine.create(timer)
coroutine.resume(c_main)
coroutine.resume(c_timer)
