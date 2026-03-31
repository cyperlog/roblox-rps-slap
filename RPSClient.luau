-- RPSClient.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- 클라이언트 측 게임 로직 (UI 조작 + 서버 통신 + 카메라 연출)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screenGui = script.Parent

-- RemoteEvent 참조
local rpsChoice = ReplicatedStorage:WaitForChild("RPSChoice")
local rpsResult = ReplicatedStorage:WaitForChild("RPSResult")

-- UI 요소 참조
local frame = screenGui:WaitForChild("RPSFrame")
local title = frame:WaitForChild("Title")
local result = frame:WaitForChild("Result")
local buttons = frame:WaitForChild("Buttons")
local scoreLabel = screenGui:WaitForChild("Score")
local charSelect = screenGui:WaitForChild("CharSelect")

local canChoose = false
local streak = 0
local inGame = false
local originalCameraType = nil

-----------------------------------------------
-- 카메라: 옆에서 비추기 (양쪽 얼굴 보이게)
-----------------------------------------------
local function setSideCamera()
	local character = player.Character
	if not character then return end
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not playerRoot or not npcRoot then return end

	-- 두 캐릭터의 중간 지점
	local midPoint = (playerRoot.Position + npcRoot.Position) / 2

	-- 두 캐릭터를 잇는 방향 (플레이어 → NPC)
	local direction = (npcRoot.Position - playerRoot.Position).Unit

	-- 옆 방향 (오른쪽으로 카메라 배치)
	local sideDirection = direction:Cross(Vector3.new(0, 1, 0)).Unit

	-- 카메라 위치: 중간 지점에서 옆으로 + 약간 위로
	local cameraPos = midPoint + sideDirection * 10 + Vector3.new(0, 3, 0)

	-- 카메라 설정
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = CFrame.lookAt(cameraPos, midPoint + Vector3.new(0, 1, 0))
	})
	tween:Play()
end

-- 카메라 원래대로
local function resetCamera()
	camera.CameraType = Enum.CameraType.Custom
end

-----------------------------------------------
-- 플레이어와 NPC 서로 마주보게 하기
-----------------------------------------------
local function faceEachOther()
	local character = player.Character
	if not character then return end
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not playerRoot or not npcRoot then return end

	-- NPC가 플레이어를 바라보게
	local npcLookAt = Vector3.new(playerRoot.Position.X, npcRoot.Position.Y, playerRoot.Position.Z)
	npcRoot.CFrame = CFrame.lookAt(npcRoot.Position, npcLookAt)

	-- 플레이어가 NPC를 바라보게
	local playerLookAt = Vector3.new(npcRoot.Position.X, playerRoot.Position.Y, npcRoot.Position.Z)
	playerRoot.CFrame = CFrame.lookAt(playerRoot.Position, playerLookAt)
end

-----------------------------------------------
-- 캐릭터 선택 시스템
-----------------------------------------------
local selectedNPCName = nil

-- 캐릭터 선택 버튼 클릭
for _, btn in ipairs(charSelect:WaitForChild("CharList"):GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			-- 선택 표시
			for _, other in ipairs(charSelect.CharList:GetChildren()) do
				if other:IsA("TextButton") then
					other.BorderSizePixel = 0
				end
			end
			btn.BorderSizePixel = 3
			btn.BorderColor3 = Color3.fromRGB(255, 255, 50)
			selectedNPCName = btn.Name
		end)
	end
end

-- 시작 버튼
charSelect:WaitForChild("StartBtn").MouseButton1Click:Connect(function()
	if not selectedNPCName then return end
	charSelect.Visible = false

	-- 서버에 캐릭터 선택 알려주기
	local changeNPC = ReplicatedStorage:WaitForChild("ChangeNPC")
	changeNPC:FireServer(selectedNPCName)

	-- 잠시 대기 후 게임 시작
	task.wait(1)
	inGame = true
	faceEachOther()
	setSideCamera()
	task.wait(0.5)
	startRound()
end)

-----------------------------------------------
-- 게임 라운드
-----------------------------------------------
function startRound()
	frame.Visible = true
	result.Text = "선택하세요!"
	title.Text = "가위 바위 보!"
	canChoose = true

	for _, btn in ipairs(buttons:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundTransparency = 0
		end
	end
end

local function disableButtons()
	canChoose = false
	for _, btn in ipairs(buttons:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundTransparency = 0.5
		end
	end
end

-- 버튼 클릭
for _, btn in ipairs(buttons:GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
			if not canChoose then return end
			disableButtons()
			result.Text = btn.Name .. " 선택!"
			rpsChoice:FireServer(btn.Name)
		end)
	end
end

-- 서버 결과 수신
rpsResult.OnClientEvent:Connect(function(data)
	local outcome = data.outcome
	local npcChoice = data.npcChoice
	local playerChoice = data.playerChoice

	if outcome == "draw" then
		result.Text = "비겼다! (둘 다 " .. npcChoice .. ") 다시!"
		title.Text = "다시!"
		task.wait(1.5)
		startRound()

	elseif outcome == "win" then
		streak = streak + 1
		scoreLabel.Text = "연승: " .. streak
		result.Text = playerChoice .. " vs " .. npcChoice .. " → 이겼다!"
		title.Text = "찰싹! 뺨을 때렸다!"

		task.wait(2.5)
		-- 다음 상대: 캐릭터 선택 화면으로
		frame.Visible = false
		resetCamera()
		title.Text = "다음 상대를 고르세요!"
		result.Text = ""
		charSelect.Visible = true

	elseif outcome == "lose" then
		result.Text = playerChoice .. " vs " .. npcChoice .. " → 졌다!"
		title.Text = "찰싹 맞았다... 게임 오버!"
		scoreLabel.Text = "최종 연승: " .. streak

		task.wait(3)
		streak = 0
		scoreLabel.Text = "연승: 0"
		frame.Visible = false
		resetCamera()
		charSelect.Visible = true
	end
end)

-----------------------------------------------
-- 처음 시작: 캐릭터 선택 화면 표시
-----------------------------------------------
charSelect.Visible = true
frame.Visible = false
