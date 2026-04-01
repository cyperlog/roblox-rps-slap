-- RPSClient.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- 클라이언트: UI + 카메라 연출 + 싱글/PvP 처리

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screenGui = script.Parent

-----------------------------------------------
-- UI 효과음
-----------------------------------------------
local UI_SOUNDS = {
	click     = "rbxassetid://6895079853",
	win       = "rbxassetid://1837756993",
	lose      = "rbxassetid://282954522",
	streak    = "rbxassetid://5766164683",
	select    = "rbxassetid://6895079853",
	countdown = "rbxassetid://5765933873",
}

local function playUISound(soundId, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = screenGui
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

-----------------------------------------------
-- RemoteEvent
-----------------------------------------------
local rpsChoice = ReplicatedStorage:WaitForChild("RPSChoice")
local rpsResult = ReplicatedStorage:WaitForChild("RPSResult")
local rpsPvP = ReplicatedStorage:WaitForChild("RPSPvP")
local rpsAnnounce = ReplicatedStorage:WaitForChild("RPSAnnounce")

-----------------------------------------------
-- UI 요소
-----------------------------------------------
local modeSelect = screenGui:WaitForChild("ModeSelect")
local charSelect = screenGui:WaitForChild("CharSelect")
local pvpWait = screenGui:WaitForChild("PvPWait")
local challengePopup = screenGui:WaitForChild("ChallengePopup")
local announceBar = screenGui:WaitForChild("AnnounceBar")
local pvpEndFrame = screenGui:WaitForChild("PvPEndFrame")
local frame = screenGui:WaitForChild("RPSFrame")
local title = frame:WaitForChild("Title")
local result = frame:WaitForChild("Result")
local buttons = frame:WaitForChild("Buttons")
local scoreLabel = screenGui:WaitForChild("Score")
local streakPopup = screenGui:WaitForChild("StreakPopup")

-----------------------------------------------
-- 상태 변수
-----------------------------------------------
local gameMode = nil   -- "solo" or "pvp"
local canChoose = false
local streak = 0
local inGame = false
local currentOpponentId = nil   -- PvP 상대 UserId (복수용)
local pendingChallengeFromId = nil  -- 도전장 보낸 사람

-----------------------------------------------
-- 화면 연출 함수들
-----------------------------------------------
local function shakeCamera(intensity, duration)
	local startTime = tick()
	while tick() - startTime < duration do
		local elapsed = tick() - startTime
		local decay = 1 - (elapsed / duration)
		local sx = (math.random() - 0.5) * 2 * intensity * decay
		local sy = (math.random() - 0.5) * 2 * intensity * decay
		camera.CFrame = camera.CFrame * CFrame.new(sx, sy, 0)
		task.wait()
	end
end

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
	tween.Completed:Connect(function() flash.Visible = false end)
end

local function slowMotion(dur, factor)
	workspace:SetAttribute("TimeScale", factor)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.3
	cc.Saturation = 0.5
	cc.TintColor = Color3.fromRGB(255, 220, 200)
	cc.Parent = Lighting
	task.wait(dur)
	workspace:SetAttribute("TimeScale", 1)
	local fadeTween = TweenService:Create(cc, TweenInfo.new(0.3), { Contrast = 0, Saturation = 0 })
	fadeTween:Play()
	fadeTween.Completed:Connect(function() cc:Destroy() end)
end

local function impactZoom()
	local currentCF = camera.CFrame
	local lookDir = currentCF.LookVector
	local zoomIn = TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = currentCF + lookDir * 2
	})
	zoomIn:Play()
	zoomIn.Completed:Connect(function()
		local zoomOut = TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = currentCF
		})
		zoomOut:Play()
	end)
end

local function playSlapEffect(isWin)
	hitFlash(isWin and Color3.fromRGB(255, 100, 50) or Color3.fromRGB(255, 0, 0))
	task.spawn(function() shakeCamera(2, 0.4) end)
	task.spawn(function() slowMotion(0.2, 0.15) end)
	impactZoom()
end

