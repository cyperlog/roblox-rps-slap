-- RPSServer.luau
-- ServerScriptService에 Script로 넣기
-- 서버: 가위바위보 싱글 + PvP + 굴욕 + 복수 + 시네마틱 애니메이션

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-----------------------------------------------
-- 효과음
-----------------------------------------------
local SOUNDS = {
	slap     = "rbxassetid://5765933873",
	whoosh   = "rbxassetid://5766164683",
	thud     = "rbxassetid://5765933873",
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

	task.delay(5, function() part:Destroy() end)
end

-----------------------------------------------
-- RemoteEvent 생성
-----------------------------------------------
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
local rpsPvP = getOrCreate("RPSPvP", "RemoteEvent")
local rpsAnnounce = getOrCreate("RPSAnnounce", "RemoteEvent")

-----------------------------------------------
-- 게임 상수
-----------------------------------------------
local winTable = {
	["가위"] = "보",
	["바위"] = "가위",
	["보"] = "바위",
}
local choicesList = { "가위", "바위", "보" }
local validChoices = { ["가위"] = true, ["바위"] = true, ["보"] = true }

local CENTER = Vector3.new(0, 3, 0)
local POS_A = CENTER + Vector3.new(0, 0, 3)
local POS_B = CENTER + Vector3.new(0, 0, -3)
local CFRAME_A = CFrame.lookAt(POS_A, POS_B)
local CFRAME_B = CFrame.lookAt(POS_B, POS_A)

local npcStyles = {
	["건달"]     = { userId = 261 },
	["학생"]     = { userId = 156 },
	["할아버지"] = { userId = 2407518839 },
	["로봇"]     = { userId = 4450258599 },
	["닌자"]     = { userId = 13656149 },
	["광대"]     = { userId = 1 },
}

-----------------------------------------------
-- ★ NPC AI 시스템
-----------------------------------------------
local playerHistory = {} -- playerId → {choice, choice, ...}

local function getNPCChoice(npcName, playerId)
	local history = playerHistory[playerId] or {}

	if npcName == "학생" then
		-- 쉬움: 완전 랜덤
		return choicesList[math.random(1, 3)]

	elseif npcName == "건달" then
		-- 공격적: 바위 50%, 가위 30%, 보 20%
		local r = math.random(100)
		if r <= 50 then return "바위"
		elseif r <= 80 then return "가위"
		else return "보" end

	elseif npcName == "할아버지" then
		-- 느긋: 보 50%, 바위 30%, 가위 20%
		local r = math.random(100)
		if r <= 50 then return "보"
		elseif r <= 80 then return "바위"
		else return "가위" end

	elseif npcName == "로봇" then
		-- 분석형: 플레이어가 가장 많이 낸 걸 카운터 (40% 확률)
		if #history >= 3 then
			local counts = { ["가위"] = 0, ["바위"] = 0, ["보"] = 0 }
			for _, c in ipairs(history) do counts[c] = (counts[c] or 0) + 1 end
			local maxC, maxN = "가위", 0
			for c, n in pairs(counts) do
				if n > maxN then maxC, maxN = c, n end
			end
			if math.random(100) <= 40 then
				-- 가장 많이 낸 걸 이기는 패
				if maxC == "가위" then return "바위"
				elseif maxC == "바위" then return "보"
				else return "가위" end
			end
		end
		return choicesList[math.random(1, 3)]

	elseif npcName == "닌자" then
		-- 어려움: 직전 선택을 카운터 (60% 확률)
		if #history >= 1 then
			local last = history[#history]
			if math.random(100) <= 60 then
				if last == "가위" then return "바위"
				elseif last == "바위" then return "보"
				else return "가위" end
			end
		end
		return choicesList[math.random(1, 3)]

	elseif npcName == "광대" then
		-- 카오스: 따라하기 30%, 카운터 25%, 랜덤 45%
		if #history >= 1 then
			local last = history[#history]
			local r = math.random(100)
			if r <= 30 then
				return last -- 따라하기 (비김)
			elseif r <= 55 then
				if last == "가위" then return "바위"
				elseif last == "바위" then return "보"
				else return "가위" end
			end
		end
		return choicesList[math.random(1, 3)]
	end

	return choicesList[math.random(1, 3)]
end

-----------------------------------------------
-- ★ 3판 2선승 상태 (싱글)
-----------------------------------------------
local soloMatchState = {} -- playerId → {playerWins, npcWins, npcName, round}

-----------------------------------------------
-- PvP 상태
-----------------------------------------------
local pvpQueue = {}
local pvpMatches = {}
local playerMatch = {}
local nextMatchId = 1
local rivalry = {}
local pvpStreaks = {}
local lastDefeatedBy = {}

-----------------------------------------------
-- 라이벌 시스템
-----------------------------------------------
local function getRivalryKey(id1, id2)
	if id1 < id2 then return id1 .. "_" .. id2 end
	return id2 .. "_" .. id1
end

local function addLoss(loserId, winnerId)
	local key = getRivalryKey(loserId, winnerId)
	if not rivalry[key] then
		rivalry[key] = { losses_a = 0, losses_b = 0 }
	end
	if loserId < winnerId then
		rivalry[key].losses_a += 1
	else
		rivalry[key].losses_b += 1
	end
end

local function getLosses(loserId, winnerId)
	local key = getRivalryKey(loserId, winnerId)
	local data = rivalry[key]
	if not data then return 0 end
	if loserId < winnerId then return data.losses_a end
	return data.losses_b
end

-----------------------------------------------
-- 서버 전체 공지
-----------------------------------------------
local function announce(msg)
	rpsAnnounce:FireAllClients(msg)
end

-----------------------------------------------
-- 물리/위치 유틸
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

local function teleportCharacter(character, cframe)
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	clearPhysics(root)
	root.CFrame = cframe
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.PlatformStand = false end
end

local function resetNPCPositions(playerCharacter)
	local npc = workspace:FindFirstChild("NPC")
	if npc then teleportCharacter(npc, CFRAME_B) end
	if playerCharacter then teleportCharacter(playerCharacter, CFRAME_A) end
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
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(style.userId)
		end)
		if ok and desc then
			pcall(function() humanoid:ApplyDescription(desc) end)
		end
	end

	local head = npc:FindFirstChild("Head")
	if head then
		local nameTag = head:FindFirstChild("NameTag")
		if not nameTag then
			local bb = Instance.new("BillboardGui")
			bb.Name = "NameTag"
			bb.Size = UDim2.new(0, 200, 0, 50)
			bb.StudsOffset = Vector3.new(0, 2, 0)
			bb.Parent = head
			local lbl = Instance.new("TextLabel")
			lbl.Name = "Label"
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextStrokeTransparency = 0.5
			lbl.TextSize = 20
			lbl.Font = Enum.Font.GothamBold
			lbl.Parent = bb
			nameTag = bb
		end
		nameTag.Label.Text = npcName
	end
end

-----------------------------------------------
-- ★ 파티클/이펙트 (강화)
-----------------------------------------------
local function createSlapEffect(position)
	-- 메인 파티클 (빨간/주황 폭발)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace

	local particle = Instance.new("ParticleEmitter")
	particle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 80, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 10)),
	})
	particle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.3, 4),
		NumberSequenceKeypoint.new(1, 0),
	})
	particle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	particle.Lifetime = NumberRange.new(0.3, 0.8)
	particle.Speed = NumberRange.new(20, 40)
	particle.SpreadAngle = Vector2.new(360, 360)
	particle.LightEmission = 0.8
	particle.Rate = 0
	particle.Parent = part
	particle:Emit(60)

	-- 충격파 링
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 200, 50)
	ring.Transparency = 0.3
	ring.Parent = workspace

	-- 링 확대 애니메이션
	local startTime = tick()
	local ringDuration = 0.5
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = (tick() - startTime) / ringDuration
		if t >= 1 then
			conn:Disconnect()
			ring:Destroy()
			return
		end
		local size = 1 + t * 12
		ring.Size = Vector3.new(0.2, size, size)
		ring.Transparency = 0.3 + t * 0.7
	end)

	task.delay(2, function() part:Destroy() end)
