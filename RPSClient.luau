-- RPSClient.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- 클라이언트: UI + 카메라 연출 + 타격감

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screenGui = script.Parent

-- RemoteEvent
local rpsChoice = ReplicatedStorage:WaitForChild("RPSChoice")
local rpsResult = ReplicatedStorage:WaitForChild("RPSResult")

-- UI 요소
local frame = screenGui:WaitForChild("RPSFrame")
local title = frame:WaitForChild("Title")
local result = frame:WaitForChild("Result")
local buttons = frame:WaitForChild("Buttons")
local scoreLabel = screenGui:WaitForChild("Score")
local charSelect = screenGui:WaitForChild("CharSelect")
local streakPopup = screenGui:WaitForChild("StreakPopup")

local canChoose = false
local streak = 0
local inGame = false

-----------------------------------------------
-- 화면 흔들기 (타격감 핵심)
-----------------------------------------------
local shaking = false

local function shakeCamera(intensity, duration)
	shaking = true
	local startTime = tick()
	local originalCFrame = camera.CFrame

	while tick() - startTime < duration do
		local elapsed = tick() - startTime
		-- 점점 줄어드는 흔들림
		local decay = 1 - (elapsed / duration)
		local shakeX = (math.random() - 0.5) * 2 * intensity * decay
		local shakeY = (math.random() - 0.5) * 2 * intensity * decay
		camera.CFrame = camera.CFrame * CFrame.new(shakeX, shakeY, 0)
		task.wait()
	end
	shaking = false
end

-----------------------------------------------
-- 화면 번쩍임 (히트 플래시)
-----------------------------------------------
local function hitFlash(color)
	local flash = screenGui:FindFirstChild("HitFlash")
	if not flash then
		flash = Instance.new("Frame")
		flash.Name = "HitFlash"
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.Position = UDim2.new(0, 0, 0, 0)
		flash.BorderSizePixel = 0
		flash.ZIndex = 100
		flash.Parent = screenGui
	end
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.3
	flash.Visible = true

	local tween = TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		flash.Visible = false
	end)
end

-----------------------------------------------
-- 슬로모션 (때리기 직전 + 직후)
-----------------------------------------------
local function slowMotion(slowDuration, slowFactor)
	-- 살짝 느려짐
	workspace:SetAttribute("TimeScale", slowFactor)

	-- ColorCorrection으로 임팩트 느낌
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.3
	cc.Saturation = 0.5
	cc.TintColor = Color3.fromRGB(255, 220, 200)
	cc.Parent = Lighting

	task.wait(slowDuration)

	-- 원래 속도로 복귀
	workspace:SetAttribute("TimeScale", 1)

	local fadeTween = TweenService:Create(cc, TweenInfo.new(0.3), {
		Contrast = 0,
		Saturation = 0,
	})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		cc:Destroy()
	end)
end

-----------------------------------------------
-- 카메라 줌인 (때리는 순간)
-----------------------------------------------
local function impactZoom()
	local currentCF = camera.CFrame
	local lookDir = currentCF.LookVector

	-- 줌인
	local zoomIn = TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = currentCF + lookDir * 2
	})
	zoomIn:Play()
	zoomIn.Completed:Connect(function()
		-- 줌아웃 (원래로)
		local zoomOut = TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = currentCF
		})
		zoomOut:Play()
	end)
end

-----------------------------------------------
-- 다이하드 카메라: NPC가 날아가는 걸 따라감
-----------------------------------------------
local function dieHardCamera()
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not npcRoot then return end

	-- 카메라가 NPC를 따라가며 올려다봄
	local startTime = tick()
	local duration = 2.5  -- 전체 연출 시간

	while tick() - startTime < duration do
		local npcPos = npcRoot.Position
		local elapsed = tick() - startTime

		-- 카메라는 약간 뒤, 옆에서 NPC를 추적
		local offset
		if elapsed < 0.8 then
			-- 올라가는 중: 아래에서 올려다봄
			offset = Vector3.new(8, -2, 8)
		elseif elapsed < 1.5 then
			-- 꼭대기: 옆에서 수평으로
			offset = Vector3.new(10, 0, 5)
		else
			-- 떨어지는 중: 위에서 내려다봄
			offset = Vector3.new(6, 5, 6)
		end

		local cameraPos = npcPos + offset
		camera.CFrame = CFrame.lookAt(cameraPos, npcPos)
		task.wait()
	end
end

-----------------------------------------------
-- 빡! 때리기 연출 (다이하드 스타일)
-----------------------------------------------
local function playSlapEffect(isPlayerWin)
	if isPlayerWin then
		-- 빡! 순간: 슬로모션 + 플래시 + 흔들림
		task.spawn(function() slowMotion(0.2, 0.2) end)
		task.wait(0.1)
		hitFlash(Color3.fromRGB(255, 100, 50))
		impactZoom()
		task.spawn(function() shakeCamera(2, 0.4) end)
		task.wait(0.3)

		-- 다이하드 카메라: NPC 따라감 (하늘로 → 체공 → 추락)
		task.spawn(function() dieHardCamera() end)

		-- 착지 순간 다시 흔들림 + 플래시
		task.wait(2)
		hitFlash(Color3.fromRGB(255, 200, 50))
		task.spawn(function() shakeCamera(3, 0.6) end)
	else
		-- 내가 맞을 때
		hitFlash(Color3.fromRGB(255, 0, 0))
		task.spawn(function() shakeCamera(2, 0.7) end)
		task.spawn(function() slowMotion(0.3, 0.2) end)
	end
