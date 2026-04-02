-- RPSClient.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- 클라이언트: UI + 시네마틱 카메라 + VS연출 + 카운트다운 + 싱글/PvP

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screenGui = script.Parent

-----------------------------------------------
-- 포스트 프로세싱 초기화
-----------------------------------------------
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 1.1
bloom.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.FarIntensity = 0
dof.FocusDistance = 20
dof.InFocusRadius = 30
dof.NearIntensity = 0
dof.Enabled = false
dof.Parent = Lighting

local colorCorrect = Instance.new("ColorCorrectionEffect")
colorCorrect.Brightness = 0
colorCorrect.Contrast = 0.05
colorCorrect.Saturation = 0.1
colorCorrect.Parent = Lighting

-----------------------------------------------
-- 배경 음악 (BGM)
-----------------------------------------------
local bgm = Instance.new("Sound")
bgm.Name = "BGM"
bgm.SoundId = "rbxassetid://138746478130265"
bgm.Volume = 0.4
bgm.Looped = true
bgm.Playing = true
bgm.Parent = screenGui

local battleBgm = Instance.new("Sound")
battleBgm.Name = "BattleBGM"
battleBgm.SoundId = "rbxassetid://108322204177228"
battleBgm.Volume = 0.5
battleBgm.Looped = true
battleBgm.Playing = false
battleBgm.Parent = screenGui

-- 승리/패배 전용 사운드 (별도 관리)
local resultSound = Instance.new("Sound")
resultSound.Name = "ResultSound"
resultSound.Volume = 0.7
resultSound.Looped = false
resultSound.Parent = screenGui

-----------------------------------------------
-- BGM 전환
-----------------------------------------------
local function stopResultSound()
	resultSound.Playing = false
	resultSound.TimePosition = 0
end

local function switchBGM(mode)
	if mode == "battle" then
		stopResultSound()
		TweenService:Create(bgm, TweenInfo.new(0.5), { Volume = 0 }):Play()
		task.delay(0.5, function()
			bgm.Playing = false
			battleBgm.Volume = 0
			battleBgm.Playing = true
			TweenService:Create(battleBgm, TweenInfo.new(0.5), { Volume = 0.5 }):Play()
		end)
	elseif mode == "lobby" then
		stopResultSound()
		TweenService:Create(battleBgm, TweenInfo.new(0.5), { Volume = 0 }):Play()
		task.delay(0.5, function()
			battleBgm.Playing = false
			bgm.Volume = 0
			bgm.Playing = true
			TweenService:Create(bgm, TweenInfo.new(0.5), { Volume = 0.4 }):Play()
		end)
	elseif mode == "win" then
		-- 대전 BGM 끄고 승리 사운드
		TweenService:Create(battleBgm, TweenInfo.new(0.3), { Volume = 0 }):Play()
		task.delay(0.3, function() battleBgm.Playing = false end)
		stopResultSound()
		resultSound.SoundId = "rbxassetid://138911503838724"
		resultSound.Volume = 0.7
		resultSound.Playing = true
	elseif mode == "lose" then
		-- 대전 BGM 끄고 패배 사운드
		TweenService:Create(battleBgm, TweenInfo.new(0.3), { Volume = 0 }):Play()
		task.delay(0.3, function() battleBgm.Playing = false end)
		stopResultSound()
		resultSound.SoundId = "rbxassetid://136335820421357"
		resultSound.Volume = 0.7
		resultSound.Playing = true
	end
end