end

-----------------------------------------------
-- ★ 별 빙빙 이펙트 (강화)
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

	local stars = {}
	local starColors = {
		Color3.fromRGB(255, 255, 50),
		Color3.fromRGB(255, 150, 0),
		Color3.fromRGB(255, 255, 150),
		Color3.fromRGB(255, 200, 50),
		Color3.fromRGB(255, 100, 100),
	}

	for i = 1, 5 do
		local star = Instance.new("Part")
		star.Name = "Star" .. i
		star.Size = Vector3.new(0.8, 0.8, 0.2)
		star.Anchored = true
		star.CanCollide = false
		star.Color = starColors[i]
		star.Material = Enum.Material.Neon
		star.Shape = Enum.PartType.Ball
		star.Parent = workspace

		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(starColors[i])
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Lifetime = NumberRange.new(0.2, 0.4)
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.Rate = 20
		sparkle.LightEmission = 1
		sparkle.Parent = star

		table.insert(stars, star)
	end

	local radius = 2.2
	local spinSpeed = 10
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

		local fade = 1
		if elapsed > duration - 1.0 then
			fade = (duration - elapsed) / 1.0
		end

		local centerPos = head.Position + Vector3.new(0, 2.5, 0)
		starsHolder.Position = centerPos
		local bobY = math.sin(elapsed * 4) * 0.3

		for i, star in ipairs(stars) do
			local angle = elapsed * spinSpeed + (i - 1) * math.rad(360 / #stars)
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			star.Position = centerPos + Vector3.new(x, bobY + math.sin(elapsed * 6 + i) * 0.2, z)
			star.Transparency = 1 - fade
			local pulse = 0.5 + 0.4 * math.sin(elapsed * 12 + i * 2)
			star.Size = Vector3.new(pulse, pulse, 0.2)
		end
	end)
end

-----------------------------------------------
-- ★ 뺨때리기 팔 애니메이션 (신규!)
-----------------------------------------------
local function animateSlap(attacker)
	if not attacker then return end

	local rightShoulder = nil
	local rightElbow = nil
	for _, desc in ipairs(attacker:GetDescendants()) do
		if desc:IsA("Motor6D") then
			if desc.Name == "RightShoulder" then rightShoulder = desc end
			if desc.Name == "RightElbow" then rightElbow = desc end
		end
	end
	if not rightShoulder then return end

	local origC0 = rightShoulder.C0
	local origElbow = rightElbow and rightElbow.C0

	-- 키프레임 기반 애니메이션
	-- {시간, 어깨 오프셋, 팔꿈치 오프셋}
	local keyframes = {
		{ 0.00, CFrame.new(), CFrame.new() },
		-- 와인드업: 팔을 뒤로
		{ 0.12, CFrame.Angles(math.rad(-15), math.rad(-70), math.rad(60)), CFrame.Angles(math.rad(-50), 0, 0) },
		-- 스윙: 빠르게 앞으로!
		{ 0.20, CFrame.Angles(math.rad(10), math.rad(100), math.rad(-30)), CFrame.Angles(math.rad(-20), 0, 0) },
		-- 팔로스루
		{ 0.28, CFrame.Angles(math.rad(5), math.rad(80), math.rad(-15)), CFrame.Angles(math.rad(-10), 0, 0) },
		-- 복귀
		{ 0.55, CFrame.new(), CFrame.new() },
	}

	-- 와인드업 사운드
	local headPos = attacker:FindFirstChild("Head")
	if headPos then
		playSound(SOUNDS.whoosh, headPos.Position, 0.8, 1.5)
	end

	local startTime = tick()
	local totalDuration = keyframes[#keyframes][1]

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not rightShoulder or not rightShoulder.Parent then
			conn:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		if elapsed >= totalDuration then
			conn:Disconnect()
			rightShoulder.C0 = origC0
			if rightElbow and origElbow then rightElbow.C0 = origElbow end
			return
		end

		-- 현재 키프레임 쌍 찾기
		local prevKF, nextKF
		for i = 1, #keyframes - 1 do
			if elapsed >= keyframes[i][1] and elapsed < keyframes[i + 1][1] then
				prevKF = keyframes[i]
				nextKF = keyframes[i + 1]
				break
			end
		end

		if prevKF and nextKF then
			local segDur = nextKF[1] - prevKF[1]
			local t = (elapsed - prevKF[1]) / segDur
			t = t * t * (3 - 2 * t) -- smoothstep

			rightShoulder.C0 = origC0 * prevKF[2]:Lerp(nextKF[2], t)
			if rightElbow and origElbow then
				rightElbow.C0 = origElbow * prevKF[3]:Lerp(nextKF[3], t)
			end
		end
	end)
end

