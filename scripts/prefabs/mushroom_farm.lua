require "prefabutil"
local U = require("extrabuilds_utils")

local assets =
{
    Asset("ANIM", "anim/mushroom_farm.zip"),
    Asset("ANIM", "anim/mushroom_farm_red_build.zip"),
    Asset("ANIM", "anim/mushroom_farm_green_build.zip"),
    Asset("ANIM", "anim/mushroom_farm_blue_build.zip"),
}

local prefabs =
{
    "red_cap",
    "green_cap",
    "blue_cap",
    "collapse_small",
}

local levels =
{
    { amount=4, grow="mushroom_3", idle="mushroom_3_idle", hit="hit_mushroom_3" },
    { amount=2, grow="mushroom_2", idle="mushroom_2_idle", hit="hit_mushroom_2" },
    { amount=1, grow="mushroom_1", idle="mushroom_1_idle", hit="hit_mushroom_1" },
    { amount=0, idle="idle", hit="hit_idle" },
}

local FULLY_REPAIRED_WORKLEFT = 3

local function IsSnowCovered()
    return GetSeasonManager() and GetSeasonManager().ground_snow_level > SNOW_THRESH
end

local function DoMushroomOverrideSymbol(inst, product)
    inst.AnimState:OverrideSymbol("swap_mushroom", "mushroom_farm_"..(string.split(product, "_")[1]).."_build", "swap_mushroom")
end

local function StartGrowing(inst, giver, product)
    if inst.components.harvestable ~= nil then
        local max_produce = levels[1].amount
        local productname = product.prefab

        local grow_time = TUNING.MUSHROOMFARM_FULL_GROW_TIME

        DoMushroomOverrideSymbol(inst, productname)

        inst.components.harvestable:SetProduct(productname, max_produce)
        inst.components.harvestable:SetGrowTime(grow_time / max_produce)
        inst.components.harvestable:Grow()
    end
end

local function setlevel(inst, level, dotransition)
    if not inst:HasTag("burnt") then
        if inst.anims == nil then
            inst.anims = {}
        end
        if inst.anims.idle == level.idle then
            dotransition = false
        end

        inst.anims.idle = level.idle
        inst.anims.hit = level.hit

        if inst.remainingharvests == 0 then
            inst.anims.idle = "expired"
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
            inst.components.workable:SetWorkLeft(1)
        elseif IsSnowCovered() then
            inst.components.trader:Disable()
        elseif inst.components.harvestable:CanBeHarvested() then
            inst.components.trader:Disable()
        else
            inst.components.trader:Enable()
            inst.components.harvestable:SetGrowTime(nil)
        end

        if dotransition then
            inst.AnimState:PlayAnimation(level.grow)
            inst.AnimState:PushAnimation(inst.anims.idle, false)
            inst.SoundEmitter:PlaySound("extrabuilds/mushroomfarm/grow")
        else
            inst.AnimState:PlayAnimation(inst.anims.idle)
        end

    end
end

local function updatelevel(inst, dotransition)
    if not inst:HasTag("burnt") then
        if IsSnowCovered() then
            if inst.components.harvestable:CanBeHarvested() then
                for i= 1,inst.components.harvestable.produce do
                    inst.components.lootdropper:SpawnLootPrefab("spoiled_food")
                end

                inst.components.harvestable.produce = 0
                inst.components.harvestable:StopGrowing()
                inst.remainingharvests = inst.remainingharvests and inst.remainingharvests - 1
            end
        end

        for k, v in pairs(levels) do
            if inst.components.harvestable.produce >= v.amount then
                setlevel(inst, v, dotransition)
                break
            end
        end
    end
    -- Delete loot table if produce==0 (basically if burnt or snowed or harvested)
    if inst:HasTag("burnt") or IsSnowCovered() or inst.components.harvestable and inst.components.harvestable.produce == 0 then
        inst.components.lootdropper:SetLoot({})
    end
end

local function OnSnowCoverChange(inst)
    updatelevel(inst)
end

local function onharvest(inst, picker)
    if not inst:HasTag("burnt") then
        inst.remainingharvests = inst.remainingharvests and inst.remainingharvests - 1
        updatelevel(inst)
    end
end

local function lootsetfn(inst)
    local lootdropper = inst.components.lootdropper

    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or (not inst.components.harvestable:CanBeHarvested()) then
        return
    end

    local loot = {}
    for i= 1,inst.components.harvestable.produce do
        table.insert(loot, inst.components.harvestable.product)
    end
    lootdropper:SetLoot(loot)
end

