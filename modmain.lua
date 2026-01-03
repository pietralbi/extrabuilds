local GLOBAL = GLOBAL
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local hasROG = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.REIGN_OF_GIANTS)
local hasSHIP = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.CAPY_DLC)
local hasPORK = GLOBAL.TheSim:IsDLCInstalled(GLOBAL.PORKLAND_DLC)
local vanilla = not (hasROG or hasSHIP or hasPORK)
local hasAnyDLC = hasROG or hasSHIP or hasPORK

-- Recipe DLC wrapper
do
    local _Recipe = GLOBAL.Recipe
    local RECIPE_GAME_TYPE = GLOBAL.RECIPE_GAME_TYPE

    local function NormalizeGameType(flag)
        -- Vanilla/RoG don't have game types; caller flag is ignored there anyway.
        if not RECIPE_GAME_TYPE then
            return nil
        end

        if flag == nil then
            return RECIPE_GAME_TYPE.COMMON
        end

        -- Allow passing a list of game types (SW/HAM support table)
        if type(flag) == "table" then
            return flag
        end

        -- Allow passing RECIPE_GAME_TYPE.* directly
        if flag == RECIPE_GAME_TYPE.COMMON
        or flag == RECIPE_GAME_TYPE.ROG
        or flag == RECIPE_GAME_TYPE.SHIPWRECKED
        or flag == RECIPE_GAME_TYPE.PORKLAND then
            return flag
        end

        -- Allow passing DLC constants
        if flag == GLOBAL.REIGN_OF_GIANTS then
            return RECIPE_GAME_TYPE.ROG
        elseif flag == GLOBAL.CAPY_DLC then
            return RECIPE_GAME_TYPE.SHIPWRECKED
        elseif flag == GLOBAL.PORKLAND_DLC then
            return RECIPE_GAME_TYPE.PORKLAND
        end

        -- Allow passing strings
        if type(flag) == "string" then
            local f = string.upper(flag)
            if f == "COMMON" then return RECIPE_GAME_TYPE.COMMON end
            if f == "ROG" or f == "REIGN_OF_GIANTS" then return RECIPE_GAME_TYPE.ROG end
            if f == "SW" or f == "SHIPWRECKED" then return RECIPE_GAME_TYPE.SHIPWRECKED end
            if f == "HAM" or f == "HAMLET" or f == "PORK" or f == "PORKLAND" then return RECIPE_GAME_TYPE.PORKLAND end
        end

        return RECIPE_GAME_TYPE.COMMON
    end

    -- New call:
    --   Recipe(dlc_flag, name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive, [opts or positional extras])
    --
    -- Legacy call (still supported):
    --   Recipe(name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive, [positional extras])
    GLOBAL.Recipe = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, ...)
        local dlc_flag, name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive
        local extra1, extra2, extra3, extra4, extra5, extra6, extra7

        -- Legacy signature detection: Recipe(name:string, ingredients:table, ...)
        if type(a1) == "string" and type(a2) == "table" then
            dlc_flag    = nil
            name        = a1
            ingredients = a2
            tab         = a3
            level       = a4
            placer      = a5
            min_spacing = a6
            nounlock    = a7
            numtogive   = a8
            extra1, extra2, extra3, extra4, extra5, extra6, extra7 = a9, ...
        else
            dlc_flag    = a1
            name        = a2
            ingredients = a3
            tab         = a4
            level       = a5
            placer      = a6
            min_spacing = a7
            nounlock    = a8
            numtogive   = a9
            extra1, extra2, extra3, extra4, extra5, extra6, extra7 = ...
        end

        -- Extra args:
        -- SW positional: aquatic, distance
        -- HAM positional: aquatic, distance, decor, flipable, image, wallitem, alt_ingredients
        --
        -- Also supports passing a single opts-table right after numtogive:
        --   { aquatic=..., distance=..., decor=..., flipable=..., image=..., wallitem=..., alt_ingredients=... }
        local aquatic, distance, decor, flipable, image, wallitem, alt_ingredients =
            extra1, extra2, extra3, extra4, extra5, extra6, extra7

        if type(extra1) == "table" and (
            extra1.aquatic ~= nil or extra1.distance ~= nil or extra1.decor ~= nil or extra1.flipable ~= nil
            or extra1.image ~= nil or extra1.wallitem ~= nil or extra1.alt_ingredients ~= nil
        ) then
            local o = extra1
            aquatic         = o.aquatic
            distance        = o.distance
            decor           = o.decor
            flipable        = o.flipable
            image           = o.image
            wallitem        = o.wallitem
            alt_ingredients = o.alt_ingredients
        end

        if hasPORK then
            local game_type = NormalizeGameType(dlc_flag)
            return _Recipe(
                name, ingredients, tab, level, game_type,
                placer, min_spacing, nounlock, numtogive,
                aquatic, distance, decor, flipable, image, wallitem, alt_ingredients
            )
        elseif hasSHIP then
            local game_type = NormalizeGameType(dlc_flag)
            return _Recipe(
                name, ingredients, tab, level, game_type,
                placer, min_spacing, nounlock, numtogive,
                aquatic, distance
            )
        else
            -- Vanilla/RoG: ignore dlc_flag and DLC-only extras
            return _Recipe(name, ingredients, tab, level, placer, min_spacing, nounlock, numtogive)
        end
    end
end



PrefabFiles = {
	"catcoondenplacer",
}
Assets = {
	Asset("ATLAS", "images/inventoryimages/catcoonden.xml"),
    Asset("IMAGE", "images/inventoryimages/catcoonden.tex"),
    Asset("ATLAS", "minimap/catcoonden_map.xml"),
}
AddMinimapAtlas("minimap/catcoonden_map.xml")
STRINGS.RECIPE_DESC.CATCOONDEN = "Catcoon's sweet home."

-- Hollow Stump
if GetModConfigData("hollow_stump") then
    
end

if IsDLCEnabled and ( IsDLCEnabled(CAPY_DLC) or IsDLCEnabled(PORKLAND_DLC) ) then

    print("INSIDE SW AND HM AA")
    --//Enable recipe at ROG world
    local catcoonden = Recipe("catcoonden",
        {
            Ingredient("twigs", GetModConfigData("twigs")),
            Ingredient("log", GetModConfigData("log")),
            Ingredient("coontail", GetModConfigData("coontail"))
        },
		RECIPETABS.TOWN, TECH.SCIENCE_TWO)
	catcoonden.atlas = "images/inventoryimages/catcoonden.xml"
    --catcoonden.image = "images/inventoryimages/catcoonden.tex"
    catcoonden.placer = "catcoonden_placer"
    catcoonden.game_type =  "rog"

elseif IsDLCEnabled and IsDLCEnabled(REIGN_OF_GIANTS) then
    --//Enable recipe at Vanilla world
    print("INSIDE ROG")
    local catcoonden = Recipe("catcoonden",
        {
            Ingredient("twigs", GetModConfigData("twigs")),
            Ingredient("log", GetModConfigData("log")),
            Ingredient("coontail", GetModConfigData("coontail"))
        },
		RECIPETABS.TOWN, TECH.SCIENCE_TWO)
	catcoonden.atlas = "images/inventoryimages/catcoonden.xml"
    catcoonden.placer = "catcoonden_placer"
end

if GetModConfigData("infinite_lives") == "on" then
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

if GetModConfigData("change_minimap_icon") == "on" then
    local function ChangeMiniMapIcon(inst)
        inst.MiniMapEntity:SetIcon("catcoonden_map.tex")
    end
    AddPrefabPostInit("catcoonden", ChangeMiniMapIcon)
end
