local U = require("extrabuilds_utils")

local DEFAULT_MEAT_BUILD = "meat_rack_food"

local function interiorcheck(inst)
	if U.enabledPORK then
		inst:UpdateIsInInterior()
		return inst:CheckIsInInterior()
	else return false end
end

local DryingRack = Class(function(self, inst, container)
	self.inst = inst
	self.container = container or inst.components.container
	self.enabled = false
	self.dryingpaused = true
	self.dryinginfo = {}
	self.showitemfn = nil
	self.hideitemfn = nil

	self.onrainstart = function()
		if not interiorcheck(self.inst) then self:PauseDrying() end
	end

	self.onrainstop = function()
		self:ResumeDrying()
	end

	inst:ListenForEvent("itemget", function(_, data)
		if data and data.item then
			self:OnGetItem(data.item, data.slot)
		end
	end, self.container.inst)
	inst:ListenForEvent("itemlose", function(_, data)
		if data then
			self:OnLoseItem(data)
		end
	end, self.container.inst)
end)

function DryingRack:OnRemoveFromEntity()
	self:DisableDrying()
	
	if self.container.inst ~= self.inst then
		self.container:DropEverything()
		self.container.inst:Remove()
	end
end

function DryingRack:GetContainer()
	return self.container
end

function DryingRack:SetShowItemFn(fn)
	self.showitemfn = fn
end

function DryingRack:SetHideItemFn(fn)
	self.hideitemfn = fn
end

function DryingRack:GetItemInSlot(slot)
	local item = self.container:GetItemInSlot(slot)
	if item then
		local build
		local info = self.dryinginfo[item]
		if info then
			build = info.build
		end
		return item, item.prefab, build or DEFAULT_MEAT_BUILD
	end
end

function DryingRack:EnableDrying()
	if not self.enabled then
		self.enabled = true

		if U.enabledAnyDLC then
			self.inst:ListenForEvent("rainstart", self.onrainstart, GetWorld())
			self.inst:ListenForEvent("rainstop", self.onrainstop, GetWorld())
		end

		if self.inst.components.rideable then
			self._onriderchanged = function(inst, data)
				if self:IsExposedToRain() then
					self:PauseDrying()
				else
					self:ResumeDrying()
				end
			end
			self.inst:ListenForEvent("riderchanged", self._onriderchanged)
		end

		if not self:IsExposedToRain() then
			self:ResumeDrying()
		end
	end
end

function DryingRack:DisableDrying()
	if self.enabled then
		self.enabled = false

		if self._onriderchanged then
			self.inst:RemoveEventCallback("riderchanged", self._onriderchanged)
			self._onriderchanged = nil
		end

		if U.enabledAnyDLC then
			self.inst:RemoveEventCallback("rainstart", self.onrainstart, GetWorld())
			self.inst:RemoveEventCallback("rainstop", self.onrainstop, GetWorld())
		end

		self._onrainimmunity = nil
		self._onrainvulnerable = nil

		if self._onriderchanged then
			self.inst:RemoveEventCallback("riderchanged", self._onriderchanged)
			self._onriderchanged = nil
		end

		self:PauseDrying()
	end
end

local function OnDoneDrying(inst, self, item)
	self.dryinginfo[item] = nil
	local slot = self.container:GetItemSlot(item)
	local product = item.components.dryable and item.components.dryable:GetProduct() or nil
	if slot and product then
		product = SpawnPrefab(product)
		if product then
			local build = DEFAULT_MEAT_BUILD
			if U.enabledAnyDLC then
				item:ApplyInheritedMoisture(product)
			end
			item:Remove()
			self:_dbg_print("Done drying", product.prefab)
			self.container:GiveItem(product, slot)
			local info = self.dryinginfo[product]
			if info == nil then --just making sure it's not another dryable item
				if build ~= DEFAULT_MEAT_BUILD then
					self.dryinginfo[product] = { build = build }
				end
				if self.showitemfn then
					self.showitemfn(self.inst, slot, product.prefab, build)
				end
			end
			return product --returned for LongUpdate
		end
	end
