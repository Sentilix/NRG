--[[
Author:			Mimma @ <EU-Pyrewood Village>
Create Date:	2022-06-25

The source code can be found at Github:
https://github.com/Sentilix/nrg

A small and simple addon to display mp5 cooldown.

Please see the ReadMe.txt for addon details.
]]


local addonMetadata = {
	["ADDONNAME"]		= "NRG",
	["SHORTNAME"]		= "NRG",
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
local CONFIG_KEY_PowerButtonVisible = "PowerButton.Visible";


local CONFIG_DEFAULT_PowerButtonVisible = true;

A.options = { };
A.currentVersion = 0;
A.currentPowerLevel = 0;

--	Timer settings:
A.timerTick = 0;
A.nextPowerStep = 0;
A.powerFrequency = 1.00;


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
		SlashCmdList["NRG_CONFIG"]();
	elseif option == "SHOW" then
		SlashCmdList["NRG_SHOW"]();
	elseif option == "HIDE" then
		SlashCmdList["NRG_HIDE"]();
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


function A:MainInitialization()
	self.currentPowerLevel = 0;
	self:InitializeConfigSettings();
	self:RepositionateButton(NRGPowerButton);

	if NRG_ENABLED_FOR_CLASSES[self.localPlayerClass] and A.configPowerButtonVisible then
		NRGPowerButton:Show();
	else
		NRGPowerButton:Hide();
	end;
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
	if self.options[self.localPlayerRealm] then
		if self.options[self.localPlayerRealm][self.localPlayerName] then
			if self.options[self.localPlayerRealm][self.localPlayerName][parameter] then
				local value = self.options[self.localPlayerRealm][self.localPlayerName][parameter];
				if (type(value) == "table") or not(value == "") then
					return value;
				end
			end		
		end
	end
	
	return defaultValue;
end

function A:SetOption(parameter, value)
	if not self.options[self.localPlayerRealm] then
		self.options[self.localPlayerRealm] = { };
	end
		
	if not self.options[self.localPlayerRealm][self.localPlayerName] then
		self.options[self.localPlayerRealm][self.localPlayerName] = { };
	end
		
	self.options[self.localPlayerRealm][self.localPlayerName][parameter] = value;
end

function A:InitializeConfigSettings()
	if not self.options then
		self.options = { };
	end

	local x,y = NRGPowerButton:GetPoint();
	self:SetOption(CONFIG_KEY_PowerButtonPosX, Buffalo_GetOption(CONFIG_KEY_PowerButtonPosX, x))
	self:SetOption(CONFIG_KEY_PowerButtonPosY, Buffalo_GetOption(CONFIG_KEY_PowerButtonPosY, y))

	local value = self:GetOption(CONFIG_KEY_PowerButtonVisible, CONFIG_DEFAULT_PowerButtonVisible);
	if type(value) == "boolean" then
		A.configPowerButtonVisible = value;
	else
		A.configPowerButtonVisible = CONFIG_DEFAULT_PowerButtonVisible;
	end;
	self:SetOption(CONFIG_KEY_PowerButtonVisible, A.configPowerButtonVisible);
end;

function A:HandleTXVersion(message, sender)
	self:sendAddonMessage("RX_VERSION#".. self.addonVersion .."#"..sender);
end;

function A:HandleRXVersion(message, sender)
	self:echo(string.format("[%s] is using NRG version %s", sender, message))
end;


function A:OnTimer(elapsed)
	self.timerTick = self.timerTick + elapsed

	if self.timerTick > (self.nextPowerStep + self.powerFrequency) then
		self:AdvancePower();
		self.nextPowerStep = self.timerTick;
	end;
end;

function A:OnEvent(object, event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		self:ResetPower();

	--elseif event == "UNIT_SPELLCAST_SENT" then
	--elseif event == "UNIT_SPELLCAST_START" then
	--elseif event == "UNIT_SPELLCAST_STOP" then
	--elseif event == "UNIT_SPELLCAST_FAILED" then

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

    NRGEventFrame:RegisterEvent("CHAT_MSG_ADDON");
    --NRGEventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
    --NRGEventFrame:RegisterEvent("UNIT_SPELLCAST_START");
    --NRGEventFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
    --NRGEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
    NRGEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");

	C_ChatInfo.RegisterAddonMessagePrefix(self.addonPrefix);

	self:MainInitialization();
end


--
--	Event wrappers
--

function NRG_OnTimer(elapsed)
	A:OnTimer(elapsed);
end;

function NRG_OnEvent(self, event, ...)
	A:OnEvent(self, event, ...);
end;

function NRG_RepositionateButton(sender)
	A:RepositionateButton(sender);
end

function NRG_OnLoad()
	A:OnLoad();
end;
