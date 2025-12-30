@tool
extends ProgrammaticTheme

const UPDATE_ON_SAVE = true

var font_ui := load("res://assets/bited.woff2")
var font_size_ui := 16
var font_icon := load("res://assets/UnifontExMono.woff")
var font_size_icon := 16
var font_uc := font_icon
var font_size_uc := 16
var font_tiny := load("res://assets/variad.woff2")
var font_size_tiny := 12

var color_bg: Color
var color_bg_2: Color
var color_fg: Color
var color_fg_2: Color
var color_border: Color
var color_warn: Color
var color_warn_2: Color
var color_danger: Color
var color_danger_2: Color
var color_danger_foc: Color
var color_dis: Color
var color_sel: Color
var color_edit: Color
var color_edit_sel: Color
var color_nop_sel: Color

var color_tip_bg: Color
var color_tip_fg: Color
var color_tip_border: Color

var color_win_dis: Color
var color_win_fg_2: Color

var color_grid_border: Color
var color_grid_origin: Color
var color_grid_asc: Color
var color_grid_cap: Color
var color_grid_desc: Color
var color_grid_w: Color
var color_grid_x: Color

var border_w := 1
var border_w_foc := 1

var ui_down := load("res://assets/ui/down.png")
var ui_up := load("res://assets/ui/up.png")
var ui_tree_arrow := load("res://assets/ui/tree_arrow.png")
var ui_select_arrow := load("res://assets/ui/select_arrow.png")
var ui_radio_uncheck := load("res://assets/ui/radio_unchecked.png")
var ui_radio_uncheck_dis := load("res://assets/ui/radio_unchecked_disabled.png")
var ui_radio_check := load("res://assets/ui/radio_checked.png")
var ui_close := load("res://assets/ui/close.png")
var ui_close_press := load("res://assets/ui/close_pressed.png")


func setup_dark():
	set_save_path("res://components/themes/dark.tres")

	color_bg = Color.BLACK
	color_bg_2 = Color.from_rgba8(38, 38, 38)
	color_fg = Color.WHITE
	color_fg_2 = Color.from_rgba8(163, 163, 163)
	color_border = Color.from_rgba8(38, 38, 38)
	color_warn = Color.from_rgba8(251, 146, 60)
	color_warn_2 = Color.from_rgba8(154, 52, 18)
	color_danger = Color.from_rgba8(220, 38, 38)
	color_danger_2 = Color.from_rgba8(153, 27, 27)
	color_danger_foc = Color.from_rgba8(248, 113, 113)
	color_dis = Color.from_rgba8(23, 23, 23)
	color_sel = Color.from_rgba8(30, 64, 175)
	color_edit = Color.from_rgba8(112, 16, 117)
	color_edit_sel = Color.from_rgba8(91, 33, 182)
	color_nop_sel = Color.from_rgba8(30, 41, 59)

	color_tip_bg = Color.BLACK
	color_tip_fg = Color.WHITE
	color_tip_border = Color.from_rgba8(115, 115, 115)

	color_win_dis = Color.from_rgba8(64, 64, 64)
	color_win_fg_2 = Color.from_rgba8(163, 163, 163)

	color_grid_border = Color.from_rgba8(23, 23, 23)
	color_grid_origin = Color.from_rgba8(82, 82, 82)
	color_grid_asc = Color.from_rgba8(131, 24, 67)
	color_grid_cap = Color.from_rgba8(127, 29, 29)
	color_grid_desc = Color.from_rgba8(22, 78, 99)
	color_grid_w = Color.from_rgba8(20, 83, 45)
	color_grid_x = Color.from_rgba8(113, 63, 18)