-----------------------------------------------
-- 연승 팝업
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

	scoreLabel.Text = "🔥 " .. count .. "연승"

	local msg = messages[count]
	if not msg and count >= 3 and count % 5 == 0 then
		msg = "🔥 " .. count .. "연승!"
	end

	if msg then
		streakPopup.Text = msg
		streakPopup.TextTransparency = 0
		streakPopup.Visible = true
		streakPopup.TextSize = 10

		local popIn = TweenService:Create(streakPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 48
		})
		popIn:Play()

		task.wait(1.5)

		local fadeOut = TweenService:Create(streakPopup, TweenInfo.new(0.5), { TextTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function() streakPopup.Visible = false end)
	end
end

-----------------------------------------------
-- 카메라 제어
-----------------------------------------------
local function setSideCamera()
	local character = player.Character
	if not character then return end

	-- PvP: 상대 플레이어 찾기 / 싱글: NPC
	local targetRoot = nil
	if gameMode == "pvp" and currentOpponentId then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == currentOpponentId and p.Character then
				targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
				break
			end
		end
	end
	if not targetRoot then
		local npc = workspace:FindFirstChild("NPC")
		if npc then targetRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") end
	end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot or not targetRoot then return end

	local midPoint = (playerRoot.Position + targetRoot.Position) / 2
	local direction = (targetRoot.Position - playerRoot.Position).Unit
	local sideDirection = direction:Cross(Vector3.new(0, 1, 0)).Unit
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
-- UI 숨기기 헬퍼
-----------------------------------------------
local function hideAllUI()
	modeSelect.Visible = false
	charSelect.Visible = false
	pvpWait.Visible = false
	challengePopup.Visible = false
	pvpEndFrame.Visible = false
	frame.Visible = false
end

-----------------------------------------------
-- 가위바위보 라운드 (싱글/PvP 공통)
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
			playUISound(UI_SOUNDS.click, 0.5, 1.2)
			disableButtons()
			result.Text = btn.Name .. " 선택!"

			if gameMode == "pvp" then
				rpsPvP:FireServer({ action = "choice", choice = btn.Name })
			else
				rpsChoice:FireServer(btn.Name)
			end
		end)
	end
end

-----------------------------------------------
-- 모드 선택
-----------------------------------------------
modeSelect:WaitForChild("SoloBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.6, 1)
	gameMode = "solo"
	hideAllUI()
	charSelect.Visible = true
end)

modeSelect:WaitForChild("PvPBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.6, 1)
	gameMode = "pvp"
	hideAllUI()
	pvpWait.Visible = true
	rpsPvP:FireServer({ action = "join_queue" })
end)

-- PvP 대기 취소
pvpWait:WaitForChild("CancelBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	rpsPvP:FireServer({ action = "leave_queue" })
	pvpWait.Visible = false
	modeSelect.Visible = true
end)

-- 온라인 인원 업데이트
task.spawn(function()
	while true do
		local count = #Players:GetPlayers()
		local label = modeSelect:FindFirstChild("OnlineCount")
		if label then
			label.Text = "현재 접속: " .. count .. "명"
		end
		task.wait(3)
	end
end)

-----------------------------------------------
-- 싱글모드: 캐릭터 선택
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
			playUISound(UI_SOUNDS.select, 0.4, 1.3)
		end)
	end
end

charSelect:WaitForChild("BackBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	charSelect.Visible = false
	modeSelect.Visible = true
	gameMode = nil
end)

charSelect:WaitForChild("StartBtn").MouseButton1Click:Connect(function()
	if not selectedNPCName then return end
	playUISound(UI_SOUNDS.click, 0.6, 1)
	charSelect.Visible = false

	local changeNPCEvt = ReplicatedStorage:WaitForChild("ChangeNPC")
	changeNPCEvt:FireServer(selectedNPCName)

	task.wait(1.5)
	inGame = true
	task.wait(0.3)
	setSideCamera()
	task.wait(0.5)
	startRound()
end)

