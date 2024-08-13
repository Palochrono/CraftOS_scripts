local UI_element = {
	anchor_x = 1,
	anchor_y = 1,
	size_x = 1,
	size_y = 1,
	content = "a",
	bg = colors.gray,
	fg = colors.green,
	label = "default data",
	pressed_state = 0,
}

function UI_element:new(params)
	local o = params or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function UI_element:render(real_x, real_y, boundxmin, boundymin, boundxmax, boundymax)
	for char_i = 1, #self.content do
		local char = self.content:sub(char_i, char_i)
		-- figure out positions
		local x_pos = (char_i - 1) % self.size_x
		local y_pos = math.floor((char_i - 1) / self.size_x)
		local to_draw_x = real_x + x_pos
		local to_draw_y = real_y + y_pos
		if to_draw_x <= boundxmax and to_draw_x >= boundxmin and to_draw_y <= boundymax and to_draw_y >= boundymin then
			term.setBackgroundColor(self.bg)
			term.setTextColor(self.fg)
			term.setCursorPos(to_draw_x, to_draw_y)
			print(char)
		end
	end
end

function UI_element:on_click(ev)
	self.click_posx = ev.para2
	self.click_posy = ev.para3
	self.pressed_state = 1
	self.fg = colors.yellow
end

function UI_element:on_release()
	self.pressed_state = 0
	self.fg = colors.green
end

function UI_element:on_drag(ev)
	-- nothing
end

function UI_element:update()
	--nothing, can do update based on internal properties
end

local Hbar_object_base = UI_element:new({ bg = colors.gray })

function Hbar_object_base:update()
	-- update properties
	self.show = false
	if self.canvas.virtual_x_size > self.canvas.size_x then
		self.size_x = self.canvas.size_x
		self.size_y = 1
		self.content = string.rep("-", self.size_x)
		self.anchor_x = 1
		self.anchor_y = self.canvas.size_y + 1
		self.show = true
	end
end

local Hbar_object_top = UI_element:new({ bg = colors.yellow })

function Hbar_object_top:update()
	-- change position and length
	self.show = false
	if self.canvas.virtual_x_size > self.canvas.size_x then
		self.size_x = math.floor((self.canvas.size_x ^ 2) / self.canvas.virtual_x_size) + 1
		self.content = string.rep("|", self.size_x)
		self.size_y = 1
		self.anchor_x = 1
			+ math.floor(
				(self.canvas.size_x - self.size_x)
					* -self.canvas.virtual_offset_x
					/ (self.canvas.virtual_x_size - self.canvas.size_x)
			)
		self.anchor_y = self.canvas.size_y + 1
		self.show = true
	end
end

function Hbar_object_top:on_click(ev)
	self.click_posx = ev.para2
	self.click_posy = ev.para3
	self.offsetx_init = self.canvas.virtual_offset_x
	self.pressed_state = 1
end

function Hbar_object_top:on_drag(ev)
	local max_offset = self.canvas.virtual_x_size - self.canvas.size_x
	-- move
	local deltax = ev.para2 - self.click_posx
	self.canvas.virtual_offset_x = math.max(math.min(self.offsetx_init - deltax, 0), -max_offset)
end

local Vbar_object_base = UI_element:new({ bg = colors.gray })

function Vbar_object_base:update()
	-- update properties
	self.show = false
	if self.canvas.virtual_y_size > self.canvas.size_y then
		self.size_y = self.canvas.size_y
		self.size_x = 1
		self.content = string.rep("|", self.size_y)
		self.anchor_x = self.canvas.size_x + 1
		self.anchor_y = 1
		self.show = true
	end
end

local Vbar_object_top = UI_element:new({ bg = colors.yellow })

function Vbar_object_top:update()
	-- change position and length
	self.show = false
	if self.canvas.virtual_y_size > self.canvas.size_y then
		self.size_y = math.floor((self.canvas.size_y ^ 2) / self.canvas.virtual_y_size) + 1
		self.content = string.rep("=", self.size_y)
		self.size_x = 1
		self.anchor_y = 1
			+ math.floor(
				(self.canvas.size_y - self.size_y)
					* -self.canvas.virtual_offset_y
					/ (self.canvas.virtual_y_size - self.canvas.size_y)
			)
		self.anchor_x = self.canvas.size_x + 1
		self.show = true
	end
