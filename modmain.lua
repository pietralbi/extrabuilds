-- UTILS
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH
local RECIPE_GAME_TYPE = GLOBAL.RECIPE_GAME_TYPE
local AllRecipes = GLOBAL.GetAllRecipes()
local enabledROG = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local enabledSHIP = GLOBAL.rawget(GLOBAL, "CAPY_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)
local enabledPORK = GLOBAL.rawget(GLOBAL, "PORKLAND_DLC") and GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC)
local enabledAnyDLC = enabledROG or enabledSHIP or enabledPORK
local vanilla = not enabledAnyDLC

local seg_time = 30
local total_day_time = seg_time*16
local day_segs = 10
local dusk_segs = 4
local night_segs = 2
local day_time = seg_time * day_segs
local dusk_time = seg_time * dusk_segs
local night_time = seg_time * night_segs

local DEBUG = false

local function dprint(...)
    if DEBUG then
        print(...)
    end
end

local function MakeRecipe(name, ingredients, tab, level, game_type, placer, min_spacing, nounlock, numtogive, aquatic, distance, decor, flipable, image, wallitem, alt_ingredients)
    if enabledPORK then
        return Recipe(name, ingredients, tab, level, game_type, placer, min_spacing, nounlock, numtogive, aquatic, distance, decor, flipable, image, wallitem, alt_ingredients)
    elseif enabledSHIP then
        return Recipe(name, ingredients, tab, level, game_type, placer, min_spacing, nounlock, numtogive, aquatic, distance)
    else
        return Recipe(name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive)
    end
end

Assets = {
    Asset("SOUND", "sound/extrabuilds.fsb"),
	Asset("SOUNDPACKAGE", "sound/extrabuilds.fev"),
}

PrefabFiles = {}

-- HOLLOW STUMP
if GetModConfigData("hollow_stump") and enabledAnyDLC then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/catcoonden.xml"))
    GLOBAL.table.insert(PrefabFiles, "catcoondenplacer")

    STRINGS.RECIPE_DESC.CATCOONDEN = "Catcoon's sweet home."

    local ingredients = {
        Ingredient("twigs", GetModConfigData("twigs")),
        Ingredient("log",   GetModConfigData("log")),
        Ingredient("coontail", GetModConfigData("coontail")),
    }

    local catcoonden = MakeRecipe("catcoonden", ingredients, RECIPETABS.TOWN, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.ROG, "catcoonden_placer")
    catcoonden.atlas = "images/inventoryimages/catcoonden.xml"

    local rabbithouse = GLOBAL.GetRecipe("rabbithouse")
    if rabbithouse ~= nil then
        catcoonden.sortkey = rabbithouse.sortkey + 0.1
    end
end

-- HOLLOW STUMP INFINITE LIVES
if GetModConfigData("infinite_lives") then
    local function InfiniteLives(inst)
        inst.components.childspawner.onchildkilledfn = function(inst, child)
            inst.lives_left = inst.lives_left -- do not decrement 
            if inst.lives_left <= 0 then
                inst.components.childspawner:StopRegen()
                inst.components.childspawner:StopSpawning()
                inst:RemoveComponent("childspawner")
            end
        end
    end
    AddPrefabPostInit("catcoonden", InfiniteLives)
end

-- HOLLOW STUMP MINIMAP ICON
if GetModConfigData("change_minimap_icon") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/catcoonden_map.xml"))

    AddMinimapAtlas("minimap/catcoonden_map.xml")

    local function ChangeMiniMapIcon(inst)
        inst.MiniMapEntity:SetIcon("catcoonden_map.tex")
    end
    AddPrefabPostInit("catcoonden", ChangeMiniMapIcon)
end

