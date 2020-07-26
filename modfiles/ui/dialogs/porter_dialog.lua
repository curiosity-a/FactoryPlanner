import_dialog = {}
export_dialog = {}
porter_dialog = {}  -- table containing functionality shared between both dialogs

-- ** LOCAL UTIL **
-- Adds the barebones dialog structure that both dialogs need
local function initialize_dialog(flow_modal_dialog, dialog_type)
    flow_modal_dialog.parent.caption = {"", {"fp." .. dialog_type}, " ", {"fp.subfactories"}}
    flow_modal_dialog.vertical_scroll_policy = "never"

    local content_frame = flow_modal_dialog.add{type="frame", name="frame_content", direction="vertical",
      style="inside_shallow_frame_with_padding"}

    local label_text = content_frame.add{type="label", caption={"fp." .. dialog_type .. "_instruction_1"}}
    label_text.style.margin = {0, 30, 10, 0}

    return content_frame
end

-- Adds a flow containing a textfield and a button
local function add_textfield_and_button(parent_flow, dialog_type, button_first, button_enabled)
    local flow = parent_flow.add{type="flow", name="flow_" .. dialog_type .. "_subfactories", direction="horizontal"}
    flow.style.vertical_align = "center"

    local function add_button()
        local button = flow.add{type="button", name="fp_button_porter_subfactory_" .. dialog_type,
          enabled=button_enabled, caption={"fp." .. dialog_type}, style="confirm_button", mouse_button_filter={"left"}}
        if button_first then button.style.horizontal_align = "left" end
    end

    local function add_textfield()
        local textfield_export_string = flow.add{type="textfield", name="fp_textfield_porter_string_" .. dialog_type}
        ui_util.setup_textfield(textfield_export_string)
        textfield_export_string.style.width = 0  -- needs to be set to 0 so stretching works
        textfield_export_string.style.horizontally_stretchable = true

        if button_first then textfield_export_string.style.left_margin = 12
        else textfield_export_string.style.right_margin = 12 end
    end

    if button_first then add_button(); add_textfield()
    else add_textfield(); add_button() end
end

-- Initializes the subfactories table by adding it and its header
local function setup_subfactories_table(parent_flow, add_location)
    local scroll_pane_subfactories = parent_flow.add{type="scroll-pane", name="scroll_pane_subfactories"}
    scroll_pane_subfactories.style.margin = {4, 0, 12, 0}
    scroll_pane_subfactories.style.padding = 0
    scroll_pane_subfactories.style.extra_top_padding_when_activated = 0
    scroll_pane_subfactories.style.extra_right_padding_when_activated = 0
    scroll_pane_subfactories.style.extra_bottom_padding_when_activated = 0
    scroll_pane_subfactories.style.extra_left_padding_when_activated = 0
    scroll_pane_subfactories.style.maximal_height = 450  -- I hate that I have to set this, seemingly

    local frame_subfactories = scroll_pane_subfactories.add{type="frame", name="frame_subfactories",
      style="deep_frame_in_shallow_frame"}
    frame_subfactories.style.padding = {-2, 2, 3, 2}

    local table_columns = {
        [2] = {caption={"fp.csubfactory"}, alignment="left", margin={6, 150, 6, 4}},
        [3] = {caption={"fp.validity"}}
    }
    if add_location then table_columns[4] = {caption={"fp.location"}} end

    local table_subfactories = frame_subfactories.add{type="table", name="table_subfactories",
      column_count=(table_size(table_columns) + 1), style="mods_table"}

    -- Add master checkbox in any case
    table_subfactories.add{type="checkbox", name="fp_checkbox_porter_master", state=false}

    for column_nr, table_column in pairs(table_columns) do
        table_subfactories.style.column_alignments[column_nr] = table_column.alignment or "center"

        local label_column = table_subfactories.add{type="label", caption=table_column.caption}
        label_column.style.font = "heading-3"
        label_column.style.margin = table_column.margin or {0, 4}
    end

    return table_subfactories
end