end

function Vbar_object_top:on_click(ev)
	self.click_posx = ev.para2
	self.click_posy = ev.para3
	self.offsety_init = self.canvas.virtual_offset_y
	self.pressed_state = 1
end

function Vbar_object_top:on_drag(ev)
	local max_offset = self.canvas.virtual_y_size - self.canvas.size_y
	-- move
	local deltay = ev.para3 - self.click_posy
	self.canvas.virtual_offset_y = math.max(math.min(self.offsety_init - deltay, 0), -max_offset - 1)
end

local Canvas_window = {
	anchor_x = 1,
	anchor_y = 1,
	size_x = 1,
	size_y = 1,
	virtual_offset_x = 0,
	virtual_offset_y = 0,
	element_list = {},
	rendermap = {},
	decoration_map = {},
	decorations = {},
	bg = colors.black,
}

function Canvas_window:new(params)
	local o = params or {}
	setmetatable(o, self)
	self.__index = self
	local hbar_base = Hbar_object_base:new({ canvas = o })
	local hbar_top = Hbar_object_top:new({ canvas = o })
	local vbar_base = Vbar_object_base:new({ canvas = o })
	local vbar_top = Vbar_object_top:new({ canvas = o })
	o.decorations[1] = hbar_base
	o.decorations[2] = hbar_top
	o.decorations[3] = vbar_base
	o.decorations[4] = vbar_top
	return o
end

function Canvas_window:element_add(elem_obj)
	table.insert(self.element_list, elem_obj)
end

function Canvas_window:handle_event(ev)
	-- on click
	-- -- look for boundary, trigger on-click function
	for i_elem, bounds in ipairs(self.rendermap) do
		if ev.name == "mouse_click" then
			if
				bounds.boundxmin <= ev.para2
				and bounds.boundxmax >= ev.para2
				and bounds.boundymin <= ev.para3
				and bounds.boundymax >= ev.para3
			then
				self.element_list[i_elem]:on_click(ev)
			end
		end
		if ev.name == "mouse_up" then
			self.element_list[i_elem]:on_release()
		end
		if ev.name == "mouse_drag" then
			if self.element_list[i_elem].pressed_state == 1 then
				self.element_list[i_elem]:on_drag(ev)
			end
		end
	end
	-- handle_decoration event
	for i_elem, bounds in ipairs(self.decoration_map) do
		if ev.name == "mouse_click" then
			if
				bounds.boundxmin <= ev.para2
				and bounds.boundxmax >= ev.para2
				and bounds.boundymin <= ev.para3
				and bounds.boundymax >= ev.para3
			then
				self.decorations[i_elem]:on_click(ev)
			end
		end
		if ev.name == "mouse_up" then
			self.decorations[i_elem]:on_release()
		end
		if ev.name == "mouse_drag" then
			if self.decorations[i_elem].pressed_state == 1 then
				self.decorations[i_elem]:on_drag(ev)
			end
		end
	end
end