-- MERMHOUSE, MERM'S HUT, FISHERMERM HOUSE
if GetModConfigData("mermhouse") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/mermhouse.xml"))
    GLOBAL.table.insert(PrefabFiles, "mermhouseplacer")

    -- To avoid crash due to NAMES.MERMHOUSE being a table
    local function ResolveNameTable(v)
        if type(v) ~= "table" then
            return v
        end
        local name = ((vanilla or enabledROG) and v.BASE)
                or ((enabledSHIP or enabledPORK) and v.SW)
        return name or "ERROR"
    end

    -- Patch 1: PlayerController:GetHoverTextOverride (avoid concatenating a table)
    AddComponentPostInit("playercontroller", function(self)
        local _GetHoverTextOverride = self.GetHoverTextOverride
        function self:GetHoverTextOverride()
            if self.placer_recipe then
                local key = string.upper(self.placer_recipe.name)
                local v = STRINGS.NAMES[key]
                if type(v) == "table" then
                    v = ResolveNameTable(v)
                end
                return STRINGS.UI.HUD.BUILD .. " " .. (v or STRINGS.UI.HUD.HERE)
            end
        end
    end)

    -- Patch 2: Text:SetString (avoid passing a table into the engine TextWidget)
    AddClassPostConstruct("widgets/text", function(self)
        local _SetString = self.SetString

        function self:SetString(str)
            if type(str) == "table" then
                str = ResolveNameTable(str)
            end
            return _SetString(self, str)
        end
    end)

    STRINGS.RECIPE_DESC.MERMHOUSE = "A soggy shack for merms."

    local ingredients_base = {
        Ingredient("boards", GetModConfigData("boards")),
        Ingredient("rocks",   GetModConfigData("rocks")),
        Ingredient("fish", GetModConfigData("fish")),
    }

    local mermhouse_base = MakeRecipe("mermhouse", ingredients_base, RECIPETABS.TOWN, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.VANILLA, "mermhouse_placer")
    mermhouse_base.atlas = "images/inventoryimages/mermhouse.xml"
    local pighouse = GLOBAL.GetRecipe("pighouse")
    if pighouse ~= nil then
        mermhouse_base.sortkey = pighouse.sortkey + 0.1
    end

    if enabledSHIP or enabledPORK then
        GLOBAL.table.insert(PrefabFiles, "mermhutplacer")

        local ingredients_sw = {
            Ingredient("boards", GetModConfigData("boards")),
            Ingredient("rocks",   GetModConfigData("rocks")),
            Ingredient("tropical_fish", GetModConfigData("fish")),
        }

        local mermhouse_sw = MakeRecipe("mermhouse", ingredients_sw, RECIPETABS.TOWN, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.SHIPWRECKED, "mermhut_placer")
        mermhouse_sw.atlas = "images/inventoryimages/mermhouse.xml"
        local pighouse = GLOBAL.GetRecipe("pighouse")
        if pighouse ~= nil then
            mermhouse_sw.sortkey = pighouse.sortkey + 0.1
        end
    end
end

if GetModConfigData("mermhouse_fisher") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/mermhouse_fisher.xml"))
    GLOBAL.table.insert(PrefabFiles, "mermfisherplacer")

    if enabledSHIP or enabledPORK then

        STRINGS.RECIPE_DESC.MERMHOUSE_FISHER = "A fishy house for fishing merms."

        local ingredients = {
            Ingredient("boards", GetModConfigData("boards_fisher")),
            Ingredient("rocks",   GetModConfigData("rocks_fisher")),
            Ingredient("seaweed", GetModConfigData("seaweed_fisher")),
        }

        local fishermermhouse = MakeRecipe("mermhouse_fisher", ingredients, RECIPETABS.TOWN, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.SHIPWRECKED, "mermfisher_placer")
        fishermermhouse.atlas = "images/inventoryimages/mermhouse_fisher.xml"
        local pighouse = GLOBAL.GetRecipe("pighouse")
        if pighouse ~= nil then
            fishermermhouse.sortkey = pighouse.sortkey + 0.2
        end
    end
end

if GetModConfigData("change_minimap_icon_fisher") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/mermhouse_fisher_map.xml"))

    AddMinimapAtlas("minimap/mermhouse_fisher_map.xml")

    local function ChangeMiniMapIcon(inst)
        inst.MiniMapEntity:SetIcon("mermhouse_fisher_map.tex")
    end
    AddPrefabPostInit("mermhouse_fisher", ChangeMiniMapIcon)
end

-- MARBLE BEAN AND SHRUB
if GetModConfigData("marble_tree") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/marblebean.xml"))
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/marbleshrub1.xml"))
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/marbleshrub2.xml"))
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/marbleshrub3.xml"))
    GLOBAL.table.insert(PrefabFiles, "marblebean")
    GLOBAL.table.insert(PrefabFiles, "marblebean_sapling")
    GLOBAL.table.insert(PrefabFiles, "marbleshrub")

    RegisterInventoryItemAtlas("images/inventoryimages/marblebean.xml", "marblebean.tex")

    local marblebean = MakeRecipe("marblebean", {Ingredient("marble",1)}, RECIPETABS.REFINE, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.VANILLA)
	marblebean.atlas = "images/inventoryimages/marblebean.xml"
    local cutstone = GLOBAL.GetRecipe("cutstone")
    if cutstone ~= nil then
        marblebean.sortkey = cutstone.sortkey + 0.2
    end

    AddMinimapAtlas("minimap/marbleshrub1.xml")
    AddMinimapAtlas("minimap/marbleshrub2.xml")
    AddMinimapAtlas("minimap/marbleshrub3.xml")

    TUNING.MARBLESHRUB_MINE_SMALL = 6  -- why are you even mining at this stage?
    TUNING.MARBLESHRUB_MINE_NORMAL = 8 -- same as MARBLETREE_MINE
    TUNING.MARBLESHRUB_MINE_TALL = 10  -- same as MARBLEPILLAR_MINE

    TUNING.MARBLESHRUB_LOOPING = GetModConfigData("marble_tree_loop")

    TUNING.MARBLESHRUB_GROW_TIME =
        {
            {base=9.0*day_time, random=1.0*day_time}, --short
            {base=9.0*day_time, random=1.0*day_time}, --normal
            {base=9.0*day_time, random=1.0*day_time}, --tall
        }

    modimport("scripts/strings/marbleshrub_strings.lua")