func setup_light():
	set_save_path("res://components/themes/light.tres")

	color_bg = Color.WHITE
	color_bg_2 = Color.from_rgba8(212, 212, 212)
	color_fg = Color.BLACK
	color_fg_2 = Color.from_rgba8(64, 64, 64)
	color_border = Color.BLACK
	color_warn = Color.from_rgba8(249, 115, 22)
	color_warn_2 = Color.from_rgba8(253, 186, 116)
	color_danger = Color.from_rgba8(220, 38, 38)
	color_danger_2 = Color.from_rgba8(248, 113, 113)
	color_danger_foc = Color.from_rgba8(220, 38, 38)
	color_dis = Color.from_rgba8(64, 64, 64)
	color_sel = Color.from_rgba8(96, 165, 250)
	color_edit = Color.from_rgba8(232, 121, 249)
	color_edit_sel = Color.from_rgba8(167, 139, 250)
	color_nop_sel = Color.from_rgba8(148, 163, 184)

	color_tip_bg = Color.BLACK
	color_tip_fg = Color.WHITE
	color_tip_border = Color.BLACK

	color_win_dis = Color.from_rgba8(64, 64, 64)
	color_win_fg_2 = Color.from_rgba8(163, 163, 163)

	color_grid_border = Color.from_rgba8(212, 212, 212)
	color_grid_origin = Color.from_rgba8(64, 64, 64)
	color_grid_asc = Color.from_rgba8(236, 72, 153)
	color_grid_cap = Color.from_rgba8(239, 68, 68)
	color_grid_desc = Color.from_rgba8(6, 182, 212)
	color_grid_w = Color.from_rgba8(34, 197, 94)
	color_grid_x = Color.from_rgba8(234, 179, 8)

	border_w_foc = 2


