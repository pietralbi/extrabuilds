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
    Asset("ATLAS", "images/inventoryimages/catcoonden.xml"),
    Asset("ATLAS", "images/inventoryimages/mermhouse.xml"),
    Asset("ATLAS", "images/inventoryimages/mermhouse_fisher.xml"),
    Asset("ATLAS", "images/inventoryimages/marblebean.xml"),
    Asset("ATLAS", "images/inventoryimages/mushroom_farm.xml"),
    Asset("ATLAS", "minimap/catcoonden_map.xml"),
    Asset("ATLAS", "minimap/mermhouse_fisher_map.xml"),
    Asset("ATLAS", "minimap/marbleshrub1.xml"),
    Asset("ATLAS", "minimap/marbleshrub2.xml"),
    Asset("ATLAS", "minimap/marbleshrub3.xml"),
    Asset("ATLAS", "minimap/mushroom_farm_map.xml"),
}

PrefabFiles = {
    "catcoondenplacer",
    "mermhouseplacer",
    "mermhutplacer",
    "mermfisherplacer",
    "marblebean",
    "marblebean_sapling",
    "marbleshrub",
    "mushroom_farm"
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

    STRINGS.NAMES.MARBLEBEAN = "Marble Bean"
    STRINGS.NAMES.MARBLEBEAN_SAPLING = "Marble Sprout"
    STRINGS.NAMES.MARBLESHRUB = "Marble Shrub"
    STRINGS.RECIPE_DESC.MARBLEBEAN = "Grow a marble forest."

    -- Character strings, no WES or WILBUR since they don't talk.
    -- Remove DST-only characters: WALTER WANDA WINONA WORTOX WURT 
    -- Need to add DS-only: WAGSTAFF WALANI WHEELER WILBA WOODLEGS 
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLEBEAN = "I traded the old family cow for it."
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLEBEAN_SAPLING = "It looks carved."
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MARBLESHRUB = "Makes sense to me."

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

    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLEBEAN = "I guess we just... plant it? In the dirt?"
    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLEBEAN_SAPLING = "That makes no sense!"
    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MARBLESHRUB = "What sort of bush doesn't burn?!"

    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLEBEAN = "Brainlady says is not for eat."
    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLEBEAN_SAPLING = "Rock bush is growing!"
    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MARBLESHRUB = "Rock is strongest bush!"

    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLEBEAN = "The magical fruit."
    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLEBEAN_SAPLING = "Well, lookit that. It sprouted."
    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MARBLESHRUB = "Defo can't chop that."

    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLEBEAN = "Hard Bean."
    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLEBEAN_SAPLING = "Little Stone Friend!"
    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MARBLESHRUB = "Stone Friend Big Now."

    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLEBEAN = "INFURIATINGLY ILLOGICAL"
    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLEBEAN_SAPLING = "IS IT ORGANIC OR INORGANIC?"
    STRINGS.CHARACTERS.WX78.DESCRIBE.MARBLESHRUB = "INFERIORITY ASSESSMENT: INCONCLUSIVE"

    -- DS-only
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLEBEAN = "A lithic seed specimen. Preposterous... yet full of potential."
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLEBEAN_SAPLING = "Vegetative growth without soil dependence. Fascinating."
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MARBLESHRUB = "A fully developed marble growth. Classification remains elusive."

    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLEBEAN = "Yeah, I wouldn't try eatin' that, dude."
    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLEBEAN_SAPLING = "No way. It's actually growin'."
    STRINGS.CHARACTERS.WALANI.DESCRIBE.MARBLESHRUB = "A rock bush. Weird, but kinda cool."

    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLEBEAN = "A bean made of stone. Figures."
    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLEBEAN_SAPLING = "It's growing. It shouldn't be."
    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MARBLESHRUB = "A marble shrub. This place is ridiculous."

    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLEBEAN = "'TIS HARD BEAN"
    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLEBEAN_SAPLING = "LITTLE ROCK TREE GROWS"
    STRINGS.CHARACTERS.WILBA.DESCRIBE.MARBLESHRUB = "'TIS BUSH O' ROCK"

    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLEBEAN = "Arr, a bean o' stone. The sea's got stranger, but not by much."
    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLEBEAN_SAPLING = "Growin' like a cursed splinter, it be."
    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MARBLESHRUB = "A bush o' marble. Worthless, 'less ye need cover fer plunder."
end

if GetModConfigData("mushroom_farm") then
    local mushroom_farm = MakeRecipe("mushroom_farm", {Ingredient("spoiled_food", 8),Ingredient("poop", 5),Ingredient("livinglog", 2)}, RECIPETABS.FARM, TECH.SCIENCE_TWO, RECIPE_GAME_TYPE.VANILLA, "mushroom_farm_placer", 2)
	mushroom_farm.atlas = "images/inventoryimages/mushroom_farm.xml"
    local beebox = GLOBAL.GetRecipe("beebox")
    if beebox ~= nil then
        mushroom_farm.sortkey = beebox.sortkey + 0.2
    end

    AddMinimapAtlas("minimap/mushroom_farm_map.xml")

    STRINGS.NAMES.MUSHROOM_FARM = "Mushroom Planter"
    STRINGS.RECIPE_DESC.MUSHROOM_FARM = "Grows mushrooms."

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

    STRINGS.CHARACTERS.GENERIC.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "The power of science compelled it.",
        EMPTY = "It could use a mushroom transplant.",
        LOTS = "The mushrooms have really taken to the log.",
        ROTTEN = "The log is dead. We should replace it with a live one.",
        SNOWCOVERED = "I don't think it can grow in this cold.",
        SOME = "It should keep growing now."
    }

    STRINGS.CHARACTERS.WARLY.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Mmm, smells like fried mushrooms.",
        EMPTY = "I could grow some fresh mushrooms here.",
        LOTS = "It's nice not to have to forage for the basics.",
        ROTTEN = "I'll need to find a replacement if I want fresh mushrooms.",
        SNOWCOVERED = "Mushrooms are out of season right now.",
        SOME = "Oh, my mushrooms are beginning to grow!"
    }

    STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "'Twas consumed by a mighty inferno!",
        EMPTY = "An empty home for forest sprites.",
        LOTS = "It is growing strong and hearty.",
        ROTTEN = "A blight has beset this log. Another!",
        SNOWCOVERED = "Not all can withstand the frost giant's touch.",
        SOME = "The forest sprite has taken root."
    }

    STRINGS.CHARACTERS.WAXWELL.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Only ash and ruin remain here.",
        EMPTY = "Smells... \"piney\".",
        LOTS = "The mushrooms have really taken to the log.",
        ROTTEN = "Rotten, all the way through. I relate.",
        SNOWCOVERED = "Nothing grows in these frigid wastes.",
        SOME = "They seem to be doing well."
    }

    STRINGS.CHARACTERS.WEBBER.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Fire's dangerous, I guess.",
        EMPTY = "There aren't any mushrooms.",
        LOTS = "They look happy.",
        ROTTEN = "It's all yucky.",
        SNOWCOVERED = "You look chilly.",
        SOME = "Aw, they're so little."
    }

    STRINGS.CHARACTERS.WENDY.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "It is no more.",
        EMPTY = "Emptiness. The natural state of all things.",
        LOTS = "It thrives... against all odds...",
        ROTTEN = "Nothing escapes the pull of decay.",
        SNOWCOVERED = "A frigid cold bites at its heart.",
        SOME = "The beginnings of life..."
    }

    STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Carbonized by an exothermic chemical reaction.",
        EMPTY = "It must first be seeded with a cut specimen.",
        LOTS = "An excellent fungal yield.",
        ROTTEN = "The state of decomposition is too advanced to support any specimens.",
        SNOWCOVERED = "Its growth has been halted by the extreme cold.",
        SOME = "The fungi are fruiting nicely."
    }

    STRINGS.CHARACTERS.WILLOW.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Mold problem's taken care of.",
        EMPTY = "It's just a dumb log.",
        LOTS = "Gross, they're taking over!",
        ROTTEN = "Nasty. Let's burn the rot out.",
        SNOWCOVERED = "I'm sure fire would fix that.",
        SOME = "There's mushrooms growing in it now."
    }

    STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Log is not looking mighty!",
        EMPTY = "Is nothing.",
        LOTS = "So many little mushy-rooms!",
        ROTTEN = "Dead log is need to be replaced.",
        SNOWCOVERED = "Mushy-rooms not mighty enough to fight snow!",
        SOME = "Little mushy-rooms is start to grow."
    }

    STRINGS.CHARACTERS.WOODIE.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "If a log burns in the forest does it hurt my feelings? Yes. It does.",
        EMPTY = "It needs a bit of help getting started.",
        LOTS = "It's doing real well on its own.",
        ROTTEN = "That rotten log needs replacing.",
        SNOWCOVERED = "Everybody's got hardships, eh?",
        SOME = "There we go. Everyone needs a bit of help sometimes."
    }

    STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Fire is bad",
        EMPTY = "What happened, friend?",
        LOTS = "Lots of new friends!",
        ROTTEN = "Oh. So sorry",
        SNOWCOVERED = "Too cold?",
        SOME = "Hello, little friends!"
    }

    STRINGS.CHARACTERS.WX78.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "THAT'S WHAT IT GETS FOR BEING FLAMMABLE",
        EMPTY = "IT IS FREE FROM ORGANIC GROWTHS",
        LOTS = "LOTS OF FILTHY GROWTHS",
        ROTTEN = "LOG ERROR",
        SNOWCOVERED = "INFERIOR PLANT. MY CIRCUITS FUNCTION BETTER WHEN COLD",
        SOME = "IT IS STARTING TO GROW THINGS"
    }

    -- DS-only
    STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Catastrophic combustion. A regrettable but informative outcome.",
        EMPTY = "An uncolonized substrate. It requires fungal inoculation.",
        LOTS = "Ah! A successful symbiotic proliferation.",
        ROTTEN = "Structural integrity failure. The log must be replaced.",
        SNOWCOVERED = "Growth has ceased under suboptimal thermal conditions.",
        SOME = "Initial growth phase observed. Promising."
    }

    STRINGS.CHARACTERS.WALANI.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Whoa. Yeah, that thing's toast.",
        EMPTY = "Looks like it needs somethin' to get started.",
        LOTS = "Nice. Free mushrooms without the hike.",
        ROTTEN = "Bummer. Guess the log gave up.",
        SNOWCOVERED = "Too cold for stuff to grow, I guess.",
        SOME = "Hey, it's workin'!"
    }

    STRINGS.CHARACTERS.WHEELER.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "That didn't last.",
        EMPTY = "Nothing growing yet.",
        LOTS = "It's producing well.",
        ROTTEN = "Log's done. Replace it.",
        SNOWCOVERED = "Too cold to function.",
        SOME = "It's starting."
    }

    STRINGS.CHARACTERS.WILBA.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "'TIS SLAIN BY FIRE",
        EMPTY = "NO FRIENDS DWELL WITHIN",
        LOTS = "MANY FRIENDS DOTH GROW",
        ROTTEN = "LOG DOTH DECAY",
        SNOWCOVERED = "COLD STAYETH GROWTH",
        SOME = "LITTLE FRIENDS DOTH SPROUT"
    }

    STRINGS.CHARACTERS.WOODLEGS.DESCRIBE.MUSHROOM_FARM = {
        BURNT = "Arrr, fire's claimed it. Nothin' but ash an' ruin.",
        EMPTY = "Nary a shroom in sight. Needs seedin', aye.",
        LOTS = "Har har! The fungus be takin' it over, it be.",
        ROTTEN = "That log's gone foul. Best swap it out, matey.",
        SNOWCOVERED = "Too bleedin' cold fer anythin' to grow.",
        SOME = "Aye, it's sproutin' now. Slow an' steady."
    }

    -- ACTIONS --
    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "A living log would probably be of more use."
    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "A mushroom would probably be of more use."

    STRINGS.CHARACTERS.WARLY.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "It needs a dash of something else."
    STRINGS.CHARACTERS.WARLY.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "It needs a dash of something else."

    STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "The sprite home requires sprucing up. With magical spruce!"
    STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Forest sprites have no need of that."

    STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "A living log would be more suited to this."
    STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "A mushroom would be more suited to this."

    STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "It needs a special kind of log!"
    STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "It needs a mushroom!"

    STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "It doesn't need that. It needs a magic log."
    STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "It doesn't need that. It needs a mushroom."

    STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "It needs a log, imbued with magical properties."
    STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Goodness no, it needs a fresh mushroom."

    STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Ughh, it doesn't need this! It needs a living log!"
    STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Ughh, it doesn't need this! It needs a mushroom!"

    STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Is needing tiny log with face."
    STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Is needing tiny mushy-room, I think."

    STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "That needs a magic log, eh?"
    STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "That needs a mushroom spore, eh?"

    STRINGS.CHARACTERS.WORMWOOD.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Needs friends"
    STRINGS.CHARACTERS.WORMWOOD.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Needs Fun Guy Friends"

    STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "SPECIAL LOG-IN REQUIRED"
    STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "FUNGUS UPDATE REQUIRED"

    -- DS-only
    STRINGS.CHARACTERS.WAGSTAFF.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "No, no! It requires a living log. A crucial reagent!"
    STRINGS.CHARACTERS.WAGSTAFF.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "That won't do. It needs a mushroom to proceed!"

    STRINGS.CHARACTERS.WALANI.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Nah, it wants one of those living logs."
    STRINGS.CHARACTERS.WALANI.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "Nope. It needs a mushroom."

    STRINGS.CHARACTERS.WHEELER.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Wrong. Needs a living log."
    STRINGS.CHARACTERS.WHEELER.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "No. Needs a mushroom."

    STRINGS.CHARACTERS.WILBA.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "'TIS NOT RIGHT. IT NEED'ST LIVING LOG"
    STRINGS.CHARACTERS.WILBA.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "NAY. IT NEED'ST A MUSHROOM"

    STRINGS.CHARACTERS.WOODLEGS.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSLOG = "Nay, that won't do. It be needin' a livin' log."
    STRINGS.CHARACTERS.WOODLEGS.ACTIONFAIL.GIVE.MUSHROOMFARM_NEEDSSHROOM = "That ain't right. It be needin' a mushroom."
end