-----------------------------------------------
-- 싱글모드: 결과 수신
-----------------------------------------------
rpsResult.OnClientEvent:Connect(function(data)
	local outcome = data.outcome
	local npcChoice = data.npcChoice

	if outcome == "draw" then
		playUISound(UI_SOUNDS.click, 0.3, 0.8)
		result.Text = "비겼다! (둘 다 " .. npcChoice .. ") 다시!"
		title.Text = "다시!"
		task.wait(1.5)
		startRound()

	elseif outcome == "win" then
		streak = streak + 1
		frame.Visible = false
		playSlapEffect(true)
		task.wait(2)

		playUISound(UI_SOUNDS.streak, 0.8, 1)
		showStreakPopup(streak)
		task.wait(2)

		resetCamera()
		charSelect.Visible = true

	elseif outcome == "lose" then
		frame.Visible = false
		playSlapEffect(false)
		task.wait(2)

		playUISound(UI_SOUNDS.lose, 0.8, 0.6)
		frame.Visible = true
		title.Text = "게임 오버!"
		result.Text = "최종 기록: " .. streak .. "연승"
		scoreLabel.Text = "최종: " .. streak .. "연승"

		task.wait(3)

		streak = 0
		scoreLabel.Text = "연승: 0"
		frame.Visible = false
		resetCamera()
		modeSelect.Visible = true
	end
end)

-----------------------------------------------
-- 서버 공지 표시
-----------------------------------------------
rpsAnnounce.OnClientEvent:Connect(function(msg)
	announceBar.Text = msg
	announceBar.Visible = true
	announceBar.BackgroundTransparency = 0.4

	-- 5초 후 페이드아웃
	task.delay(4, function()
		if announceBar.Text == msg then
			local fade = TweenService:Create(announceBar, TweenInfo.new(1), {
				BackgroundTransparency = 1,
			})
			fade:Play()
			fade.Completed:Connect(function()
				if announceBar.Text == msg then
					announceBar.Visible = false
				end
			end)
		end
	end)
end)

-----------------------------------------------
-- 도전장 팝업 처리
-----------------------------------------------
challengePopup:WaitForChild("AcceptBtn").MouseButton1Click:Connect(function()
	if not pendingChallengeFromId then return end
	playUISound(UI_SOUNDS.click, 0.6, 1.2)
	rpsPvP:FireServer({ action = "challenge_reply", fromId = pendingChallengeFromId, accepted = true })
	challengePopup.Visible = false
	pendingChallengeFromId = nil
end)

challengePopup:WaitForChild("DeclineBtn").MouseButton1Click:Connect(function()
	if not pendingChallengeFromId then return end
	playUISound(UI_SOUNDS.click, 0.4, 0.7)
	rpsPvP:FireServer({ action = "challenge_reply", fromId = pendingChallengeFromId, accepted = false })
	challengePopup.Visible = false
	pendingChallengeFromId = nil
end)

-----------------------------------------------
-- PvP 결과 후 버튼들
-----------------------------------------------
pvpEndFrame:WaitForChild("RevengeBtn").MouseButton1Click:Connect(function()
	if not currentOpponentId then return end
	playUISound(UI_SOUNDS.click, 0.8, 1.3)
	pvpEndFrame.Visible = false

	-- 복수 도전 보내기
	rpsPvP:FireServer({ action = "challenge", targetId = currentOpponentId })
	pvpEndFrame:WaitForChild("WaitNote").Visible = true
	pvpEndFrame.Visible = true
	pvpEndFrame.RevengeBtn.Visible = false
	pvpEndFrame.RematchBtn.Visible = false
	pvpEndFrame.ResultLabel.Text = "복수 도전장을 보냈습니다..."
end)

pvpEndFrame:WaitForChild("RematchBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.6, 1)
	pvpEndFrame.Visible = false
	resetCamera()
	pvpWait.Visible = true
	rpsPvP:FireServer({ action = "join_queue" })
end)

pvpEndFrame:WaitForChild("MenuBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	pvpEndFrame.Visible = false
	resetCamera()
	currentOpponentId = nil
	gameMode = nil
	modeSelect.Visible = true
end)

