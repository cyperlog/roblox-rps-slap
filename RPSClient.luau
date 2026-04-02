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
local roundFrame = screenGui:WaitForChild("RoundScore")
local roundLabel = roundFrame:WaitForChild("RoundLabel")
local roundDots = roundFrame:WaitForChild("RoundDots")
local coinDisplay = screenGui:WaitForChild("CoinDisplay")
local shopFrame = screenGui:WaitForChild("ShopFrame")
local spectateFrame = screenGui:WaitForChild("SpectateFrame")
local specExitBtn = screenGui:WaitForChild("SpectateExit")
local specInfoBar = screenGui:WaitForChild("SpectateInfo")

-- 신규 RemoteEvent
local rpsSkin = ReplicatedStorage:WaitForChild("RPSSkin")
local rpsSpectate = ReplicatedStorage:WaitForChild("RPSSpectate")

-----------------------------------------------
-- 상태 변수
-----------------------------------------------
local gameMode = nil
local canChoose = false
local streak = 0
local inGame = false
local isSpectating = false
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
	roundFrame.Visible = false
	shopFrame.Visible = false
	spectateFrame.Visible = false
	specExitBtn.Visible = false
	specInfoBar.Visible = false
end

-----------------------------------------------
-- ★ 코인 표시 업데이트
-----------------------------------------------
local function updateCoinDisplay()
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		coinDisplay.Text = "💰 " .. ls.Coins.Value
	end
end

-- leaderstats 변경 감지
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if ls then
		local coins = ls:WaitForChild("Coins", 5)
		if coins then
			coins.Changed:Connect(updateCoinDisplay)
			updateCoinDisplay()
		end
	end
end)

-----------------------------------------------
-- ★ 라운드 스코어 표시
-----------------------------------------------
local function updateRoundScore(myWins, opWins, round)
	roundFrame.Visible = true

	roundLabel.Text = "라운드 " .. round .. " / 3"

	-- 시각적 스코어: ● = 승리, ○ = 미정
	local myDots = string.rep("●", myWins) .. string.rep("○", 2 - myWins)
	local opDots = string.rep("●", opWins) .. string.rep("○", 2 - opWins)
	roundDots.Text = myDots .. "  VS  " .. opDots
end

