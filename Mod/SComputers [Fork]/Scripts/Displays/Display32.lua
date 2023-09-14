dofile "$CONTENT_DATA/Scripts/Displays/DisplayBase.lua"

CompositeDisplay32 = class(nil)

CompositeDisplay32.maxParentCount = 1
CompositeDisplay32.maxChildCount = 0
CompositeDisplay32.connectionInput = sm.interactable.connectionType.composite
CompositeDisplay32.colorNormal = sm.color.new(0xbbbb1aff)
CompositeDisplay32.colorHighlight = sm.color.new(0xecec1fff)
CompositeDisplay32.componentType = "display"


-- SERVER --


function CompositeDisplay32.server_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 32, 32, 1)
	sc.display.server_init(self.display)
end

function CompositeDisplay32.server_onDestroy(self)
	sc.display.server_destroy(self.display)
end

function CompositeDisplay32.server_onFixedUpdate(self, dt)
	sc.display.server_update(self.display, dt)
end

function CompositeDisplay32.server_recvPress(self, p)
	sc.display.server_recvPress(self.display, p)
end

function CompositeDisplay32.server_onDataRequired(self, client)
	sc.display.server_onDataRequired(self.display, client)
end

-- CLIENT --

function CompositeDisplay32.client_onReceiveDrawStack(self, stack)
	sc.display.client_drawStack(self.display, stack)
end

function CompositeDisplay32.client_onCreate(self)
	self.display = self.display or sc.display.createDisplay(self, 32, 32, 1)
	sc.display.client_init(self.display)
end

function CompositeDisplay32.client_onDestroy(self)
	sc.display.client_destroy(self.display)
end

function CompositeDisplay32.client_onFixedUpdate(self, dt)
	sc.display.client_update(self.display, dt)
end

function CompositeDisplay32.client_onInteract(self, character, state)
	sc.display.client_onInteract(self.display, character, state)
end

function CompositeDisplay32.client_canInteract(self, character)
	return sc.display.client_canInteract(self.display, character)
end

function CompositeDisplay32.client_canTinker(self, character)
	return sc.display.client_canTinker(self.display, character)
end

function CompositeDisplay32.client_onTinker(self, character, state)
	sc.display.client_onTinker(self.display, character, state)
end
function CompositeDisplay32.client_onDataResponse(self, data)
	sc.display.client_onDataResponse(self.display, data)
end