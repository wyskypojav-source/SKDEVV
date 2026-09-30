--[[
	Universal Aimbot Module Refactored
	Original by Exunys © CC0 1.0 Universal (2023)
	Optimized for Performance, Stability and Security.
]]

--// Luraph Macros
if LPH_OBFUSCATED == nil then
	LPH_NO_VIRTUALIZE = function(...)
		return ...
	end
end

--// Cache
local game, workspace = game, workspace
local getrawmetatable, pcall, next, os_clock, getgenv = getrawmetatable, pcall, next, os.clock, getgenv
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing and Drawing.new, TweenInfo.new
local mousemoverel, mousemoveabs, tablefind, tableremove, stringlower, stringsub, mathclamp = mousemoverel or (Input and Input.MouseMove), mousemoveabs, table.find, table.remove, string.lower, string.sub, math.clamp
local mouse1press, mouse1release, taskwait = mouse1press, mouse1release, task.wait
local clonefunction, cloneref = clonefunction or LPH_NO_VIRTUALIZE(function(...) return ... end), cloneref or LPH_NO_VIRTUALIZE(function(...) return ... end)

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = LPH_NO_VIRTUALIZE(function(self, Index) return self[Index] end),
	__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value) self[Index] = Value end)
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex
local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local _GetService = __index(game, "GetService")
local GetService = function(Service)
	return cloneref(_GetService(game, Service))
end

--// Services
local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local Players = GetService("Players")

--// Dynamic Getters (Fixes Problem 1 & 5)
local function GetLocalPlayer() return __index(Players, "LocalPlayer") end
local function GetCamera() return __index(workspace, "CurrentCamera") end
local function GetPlayersList() return GetPlayers(Players) end
local function GetMouse() return GetLocalPlayer() and __index(GetLocalPlayer(), "GetMouse")(GetLocalPlayer()) end

--// Service Methods Cache
local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")
local GetPlayerFromCharacter = __index(Players, "GetPlayerFromCharacter")

--// Variables (Fixes Problem 2)
local RequiredDistance, Required3DDistance = 2000, 10000
local Typing, Running = false, false
local ServiceConnections = {}
local Animation = nil
local OriginalSensitivity = nil

local Connect, Disconnect = __index(game, "DescendantAdded").Connect
do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

--// Environment
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1,
		DisableWarnings = false
	},

	Settings = {
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		OffsetToMoveDirection = false,
		OffsetIncrement = 15,
		Sensitivity = 0,
		Sensitivity2 = 1,
		LockMode = 1,
		LockPart = "Head",
		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false
	},

	Triggerbot = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		AimLockedCheck = false,
		Delay = 0
	},

	ClosestPlayerTracer = {
		Enabled = true,
		Position = 3,
		Transparency = 0.5,
		Thickness = 1,
		RainbowColor = false,
		Color = Color3fromRGB(150, 150, 255)
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Radius = 180,
		NumSides = 60,
		Thickness = 1,
		Transparency = 1,
		Filled = false,
		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle"),
	Tracer = Drawingnew("Line")
}

local Environment, _warn = getgenv().ExunysDeveloperAimbot, clonefunction(warn)
warn = function(...) return not Environment.DeveloperSettings.DisableWarnings and _warn(...) end

repeat taskwait(0) until Environment and Environment.FOVCircle and Environment.FOVCircleOutline

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Helpers (Fixes Problem 3, 9, 12)
local function ApplyDrawingProps(drawing, tbl, skipKeys)
	for Index, Value in next, tbl do
		if skipKeys and skipKeys[Index] then continue end
		if pcall(getrenderproperty, drawing, Index) then
			setrenderproperty(drawing, Index, Value)
		end
	end
end

local FixUsername = LPH_NO_VIRTUALIZE(function(String)
	for _, Value in next, GetPlayersList() do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then return Name end
	end
end)

local GetRainbowColor = LPH_NO_VIRTUALIZE(function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(os_clock() % RainbowSpeed / RainbowSpeed, 1, 1)
end)

local ConvertVector = LPH_NO_VIRTUALIZE(function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end)

local CancelLock = LPH_NO_VIRTUALIZE(function()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	if OriginalSensitivity then
		__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	end
	if Animation then Animation:Cancel(); Animation = nil end
	setrenderproperty(Environment.Tracer, "Visible", Environment.ClosestPlayerTracer.Enabled)
end)