local function hideRoundScore()
	roundFrame.Visible = false
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

	-- 라운드 스코어 초기화
	updateRoundScore(0, 0, 1)

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

	-- NPC 외형 변경 완료 대기
	task.wait(2)

	-- NPC 루트가 준비될 때까지 확인
	local npc = workspace:WaitForChild("NPC", 5)
	if npc then
		local tries = 0
		while not npc:FindFirstChild("HumanoidRootPart") and tries < 20 do
			task.wait(0.1)
			tries += 1
		end
	end

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
	local msgType = data.type or "match" -- "round" 또는 "match"
	local pWins = data.playerWins or 0
	local nWins = data.npcWins or 0
	local round = data.round or 1

	-- 스코어 업데이트
	updateRoundScore(pWins, nWins, round)

	if outcome == "draw" then
		playUISound(UI_SOUNDS.click, 0.3, 0.8)
		result.Text = "비겼다! (둘 다 " .. npcChoice .. ") 다시!"
		title.Text = "다시!"
		task.wait(1.5)
		startRound()

	elseif msgType == "round" then
		-- ★ 라운드 승/패 (매치 계속!)
		frame.Visible = false

		if outcome == "win" then
			playSlapEffect(true)
			task.wait(1)
			result.Text = "라운드 승리! (" .. pWins .. " - " .. nWins .. ")"
		else
			playSlapEffect(false)
			task.wait(1)
			result.Text = "라운드 패배... (" .. pWins .. " - " .. nWins .. ")"
		end

		-- 잠깐 결과 보여주고 다음 라운드
		frame.Visible = true
		title.Text = "라운드 " .. (round + 1)
		task.wait(1.5)
		-- 카메라 리셋 후 사이드뷰
		setCameraAngle("side_close")
		task.wait(0.5)
		updateRoundScore(pWins, nWins, round + 1)
		startRound()

	elseif msgType == "match" then
		-- ★ 매치 종료! (3판 2선승 확정)
		if outcome == "win" then
			streak = streak + 1
			frame.Visible = false

			playSlapEffect(true)
			task.wait(1)

			task.spawn(function()
				showWinBanner(pWins .. " : " .. nWins .. " 승리! " .. selectedNPCName .. "의 뺨을 갈겼다!", true)
			end)

			setCameraAngle("victory")
			switchBGM("win")
			showStreakPopup(streak)
			task.wait(2)

			hideRoundScore()
			resetCamera()
			charSelect.Visible = true

		elseif outcome == "lose" then
			frame.Visible = false

			playSlapEffect(false)
			task.wait(1)

			task.spawn(function()
				showWinBanner(pWins .. " : " .. nWins .. " 패배... " .. selectedNPCName .. "에게 뺨을 맞았다!", false)
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
			hideRoundScore()
			resetCamera()
			switchBGM("lobby")
			modeSelect.Visible = true
		end
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

	elseif action == "pvp_round" then
		-- ★ PvP 라운드 승/패 (매치 계속)
		local outcome = data.outcome
		updateRoundScore(data.winsMe or 0, data.winsOp or 0, data.round or 1)

		frame.Visible = false
		if outcome == "win" then
			playSlapEffect(true)
			task.wait(1)
			result.Text = "라운드 승리! (" .. (data.winsMe or 0) .. " - " .. (data.winsOp or 0) .. ")"
		else
			playSlapEffect(false)
			task.wait(1)
			result.Text = "라운드 패배... (" .. (data.winsMe or 0) .. " - " .. (data.winsOp or 0) .. ")"
		end

		frame.Visible = true
		title.Text = "라운드 " .. ((data.round or 1) + 1)
		task.wait(1.5)
		setCameraAngle("side_close")
		task.wait(0.5)
		updateRoundScore(data.winsMe or 0, data.winsOp or 0, (data.round or 1) + 1)
		startRound()

	elseif action == "pvp_result" then
		local outcome = data.outcome

		-- 스코어 표시
		if data.winsMe then
			updateRoundScore(data.winsMe, data.winsOp or 0, 3)
		end

		if outcome == "draw" then
			if data.round then updateRoundScore(data.winsMe or 0, data.winsOp or 0, data.round) end
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

			hideRoundScore()
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

			hideRoundScore()
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
-- ★ 상점 시스템
-----------------------------------------------
modeSelect:WaitForChild("ShopBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.6, 1)
	modeSelect.Visible = false
	shopFrame.Visible = true
	rpsSkin:FireServer({ action = "list" })
end)

shopFrame:WaitForChild("CloseBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	shopFrame.Visible = false
	modeSelect.Visible = true
end)

-- ★ 스킨 미리보기
local previewPart = nil
local function previewSkin(color1, color2)
	-- 기존 미리보기 정리
	if previewPart and previewPart.Parent then previewPart:Destroy() end

	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 미리보기 파트 (머리 앞에 생성)
	local pos = head.Position + head.CFrame.LookVector * 3 + Vector3.new(0, 1, 0)
	previewPart = Instance.new("Part")
	previewPart.Size = Vector3.new(1, 1, 1)
	previewPart.Position = pos
	previewPart.Anchored = true
	previewPart.CanCollide = false
	previewPart.Transparency = 1
	previewPart.Parent = workspace

	-- 메인 파티클
	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, color1),
		ColorSequenceKeypoint.new(1, color2),
	})
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.3, 3),
		NumberSequenceKeypoint.new(1, 0),
	})
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	particle.Lifetime = NumberRange.new(0.3, 0.8)
	particle.Speed = NumberRange.new(10, 25)
	particle.SpreadAngle = Vector2.new(360, 360)
	particle.LightEmission = 0.8
	particle.Rate = 0
	particle.Parent = previewPart
	particle:Emit(40)

	-- 충격파 링
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = color1
	ring.Transparency = 0.3
	ring.Parent = previewPart

	local startTime = tick()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = (tick() - startTime) / 0.5
		if t >= 1 then
			conn:Disconnect()
			ring:Destroy()
			return
		end
		local size = 1 + t * 8
		ring.Size = Vector3.new(0.2, size, size)
		ring.Transparency = 0.3 + t * 0.7
	end)

	-- 임팩트 텍스트 (스킨 색상)
	task.spawn(function()
		showImpactText("퍽!", color1)
	end)

	playUISound(UI_SOUNDS.impact, 0.6, 1)

	-- 2초 후 정리
	task.delay(2, function()
		if previewPart and previewPart.Parent then previewPart:Destroy() end
	end)
