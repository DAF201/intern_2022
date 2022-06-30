function can_menu_init()
    print(wgg_data['can1_flow_low'])
    gre.set_value("can_overview_layer.content_group.low_control.text", recipevalue[10] * 1 / 1 / 1000)
    gre.set_value("can_overview_layer.content_group.high_control.text", recipevalue[11] * 1 / 1 / 1000)
    gre.set_value("can_overview_layer.content_group.finish_control.text", recipevalue[12] * 1 / 1 / 1000)

    gre.set_value("can_overview_layer.content_group.co2_control.text",recipevalue[14]*1/1/1000)
    gre.set_value("can_overview_layer.content_group.start_control.text",recipevalue[15]*1/1/1000)
    gre.set_value("can_overview_layer.content_group.raise_control.text",recipevalue[16]*1/1/1000)
    gre.set_value("can_overview_layer.content_group.sensor_control.text",recipevalue[17]*1/1/1000)
    
    gre.set_value("can_overview_layer.content_group.DOhood_control.text",recipevalue[18]*1/1)
    gre.set_value("can_overview_layer.content_group.lid_control.text",recipevalue[19]*1/1)
    gre.set_value("can_overview_layer.content_group.seam_control.text",recipevalue[20]*1/1)
end
