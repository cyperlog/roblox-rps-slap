-- RPSServer.luau
-- ServerScriptService에 Script로 넣기
-- 서버: 가위바위보 싱글 + PvP + 굴욕 + 복수 시스템

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-----------------------------------------------
-- 효과음
-----------------------------------------------
local SOUNDS = {
	slap = "rbxassetid://5765933873",
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

-- 싱글모드
local rpsChoice = getOrCreate("RPSChoice", "RemoteEvent")
local rpsResult = getOrCreate("RPSResult", "RemoteEvent")
local changeNPC = getOrCreate("ChangeNPC", "RemoteEvent")
local resetNPC = getOrCreate("ResetNPC", "RemoteEvent")

-- PvP
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
-- PvP 상태
-----------------------------------------------
local pvpQueue = {}            -- 대기열 {player, ...}
local pvpMatches = {}          -- matchId → {playerA, playerB, choiceA, choiceB, state}
local playerMatch = {}         -- player → matchId
local nextMatchId = 1

-- 라이벌/굴욕 추적
local rivalry = {}             -- "idA_idB" → {losses_a=0, losses_b=0}
local pvpStreaks = {}          -- playerId → 연승 수
local lastDefeatedBy = {}      -- playerId → opponent Player (복수 대상)

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
-- NPC 외형 변경 (싱글모드)
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
-- 파티클/이펙트
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
-- 별 빙빙 이펙트
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
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(255, 150, 0),
		Color3.fromRGB(255, 255, 100),
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

	local radius = 2.0
	local spinSpeed = 8
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
			local angle = elapsed * spinSpeed + (i - 1) * math.rad(120)
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			star.Position = centerPos + Vector3.new(x, bobY, z)
			star.Transparency = 1 - fade
			local pulse = 0.6 + 0.3 * math.sin(elapsed * 10 + i)
			star.Size = Vector3.new(pulse, pulse, 0.2)
		end
	end)
end

-----------------------------------------------
-- 목 세바퀴 회전
-----------------------------------------------
local function spinHead(character)
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 별 이펙트는 항상 표시
	createStarsEffect(head)

	-- Neck Motor6D 찾기 (없으면 별만 나옴)
	local neck = nil
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name == "Neck" then
			neck = desc
			break
		end
	end

	if not neck then return end

	local originalC0 = neck.C0
	local spinDuration = 0.8
	local totalSpins = 3
	local startTime = tick()

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

		local eased = 1 - (1 - t) * (1 - t)
		local angle = eased * totalSpins * math.pi * 2
		neck.C0 = originalC0 * CFrame.Angles(0, angle, math.sin(angle * 0.5) * math.rad(15))
	end)
end

-----------------------------------------------
-- 코믹 뺨 때리기 (공통)
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
-- 굴욕 말풍선 (패자 머리 위)
-----------------------------------------------
local function showHumiliationBubble(character, text, duration)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 기존 말풍선 제거
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

	-- 연승별 추가 굴욕
	local streakHumiliation = nil
	if winnerStreak >= 10 then
		streakHumiliation = "냄비뚜껑"   -- 클라이언트에서 처리
	elseif winnerStreak >= 5 then
		streakHumiliation = "축소"       -- 캐릭터 크기 축소
	elseif winnerStreak >= 3 then
		streakHumiliation = "호구칭호"   -- 머리위 칭호
	end

	return bubbleText, announceExtra, streakHumiliation
end

-----------------------------------------------
-- 싱글모드 뺨 때리기 (굴욕 포함)
-----------------------------------------------
local soloStreak = {}  -- playerId → 연승 수

