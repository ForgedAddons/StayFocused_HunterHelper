do

if select(2, UnitClass("player")) ~= "HUNTER" then
	do return end
end

local myname, ns = ...

local ICONSIZE, ICONGAP, GAP, EDGEGAP, BIGGAP = 32, 3, 8, 16, 16
local tekcheck = LibStub("tekKonfig-Checkbox")
local tekslide = LibStub("tekKonfig-Slider")
local tekbutton = LibStub("tekKonfig-Button")

local frame = CreateFrame("Frame", "StayFocusedHunterHelperConfig", InterfaceOptionsFramePanelContainer)
frame.name = "Hunter Helper (plugin)"
frame.parent = "Stay Focused!"

local data = StayFocused_HunterHelper

local title, subtitle = LibStub("tekKonfig-Heading").new(frame, "|cffa0a0f0Stay Focused!|r - Hunter Helper", "Color/Text Options for Hunter Helper")

local function CreateBar(parent, text, ...)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(StayFocused:GetStatusBarTexture():GetTexture())
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(1)
	bar:SetSize(100, 20)
	bar:SetStatusBarColor(1,1,1,1)
	bar:SetFrameStrata("FULLSCREEN_DIALOG")
	if select("#", ...) > 0 then bar:SetPoint(...) end
	
	bar.value = bar:CreateFontString()
	bar.value:SetPoint("CENTER", bar, "CENTER")
	--bar.value:SetJustifyH("CENTER")
	bar.value:SetFont(StayFocused.value:GetFont())
	bar.value:SetText(text)
	--bar.value:SetFrameLevel(100)
	--bar:SetPoint("CENTER", parent, "CENTER", 0, 0)
	return bar
end

local function ShowColorPicker(r, g, b, a, changedCallback)
 
 ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
 ColorPickerFrame.previousValues = {r,g,b,a};
 ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
 --ColorPickerFrame.func, ColorPickerFrame.cancelFunc = changedCallback, changedCallback
 ColorPickerFrame:SetColorRGB(r,g,b);
 ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
 ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
 ColorPickerFrame:Show();
end

local function warnCallback(restore)
 local newR, newG, newB
 if restore then
  newR, newG, newB = unpack(restore);
 else
  newR, newG, newB = ColorPickerFrame:GetColorRGB();
 end
 data.db.warncolor = {newR, newG, newB}
 warnbar:SetStatusBarColor(data.db.warncolor[1], data.db.warncolor[2], data.db.warncolor[3], 1)
end

local function fullCallback(restore)
 local newR, newG, newB
 if restore then
  newR, newG, newB = unpack(restore);
 else
  newR, newG, newB = ColorPickerFrame:GetColorRGB();
 end
 data.db.fullcolor = {newR, newG, newB}
 fullbar:SetStatusBarColor(data.db.fullcolor[1], data.db.fullcolor[2], data.db.fullcolor[3], 1)
end

local function preCallback(restore)
 local newR, newG, newB
 if restore then
  newR, newG, newB = unpack(restore);
 else
	newR, newG, newB = ColorPickerFrame:GetColorRGB();
 end
 data.db.precolor = {newR, newG, newB}
 castbar:SetStatusBarColor(data.db.precolor[1], data.db.precolor[2], data.db.precolor[3], 1)
 StayFocused_HunterHelper:ApplyOptions()
end

warnbar = CreateBar(frame, "Warn Color", "TOPLEFT", 32, -196)
warnbar:SetScript("OnMouseUp", function() ShowColorPicker(data.db.warncolor[1], data.db.warncolor[2], data.db.warncolor[3], nil, warnCallback) end)

fullbar = CreateBar(frame, "Full Color", "TOPLEFT", 160, -196)
fullbar:SetScript("OnMouseUp", function() ShowColorPicker(data.db.fullcolor[1], data.db.fullcolor[2], data.db.fullcolor[3], nil, fullCallback) end)

castbar = CreateBar(frame, "Cast Color", "TOPLEFT", 288, -196)
local function castbarscript()
	ShowColorPicker(data.db.precolor[1], data.db.precolor[2], data.db.precolor[3], nil, preCallback)
