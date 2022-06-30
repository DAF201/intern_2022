function label_page_values_init()
    wgg_data['conveyor_speed'] = 0
    wgg_data['conveyor_sync'] = 0

    wgg_data['wrapbelt_speed'] = 0
    wgg_data['wrapbelt_sync'] = 0

    wgg_data['stepper_speed'] = 0
    wgg_data['stepper_accelerate'] = 0
    wgg_data['stepper_decelerate'] = 0
    wgg_data['stepper_test_feed_length'] = 0
    wgg_data['stepper_test_feed_deley'] = 0

    wgg_data['spacing_speed_control'] = 0
    wgg_data['spacing_flag_control'] = 0

    wgg_data['backwrap_delay'] = 0
    wgg_data['backwrap_timer'] = 0

    wgg_data['imprinter_delay'] = 0
    wgg_data['imprinter_dwell'] = 0

    wgg_data['label_feed_delay'] = 0
    wgg_data['label_feed_speed'] = 0

end

--  TODO AFTER LUNCH: FIX "can_overview_layer.content_group" page elements displaying issue
--  TODO SEPRATE DIFFERENT CAN RUN PAGE

function label_page_init()
    gre.set_value('label_layer.conveyor_group.speed_control.text', wgg_data['conveyor_speed'])
    gre.set_value('label_layer.conveyor_group.duration_control.text', wgg_data['conveyor_sync'])

    gre.set_value('label_layer.wrapbelt_group.speed_control.text', wgg_data['wrapbelt_speed'])
    gre.set_value('label_layer.wrapbelt_group.sync_control.text', wgg_data['wrapbelt_sync'])

    gre.set_value('label_layer.stepper_group.speed_control.text', wgg_data['stepper_speed'])
    gre.set_value('label_layer.stepper_group.accelerate_control.text', wgg_data['stepper_accelerate'])
    gre.set_value('label_layer.stepper_group.decelerate_control.text', wgg_data['stepper_decelerate'])
    gre.set_value('label_layer.stepper_group.testfeed_control.text', wgg_data['stepper_test_feed_length'])
    gre.set_value('label_layer.stepper_group.postfeed_control.text', wgg_data['stepper_test_feed_deley'])

    gre.set_value('label_layer.spacing_group.speed_control.text', wgg_data['spacing_speed_control'])
    gre.set_value('label_layer.spacing_group.flag_control.text', wgg_data['spacing_flag_control'])

    gre.set_value('label_layer.backwrap_group.delay_control.text', wgg_data['backwrap_delay'])
    gre.set_value('label_layer.backwrap_group.timer_control.text', wgg_data['backwrap_timer'])

    gre.set_value('label_layer.imprinter_group.delay_control.text', wgg_data['imprinter_delay'])
    gre.set_value('label_layer.imprinter_group.dwell_control.text', wgg_data['imprinter_dwell'])

    gre.set_value('label_layer.labelfeed_group.delay_control.text', wgg_data['label_feed_delay'])
    gre.set_value('label_layer.labelfeed_group.timer_control.text', wgg_data['label_feed_speed'])

    --    print("value equal: " .. tostring(gre.get_value("label_layer.sync_group.switch_control.switch_status") == 1))

    if (gre.get_value("label_layer.sync_group.switch_control.status") == 1) then
        gre.set_value("label_layer.sync_group.switch_control.image", "images/switch_on.png")
        gre.set_value("label_layer.sync_group.switch_control.text", "Sync Enable")
    end

    if (gre.get_value("label_layer.spacing_group.switch_control.status") == 1) then
        gre.set_value("label_layer.spacing_group.switch_control.image", "images/switch_on.png")
    end
    
     if (gre.get_value("label_layer.backwrap_group.switch_control.status") == 1) then
         gre.set_value("label_layer.backwrap_group.switch_control.image", "images/switch_on.png")
    end
    
    if (gre.get_value("label_layer.labelfeed_group.switch_control.status") == 1) then
        gre.set_value("label_layer.labelfeed_group.switch_control.image", "images/switch_on.png")
    end