local function ongrow(inst, produce)
    updatelevel(inst, true)
    lootsetfn(inst)
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation(inst.anims.hit)
        inst.AnimState:PushAnimation(inst.anims.idle, false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("extrabuilds/mushroomfarm/craft")
end

local function getstatus(inst)
    if inst.components.harvestable == nil then
        return nil
    end

    return inst.remainingharvests == 0 and "ROTTEN"
			or IsSnowCovered() and "SNOWCOVERED"
            or inst.components.harvestable.produce == levels[1].amount and "LOTS"
            or inst.components.harvestable:CanBeHarvested() and "SOME"
            or "EMPTY"
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
    if inst.components.harvestable then
        inst.components.harvestable:StopGrowing()
        inst:RemoveComponent("harvestable")
    end
    if inst.components.trader then
        inst:RemoveComponent("trader")
    end
    if inst.Light then
        inst.Light:Enable(false)
    end
    if inst.components.burnable then
        inst:RemoveComponent("burnable")
    end
    inst:RemoveTag("dragonflybait_lowprio")
    inst:RemoveTag("dragonflybait_medprio")
    inst:RemoveTag("dragonflybait_highprio")
end

local function onignite(inst)
    DefaultBurnFn(inst)
    if inst.components.harvestable ~= nil then
        if inst.components.harvestable:CanBeHarvested() then
            for i= 1,inst.components.harvestable.produce do
                inst.components.lootdropper:SpawnLootPrefab("ash")
            end
        end

        inst.components.harvestable.produce = 0
        inst.components.harvestable:StopGrowing()
        updatelevel(inst)
    end

    if inst.components.trader ~= nil then
        inst.components.trader:Disable()
    end
end

local function onextinguish(inst)
    DefaultExtinguishFn(inst)
    updatelevel(inst)
end

local function accepttest(inst, item, giver)
    if item == nil then
        return false
    elseif inst.remainingharvests == 0 then
        if item.prefab == "livinglog" then -- only livinglog for now because that is the recipe
            return true
        end
        return false --, "MUSHROOMFARM_NEEDSLOG"
    elseif not item:HasTag("mushroom") then
        return false --, "MUSHROOMFARM_NEEDSSHROOM"
    else
        return true
    end
end

local function refusereason(inst, item, giver)
    return inst.remainingharvests == 0 and "MUSHROOMFARM_NEEDSLOG"
        or item and not item:HasTag("mushroom") and "MUSHROOMFARM_NEEDSSHROOM"
        or nil
end

local function onacceptitem(inst, giver, item)
    if inst.remainingharvests == 0 then
        inst.remainingharvests = TUNING.MUSHROOMFARM_MAX_HARVESTS
        inst.components.workable:SetWorkLeft(FULLY_REPAIRED_WORKLEFT)
        updatelevel(inst)
    else
        StartGrowing(inst, giver, item)
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    elseif inst.components.harvestable ~= nil then
        data.growtime = inst.components.harvestable.growtime
        data.product = inst.components.harvestable.product
        data.maxproduce = inst.components.harvestable.maxproduce
        data.remainingharvests = inst.remainingharvests
    end
end


local function onload(inst, data)
    if data ~= nil then
        if data.burnt then
            inst.components.burnable.onburnt(inst)
        else
            inst.components.harvestable.growtime = data.growtime
            inst.components.harvestable.product = data.product
            inst.components.harvestable.maxproduce = data.maxproduce

            if data.remainingharvests ~= nil then
                inst.remainingharvests = data.remainingharvests
            else
                inst.remainingharvests = 0
            end
            if inst.components.harvestable.product ~= nil then
                DoMushroomOverrideSymbol(inst, inst.components.harvestable.product)
            end

            updatelevel(inst)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("mushroom_farm_map.tex")

    inst.AnimState:SetBank("mushroom_farm")
    inst.AnimState:SetBuild("mushroom_farm")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("playerowned")
    inst:AddTag("mushroom_farm")

    --trader, alltrader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")
    inst:AddTag("alltrader")

    ---------------------
    inst:AddComponent("harvestable")
    inst.components.harvestable:SetOnGrowFn(ongrow)
    inst.components.harvestable:SetOnHarvestFn(onharvest)
    -------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(accepttest)
    inst.components.trader:SetRefuseReason(refusereason)
    inst.components.trader.onaccept = onacceptitem
    inst.components.trader.acceptnontradable = true

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("lootdropper")
    lootsetfn(inst)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(FULLY_REPAIRED_WORKLEFT)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSnowCovered(inst)
    inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("snowcoverchange", function() OnSnowCoverChange(inst) end, GetWorld())

    U.MakeMediumBurnableDLC(inst)
    MakeLargePropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    inst.remainingharvests = TUNING.MUSHROOMFARM_MAX_HARVESTS

    inst.OnSave = onsave
    inst.OnLoad = onload

    updatelevel(inst)

    return inst
end

return Prefab("mushroom_farm", fn, assets, prefabs),
    MakePlacer("mushroom_farm_placer", "mushroom_farm", "mushroom_farm", "idle")