local function slapNPC(player)
	local npc = workspace:FindFirstChild("NPC")
	if not npc then return end
	comicSlap(npc)

	-- NPC에게 굴욕 말풍선
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
	comicSlap(character)

	-- 플레이어에게 굴욕 말풍선
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
	}
	playerMatch[playerA] = matchId
	playerMatch[playerB] = matchId

	-- NPC 숨기기
	local npc = workspace:FindFirstChild("NPC")
	if npc then
		local npcRoot = npc:FindFirstChild("HumanoidRootPart")
		if npcRoot then npcRoot.CFrame = CFrame.new(0, -100, 0) end
	end

	-- 양쪽 플레이어 위치 배치
	if playerA.Character then teleportCharacter(playerA.Character, CFRAME_A) end
	if playerB.Character then teleportCharacter(playerB.Character, CFRAME_B) end

	-- 양쪽에 매치 시작 알림
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
-- PvP 매치 큐 체크 (2명 모이면 매칭)
-----------------------------------------------
local function tryMatchFromQueue()
	while #pvpQueue >= 2 do
		local a = table.remove(pvpQueue, 1)
		local b = table.remove(pvpQueue, 1)

		-- 이미 매치 중이면 스킵
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

	match.state = "resolved"

	local pA = match.playerA
	local pB = match.playerB
	local cA = match.choiceA
	local cB = match.choiceB

	local outcome -- A 기준
	if cA == cB then
		outcome = "draw"
	elseif winTable[cA] == cB then
		outcome = "a_wins"
	else
		outcome = "b_wins"
	end

	if outcome == "draw" then
		rpsPvP:FireClient(pA, { action = "pvp_result", outcome = "draw", myChoice = cA, opChoice = cB })
		rpsPvP:FireClient(pB, { action = "pvp_result", outcome = "draw", myChoice = cB, opChoice = cA })
		-- 다시 choosing 상태로
		match.choiceA = nil
		match.choiceB = nil
		match.state = "choosing"
		return
	end

	local winner, loser, winChoice, loseChoice
	if outcome == "a_wins" then
		winner, loser = pA, pB
		winChoice, loseChoice = cA, cB
	else
		winner, loser = pB, pA
		winChoice, loseChoice = cB, cA
	end

	-- 연승/라이벌 업데이트
	pvpStreaks[winner.UserId] = (pvpStreaks[winner.UserId] or 0) + 1
	pvpStreaks[loser.UserId] = 0
	addLoss(loser.UserId, winner.UserId)

	local winStreak = pvpStreaks[winner.UserId]
	local sameOpLosses = getLosses(loser.UserId, winner.UserId)
	local isRevenge = match.isRevenge and (winner == pA or winner == pB)
	-- 복수 성공 = 복수 도전자가 이김
	local revengeSuccess = match.isRevenge and (lastDefeatedBy[winner.UserId] == loser)

	lastDefeatedBy[loser.UserId] = winner

	-- 굴욕 데이터
	local bubbleText, announceExtra, streakHumiliation = getHumiliationData(
		winStreak, sameOpLosses, revengeSuccess
	)

	-- 패자에게 뺨 + 굴욕
	if loser.Character then
		comicSlap(loser.Character)
		showHumiliationBubble(loser.Character, bubbleText, 4)
	end

	-- 서버 공지
	local announceMsg = "🔥 " .. winner.DisplayName .. "이(가) " .. loser.DisplayName .. "의 뺨을 갈겼습니다!" .. announceExtra
	if winStreak >= 3 then
		announceMsg = announceMsg .. " (" .. winStreak .. "연승!)"
	end
	announce(announceMsg)

	-- 복수 실패 공지
	if match.isRevenge and not revengeSuccess then
		announce("😂 " .. loser.DisplayName .. " 복수도 실패ㅋㅋ")
	end

	-- 양쪽에 결과 전송
	rpsPvP:FireClient(winner, {
		action = "pvp_result",
		outcome = "win",
		myChoice = (winner == pA) and cA or cB,
		opChoice = (winner == pA) and cB or cA,
		streak = winStreak,
		humiliation = bubbleText,
		streakHumiliation = streakHumiliation,
		opponentName = loser.DisplayName,
		opponentId = loser.UserId,
		revengeSuccess = revengeSuccess,
	})

	rpsPvP:FireClient(loser, {
		action = "pvp_result",
		outcome = "lose",
		myChoice = (loser == pA) and cA or cB,
		opChoice = (loser == pA) and cB or cA,
		streak = 0,
		humiliation = bubbleText,
		streakHumiliation = streakHumiliation,
		opponentName = winner.DisplayName,
		opponentId = winner.UserId,
		canRevenge = true,
	})

	-- 매치 정리
	playerMatch[pA] = nil
	playerMatch[pB] = nil
	pvpMatches[matchId] = nil
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

		-- 상대에게 "상대가 선택 완료" 알림
		local opponent = (player == match.playerA) and match.playerB or match.playerA
		rpsPvP:FireClient(opponent, { action = "opponent_chose" })

		-- 둘 다 선택했으면 결과 처리
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

		-- 도전장 보내기
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
			-- 양쪽 큐에서 빼기
			removeFromQueue(player)
			removeFromQueue(challenger)
			startPvPMatch(challenger, player, true)
		else
			-- 도전 거절 → 굴욕 공지!
			announce("🐔 " .. player.DisplayName .. "이(가) " .. challenger.DisplayName .. "의 도전에서 도망쳤습니다!")
			rpsPvP:FireClient(challenger, {
				action = "challenge_declined",
				targetName = player.DisplayName,
			})
		end
	end
end)

-----------------------------------------------
-- 싱글모드 이벤트 (기존)
-----------------------------------------------
changeNPC.OnServerEvent:Connect(function(player, npcName)
	if npcStyles[npcName] then
		resetNPCPositions(player.Character)
		changeNPCAppearance(npcName)
	end
end)

resetNPC.OnServerEvent:Connect(function(player)
	resetNPCPositions(player.Character)
end)

rpsChoice.OnServerEvent:Connect(function(player, playerChoice)
	if not validChoices[playerChoice] then return end

	local npcChoice = choicesList[math.random(1, 3)]
	local outcome

	if playerChoice == npcChoice then
		outcome = "draw"
	elseif winTable[playerChoice] == npcChoice then
		outcome = "win"
		soloStreak[player.UserId] = (soloStreak[player.UserId] or 0) + 1
		slapNPC(player)
	else
		outcome = "lose"
		soloStreak[player.UserId] = 0
		slapPlayerSolo(player)
	end

	rpsResult:FireClient(player, {
		outcome = outcome,
		npcChoice = npcChoice,
		playerChoice = playerChoice,
	})
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
end)

print("[RPS] 가위바위보 서버 로드 완료! (싱글 + PvP)")
