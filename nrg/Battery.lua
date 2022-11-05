--[[
Author:			Mimma @ <EU-Pyrewood Village>
Create Date:	2022-06-25

The source code can be found at Github:
https://github.com/Sentilix/nrg

A small and simple addon to display mp5 cooldown.

Please see the ReadMe.txt for addon details.
]]


--	Persisted options, needs to be global.
NRG_Options = { };


local addonMetadata = {
	["ADDONNAME"]		= "NRG",
	["SHORTNAME"]		= "nrg",
	["PREFIX"]			= "NRGv1",
	["NORMALCHATCOLOR"]	= "2060FF",
	["HOTCHATCOLOR"]	= "F0F0F0",
};
local A = DigamAddonLib:new(addonMetadata);


local NRG_BACKDROP_POWER0 = {
	bgFile = "Interface\\Icons\\battery-00.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};
local NRG_BACKDROP_POWER1 = {
	bgFile = "Interface\\Icons\\battery-00.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};
local NRG_BACKDROP_POWER2 = {
	bgFile = "Interface\\Icons\\battery-02.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};
local NRG_BACKDROP_POWER3 = {
	bgFile = "Interface\\Icons\\battery-03.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};
local NRG_BACKDROP_POWER4 = {
	bgFile = "Interface\\Icons\\battery-04.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};
local NRG_BACKDROP_POWER5 = {
	bgFile = "Interface\\Icons\\battery-05.blp",
	edgeSize = 0,
	tile = 0,
	tileSize = 256,
};

local NRG_POWERLEVELS = {
	[0] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power0", },
	[1] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power1", },
	[2] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power2", },
	[3] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power3", },
	[4] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power4", },
	[5] = { ["icon"] = "Interface\\AddOns\\nrg\\Icons\\power5", },
}

local NRG_ENABLED_FOR_CLASSES = {
	["DRUID"] = true,
	["MAGE"] = true,
	["MONK"] = true,
	["PALADIN"] = true,
	["PRIEST"] = true,
	["SHAMAN"] = true,
	["WARLOCK"] = true,
}

local CONFIG_KEY_PowerButtonPosX = "PowerButton.X";
local CONFIG_KEY_PowerButtonPosY = "PowerButton.Y";
local CONFIG_KEY_PowerButtonSize = "PowerButton.Size";
local CONFIG_KEY_PowerButtonVisible = "PowerButton.Visible";


local CONFIG_DEFAULT_PowerButtonSize = 3;
local CONFIG_DEFAULT_PowerButtonVisible = true;

A.currentVersion = 0;
A.currentPowerLevel = 0;
A.enabledForPlayer = false;

--	Timer settings:
A.timerTick = 0;
A.nextPowerStep = 0;
A.powerFrequency = 1.00;
A.disableUpdates = true;


--
--	Slash commands
--

SLASH_NRG_NRG1 = "/nrg"
SlashCmdList["NRG_NRG"] = function(msg)
	local _, _, option = string.find(msg, "(%S*)")

	if not option or option == "" then
		option = "CFG"
	end
	option = string.upper(option);
		
	if (option == "CFG" or option == "CONFIG") then
		-- Skip; no CONFIG options in addon (yet?)
		--SlashCmdList["NRG_CONFIG"]();
	elseif option == "SHOW" then
		SlashCmdList["NRG_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["NRG_HIDE"]();
	elseif option == "SIZE" then
		SlashCmdList["NRG_SIZE"](msg);
	elseif option == "VERSION" then
		SlashCmdList["NRG_VERSION"]();
	else
		A:echo(string.format("Unknown command: %s", option));
	end
end

--	Show the power button
--	Syntax: /nrgshow
--	Alternative: /nrgshow
SLASH_NRG_SHOW1 = "/nrg show"	
SlashCmdList["NRG_SHOW"] = function(msg)
	NRGPowerButton:Show();
	A.configPowerButtonVisible = true;
	A:SetOption(CONFIG_KEY_PowerButtonVisible, A.configPowerButtonVisible);
end

--	Hide the power button
--	Syntax: /nrghide
--	Alternative: /nrg hide
SLASH_NRG_HIDE1 = "/nrghide"	
SlashCmdList["NRG_HIDE"] = function(msg)
	NRGPowerButton:Hide();
	A.configPowerButtonVisible = false;
	A:SetOption(CONFIG_KEY_PowerButtonVisible, A.configPowerButtonVisible);
end

--	Set the size of the power button
--	Syntax: /nrgsize <size 1-15>
--	Alternative: /nrg size <size 1-15>
SLASH_NRG_SIZE1 = "/nrgsize"	
SlashCmdList["NRG_SIZE"] = function(msg)
	local _, _, sizeStr = string.find(msg, "size (%d*)");
	local size = tonumber(sizeStr);
	if size and size >= 1 and size <= 15 then
		A:UpdatePowerButtonSize(size + 1);
		A:SetOption(CONFIG_KEY_PowerButtonSize, size);
	end;
end

--	Request client version information
--	Syntax: /nrgversion
--	Alternative: /nrg version
SLASH_NRG_VERSION1 = "/nrgversion"
SlashCmdList["NRG_VERSION"] = function(msg)
	if IsInRaid() or A:isInParty() then
		A:sendAddonMessage("TX_VERSION##");
	else
		A:echo(string.format("[%s] is using NRG version %s", A.localPlayerName, A.addonVersion));
	end
end


function A:PreInitialization()
	self.currentPowerLevel = 0;
	self.disableUpdates = true;
	NRGPowerButton:Hide();
end;

function A:PostInitialization()
	self:InitializeConfigSettings();
	self:RepositionateButton(NRGPowerButton);

	self.enabledForPlayer = NRG_ENABLED_FOR_CLASSES[self.localPlayerClass];
	if self.enabledForPlayer and self.configPowerButtonVisible then
		NRGPowerButton:Show();
	else
		NRGPowerButton:Hide();
	end;

	self.disableUpdates = false;
end;


function A:RepositionateButton(sender)
	local x, y = sender:GetLeft(), sender:GetTop() - UIParent:GetHeight();

	self:SetOption(CONFIG_KEY_PowerButtonPosX, x);
	self:SetOption(CONFIG_KEY_PowerButtonPosY, y);
	
	self:UpdatePower();
end;

function A:UpdatePower()
	NRGPowerButton:SetNormalTexture(NRG_POWERLEVELS[self.currentPowerLevel]["icon"]);
	NRGPowerButton:SetPushedTexture(NRG_POWERLEVELS[self.currentPowerLevel]["icon"]);
end;

function A:UpdatePowerButtonSize(size)
	NRGPowerButton:SetWidth(size * 16);
	NRGPowerButton:SetHeight(size * 8);
	NRGPowerButtonValue:SetFont("Fonts\\FRIZQT__.TTF", 10 + size * 3);
end;

function A:ResetPower()
	self.currentPowerLevel = 0;
	self:UpdatePower();
end;

function A:AdvancePower()
	if self.currentPowerLevel < 5 then
		self.currentPowerLevel = self.currentPowerLevel + 1;
		self:UpdatePower();
	end;
end;


--
--	Configuration functions
--
function A:GetOption(parameter, defaultValue)
	local realmname = self.localPlayerRealm;
	local playername = UnitName("player");

	-- Character level
	if NRG_Options[realmname] then
		if NRG_Options[realmname][playername] then
			if NRG_Options[realmname][playername][parameter] then
				local value = NRG_Options[realmname][playername][parameter];
				if (type(value) == "table") or not(value == "") then
					return value;
				end
			end
		end
	end
	
	return defaultValue;
end

function A:SetOption(parameter, value)
	local realmname = self.localPlayerRealm;
	local playername = UnitName("player");

	-- Character level:
	if not NRG_Options[realmname] then
		NRG_Options[realmname] = { };
	end
		
	if not NRG_Options[realmname][playername] then
		NRG_Options[realmname][playername] = { };
	end
		
	NRG_Options[realmname][playername][parameter] = value;
end

function A:InitializeConfigSettings()
	if not NRG_Options then
		NRG_Options = { };
	end

	local x,y = NRGPowerButton:GetPoint();
	self:SetOption(CONFIG_KEY_PowerButtonPosX, self:GetOption(CONFIG_KEY_PowerButtonPosX, x))
	self:SetOption(CONFIG_KEY_PowerButtonPosY, self:GetOption(CONFIG_KEY_PowerButtonPosY, y))

	local value = self:GetOption(CONFIG_KEY_PowerButtonVisible, CONFIG_DEFAULT_PowerButtonVisible);
	if type(value) == "boolean" then
		self.configPowerButtonVisible = value;
	else
		self.configPowerButtonVisible = CONFIG_DEFAULT_PowerButtonVisible;
	end;
	self:SetOption(CONFIG_KEY_PowerButtonVisible, self.configPowerButtonVisible);

	local value = self:GetOption(CONFIG_KEY_PowerButtonSize, CONFIG_DEFAULT_PowerButtonSize);
	local powerButtonSize = tonumber(value);
	if not powerButtonSize or powerButtonSize < 1 or powerButtonSize > 15 then
		powerButtonSize = CONFIG_DEFAULT_PowerButtonSize;
	end;
	self:UpdatePowerButtonSize(powerButtonSize + 1);
	self:SetOption(CONFIG_KEY_PowerButtonSize, powerButtonSize);
end;

function A:HandleTXVersion(message, sender)
	self:sendAddonMessage("RX_VERSION#".. self.addonVersion .."#"..sender);
end;

function A:HandleRXVersion(message, sender)
	self:echo(string.format("[%s] is using NRG version %s", sender, message))
end;

A.frameSkipDefault			= 4;	-- Skip every Nth frame
A.frameSkipCounter			= 0;	-- (Internal) frame counter
A.lastManaValue				= -1;	-- (Internal) last mana value
A.lastManaAlphaValue		= 0.00;	-- (Internal) last alpha value
A.manaAlphaValueDecay		= 0.05;

function A:OnTimer(elapsed)
	self.timerTick = self.timerTick + elapsed

	if A.enabledForPlayer then
		self.frameSkipCounter = self.frameSkipCounter - 1;
		if self.frameSkipCounter < 0 then
			self.frameSkipCounter = self.frameSkipDefault;
			self:CheckManaUpdates();
		end;
	end;

	if self.timerTick > (self.nextPowerStep + self.powerFrequency) then
		self:AdvancePower();
		self.nextPowerStep = self.timerTick;

		A.manaAlphaValueDecay = 1 / (GetFramerate() * 2 / A.frameSkipDefault);
	end;
end;

function A:IsEligibleForReset(unitid, spellID)
	if unitid ~= "player" then return false; end;

	return true;
end;

function A:CheckManaUpdates()
	if disableUpdates then 
		return; 
	end;

	local mana = UnitPower("player", 0);

	if mana > self.lastManaValue and self.lastManaValue >= 0 then
		NRGPowerButtonValue:SetText(mana - self.lastManaValue);
		self.lastManaAlphaValue = 1.00;
		NRGPowerButtonValue:SetAlpha(self.lastManaAlphaValue);
	else
		if self.lastManaAlphaValue > 0 then
			self.lastManaAlphaValue = self.lastManaAlphaValue - self.manaAlphaValueDecay;
			if self.lastManaAlphaValue < 0 then 
				self.lastManaAlphaValue = 0; 
			end;
			NRGPowerButtonValue:SetAlpha(self.lastManaAlphaValue);
		end;
	end;

	self.lastManaValue = mana;
end;


local NRG_ValidSubEvents = {
	["SPELL_CAST_SUCCESS"] = true,
}

function A:OnEvent(object, event, ...)

	if event == "ADDON_LOADED" then
		local addonname = ...;
		if addonname == self.addonShortName then
			self:PostInitialization();
		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subevent, _, sourceGUID, sourceName = CombatLogGetCurrentEventInfo();

		--	Only spells I did please
		if sourceGUID == self.localPlayerGUID then
--			self:echo(string.format("Subevent, event:%s", subevent or "nil"));
		
			--	Filter out unwanted heal/damage sub events.
			if NRG_ValidSubEvents[subevent] then
				--	Only react on magic stuff. SpellID is always 0 in classic :(
				local spellId, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo());
				
				if spellSchool and bit.band(spellSchool, 0x07e) > 0 then				
--					self:echo(string.format("Resetting, spell:%s, school:%s", spellName or "nil", spellSchool or "nil"));
					
					self:ResetPower();
				end;
			end;
		end;

	elseif event == "CHAT_MSG_ADDON" then
		local prefix, msg, channel, sender = ...;

		if prefix ~= self.addonPrefix then	
			return;
		end;

		--	Note: sender+recipient contains both name+realm of who sended message.
		local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	
		if not (recipient == "") then
			if not (recipient == self.localPlayerName) then
				return
			end
		end

		if cmd == "TX_VERSION" then
			self:HandleTXVersion(message, sender);
		elseif cmd == "RX_VERSION" then
			self:HandleRXVersion(message, sender);
		end;
	end;
end;

function A:OnLoad()
	self.currentVersion = self:calculateVersion(A.addonVersion);
	self:echo(string.format("Type %s/nrg%s to configure the addon, or right-click the NRG power button.", self.chatColorHot, self.chatColorNormal));

	CombatTextSetActiveUnit("player");

    NRGEventFrame:RegisterEvent("ADDON_LOADED");
    NRGEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    NRGEventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

	C_ChatInfo.RegisterAddonMessagePrefix(self.addonPrefix);

	self:PreInitialization();
end


--
--	Event wrappers
--

function NRG_OnTimer(elapsed)
	A:OnTimer(elapsed);
end;

function NRG_OnEvent(object, event, ...)
	A:OnEvent(object, event, ...);
end;

function NRG_RepositionateButton(sender)
	A:RepositionateButton(sender);
end

function NRG_OnLoad()
	A:OnLoad();
end;
