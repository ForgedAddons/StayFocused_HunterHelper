
if select(2, UnitClass("player")) ~= "HUNTER" then
	do return end
end

StayFocused_HunterHelper = CreateFrame("Frame")
local frame = StayFocused_HunterHelper

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_POWER")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")

StayFocused_HunterHelper_Cast = CreateFrame("StatusBar", nil, StayFocused)
local precast = StayFocused_HunterHelper_Cast

StayFocused_HunterHelper_Spark = CreateFrame("Frame", nil, StayFocused)
local spark = StayFocused_HunterHelper_Spark

local sparkmin = spark:CreateTexture(nil,"OVERLAY");
sparkmin:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");

local sparkmax = spark:CreateTexture(nil,"OVERLAY");
sparkmax:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
	
local function precast_Hide()
	precast:SetAlpha(0)
end

local function precast_Show()
	 precast:SetAlpha(StayFocused:GetAlpha()*0.5)
end

local function SpellInfo(spell)
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spell)
	return name, cost
end

local function MainShot()

	local tree = GetPrimaryTalentTree()
	
	if tree == 3 then 
		return select(2, SpellInfo(53301)), 53301
	elseif tree == 2 then 
		return select(2, SpellInfo(53209)), 53209
	else 
		return select(2, SpellInfo(34026)), 34026
	end

end

local _, dumpshot = SpellInfo(SpellInfo(3044))
local mainshot = MainShot()
local regen = GetPowerRegen()

local function precast_Set()
   local alias = StayFocused
   local db = StayFocused_HunterHelperDB 

   precast:SetStatusBarTexture(StayFocused:GetStatusBarTexture():GetTexture())
   precast:SetMinMaxValues(0, 1)
   precast:SetValue(1)
   precast:SetFrameLevel(alias:GetFrameLevel())
   
   precast:SetSize((alias:GetWidth()/100)*9, alias:GetHeight())
   
   precast_Hide()
   
	if frame.db.castcolor then
		precast:SetStatusBarColor(db.precolor[1], db.precolor[2], db.precolor[3], 1)
	else
		precast:SetStatusBarColor(StayFocused:GetStatusBarColor())
	end
end

local include = 0
local casting = false
local function precast_Update()

	if not casting then return end

	local alias = StayFocused

	local width = alias:GetWidth()
	local value = alias:GetValue()
	local _, max = alias:GetMinMaxValues()
	local position = width/(max/value)

	if UnitHealth("target")/UnitHealthMax("target") <= 0.25 then 
		include = 9 + select(5, GetTalentInfo(2, 12)) * 3
	end

--	precast:SetSize((alias:GetWidth()/100)*(include or 9), alias:GetHeight())
	precast:SetSize((alias:GetWidth()/100)*(include), alias:GetHeight())

	precast:ClearAllPoints()
	precast:SetPoint("LEFT", alias, "LEFT", position, 0)
	if not frame.db.castcolor then
		precast:SetStatusBarColor(StayFocused:GetStatusBarColor())
	end

end

local function spark_Set()

	
	if not frame.db.show_spark then 
		sparkmin:Hide()
		sparkmax:Hide()
		return
	end
	
	local alias = StayFocused
	sparkmin:SetWidth(10)
    sparkmin:SetBlendMode("ADD")
    sparkmin:SetHeight(alias:GetHeight()*1.7)
	
	sparkmax:SetWidth(10)
    sparkmax:SetBlendMode("ADD")
    sparkmax:SetHeight(alias:GetHeight()*1.7)
end

local function spark_Update(power)

	if not frame.db.show_spark then 
		sparkmin:Hide()
		sparkmax:Hide()
		return
	end

	local alias = StayFocused
	local _, mainshot_id = MainShot()
	local power = power or 0
 
 	local width = alias:GetWidth()
	local _, max = alias:GetMinMaxValues()
	local ppf = (width/max)
	
	do
		if mainshot == 0 then return end -- to avoid lock + load confusion
		sparkmin:SetPoint("LEFT", alias, "LEFT", mainshot*ppf-5, 0)
		sparkmax:SetPoint("LEFT", alias, "LEFT", (mainshot+dumpshot)*ppf-5, 0)
	end
	
	local start, duration, enabled = GetSpellCooldown(mainshot_id)
	if ( start > 0 and duration > 0) then
		local cooldown = (start + duration - GetTime())
		if cooldown > 3 then
			sparkmin:SetVertexColor(1,0,0) -- not ready
		elseif cooldown > 1 then
			sparkmin:SetVertexColor(1,0.5,0) -- ready soon
		else
			sparkmin:SetVertexColor(0.5,1,0) --gcd, ready
		end
	else
	 sparkmin:SetVertexColor(0,1,0) --no gcd, ready
	end

	if power >= select(2, SpellInfo(2643)) then
		sparkmax:SetVertexColor(0,1,0)
	else
		sparkmax:SetVertexColor(1,1,0)
	end
	
	sparkmin:Show()
	sparkmax:Show()
end

function frame:ApplyOptions()
	precast_Set()
	spark_Set()
end



