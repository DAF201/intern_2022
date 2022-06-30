-- DONT EDIT ANYTHING IN THIS FILE, RIGHT CLICK MAKE A NEW FILE TO MAKE YOUR CHANGES
-- TODO: FIND WHAT CAUSED THE BUG WITH PERCENTAGE PARTS 06/21/2022
backup_data = {}

function can_run_screen_init()
    -- value in input page
    wgg_data["can_flow_high"] = recipevalue[11]
    wgg_data["can_flow_low"] = recipevalue[10]
    wgg_data["can_flow_finish"] = recipevalue[12]

    wgg_data["can_filldelay_raise"] = recipevalue[16]
    wgg_data["can_filldelay_start"] = recipevalue[15]
    wgg_data["can_filldelay_co2"] = recipevalue[14]

    wgg_data["can_canslide_seam"] = recipevalue[20]
    wgg_data["can_canslide_lid"] = recipevalue[19]
    wgg_data["can_canslide_do"] = recipevalue[18]

    can_canslide_seam = recipevalue[20]
    can_canslide_lid = recipevalue[19]
    can_canslide_do = recipevalue[18]
    
    -- value in normal page
    gre.set_value("drawer_run_layer.drawer_group.highinput_control.text", wgg_data["can_flow_high"] * 1 / 1 / 1000)
    gre.set_value("drawer_run_layer.drawer_group.lowinput_control.text", wgg_data["can_flow_low"] * 1 / 1 / 1000)
    gre.set_value("drawer_run_layer.drawer_group.fininput_control.text", wgg_data["can_flow_finish"] * 1 / 1 / 1000)

    gre.set_value("drawer_run_layer.drawer_group.raiseinput_control.text",
        wgg_data["can_filldelay_raise"] * 1 / 1 / 1000)
    gre.set_value("drawer_run_layer.drawer_group.startinput_control.text",
        wgg_data["can_filldelay_start"] * 1 / 1 / 1000)
    gre.set_value("drawer_run_layer.drawer_group.co2input_control.text", wgg_data["can_filldelay_co2"] * 1 / 1 / 1000)

    gre.set_value("drawer_run_layer.drawer_group.seaminput_control.text", recipevalue[20] * 1 / 1)
    gre.set_value("drawer_run_layer.drawer_group.lidinput_control.text", recipevalue[19] * 1 / 1)
    gre.set_value("drawer_run_layer.drawer_group.DOinput_control.text", recipevalue[18] * 1 / 1)
end

function can_run_screen_backup()

    backup_data["can_flow_high"] = wgg_data["can_flow_high"]
    backup_data["can_flow_low"] = wgg_data["can_flow_low"]
    backup_data["can_flow_finish"] = wgg_data["can_flow_finish"]

    backup_data["can_filldelay_raise"] = wgg_data["can_filldelay_raise"]
    backup_data["can_filldelay_start"] = wgg_data["can_filldelay_start"]
    backup_data["can_filldelay_co2"] = wgg_data["can_filldelay_co2"]

    backup_data["can_canslide_seam"] = can_canslide_seam
    backup_data["can_canslide_lid"] = can_canslide_lid
    backup_data["can_canslide_do"] = can_canslide_do
end

function restore_to_back_up()
    wgg_data["can_flow_high"] = backup_data["can_flow_high"]
    wgg_data["can_flow_low"] = backup_data["can_flow_low"]
    wgg_data["can_flow_finish"] = backup_data["can_flow_finish"]

    wgg_data["can_filldelay_raise"] = backup_data["can_filldelay_raise"]
    wgg_data["can_filldelay_start"] = backup_data["can_filldelay_start"]
    wgg_data["can_filldelay_co2"] = backup_data["can_filldelay_co2"]

    wgg_data["can_canslide_seam"] = backup_data["can_canslide_seam"]
    wgg_data["can_canslide_lid"] = backup_data["can_canslide_lid"]
    wgg_data["can_canslide_do"] = backup_data["can_canslide_do"]

    print("restoring to original")
end

function save_backup_to_reciptes()
    recipevalue[11]=wgg_data["can_flow_high"]
    recipevalue[10]=wgg_data["can_flow_low"]
    recipevalue[12]=wgg_data["can_flow_finish"]

    recipevalue[16]=wgg_data["can_filldelay_raise"]
    recipevalue[15]=wgg_data["can_filldelay_start"]
    recipevalue[14]=wgg_data["can_filldelay_co2"]

    recipevalue[20]=wgg_data["can_canslide_seam"]
    recipevalue[19]=wgg_data["can_canslide_lid"]
    recipevalue[18]=wgg_data["can_canslide_do"]

--    recipevalue[20]=backup_data["can_canslide_seam"] 
--     recipevalue[19]=backup_data["can_canslide_seam"] 
--     recipevalue[18]=backup_data["can_canslide_seam"] 
end