end

local function ForgetItem(item)
	item:RemoveEventCallback("stacksizechange", ForgetItem)
	item:RemoveEventCallback("ondropped", ForgetItem)
	item.dryingrack_drytime = nil
end

function DryingRack:OnGetItem(item, slot)
	local resumedrytime = item.dryingrack_drytime
	if resumedrytime then
		ForgetItem(item)
	end
	if item.dryingrack_lastinfo then
		item.dryingrack_lastinfo:Cancel()
		item.dryingrack_lastinfo = nil
	end
	local info = self.dryinginfo[item]
	if info == nil then
		if item.components.dryable then
			local product = item.components.dryable:GetProduct()
			local drytime = item.components.dryable:GetDryingTime()
			if resumedrytime then
				drytime = math.min(math.max(10, resumedrytime), drytime)
			end
			if product and drytime then
				info = {}
				self.dryinginfo[item] = info
				if self.dryingpaused then
					self:_dbg_print("Start drying (paused)", item, drytime)
					info.drytime = drytime
				else
					self:_dbg_print("Start drying", item, drytime)
					info.task = self.inst:DoTaskInTime(drytime, OnDoneDrying, self, item)
				end
			end
			if slot and self.showitemfn then
				self.showitemfn(self.inst, slot, item.prefab, DEFAULT_MEAT_BUILD)
			end
		elseif slot and self.showitemfn then
			self.showitemfn(self.inst, slot, item.prefab, DEFAULT_MEAT_BUILD)
		end
	end
end

local function ClearDryingRackLastInfo(item)
	item.dryingrack_lastinfo = nil
end

function DryingRack:OnLoseItem(data)
	local slot = data.slot
	if data.prev_item then
		local item = data.prev_item
		local info = self.dryinginfo[item]
		if info then
			if info.task or info.drytime then
				self:_dbg_print("Stop drying", item)
				if item:IsValid() and item.dryingrack_drytime == nil then
					item.dryingrack_drytime = info.drytime or GetTaskRemaining(info.task)
					item:ListenForEvent("stacksizechange", ForgetItem)
					item:ListenForEvent("ondropped", ForgetItem)
				end
				if info.task then
					info.task:Cancel()
				end
			end
			self.dryinginfo[item] = nil
		end
		if item:IsValid() then
			if slot then
				if item.dryingrack_lastinfo then
					item.dryingrack_lastinfo:Cancel()
				end
				item.dryingrack_lastinfo = item:DoTaskInTime(0, ClearDryingRackLastInfo)
				item.dryingrack_lastinfo.container = self.container
				item.dryingrack_lastinfo.slot = slot
			end
		end
	end
	if self.hideitemfn and slot then
		local prefab = data.prev_item and data.prev_item.prefab or nil
		self.hideitemfn(self.inst, slot, prefab)
	end
end

function DryingRack:IsExposedToRain()
	return GetSeasonManager():IsRaining()
end

function DryingRack:PauseDrying()
	if not self.dryingpaused then
		self.dryingpaused = true
		self:_dbg_print("Drying paused")
		for item, info in pairs(self.dryinginfo) do
			if info.task then
				info.drytime = GetTaskRemaining(info.task)
				self:_dbg_print("--", item, info.drytime)
				info.task:Cancel()
				info.task = nil
			end
		end
	end
end

function DryingRack:ResumeDrying()
	if self.dryingpaused then
		self.dryingpaused = false
		self:_dbg_print("Drying resumed")
		for item, info in pairs(self.dryinginfo) do
			if info.drytime then
				self:_dbg_print("--", item, info.drytime)
				info.task = self.inst:DoTaskInTime(info.drytime, OnDoneDrying, self, item)
				info.drytime = nil
			end
		end
	end
end

local function InstantDry(item, container)
	local slot = container:GetItemSlot(item)
	local product = item.components.dryable and item.components.dryable:GetProduct() or nil

	if slot and product then
		if container.inst.components.lootdropper then
			container.inst.components.lootdropper:SpawnLootPrefab(product)
		end
		item:Remove()
	end
end