end

-- MUSHROOM PLANTER
if GetModConfigData("mushroom_farm") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/mushroom_farm.xml"))
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/mushroom_farm_map.xml"))
    GLOBAL.table.insert(PrefabFiles, "mushroom_farm")

    local mushroom_farm = MakeRecipe("mushroom_farm", {Ingredient("spoiled_food", 8),Ingredient("poop", 5),Ingredient("livinglog", 2)}, RECIPETABS.FARM, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.VANILLA, "mushroom_farm_placer", 2)
	mushroom_farm.atlas = "images/inventoryimages/mushroom_farm.xml"
    local beebox = GLOBAL.GetRecipe("beebox")
    if beebox ~= nil then
        mushroom_farm.sortkey = beebox.sortkey + 0.2
    end

    AddMinimapAtlas("minimap/mushroom_farm_map.xml")

    TUNING.MUSHROOMFARM_MAX_HARVESTS = GetModConfigData("mushroomfarm_maxharvest")
    TUNING.MUSHROOMFARM_FULL_GROW_TIME = total_day_time * 3.75

    AddComponentPostInit("trader", function(self)
        function self:SetRefuseReason(fn)
            self.refusereasonfn = fn
        end

        function self:GetRefuseReason(item, giver)
            if self.refusereasonfn then
                return self.refusereasonfn(self.inst, item, giver)
            end
        end
    end)

    local _GIVE_fn = GLOBAL.ACTIONS.GIVE.fn
    GLOBAL.ACTIONS.GIVE.fn = function(act)
        if act.target.components.trader and act.target.components.trader.refusereasonfn and
        (act.invobject.components.tradable or act.target.components.trader.acceptnontradable) then
            local can_accept = act.target.components.trader:CanAccept(act.invobject)
            if can_accept then
                act.target.components.trader:AcceptGift(act.doer, act.invobject)
                return true
            else
                local reason = act.target.components.trader:GetRefuseReason(act.invobject, act.doer)
                if reason then
                    return false, reason
                else
                    return true
                end
            end
        end
        return _GIVE_fn(act)
    end

    local function AddMushroomTag(inst)
            inst:AddTag("mushroom")
    end
    AddPrefabPostInit("red_cap", AddMushroomTag)
    AddPrefabPostInit("green_cap", AddMushroomTag)
    AddPrefabPostInit("blue_cap", AddMushroomTag)

    modimport("scripts/strings/mushroom_farm_strings.lua")
end

-- DRYING RACK
if GetModConfigData("meatrack") then
    GLOBAL.table.insert(Assets, Asset("ATLAS", "images/inventoryimages/meatrack2.xml"))
    GLOBAL.table.insert(Assets, Asset("ATLAS", "minimap/meatrack2_map.xml"))
    GLOBAL.table.insert(PrefabFiles, "meatrack2")

    local meatrack2 = MakeRecipe("meatrack2", {Ingredient("twigs", 3),Ingredient("charcoal", 2), Ingredient("rope", 3)}, RECIPETABS.FARM, TECH.SCIENCE_ONE, RECIPE_GAME_TYPE.COMMON, "meatrack_placer")
	meatrack2.atlas = "images/inventoryimages/meatrack2.xml"
    local meatrack = GLOBAL.GetRecipe("meatrack")
    if meatrack ~= nil then
        meatrack2.sortkey = meatrack.sortkey + 0.2
        meatrack.tab = "null"
    end

    AddMinimapAtlas("minimap/meatrack2_map.xml")

    -- Replace Container:RemoveItemBySlot
    AddComponentPostInit("container", function(inst)
        function inst:RemoveItemBySlot(slot)
            if slot and self.slots[slot] then
                local item = self.slots[slot]
                if item then
                    self.slots[slot] = nil
                    if item.components.inventoryitem then
                        item.components.inventoryitem:OnRemoved()
                    end
                    
                    self.inst:PushEvent("itemlose", {slot = slot, prev_item = item})
                end
                item.prevcontainer = self
                item.prevslot = slot
                return item        
            end
        end
    end)

    modimport("scripts/strings/meatrack2_strings.lua")

    for k, v in pairs(STRINGS.CHARACTERS) do
        v.DESCRIBE.MEATRACK2 = v.DESCRIBE.MEATRACK
    end
    STRINGS.NAMES.MEATRACK2 = STRINGS.NAMES.MEATRACK
    STRINGS.RECIPE_DESC.MEATRACK2 = STRINGS.RECIPE_DESC.MEATRACK
end