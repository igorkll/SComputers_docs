dofile "$CONTENT_DATA/Scripts/Config.lua"

hdd = class(nil)
hdd.maxParentCount = 1
hdd.maxChildCount = 0
hdd.connectionInput = sm.interactable.connectionType.composite
hdd.colorNormal = sm.color.new(0xbf1996ff)
hdd.colorHighlight = sm.color.new(0xec1db9ff)
hdd.componentType = "disk"


function hdd:server_onFixedUpdate()
	sc.creativeCheck(self, not self.data)

	if self.changed and self.data and sc.needSaveData() then
		local data = self.fs:serialize()
		self.storage:save(data)

		self.changed = nil
	end
end

function hdd.server_onCreate(self)
	local data
	print("loading_hdd_content", pcall(function()
		data = self.storage:load()
	end))

	if data then
		self.fs = FileSystem.deserialize(data)
		if self.data then
			local newsize = math.floor(self.data.size)
			if math.floor(self.fs.maxSize) ~= newsize then
				print("old disk size", math.floor(self.fs.maxSize))
				print("new disk size", newsize)
				self.fs.maxSize = newsize
			else
				print("disk size:", newsize)
			end
		end
	else
		if self.data then
			self.fs = FileSystem.new(math.floor(self.data.size))
		else
			self.fs = FileSystem.new(1 * 1024 * 1024)
		end
	end
	self.changed = false

	local id = self.interactable:getId()
	sc.hardDiskDrivesDatas[id] = FileSystem.createSelfData(self)

	fsmanager_init(self)
	sc.creativeCheck(self, not self.data)
end

function hdd.server_onDestroy(self)
	local id = self.interactable:getId()
	sc.hardDiskDrivesDatas[id] = nil
end

-----------------------------------------------------------

function hdd:client_onCreate()
	fsmanager_init(self)
end

function hdd:client_onInteract(_, state)
	if state then
		fsmanager_open(self)
	end
end