function DryingRack:OnBurnt() --Called by DefaultBurntStructureFn
	for _, v in pairs(self.container.slots) do
        InstantDry(v, self.container)
    end
end

function DryingRack:LongUpdate(dt)
	if self.enabled then
		local todone = {}
		for item, info in pairs(self.dryinginfo) do
			if info.task then
				local t = GetTaskRemaining(info.task)
				info.task:Cancel()
				if t > dt then
					info.task = self.inst:DoTaskInTime(t - dt, OnDoneDrying, self, item)
				else
					table.insert(todone, { item = item, dt = dt - t })
				end
			elseif info.drytime then
				if info.drytime > dt then
					info.drytime = info.drytime - dt
				else
					table.insert(todone, { item = item, dt = dt - info.drytime })
				end
			end
		end
		for i, v in ipairs(todone) do
			local product = OnDoneDrying(self.inst, self, v.item)
			if product and v.dt > 0 then
				product:LongUpdate(v.dt)
			end
		end
	end
end

function DryingRack:OnSave()
	if not self.container:IsEmpty() then
		local info
		for k, v in pairs(self.dryinginfo) do
			local slot = self.container:GetItemSlot(k)
			if slot then
				info = info or {}
				info[slot] =
					(v.task and math.floor(GetTaskRemaining(v.task))) or
					(v.drytime and math.floor(v.drytime)) or
					v.build
			end
		end
---@diagnostic disable-next-line: unbalanced-assignments
		local data, refs = info and { info = info }
		if self.container.inst ~= self.inst then
			data = data or {}
			data.contents, refs = self.container.inst:GetPersistData()
		end
		return data, refs
	end
end

function DryingRack:OnLoad(data, newents)
	if self.container.inst ~= self.inst then
		if data.contents then
			self.container.inst:SetPersistData(data.contents, newents)
			self:LoadInfo_Internal(data)
		end
	end
end

function DryingRack:LoadPostPass(newents, data)
	if self.container.inst == self.inst then
		--deferred till LoadPostPass to make sure container data is loaded first
		self:LoadInfo_Internal(data)
	end
end

function DryingRack:LoadInfo_Internal(data)
	if data.info then
		for k, v in pairs(data.info) do
			local item = self.container:GetItemInSlot(k)
			if item then
				local info = self.dryinginfo[item]
				if type(v) == "number" then
					if info then
						if info.task then
							info.task:Cancel()
							info.task = self.inst:DoTaskInTime(v, OnDoneDrying, self, item)
							self:_dbg_print("Restart drying", item, v)
						elseif info.drytime then
							info.drytime = v
							self:_dbg_print("Restart drying (paused)", item, v)
						end
					end
				elseif info == nil then
					self.dryinginfo[item] = { build = v }
					if self.showitemfn then
						self.showitemfn(self.inst, k, item.prefab, v)
					end
				end
			end
		end
	end
end

function DryingRack:GetDryingInfoSnapshot()
	local info = {}
	for k, v in pairs(self.dryinginfo) do
		info[k] =
			(v.task and GetTaskRemaining(v.task)) or
			(v.drytime and v.drytime) or
			v.build
	end
	return next(info) and info or nil
end

function DryingRack:ApplyDryingInfoSnapshot(snapshot)
	for k, v in pairs(snapshot) do
		local info = self.dryinginfo[k]
		if type(v) == "number" then
			if info then
				if info.task then
					info.task:Cancel()
					info.task = self.inst:DoTaskInTime(v, OnDoneDrying, self, k)
					self:_dbg_print("Restart drying", k, v)
				elseif info.drytime then
					info.drytime = v
					self:_dbg_print("Restart drying (paused)", k, v)
				end
			end
		elseif info == nil then
			local slot = self.container:GetItemSlot(k)
			if slot then
				self.dryinginfo[k] = { build = v }
				if self.showitemfn then
					self.showitemfn(self.inst, slot, k.prefab, v)
				end
			end
		end
	end
end

function DryingRack:_dbg_print(...)
	--print("/AAT DryingRack:", ...)
end

return DryingRack
