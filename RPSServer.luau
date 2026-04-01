-- RPSServer.luau
-- ServerScriptService에 Script로 넣기
-- 서버: 가위바위보 + 다이하드 뺨 (CFrame 애니메이션)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-----------------------------------------------
-- 효과음 시스템
-- Roblox 무료 사운드 에셋 사용
-----------------------------------------------
local SOUNDS = {
	slap = "rbxassetid://5765933873",  -- 찰싹/빡 때리는 소리
}

local function playSound(soundId, position, volume, pitch)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position or Vector3.new(0, 10, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMaxDistance = 200
	sound.Parent = part
	sound:Play()

	-- 재생 끝나면 정리
	task.delay(5, function()
		part:Destroy()
	end)
end

local function getOrCreate(name, className)
	local obj = ReplicatedStorage:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = ReplicatedStorage
	end
	return obj
end

local rpsChoice = getOrCreate("RPSChoice", "RemoteEvent")
local rpsResult = getOrCreate("RPSResult", "RemoteEvent")
local changeNPC = getOrCreate("ChangeNPC", "RemoteEvent")
local resetNPC = getOrCreate("ResetNPC", "RemoteEvent")

local winTable = {
	["가위"] = "보",
	["바위"] = "가위",
	["보"] = "바위",
}
local choicesList = { "가위", "바위", "보" }

-- 맵 중앙 좌표
local CENTER = Vector3.new(0, 3, 0)
local NPC_POS = CENTER + Vector3.new(0, 0, -3)
local PLAYER_POS = CENTER + Vector3.new(0, 0, 3)
local NPC_CFRAME = CFrame.lookAt(NPC_POS, PLAYER_POS)
local PLAYER_CFRAME = CFrame.lookAt(PLAYER_POS, NPC_POS)

local npcStyles = {
	["건달"]     = { userId = 261 },
	["학생"]     = { userId = 156 },
	["할아버지"] = { userId = 2407518839 },
	["로봇"]     = { userId = 4450258599 },
	["닌자"]     = { userId = 13656149 },
	["광대"]     = { userId = 1 },
}

-----------------------------------------------
-- 위치 리셋
-----------------------------------------------
local function clearPhysics(root)
	if not root then return end
	for _, obj in ipairs(root:GetChildren()) do
		if obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity") or obj:IsA("BodyPosition") then
			obj:Destroy()
		end
	end
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

local function resetPositions(playerCharacter)
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if npcRoot then
		clearPhysics(npcRoot)
		npcRoot.CFrame = NPC_CFRAME

		-- Humanoid 상태 복원
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end

	if playerCharacter then
		local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart")
		if playerRoot then
			clearPhysics(playerRoot)
			playerRoot.CFrame = PLAYER_CFRAME
		end
		local humanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

-----------------------------------------------
-- NPC 외형 변경
-----------------------------------------------
local function changeNPCAppearance(npcName)
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	local style = npcStyles[npcName]
	if not style then return end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if style.userId then
		local success, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(style.userId)
		end)
		if success and desc then
			pcall(function()
				humanoid:ApplyDescription(desc)
			end)
		end
	end

	local head = npc:FindFirstChild("Head")
	if head then
		local nameTag = head:FindFirstChild("NameTag")
		if not nameTag then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "NameTag"
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 2, 0)
			billboard.Parent = head
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Label"
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextStrokeTransparency = 0.5
			nameLabel.TextSize = 20
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Parent = billboard
			nameTag = billboard
		end
		nameTag.Label.Text = npcName
	end
end

-----------------------------------------------
-- 파티클 이펙트
-----------------------------------------------
local function createSlapEffect(position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new(Color3.fromRGB(255, 80, 30))
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 3),
		NumberSequenceKeypoint.new(1, 0),
	})
	particle.Lifetime = NumberRange.new(0.3, 0.8)
	particle.Speed = NumberRange.new(15, 30)
	particle.SpreadAngle = Vector2.new(360, 360)
	particle.Rate = 0
	particle.Parent = part
	particle:Emit(50)

	task.delay(1.5, function() part:Destroy() end)
end

