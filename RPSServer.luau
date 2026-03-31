-- RPSServer.luau
-- ServerScriptService에 Script로 넣기
-- 서버 측 가위바위보 판정 + 뺨때리기 + 캐릭터 변경

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent 생성 (없으면 자동 생성)
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

-- 가위바위보 판정표
local winTable = {
	["가위"] = "보",
	["바위"] = "가위",
	["보"] = "바위",
}

local choicesList = { "가위", "바위", "보" }

-- NPC 캐릭터별 설정
-- userId: 로블록스 유저 ID (아바타를 가져옴)
-- 원하는 로블록스 유저의 프로필 URL에서 숫자를 복사하면 됨
-- 예: roblox.com/users/1234567/profile → userId = 1234567
local npcStyles = {
	["건달"]     = { userId = 261,        bodyColor = BrickColor.new("Bright red") },
	["학생"]     = { userId = 156,        bodyColor = BrickColor.new("Bright blue") },
	["할아버지"] = { userId = 2407518839, bodyColor = BrickColor.new("Brown") },
	["로봇"]     = { userId = 4450258599, bodyColor = BrickColor.new("Medium stone grey") },
	["닌자"]     = { userId = 13656149,   bodyColor = BrickColor.new("Black") },
	["광대"]     = { userId = 1,          bodyColor = BrickColor.new("Bright orange") },
}

-----------------------------------------------
-- NPC 외형 변경 (로블록스 아바타 로드)
-----------------------------------------------
local function changeNPCAppearance(npcName)
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local style = npcStyles[npcName]
	if not style then return end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- 로블록스 유저 아바타 불러오기
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

	-- 머리 위 이름 표시
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
-- 뺨 때리기 효과
-----------------------------------------------
local function slapNPC()
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local torso = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("UpperTorso") or npc:FindFirstChild("Torso")
	if torso then
		local pushDirection = torso.CFrame.LookVector * -1
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = pushDirection * 8 + Vector3.new(0, 3, 0)
		bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
		bodyVelocity.Parent = torso

		task.delay(0.3, function()
			bodyVelocity:Destroy()
		end)
	end
end

local function slapPlayer(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(10)
	end

	local torso = character:FindFirstChild("HumanoidRootPart")
	if torso then
		local pushDirection = torso.CFrame.LookVector * -1
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = pushDirection * 8 + Vector3.new(0, 3, 0)
		bodyVelocity.MaxForce = Vector3.new(2000, 2000, 2000)
		bodyVelocity.Parent = torso

		task.delay(0.3, function()
			bodyVelocity:Destroy()
		end)
	end
end

-----------------------------------------------
-- 이벤트 처리
-----------------------------------------------

-- 캐릭터 변경 요청
changeNPC.OnServerEvent:Connect(function(player, npcName)
	if npcStyles[npcName] then
		changeNPCAppearance(npcName)
	end
end)

-- 가위바위보 선택
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

print("[RPS] 가위바위보 서버 스크립트 로드 완료!")