end
--xcastbar:SetScript("OnMouseUp", castbarscript)


local show_text = tekcheck.new(frame, nil, "Show focus per second", "TOPLEFT", subtitle, "BOTTOMLEFT", 0, -GAP)
local check_text = show_text:GetScript("OnClick")
show_text:SetScript("OnClick", function(self)
	check_text(self);
	data.db.show_text = not data.db.show_text
	StayFocused_HunterHelper:ApplyOptions()
end)

local include_ss = tekcheck.new(frame, nil, "Include Steady/Cobra", "LEFT", show_text, "LEFT", 12*BIGGAP, 0)
local check_include_ss = include_ss:GetScript("OnClick")
include_ss:SetScript("OnClick", function(self)
	check_include_ss(self);
	data.db.include_ss = not data.db.include_ss
	StayFocused_HunterHelper:ApplyOptions()
end)

local show_cast = tekcheck.new(frame, nil, "Show Cast Preview", "TOPRIGHT", show_text, "BOTTOMRIGHT", 0, -GAP)
local check_cast = show_cast:GetScript("OnClick")
show_cast:SetScript("OnClick", function(self)
	check_cast(self);
	data.db.show_cast = not data.db.show_cast
	StayFocused_HunterHelper:ApplyOptions()
end)

local color_cast = tekcheck.new(frame, nil, "Extra Cast Preview Color", "LEFT", show_cast, "LEFT", 12*BIGGAP, 0)
local check_color_cast = color_cast:GetScript("OnClick")
color_cast:SetScript("OnClick", function(self)
	check_color_cast(self);
	data.db.castcolor = not data.db.castcolor
	---[[--
	if data.db.castcolor then 
		castbar:SetScript("OnMouseUp", castbarscript)
		castbar:SetStatusBarColor(data.db.precolor[1], data.db.precolor[2], data.db.precolor[3], 1)
	else
		castbar:SetScript("OnMouseUp", nil)
		castbar:SetStatusBarColor(1,1,1, 0.2)
	end
	--]]--
	StayFocused_HunterHelper:ApplyOptions()
end)

local show_spark = tekcheck.new(frame, nil, "Show Sparks", "TOPRIGHT", show_cast, "BOTTOMRIGHT", 0, -GAP)
local check_spark = show_spark:GetScript("OnClick")
show_spark:SetScript("OnClick", function(self)
	check_spark(self);
	data.db.show_spark = not data.db.show_spark
	StayFocused_HunterHelper:ApplyOptions()
end)


frame:SetScript("OnShow", function(frame)
	show_text:SetChecked(data.db.show_text)
	include_ss:SetChecked(data.db.include_ss)
	show_cast:SetChecked(data.db.show_cast)
	color_cast:SetChecked(data.db.castcolor)
	show_spark:SetChecked(data.db.show_spark)

	 warnbar:SetStatusBarColor(data.db.warncolor[1], data.db.warncolor[2], data.db.warncolor[3], 1)
	 fullbar:SetStatusBarColor(data.db.fullcolor[1], data.db.fullcolor[2], data.db.fullcolor[3], 1)
	
	if data.db.castcolor then 
		castbar:SetScript("OnMouseUp", castbarscript)
		castbar:SetStatusBarColor(data.db.precolor[1], data.db.precolor[2], data.db.precolor[3], 1)
	else
		castbar:SetScript("OnMouseUp", nil)
		castbar:SetStatusBarColor(1,1,1, 0.2)
	end
	 
	 warnbar:SetStatusBarTexture(StayFocused:GetStatusBarTexture():GetTexture())
	 fullbar:SetStatusBarTexture(StayFocused:GetStatusBarTexture():GetTexture())
	 castbar:SetStatusBarTexture(StayFocused:GetStatusBarTexture():GetTexture())
end)

StayFocused_HunterHelper.configframe = frame
InterfaceOptions_AddCategory(frame)

--LibStub("tekKonfig-AboutPanel").new("Hunter Helper (plugin)", "StayFocused_HunterHelper")

end