-----------------------------------------------
-- 머리 위 별 빙빙 도는 이펙트 (만화적 연출)
-----------------------------------------------
local function createStarsEffect(head)
	if not head then return end

	local starsHolder = Instance.new("Part")
	starsHolder.Name = "StarsEffect"
	starsHolder.Size = Vector3.new(0.1, 0.1, 0.1)
	starsHolder.Anchored = true
	starsHolder.CanCollide = false
	starsHolder.Transparency = 1
	starsHolder.Position = head.Position + Vector3.new(0, 2.5, 0)
	starsHolder.Parent = workspace

	-- 별 3개 생성 (120도 간격으로 배치)
	local stars = {}
	local starColors = {
		Color3.fromRGB(255, 255, 0),   -- 노랑
		Color3.fromRGB(255, 150, 0),   -- 주황
		Color3.fromRGB(255, 255, 100), -- 연노랑
	}

	for i = 1, 3 do
		local star = Instance.new("Part")
		star.Name = "Star" .. i
		star.Size = Vector3.new(0.8, 0.8, 0.2)
		star.Anchored = true
		star.CanCollide = false
		star.Color = starColors[i]
		star.Material = Enum.Material.Neon
		star.Shape = Enum.PartType.Ball
		star.Parent = workspace

		-- 별 파티클 (반짝임)
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(starColors[i])
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Lifetime = NumberRange.new(0.2, 0.5)
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.Rate = 15
		sparkle.LightEmission = 1
		sparkle.Parent = star

		table.insert(stars, star)
	end

	-- 빙빙 도는 애니메이션
	local radius = 2.0
	local spinSpeed = 8  -- 빠르게 회전
	local duration = 3.0
	local startTime = tick()

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not head or not head.Parent then
			conn:Disconnect()
			for _, s in ipairs(stars) do s:Destroy() end
			starsHolder:Destroy()
			return
		end

		local elapsed = tick() - startTime
		if elapsed >= duration then
			conn:Disconnect()
			for _, s in ipairs(stars) do s:Destroy() end
			starsHolder:Destroy()
			return
		end

		-- 페이드 아웃 (마지막 1초)
		local fade = 1
		if elapsed > duration - 1.0 then
			fade = (duration - elapsed) / 1.0
		end

		local centerPos = head.Position + Vector3.new(0, 2.5, 0)
		starsHolder.Position = centerPos

		-- 위아래 출렁임
		local bobY = math.sin(elapsed * 4) * 0.3

		for i, star in ipairs(stars) do
			local angle = elapsed * spinSpeed + (i - 1) * math.rad(120)
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			star.Position = centerPos + Vector3.new(x, bobY, z)
			star.Transparency = 1 - fade
			-- 크기 맥동
			local pulse = 0.6 + 0.3 * math.sin(elapsed * 10 + i)
			star.Size = Vector3.new(pulse, pulse, 0.2)
		end
	end)
end

-----------------------------------------------
-- 목 세바퀴 회전 연출 (Neck Motor6D 활용)
-----------------------------------------------
local function spinHead(character)
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Neck Motor6D 찾기
	local neck = nil
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name == "Neck" then
			neck = desc
			break
		end
	end

	if not neck then return end

	local originalC0 = neck.C0
	local spinDuration = 0.8  -- 세 바퀴 도는 시간
	local totalSpins = 3
	local startTime = tick()

	-- 별 이펙트 시작
	createStarsEffect(head)

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not neck or not neck.Parent then
			conn:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local t = elapsed / spinDuration

		if t >= 1 then
			conn:Disconnect()
			neck.C0 = originalC0
			return
		end

		-- 이징: 처음에 빠르고 끝에 느려짐
		local eased = 1 - (1 - t) * (1 - t)
		local angle = eased * totalSpins * math.pi * 2

		-- Y축 회전 (고개가 빙글빙글)
		neck.C0 = originalC0 * CFrame.Angles(0, angle, math.sin(angle * 0.5) * math.rad(15))
	end)
end

-----------------------------------------------
-----------------------------------------------
-- 코믹 뺨 때리기 (목 세바퀴 + 별 빙빙)
-- NPC, 플레이어 공통 사용
-----------------------------------------------
local function comicSlap(character)
	if not character then return end

	local head = character:FindFirstChild("Head")
	if head then
		createSlapEffect(head.Position)
		playSound(SOUNDS.slap, head.Position, 2, 0.8)
	end

	spinHead(character)
end

-----------------------------------------------
-- 뺨 때리기 함수
-----------------------------------------------
local function slapNPC()
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	comicSlap(npc)
end

local function slapPlayer(player)
	local character = player.Character
	if not character then return end
	comicSlap(character)
end

-----------------------------------------------
-- 이벤트
-----------------------------------------------
changeNPC.OnServerEvent:Connect(function(player, npcName)
	if npcStyles[npcName] then
		resetPositions(player.Character)
		changeNPCAppearance(npcName)
	end
end)

resetNPC.OnServerEvent:Connect(function(player)
	resetPositions(player.Character)
end)

rpsChoice.OnServerEvent:Connect(function(player, playerChoice)
	if playerChoice ~= "가위" and playerChoice ~= "바위" and playerChoice ~= "보" then
		return
	end

	local npcChoice = choicesList[math.random(1, 3)]
	local outcome

	if playerChoice == npcChoice then
		outcome = "draw"
	elseif winTable[playerChoice] == npcChoice then
		outcome = "win"
		slapNPC()
	else
		outcome = "lose"
		slapPlayer(player)
	end

	rpsResult:FireClient(player, {
		outcome = outcome,
		npcChoice = npcChoice,
		playerChoice = playerChoice,
	})
end)

print("[RPS] 가위바위보 서버 로드 완료!")
