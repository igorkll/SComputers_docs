dofile "$CONTENT_DATA/Scripts/Displays/DisplayBase.lua"

CompositeDisplay64x2 = class(nil)

CompositeDisplay64x2.maxParentCount = 1
CompositeDisplay64x2.maxChildCount = 0
CompositeDisplay64x2.connectionInput = sm.interactable.connectionType.composite
CompositeDisplay64x2.colorNormal = sm.color.new(0xbbbb1aff)
CompositeDisplay64x2.colorHighlight = sm.color.new(0xecec1fff)
CompositeDisplay64x2.componentType = "display"


-- SERVER --


function CompositeDisplay64x2.server_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 64, 64, 2)
	sc.display.server_init(self.display)
end

function CompositeDisplay64x2.server_onDestroy(self)
	sc.display.server_destroy(self.display)
end

function CompositeDisplay64x2.server_onFixedUpdate(self, dt)
	sc.display.server_update(self.display, dt)
end

function CompositeDisplay64x2.server_recvPress(self, p)
	sc.display.server_recvPress(self.display, p)
end

function CompositeDisplay64x2.server_onDataRequired(self, client)
	sc.display.server_onDataRequired(self.display, client)
end

-- CLIENT --

function CompositeDisplay64x2.client_onReceiveDrawStack(self, stack)
	sc.display.client_drawStack(self.display, stack)
end

function CompositeDisplay64x2.client_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 64, 64, 2)
	sc.display.client_init(self.display)
end

function CompositeDisplay64x2.client_onDestroy(self)
	sc.display.client_destroy(self.display)
end

function CompositeDisplay64x2.client_onFixedUpdate(self, dt)
	sc.display.client_update(self.display, dt)
end

function CompositeDisplay64x2.client_onInteract(self, character, state)
	sc.display.client_onInteract(self.display, character, state)
end

function CompositeDisplay64x2.client_canInteract(self, character)
	return sc.display.client_canInteract(self.display, character)
end

function CompositeDisplay64x2.client_canTinker(self, character)
	return sc.display.client_canTinker(self.display, character)
end

function CompositeDisplay64x2.client_onTinker(self, character, state)
	sc.display.client_onTinker(self.display, character, state)
end

function CompositeDisplay64x2.client_onDataResponse(self, data)
	sc.display.client_onDataResponse(self.display, data)
end