--// Optimized Core (Fixes Problem 4, 8, 15)
local function GetClosestPlayer(Aux)
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart
	local LocalPlayer = GetLocalPlayer()
	local Camera = GetCamera()
	if not Camera or not LocalPlayer then return end

	if Environment.Locked and not Aux then
		local lockedChar = __index(Environment.Locked, "Character")
		if not lockedChar or not lockedChar[LockPart] then
			CancelLock()
			return
		end
		local worldPos = __index(lockedChar[LockPart], "Position")
		local screenPos = ConvertVector(__index(Camera, "WorldToViewportPoint")(Camera, worldPos))
		if (GetMouseLocation(UserInputService) - screenPos).Magnitude > RequiredDistance then
			CancelLock()
		end
		return
	end

	RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
	Required3DDistance = 10000

	local mouseLoc = GetMouseLocation(UserInputService)
	local cameraCFrame = Camera.CFrame
	local teamCheckOption = Environment.DeveloperSettings.TeamCheckOption
	local players = GetPlayersList()

	local blacklist = nil
	if Settings.WallCheck then
		blacklist = { LocalPlayer.Character, Camera }
		for _, p in next, players do
			if p.Character then table.insert(blacklist, p.Character) end
		end
	end

	for _, Value in next, players do
		if Value == LocalPlayer then continue end
		local Character = __index(Value, "Character")
		if not Character then continue end
		local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
		local TargetPart = FindFirstChild(Character, LockPart)

		if TargetPart and Humanoid and not tablefind(Environment.Blacklisted, __index(Value, "Name")) then
			if Settings.TeamCheck and __index(Value, teamCheckOption) == __index(LocalPlayer, teamCheckOption) then continue end
			if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then continue end

			local partPos = TargetPart.Position
			if Settings.WallCheck then
				if #__index(Camera, "GetPartsObscuringTarget")(Camera, {partPos}, blacklist) > 0 then continue end
			end

			local viewport, onScreen = __index(Camera, "WorldToViewportPoint")(Camera, partPos)
			if onScreen and viewport.Z > 0 then
				local screenVec = ConvertVector(viewport)
				local dist = (mouseLoc - screenVec).Magnitude
				local dist3D = (cameraCFrame.Position - partPos).Magnitude

				if dist < RequiredDistance and dist3D < Required3DDistance then
					RequiredDistance, Required3DDistance = dist, dist3D
					if not Aux then
						Environment.Locked = Value
					elseif not Running and not Environment.Locked then
						return Value
					end
				end
			end
		end
	end