-----------------------------------------------
-- UI 효과음
-----------------------------------------------
local UI_SOUNDS = {
	click     = "rbxassetid://6895079853",
	win       = "rbxassetid://138911503838724",
	lose      = "rbxassetid://136335820421357",
	streak    = "rbxassetid://5766164683",
	select    = "rbxassetid://6895079853",
	countdown = "rbxassetid://5765933873",
	whoosh    = "rbxassetid://5766164683",
	impact    = "rbxassetid://5765933873",
	vs        = "rbxassetid://1837756993",
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

-- 신규 UI 요소
local vsOverlay = screenGui:WaitForChild("VSOverlay")
local countdownLabel = screenGui:WaitForChild("CountdownLabel")
local impactText = screenGui:WaitForChild("ImpactText")
local winBanner = screenGui:WaitForChild("WinBanner")

-----------------------------------------------
-- 상태 변수
-----------------------------------------------
local gameMode = nil
local canChoose = false
local streak = 0
local inGame = false
local currentOpponentId = nil
local currentOpponentName = nil
local pendingChallengeFromId = nil

-----------------------------------------------
-- ★ VS 화면 연출
-----------------------------------------------
local function showVSScreen(myName, opponentName)
	local leftBg = vsOverlay:WaitForChild("LeftBg")
	local rightBg = vsOverlay:WaitForChild("RightBg")
	local nameLeft = vsOverlay:WaitForChild("NameLeft")
	local nameRight = vsOverlay:WaitForChild("NameRight")
	local vsTextLabel = vsOverlay:WaitForChild("VSText")
	local fightText = vsOverlay:WaitForChild("FightText")

	-- 초기화
	nameLeft.Text = myName
	nameRight.Text = opponentName
	leftBg.Position = UDim2.new(-0.5, 0, 0, 0)
	rightBg.Position = UDim2.new(1, 0, 0, 0)
	nameLeft.Position = UDim2.new(-0.4, 0, 0.38, 0)
	nameRight.Position = UDim2.new(1, 0, 0.48, 0)
	vsTextLabel.TextSize = 0
	vsTextLabel.TextTransparency = 1
	fightText.TextSize = 0
	fightText.TextTransparency = 1
	vsOverlay.Visible = true

	playUISound(UI_SOUNDS.vs, 0.7, 0.8)

	-- 배경 슬라이드 인
	TweenService:Create(leftBg, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()
	TweenService:Create(rightBg, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 0)
	}):Play()

	task.wait(0.3)

	-- 이름 슬라이드 인
	TweenService:Create(nameLeft, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.05, 0, 0.38, 0)
	}):Play()
	TweenService:Create(nameRight, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.55, 0, 0.48, 0)
	}):Play()

	task.wait(0.3)

	-- VS 팝인
	TweenService:Create(vsTextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 100,
		TextTransparency = 0,
	}):Play()

	playUISound(UI_SOUNDS.impact, 1, 0.6)
	task.wait(0.5)

	-- 대결 시작 텍스트
	TweenService:Create(fightText, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
		TextSize = 28,
		TextTransparency = 0,
	}):Play()

	task.wait(1.2)

	-- 페이드 아웃
	TweenService:Create(vsOverlay, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	}):Play()
	TweenService:Create(leftBg, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(rightBg, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(nameLeft, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
	TweenService:Create(nameRight, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
	TweenService:Create(vsTextLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
	TweenService:Create(fightText, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()

	task.wait(0.5)

	-- 리셋
	vsOverlay.Visible = false
	vsOverlay.BackgroundTransparency = 0.25
	leftBg.BackgroundTransparency = 0.3
	rightBg.BackgroundTransparency = 0.3
end

-----------------------------------------------
-- ★ 카운트다운 연출
-----------------------------------------------
local function playCountdown()
	countdownLabel.Visible = true

	local colors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 200, 50),
		Color3.fromRGB(100, 255, 100),
	}

	for i = 3, 1, -1 do
		countdownLabel.Text = tostring(i)
		countdownLabel.TextColor3 = colors[4 - i]
		countdownLabel.TextTransparency = 0
		countdownLabel.TextSize = 20
		countdownLabel.Rotation = math.random(-5, 5)

		playUISound(UI_SOUNDS.countdown, 0.6, 0.8 + (3 - i) * 0.15)

		TweenService:Create(countdownLabel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 90,
			Rotation = 0,
		}):Play()

		task.wait(0.6)

		TweenService:Create(countdownLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
			TextSize = 120,
		}):Play()

		task.wait(0.2)
	end

	-- "승부!" 텍스트
	countdownLabel.Text = "승부!"
	countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	countdownLabel.TextTransparency = 0
	countdownLabel.TextSize = 10
	countdownLabel.Rotation = -5

	playUISound(UI_SOUNDS.impact, 1, 1.2)

	TweenService:Create(countdownLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 110,
		Rotation = 0,
	}):Play()

	task.wait(0.6)

	TweenService:Create(countdownLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		TextTransparency = 1,
	}):Play()

	task.wait(0.3)
	countdownLabel.Visible = false
	countdownLabel.TextTransparency = 0
end

