production_box = {}

-- ** LOCAL UTIL **
local function refresh_production(player, _, _)
    local subfactory = data_util.get("context", player).subfactory
    if subfactory and subfactory.valid then
        calculation.update(player, subfactory)
        main_dialog.refresh(player, "subfactory")
    end
end

local function paste_line(player, _, event)
    if event.button == defines.mouse_button_type.left and event.shift then
        local context = data_util.get("context", player)
        local line_count = context.floor.Line.count
        local last_line = Floor.get_by_gui_position(context.floor, "Line", line_count)
        -- Use a fake first line to paste below if no actual line exists
        if not last_line then last_line = {parent=context.floor, class="Line", gui_position=0} end

        if ui_util.clipboard.paste(player, last_line) then
            calculation.update(player, context.subfactory)
            main_dialog.refresh(player, "subfactory")
        end
    end
end


-- ** TOP LEVEL **
function production_box.build(player)
    local main_elements = data_util.get("main_elements", player)
    main_elements.production_box = {}

    local parent_flow = main_elements.flows.right_vertical
    local frame_vertical = parent_flow.add{type="frame", direction="vertical", style="inside_deep_frame"}
    -- Insert a 'superfluous' flow for the sole purpose of detecting clicks on it
    local click_flow = frame_vertical.add{type="flow", direction="vertical",
      tags={mod="fp", on_gui_click="paste_line"}}
    click_flow.style.vertically_stretchable = true
    click_flow.style.horizontally_stretchable = true
    main_elements.production_box["vertical_frame"] = click_flow

    local subheader = click_flow.add{type="frame", direction="horizontal", style="subheader_frame"}
    subheader.style.maximal_height = 100  -- large value to nullify maximal_height
    subheader.style.padding = {8, 8, 6, 8}

    local button_refresh = subheader.add{type="sprite-button", tags={mod="fp", on_gui_click="refresh_production"},
      sprite="utility/refresh", style="tool_button", tooltip={"fp.refresh_production"}, mouse_button_filter={"left"}}
    main_elements.production_box["refresh_button"] = button_refresh

    local label_title = subheader.add{type="label", caption={"fp.production"}, style="frame_title"}
    label_title.style.padding = {0, 8}

    local label_level = subheader.add{type="label"}
    label_level.style.margin = {0, 6, 0, 6}
    main_elements.production_box["level_label"] = label_level

    local button_floor_up = subheader.add{type="sprite-button", sprite="fp_sprite_arrow_line_up",
      tooltip={"fp.floor_up_tt"}, tags={mod="fp", on_gui_click="change_floor", destination="up"},
      style="fp_sprite-button_rounded_mini", mouse_button_filter={"left"}}
    main_elements.production_box["floor_up_button"] = button_floor_up

    local button_floor_top = subheader.add{type="sprite-button", sprite="fp_sprite_arrow_line_bar_up",
      tooltip={"fp.floor_top_tt"}, tags={mod="fp", on_gui_click="change_floor", destination="top"},
      style="fp_sprite-button_rounded_mini", mouse_button_filter={"left"}}
    main_elements.production_box["floor_top_button"] = button_floor_top

    local separator = subheader.add{type="line", direction="vertical"}
    separator.style.margin = {0, 12}
    main_elements.production_box["separator_line"] = separator

    local button_utility_dialog = subheader.add{type="sprite-button", sprite="utility/slot_icon_robot_material_black",
      tooltip={"fp.utility_dialog_tt"}, tags={mod="fp", on_gui_click="open_utility_dialog"},
      style="fp_sprite-button_rounded_mini", mouse_button_filter={"left"}}
    button_utility_dialog.style.padding = -4
    main_elements.production_box["utility_dialog_button"] = button_utility_dialog

    subheader.add{type="empty-widget", style="flib_horizontal_pusher"}

    local table_view_state = view_state.build(player, subheader)
    main_elements.production_box["view_state_table"] = table_view_state

    local label_instruction = click_flow.add{type="label", style="bold_label"}
    label_instruction.style.margin = 20
    main_elements.production_box["instruction_label"] = label_instruction

    production_box.refresh(player)
end

function production_box.refresh(player)
    local ui_state = data_util.get("ui_state", player)
    local production_box_elements = ui_state.main_elements.production_box

    local subfactory = ui_state.context.subfactory
    local subfactory_valid = subfactory and subfactory.valid

    local current_level = (subfactory_valid) and subfactory.selected_floor.level or 1
    local any_lines_present = (subfactory_valid) and (subfactory.selected_floor.Line.count > 0) or false
    local archive_open = (ui_state.flags.archive_open)

    production_box_elements.refresh_button.enabled = (not archive_open and subfactory_valid and any_lines_present)
    production_box_elements.level_label.caption = (not subfactory_valid) and ""
      or {"fp.bold_label", {"", {"fp.level"}, " ", current_level}}

    production_box_elements.floor_up_button.visible = (subfactory_valid)
    production_box_elements.floor_up_button.enabled = (current_level > 1)

    production_box_elements.floor_top_button.visible = (subfactory_valid)
    production_box_elements.floor_top_button.enabled = (current_level > 1)

    production_box_elements.utility_dialog_button.visible = (subfactory_valid)
    production_box_elements.separator_line.visible = (subfactory_valid)

    view_state.refresh(player, production_box_elements.view_state_table)
    production_box_elements.view_state_table.visible = (subfactory_valid)

    -- This structure is stupid and huge, but not sure how to do it more elegantly
    production_box_elements.instruction_label.visible = false
    if not archive_open then
        if subfactory == nil then
            production_box_elements.instruction_label.caption = {"fp.production_instruction_subfactory"}
            production_box_elements.instruction_label.visible = true
        elseif subfactory_valid then
            if subfactory.Product.count == 0 then
                production_box_elements.instruction_label.caption = {"fp.production_instruction_product"}
                production_box_elements.instruction_label.visible = true
            elseif not any_lines_present then
                production_box_elements.instruction_label.caption = {"fp.production_instruction_recipe"}
                production_box_elements.instruction_label.visible = true
            end
        end
    end
end


-- Changes the floor to either be the top one or the one above the current one
function production_box.change_floor(player, destination)
    local floor_changed = ui_util.context.change_floor(player, destination)

    if floor_changed then  -- only need to refresh if the floor was indeed changed
        local subfactory = data_util.get("context", player).subfactory
        calculation.update(player, subfactory)
        main_dialog.refresh(player, "production_detail")
    end
end


-- ** EVENTS **
production_box.gui_events = {
    on_gui_click = {
        {
            name = "refresh_production",
            timeout = 20,
            handler = refresh_production
        },
        {
            name = "change_floor",
            handler = (function(player, tags, _)
                production_box.change_floor(player, tags.destination)
            end)
        },
        {
            name = "open_utility_dialog",
            handler = (function(player, _, _)
                modal_dialog.enter(player, {type="utility"})
            end)
        },
        {
            name = "paste_line",
            handler = paste_line
        }
    }
}

production_box.misc_events = {
    fp_refresh_production = (function(player, _, _)
        if main_dialog.is_in_focus(player) then refresh_production(player, nil, nil) end
    end),

    fp_floor_up = (function(player, _)
        if main_dialog.is_in_focus(player) then production_box.change_floor(player, "up") end
    end)
}
