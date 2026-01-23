local marblebean_assets =
{
    Asset("ANIM", "anim/marblebean.zip"),
}

local marblebean_prefabs =
{
    "marbleshrub_short",
}

local function growtree(inst)
    local grow_prefab = type(inst.growprefab) == "table" and GetRandomItem(inst.growprefab) or inst.growprefab
    local tree = SpawnPrefab(grow_prefab)
    if tree then
        tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
        tree:growfromseed()
        inst:Remove()
    end
end

local function stopgrowing(inst)
    inst.components.timer:StopTimer("grow")
end

local function startgrowing(inst)
    if not inst.components.timer:TimerExists("grow") then
        local basetime = inst.growtimes and inst.growtimes.base or TUNING.PINECONE_GROWTIME.base
        local randomtime = inst.growtimes and inst.growtimes.random or TUNING.PINECONE_GROWTIME.random
        local growtime = GetRandomWithVariance(basetime, randomtime)
        inst.components.timer:StartTimer("grow", growtime)
    end
end

local function ontimerdone(inst, data)
    if data.name == "grow" then
        growtree(inst)
    end
end

local function digup(inst, digger)
    inst.components.lootdropper:DropLoot()
    inst:Remove()
end

local function sapling_fn(build, anim, growprefab, tag, fireproof, overrideloot, grow_times)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        if not fireproof then
            inst:AddTag("plant")
        end

        inst:AddTag(tag)

        inst.growprefab = growprefab
        inst.growtimes = grow_times
        inst.StartGrowing = startgrowing

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", ontimerdone)
        startgrowing(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(overrideloot or {"twigs"})

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnFinishCallback(digup)
        inst.components.workable:SetWorkLeft(1)

        if not fireproof then
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            inst:ListenForEvent("onignite", stopgrowing)
            inst:ListenForEvent("onextinguish", startgrowing)
            MakeSmallPropagator(inst)
        end

        return inst
    end
    return fn
end

return Prefab("marblebean_sapling",
    sapling_fn("marblebean", "idle_planted", "marbleshrub_short", "marbleshrub", true, {"marblebean"}),
    marblebean_assets, marblebean_prefabs)