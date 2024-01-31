dofile "$MOD_DATA/Scripts/Config.lua"

NetworkPort = class(nil)

NetworkPort.maxParentCount = -1
NetworkPort.maxChildCount = -1
NetworkPort.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.networking
NetworkPort.connectionOutput = sm.interactable.connectionType.networking
NetworkPort.colorNormal = sm.color.new(0xedc84cff)
NetworkPort.colorHighlight = sm.color.new(0xebcf71ff)

NetworkPort.MAX_STORED_PACKETS = 128

-- CLIENT --

--[[
function NetworkPort.getParentCount(self, connectionType)
	return #
end

function NetworkPort.getChildCount(self, connectionType)
	return #self.interactable:getChildren(connectionType)
end

function NetworkPort.getNetworkConnectionsCount(self)
	return self:getChildCount() + self:getParentCount(sm.interactable.connectionType.networking)
end

function NetworkPort.client_getAvailableChildConnectionCount(self, connectionType)
	return 1 - self:getNetworkConnectionsCount()
end


]]

function NetworkPort.client_getAvailableParentConnectionCount(self, connectionType)
	local checks = sm.interactable.connectionType.composite
	if bit.band(connectionType, checks) ~= 0 then
		return 1 - #self.interactable:getParents(checks)
	end
	return 1
end



-- SERVER --

function NetworkPort:getUniqueId()
	return self.interactable:getId()
end

function NetworkPort.createData(self)
	return {
		getMaxPacketsCount = function () return NetworkPort.MAX_STORED_PACKETS end,
		getPacketsCount = function () 
			return #self.packets
		end,
		nextPacket = function () 
			local packet = table.remove(self.packets, 1)
			if not packet then return nil, nil end
			return packet.data, packet.source
		end,
		send = function (packet)
			checkArg(1, packet, "string")
			self:server_putPacket(packet)
		end,
		sendTo = function (id, packet)
			checkArg(1, id, "number")
			checkArg(2, packet, "string")
			self:server_putPacket(packet, id)
		end,
		clear = function ()
			self.packets = {}
		end,
		getUniqueId = function ()
			return self:getUniqueId()
		end
	}
end

-- interface method
function NetworkPort.propagatePackets(self, packets) --получения
	local packs = self.packets
	local id = self:getUniqueId()

	local max = NetworkPort.MAX_STORED_PACKETS
	local insert = table.insert

	local dcopy = sc.deepcopy

	for i, packet in ipairs(packets) do
		if not packet.id or packet.id == id then
			if #packs <= max then
				insert(packs, dcopy(packet))
			else
				break
			end
		end
	end
end

function NetworkPort.server_putPacket(self, packet, id) --помешения на отправку из компа
	assert(type(packet) == "string", "network data must be string")
	if #self.packetsToSend < NetworkPort.MAX_STORED_PACKETS then
		table.insert(self.packetsToSend, {
			data = packet,
			id = id,
			source = self:getUniqueId()
		})
	else
		error("packet buffer overflow")
	end
end

function NetworkPort.server_sendPackets(self) --отправка
	local childs = self.interactable:getChildren(sm.interactable.connectionType.networking) or {}
	local parents = self.interactable:getParents(sm.interactable.connectionType.networking) or {}

	for index, child in ipairs(childs) do
		local script = sc.networking[child:getId()]
		if script then
			script:propagatePackets(self.packetsToSend)
		end
	end
	for index, parent in ipairs(parents) do
		local script = sc.networking[parent:getId()]
		if script then
			script:propagatePackets(self.packetsToSend)
		end
	end

	self.packetsToSend = {}
end

function NetworkPort.server_onCreate(self)
	self.packets = {}
	self.packetsToSend = {}

	local id = self.interactable:getId()

	sc.networkPortsDatas[id] = self:createData()
	sc.networking[id] = self
end

function NetworkPort.server_onDestroy(self)
	local id = self.interactable:getId()

	sc.networkPortsDatas[id] = nil
	sc.networking[id] = nil
end

function NetworkPort.server_onFixedUpdate(self, dt)
	if #self.packetsToSend > 0 then
		self:server_sendPackets()
	end
end