-- Adds a row to the subfactories table
local function add_to_subfactories_table(table_subfactories, subfactory, location_name)
    local factory_name = location_name or "tmp"
    table_subfactories.add{type="checkbox", name=("fp_checkbox_porter_subfactory_" .. factory_name
      .. "_" .. subfactory.id), state=false, enabled=subfactory.valid}

    local subfactory_icon = " "
    if subfactory.icon ~= nil then
        local subfactory_sprite = subfactory.icon.type .. "/" .. subfactory.icon.name
        if not game.is_valid_sprite_path(subfactory_sprite) then subfactory_sprite = "utility/danger_icon" end
        subfactory_icon = " [img=" .. subfactory_sprite .. "]  "
    end
    table_subfactories.add{type="label", caption=subfactory_icon .. subfactory.name}

    local validity_caption = (subfactory.valid) and {"fp.valid"} or {"fp.error_message", {"fp.invalid"}}
    table_subfactories.add{type="label", caption=validity_caption}

    if location_name then table_subfactories.add{type="label", caption={"fp." .. location_name}} end
end


-- ** IMPORT DIALOG **
function import_dialog.open(flow_modal_dialog)
    flow_modal_dialog.parent["flow_modal_dialog_button_bar"]["fp_button_modal_dialog_submit"].enabled = false

    local content_frame = initialize_dialog(flow_modal_dialog, "import")

    add_textfield_and_button(content_frame, "import", false, false)

    local tmp_export_string = "eNrdkL0KAjEQhF9FtrA6RUVErhUEwUKwFDlycZVILhuSVZBw7+7m/KvE3nJnPoadSdDQobpiiIYclDAajufD6QQKiJf6qDRTMBih3CVwqkEhVoFcr99bkPcYhGPTYNTKijcbFeCIMw/ibAIdLpqhTED1GTWLntrieVTaqpjJFWMj9OtckLVi53eEZfLV0RKFnLI2Dn+ldcy3NItXtFCOP/6yy24/wvZV+ybqu/SaTiay0VGijc5LJeCbz5Z5vP8EOSgXPQUe1Gi5a/C/++zbO5pgwC0="
    content_frame["flow_import_subfactories"]["fp_textfield_porter_string_import"].text = tmp_export_string
    content_frame["flow_import_subfactories"]["fp_button_porter_subfactory_import"].enabled = true
end

-- En/Disables the import-button depending on the import textfield contents
function import_dialog.handle_import_string_change(player, textfield_import)
    local content_frame = player.gui.screen["fp_frame_modal_dialog"]["flow_modal_dialog"]["frame_content"]
    local button_import = content_frame["flow_import_subfactories"]["fp_button_porter_subfactory_import"]
    button_import.enabled = (string.len(textfield_import.text) > 0)
end

-- Tries importing the given string, showing the resulting subfactories-table, if possible
function import_dialog.import_subfactories(player)
    local content_frame = player.gui.screen["fp_frame_modal_dialog"]["flow_modal_dialog"]["frame_content"]

    local export_string = content_frame["flow_import_subfactories"]["fp_textfield_porter_string_import"].text
    -- The imported subfactories will be temporarily contained in a factory object
    local import_factory, error = porter.get_subfactories(player, export_string)

    local function add_into_label(caption)
        local label_info = content_frame.add{type="label", name="label_import_info", caption=caption}
        label_info.style.single_line = false
        label_info.style.top_margin = 8
        label_info.style.maximal_width = 375
    end

    if content_frame["label_import_info"] then content_frame["label_import_info"].destroy() end
    if content_frame["scroll_pane_subfactories"] then content_frame["scroll_pane_subfactories"].destroy() end

    if error ~= nil then
        add_into_label({"fp.error_message", {"fp.importer_" .. error}})
    else
        add_into_label({"fp.import_instruction_2"})
        get_modal_data(player).import_factory = import_factory

        local table_subfactories = setup_subfactories_table(content_frame, false)
        for _, subfactory in ipairs(Factory.get_in_order(import_factory, "Subfactory")) do
            add_to_subfactories_table(table_subfactories, subfactory, nil)
        end
        -- TODO Need to set the master checkbox status still, prolly with function below
    end

    content_frame.parent.parent.force_auto_center()
