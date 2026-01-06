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
    Asset("ATLAS", "images/inventoryimages/catcoonden.xml"),
    Asset("ATLAS", "images/inventoryimages/mermhouse.xml"),
    Asset("ATLAS", "images/inventoryimages/mermhouse_fisher.xml"),
    Asset("ATLAS", "images/inventoryimages/marblebean.xml"),
    Asset("ATLAS", "minimap/catcoonden_map.xml"),
    Asset("ATLAS", "minimap/mermhouse_fisher_map.xml")
}

PrefabFiles = {
    "catcoondenplacer",
    "mermhouseplacer",
    "mermhutplacer",
    "mermfisherplacer",
    "marblebean"
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

if GetModConfigData("mermhouse_fisher") then
    if enabledSHIP or enabledPORK then

        STRINGS.RECIPE_DESC.MERMHOUSE_FISHER = "A fishy house for fishing merms."

        local ingredients = {
            Ingredient("boards", GetModConfigData("boards_fisher")),
            Ingredient("rocks",   GetModConfigData("rocks_fisher")),
            Ingredient("tropical_fish", GetModConfigData("fish_fisher")),
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
    AddMinimapAtlas("minimap/mermhouse_fisher_map.xml")

    local function ChangeMiniMapIcon(inst)
        inst.MiniMapEntity:SetIcon("mermhouse_fisher_map.tex")
    end
    AddPrefabPostInit("mermhouse_fisher", ChangeMiniMapIcon)
end

if GetModConfigData("marble_tree") then
    local marblebean = MakeRecipe("marblebean", {Ingredient("marble",1)}, RECIPETABS.REFINE, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.VANILLA)
	marblebean.atlas = "images/inventoryimages/marblebean.xml"
	-- marblebean.image = "marblebean.tex" 

    STRINGS.NAMES.MARBLEBEAN = "Marble Bean"
    STRINGS.NAMES.MARBLEBEAN_SAPLING = "Marble Sprout"
    STRINGS.NAMES.MARBLESHRUB = "Marble Shrub"
    STRINGS.RECIPE_DESC.MARBLEBEAN = "Grow a marble forest."

    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLEBEAN = "I traded the old family cow for it."
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLEBEAN_SAPLING = "It looks carved."
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLESHRUB = "Makes sense to me."

    -- Character strings, no WES or WILBUR
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLEBEAN = "A lithic seed specimen. Absurd... yet promising."
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLEBEAN_SAPLING = "Growth without soil compatibility. The mechanism must be extraordinary."
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLESHRUB = "A mature marble growth. The Constant continues to defy taxonomy."

    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLEBEAN = "Pretty sure that's not gonna be edible, dude."
    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLEBEAN_SAPLING = "Whoa... it's actually growing. That's wild."
    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLESHRUB = "A rock bush. Kinda rad, not gonna lie."

    STRINGS.CHARACTERS.WARLY.DESCRIBE.MARBLEBEAN = "I don't think this bean is edible."
    STRINGS.CHARACTERS.WARLY.DESCRIBE.MARBLEBEAN_SAPLING = "Just a petite marble bébé."
    STRINGS.CHARACTERS.WARLY.DESCRIBE.MARBLESHRUB = "If marble beans can grow, maybe they can be eaten."

    STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.MARBLEBEAN = "Fee fi fo fum!"
    STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.MARBLESHRUB = "Tis a shrub of stone!"
    STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.MARBLEBEAN_SAPLING = "How dost thou grow?"

    STRINGS.CHARACTERS.WAXWELL.DESCRIBE.MARBLEBEAN = "Let me guess, it grows a marble stalk?"
    STRINGS.CHARACTERS.WAXWELL.DESCRIBE.MARBLEBEAN_SAPLING = "Stone cold growth."
    STRINGS.CHARACTERS.WAXWELL.DESCRIBE.MARBLESHRUB = "I've found a shrubbery."

    STRINGS.CHARACTERS.WEBBER.DESCRIBE.MARBLEBEAN = "Bean there, done that!"
    STRINGS.CHARACTERS.WEBBER.DESCRIBE.MARBLEBEAN_SAPLING = "You can plant anything in the ground!"
    STRINGS.CHARACTERS.WEBBER.DESCRIBE.MARBLESHRUB = "That's a weird shape for a bush."

    STRINGS.CHARACTERS.WENDY.DESCRIBE.MARBLEBEAN = "Cold... but not lifeless..."
    STRINGS.CHARACTERS.WENDY.DESCRIBE.MARBLEBEAN_SAPLING = "It cares nothing for the laws of this world..."
    STRINGS.CHARACTERS.WENDY.DESCRIBE.MARBLESHRUB = "Against all odds, it has flourished in life..."

    STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.MARBLEBEAN = "Marble growth is arboriculturally impossible."
    STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.MARBLEBEAN_SAPLING = "I believe it's a perennial."
    STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.MARBLESHRUB = "Not ideal for topiary."

    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLEBEAN = "'TIS BEAN O' ROCK"
    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLEBEAN_SAPLING = "LIL' ROCK TREE"
    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLESHRUB = "'TIS BUSH O' ROCK"

    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLEBEAN = "A stone bean. That's a new one."
    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLEBEAN_SAPLING = "It's sprouting... against all logic."
    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLESHRUB = "A marble shrub. File it under \"impossible\"."

    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLEBEAN = "I guess we just... plant it? In the dirt?"
    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLEBEAN_SAPLING = "That makes no sense!"
    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLESHRUB = "What sort of bush doesn't burn?!"

    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLEBEAN = "Brainlady says is not for eat."
    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLEBEAN_SAPLING = "Rock bush is growing!"
    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLESHRUB = "Rock is strongest bush!"

    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLEBEAN = "The magical fruit."
    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLEBEAN_SAPLING = "Well, lookit that. It sprouted."
    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLESHRUB = "Defo can't chop that."

    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLEBEAN = "Arr, that be a bean with no business bein' stone."
    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLEBEAN_SAPLING = "It be sproutin' like a cursed little mast."
    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLESHRUB = "A stony shrubbery... not much use, 'less ye be hidin' treasure."

    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLEBEAN = "Hard Bean."
    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLEBEAN_SAPLING = "Little Stone Friend!"
    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLESHRUB = "Stone Friend Big Now."

    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLEBEAN = "INFURIATINGLY ILLOGICAL"
    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLEBEAN_SAPLING = "IS IT ORGANIC OR INORGANIC?"
    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLESHRUB = "INFERIORITY ASSESSMENT: INCONCLUSIVE"
end