end

rpsSkin.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end

	if data.action == "skin_list" then
		-- 상점 목록 생성
		local list = shopFrame:WaitForChild("ShopList")
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		for _, skin in ipairs(data.skins) do
			local isOwned = false
			for _, o in ipairs(data.owned) do
				if o == skin.id then isOwned = true; break end
			end
			local isActive = data.active == skin.id

			local item = Instance.new("Frame")
			item.Size = UDim2.new(1, 0, 0, 55)
			item.BackgroundColor3 = isActive and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(25, 25, 35)
			item.BorderSizePixel = 0
			item.ZIndex = 32
			item.Parent = list

			local ic = Instance.new("UICorner")
			ic.CornerRadius = UDim.new(0, 8)
			ic.Parent = item

			-- 색상 미리보기
			local preview = Instance.new("Frame")
			preview.Size = UDim2.new(0, 36, 0, 36)
			preview.Position = UDim2.new(0, 10, 0.5, -18)
			preview.BackgroundColor3 = skin.color1
			preview.ZIndex = 33
			preview.Parent = item
			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0, 18)
			pc.Parent = preview

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0, 120, 0, 22)
			nameLabel.Position = UDim2.new(0, 55, 0, 6)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = skin.id
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 18
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.ZIndex = 33
			nameLabel.Parent = item

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(0, 150, 0, 16)
			descLabel.Position = UDim2.new(0, 55, 0, 30)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = skin.desc
			descLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
			descLabel.TextSize = 13
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.ZIndex = 33
			descLabel.Parent = item

			-- 미리보기 버튼
			local prevBtn = Instance.new("TextButton")
			prevBtn.Size = UDim2.new(0, 55, 0, 34)
			prevBtn.Position = UDim2.new(1, -180, 0.5, -17)
			prevBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			prevBtn.Text = "▶"
			prevBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
			prevBtn.TextSize = 18
			prevBtn.Font = Enum.Font.GothamBold
			prevBtn.BorderSizePixel = 0
			prevBtn.ZIndex = 33
			prevBtn.Parent = item
			local pbc = Instance.new("UICorner")
			pbc.CornerRadius = UDim.new(0, 8)
			pbc.Parent = prevBtn

			local skinColor1 = skin.color1
			local skinColor2 = skin.color2
			prevBtn.MouseButton1Click:Connect(function()
				previewSkin(skinColor1, skinColor2)
			end)

			-- 구매/장착 버튼
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 100, 0, 34)
			btn.Position = UDim2.new(1, -115, 0.5, -17)
			btn.BorderSizePixel = 0
			btn.TextSize = 15
			btn.Font = Enum.Font.GothamBold
			btn.ZIndex = 33
			btn.Parent = item

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 8)
			bc.Parent = btn

			if isActive then
				btn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
				btn.Text = "장착 중"
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			elseif isOwned then
				btn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
				btn.Text = "장착"
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.MouseButton1Click:Connect(function()
					rpsSkin:FireServer({ action = "equip", skinId = skin.id })
				end)
			else
				btn.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
				btn.Text = "💰 " .. skin.price
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.MouseButton1Click:Connect(function()
					rpsSkin:FireServer({ action = "buy", skinId = skin.id })
				end)
			end
		end

	elseif data.action == "buy_ok" or data.action == "equip_ok" then
		playUISound(UI_SOUNDS.click, 0.8, 1.5)
		rpsSkin:FireServer({ action = "list" }) -- 목록 새로고침

	elseif data.action == "buy_fail" then
		playUISound(UI_SOUNDS.lose, 0.5, 0.5)
	end
