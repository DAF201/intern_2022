--sadly, some function written by previous guy does not seem to work on my timer
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

function register_callback(the_function, func_name, time_interval) --[[(the_function: function, func_name: string, time_interval: number) This function will register a function with a time interval, after the exactly seconds passed, the function will be called, reutrn true or nil]]
    if registered_function[the_function] == nil then
        if pcall(register, the_function, time_interval, func_name) then
            registered_function[the_function] = ''
            return true
        else
            return nil
        end
    else
        return true
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


        --executing something

        --registering callback for functions
        --examples of timing callback:
        --        register_callback(test, 'test', 1)
        --        register_callback(foo, 'foo', 2)
        --        register_callback(yehoo, 'yehoo', 3)


        -- Timer to update time and date on screen
        register_callback(updateTime, 'updateTime', 1) -- sec - every second


        -- Timer to check the defrost times
        register_callback(defrostCheck, 'defrostCheck', 60) -- sec - every minute - 
        -- we can not allow this to trigger less ore more than once a minute but it must trigger every minute
        --above is old note from old guy


        -- Timer to check beep status
        register_callback(beepSilenceCheck, 'beepSilenceCheck', 60) -- sec - every minute - 


        -- Get the UVC4 version
        --I don't know what is this idvelstr for
        idval_str = register_callback(RequestVersion, 'RequestVersion', 2)


        -- Get the brix_backend version
        if (is_dev == 0) then
            idval_bac = register_callback(RequestBrixBackendVersion, 'RequestBrixBackendVersion', 1)
        end


        -- Get the voltage
        idval_vol = register_callback(RequestVoltage, 'RequestVoltage', 1)


        -- If this is a development install, auto close the init screen so the UI does not get stuck there
        -- print(is_dev)
        if is_dev ~= 0 then
            print("init dev")
            idval_init = register_callback(initEndTest, 'initEndTest', 4)
        end

        --send 40003 for test use
        register_callback(test_send, 'test_send', 1)


        --end of executing

        --give control to timer
        counter = counter + 1
        coroutine.resume(c_timer)
    end
end

function init()


    --OLD THINGS
    os.execute("ifconfig eth0 192.168.1.222 netmask 255.255.255.0")

    local dk_data = {}

    -- print("App Start")

    -- Set all the defaults from hardcoded values
    -- Get the values of locally saved variabes from the powerup.csv file
    PowerupValue()
    updateTime()

    -- Trigger the power saver on off animation based on the saved values so it is correct on the screen
    power_save_anim_init()

    -- Set initial values into the UI controls
    DispayCurrentStandbyTemp();
    DisplayPowerSaver()
    DisplayCompressorTimes()

    -- This call puts the BOM, SN, Model, UVC4 Version, Store Id into the UI elements
    SetSystemInfo()


    --END OF OLD THINGS


    InitValues(mpargs)

    c_main = coroutine.create(main)
    c_timer = coroutine.create(timer)
    coroutine.resume(c_main)
    coroutine.resume(c_timer)
end

function timer_test()
    echo('this is to check the timer is running')
end