-----------------------------------------------
-- ★ 임팩트 텍스트 ("퍽!")
-----------------------------------------------
local function showImpactText(text, color)
	impactText.Text = text or "퍽!"
	impactText.TextColor3 = color or Color3.fromRGB(255, 50, 30)
	impactText.TextTransparency = 0
	impactText.TextSize = 10
	impactText.Rotation = math.random(-15, 15)
	impactText.Visible = true

	TweenService:Create(impactText, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 130,
		Rotation = math.random(-5, 5),
	}):Play()

	task.wait(0.5)

	TweenService:Create(impactText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
		TextTransparency = 1,
		TextSize = 160,
	}):Play()

	task.wait(0.3)
	impactText.Visible = false
end

-----------------------------------------------
-- ★ 승리/패배 배너
-----------------------------------------------
local function showWinBanner(text, isWin)
	local banner = winBanner
	local bannerText = banner:WaitForChild("Text")

	if isWin then
		banner.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
		bannerText.TextColor3 = Color3.fromRGB(40, 20, 0)
	else
		banner.BackgroundColor3 = Color3.fromRGB(60, 10, 10)
		bannerText.TextColor3 = Color3.fromRGB(255, 80, 80)
	end

	bannerText.Text = text
	banner.Position = UDim2.new(0, 0, -0.15, 0)
	banner.Visible = true

	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0.42, 0)
	}):Play()

	task.wait(2.5)

	TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0, 0, 1.1, 0)
	}):Play()

	task.wait(0.3)
	banner.Visible = false
end

-----------------------------------------------
-- 화면 연출 함수들 (강화)
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
	flash.BackgroundTransparency = 0
	flash.Visible = true

	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()

	task.delay(0.6, function()
		flash.Visible = false
	end)
end

local function slowMotion(dur, factor)
	-- 포스트 프로세싱 강화
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.4
	cc.Saturation = -0.3
	cc.Brightness = 0.05
	cc.TintColor = Color3.fromRGB(255, 230, 210)
	cc.Parent = Lighting

	-- DOF 활성화
	dof.Enabled = true
	dof.FarIntensity = 0.5
	dof.FocusDistance = 10
	dof.InFocusRadius = 5

	-- 블룸 강화
	local origBloomIntensity = bloom.Intensity
	bloom.Intensity = 1.2
	bloom.Threshold = 0.8

	task.wait(dur)

	-- 복원
	local fadeTween = TweenService:Create(cc, TweenInfo.new(0.4), {
		Contrast = 0, Saturation = 0, Brightness = 0
	})
	fadeTween:Play()
	fadeTween.Completed:Connect(function() cc:Destroy() end)

	TweenService:Create(bloom, TweenInfo.new(0.4), {
		Intensity = origBloomIntensity
	}):Play()
	bloom.Threshold = 1.1

	dof.Enabled = false
end

local function impactZoom()
	local currentCF = camera.CFrame
	local lookDir = currentCF.LookVector

	TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = currentCF + lookDir * 3
	}):Play()

	task.wait(0.08)

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = currentCF
	}):Play()
end

-----------------------------------------------
-- ★ 시네마틱 카메라 시스템
-----------------------------------------------
local function getTargetRoots()
	local playerRoot = nil
	local opponentRoot = nil

	if player.Character then
		playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
	end

	if gameMode == "pvp" and currentOpponentId then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == currentOpponentId and p.Character then
				opponentRoot = p.Character:FindFirstChild("HumanoidRootPart")
				break
			end
		end
	end

	if not opponentRoot then
		local npc = workspace:FindFirstChild("NPC")
		if npc then
			opponentRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
		end
	end

	return playerRoot, opponentRoot
end