end)

-----------------------------------------------
-- ★ 관전 시스템
-----------------------------------------------
modeSelect:WaitForChild("SpectateBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.6, 1)
	modeSelect.Visible = false
	spectateFrame.Visible = true
	rpsSpectate:FireServer({ action = "list_matches" })
end)

spectateFrame:WaitForChild("CloseBtn").MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	spectateFrame.Visible = false
	modeSelect.Visible = true
end)

specExitBtn.MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 0.8)
	rpsSpectate:FireServer({ action = "stop" })
	isSpectating = false
	specExitBtn.Visible = false
	specInfoBar.Visible = false
	resetCamera()
	modeSelect.Visible = true
end)

rpsSpectate.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end

	if data.action == "match_list" then
		local list = spectateFrame:WaitForChild("SpecList")
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		if #data.matches == 0 then
			local noMatch = Instance.new("TextButton")
			noMatch.Size = UDim2.new(1, 0, 0, 40)
			noMatch.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			noMatch.Text = "진행 중인 대전이 없습니다"
			noMatch.TextColor3 = Color3.fromRGB(120, 120, 140)
			noMatch.TextSize = 16
			noMatch.Font = Enum.Font.Gotham
			noMatch.BorderSizePixel = 0
			noMatch.ZIndex = 32
			noMatch.Parent = list
			local nc = Instance.new("UICorner")
			nc.CornerRadius = UDim.new(0, 8)
			nc.Parent = noMatch
		else
			for _, match in ipairs(data.matches) do
				local mBtn = Instance.new("TextButton")
				mBtn.Size = UDim2.new(1, 0, 0, 50)
				mBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
				mBtn.Text = match.nameA .. " vs " .. match.nameB .. "  (R" .. match.round .. " | " .. match.winsA .. "-" .. match.winsB .. ")"
				mBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				mBtn.TextSize = 17
				mBtn.Font = Enum.Font.GothamBold
				mBtn.BorderSizePixel = 0
				mBtn.ZIndex = 32
				mBtn.Parent = list
				local mc = Instance.new("UICorner")
				mc.CornerRadius = UDim.new(0, 8)
				mc.Parent = mBtn

				local matchId = match.matchId
				mBtn.MouseButton1Click:Connect(function()
					rpsSpectate:FireServer({ action = "watch", matchId = matchId })
				end)
			end
		end

	elseif data.action == "watch_start" then
		spectateFrame.Visible = false
		isSpectating = true
		specExitBtn.Visible = true
		specInfoBar.Visible = true
		specInfoBar.Text = "관전 중: " .. data.nameA .. " vs " .. data.nameB

		-- 관전 카메라 (두 플레이어 사이)
		camera.CameraType = Enum.CameraType.Scriptable
		task.spawn(function()
			while isSpectating do
				local rootA, rootB = nil, nil
				for _, p in ipairs(Players:GetPlayers()) do
					if p.UserId == data.idA and p.Character then
						rootA = p.Character:FindFirstChild("HumanoidRootPart")
					elseif p.UserId == data.idB and p.Character then
						rootB = p.Character:FindFirstChild("HumanoidRootPart")
					end
				end
				if rootA and rootB then
					local mid = (rootA.Position + rootB.Position) / 2
					local dir = (rootB.Position - rootA.Position).Unit
					local side = dir:Cross(Vector3.new(0, 1, 0)).Unit
					local camPos = mid + side * 10 + Vector3.new(0, 3, 0)
					local targetCF = CFrame.lookAt(camPos, mid + Vector3.new(0, 1.5, 0))
					camera.CFrame = camera.CFrame:Lerp(targetCF, 0.1)
				end
				task.wait()
			end
		end)

	elseif data.action == "watch_stop" then
		isSpectating = false
		specExitBtn.Visible = false
		specInfoBar.Visible = false
		resetCamera()

	elseif data.action == "watch_fail" then
		spectateFrame.Visible = true
		rpsSpectate:FireServer({ action = "list_matches" })
	end
