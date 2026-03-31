-- RPSServer.luau
-- ServerScriptService에 Script로 넣기
-- 서버: 가위바위보 + 다이하드 뺨 (CFrame 애니메이션)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

local function createLandingEffect(position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(Color3.fromRGB(180, 160, 130))
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 6),
		NumberSequenceKeypoint.new(1, 0),
	})
	dust.Lifetime = NumberRange.new(0.5, 1.2)
	dust.Speed = NumberRange.new(10, 30)
	dust.SpreadAngle = Vector2.new(360, 30)
	dust.Rate = 0
	dust.Parent = part
	dust:Emit(60)

	task.delay(2, function() part:Destroy() end)
end

-----------------------------------------------
-- 다이하드식 뺨 때리기 (CFrame 직접 제어)
-- Humanoid를 PlatformStand로 만들어서 물리 간섭 제거
-- CFrame으로 직접 위치/회전 애니메이션
-----------------------------------------------
local function dieHardSlap(character)
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	-- Humanoid가 움직임을 방해하지 않도록
	if humanoid then
		humanoid.PlatformStand = true
	end

	-- 시작 위치 기록
	local startPos = root.Position
	local startCF = root.CFrame
	local sideDir = startCF.RightVector
	local backDir = startCF.LookVector * -1

	-- 머리에 파티클
	local head = character:FindFirstChild("Head")
	if head then
		createSlapEffect(head.Position)
	end

	-- 애니메이션 키프레임 정의
	-- {시간, 위치오프셋, 회전각도(X,Y,Z)}
	local totalDuration = 3.0
	local peakHeight = 60  -- 올라가는 높이

	local startTime = tick()

	-- Heartbeat로 매 프레임 위치 업데이트
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local t = elapsed / totalDuration -- 0~1 진행도

		if t >= 1 then
			-- 애니메이션 끝: 바닥에 착지
			connection:Disconnect()
			local landPos = startPos + sideDir * 15 + backDir * 8
			landPos = Vector3.new(landPos.X, startPos.Y, landPos.Z) -- 원래 높이로
			root.CFrame = CFrame.new(landPos) * CFrame.Angles(math.rad(-80), 0, math.rad(30))
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

			-- 착지 이펙트
			createLandingEffect(landPos)
			return
		end

		-- 수평 이동 (옆 + 뒤로)
		local horizProgress = t  -- 선형
		local horizOffset = sideDir * 15 * horizProgress + backDir * 8 * horizProgress

		-- 수직 이동 (포물선: 올라갔다 내려옴)
		local verticalT
		local height

		if t < 0.15 then
			-- 1단계 (0~15%): 빡! 맞고 살짝 위로
			verticalT = t / 0.15
			height = 5 * verticalT
		elseif t < 0.45 then
			-- 2단계 (15~45%): 하늘로 쭈욱 올라감
			verticalT = (t - 0.15) / 0.30
			height = 5 + (peakHeight - 5) * verticalT
		elseif t < 0.60 then
			-- 3단계 (45~60%): 꼭대기에서 체공 (거의 안 움직임)
			verticalT = (t - 0.45) / 0.15
			height = peakHeight - 2 * verticalT  -- 아주 살짝만 내려옴
		else
			-- 4단계 (60~100%): 아래로 쿵!!! 추락
			verticalT = (t - 0.60) / 0.40
			-- 가속 추락 (제곱 커브)
			height = (peakHeight - 2) * (1 - verticalT * verticalT)
		end

		-- 회전 (빙글빙글)
		local rotX, rotY, rotZ
		if t < 0.15 then
			-- 빡! 맞는 순간: 머리가 확 꺾임
			rotX = math.rad(30) * (t / 0.15)
			rotY = math.rad(90) * (t / 0.15)
			rotZ = math.rad(20) * (t / 0.15)
		elseif t < 0.45 then
			-- 올라가면서 회전
			local rt = (t - 0.15) / 0.30
			rotX = math.rad(30) + math.rad(360) * rt
			rotY = math.rad(90) + math.rad(180) * rt
			rotZ = math.rad(20) + math.rad(200) * rt
		elseif t < 0.60 then
			-- 체공: 천천히 회전
			local rt = (t - 0.45) / 0.15
			rotX = math.rad(390) + math.rad(30) * rt
			rotY = math.rad(270) + math.rad(20) * rt
			rotZ = math.rad(220) + math.rad(10) * rt
		else
			-- 추락: 빠르게 회전
			local rt = (t - 0.60) / 0.40
			rotX = math.rad(420) + math.rad(540) * rt
			rotY = math.rad(290) + math.rad(360) * rt
			rotZ = math.rad(230) + math.rad(400) * rt
		end

		local newPos = startPos + horizOffset + Vector3.new(0, height, 0)
		root.CFrame = CFrame.new(newPos) * CFrame.Angles(rotX, rotY, rotZ)
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end)
end

-----------------------------------------------
-- 뺨 때리기 함수
-----------------------------------------------
local function slapNPC()
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	dieHardSlap(npc)
end

-----------------------------------------------
-- 플레이어가 맞을 때: 제자리에서 머리 꺾임 → 무릎 꿇기
-- (거의 안 움직임, 카메라 밖으로 안 나감)
-----------------------------------------------
local function slapPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(10)
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local head = character:FindFirstChild("Head")
	if head then
		createSlapEffect(head.Position)
	end

	if humanoid then
		humanoid.PlatformStand = true
	end

	local startCF = root.CFrame
	local startPos = startCF.Position
	-- 시작 회전값 보존 (Y축 = 바라보는 방향)
	local _, startRotY, _ = startCF:ToEulerAnglesYXZ()
	local totalDuration = 1.2
	local startTime = tick()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not root or not root.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local t = elapsed / totalDuration

		if t >= 1 then
			-- 무릎 꿇은 상태로 끝 (제자리)
			connection:Disconnect()
			root.CFrame = CFrame.new(startPos.X, startPos.Y - 1, startPos.Z)
				* CFrame.Angles(0, startRotY, 0)
				* CFrame.Angles(math.rad(15), 0, math.rad(10))
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			return
		end

		local posY = startPos.Y
		local rotX = 0
		local rotZ = 0

		if t < 0.15 then
			-- 빡! 맞는 순간: 머리가 옆으로 확 꺾임 (제자리)
			local p = t / 0.15
			rotX = 0
			rotZ = math.rad(25) * p  -- 옆으로 확 기울어짐
		elseif t < 0.4 then
			-- 충격으로 살짝 흔들림
			local p = (t - 0.15) / 0.25
			rotZ = math.rad(25) - math.rad(35) * p  -- 반대쪽으로 흔들
		elseif t < 0.7 then
			-- 비틀거림
			local p = (t - 0.4) / 0.3
			rotZ = math.rad(-10) + math.rad(15) * p
			rotX = math.rad(10) * p
			posY = startPos.Y - 0.3 * p  -- 살짝 내려감
		else
			-- 무릎 꿇기
			local p = (t - 0.7) / 0.3
			rotZ = math.rad(5) + math.rad(5) * p
			rotX = math.rad(10) + math.rad(5) * p
			posY = startPos.Y - 0.3 - 0.7 * p  -- 내려앉음
		end

		root.CFrame = CFrame.new(startPos.X, posY, startPos.Z)
			* CFrame.Angles(0, startRotY, 0)
			* CFrame.Angles(rotX, 0, rotZ)
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end)
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