end


-- ** EXPORT DIALOG **
function export_dialog.open(flow_modal_dialog)
    local content_frame = initialize_dialog(flow_modal_dialog, "export")

    local table_subfactories = setup_subfactories_table(content_frame, true)

    local player_table = get_table(game.get_player(flow_modal_dialog.player_index))
    for _, factory_name in ipairs{"factory", "archive"} do
        for _, subfactory in ipairs(Factory.get_in_order(player_table[factory_name], "Subfactory")) do
            add_to_subfactories_table(table_subfactories, subfactory, factory_name)
        end
    end
    -- TODO Need to set the master checkbox status still, prolly with function below

    add_textfield_and_button(content_frame, "export", true, false)
end

-- Exports the currently selected subfactories and puts the resulting string into the textbox
function export_dialog.export_subfactories(player)
    local player_table = get_table(player)
    local content_frame = player.gui.screen["fp_frame_modal_dialog"]["flow_modal_dialog"]["frame_content"]
    local table_subfactories = content_frame["scroll_pane_subfactories"]["frame_subfactories"]["table_subfactories"]

    local subfactories_to_export = {}
    for _, factory_name in ipairs{"factory", "archive"} do
        for _, subfactory in ipairs(Factory.get_in_order(player_table[factory_name], "Subfactory")) do
            local subfactory_checkbox = table_subfactories["fp_checkbox_porter_subfactory_" .. factory_name
              .. "_" .. subfactory.id]

            if subfactory_checkbox.state == true then
                table.insert(subfactories_to_export, subfactory)
            end
        end
    end

    local export_string = porter.get_export_string(player, subfactories_to_export)

    local textfield_export_string = content_frame["flow_export_subfactories"]["fp_textfield_porter_string_export"]
    textfield_export_string.text = export_string
    ui_util.select_all(textfield_export_string)
end



-- ** SHARED **
-- Sets all slave checkboxes to the given state
function porter_dialog.set_all_checkboxes(player, checkbox_state)
    local content_frame = player.gui.screen["fp_frame_modal_dialog"]["flow_modal_dialog"]["frame_content"]
    local table_subfactories = content_frame["scroll_pane_subfactories"]["frame_subfactories"]["table_subfactories"]

    for _, element in pairs(table_subfactories) do
        if string.find(element.name, "^fp_checkbox_porter_subfactory_[a-z]+_%d+$") and element.enabled then
            element.state = checkbox_state
        end
    end

    if get_ui_state(player).modal_dialog_type == "export" then
        local button_export = content_frame["flow_export_subfactories"]["fp_button_porter_subfactory_export"]
        button_export.enabled = checkbox_state
    end
end

-- Sets the master checkbox to the appropriate state after a slave one is changed
function porter_dialog.adjust_after_checkbox_click(player)
    local content_frame = player.gui.screen["fp_frame_modal_dialog"]["flow_modal_dialog"]["frame_content"]
    local table_subfactories = content_frame["scroll_pane_subfactories"]["frame_subfactories"]["table_subfactories"]

    local checked_element_count, unchecked_element_count = 0, 0
    for _, element in pairs(table_subfactories.children) do
        if string.find(element.name, "^fp_checkbox_porter_subfactory_[a-z]+_%d+$") then
            if element.state == true then checked_element_count = checked_element_count + 1
            elseif element.enabled then unchecked_element_count = unchecked_element_count + 1 end
        end
    end

    table_subfactories["fp_checkbox_porter_master"].state = (unchecked_element_count == 0)

    if get_ui_state(player).modal_dialog_type == "export" then
        local button_export = content_frame["flow_export_subfactories"]["fp_button_porter_subfactory_export"]
        button_export.enabled = (checked_element_count > 0)
    end
end