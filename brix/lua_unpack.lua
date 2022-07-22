packing_counter=0
function unpack(tab)
    packing_counter=packing_counter+1
    if tab[packing_counter]~=nil then
    return tab[packing_counter],unpack(tab)
    else
        packing_counter=0
    end
end
