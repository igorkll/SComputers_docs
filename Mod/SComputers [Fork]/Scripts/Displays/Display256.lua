dofile "$CONTENT_DATA/Scripts/Displays/DisplayBase.lua"

CompositeDisplay256 = class(nil)

CompositeDisplay256.maxParentCount = 1
CompositeDisplay256.maxChildCount = 0
CompositeDisplay256.connectionInput = sm.interactable.connectionType.composite
CompositeDisplay256.colorNormal = sm.color.new(0xbbbb1aff)
CompositeDisplay256.colorHighlight = sm.color.new(0xecec1fff)
CompositeDisplay256.componentType = "display"

-- SERVER --


function CompositeDisplay256.server_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 256, 256, .5)
	sc.display.server_init(self.display)
end

function CompositeDisplay256.server_onDestroy(self)
	sc.display.server_destroy(self.display)
end

function CompositeDisplay256.server_onFixedUpdate(self, dt)
	sc.display.server_update(self.display, dt)
end

function CompositeDisplay256.server_recvPress(self, p)
	sc.display.server_recvPress(self.display, p)
end

function CompositeDisplay256.server_onDataRequired(self, client)
	sc.display.server_onDataRequired(self.display, client)
end

-- CLIENT --

function CompositeDisplay256.client_onReceiveDrawStack(self, stack)
	sc.display.client_drawStack(self.display, stack)
end

function CompositeDisplay256.client_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 256, 256, .5)
	sc.display.client_init(self.display)
end

function CompositeDisplay256.client_onDestroy(self)
	sc.display.client_destroy(self.display)
end

function CompositeDisplay256.client_onFixedUpdate(self, dt)
	sc.display.client_update(self.display, dt)
end

function CompositeDisplay256.client_onInteract(self, character, state)
	sc.display.client_onInteract(self.display, character, state)
end

function CompositeDisplay256.client_canInteract(self, character)
	return sc.display.client_canInteract(self.display, character)
end

function CompositeDisplay256.client_canTinker(self, character)
	return sc.display.client_canTinker(self.display, character)
end

function CompositeDisplay256.client_onTinker(self, character, state)
	sc.display.client_onTinker(self.display, character, state)
end

function CompositeDisplay256.client_onDataResponse(self, data)
	sc.display.client_onDataResponse(self.display, data)
end