-----------------------------------------------
-- ★ 피격 리액션 (신규!)
-----------------------------------------------
local function victimReaction(character)
	if not character then return end

	-- 목 스냅 (머리가 옆으로 확 돌아감)
	local neck = nil
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name == "Neck" then
			neck = desc
			break
		end
	end

	if neck then
		local origC0 = neck.C0
		local snapDuration = 0.06
		local holdDuration = 0.2
		local recoverDuration = 0.5
		local totalDuration = snapDuration + holdDuration + recoverDuration
		local startTime = tick()

		local conn
		conn = RunService.Heartbeat:Connect(function()
			if not neck or not neck.Parent then
				conn:Disconnect()
				return
			end

			local elapsed = tick() - startTime
			if elapsed >= totalDuration then
				conn:Disconnect()
				neck.C0 = origC0
				return
			end

			if elapsed < snapDuration then
				local t = elapsed / snapDuration
				neck.C0 = origC0 * CFrame.Angles(math.rad(10) * t, math.rad(-50) * t, math.rad(20) * t)
			elseif elapsed < snapDuration + holdDuration then
				-- 진동하며 홀드
				local holdT = (elapsed - snapDuration) / holdDuration
				local vibrate = math.sin(holdT * 30) * (1 - holdT) * 5
				neck.C0 = origC0 * CFrame.Angles(math.rad(10), math.rad(-50) + math.rad(vibrate), math.rad(20))
			else
				local t = (elapsed - snapDuration - holdDuration) / recoverDuration
				t = t * t * (3 - 2 * t) -- smoothstep
				neck.C0 = origC0 * CFrame.Angles(math.rad(10) * (1 - t), math.rad(-50) * (1 - t), math.rad(20) * (1 - t))
			end
		end)
	end

	-- 살짝 뒤로 밀림
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local knockDir = root.CFrame.RightVector
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(4000, 2000, 4000)
		bv.Velocity = knockDir * 6 + Vector3.new(0, 2, 0)
		bv.Parent = root
		task.delay(0.15, function()
			if bv and bv.Parent then bv:Destroy() end
		end)
	end

	-- 별 이펙트
	local head = character:FindFirstChild("Head")
	if head then
		createStarsEffect(head)
	end
end

-----------------------------------------------
-- ★ 목 세바퀴 회전 (유지하되 victimReaction으로 교체)
-----------------------------------------------
local function spinHead(character)
	-- 이제 victimReaction이 더 나은 연출을 해주므로 그쪽으로 위임
	victimReaction(character)
end

-----------------------------------------------
-- ★ 코믹 뺨 때리기 (전면 개편!)
-----------------------------------------------
local function comicSlap(attackerChar, victimChar)
	if not victimChar then return end

	local head = victimChar:FindFirstChild("Head")
	if head then
		-- 타격 사운드
		playSound(SOUNDS.slap, head.Position, 2, 0.8)
		-- 타격 이펙트
		createSlapEffect(head.Position)
	end

	-- 공격자 팔 애니메이션
	if attackerChar then
		task.spawn(function()
			animateSlap(attackerChar)
		end)
	end

	-- 0.18초 뒤 (스윙이 도달하는 타이밍) 피격 리액션
	task.delay(0.18, function()
		victimReaction(victimChar)
	end)
end

-----------------------------------------------
-- 굴욕 말풍선
-----------------------------------------------
local function showHumiliationBubble(character, text, duration)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	local existing = head:FindFirstChild("HumiliationBubble")
	if existing then existing:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "HumiliationBubble"
	bb.Size = UDim2.new(0, 250, 0, 70)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.Parent = head

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bg.BackgroundTransparency = 0.1
	bg.Parent = bb

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 12)
	bgCorner.Parent = bg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextSize = 24
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(220, 30, 30)
	lbl.Parent = bg

	task.delay(duration or 4, function()
		if bb and bb.Parent then bb:Destroy() end
	end)
end