end

-----------------------------------------------
-- 연승 팝업 연출
-----------------------------------------------
local function showStreakPopup(count)
	local messages = {
		[3]  = "🔥 3연승!",
		[5]  = "🔥🔥 5연승! 뺨장인!",
		[10] = "💥 10연승! 전설의 손바닥!",
		[15] = "⚡ 15연승! 뺨의 신!",
		[20] = "👑 20연승! 뺨왕 등극!",
		[30] = "☠️ 30연승! 더 이상 상대가 없다!",
		[50] = "🌟 50연승! 우주 최강 뺨!",
	}

	-- 매 라운드 기본 표시
	scoreLabel.Text = "🔥 " .. count .. "연승"

	-- 특별 연승 팝업
	local msg = messages[count]
	if not msg and count >= 3 and count % 5 == 0 then
		msg = "🔥 " .. count .. "연승!"
	end

	if msg then
		streakPopup.Text = msg
		streakPopup.TextTransparency = 0
		streakPopup.Visible = true
		streakPopup.TextSize = 10

		-- 팡! 하고 커지는 애니메이션
		local popIn = TweenService:Create(streakPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 48
		})
		popIn:Play()

		task.wait(1.5)

		local fadeOut = TweenService:Create(streakPopup, TweenInfo.new(0.5), {
			TextTransparency = 1
		})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			streakPopup.Visible = false
		end)
	end
end

-----------------------------------------------
-- 옆에서 보는 카메라
-----------------------------------------------
local function setSideCamera()
	local character = player.Character
	if not character then return end
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not playerRoot or not npcRoot then return end

	local midPoint = (playerRoot.Position + npcRoot.Position) / 2
	local direction = (npcRoot.Position - playerRoot.Position).Unit
	local sideDirection = direction:Cross(Vector3.new(0, 1, 0)).Unit

	-- 좀 더 가까이 + 얼굴 높이
	local cameraPos = midPoint + sideDirection * 8 + Vector3.new(0, 2, 0)

	camera.CameraType = Enum.CameraType.Scriptable
	local tween = TweenService:Create(camera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(cameraPos, midPoint + Vector3.new(0, 1.5, 0))
	})
	tween:Play()
end

local function resetCamera()
	camera.CameraType = Enum.CameraType.Custom
end

-----------------------------------------------
-- 서로 마주보기
-----------------------------------------------
local function faceEachOther()
	local character = player.Character
	if not character then return end
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
	if not playerRoot or not npcRoot then return end

	local npcLookAt = Vector3.new(playerRoot.Position.X, npcRoot.Position.Y, playerRoot.Position.Z)
	npcRoot.CFrame = CFrame.lookAt(npcRoot.Position, npcLookAt)

	local playerLookAt = Vector3.new(npcRoot.Position.X, playerRoot.Position.Y, npcRoot.Position.Z)
	playerRoot.CFrame = CFrame.lookAt(playerRoot.Position, playerLookAt)
end

-----------------------------------------------
-- 캐릭터 선택
-----------------------------------------------
local selectedNPCName = nil

for _, btn in ipairs(charSelect:WaitForChild("CharList"):GetChildren()) do
	if btn:IsA("TextButton") then
		btn.MouseButton1Click:Connect(function()
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

charSelect:WaitForChild("StartBtn").MouseButton1Click:Connect(function()
	if not selectedNPCName then return end
	charSelect.Visible = false

	-- 서버에 캐릭터 변경 요청 (위치 리셋 포함)
	local changeNPC = ReplicatedStorage:WaitForChild("ChangeNPC")
	changeNPC:FireServer(selectedNPCName)

	-- 위치 리셋 + 아바타 로드 대기
	task.wait(1.5)
	inGame = true
	faceEachOther()
	task.wait(0.3)
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

-----------------------------------------------
-- 서버 결과 수신
-----------------------------------------------
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

		-- UI 숨기고 연출에 집중
		frame.Visible = false

		-- 빡! 때리기 연출
		playSlapEffect(true)

		-- 연출 감상 시간 (서버 다이하드 애니메이션 3초 + 여유)
		task.wait(3.5)

		-- 연승 팝업
		showStreakPopup(streak)
		task.wait(2)

		-- 다음 상대 선택
		resetCamera()
		charSelect.Visible = true

	elseif outcome == "lose" then
		-- UI 숨기고 연출에 집중
		frame.Visible = false

		-- 맞는 연출 (플래시 + 흔들림)
		playSlapEffect(false)

		-- 넘어지는 연출 감상 (1.5초 애니메이션)
		task.wait(2)

		-- 게임 오버 표시
		frame.Visible = true
		title.Text = "게임 오버!"
		result.Text = "최종 기록: " .. streak .. "연승"
		scoreLabel.Text = "최종: " .. streak .. "연승"

		task.wait(3)

		streak = 0
		scoreLabel.Text = "연승: 0"
		frame.Visible = false
		resetCamera()
		charSelect.Visible = true
	end
end)

-----------------------------------------------
-- 시작
-----------------------------------------------
charSelect.Visible = true
frame.Visible = false