function Canvas_window:render()
	-- clear canvas
	for x_iter = self.anchor_x, self.size_x + self.anchor_x - 1 do
		for y_iter = self.anchor_y, self.size_y + self.anchor_y - 1 do
			term.setBackgroundColor(self.bg)
			term.setCursorPos(x_iter, y_iter)
			print(" ")
		end
	end
	-- grab all element in element_list
	local x_min = self.virtual_offset_x + self.anchor_x + self.element_list[1].anchor_x - 1
	local y_min = self.virtual_offset_y + self.anchor_y + self.element_list[1].anchor_y - 1
	local x_max = x_min + self.element_list[1].size_x - 1
	local y_max = y_min + self.element_list[1].size_y - 1
	for i_elem, element in ipairs(self.element_list) do
		element:update()
		local real_x_min = self.virtual_offset_x + self.anchor_x + element.anchor_x - 1
		local real_y_min = self.virtual_offset_y + self.anchor_y + element.anchor_y - 1
		local real_x_max = real_x_min + element.size_x - 1
		local real_y_max = real_y_min + element.size_y - 1
		-- detecting limit of canvas
		x_min = math.min(real_x_min, x_min)
		y_min = math.min(real_y_min, y_min)
		x_max = math.max(real_x_max, x_max)
		y_max = math.max(real_y_max, y_max)
		-- determine if in bound
		self.rendermap[i_elem] = { boundxmin = -1, boundymin = -1, boundxmax = -1, boundymax = -1 }
		local canvas_x_max = self.anchor_x + self.size_x - 1
		local canvas_y_max = self.anchor_y + self.size_y - 1

		if
			real_x_min <= canvas_x_max
			and real_y_min <= canvas_y_max
			and real_x_max >= self.anchor_x
			and real_y_max >= self.anchor_y
		then
			self.rendermap[i_elem].boundxmin = math.max(real_x_min, self.anchor_x)
			self.rendermap[i_elem].boundymin = math.max(real_y_min, self.anchor_y)
			self.rendermap[i_elem].boundxmax = math.min(real_x_max, canvas_x_max)
			self.rendermap[i_elem].boundymax = math.min(real_y_max, canvas_y_max)
			element:render(
				real_x_min,
				real_y_min,
				self.rendermap[i_elem].boundxmin,
				self.rendermap[i_elem].boundymin,
				self.rendermap[i_elem].boundxmax,
				self.rendermap[i_elem].boundymax
			)
		end
	end
	self.virtual_x_size = x_max - x_min + 1
	self.virtual_y_size = y_max - y_min + 1
	-- render decorations
	self.decoration_map = {}
	for i_elem, element in ipairs(self.decorations) do
		element:update()
		self.decoration_map[i_elem] = { boundxmin = -1, boundymin = -1, boundxmax = -1, boundymax = -1 }
		if element.show == true then
			self.decoration_map[i_elem] = {
				boundxmin = self.anchor_x + element.anchor_x - 1,
				boundymin = self.anchor_y + element.anchor_y - 1,
				boundxmax = self.anchor_x + element.anchor_x + element.size_x - 2,
				boundymax = self.anchor_y + element.anchor_y + element.size_y - 2,
			}
			element:render(
				self.decoration_map[i_elem].boundxmin,
				self.decoration_map[i_elem].boundymin,
				self.decoration_map[i_elem].boundxmin,
				self.decoration_map[i_elem].boundymin,
				self.decoration_map[i_elem].boundxmax,
				self.decoration_map[i_elem].boundymax
			)
		end
	end
end

local Display_manager = { Canvas_list = {} }

function Display_manager:ini_new()
	local o = {}
	setmetatable(o, Display_manager)
	-- get window size
	-- get device info and stuff
	self.__index = self
	self.termx, self.termy = term.getSize()
	return o
end

function Display_manager:canvas_add(canvas_obj)
	table.insert(self.Canvas_list, canvas_obj)
end

function Display_manager:render()
	for _, canvas_obj in ipairs(self.Canvas_list) do
		canvas_obj:render()
	end
end

function Display_manager:pullevent()
	local ev = {}
	ev.name, ev.para1, ev.para2, ev.para3, ev.para4 = os.pullEvent()
	-- figure out event type
	for _, canvas_obj in ipairs(self.Canvas_list) do
		canvas_obj:handle_event(ev)
	end
end
-- example code
--
-- term.clear()
--
-- display = Display_manager:ini_new()
-- maincanvas = Canvas_window:new({ anchor_x = 3, anchor_y = 3, size_x = 10, size_y = 10 })
--
-- element1 = UI_element:new({
-- 	anchor_x = 1,
-- 	anchor_y = 2,
-- 	size_x = 20,
-- 	size_y = 2,
-- 	content = "daesdabfurncdddnd12345132614328572346234623574386",
-- })
-- element2 = UI_element:new({
-- 	anchor_x = 2,
-- 	anchor_y = 20,
-- 	size_x = 4,
-- 	size_y = 9,
-- 	content = "daedfidhfihfidsfhidhfidshfidfhisdfhidfhdisfhsdabfurnceiefncecdfdf",
-- })
--
-- maincanvas:element_add(element1)
-- maincanvas:element_add(element2)
-- display:canvas_add(maincanvas)
-- while true do
-- 	display:render()
-- 	display:pullevent()
-- end
local window_lib =
	{ UI_element = UI_element:new(), Canvas_window = Canvas_window:new(), Display_manager = Display_manager:ini_new() }
return window_lib