local function setCameraAngle(mode)
	local playerRoot, opponentRoot = getTargetRoots()
	if not playerRoot or not opponentRoot then return end

	local midPoint = (playerRoot.Position + opponentRoot.Position) / 2
	local direction = (opponentRoot.Position - playerRoot.Position).Unit
	local sideDir = direction:Cross(Vector3.new(0, 1, 0)).Unit

	camera.CameraType = Enum.CameraType.Scriptable

	local targetCF

	if mode == "side_wide" then
		-- 넓은 측면 뷰
		local pos = midPoint + sideDir * 10 + Vector3.new(0, 3, 0)
		targetCF = CFrame.lookAt(pos, midPoint + Vector3.new(0, 1.5, 0))

	elseif mode == "side_close" then
		-- 가까운 측면
		local pos = midPoint + sideDir * 6 + Vector3.new(0, 1.8, 0)
		targetCF = CFrame.lookAt(pos, midPoint + Vector3.new(0, 1.5, 0))

	elseif mode == "low_dramatic" then
		-- 로우 앵글 (아래에서 위를 올려다봄)
		local pos = midPoint + sideDir * 7 + Vector3.new(0, -1, 0)
		targetCF = CFrame.lookAt(pos, midPoint + Vector3.new(0, 2.5, 0))

	elseif mode == "closeup_player" then
		-- 플레이어 클로즈업
		local lookDir = playerRoot.CFrame.LookVector
		local pos = playerRoot.Position + lookDir * -3 + Vector3.new(0, 1.5, 0) + sideDir * 1.5
		targetCF = CFrame.lookAt(pos, playerRoot.Position + Vector3.new(0, 1.5, 0))

	elseif mode == "closeup_opponent" then
		-- 상대 클로즈업
		local lookDir = opponentRoot.CFrame.LookVector
		local pos = opponentRoot.Position + lookDir * -3 + Vector3.new(0, 1.5, 0) + sideDir * -1.5
		targetCF = CFrame.lookAt(pos, opponentRoot.Position + Vector3.new(0, 1.5, 0))

	elseif mode == "impact" then
		-- 임팩트 앵글 (약간 아래에서, 가까이)
		local pos = midPoint + sideDir * 4 + Vector3.new(0, 0.5, 0) - direction * 1
		targetCF = CFrame.lookAt(pos, opponentRoot.Position + Vector3.new(0, 1.8, 0))

	elseif mode == "victory" then
		-- 승자 스포트라이트
		local pos = playerRoot.Position + playerRoot.CFrame.LookVector * -5 + Vector3.new(0, 2, 0)
		targetCF = CFrame.lookAt(pos, playerRoot.Position + Vector3.new(0, 2, 0))

	elseif mode == "defeat" then
		-- 패배자 앵글 (위에서 내려다봄)
		local pos = playerRoot.Position + Vector3.new(0, 8, 3)
		targetCF = CFrame.lookAt(pos, playerRoot.Position + Vector3.new(0, 1, 0))
	end

	if targetCF then
		TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCF
		}):Play()
	end
end

local function setSideCamera()
	setCameraAngle("side_close")
end

local function resetCamera()
	camera.CameraType = Enum.CameraType.Custom
	dof.Enabled = false
end

-----------------------------------------------
-- ★ 강화된 타격 연출
-----------------------------------------------
local function playSlapEffect(isWin)
	-- 임팩트 앵글로 전환
	setCameraAngle("impact")
	task.wait(0.1)

	-- 히트 플래시
	hitFlash(isWin and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 0, 0))

	-- 카메라 셰이크 + 슬로모션 + 줌 동시
	task.spawn(function() shakeCamera(2.5, 0.5) end)
	task.spawn(function() slowMotion(0.35, 0.15) end)
	task.spawn(function() impactZoom() end)

	-- 임팩트 텍스트
	task.spawn(function()
		local texts = isWin and { "퍽!", "쎄게!", "찰싹!", "맛좀 봐라!" } or { "억!", "으악!", "아야!", "헉!" }
		local colors = isWin and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(255, 50, 30)
		showImpactText(texts[math.random(#texts)], colors)
	end)

	playUISound(UI_SOUNDS.impact, 1.2, isWin and 0.7 or 0.5)
end

-----------------------------------------------
-- 연승 팝업
-----------------------------------------------
local function showStreakPopup(count)
	local messages = {
		[3]  = "3연승!",
		[5]  = "5연승! 뺨장인!",
		[10] = "10연승! 전설의 손바닥!",
		[15] = "15연승! 뺨의 신!",
		[20] = "20연승! 뺨왕 등극!",
		[30] = "30연승! 더 이상 상대가 없다!",
		[50] = "50연승! 우주 최강 뺨!",
	}

	scoreLabel.Text = count .. "연승"

	local msg = messages[count]
	if not msg and count >= 3 and count % 5 == 0 then
		msg = count .. "연승!"
	end

	if msg then
		streakPopup.Text = msg
		streakPopup.TextTransparency = 0
		streakPopup.Visible = true
		streakPopup.TextSize = 10

		TweenService:Create(streakPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 52
		}):Play()

		task.wait(1.5)

		TweenService:Create(streakPopup, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.5)
		streakPopup.Visible = false
	end
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
	vsOverlay.Visible = false
	countdownLabel.Visible = false
	impactText.Visible = false
	winBanner.Visible = false
end

-----------------------------------------------
-- 가위바위보 라운드
-----------------------------------------------
function startRound()
	frame.Visible = true
	result.Text = "선택하세요!"
	title.Text = "가위 바위 보!"
	canChoose = true

	-- 버튼 등장 애니메이션
	for i, btn in ipairs(buttons:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundTransparency = 0
			btn.Size = UDim2.new(0, 10, 0, 10)
			TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, (i - 1) * 0.08), {
				Size = UDim2.new(0, 110, 0, 90)
			}):Play()
		end
	end
end

local function disableButtons()
	canChoose = false
	for _, btn in ipairs(buttons:GetChildren()) do
		if btn:IsA("TextButton") then
			TweenService:Create(btn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.5
			}):Play()
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

			-- 클릭한 버튼 확대 연출
			TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
				Size = UDim2.new(0, 125, 0, 100)
			}):Play()

			if gameMode == "pvp" then
				rpsPvP:FireServer({ action = "choice", choice = btn.Name })
			else
				rpsChoice:FireServer(btn.Name)
			end
		end)
	end