end)

-----------------------------------------------
-- ★ 튜토리얼 시스템
-----------------------------------------------
local rpsTutorial = ReplicatedStorage:WaitForChild("RPSTutorial")
local tutorialOverlay = screenGui:WaitForChild("TutorialOverlay")
local tutFrame = tutorialOverlay:WaitForChild("TutFrame")
local tutTitle = tutFrame:WaitForChild("Title")
local tutDesc = tutFrame:WaitForChild("Desc")
local tutEmoji = tutFrame:WaitForChild("Emoji")
local tutPage = tutFrame:WaitForChild("Page")
local tutNextBtn = tutFrame:WaitForChild("NextBtn")
local tutSkipBtn = tutFrame:WaitForChild("SkipBtn")

local TUTORIAL_PAGES = {
	{
		title = "환영합니다!",
		desc = "도전! 뺨때리기 마스터에 오신 걸 환영합니다!\n\n가위바위보로 대결해서\n상대의 뺨을 갈기는 게임입니다!",
		emoji = "👋",
	},
	{
		title = "게임 방법",
		desc = "가위, 바위, 보 중 하나를 선택하세요.\n이기면 상대의 뺨을 때리고\n지면 내가 맞습니다!\n\n3판 2선승으로 먼저 2번 이기면 승리!",
		emoji = "✌️ ✊ 🖐️",
	},
	{
		title = "NPC 대전",
		desc = "싱글플레이에서 다양한 NPC와 대결!\n각 NPC마다 난이도와 전략이 다릅니다.\n\n학생은 쉽고, 닌자는 어렵습니다!",
		emoji = "🤖",
	},
	{
		title = "PvP 대전",
		desc = "다른 플레이어와 실시간 대결!\n이기면 복수 도전도 가능합니다.\n\n관전 모드로 다른 사람의 대전도 구경하세요!",
		emoji = "⚔️",
	},
	{
		title = "코인 & 상점",
		desc = "승리하면 코인을 획득!\n연승할수록 보너스 코인이 늘어납니다.\n\n상점에서 멋진 뺨 이펙트를 구매하세요!",
		emoji = "💰",
	},
}

local tutorialPage = 1

local function showTutorialPage(page)
	local data = TUTORIAL_PAGES[page]
	if not data then return end

	tutTitle.Text = data.title
	tutDesc.Text = data.desc
	tutEmoji.Text = data.emoji
	tutPage.Text = page .. " / " .. #TUTORIAL_PAGES

	if page >= #TUTORIAL_PAGES then
		tutNextBtn.Text = "시작하기!"
	else
		tutNextBtn.Text = "다음 >"
	end

	-- 텍스트 등장 애니메이션
	tutTitle.TextTransparency = 1
	tutDesc.TextTransparency = 1
	tutEmoji.TextTransparency = 1
	TweenService:Create(tutTitle, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(tutDesc, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), { TextTransparency = 0 }):Play()
	TweenService:Create(tutEmoji, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), { TextTransparency = 0 }):Play()
end

local function closeTutorial()
	tutorialOverlay.Visible = false
	modeSelect.Visible = true
	rpsTutorial:FireServer({ action = "done" })
end

tutNextBtn.MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.5, 1.2)
	tutorialPage += 1
	if tutorialPage > #TUTORIAL_PAGES then
		closeTutorial()
	else
		showTutorialPage(tutorialPage)
	end
end)

tutSkipBtn.MouseButton1Click:Connect(function()
	playUISound(UI_SOUNDS.click, 0.4, 0.8)
	closeTutorial()
end)

-- 서버에서 튜토리얼 필요 여부 수신
rpsTutorial.OnClientEvent:Connect(function(data)
	if typeof(data) == "table" and data.needTutorial then
		modeSelect.Visible = false
		tutorialOverlay.Visible = true
		tutorialPage = 1
		showTutorialPage(1)
	end
end)

-----------------------------------------------
-- 시작: 모드 선택 화면
-----------------------------------------------
hideAllUI()
modeSelect.Visible = true
scoreLabel.Text = "연승: 0"
