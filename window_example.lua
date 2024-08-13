window_library = require("window_library")
term.clear()

display = window_library.Display_manager:ini_new()
maincanvas = window_library.Canvas_window:new({ anchor_x = 3, anchor_y = 3, size_x = 10, size_y = 10 })

element1 = window_library.UI_element:new({
	anchor_x = 1,
	anchor_y = 2,
	size_x = 20,
	size_y = 2,
	content = "daesdabfurncdddnd12345132614328572346234623574386",
})
element2 = window_library.UI_element:new({
	anchor_x = 2,
	anchor_y = 20,
	size_x = 4,
	size_y = 9,
	content = "daedfidhfihfidsfhidhfidshfidfhisdfhidfhdisfhsdabfurnceiefncecdfdf",
})

maincanvas:element_add(element1)
maincanvas:element_add(element2)
display:canvas_add(maincanvas)
while true do
	display:render()
	display:pullevent()
end