-----------------------------------------------
-- 굴욕 텍스트 결정
-----------------------------------------------
local function getHumiliationData(winnerStreak, sameOpponentLosses, isRevenge)
	local bubbleText = "꼴좋다~"
	local announceExtra = ""

	if isRevenge then
		bubbleText = "복수 완료!!"
		announceExtra = " (복수 성공!)"
	elseif sameOpponentLosses >= 3 then
		bubbleText = "노예 인증ㅋㅋ"
		announceExtra = " (같은 상대 " .. sameOpponentLosses .. "연패!)"
	elseif winnerStreak >= 10 then
		bubbleText = "호구 인증ㅋㅋ"
	elseif winnerStreak >= 5 then
		bubbleText = "만만하네~"
	else
		local texts = { "꼴좋다~", "아프지?ㅋ", "약하네~", "ㅋㅋㅋ" }
		bubbleText = texts[math.random(#texts)]
	end

	local streakHumiliation = nil
	if winnerStreak >= 10 then
		streakHumiliation = "냄비뚜껑"
	elseif winnerStreak >= 5 then
		streakHumiliation = "축소"
	elseif winnerStreak >= 3 then
		streakHumiliation = "호구칭호"
	end

	return bubbleText, announceExtra, streakHumiliation
end

-----------------------------------------------
-- 싱글모드 뺨 때리기
-----------------------------------------------
local soloStreak = {}

local function slapNPC(player)
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	local playerChar = player.Character

	-- ★ 개선: 공격자(플레이어)가 NPC를 때림
	comicSlap(playerChar, npc)

	local playerStreak = soloStreak[player.UserId] or 0
	local texts = { "꼴좋다~", "아프지?ㅋ", "약하네~", "ㅋㅋㅋ" }
	local bubbleText = texts[math.random(#texts)]
	if playerStreak >= 10 then
		bubbleText = "호구 NPC ㅋㅋ"
	elseif playerStreak >= 5 then
		bubbleText = "만만하네~"
	elseif playerStreak >= 3 then
		bubbleText = "꼴좋다~"
	end
	showHumiliationBubble(npc, bubbleText, 3)
end

local function slapPlayerSolo(player)
	local character = player.Character
	if not character then return end
	local npc = workspace:FindFirstChild("NPC")

	-- ★ 개선: NPC가 플레이어를 때림
	comicSlap(npc, character)

	local texts = { "에잇 아프다!", "으악!", "한판 더!", "분하다..." }
	showHumiliationBubble(character, texts[math.random(#texts)], 3)
end

-----------------------------------------------
-- PvP 큐 관리
-----------------------------------------------
local function removeFromQueue(player)
	for i, p in ipairs(pvpQueue) do
		if p == player then
			table.remove(pvpQueue, i)
			return true
		end
	end
	return false
end

local function isInQueue(player)
	for _, p in ipairs(pvpQueue) do
		if p == player then return true end
	end
	return false
end

-----------------------------------------------
-- PvP 매치 시작
-----------------------------------------------
local function startPvPMatch(playerA, playerB, isRevenge)
	local matchId = nextMatchId
	nextMatchId += 1

	pvpMatches[matchId] = {
		playerA = playerA,
		playerB = playerB,
		choiceA = nil,
		choiceB = nil,
		state = "choosing",
		isRevenge = isRevenge or false,
		winsA = 0,
		winsB = 0,
		round = 1,
	}
	playerMatch[playerA] = matchId
	playerMatch[playerB] = matchId

	local npc = workspace:FindFirstChild("NPC")
	if npc then
		local npcRoot = npc:FindFirstChild("HumanoidRootPart")
		if npcRoot then npcRoot.CFrame = CFrame.new(0, -100, 0) end
	end

	if playerA.Character then teleportCharacter(playerA.Character, CFRAME_A) end
	if playerB.Character then teleportCharacter(playerB.Character, CFRAME_B) end

	rpsPvP:FireClient(playerA, {
		action = "matched",
		opponentName = playerB.DisplayName,
		opponentId = playerB.UserId,
		side = "A",
		isRevenge = isRevenge or false,
	})
	rpsPvP:FireClient(playerB, {
		action = "matched",
		opponentName = playerA.DisplayName,
		opponentId = playerA.UserId,
		side = "B",
		isRevenge = isRevenge or false,
	})

	announce("⚔️ " .. playerA.DisplayName .. " vs " .. playerB.DisplayName .. " 대결 시작!")
end

-----------------------------------------------
-- PvP 매치 큐 체크
-----------------------------------------------
local function tryMatchFromQueue()
	while #pvpQueue >= 2 do
		local a = table.remove(pvpQueue, 1)
		local b = table.remove(pvpQueue, 1)

		if playerMatch[a] or playerMatch[b] then
			if not playerMatch[a] then table.insert(pvpQueue, 1, a) end
			if not playerMatch[b] then table.insert(pvpQueue, 1, b) end
			break
		end

		startPvPMatch(a, b, false)
	end
end

-----------------------------------------------
-- PvP 결과 처리
-----------------------------------------------
local function resolvePvPMatch(matchId)
	local match = pvpMatches[matchId]
	if not match then return end
	if not match.choiceA or not match.choiceB then return end

	local pA = match.playerA
	local pB = match.playerB
	local cA = match.choiceA
	local cB = match.choiceB

	local outcome
	if cA == cB then
		outcome = "draw"
	elseif winTable[cA] == cB then
		outcome = "a_wins"
	else
		outcome = "b_wins"
	end

	-- 비김: 같은 라운드 다시
	if outcome == "draw" then
		rpsPvP:FireClient(pA, { action = "pvp_result", outcome = "draw", myChoice = cA, opChoice = cB,
			winsMe = match.winsA, winsOp = match.winsB, round = match.round })
		rpsPvP:FireClient(pB, { action = "pvp_result", outcome = "draw", myChoice = cB, opChoice = cA,
			winsMe = match.winsB, winsOp = match.winsA, round = match.round })
		match.choiceA = nil
		match.choiceB = nil
		match.state = "choosing"
		return
	end

	-- 라운드 승자 결정
	local winner, loser
	if outcome == "a_wins" then
		winner, loser = pA, pB
		match.winsA += 1
	else
		winner, loser = pB, pA
		match.winsB += 1
	end

	local winsW = (winner == pA) and match.winsA or match.winsB
	local winsL = (loser == pA) and match.winsA or match.winsB
	local matchOver = winsW >= 2

	-- 라운드 뺨때리기 연출
	if winner.Character and loser.Character then
		comicSlap(winner.Character, loser.Character)
	end

	if not matchOver then
		-- ★ 라운드 승리 (매치 계속)
		rpsPvP:FireClient(winner, { action = "pvp_round", outcome = "win",
			myChoice = (winner == pA) and cA or cB, opChoice = (winner == pA) and cB or cA,
			winsMe = winsW, winsOp = winsL, round = match.round,
			opponentName = loser.DisplayName })
		rpsPvP:FireClient(loser, { action = "pvp_round", outcome = "lose",
			myChoice = (loser == pA) and cA or cB, opChoice = (loser == pA) and cB or cA,
			winsMe = winsL, winsOp = winsW, round = match.round,
			opponentName = winner.DisplayName })

		-- 다음 라운드 준비
		match.round += 1
		match.choiceA = nil
		match.choiceB = nil
		match.state = "choosing"
		-- 위치 리셋
		task.delay(1.5, function()
			if pA.Character then teleportCharacter(pA.Character, CFRAME_A) end
			if pB.Character then teleportCharacter(pB.Character, CFRAME_B) end
		end)
	else
		-- ★ 매치 종료!
		match.state = "resolved"

		pvpStreaks[winner.UserId] = (pvpStreaks[winner.UserId] or 0) + 1
		pvpStreaks[loser.UserId] = 0
		addLoss(loser.UserId, winner.UserId)

		local winStreak = pvpStreaks[winner.UserId]
		local sameOpLosses = getLosses(loser.UserId, winner.UserId)
		local revengeSuccess = match.isRevenge and (lastDefeatedBy[winner.UserId] == loser)
		lastDefeatedBy[loser.UserId] = winner

		local bubbleText, announceExtra, streakHumiliation = getHumiliationData(
			winStreak, sameOpLosses, revengeSuccess
		)
		showHumiliationBubble(loser.Character, bubbleText, 4)

		local announceMsg = "🔥 " .. winner.DisplayName .. "이(가) " .. loser.DisplayName .. "의 뺨을 갈겼습니다!" .. announceExtra
		if winStreak >= 3 then
			announceMsg = announceMsg .. " (" .. winStreak .. "연승!)"
		end
		announce(announceMsg)

		if match.isRevenge and not revengeSuccess then
			announce("😂 " .. loser.DisplayName .. " 복수도 실패ㅋㅋ")
		end

		rpsPvP:FireClient(winner, {
			action = "pvp_result", outcome = "win",
			myChoice = (winner == pA) and cA or cB,
			opChoice = (winner == pA) and cB or cA,
			winsMe = winsW, winsOp = winsL,
			streak = winStreak, humiliation = bubbleText,
			streakHumiliation = streakHumiliation,
			opponentName = loser.DisplayName, opponentId = loser.UserId,
			revengeSuccess = revengeSuccess,
		})
		rpsPvP:FireClient(loser, {
			action = "pvp_result", outcome = "lose",
			myChoice = (loser == pA) and cA or cB,
			opChoice = (loser == pA) and cB or cA,
			winsMe = winsL, winsOp = winsW,
			streak = 0, humiliation = bubbleText,
			streakHumiliation = streakHumiliation,
			opponentName = winner.DisplayName, opponentId = winner.UserId,
			canRevenge = true,
		})

		playerMatch[pA] = nil
		playerMatch[pB] = nil
		pvpMatches[matchId] = nil
	end
end

-----------------------------------------------
-- PvP 이벤트 처리
-----------------------------------------------
rpsPvP.OnServerEvent:Connect(function(player, data)
	if typeof(data) ~= "table" then return end
	local action = data.action

	if action == "join_queue" then
		if playerMatch[player] then return end
		if isInQueue(player) then return end
		table.insert(pvpQueue, player)
		rpsPvP:FireClient(player, { action = "queue_joined" })
		tryMatchFromQueue()

	elseif action == "leave_queue" then
		removeFromQueue(player)
		rpsPvP:FireClient(player, { action = "queue_left" })

	elseif action == "choice" then
		local choice = data.choice
		if not validChoices[choice] then return end

		local matchId = playerMatch[player]
		if not matchId then return end
		local match = pvpMatches[matchId]
		if not match or match.state ~= "choosing" then return end

		if player == match.playerA then
			match.choiceA = choice
		elseif player == match.playerB then
			match.choiceB = choice
		end

		local opponent = (player == match.playerA) and match.playerB or match.playerA
		rpsPvP:FireClient(opponent, { action = "opponent_chose" })

		if match.choiceA and match.choiceB then
			resolvePvPMatch(matchId)
		end

	elseif action == "challenge" then
		local targetId = data.targetId
		if not targetId then return end

		local target = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == targetId then
				target = p
				break
			end
		end

		if not target then
			rpsPvP:FireClient(player, { action = "challenge_failed", reason = "상대가 서버에 없습니다." })
			return
		end

		if playerMatch[target] then
			rpsPvP:FireClient(player, { action = "challenge_failed", reason = "상대가 이미 대전 중입니다." })
			return
		end

		rpsPvP:FireClient(target, {
			action = "challenge_received",
			fromName = player.DisplayName,
			fromId = player.UserId,
		})
		rpsPvP:FireClient(player, { action = "challenge_sent", targetName = target.DisplayName })

	elseif action == "challenge_reply" then
		local fromId = data.fromId
		local accepted = data.accepted

		local challenger = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == fromId then
				challenger = p
				break
			end
		end

		if not challenger then return end

		if accepted then
			removeFromQueue(player)
			removeFromQueue(challenger)
			startPvPMatch(challenger, player, true)
		else
			announce("🐔 " .. player.DisplayName .. "이(가) " .. challenger.DisplayName .. "의 도전에서 도망쳤습니다!")
			rpsPvP:FireClient(challenger, {
				action = "challenge_declined",
				targetName = player.DisplayName,
			})
		end
	end
end)

-----------------------------------------------
-- 싱글모드 이벤트
-----------------------------------------------
changeNPC.OnServerEvent:Connect(function(player, npcName)
	if npcStyles[npcName] then
		resetNPCPositions(player.Character)
		changeNPCAppearance(npcName)

		-- ★ 3판 2선승 매치 초기화
		soloMatchState[player.UserId] = {
			playerWins = 0,
			npcWins = 0,
			npcName = npcName,
			round = 1,
		}
		playerHistory[player.UserId] = {}
	end
end)

resetNPC.OnServerEvent:Connect(function(player)
	resetNPCPositions(player.Character)
end)

rpsChoice.OnServerEvent:Connect(function(player, playerChoice)
	if not validChoices[playerChoice] then return end

	local state = soloMatchState[player.UserId]
	if not state then
		-- 매치 상태 없으면 기본 생성
		state = { playerWins = 0, npcWins = 0, npcName = "학생", round = 1 }
		soloMatchState[player.UserId] = state
		playerHistory[player.UserId] = {}
	end

	-- ★ NPC AI로 선택
	local npcChoice = getNPCChoice(state.npcName, player.UserId)

	-- 히스토리 기록
	if not playerHistory[player.UserId] then playerHistory[player.UserId] = {} end
	table.insert(playerHistory[player.UserId], playerChoice)

	local outcome
	if playerChoice == npcChoice then
		outcome = "draw"
	elseif winTable[playerChoice] == npcChoice then
		outcome = "win"
		state.playerWins += 1
		slapNPC(player)
	else
		outcome = "lose"
		state.npcWins += 1
		slapPlayerSolo(player)
	end

	local matchOver = state.playerWins >= 2 or state.npcWins >= 2

	if outcome == "draw" then
		-- 비김: 같은 라운드 다시
		rpsResult:FireClient(player, {
			type = "round",
			outcome = "draw",
			npcChoice = npcChoice,
			playerChoice = playerChoice,
			playerWins = state.playerWins,
			npcWins = state.npcWins,
			round = state.round,
		})
	elseif not matchOver then
		-- ★ 라운드 승/패 (매치 계속)
		rpsResult:FireClient(player, {
			type = "round",
			outcome = outcome,
			npcChoice = npcChoice,
			playerChoice = playerChoice,
			playerWins = state.playerWins,
			npcWins = state.npcWins,
			round = state.round,
		})
		state.round += 1
		-- 다음 라운드 전 위치 리셋
		task.delay(1.5, function()
			resetNPCPositions(player.Character)
		end)
	else
		-- ★ 매치 종료!
		local finalOutcome = state.playerWins >= 2 and "win" or "lose"

		if finalOutcome == "win" then
			soloStreak[player.UserId] = (soloStreak[player.UserId] or 0) + 1
		else
			soloStreak[player.UserId] = 0
		end

		rpsResult:FireClient(player, {
			type = "match",
			outcome = finalOutcome,
			npcChoice = npcChoice,
			playerChoice = playerChoice,
			playerWins = state.playerWins,
			npcWins = state.npcWins,
			round = state.round,
		})
		soloMatchState[player.UserId] = nil
	end
end)

-----------------------------------------------
-- 플레이어 퇴장 시 정리
-----------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	removeFromQueue(player)

	local matchId = playerMatch[player]
	if matchId then
		local match = pvpMatches[matchId]
		if match then
			local opponent = (player == match.playerA) and match.playerB or match.playerA
			if opponent then
				rpsPvP:FireClient(opponent, { action = "opponent_left" })
			end
			playerMatch[match.playerA] = nil
			playerMatch[match.playerB] = nil
			pvpMatches[matchId] = nil
		end
	end

	lastDefeatedBy[player.UserId] = nil
	pvpStreaks[player.UserId] = nil
	soloMatchState[player.UserId] = nil
	playerHistory[player.UserId] = nil
end)

-----------------------------------------------
-- ★ 경기장 링 건설
-----------------------------------------------
local arenaFolder = Instance.new("Folder")
arenaFolder.Name = "Arena"
arenaFolder.Parent = workspace

-- 링 바닥 (메인 매트)
local ringFloor = Instance.new("Part")
ringFloor.Name = "RingFloor"
ringFloor.Size = Vector3.new(18, 0.4, 18)
ringFloor.Position = Vector3.new(0, 0.2, 0)
ringFloor.Anchored = true
ringFloor.Material = Enum.Material.SmoothPlastic
ringFloor.Color = Color3.fromRGB(240, 235, 220)
ringFloor.Parent = arenaFolder

-- 빨간 코너 (플레이어 쪽)
local redCorner = Instance.new("Part")
redCorner.Size = Vector3.new(5, 0.05, 5)
redCorner.Position = Vector3.new(0, 0.43, 4)
redCorner.Anchored = true
redCorner.CanCollide = false
redCorner.Material = Enum.Material.Neon
redCorner.Color = Color3.fromRGB(255, 40, 40)
redCorner.Transparency = 0.5
redCorner.Parent = arenaFolder

-- 파란 코너 (상대 쪽)
local blueCorner = Instance.new("Part")
blueCorner.Size = Vector3.new(5, 0.05, 5)
blueCorner.Position = Vector3.new(0, 0.43, -4)
blueCorner.Anchored = true
blueCorner.CanCollide = false
blueCorner.Material = Enum.Material.Neon
blueCorner.Color = Color3.fromRGB(40, 80, 255)
blueCorner.Transparency = 0.5
blueCorner.Parent = arenaFolder

-- 중앙 원형 마크
local centerRing = Instance.new("Part")
centerRing.Shape = Enum.PartType.Cylinder
centerRing.Size = Vector3.new(0.05, 8, 8)
centerRing.CFrame = CFrame.new(0, 0.43, 0) * CFrame.Angles(0, 0, math.rad(90))
centerRing.Anchored = true
centerRing.CanCollide = false
centerRing.Material = Enum.Material.Neon
centerRing.Color = Color3.fromRGB(255, 200, 50)
centerRing.Transparency = 0.6
centerRing.Parent = arenaFolder

-- 코너 포스트 4개
local postCorners = {
	Vector3.new(8, 0, 8),
	Vector3.new(-8, 0, 8),
	Vector3.new(8, 0, -8),
	Vector3.new(-8, 0, -8),
}

for i, basePos in ipairs(postCorners) do
	-- 기둥
	local post = Instance.new("Part")
	post.Name = "Post" .. i
	post.Shape = Enum.PartType.Cylinder
	post.Size = Vector3.new(6, 0.8, 0.8)
	post.CFrame = CFrame.new(basePos + Vector3.new(0, 3.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	post.Anchored = true
	post.Material = Enum.Material.Metal
	post.Color = Color3.fromRGB(200, 200, 210)
	post.Parent = arenaFolder

	-- 골드 캡
	local cap = Instance.new("Part")
	cap.Shape = Enum.PartType.Ball
	cap.Size = Vector3.new(1.3, 1.3, 1.3)
	cap.Position = basePos + Vector3.new(0, 6.5, 0)
	cap.Anchored = true
	cap.Material = Enum.Material.Metal
	cap.Color = Color3.fromRGB(255, 200, 50)
	cap.Parent = arenaFolder

	-- 포스트 조명
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 180)
	light.Brightness = 1
	light.Range = 12
	light.Parent = cap
end

-- 로프 3줄 연결
local ropeHeights = { 2, 4, 5.8 }
local ropeColors = {
	Color3.fromRGB(255, 50, 30),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 50, 30),
}

local ropePairs = {
	{ postCorners[1], postCorners[2] },
	{ postCorners[2], postCorners[4] },
	{ postCorners[4], postCorners[3] },
	{ postCorners[3], postCorners[1] },
}

for hi, height in ipairs(ropeHeights) do
	for _, pair in ipairs(ropePairs) do
		local p1 = pair[1] + Vector3.new(0, height, 0)
		local p2 = pair[2] + Vector3.new(0, height, 0)
		local mid = (p1 + p2) / 2
		local length = (p2 - p1).Magnitude

		local rope = Instance.new("Part")
		rope.Size = Vector3.new(0.15, 0.15, length)
		rope.CFrame = CFrame.lookAt(mid, p2)
		rope.Anchored = true
		rope.CanCollide = false
		rope.Material = Enum.Material.SmoothPlastic
		rope.Color = ropeColors[hi]
		rope.Parent = arenaFolder
	end
end

-- 상단 스포트라이트 2개
for _, xDir in ipairs({-1, 1}) do
	local spotPole = Instance.new("Part")
	spotPole.Size = Vector3.new(0.5, 12, 0.5)
	spotPole.Position = Vector3.new(xDir * 12, 6.4, 0)
	spotPole.Anchored = true
	spotPole.Material = Enum.Material.Metal
	spotPole.Color = Color3.fromRGB(60, 60, 70)
	spotPole.Parent = arenaFolder

	local spotHead = Instance.new("Part")
	spotHead.Size = Vector3.new(2, 1, 2)
	spotHead.Position = Vector3.new(xDir * 12, 12.8, 0)
	spotHead.Anchored = true
	spotHead.Material = Enum.Material.Metal
	spotHead.Color = Color3.fromRGB(40, 40, 50)
	spotHead.Parent = arenaFolder

	local spot = Instance.new("SpotLight")
	spot.Brightness = 3
	spot.Range = 40
	spot.Angle = 50
	spot.Face = Enum.NormalId.Bottom
	spot.Color = Color3.fromRGB(255, 240, 220)
	spot.Parent = spotHead
end

-----------------------------------------------
-- ★ 관객석 (블리처) 건설
-----------------------------------------------
local standPositions = {}

-- 양쪽 관객석 (X+ / X- 방향)
for _, side in ipairs({1, -1}) do
	for row = 1, 3 do
		local x = side * (11 + (row - 1) * 3)
		local y = 0.3 + (row - 1) * 1.8
		local zStart = -7
		local zEnd = 7

		-- 좌석 벤치
		local bench = Instance.new("Part")
		bench.Name = "Bench"
		bench.Size = Vector3.new(2.5, 0.4, zEnd - zStart + 2)
		bench.Position = Vector3.new(x, y, 0)
		bench.Anchored = true
		bench.Material = Enum.Material.SmoothPlastic
		bench.Color = row == 1 and Color3.fromRGB(80, 80, 90) or (row == 2 and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(60, 60, 70))
		bench.Parent = arenaFolder

		-- 이 줄의 관중 위치 계산 (벤치 위에 서 있음)
		local numSeats = 5
		for s = 1, numSeats do
			local z = zStart + (s - 1) * ((zEnd - zStart) / (numSeats - 1))
			table.insert(standPositions, {
				pos = Vector3.new(x, y + 3, z),
				lookAt = Vector3.new(0, 3, 0),
				side = side,
				row = row,
			})
		end
	end
end

-----------------------------------------------
-- ★ 관중 NPC 생성
-----------------------------------------------
local spectatorData = {} -- {model, origWaist, origLeftShoulder, origRightShoulder}
local cheerleaderData = {}

local spectatorUserIds = {
	1, 156, 261, 7, 8, 9, 10, 11, 12, 16, 18, 19, 20, 21, 22, 23,
	24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 2407518839,
	4450258599, 13656149,
}

local function createSpectatorNPC(position, lookAt, userId)
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)
	if not ok or not desc then return nil end

	local ok2, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok2 or not model then return nil end

	model.Name = "Spectator"
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.lookAt(position, lookAt)
		root.Anchored = true
	end

	-- 관중 위 이름표 제거 (깔끔하게)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	model.Parent = workspace:FindFirstChild("Arena") or workspace
	return model
end

local function getMotorData(model)
	local data = {}
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("Motor6D") then
			if desc.Name == "Waist" then
				data.waist = desc
				data.origWaist = desc.C0
			elseif desc.Name == "LeftShoulder" then
				data.leftShoulder = desc
				data.origLeft = desc.C0
			elseif desc.Name == "RightShoulder" then
				data.rightShoulder = desc
				data.origRight = desc.C0
			elseif desc.Name == "Neck" then
				data.neck = desc
				data.origNeck = desc.C0
			end
		end
	end
	return data
end

-- 관중 스폰 (비동기, 순차적으로 생성해서 서버 부담 최소화)
task.spawn(function()
	task.wait(3) -- 서버 로드 후 약간 대기

	-- 관중 생성
	for i, standData in ipairs(standPositions) do
		local userId = spectatorUserIds[((i - 1) % #spectatorUserIds) + 1]
		local model = createSpectatorNPC(standData.pos, standData.lookAt, userId)
		if model then
			local motors = getMotorData(model)
			motors.model = model
			motors.index = i
			table.insert(spectatorData, motors)
		end
		task.wait(0.15) -- 서버 부담 방지
	end

	-- 치어리더 4명 (링 바로 바깥 모서리)
	local cheerPositions = {
		{ pos = Vector3.new(9, 3, 9),   lookAt = Vector3.new(0, 3, 0) },
		{ pos = Vector3.new(-9, 3, 9),  lookAt = Vector3.new(0, 3, 0) },
		{ pos = Vector3.new(9, 3, -9),  lookAt = Vector3.new(0, 3, 0) },
		{ pos = Vector3.new(-9, 3, -9), lookAt = Vector3.new(0, 3, 0) },
	}

	local cheerUserIds = { 1, 156, 261, 13656149 }

	for i, cData in ipairs(cheerPositions) do
		local model = createSpectatorNPC(cData.pos, cData.lookAt, cheerUserIds[i])
		if model then
			local motors = getMotorData(model)
			motors.model = model
			motors.index = i
			table.insert(cheerleaderData, motors)
		end
		task.wait(0.2)
	end

	print("[RPS] 관중 " .. #spectatorData .. "명 + 치어리더 " .. #cheerleaderData .. "명 생성 완료!")
end)

-----------------------------------------------
-- ★ 관중 아이들 애니메이션 (상시)
-----------------------------------------------
RunService.Heartbeat:Connect(function()
	local t = tick()

	-- 관중: 가벼운 몸 흔들기
	for i, data in ipairs(spectatorData) do
		if data.waist and data.waist.Parent and data.origWaist then
			local phase = i * 0.8
			local sway = math.sin(t * 1.2 + phase) * math.rad(3)
			local nod = math.sin(t * 0.8 + phase * 1.3) * math.rad(2)
			data.waist.C0 = data.origWaist * CFrame.Angles(nod, sway, 0)
		end
	end

	-- 치어리더: 댄스 (팔 번갈아 올리기 + 허리 흔들기)
	for i, data in ipairs(cheerleaderData) do
		if data.model and data.model.Parent then
			local phase = i * math.pi / 2
			local speed = 3

			if data.leftShoulder and data.origLeft then
				local armL = math.sin(t * speed + phase) * math.rad(100) - math.rad(50)
				data.leftShoulder.C0 = data.origLeft * CFrame.Angles(armL, 0, math.rad(-15))
			end
			if data.rightShoulder and data.origRight then
				local armR = math.sin(t * speed + phase + math.pi) * math.rad(100) - math.rad(50)
				data.rightShoulder.C0 = data.origRight * CFrame.Angles(armR, 0, math.rad(15))
			end
			if data.waist and data.origWaist then
				local hipSway = math.sin(t * speed * 2 + phase) * math.rad(12)
				local bounce = math.abs(math.sin(t * speed + phase)) * math.rad(5)
				data.waist.C0 = data.origWaist * CFrame.Angles(-bounce, hipSway, 0)
			end
		end
	end
end)

-----------------------------------------------
-- ★ 관중 반응 시스템
-----------------------------------------------
local function crowdReact(reaction)
	task.spawn(function()
		for i, data in ipairs(spectatorData) do
			if not data.model or not data.model.Parent then continue end

			task.spawn(function()
				-- 랜덤 딜레이 (파도타기 효과)
				task.wait(math.random() * 0.4)

				if reaction == "cheer" then
					-- 양 팔 올리기 + 점프 흉내
					local root = data.model:FindFirstChild("HumanoidRootPart")
					local origPos = root and root.Position

					-- 팔 올리기
					if data.leftShoulder and data.origLeft then
						local startTime = tick()
						local dur = 1.5
						local conn
						conn = RunService.Heartbeat:Connect(function()
							local elapsed = tick() - startTime
							if elapsed >= dur then
								conn:Disconnect()
								if data.leftShoulder and data.leftShoulder.Parent then
									data.leftShoulder.C0 = data.origLeft
								end
								if data.rightShoulder and data.rightShoulder.Parent then
									data.rightShoulder.C0 = data.origRight
								end
								return
							end

							local t2 = elapsed / dur
							local pump
							if t2 < 0.1 then
								pump = t2 / 0.1
							elseif t2 < 0.75 then
								pump = 1 + math.sin((t2 - 0.1) * 25) * 0.15
							else
								pump = 1 - (t2 - 0.75) / 0.25
							end

							local upAngle = math.rad(-160) * pump
							if data.leftShoulder and data.leftShoulder.Parent then
								data.leftShoulder.C0 = data.origLeft * CFrame.Angles(upAngle, 0, math.rad(-10))
							end
							if data.rightShoulder and data.rightShoulder.Parent then
								data.rightShoulder.C0 = data.origRight * CFrame.Angles(upAngle, 0, math.rad(10))
							end
						end)
					end

					-- 점프 (위치 살짝 올렸다 내림)
					if root and origPos then
						local startTime = tick()
						local jumpDur = 0.6
						local conn2
						conn2 = RunService.Heartbeat:Connect(function()
							local elapsed = tick() - startTime
							if elapsed >= jumpDur then
								conn2:Disconnect()
								root.CFrame = CFrame.lookAt(origPos, Vector3.new(0, 3, 0))
								return
							end
							local t2 = elapsed / jumpDur
							local jumpH = math.sin(t2 * math.pi) * 2
							root.CFrame = CFrame.lookAt(origPos + Vector3.new(0, jumpH, 0), Vector3.new(0, 3, 0))
						end)
					end

				elseif reaction == "gasp" then
					-- 뒤로 젖히기 (놀람)
					if data.waist and data.origWaist then
						local startTime = tick()
						local dur = 1.0
						local conn
						conn = RunService.Heartbeat:Connect(function()
							local elapsed = tick() - startTime
							if elapsed >= dur then
								conn:Disconnect()
								return
							end
							local t2 = elapsed / dur
							local leanBack
							if t2 < 0.1 then
								leanBack = (t2 / 0.1) * math.rad(20)
							elseif t2 < 0.4 then
								leanBack = math.rad(20)
							else
								leanBack = math.rad(20) * (1 - (t2 - 0.4) / 0.6)
							end
							data.waist.C0 = data.origWaist * CFrame.Angles(-leanBack, 0, 0)
						end)
					end

					-- 손 올리기 (한 손만)
					local shoulder = math.random() > 0.5 and data.leftShoulder or data.rightShoulder
					local origS = math.random() > 0.5 and data.origLeft or data.origRight
					if shoulder and origS then
						local startTime = tick()
						local dur = 0.8
						local conn
						conn = RunService.Heartbeat:Connect(function()
							local elapsed = tick() - startTime
							if elapsed >= dur then
								conn:Disconnect()
								if shoulder.Parent then shoulder.C0 = origS end
								return
							end
							local t2 = elapsed / dur
							local raise = (t2 < 0.15) and (t2 / 0.15) or (1 - (t2 - 0.15) / 0.85)
							shoulder.C0 = origS * CFrame.Angles(math.rad(-80) * raise, 0, 0)
						end)
					end

				elseif reaction == "ohh" then
					-- 무승부 / 긴장감: 몸 앞으로 숙이기
					if data.waist and data.origWaist then
						local startTime = tick()
						local dur = 1.2
						local conn
						conn = RunService.Heartbeat:Connect(function()
							local elapsed = tick() - startTime
							if elapsed >= dur then
								conn:Disconnect()
								return
							end
							local t2 = elapsed / dur
							local lean = (t2 < 0.2) and (t2 / 0.2 * math.rad(15)) or (math.rad(15) * (1 - (t2 - 0.2) / 1.0))
							data.waist.C0 = data.origWaist * CFrame.Angles(lean, 0, 0)
						end)
					end
				end
			end)
		end

		-- 치어리더도 반응
		if reaction == "cheer" then
			-- 치어리더 속도 업!  (일시적으로 더 빠른 댄스)
			-- 별도 구현 필요없이, 이미 상시 애니메이션이 돌고 있음
		end
	end)
end

-- 관중 사운드 (환호)
local function playCrowdSound(soundType)
	local soundIds = {
		cheer = "rbxassetid://1837756993",
		gasp  = "rbxassetid://282954522",
	}

	local sid = soundIds[soundType]
	if not sid then return end

	-- 여러 방향에서 동시에 재생 (입체감)
	for _, xDir in ipairs({-10, 10}) do
		playSound(sid, Vector3.new(xDir, 5, 0), 0.6, 0.8 + math.random() * 0.4)
	end
end

-----------------------------------------------
-- ★ comicSlap에 관중 반응 연결
-----------------------------------------------
local _originalComicSlap = comicSlap
comicSlap = function(attackerChar, victimChar)
	_originalComicSlap(attackerChar, victimChar)

	-- 뺨 때릴 때 관중 "우와!" 반응
	task.spawn(function()
		task.wait(0.2)
		crowdReact("gasp")
		playCrowdSound("gasp")
	end)
end

-- 승리 시 관중 환호 (결과 처리에서 호출용)
local _originalSlapNPC = slapNPC
slapNPC = function(player)
	_originalSlapNPC(player)
	task.spawn(function()
		task.wait(0.8)
		crowdReact("cheer")
		playCrowdSound("cheer")
	end)
end

-- PvP 결과에서도 환호 추가
local _originalResolvePvP = resolvePvPMatch
resolvePvPMatch = function(matchId)
	local match = pvpMatches[matchId]
	_originalResolvePvP(matchId)

	-- 매치가 resolved 되었으면 (무승부 아닌 경우) 환호
	if match and match.state == "resolved" then
		task.spawn(function()
			task.wait(1)
			crowdReact("cheer")
			playCrowdSound("cheer")
		end)
	end
end

print("[RPS] 가위바위보 서버 로드 완료! (싱글 + PvP + 시네마틱 + 경기장)")
