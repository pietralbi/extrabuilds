local M = {}

local enabledROG  = REIGN_OF_GIANTS and IsDLCEnabled(REIGN_OF_GIANTS)
local enabledSHIP = CAPY_DLC and IsDLCEnabled(CAPY_DLC)
local enabledPORK = PORKLAND_DLC and IsDLCEnabled(PORKLAND_DLC)
local enabledAnyDLC = enabledROG or enabledSHIP or enabledPORK
local vanilla = not enabledAnyDLC

-- Expose flags
M.enabledROG = enabledROG
M.enabledSHIP = enabledSHIP
M.enabledPORK = enabledPORK
M.enabledAnyDLC = enabledAnyDLC
M.vanilla = vanilla

print("enabledROG " .. tostring(M.enabledROG))
print("enabledSHIP " .. tostring(M.enabledSHIP))
print("enabledPORK " .. tostring(M.enabledPORK))
print("vanilla " .. tostring(M.vanilla))
print("enabledAnyDLC " .. tostring(M.enabledAnyDLC))

function M.MakeMediumBurnableDLC(inst)
    if M.enabledAnyDLC then
        MakeMediumBurnable(inst, nil, nil, true)
    else
        MakeMediumBurnable(inst, nil, nil)
    end
end

function M.MakePlacerDLC(name, bank, build, anim, onground, snap, metersnap, scale, snap_to_flood, fixedcameraoffset, facing, hide_on_invalid, hide_on_ground, placeTestFn, modifyfn, preSetPrefabfn)
	if M.vanilla or M.enabledROG then
		return MakePlacer(name, bank, build, anim, onground, snap, metersnap, scale, facing, placeTestFn, preSetPrefabfn)
	elseif M.enabledSHIP then
		 return MakePlacer(name, bank, build, anim, onground, snap, metersnap, scale, snap_to_flood, fixedcameraoffset, facing, hide_on_invalid, hide_on_ground, placeTestFn, preSetPrefabfn)
	elseif M.enabledPORK then
		return MakePlacer(name, bank, build, anim, onground, snap, metersnap, scale, snap_to_flood, fixedcameraoffset, facing, hide_on_invalid, hide_on_ground, placeTestFn, modifyfn, preSetPrefabfn)
	end
end

return M