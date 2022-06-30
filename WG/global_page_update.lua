function Totally_init()
    setting_page_date_init()
    update_time()
    update_date()
    global_page_init()
    distance_unit_init()
end

function am_pm_init()
    if os.date("%p") == "AM" then
        is_am()
    else
        is_pm()
    end
end

function up_date_time()
    if data_app["milirarytime"] == "1" then
        gre.set_value("global_layer.time_group.time_control.text", os.date("%H:%M"))
    else
        gre.set_value("global_layer.time_group.time_control.text", os.date("%I:%M"))
    end
end

function setting_page_date_init()
    can_slide_update()

    filler_update()

    lid_drop_update()

    LN2_update()
end

function can_slide_update()
    gre.set_value("canslide_layer.gripper_group.delay_control.text", wgg_data["can_retractdelay"] * 1 / 1 / 1000)
end

function filler_update()
    gre.set_value("filler_layer.delay_group.co2_control.text", wgg_data["fill_co2delay"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.delay_group.start_control.text", wgg_data["fill_startdelay"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.delay_group.raise_control.text", wgg_data["fill_raisedelay"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.delay_group.sensor_control.text", wgg_data["fill_sensordelay"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.flow_group.low_control.text", wgg_data["fill_flowlow"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.flow_group.high_control.text", wgg_data["fill_flowhigh"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.flow_group.finish_control.text", wgg_data["fill_flowfinish"] * 1 / 1 / 1000)
    total_flow_update()
    gre.set_value("filler_layer.travel_group.lower_control.text", wgg_data["fill_lowertime"] * 1 / 1 / 1000)
    gre.set_value("filler_layer.travel_group.raise_control.text", wgg_data["fill_raisetime"] * 1 / 1 / 1000)
end

function lid_drop_update()
    gre.set_value("lid_layer.delay_group.start_control.text", wgg_data["lid_startdelay"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.delay_group.sensor_control.text", wgg_data["lid_sensordelay"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.delay_group.lidpick_control.text", wgg_data["lid_pickdelay"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.delay_group.liddrop_control.text", wgg_data["lid_dropdelay"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.cycle_group.nolid_control.text", wgg_data["lid_nodrop"])
    gre.set_value("lid_layer.cycle_group.fullstack_control.text", wgg_data["lid_fullstack"])
    gre.set_value("lid_layer.cycle_group.retravel_control.text", wgg_data["lid_retracttime"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.cycle_group.extravel_control.text", wgg_data["lid_extendtime"] * 1 / 1 / 1000)
    gre.set_value("lid_layer.cycle_group.fullstack_control.text", wgg_data["lid_extendretry"])
end

function seamer_update()
    gre.set_value("seamer_layer.cycle_group.start_control.text", wgg_data["seam_startdelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.cycle_group.fault_control.text", wgg_data["seam_faultsensordelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.cycle_group.can_control.text", wgg_data["seam_canstabilitydelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.cycle_group.motor_control.text", wgg_data["seam_motorspeeddelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.cycle_group.lid_control.text", wgg_data["seam_liddetecttime"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.roller_group.start_control.text", wgg_data["seam_roller1startdelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.roller_group.roll1_control.text", wgg_data["seam_roller1dwell"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.roller_group.roll2_control.text", wgg_data["seam_roller2dwell"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.cycle_group.start_control.text", wgg_data["seam_startdelay"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.canlift_group.lower_control.text", wgg_data["seam_fullylower"] * 1 / 1 / 1000)
    gre.set_value("seamer_layer.canlift_group.raise_control.text", wgg_data["seam_fullyraise"] * 1 / 1 / 1000)
end

function LN2_update()
    gre.set_value("ln2_layer.doser_group.purge_control.text", wgg_data["LN2_start"] * 1 / 1 / 1000)
    gre.set_value("ln2_layer.doser_group.duration_control.text", wgg_data["LN2_doserdur"] * 1 / 1 / 1000)
    gre.set_value("ln2_layer.purge_group.duration_control.text", wgg_data["LN2_purgedur"] * 1 / 1 / 1000)
end

function total_flow_update()
    gre.set_value("filler_layer.flow_group.total_control.text",
        (wgg_data["fill_flowlow"] + wgg_data["fill_flowhigh"] + wgg_data["fill_flowfinish"]) * 1 / 1 / 1000)
end

function update_time()
    if data_app["milirarytime"] == "1" then
        gre.set_value("global_layer.time_group.time_control.text", os.date("%H:%M"))
    else
        gre.set_value("global_layer.time_group.time_control.text", os.date("%I:%M"))
    end
end

function update_date()
    gre.set_value("global_layer.date_group.date_control.text", os.date("%m/%d/%y"))
end

function global_page_init()

    -- init images
    gre.set_value("global_layer.time_group.12hr_control.image", "images/togleft_act.png")
    gre.set_value("global_layer.time_group.24hr_control.image", "images/togrt_act.png")

    if data_app["milirarytime"] == "1" then
        hide_am_pm()
        gre.set_value("global_layer.time_group.24hr_control.image", "images/togrt_up.png")
    else
        gre.set_value("global_layer.time_group.12hr_control.image", "images/togleft_up.png")
        if os.date("%p") == 'PM' then
            -- TODO pm/am button display switch 06/22/22
            is_pm()
            print("PM")
        else
            is_am()
            print("AM")
        end
    end
end

function hide_am_pm()
    gre.set_value("global_layer.time_group.am_control.text", "")
    gre.set_value("global_layer.time_group.pm_control.text", "")

    gre.set_value("global_layer.time_group.am_control.image", "")
    gre.set_value("global_layer.time_group.am_control.image", "")
end

function is_am()
    gre.set_value("global_layer.time_group.am_control.text", "AM")
    gre.set_value("global_layer.time_group.pm_control.text", "PM")

    gre.set_value("global_layer.time_group.am_control.image", "images/togleft_up2.png")
    gre.set_value("global_layer.time_group.pm_control.image", "images/togrt_act1.png")

end

function is_pm()
    gre.set_value("global_layer.time_group.am_control.text", "AM")
    gre.set_value("global_layer.time_group.pm_control.text", "PM")

    gre.set_value("global_layer.time_group.am_control.image", "images/togleft_act1.png")
    gre.set_value("global_layer.time_group.pm_control.image", "images/togrt_up1.png")

end

function to_am()
end

function to_pm()
end

function distance_unit_init()
    --    if wgg_ata['distance_unit_is_US'] == 0 then
    gre.set_value("global_layer.langunit_group.tableft_control.image", "images/togleft_act1.png")
    gre.set_value("global_layer.langunit_group.tabright_control.image", "images/togrt_up1.png")
    --    else
    --        gre.set_value("global_layer.langunit_group.tableft_control.image","images/togleft_up2.png")
    --        gre.set_value("global_layer.langunit_group.tabright_control.image","images/togrt_act1.png")
    --    end
end

function to_24_hrs()
    if data_app["milirarytime"] == "0" then
        data_app["milirarytime"] = "1"
    end
    global_page_init()
end

function to_12_hrs()
    if data_app["milirarytime"] == "1" then
        data_app["milirarytime"] = "0"
    end
    global_page_init()
end