end


function label_page_switches_toggle(args)
    local switch_location = args.root_path
    local on_switch_title = args.ontitle
    local off_switch_title = args.offtitle
    
    
    if (gre.get_value(switch_location .. ".status") == 1) then
        print(switch_location.." is being changing to off")
        gre.set_value(switch_location .. ".status", 0)
        gre.set_value(switch_location .. ".image", "images/switch_off.png")
        
        if off_switch_title ~= nil then
            gre.set_value(switch_location .. ".text", off_switch_title)
        end
        
    else
        print(switch_location.." is being changing to on")
        gre.set_value(switch_location .. ".status", 1)
        gre.set_value(switch_location..".image", "images/switch_on.png")
        
        if on_switch_title ~= nil then
            gre.set_value(switch_location..".text", on_switch_title)
        end
        
    end
    print(gre.get_value(switch_location .. ".status"))
end

function SetupLabelFeedSpeedControlInputWindows()
    print('Setup label page label feed delay control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['label_feed_speed'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'label feed speed control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 9in/min')
end

function SetupLabelFeedDelayControlInputWindows()
    print('Setup label page label feed delay control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['label_feed_delay'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'label feed delay control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 9999sec')
end

function SetupImprinterDwellControlInputWindows()
    print('Setup label page imprinter dwewll control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['imprinter_dwell'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'imprinter dwewll control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 9')
end

function SetupImprinterDelayControlInputWindows()
    print('Setup label page imprinter delay control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['imprinter_delay'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'imprinter delay control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 999 sec')
end

function SetupBackWrapTimerControlInputWindows()
    print('Setup label page back wrap timer control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['backwrap_timer'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'backwrap timer control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 999 sec')
end

function SetupBackWrapDelayControlInputWindows()
    print('Setup label page back wrap delay control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['backwrap_delay'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'backwrap delay control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 999 sec')
end

function SetupSpacingFlagControlInputWindows()
    print('Setup label page spacing flag control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['spacing_flag_control'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'spacing flag control setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 9 in')
end

function SetupSpacingSpeedControlInputWindows()
    print('Setup label page spacing whell speed control Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['spacing_speed_control'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'spacing wheel speed setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 9999 in/min')
end

function SetupStepperTestFeedDelayInputWindows()
    print('Setup label page stepper test feed delay Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['stepper_test_feed_deley'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'stepper test feed length setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 60 sec')
end

function SetupStepperTestFeedLengthInputWindows()
    print('Setup label page stepper test feed length Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['stepper_test_feed_length'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'stepper test feed length setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in')
end

function SetupStepperDecelerateInputWindows()
    print('Setup label page stepper speed Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['stepper_decelerate'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'stepper decelerate setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in/min^2')
end

function SetupStepperAccelerateInputWindows()
    print('Setup label page stepper speed Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['stepper_accelerate'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'stepper accelerate setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in/min^2')
end

function SetupStepperSpeedInputWindows()
    print('Setup label page stepper speed Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['stepper_speed'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'stepper speed setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in/min')
end

function SetupWrapBeltSyncInputWindows()
    print('Setup label page wrapbelt sync Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['wrapbelt_sync'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'wrapbelt sync setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99')
end

function SetupWrapBeltSpeedInputWindows()
    print('Setup label page wrapbelt speed Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['wrapbelt_speed'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'wrapbelt speed setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in/min')
end

function SetupLabelPageSyncInputWindows()
    print('Setup label page conveyor sync Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['conveyor_sync'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'conveyor sync setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99')
end

function SetupLabelPageSpeedInputWindows()
    print('Setup label page conveyor speed Input')

    gre.set_value('Input_layer.input_group.input_control.text', wgg_data['conveyor_speed'] .. '_')
    gre.set_value('Input_layer.input_group.name.text', 'conveyor speed setting')
    gre.set_value('Input_layer.input_group.range.text', '0 - 99 in/min')
end