end

-----------------------------------------------
-- ★ 시네마틱 인트로 시퀀스
-----------------------------------------------
local function playCinematicIntro(opponentName)
	local myName = player.DisplayName

	-- 대전 BGM으로 전환
	switchBGM("battle")

	-- VS 화면
	showVSScreen(myName, opponentName or "???")

	-- 카메라 앵글 전환하며 카운트다운
	setCameraAngle("side_wide")
	task.wait(0.3)

	setCameraAngle("closeup_player")
	task.wait(0.4)

	setCameraAngle("closeup_opponent")
	task.wait(0.4)

	-- 카운트다운
	setCameraAngle("side_close")
	playCountdown()
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

pvpWait:WaitForChild("CancelBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	rpsPvP:FireServer({ action = "leave_queue" })
	pvpWait.Visible = false
	modeSelect.Visible = true
end)

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
					local stroke = other:FindFirstChildOfClass("UIStroke")
					if stroke then stroke.Color = Color3.fromRGB(255, 255, 255); stroke.Thickness = 1 end
				end
			end
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(255, 255, 50)
				stroke.Thickness = 3
			end
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

	task.wait(1)
	inGame = true
	currentOpponentName = selectedNPCName

	-- ★ 시네마틱 인트로!
	playCinematicIntro(selectedNPCName)

	task.wait(0.3)
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

		-- ★ 강화된 타격 연출
		playSlapEffect(true)
		task.wait(1)

		-- ★ 승리 배너
		task.spawn(function()
			showWinBanner("승리! " .. selectedNPCName .. "의 뺨을 갈겼다!", true)
		end)

		-- 승리 카메라 + 승리 사운드
		setCameraAngle("victory")
		switchBGM("win")

		showStreakPopup(streak)
		task.wait(2)

		resetCamera()
		charSelect.Visible = true

	elseif outcome == "lose" then
		frame.Visible = false

		-- ★ 강화된 피격 연출
		playSlapEffect(false)
		task.wait(1)

		-- ★ 패배 배너
		task.spawn(function()
			showWinBanner("패배... " .. selectedNPCName .. "에게 뺨을 맞았다!", false)
		end)

		setCameraAngle("defeat")
		switchBGM("lose")

		frame.Visible = true
		title.Text = "게임 오버!"
		result.Text = "최종 기록: " .. streak .. "연승"
		scoreLabel.Text = "최종: " .. streak .. "연승"

		task.wait(3)

		streak = 0
		scoreLabel.Text = "연승: 0"
		frame.Visible = false
		resetCamera()
		switchBGM("lobby")
		modeSelect.Visible = true
	end
end)

