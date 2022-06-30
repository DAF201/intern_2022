function FO_on_click(args)

    local path = args.path
    path = path:gsub('"', '')

    print(path) -- start end  or nil

    if (string.find(path, "stat") ~= nil) then
        if gre.get_value("FO_stats") == 0 then
            gre.set_value("FO_stats", 1)
        else
            gre.set_value("FO_stats", 0)
        end
    end

    if (string.find(path, "system") ~= nil) then
        if gre.get_value("FO_system") == 0 then
            gre.set_value("FO_system", 1)
        else
            gre.set_value("FO_system", 0)
        end
    end

    if (string.find(path, "lid") ~= nil) then
        if gre.get_value("FO_lids") == 0 then
            gre.set_value("FO_lids", 1)
        else
            gre.set_value("FO_lids", 0)
        end
    end

    if (string.find(path, "ln2") ~= nil) then
        if gre.get_value("FO_ln2") == 0 then
            gre.set_value("FO_ln2", 1)
        else
            gre.set_value("FO_ln2", 0)
        end
    end

    if (string.find(path, "seamtest") ~= nil) then
        if gre.get_value("FO_seamer") == 0 then
            gre.set_value("FO_seamer", 1)
        else
            gre.set_value("FO_seamer", 0)
        end
    end

    if (string.find(path, "clean") ~= nil) then
        if gre.get_value("FO_clean") == 0 then
            gre.set_value("FO_clean", 1)
        else
            gre.set_value("FO_clean", 0)
        end
    end

end