end

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	local Settings, Triggerbot, Tracer, FOVCircle, FOVCircleOutline = Environment.Settings, Environment.Triggerbot, Environment.Tracer, Environment.FOVCircle, Environment.FOVCircleOutline
	local TracerSettings, FOVSettings = Environment.ClosestPlayerTracer, Environment.FOVSettings
	local UpdateMode = Environment.DeveloperSettings.UpdateMode
	local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption

	-- Triggerbot
	if mouse1press and mouse1release then
		ServiceConnections.Triggerbot = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
			if not Triggerbot.Enabled then return end
			local mouse = GetMouse()
			if not mouse or not mouse.Target then return end
			
			local Character = mouse.Target.Parent
			local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
			local Player = GetPlayerFromCharacter(Players, Character)

			if Character and Humanoid and Player then
				if Triggerbot.TeamCheck and __index(Player, TeamCheckOption) == __index(GetLocalPlayer(), TeamCheckOption) then return end
				if Triggerbot.AliveCheck and __index(Humanoid, "Health") <= 0 then return end
				if Triggerbot.AimLockedCheck and not Environment.Locked then return end
				if Triggerbot.Delay ~= 0 then taskwait(Triggerbot.Delay) end
				mouse1press(); taskwait(0); mouse1release()
			end
		end))
	end

	-- Unified Render Loop (Fixes Problem 8, 10)
	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		if Typing then return end
		
		local Camera = GetCamera()
		if not Camera then return end
		local mouseLoc = GetMouseLocation(UserInputService)

		-- FOV Rendering
		if FOVSettings.Enabled and Settings.Enabled then
			ApplyDrawingProps(FOVCircle, FOVSettings, {Color = true})
			ApplyDrawingProps(FOVCircleOutline, FOVSettings, {Color = true})
			
			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or (FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color))
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)
			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", mouseLoc)
			setrenderproperty(FOVCircleOutline, "Position", mouseLoc)
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		-- Tracer Rendering
		local closest = TracerSettings.Enabled and Settings.Enabled and GetClosestPlayer(true)
		if closest then
			setrenderproperty(Tracer, "Visible", true)
			ApplyDrawingProps(Tracer, TracerSettings, {Color = true, From = true, To = true})
			setrenderproperty(Tracer, "Color", TracerSettings.RainbowColor and GetRainbowColor() or TracerSettings.Color)
			
			local viewportSize = Camera.ViewportSize
			if TracerSettings.Position == 1 then
				setrenderproperty(Tracer, "From", Vector2new(viewportSize.X / 2, viewportSize.Y))
			elseif TracerSettings.Position == 2 then
				setrenderproperty(Tracer, "From", viewportSize / 2)
			else
				setrenderproperty(Tracer, "From", mouseLoc)
			end
			
			local targetPos = __index(__index(closest, "Character")[Settings.LockPart], "Position")
			setrenderproperty(Tracer, "To", ConvertVector(__index(Camera, "WorldToViewportPoint")(Camera, targetPos)))
		else
			setrenderproperty(Tracer, "Visible", false)
		end

		-- Aimbot Logic
		if Running and Settings.Enabled then
			GetClosestPlayer()
			if Environment.Locked then
				local lockedChar = __index(Environment.Locked, "Character")
				local humanoid = FindFirstChildOfClass(lockedChar, "Humanoid")
				local offset = (Settings.OffsetToMoveDirection and humanoid) and (__index(humanoid, "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10)) or Vector3zero
				
				local targetPos = __index(lockedChar[Settings.LockPart], "Position") + offset
				local lockedViewport = __index(Camera, "WorldToViewportPoint")(Camera, targetPos)

				if Settings.LockMode == 2 then
					mousemoverel((lockedViewport.X - mouseLoc.X) / Settings.Sensitivity2, (lockedViewport.Y - mouseLoc.Y) / Settings.Sensitivity2)
				elseif Settings.LockMode == 3 and mousemoveabs then
					mousemoveabs(lockedViewport.X, lockedViewport.Y)
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, targetPos)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, targetPos))
					end
					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end
				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
				setrenderproperty(Tracer, "Visible", false)
			end
		end
	end))

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		local TriggerKey, Toggle = Settings.TriggerKey, Settings.Toggle
		if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == TriggerKey) or Input.UserInputType == TriggerKey then
			if Toggle then
				Running = not Running
				if not Running then CancelLock() end
			else
				Running = true
			end
		end
	end))

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Settings.TriggerKey) or Input.UserInputType == Settings.TriggerKey then
			Running = false; CancelLock()
		end
	end))
end

--// Typing Check
ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function() Typing = true end)
ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function() Typing = false end)

--// Interactive User Methods
repeat taskwait(0) until Environment and Load

Environment.Exit = LPH_NO_VIRTUALIZE(function(self)
	assert(self, "Missing parameter #1 \"self\"")
	for Index, _ in next, ServiceConnections do pcall(Disconnect, ServiceConnections[Index]) end
	CancelLock()
	self.FOVCircle:Remove(); self.FOVCircleOutline:Remove(); self.Tracer:Remove()
	getgenv().ExunysDeveloperAimbot = nil; pcall(collectgarbage, "step", 200)
end)

Environment.Restart = LPH_NO_VIRTUALIZE(function()
	for Index, _ in next, ServiceConnections do pcall(Disconnect, ServiceConnections[Index]) end
	CancelLock()
	Load()
end)

Environment.Blacklist = LPH_NO_VIRTUALIZE(function(self, Username)
	assert(self, "Missing parameter #1")
	assert(Username, "Missing parameter #2")
	Username = FixUsername(Username)
	if Username then self.Blacklisted[#self.Blacklisted + 1] = Username end
end)

Environment.Whitelist = LPH_NO_VIRTUALIZE(function(self, Username)
	assert(self, "Missing parameter #1")
	assert(Username, "Missing parameter #2")
	Username = FixUsername(Username)
	if Username then
		local Index = tablefind(self.Blacklisted, Username)
		if Index then tableremove(self.Blacklisted, Index) end
	end
end)

Environment.GetClosestPlayer = LPH_NO_VIRTUALIZE(function() return GetClosestPlayer(true) end)
Environment.Load = Load
setmetatable(Environment, {__call = Load})

return Environment
