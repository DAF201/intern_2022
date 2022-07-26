time_table = {}
arguement_table = {}
time_counter = 0

function callback_register(function_name, function_address, interval, arg1, arg2, arg3, arg4, arg5)
    if time_table[interval] == nil then
        time_table[interval] = {{function_name, function_address}}
        arguement_table[function_name] = {arg1, arg2, arg3, arg4, arg5}
    else
        table.insert(time_table[interval], #time_table[interval] + 1, {function_name, function_address})
    end
end

function callback_unregister(function_name)
    for k, v in pairs(time_table) do
        for i = 1, #v, 1 do
            if i > #v then
                break
            end
            if v[i][1] == function_name then
                table.remove(v, i)
                return
            end
        end
    end
end

function clock()
    time_counter = time_counter + 50
    for k, v in pairs(time_table) do
        if time_counter % k == 0 then
            for i = 1, #time_table[k], 1 do
                if i > #time_table[k] then
                    break
                end
                time_table[k][i][2](arguement_table[time_table[k][i][1]][1], arguement_table[time_table[k][i][1]][2],
                    arguement_table[time_table[k][i][1]][3], arguement_table[time_table[k][i][1]][4],
                    arguement_table[time_table[k][i][1]][5])
            end
        end
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
function test1()
    print('test')
end
function test2(string)
    print(string)
end
callback_register('dump', dump, 2000)
callback_register('test1', test1, 400000000)
callback_register('test2', test2, 100000000, 'this is test2','test')
-- callback_unregister('test')
print(dump(time_table))

while 1 do
    clock()
    -- os.execute('powershell sleep 0.05')
end
