require "prefabutil"
local U = require("extrabuilds_utils")

local assets =
{
	Asset("ANIM", "anim/ui_meatrack_multi_3x1.zip"),

	Asset("ANIM", "anim/meat_rack_multi.zip"),
	Asset("ANIM", "anim/meat_rack2.zip"),
	Asset("ANIM", "anim/meat_rack_food.zip"),
}

local prefabs =
{
	-- everything it can "produce" and might need symbol swaps from
	"smallmeat",
	"smallmeat_dried",
	"monstermeat",
	"monstermeat_dried",
	"meat",
	"meat_dried",
	"drumstick", -- uses smallmeat_dried
	"batwing", --uses smallmeat_dried
	"fish", -- uses smallmeat_dried
	"froglegs", -- uses smallmeat_dried
	"eel",
	"collapse_small",
	"seaweed_dried", 
	"seaweed", 
	"jellyfish", 
	"jellyjerky", 
	"fish_med", 
	"swordfish", 
	"fish_raw",
	"venus_stalk",
	"walkingstick",
}

local function OnHit(inst, worker)
	if not inst:HasTag("burnt") then
		if inst.components.container then
			inst.components.container:Close()
		end
		if inst:HasTag("abandoned") then
			inst.AnimState:PlayAnimation("broken_hit")
			inst.AnimState:PushAnimation("broken", false)
		else
			inst.AnimState:PlayAnimation("hit")
			inst.AnimState:PushAnimation("idle")
		end
	end
end

local function OnHammered(inst, worker)
	if inst.components.burnable and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	if inst.components.container then
		inst.components.container:DropEverything()
	end
	inst.components.lootdropper:DropLoot()

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")

	inst:Remove()
end

local function OnBuilt(inst)
	if not inst:HasTag("abandoned") then
		inst.AnimState:PlayAnimation("place")
		inst.AnimState:PushAnimation("idle")
		inst.SoundEmitter:PlaySound("extrabuilds/meatrack/meat_rack_craft")
	end
end

local function DoBounce(inst, slot, slotstr)
	local numslots = inst.components.container:GetNumSlots()
	if numslots > 3 then
		inst.AnimState:PlayAnimation("bounce")
		if inst._lastbounceslot ~= slotstr then
			inst.AnimState:Show("small_bounce_"..inst._lastbounceslot)
			inst.AnimState:Hide("big_bounce_"..inst._lastbounceslot)
			inst.AnimState:Show("big_bounce_"..slotstr)
			inst.AnimState:Hide("small_bounce_"..slotstr)
			inst._lastbounceslot = slotstr
		end
	else
		inst.AnimState:PlayAnimation("bounce"..slotstr)
	end
	inst.AnimState:PushAnimation("idle")
	inst.SoundEmitter:PlaySound("extrabuilds/meatrack/meat_rack_use")
end

local function HideRackItem(inst, slot, name)
	local slotstr = tostring(slot)

	inst.AnimState:OverrideSymbol("swap_rope"..slotstr, inst.build, "swap_rope_empty")

	inst.AnimState:ClearOverrideSymbol("swap_dried"..slotstr)

	if not (inst:IsAsleep() or inst:HasTag("burnt") or POPULATING) then
		DoBounce(inst, slot, slotstr)
	end
end

local function ShowRackItem(inst, slot, name, build)
	local slotstr = tostring(slot)

	inst.AnimState:OverrideSymbol("swap_rope"..slotstr, inst.build, "swap_rope")

	inst.AnimState:OverrideSymbol("swap_dried"..slotstr, build, name)

	if not (inst:IsAsleep() or inst:HasTag("burnt") or POPULATING) then
		DoBounce(inst, slot, slotstr)
	end
end

local function OnSave(inst, data)
	if inst:HasTag("burnt") or (inst.components.burnable and inst.components.burnable:IsBurning()) then
		data.burnt = true
	end
end

local function OnLoad(inst, data)--, ents)
	if data then
		if data.burnt then
			inst.components.burnable.onburnt(inst)
		elseif data.dryer then
			--loading old version meatrack data
			if data.dryer.ingredient then
				local item = SpawnPrefab(data.dryer.ingredient)
				if item then
					if data.dryer.ingredientperish and data.dryer.ingredientperish > 0 and item.components.perishable then
						item.components.perishable:SetPercent(math.min(1, data.dryer.ingredientperish))
					end
					item.dryingrack_drytime = data.dryer.remainingtime
					inst.components.container:GiveItem(item, 2)
				end
			elseif data.dryer.product then
				local item = SpawnPrefab(data.dryer.product)
				if item then
					if data.dryer.ingredientperish and data.dryer.ingredientperish > 0 and item.components.perishable then
						item.components.perishable:SetPercent(math.min(1, data.dryer.ingredientperish))
					end
					inst.components.container:GiveItem(item, 2)
					if data.dryer.dried_buildfile then
						inst.components.dryingrack:ApplyDryingInfoSnapshot({ [item] = data.dryer.dried_buildfile })
					end
				end
			end
		end
	end
end

