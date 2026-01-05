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

local DEBUG = true

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
    Asset("ATLAS", "images/inventoryimages/catcoonden.xml"),
    Asset("ATLAS", "images/inventoryimages/mermhouse.xml"),
    Asset("ATLAS", "minimap/catcoonden_map.xml"),
    Asset("ATLAS", "minimap/mermhouse_fisher.xml")
}

PrefabFiles = {
    "catcoondenplacer",
    "mermhouseplacer",
    "mermhutplacer"
}

-- Hollow Stump
if GetModConfigData("hollow_stump") and enabledAnyDLC then

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

if GetModConfigData("change_minimap_icon") then
    AddMinimapAtlas("minimap/catcoonden_map.xml")

    local function ChangeMiniMapIcon(inst)
        inst.MiniMapEntity:SetIcon("catcoonden_map.tex")
    end
    AddPrefabPostInit("catcoonden", ChangeMiniMapIcon)
end

if GetModConfigData("mermhouse") then
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