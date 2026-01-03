-- This information tells other players more about the mod
name = "Extra builds"
description = "Makes extra structures cradftable, including catcoon house, mermhouse, touch stone"
author = "Alberto Pietralunga"

version = "1.0.0"
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

configuration_options =
{
	{ 
		name = "hollow_stump",
		label = "Hollow Stump",
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
	      {description = "Off", data = "off"},
	      {description = "On", data = "on"}
	   },
        default = "on"
	},
    {
        name = "change_minimap_icon",
        label = "Minimap icon",
        options =
	   {
	      {description = "Off", data = "off"},
	      {description = "On", data = "on"}
	   },
        default = "on"
	},

}