func define_theme():
	define_default_font(font_ui)
	define_default_font_size(font_size_ui)

	current_theme.set_color("bg", "Node", color_bg)
	current_theme.set_color("fg", "Node", color_fg)
	current_theme.set_color("border", "Node", color_border)
	current_theme.set_color("danger", "Node", color_danger)
	current_theme.set_color("dis", "Node", color_dis)
	current_theme.set_color("sel", "Node", color_sel)

	define_style("Label", {font_color = color_fg, line_spacing = 0})
	define_variant_style("Label2x", "Label", {font_size = font_size_ui * 2})
	define_variant_style("Muted", "Label", {font_color = color_fg_2})

	var style_panel = stylebox_flat(
		{
			bg_color = color_bg,
			border_color = color_border,
			corner_detail = 1,
			anti_aliasing = false,
		}
	)
	define_style("Panel", {panel = style_panel})
	define_style("PanelContainer", {panel = style_panel})

	define_variant_style(
		"Border",
		"PanelContainer",
		{panel = inherit(style_panel, {border_ = border_width(border_w)})}
	)
	define_variant_style(
		"BorderL", "PanelContainer", {panel = inherit(style_panel, {border_width_left = border_w})}
	)
	define_variant_style(
		"BorderT", "PanelContainer", {panel = inherit(style_panel, {border_width_top = border_w})}
	)
	define_variant_style(
		"BorderR", "PanelContainer", {panel = inherit(style_panel, {border_width_right = border_w})}
	)
	define_variant_style(
		"BorderB",
		"PanelContainer",
		{panel = inherit(style_panel, {border_width_bottom = border_w})}
	)

	var style_nobg = inherit(style_panel, {bg_color = Color.TRANSPARENT})
	var style_input = inherit(
		style_nobg,
		{
			border_ = border_width(border_w),
			content_ = content_margins(4),
		}
	)
	var style_input_foc = inherit(
		style_input, {border_color = color_fg, border_ = border_width(border_w_foc)}
	)
	var style_input_dis = inherit(style_input, {bg_color = color_bg_2})
	define_style(
		"TextEdit",
		{
			line_spacing = 0,
			caret_color = color_fg,
			font_color = color_fg,
			font_placeholder_color = Color(color_fg, 0.5),
			font_readonly_color = Color(color_fg, 0.5),
			search_result_color = color_warn_2,
			selection_color = color_sel,
			normal = style_input,
			focus = style_input_foc,
			read_only = style_input_dis,
		}
	)
	define_variant_style(
		"TextEditUC", "TextEdit", {font = font_uc, font_size = font_size_uc, line_spacing = -1}
	)

	define_style(
		"LineEdit",
		{
			caret_color = color_fg,
			clear_button_color = color_fg,
			clear_button_color_pressed = color_fg_2,
			font_color = color_fg,
			font_placeholder_color = Color(color_fg, 0.5),
			font_selected_color = color_fg,
			font_uneditable_color = Color(color_fg, 0.5),
			selection_color = color_sel,
			normal = style_input,
			focus = style_input_foc,
			read_only = style_input_dis,
		}
	)
	define_variant_style(
		"LineEditErr",
		"LineEdit",
		{
			normal = inherit(style_input, {border_color = color_danger}),
			focus = inherit(style_input_foc, {border_color = color_danger_foc}),
			read_only = inherit(style_input_dis, {border_color = color_danger}),
		}
	)

	var ui_down_base := mul_tex(ui_down, Color(color_fg, 0.5))
	var ui_up_base := mul_tex(ui_up, Color(color_fg, 0.5))
	define_style(
		"SpinBox",
		{
			down = ui_down_base,
			down_disabled = ui_down_base,
			down_hover = mul_tex(ui_down, color_fg_2),
			down_pressed = mul_tex(ui_down, color_fg),
			up = ui_up_base,
			up_disabled = ui_up_base,
			up_hover = mul_tex(ui_up, color_fg_2),
			up_pressed = mul_tex(ui_up, color_fg),
			down_background_hovered = stylebox_empty({}),
			down_background_pressed = stylebox_empty({}),
			up_background_hovered = stylebox_empty({}),
			up_background_pressed = stylebox_empty({}),
		}
	)

	var tree_arrow_down := mul_tex(ui_tree_arrow, color_bg_2)
	var tree_arrow_right := rotate_tex(tree_arrow_down, COUNTERCLOCKWISE)
	var tree_arrow_left := rotate_tex(tree_arrow_down, CLOCKWISE)
	define_style(
		"Tree",
		{
			draw_guides = 0,
			draw_relationship_lines = 1,
			inner_item_margin_left = 4,
			inner_item_margin_top = 4,
			inner_item_margin_right = 4,
			inner_item_margin_bottom = 4,
			relationship_line_color = color_bg_2,
			parent_hl_line_color = color_fg_2,
			children_hl_line_color = color_bg_2,
			custom_button_font_highlight = color_fg,
			drop_position_color = color_fg,
			font_color = color_fg_2,
			font_hovered_color = color_fg,
			font_selected_color = color_fg,
			font_hovered_selected_color = color_fg,
			arrow = tree_arrow_down,
			arrow_collapsed = tree_arrow_right,
			arrow_collapsed_mirrored = tree_arrow_left,
			panel =
			inherit(style_panel, {border_ = border_width(border_w), content_ = content_margins(0)}),
			hovered = inherit(style_panel, {bg_color = color_bg_2}),
			focus = inherit(style_input, {border_color = color_fg_2}),
			selected = style_input,
			hovered_selected = inherit(style_input, {bg_color = color_bg_2}),
			selected_focus = inherit(style_input, {border_color = color_fg_2}),
			hovered_selected_focus =
			inherit(style_input, {bg_color = color_bg_2, border_color = color_fg_2}),
		}
	)

	var make_style_btn := func(over = {}):
		var final := {
			color_bg = color_bg,
			color_bg_2 = color_bg_2,
			color_fg = color_fg,
			color_border = color_border,
			color_dis = color_dis,
		}
		final.merge(over, true)
		var style = inherit(style_input, {border_color = final.color_border})
		return {
			font_color = final.color_fg,
			font_disabled_color = Color(final.color_fg, 0.5),
			font_focus_color = final.color_fg,
			font_hover_color = final.color_fg,
			font_hover_pressed_color = final.color_bg,
			font_pressed_color = final.color_bg,
			icon_normal_color = final.color_fg,
			icon_disabled_color = Color(final.color_fg, 0.5),
			icon_focus_color = final.color_fg,
			icon_hover_color = final.color_fg,
			icon_hover_pressed_color = Color(final.color_bg, 0.5),
			icon_pressed_color = final.color_bg,
			normal = style,
			disabled = inherit(style, {border_color = final.color_dis}),
			focus =
			inherit(
				style,
				{
					border_color = final.color_fg,
					border_ = border_width(border_w_foc),
					expand_ = expand_margins(border_w_foc / 2),
				}
			),
			hover = inherit(style, {bg_color = final.color_bg_2}),
			pressed = inherit(style, {bg_color = final.color_fg, border_color = final.color_fg})
		}
	var style_btn = make_style_btn.call()
	define_style("Button", style_btn)
	define_variant_style(
		"ButtonWarn",
		"Button",
		(
			make_style_btn
			. call(
				{
					color_bg = color_warn,
					color_bg_2 = color_warn_2,
					color_fg = color_warn,
					color_border = color_warn,
					color_dis = color_warn_2,
				}
			)
		)
	)
	define_variant_style(
		"ButtonDanger",
		"Button",
		(
			make_style_btn
			. call(
				{
					color_bg = color_danger,
					color_bg_2 = color_danger_2,
					color_fg = color_danger,
					color_border = color_danger,
					color_dis = color_danger_2,
				}
			)
		)
	)
	define_variant_style("Op", "Button", {font = font_icon, font_size = font_size_icon})
	define_variant_style(
		"Tool",
		"Op",
		{
			font_color = color_fg_2,
			icon_normal_color = color_fg_2,
		}
	)

	define_style("OptionButton", {arrow = mul_tex(ui_select_arrow, Color(color_fg, 0.5))})
	var style_line = stylebox_line(
		{
			color = Color(color_fg, 0.5),
			content_margin_left = 4,
			content_margin_top = 0,
			content_margin_right = 4,
			content_margin_bottom = 0,
		}
	)
	define_style(
		"PopupMenu",
		{
			font_color = color_fg,
			font_hover_color = color_fg,
			font_separator_color = Color(color_fg, 0.5),
			radio_unchecked = mul_tex(ui_radio_uncheck, color_fg_2),
			radio_unchecked_disabled = mul_tex(ui_radio_uncheck_dis, color_dis),
			radio_checked = mul_tex(ui_radio_check, color_fg_2),
			radio_checked_disabled = mul_tex(ui_radio_check, color_dis),
			panel = inherit(style_panel, {border_ = border_width(border_w)}),
			hover = inherit(style_panel, {bg_color = color_bg_2}),
			labeled_separator_left = style_line,
			labeled_separator_right = style_line,
			separator = style_line,
		}
	)

	var style_tab = inherit(
		style_nobg,
		{
			content_margin_left = 8,
			content_margin_top = 4,
			content_margin_right = 8,
			content_margin_bottom = 4,
		}
	)
	var style_tab_border = inherit(
		style_tab,
		{
			border_width_left = 1,
			border_width_top = 1,
			border_width_right = 1,
		}
	)
	define_style(
		"TabBar",
		{
			font_unselected_color = color_fg_2,
			font_selected_color = color_tip_fg,
			font_hovered_color = color_fg_2,
			font_disabled_color = color_dis,
			tab_unselected = style_tab,
			tab_disabled = style_tab,
			tab_hovered = style_tab_border,
			tab_focus =
			inherit(style_tab_border, {border_color = color_fg, border_width_bottom = border_w}),
			tab_selected = inherit(style_tab_border, {bg_color = color_border}),
		}
	)

	var style_sep = stylebox_line(
		{
			color = color_border,
			grow_begin = 0,
			grow_end = 0,
			thickness = border_w,
		}
	)
	define_style("HSeparator", {separator = style_sep})
	define_style("VSeparator", {separator = inherit(style_sep, {vertical = true})})

	var style_scroll_thumb = inherit(style_input, {border_ = border_width(0)})
	var style_scroll_h = inherit(
		style_nobg,
		{
			content_margin_left = 0,
			content_margin_top = 4,
			content_margin_right = 0,
			content_margin_bottom = 4
		}
	)
	var style_scroll_v = inherit(
		style_nobg,
		{
			content_margin_left = 4,
			content_margin_top = 0,
			content_margin_right = 4,
			content_margin_bottom = 0
		}
	)
	define_style(
		"HScrollBar",
		{
			grabber = inherit(style_scroll_thumb, {bg_color = Color(color_fg, 0.25)}),
			grabber_highlight = inherit(style_scroll_thumb, {bg_color = Color(color_fg, 0.5)}),
			grabber_pressed = inherit(style_scroll_thumb, {bg_color = color_fg}),
			scroll = style_scroll_h,
			scroll_focus = style_scroll_h,
		}
	)
	define_style(
		"VScrollBar",
		{
			grabber = inherit(style_scroll_thumb, {bg_color = Color(color_fg, 0.25)}),
			grabber_highlight = inherit(style_scroll_thumb, {bg_color = Color(color_fg, 0.5)}),
			grabber_pressed = inherit(style_scroll_thumb, {bg_color = color_fg}),
			scroll = style_scroll_v,
			scroll_focus = style_scroll_v,
		}
	)

	var style_window = inherit(
		style_panel,
		{
			bg_color = color_border,
			expand_margin_left = 1,
			expand_margin_top = 32,
			expand_margin_right = 1,
			expand_margin_bottom = 1,
			content_margin_left = 10,
			content_margin_top = 28,
			content_margin_right = 10,
			content_margin_bottom = 8,
		}
	)
	define_style(
		"Window",
		{
			title_color = color_tip_fg,
			close_h_offset = 24,
			close_v_offset = 24,
			title_height = 32,
			close = mul_tex(ui_close, color_win_fg_2),
			close_pressed = mul_tex(ui_close_press, color_tip_fg),
			embedded_border = style_window,
			embedded_unfocused_border = inherit(style_window, {bg_color = color_win_dis}),
		}
	)

	define_variant_style(
		"Grid",
		"PanelContainer",
		{
			panel =
			inherit(
				style_panel,
				{
					border_color = color_grid_border,
					border_width_left = border_w,
					border_width_top = border_w
				}
			)
		}
	)
	current_theme.set_color("border", "Grid", color_grid_border)
	current_theme.set_color("origin", "Grid", color_grid_origin)
	current_theme.set_color("asc", "Grid", color_grid_asc)
	current_theme.set_color("cap", "Grid", color_grid_cap)
	current_theme.set_color("desc", "Grid", color_grid_desc)
	current_theme.set_color("w", "Grid", color_grid_w)
	current_theme.set_color("x", "Grid", color_grid_x)

	define_variant_style(
		"BgBorder",
		"PanelContainer",
		{panel = inherit(style_panel, {bg_color = color_border, border_ = border_width(border_w)})}
	)
	define_variant_style(
		"TableHeader",
		"Label2x",
		{font_color = color_fg_2},
	)
	define_variant_style(
		"TableSubHeader",
		"Label2x",
		{font_color = Color(color_fg, 0.5)},
	)

	define_style(
		"TooltipPanel",
		{
			panel =
			inherit(
				style_panel,
				{
					bg_color = color_tip_bg,
					border_color = color_tip_border,
					border_ = border_width(border_w),
					content_margin_left = 8,
					content_margin_top = 4,
					content_margin_right = 8,
					content_margin_bottom = 4,
				}
			)
		}
	)
	define_style("TooltipLabel", {font_color = color_tip_fg})

	define_variant_style(
		"GlyphSel", "PanelContainer", {panel = inherit(style_panel, {bg_color = color_sel})}
	)
	define_variant_style(
		"GlyphEdit", "PanelContainer", {panel = inherit(style_panel, {bg_color = color_edit})}
	)
	define_variant_style(
		"GlyphEditSel",
		"PanelContainer",
		{panel = inherit(style_panel, {bg_color = color_edit_sel})}
	)
	define_variant_style(
		"GlyphNop", "PanelContainer", {panel = inherit(style_panel, {bg_color = color_dis})}
	)
	define_variant_style(
		"GlyphNopSel", "PanelContainer", {panel = inherit(style_panel, {bg_color = color_nop_sel})}
	)
	define_variant_style(
		"GlyphTxt", "Label", {font_color = color_fg_2, font = font_tiny, font_size = font_size_tiny}
	)
	define_variant_style(
		"GlyphUC", "Label", {font_color = color_fg_2, font = font_uc, font_size = font_size_uc}
	)

	define_variant_style(
		"Charsets",
		"Tree",
		{
			panel = inherit(style_panel, {border_ = border_width(0)}),
			focus =
			inherit(
				style_input_foc,
				{
					border_color = color_fg_2,
					expand_margin_left = 12 + border_w_foc / 2,
				}
			)
		}
	)


func mul_tex(tex: Texture2D, color: Color) -> ImageTexture:
	return update_tex(
		tex,
		func(img: Image):
			for y in img.get_height():
				for x in img.get_width():
					img.set_pixel(x, y, img.get_pixel(x, y) * color)
			return img
	)


func rotate_tex(tex: Texture2D, dir: ClockDirection) -> ImageTexture:
	return update_tex(
		tex,
		func(img: Image):
			img.rotate_90(dir)
			return img
	)


func flip_y_tex(tex: Texture2D) -> ImageTexture:
	return update_tex(
		tex,
		func(img: Image):
			img.flip_y()
			return img
	)


func update_tex(tex: Texture2D, f: Callable) -> ImageTexture:
	var img := tex.get_image()
	return ImageTexture.create_from_image(
		f.call(img.get_region(Rect2i(Vector2i.ZERO, img.get_size())))
	)