--fps calculation
local pow_c = 0
local array_pairs = {}
local array_time = {}
local pointer = 1
local timer = 0
local function HunterHelperCalc(power, max_power, elapsed)

   if power == max_power then 
      do return end
   end
   
   timer = timer + elapsed
      
      local pow = UnitPower("player")
      
      if pointer > 3 then pointer = 1 end
      
      if pow_c ~= pow then
         if ((pow-pow_c) > 1) and ((pow-pow_c) < 9 )then
            array_pairs[pointer] = {pow-pow_c, 6*timer}
			timer = 0
            local sum_f = 0
            local sum_t = 0
            local size = 0
			
            for k,v in pairs(array_pairs) do
			   size = k
               sum_f = sum_f + v[1]
               sum_t = sum_t + v[2]
            end
			
            local avg_f = sum_f / size
            local avg_t = sum_t / size
            array_time[pointer] = avg_f/avg_t
            local sum_b = 0
            local size_b = 0
			
            for k,v in pairs(array_time) do
			   size_b = k
               sum_b = sum_b + v
            end
			
            regen = GetPowerRegen() + (sum_b/size_b)
            pointer = pointer + 1
         end
         pow_c = pow
      end
	 -- regen = 4
end

local function HunterHelperOnUpdate(power, max_power, elapsed)

	if not frame.db.include_ss then include = 0 end

	HunterHelperCalc(power, max_power, elapsed)
	local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
	_, dumpshot = SpellInfo(SpellInfo(3044))
	mainshot = MainShot()
		--color handling
	if mainshot then
		if power > mainshot + dumpshot - regen - include then
		--if power > 75 then
			StayFocused:SetStatusBarColor(frame.db.fullcolor[1], frame.db.fullcolor[2], frame.db.fullcolor[3])
		elseif power < mainshot - include then
		--elseif power < 40 then
			StayFocused:SetStatusBarColor(frame.db.warncolor[1], frame.db.warncolor[2], frame.db.warncolor[3])
		elseif StayFocusedDB["class_colored"] == true then
			StayFocused:SetStatusBarColor(color.r, color.g, color.b)
		else
			StayFocused:SetStatusBarColor(1,1,1)
		end
		spark_Update(power)
	end

		--value handling
	if frame.db.show_text and StayFocused.value:GetText() then

		local value = StayFocused.value:GetText()
		value = value .. " (~" .. string.format("%.1f", regen) .. " f/s )"
		StayFocused.value:SetText(value)
	end
		--precast 
	if  frame.db.show_cast then

		precast_Update()
	end
end

--frame:SetScript("OnUpdate", HunterHelperOnUpdateTimer)

frame:SetScript("OnEvent", function(self, event, ...)
	local steady = 56641
	local cobra = 77767
		if event == "ADDON_LOADED" then
			local addon = ...
			if addon:lower() ~= "stayfocused_hunterhelper" then return end

			if StayFocused_HunterHelperDB then
				if StayFocused_HunterHelperDB.show_cast == nil then StayFocused_HunterHelperDB = nil end -- 400002.3 to 40000.3 reset
				if StayFocused_HunterHelperDB.include_ss == nil then StayFocused_HunterHelperDB.include_ss = true end --40000.5.1 to 40000.5.2
				if StayFocused_HunterHelperDB.castcolor == nil then StayFocused_HunterHelperDB.castcolor = false end --40000.5.1 to 40000.5.2
				if StayFocused_HunterHelperDB.warncolor == nil then StayFocused_HunterHelperDB = nil end --40000.5.2 to 40000.5.3 reset
				if StayFocused_HunterHelperDB.show_spark == nil then StayFocused_HunterHelperDB.show_spark = true end --40000.6.2 to 40000.6.3
			end
			
			StayFocused_HunterHelperDB = StayFocused_HunterHelperDB or {
				show_text = false,
				show_cast = true, 
				warncolor = {1, 0.3, 0.2},
				fullcolor = {0, 0.3, 1},
				precolor = {0, 1, 0.4},
				include_ss = true,
				castcolor = false,
				show_spark = true,
			}
			
			self.db = StayFocused_HunterHelperDB

			StayFocused:AddHandler('HunterHelper', HunterHelperOnUpdate)
			hooksecurefunc(StayFocused, "ApplyOptions", precast_Set)
			hooksecurefunc(StayFocused, "ApplyOptions", spark_Set)
			
			self:UnregisterEvent("ADDON_LOADED")

			
			precast_Set()
			precast_Hide()
			spark_Set()
	elseif event == "UNIT_SPELLCAST_START" then
		if select(1, ...) == "player" then
			local spellid = select(5, ...)
			if spellid  == steady or spellid == cobra then
				include = 9
				casting = true
				if self.db.show_cast then
					precast_Update()
					precast_Show()
				end
			end
		end
	elseif string.find(event, "UNIT_SPELLCAST_") then
		if select(1, ...) == "player" then
			local spellid = select(5, ...)
			if spellid  == steady or spellid == cobra then
				include = 0
				casting = false
				if self.db.show_cast then
					precast_Hide()
				end
			end
		end		
	end
end)