-----------------------------------------------
-- PvP 이벤트 수신
-----------------------------------------------
rpsPvP.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	local action = data.action

	if action == "matched" then
		-- 매칭 완료!
		hideAllUI()
		currentOpponentId = data.opponentId

		if data.isRevenge then
			playUISound(UI_SOUNDS.countdown, 0.8, 0.6)
		end

		-- 잠시 대기 후 카메라 세팅 + 라운드 시작
		task.wait(1)
		setSideCamera()
		task.wait(0.5)
		startRound()

	elseif action == "opponent_chose" then
		-- 상대가 선택 완료
		if not canChoose then
			result.Text = "결과 계산중..."
		else
			result.Text = "상대가 선택 완료! 빨리 고르세요!"
		end

	elseif action == "pvp_result" then
		local outcome = data.outcome

		if outcome == "draw" then
			playUISound(UI_SOUNDS.click, 0.3, 0.8)
			result.Text = "비겼다! (나: " .. data.myChoice .. " / 상대: " .. data.opChoice .. ") 다시!"
			title.Text = "다시!"
			task.wait(1.5)
			startRound()

		elseif outcome == "win" then
			frame.Visible = false
			playSlapEffect(true)

			local winStreak = data.streak or 0
			if winStreak > 0 then
				streak = winStreak
				scoreLabel.Text = "🔥 " .. winStreak .. "연승"
			end

			task.wait(2)

			if winStreak >= 3 then
				playUISound(UI_SOUNDS.streak, 0.8, 1)
				showStreakPopup(winStreak)
				task.wait(1.5)
			end

			-- 승리 후 옵션 표시
			resetCamera()
			pvpEndFrame.Visible = true
			if data.revengeSuccess then
				pvpEndFrame.ResultLabel.Text = "🔥 복수 성공!! " .. data.opponentName .. "을(를) 갈겼다!"
				pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 30)
			else
				pvpEndFrame.ResultLabel.Text = "✌️ 승리! " .. data.opponentName .. "의 뺨을 갈겼다!"
				pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
			pvpEndFrame.RevengeBtn.Visible = false
			pvpEndFrame.RematchBtn.Visible = true
			pvpEndFrame.WaitNote.Visible = false

		elseif outcome == "lose" then
			frame.Visible = false
			playSlapEffect(false)

			streak = 0
			scoreLabel.Text = "연승: 0"

			task.wait(2)
			playUISound(UI_SOUNDS.lose, 0.8, 0.6)

			-- 패배 후 복수 버튼 표시
			resetCamera()
			pvpEndFrame.Visible = true
			pvpEndFrame.ResultLabel.Text = "💀 패배... " .. data.opponentName .. "에게 뺨을 맞았다!"
			pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			pvpEndFrame.RevengeBtn.Visible = true
			pvpEndFrame.RematchBtn.Visible = false
			pvpEndFrame.WaitNote.Visible = false

			currentOpponentId = data.opponentId
		end

	elseif action == "challenge_received" then
		-- 도전장 수신
		pendingChallengeFromId = data.fromId
		challengePopup.Visible = true
		challengePopup.FromLabel.Text = "'" .. data.fromName .. "'이(가) 복수를 원합니다!"
		playUISound(UI_SOUNDS.countdown, 1, 0.5)

		-- 15초 후 자동 거절
		local thisId = data.fromId
		task.delay(15, function()
			if pendingChallengeFromId == thisId and challengePopup.Visible then
				rpsPvP:FireServer({ action = "challenge_reply", fromId = thisId, accepted = false })
				challengePopup.Visible = false
				pendingChallengeFromId = nil
			end
		end)

	elseif action == "challenge_sent" then
		-- 도전장 보냄 확인 (대기 UI)
		-- 이미 pvpEndFrame에서 처리됨

	elseif action == "challenge_declined" then
		-- 상대가 도전 거절 (도망!)
		pvpEndFrame.Visible = true
		pvpEndFrame.ResultLabel.Text = "🐔 " .. data.targetName .. "이(가) 도망쳤습니다!"
		pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		pvpEndFrame.RevengeBtn.Visible = false
		pvpEndFrame.RematchBtn.Visible = true
		pvpEndFrame.WaitNote.Visible = false

	elseif action == "challenge_failed" then
		pvpEndFrame.ResultLabel.Text = data.reason or "도전 실패"
		pvpEndFrame.RevengeBtn.Visible = false
		pvpEndFrame.RematchBtn.Visible = true
		pvpEndFrame.WaitNote.Visible = false

	elseif action == "opponent_left" then
		hideAllUI()
		resetCamera()
		modeSelect.Visible = true
		currentOpponentId = nil

	elseif action == "queue_joined" then
		-- 대기열 진입 확인
		pvpWait.Title.Text = "상대를 찾는 중..."

	elseif action == "queue_left" then
		-- 대기열 나감 확인 (UI는 이미 처리됨)
	end
end)

-----------------------------------------------
-- 시작: 모드 선택 화면
-----------------------------------------------
hideAllUI()
modeSelect.Visible = true
scoreLabel.Text = "연승: 0"