local function GetStatus(inst)--, viewer)
	if inst:HasTag("burnt") then
		return "BURNT"
	end

	local container = inst.components.dryingrack and inst.components.dryingrack:GetContainer()

	--priority
	--6: done meat
	--5: done not meat
	--3: drying meat
	--2: drying not meat
	--1: rot
	--0: nothing
	local prioritystatus = 0
	for k, v in pairs(container.slots) do
		local foodtype = v.components.edible and v.components.edible.foodtype
		local ismeat = foodtype == "MEAT"
		if v.components.dryable then
			prioritystatus = math.max(prioritystatus, ismeat and 3 or 2)
		elseif ismeat then
			prioritystatus = 6
			break
		else
			local isrot = foodtype == nil
			prioritystatus = math.max(prioritystatus, isrot and 1 or 5)
		end
	end

	if prioritystatus == 0 then
		return
	elseif prioritystatus == 6 then
		return "DONE"
	elseif prioritystatus == 5 then
		return "DONE_NOTMEAT"
	end

	local hasrain = GetSeasonManager():IsRaining()
	if prioritystatus == 3 then
		return hasrain and "DRYINGINRAIN" or "DRYING"
	elseif prioritystatus == 2 then
		return hasrain and "DRYINGINRAIN_NOTMEAT" or "DRYING_NOTMEAT"
	elseif prioritystatus == 1 then
		return "DONE_NOTMEAT"
	end
end

local function onburnt(inst)
    inst:AddTag("burnt")
    inst.components.burnable.canlight = false
    if inst.AnimState then
        inst.AnimState:PlayAnimation("burnt", true)
    end
    inst:PushEvent("burntup")
    if inst.SoundEmitter then
        inst.SoundEmitter:KillSound("idlesound")
        inst.SoundEmitter:KillSound("sound")
        inst.SoundEmitter:KillSound("loop")
        inst.SoundEmitter:KillSound("snd")
    end
    if inst.MiniMapEntity then
        inst.MiniMapEntity:SetEnabled(false)
    end
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
    end
	if inst.components.dryingrack then
        inst.components.dryingrack:OnBurnt()
        inst:RemoveComponent("dryingrack")
    end
    if inst.components.container then
        inst.components.container:DropEverything()
        inst.components.container:Close()
        inst:RemoveComponent("container")
    end
    if inst.components.dryer then
        inst.components.dryer:StopDrying("fire")
        inst:RemoveComponent("dryer")
    end
    if inst.Light then
        inst.Light:Enable(false)
    end
    if inst.components.burnable then
        inst:RemoveComponent("burnable")
    end
    if inst.components.floodable then 
        inst:RemoveComponent("floodable")
    end
    inst:RemoveTag("dragonflybait_lowprio")
    inst:RemoveTag("dragonflybait_medprio")
    inst:RemoveTag("dragonflybait_highprio")
end

local function itemtestfn(container, item, slot)
	local hasdryable = item.components.dryable and item.components.dryable:GetProduct() and item.components.dryable:GetDryingTime()
	local dryingrack_ok = item:GetTimeAlive() == 0 or --items perishing replaced by spoiled_food/fish
		(item.dryingrack_lastinfo and --failing to move items; return to slot
		item.dryingrack_lastinfo.container == container and
		item.dryingrack_lastinfo.slot == slot)
	return hasdryable or dryingrack_ok
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddSoundEmitter()

	inst.MiniMapEntity:SetIcon("meatrack2_map.tex")

	local build = "meat_rack2"

	inst.AnimState:SetBank("meat_rack_multi")
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:Hide("mouseover")

	for i = 1, 3 do
		inst.AnimState:OverrideSymbol("swap_rope"..tostring(i), build, "swap_rope_empty")
	end

	inst.build = build

	inst.AnimState:SetTime(math.random()*inst.AnimState:GetCurrentAnimationLength())

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("container")
	inst.components.container:SetNumSlots(3)
	inst.components.container.widgetslotpos = {}
	for x = 0, 2 do
		table.insert(inst.components.container.widgetslotpos, Vector3(75 * x - 75 * 2 + 75, 0, 0))
	end
	inst.components.container.widgetanimbank = "ui_meatrack_multi_3x1"
	inst.components.container.widgetanimbuild = "ui_meatrack_multi_3x1"
	inst.components.container.widgetpos = Vector3(0, 200, 0)
	inst.components.container.side_align_tip = 160
	inst.components.container.acceptsstacks = false

	inst.components.container.itemtestfn = itemtestfn

	inst:AddComponent("dryingrack") --must add after container is added
	inst.components.dryingrack:EnableDrying()
	inst.components.dryingrack:SetShowItemFn(ShowRackItem)
	inst.components.dryingrack:SetHideItemFn(HideRackItem)

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

	U.MakeMediumBurnableDLC(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
	MakeSmallPropagator(inst)

	MakeSnowCovered(inst)

	inst:ListenForEvent("onbuilt", OnBuilt)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("meatrack2", fn, assets, prefabs),
	U.MakePlacerDLC("meatrack2_placer", "meat_rack_multi", "meat_rack2", "placer",
	nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, function(inst) inst.AnimState:Hide("mouseover") end)