-----------------------------------------------
-- 서버 공지 표시
-----------------------------------------------
rpsAnnounce.OnClientEvent:Connect(function(msg)
	announceBar.Text = msg
	announceBar.Visible = true
	announceBar.BackgroundTransparency = 0.3
	announceBar.TextTransparency = 0

	task.delay(4, function()
		if announceBar.Text == msg then
			TweenService:Create(announceBar, TweenInfo.new(1), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}):Play()
			task.delay(1, function()
				if announceBar.Text == msg then
					announceBar.Visible = false
					announceBar.TextTransparency = 0
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
	switchBGM("lobby")
	currentOpponentId = nil
	currentOpponentName = nil
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
		hideAllUI()
		currentOpponentId = data.opponentId
		currentOpponentName = data.opponentName

		-- ★ 시네마틱 인트로!
		task.wait(0.5)
		playCinematicIntro(data.opponentName)

		task.wait(0.3)
		startRound()

	elseif action == "opponent_chose" then
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

			-- ★ 강화된 타격
			playSlapEffect(true)
			task.wait(0.8)

			local winStreak = data.streak or 0
			if winStreak > 0 then
				streak = winStreak
				scoreLabel.Text = winStreak .. "연승"
			end

			-- ★ 승리 배너
			task.spawn(function()
				local bannerMsg
				if data.revengeSuccess then
					bannerMsg = "복수 성공!! " .. data.opponentName .. "을(를) 갈겼다!"
				else
					bannerMsg = "승리! " .. data.opponentName .. "의 뺨을 갈겼다!"
				end
				showWinBanner(bannerMsg, true)
			end)

			setCameraAngle("victory")
			switchBGM("win")

			if winStreak >= 3 then
				showStreakPopup(winStreak)
				task.wait(1.5)
			else
				task.wait(1.5)
			end

			resetCamera()
			pvpEndFrame.Visible = true
			if data.revengeSuccess then
				pvpEndFrame.ResultLabel.Text = "복수 성공!! " .. data.opponentName .. "을(를) 갈겼다!"
				pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(255, 100, 30)
			else
				pvpEndFrame.ResultLabel.Text = "승리! " .. data.opponentName .. "의 뺨을 갈겼다!"
				pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
			pvpEndFrame.RevengeBtn.Visible = false
			pvpEndFrame.RematchBtn.Visible = true
			pvpEndFrame.WaitNote.Visible = false

		elseif outcome == "lose" then
			frame.Visible = false

			-- ★ 강화된 피격
			playSlapEffect(false)
			task.wait(0.8)

			streak = 0
			scoreLabel.Text = "연승: 0"

			-- ★ 패배 배너
			task.spawn(function()
				showWinBanner("패배... " .. data.opponentName .. "에게 뺨을 맞았다!", false)
			end)

			setCameraAngle("defeat")
			switchBGM("lose")

			task.wait(1.5)

			resetCamera()
			pvpEndFrame.Visible = true
			pvpEndFrame.ResultLabel.Text = "패배... " .. data.opponentName .. "에게 뺨을 맞았다!"
			pvpEndFrame.ResultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			pvpEndFrame.RevengeBtn.Visible = true
			pvpEndFrame.RematchBtn.Visible = false
			pvpEndFrame.WaitNote.Visible = false
			currentOpponentId = data.opponentId
		end

	elseif action == "challenge_received" then
		pendingChallengeFromId = data.fromId
		challengePopup.Visible = true
		challengePopup.FromLabel.Text = "'" .. data.fromName .. "'이(가) 복수를 원합니다!"
		playUISound(UI_SOUNDS.countdown, 1, 0.5)

		local thisId = data.fromId
		task.delay(15, function()
			if pendingChallengeFromId == thisId and challengePopup.Visible then
				rpsPvP:FireServer({ action = "challenge_reply", fromId = thisId, accepted = false })
				challengePopup.Visible = false
				pendingChallengeFromId = nil
			end
		end)

	elseif action == "challenge_sent" then
		-- 대기 UI (pvpEndFrame에서 처리됨)

	elseif action == "challenge_declined" then
		pvpEndFrame.Visible = true
		pvpEndFrame.ResultLabel.Text = data.targetName .. "이(가) 도망쳤습니다!"
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
		switchBGM("lobby")
		modeSelect.Visible = true
		currentOpponentId = nil
		currentOpponentName = nil

	elseif action == "queue_joined" then
		pvpWait.Title.Text = "상대를 찾는 중..."

	elseif action == "queue_left" then
		-- UI는 이미 처리됨
	end
end)

-----------------------------------------------
-- 시작: 모드 선택 화면
-----------------------------------------------
hideAllUI()
modeSelect.Visible = true
scoreLabel.Text = "연승: 0"
