function notification_init()
    gre.set_value("notifctn_layer.clean_group.am_control.text", "AM")
    gre.set_value("notifctn_layer.clean_group.pm_control.text", "PM")
    gre.set_value("notifctn_layer.ln2_group.am_control.text", "AM")
    gre.set_value("notifctn_layer.ln2_group.pm_control.text", "PM")

    gre.set_value("notifctn_layer.clean_group.am_control.image", 'images/am_act.png')
    gre.set_value("notifctn_layer.clean_group.pm_control.image", 'images/pm_up.png')
    gre.set_value("notifctn_layer.ln2_group.am_control.image", 'images/am_act.png')
    gre.set_value("notifctn_layer.ln2_group.pm_control.image", 'images/pm_up.png')

    gre.set_value("notifctn_layer.clean_group.cipremind_control.text", wgg_data['CIP_remainder'])
    gre.set_value("notifctn_layer.ln2_group.time_control.text", wgg_data['LN2_purge_remainder'])
    gre.set_value("notifctn_layer.clean_group.cip_control.text", wgg_data['CIP_recommand_duration'])
    gre.set_value("notifctn_layer.clean_group.sip_control.text", wgg_data['SIP_recommand_duration'])
    gre.set_value("notifctn_layer.lid_group.alert1_control.text", wgg_data['LOW_LID_ALARM1'])
    gre.set_value("notifctn_layer.lid_group.alert2_control.text", wgg_data['LOW_LID_ALARM2'])
end

function notification_page_values_init()
    wgg_data['CIP_remainder'] = "00:00"
    wgg_data['CIP_recommand_duration'] = 0
    wgg_data['SIP_recommand_duration'] = 0
    wgg_data['LOW_LID_ALARM1'] = 0
    wgg_data['LOW_LID_ALARM2'] = 0
    wgg_data['LN2_purge_remainder'] = "00:00"
end

function SetupCIPRecommandDurationInputWindows()
    print("Setup CIP Recommand Duration Input")

    gre.set_value("Input_layer.input_group.input_control.text", wgg_data["CIP_recommand_duration"] .. "_")
    gre.set_value("Input_layer.input_group.name.text", "CIP recommand duration")
    gre.set_value("Input_layer.input_group.range.text", "0 - 30 mins")
end

function SetupSIPRecommandDurationInputWindows()
    print("Setup SIP Recommand Duration Input")

    gre.set_value("Input_layer.input_group.input_control.text", wgg_data["SIP_recommand_duration"] .. "_")
    gre.set_value("Input_layer.input_group.name.text", "SIP recommand duration")
    gre.set_value("Input_layer.input_group.range.text", "0 - 30 mins")
end

function SetupLowLidAlart1InputWindows()
    print("Setup Low Lid Alart 1 Input")

    gre.set_value("Input_layer.input_group.input_control.text", wgg_data["LOW_LID_ALARM1"] .. "_")
    gre.set_value("Input_layer.input_group.name.text", "Low Lid Alart 1 trigger point")
    gre.set_value("Input_layer.input_group.range.text", "0 - 99 lid")
end

function SetupLowLidAlart2InputWindows()
    print("Setup Low Lid Alart 1 Input")

    gre.set_value("Input_layer.input_group.input_control.text", wgg_data["LOW_LID_ALARM2"] .. "_")
    gre.set_value("Input_layer.input_group.name.text", "Low Lid Alart 2 trigger point")
    gre.set_value("Input_layer.input_group.range.text", "0 - 99 lid")
end
