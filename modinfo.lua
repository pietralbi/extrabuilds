-- This information tells other players more about the mod
name = "Extra builds"
description = "Makes extra structures cradftable, including catcoon house, mermhouses, marble tree and mushroom planter"
author = "Alberto Pietralunga"

version = "1.4.2"
forumthread = ""

api_version = 6
dont_starve_compatible      = true
reign_of_giants_compatible  = true
shipwrecked_compatible      = true
hamlet_compatible           = true

-- Can specify a custom icon for this mod!
icon_atlas = "modicon.xml"
icon = "modicon.tex"


-- Configs

local function simpleopt(x)
	return {description = x, data = x}
end

local function append(t, x)
	t[#t + 1] = x
	return t
end

local function range(a, b, step)
	local opts = {}
	for x = a, b, step do
		append(opts, simpleopt(x))
	end
	if #opts > 0 then
		local fdata = opts[#opts].data
		if fdata < b and fdata + step - b < 1e-10 then
			append(opts, simpleopt(b))
		end
	end
	return opts
end

-- MUSHROOMFARM_MAXHARVEST --
local mm_opt = range(1, 10, 1)
mm_opt = append(mm_opt, {description = "Infinite", data = false})

configuration_options =
{
	{
		name = "hollow_stump",
		label = "1. Hollow Stump",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
    {
 		name = "twigs",
		label = "Twigs",
		options = range(1, 16, 1),
		default = 4
	},
    {
 		name = "log",
		label = "Logs",
		options = range(1, 16, 1),
		default = 4
	},

    	{
 		name = "coontail", 
		label = "Catcoon tails",
		options = range(1, 16, 1),
		default = 4
	},
	{
        name = "infinite_lives",
        label = "Infinite lives",
        options =
	   {
	      {description = "Off", data = false},
	      {description = "On", data = true}
	   },
        default = true
	},
    {
        name = "change_minimap_icon",
        label = "Minimap icon",
        options =
	   {
	      {description = "Off", data = false},
	      {description = "On", data = true}
	   },
        default = true
	},
	{
		name = "mermhouse",
		label = "2. Mermhouse/Merm Hut",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
    {
 		name = "boards", 
	    label = "Boards",
        options = range(1, 16, 1),
		default = 4
	},
    {
 		name = "rocks", 
	    label = "Rocks",
        options = range(1, 16, 1),
		default = 4
	},
    {
 		name = "fish",
	    label = "Fish/Tropical Fish",
        options = range(1, 16, 1),
		default = 4
	},
	{
		name = "mermhouse_fisher",
		label = "3. Fishermerm's Hut",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
    {
 		name = "boards_fisher",
	    label = "Boards",
        options = range(1, 16, 1),
		default = 4
	},
    {
 		name = "rocks_fisher",
	    label = "Rocks",
        options = range(1, 16, 1),
		default = 4
	},
    {
 		name = "seaweed_fisher",
	    label = "Seaweed",
        options = range(1, 16, 1),
		default = 4
	},
    {
        name = "change_minimap_icon_fisher",
        label = "Minimap icon",
        options =
	   {
	      {description = "Off", data = false},
	      {description = "On", data = true}
	   },
        default = true
	},
	{
		name = "marble_tree",
		label = "4. Marble tree",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
	{
		name = "marble_tree_loop",
		label = "Growth-stage loop ",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
	{
		name = "mushroom_farm",
		label = "4. Mushroom Planter",
        options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
        default = true
	},
	{
 		name = "mushroomfarm_maxharvest",
		label = "Harvests before depletion",
		options = mm_opt,
		default = 4
	},
	{
		name = "meatrack",
		label = "5. DST Meat Rack",
		options =
	    {
	    	{description = "Off", data = false},
	    	{description = "On", data = true}
	    },
		default = true
	}
}
