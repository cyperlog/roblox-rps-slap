-- RPSGui.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- UI 자동 생성 스크립트 (싱글 + PvP)

local Players = game:GetService("Players")
local screenGui = script.Parent

-----------------------------------------------
-- 모드 선택 화면
-----------------------------------------------
local modeSelect = Instance.new("Frame")
modeSelect.Name = "ModeSelect"
modeSelect.Size = UDim2.new(0, 480, 0, 340)
modeSelect.Position = UDim2.new(0.5, -240, 0.5, -170)
modeSelect.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
modeSelect.BackgroundTransparency = 0.05
modeSelect.BorderSizePixel = 0
modeSelect.Visible = true
modeSelect.Parent = screenGui

local msCorner = Instance.new("UICorner")
msCorner.CornerRadius = UDim.new(0, 16)
msCorner.Parent = modeSelect

local msTopBar = Instance.new("Frame")
msTopBar.Size = UDim2.new(1, 0, 0, 4)
msTopBar.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
msTopBar.BorderSizePixel = 0
msTopBar.Parent = modeSelect

local msTitle = Instance.new("TextLabel")
msTitle.Name = "Title"
msTitle.Size = UDim2.new(1, 0, 0, 60)
msTitle.Position = UDim2.new(0, 0, 0, 15)
msTitle.BackgroundTransparency = 1
msTitle.Text = "가위바위보 뺨때리기!"
msTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
msTitle.TextSize = 32
msTitle.Font = Enum.Font.GothamBlack
msTitle.Parent = modeSelect

local msSubtitle = Instance.new("TextLabel")
msSubtitle.Size = UDim2.new(1, 0, 0, 30)
msSubtitle.Position = UDim2.new(0, 0, 0, 65)
msSubtitle.BackgroundTransparency = 1
msSubtitle.Text = "모드를 선택하세요"
msSubtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
msSubtitle.TextSize = 18
msSubtitle.Font = Enum.Font.Gotham
msSubtitle.Parent = modeSelect

-- 싱글 버튼
local soloBtn = Instance.new("TextButton")
soloBtn.Name = "SoloBtn"
soloBtn.Size = UDim2.new(0, 200, 0, 130)
soloBtn.Position = UDim2.new(0.5, -215, 0, 110)
soloBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
soloBtn.Text = ""
soloBtn.BorderSizePixel = 0
soloBtn.Parent = modeSelect

local soloBtnCorner = Instance.new("UICorner")
soloBtnCorner.CornerRadius = UDim.new(0, 14)
soloBtnCorner.Parent = soloBtn

local soloEmoji = Instance.new("TextLabel")
soloEmoji.Size = UDim2.new(1, 0, 0, 50)
soloEmoji.Position = UDim2.new(0, 0, 0, 15)
soloEmoji.BackgroundTransparency = 1
soloEmoji.Text = "🤖"
soloEmoji.TextSize = 40
soloEmoji.Parent = soloBtn

local soloLabel = Instance.new("TextLabel")
soloLabel.Size = UDim2.new(1, 0, 0, 30)
soloLabel.Position = UDim2.new(0, 0, 0, 65)
soloLabel.BackgroundTransparency = 1
soloLabel.Text = "싱글플레이"
soloLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
soloLabel.TextSize = 22
soloLabel.Font = Enum.Font.GothamBlack
soloLabel.Parent = soloBtn

local soloDesc = Instance.new("TextLabel")
soloDesc.Size = UDim2.new(1, 0, 0, 20)
soloDesc.Position = UDim2.new(0, 0, 0, 95)
soloDesc.BackgroundTransparency = 1
soloDesc.Text = "NPC 상대와 대결"
soloDesc.TextColor3 = Color3.fromRGB(200, 220, 255)
soloDesc.TextSize = 14
soloDesc.Font = Enum.Font.Gotham
soloDesc.Parent = soloBtn

-- PvP 버튼
local pvpBtn = Instance.new("TextButton")
pvpBtn.Name = "PvPBtn"
pvpBtn.Size = UDim2.new(0, 200, 0, 130)
pvpBtn.Position = UDim2.new(0.5, 15, 0, 110)
pvpBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
pvpBtn.Text = ""
pvpBtn.BorderSizePixel = 0
pvpBtn.Parent = modeSelect

local pvpBtnCorner = Instance.new("UICorner")
pvpBtnCorner.CornerRadius = UDim.new(0, 14)
pvpBtnCorner.Parent = pvpBtn

local pvpEmoji = Instance.new("TextLabel")
pvpEmoji.Size = UDim2.new(1, 0, 0, 50)
pvpEmoji.Position = UDim2.new(0, 0, 0, 15)
pvpEmoji.BackgroundTransparency = 1
pvpEmoji.Text = "⚔️"
pvpEmoji.TextSize = 40
pvpEmoji.Parent = pvpBtn

local pvpLabel = Instance.new("TextLabel")
pvpLabel.Size = UDim2.new(1, 0, 0, 30)
pvpLabel.Position = UDim2.new(0, 0, 0, 65)
pvpLabel.BackgroundTransparency = 1
pvpLabel.Text = "PvP 대전"
pvpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pvpLabel.TextSize = 22
pvpLabel.Font = Enum.Font.GothamBlack
pvpLabel.Parent = pvpBtn

local pvpDesc = Instance.new("TextLabel")
pvpDesc.Size = UDim2.new(1, 0, 0, 20)
pvpDesc.Position = UDim2.new(0, 0, 0, 95)
pvpDesc.BackgroundTransparency = 1
pvpDesc.Text = "다른 플레이어와 대결"
pvpDesc.TextColor3 = Color3.fromRGB(255, 200, 200)
pvpDesc.TextSize = 14
pvpDesc.Font = Enum.Font.Gotham
pvpDesc.Parent = pvpBtn

-- 하단 온라인 인원 표시
local onlineLabel = Instance.new("TextLabel")
onlineLabel.Name = "OnlineCount"
onlineLabel.Size = UDim2.new(1, 0, 0, 30)
onlineLabel.Position = UDim2.new(0, 0, 1, -40)
onlineLabel.BackgroundTransparency = 1
onlineLabel.Text = ""
onlineLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
onlineLabel.TextSize = 14
onlineLabel.Font = Enum.Font.Gotham
onlineLabel.Parent = modeSelect

-----------------------------------------------
-- PvP 대기 화면
-----------------------------------------------
local pvpWait = Instance.new("Frame")
pvpWait.Name = "PvPWait"
pvpWait.Size = UDim2.new(0, 400, 0, 200)
pvpWait.Position = UDim2.new(0.5, -200, 0.5, -100)
pvpWait.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
pvpWait.BackgroundTransparency = 0.05
pvpWait.BorderSizePixel = 0
pvpWait.Visible = false
pvpWait.Parent = screenGui

local pwCorner = Instance.new("UICorner")
pwCorner.CornerRadius = UDim.new(0, 16)
pwCorner.Parent = pvpWait

local pwTitle = Instance.new("TextLabel")
pwTitle.Name = "Title"
pwTitle.Size = UDim2.new(1, 0, 0, 50)
pwTitle.Position = UDim2.new(0, 0, 0, 20)
pwTitle.BackgroundTransparency = 1
pwTitle.Text = "상대를 찾는 중..."
pwTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pwTitle.TextSize = 26
pwTitle.Font = Enum.Font.GothamBold
pwTitle.Parent = pvpWait

local pwDots = Instance.new("TextLabel")
pwDots.Name = "Dots"
pwDots.Size = UDim2.new(1, 0, 0, 40)
pwDots.Position = UDim2.new(0, 0, 0, 65)
pwDots.BackgroundTransparency = 1
pwDots.Text = "⚔️"
pwDots.TextSize = 36
pwDots.Parent = pvpWait

local cancelBtn = Instance.new("TextButton")
cancelBtn.Name = "CancelBtn"
cancelBtn.Size = UDim2.new(0, 160, 0, 45)
cancelBtn.Position = UDim2.new(0.5, -80, 1, -60)
cancelBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
cancelBtn.Text = "취소"
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.TextSize = 20
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.BorderSizePixel = 0
cancelBtn.Parent = pvpWait

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 10)
cancelCorner.Parent = cancelBtn

-----------------------------------------------
-- 도전장 팝업
-----------------------------------------------
local challengePopup = Instance.new("Frame")
challengePopup.Name = "ChallengePopup"
challengePopup.Size = UDim2.new(0, 420, 0, 200)
challengePopup.Position = UDim2.new(0.5, -210, 0.5, -100)
challengePopup.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
challengePopup.BackgroundTransparency = 0.05
challengePopup.BorderSizePixel = 0
challengePopup.Visible = false
challengePopup.ZIndex = 60
challengePopup.Parent = screenGui

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 16)
cpCorner.Parent = challengePopup

local cpTopBar = Instance.new("Frame")
cpTopBar.Size = UDim2.new(1, 0, 0, 4)
cpTopBar.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
cpTopBar.BorderSizePixel = 0
cpTopBar.ZIndex = 61
cpTopBar.Parent = challengePopup

local cpTitle = Instance.new("TextLabel")
cpTitle.Name = "Title"
cpTitle.Size = UDim2.new(1, 0, 0, 40)
cpTitle.Position = UDim2.new(0, 0, 0, 15)
cpTitle.BackgroundTransparency = 1
cpTitle.Text = "도전장이 날아왔습니다!"
cpTitle.TextColor3 = Color3.fromRGB(255, 80, 50)
cpTitle.TextSize = 24
cpTitle.Font = Enum.Font.GothamBlack
cpTitle.ZIndex = 61
cpTitle.Parent = challengePopup

local cpFrom = Instance.new("TextLabel")
cpFrom.Name = "FromLabel"
cpFrom.Size = UDim2.new(1, 0, 0, 35)
cpFrom.Position = UDim2.new(0, 0, 0, 55)
cpFrom.BackgroundTransparency = 1
cpFrom.Text = ""
cpFrom.TextColor3 = Color3.fromRGB(255, 255, 255)
cpFrom.TextSize = 20
cpFrom.Font = Enum.Font.GothamBold
cpFrom.ZIndex = 61
cpFrom.Parent = challengePopup

local cpAccept = Instance.new("TextButton")
cpAccept.Name = "AcceptBtn"
cpAccept.Size = UDim2.new(0, 150, 0, 45)
cpAccept.Position = UDim2.new(0.5, -165, 1, -60)
cpAccept.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
cpAccept.Text = "받아준다!"
cpAccept.TextColor3 = Color3.fromRGB(255, 255, 255)
cpAccept.TextSize = 20
cpAccept.Font = Enum.Font.GothamBlack
cpAccept.BorderSizePixel = 0
cpAccept.ZIndex = 61
cpAccept.Parent = challengePopup

local cpAcceptCorner = Instance.new("UICorner")
cpAcceptCorner.CornerRadius = UDim.new(0, 10)
cpAcceptCorner.Parent = cpAccept

local cpDecline = Instance.new("TextButton")
cpDecline.Name = "DeclineBtn"
cpDecline.Size = UDim2.new(0, 150, 0, 45)
cpDecline.Position = UDim2.new(0.5, 15, 1, -60)
cpDecline.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
cpDecline.Text = "도망친다..."
cpDecline.TextColor3 = Color3.fromRGB(200, 200, 200)
cpDecline.TextSize = 18
cpDecline.Font = Enum.Font.GothamBold
cpDecline.BorderSizePixel = 0
cpDecline.ZIndex = 61
cpDecline.Parent = challengePopup

local cpDeclineCorner = Instance.new("UICorner")
cpDeclineCorner.CornerRadius = UDim.new(0, 10)
cpDeclineCorner.Parent = cpDecline

-----------------------------------------------
-- 서버 공지 바 (상단)
-----------------------------------------------
local announceBar = Instance.new("TextLabel")
announceBar.Name = "AnnounceBar"
announceBar.Size = UDim2.new(1, 0, 0, 40)
announceBar.Position = UDim2.new(0, 0, 0, 0)
announceBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
announceBar.BackgroundTransparency = 0.4
announceBar.Text = ""
announceBar.TextColor3 = Color3.fromRGB(255, 220, 50)
announceBar.TextSize = 18
announceBar.Font = Enum.Font.GothamBold
announceBar.Visible = false
announceBar.ZIndex = 70
announceBar.Parent = screenGui

-----------------------------------------------
-- PvP 결과 후 버튼들 (복수하기 / 메뉴로)
-----------------------------------------------
local pvpEndFrame = Instance.new("Frame")
pvpEndFrame.Name = "PvPEndFrame"
pvpEndFrame.Size = UDim2.new(0, 400, 0, 180)
pvpEndFrame.Position = UDim2.new(0.5, -200, 0.6, 0)
pvpEndFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
pvpEndFrame.BackgroundTransparency = 0.1
pvpEndFrame.BorderSizePixel = 0
pvpEndFrame.Visible = false
pvpEndFrame.Parent = screenGui

local peCorner = Instance.new("UICorner")
peCorner.CornerRadius = UDim.new(0, 14)
peCorner.Parent = pvpEndFrame

local peResult = Instance.new("TextLabel")
peResult.Name = "ResultLabel"
peResult.Size = UDim2.new(1, 0, 0, 50)
peResult.Position = UDim2.new(0, 0, 0, 10)
peResult.BackgroundTransparency = 1
peResult.Text = ""
peResult.TextColor3 = Color3.fromRGB(255, 255, 255)
peResult.TextSize = 24
peResult.Font = Enum.Font.GothamBlack
peResult.Parent = pvpEndFrame

local revengeBtn = Instance.new("TextButton")
revengeBtn.Name = "RevengeBtn"
revengeBtn.Size = UDim2.new(0, 170, 0, 50)
revengeBtn.Position = UDim2.new(0.5, -180, 0, 70)
revengeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
revengeBtn.Text = "🔥 복수하기!"
revengeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
revengeBtn.TextSize = 20
revengeBtn.Font = Enum.Font.GothamBlack
revengeBtn.BorderSizePixel = 0
revengeBtn.Visible = false
revengeBtn.Parent = pvpEndFrame

local revCorner = Instance.new("UICorner")
revCorner.CornerRadius = UDim.new(0, 12)
revCorner.Parent = revengeBtn

local menuBtn = Instance.new("TextButton")
menuBtn.Name = "MenuBtn"
menuBtn.Size = UDim2.new(0, 170, 0, 50)
menuBtn.Position = UDim2.new(0.5, 10, 0, 70)
menuBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
menuBtn.Text = "메뉴로"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.TextSize = 20
menuBtn.Font = Enum.Font.GothamBold
menuBtn.BorderSizePixel = 0
menuBtn.Parent = pvpEndFrame

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuBtn

-- 승자 전용: 다시하기 버튼 (복수 자리에)
local rematchBtn = Instance.new("TextButton")
rematchBtn.Name = "RematchBtn"
rematchBtn.Size = UDim2.new(0, 170, 0, 50)
rematchBtn.Position = UDim2.new(0.5, -180, 0, 70)
rematchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
rematchBtn.Text = "한판 더!"
rematchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rematchBtn.TextSize = 20
rematchBtn.Font = Enum.Font.GothamBlack
rematchBtn.BorderSizePixel = 0
rematchBtn.Visible = false
rematchBtn.Parent = pvpEndFrame

local rematchCorner = Instance.new("UICorner")
rematchCorner.CornerRadius = UDim.new(0, 12)
rematchCorner.Parent = rematchBtn

-- PvP 대기 안내
local pvpWaitNote = Instance.new("TextLabel")
pvpWaitNote.Name = "WaitNote"
pvpWaitNote.Size = UDim2.new(1, 0, 0, 25)
pvpWaitNote.Position = UDim2.new(0, 0, 1, -35)
pvpWaitNote.BackgroundTransparency = 1
pvpWaitNote.Text = "상대의 응답을 기다리는 중..."
pvpWaitNote.TextColor3 = Color3.fromRGB(150, 150, 150)
pvpWaitNote.TextSize = 14
pvpWaitNote.Font = Enum.Font.Gotham
pvpWaitNote.Visible = false
pvpWaitNote.Parent = pvpEndFrame

-----------------------------------------------
-- 가위바위보 프레임 (기존)
-----------------------------------------------
local frame = Instance.new("Frame")
frame.Name = "RPSFrame"
frame.Size = UDim2.new(0, 400, 0, 250)
frame.Position = UDim2.new(0.5, -200, 0.75, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "가위 바위 보!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.Parent = frame

local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "Buttons"
buttonContainer.Size = UDim2.new(1, -40, 0, 80)
buttonContainer.Position = UDim2.new(0, 20, 0, 70)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = frame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 20)
layout.Parent = buttonContainer

local choices = {
	{ name = "가위", emoji = "✌️", color = Color3.fromRGB(231, 76, 60) },
	{ name = "바위", emoji = "✊", color = Color3.fromRGB(52, 152, 219) },
	{ name = "보", emoji = "🖐️", color = Color3.fromRGB(46, 204, 113) },
}

for _, choice in ipairs(choices) do
	local btn = Instance.new("TextButton")
	btn.Name = choice.name
	btn.Size = UDim2.new(0, 100, 0, 80)
	btn.BackgroundColor3 = choice.color
	btn.Text = choice.emoji .. "\n" .. choice.name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 22
	btn.Font = Enum.Font.GothamBold
	btn.Parent = buttonContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = btn
end

local result = Instance.new("TextLabel")
result.Name = "Result"
result.Size = UDim2.new(1, 0, 0, 40)
result.Position = UDim2.new(0, 0, 0, 160)
result.BackgroundTransparency = 1
result.Text = ""
result.TextColor3 = Color3.fromRGB(255, 255, 100)
result.TextSize = 22
result.Font = Enum.Font.GothamBold
result.Parent = frame

-- 점수 표시
local score = Instance.new("TextLabel")
score.Name = "Score"
score.Size = UDim2.new(0, 200, 0, 40)
score.Position = UDim2.new(0.5, -100, 0, 10)
score.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
score.BackgroundTransparency = 0.3
score.Text = "연승: 0"
score.TextColor3 = Color3.fromRGB(255, 200, 50)
score.TextSize = 24
score.Font = Enum.Font.GothamBold
score.Parent = screenGui

local scoreCorner = Instance.new("UICorner")
scoreCorner.CornerRadius = UDim.new(0, 10)
scoreCorner.Parent = score

-----------------------------------------------
-- 캐릭터 선택 화면 (싱글모드용)
-----------------------------------------------
local charSelect = Instance.new("Frame")
charSelect.Name = "CharSelect"
charSelect.Size = UDim2.new(0, 560, 0, 440)
charSelect.Position = UDim2.new(0.5, -280, 0.5, -220)
charSelect.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
charSelect.BackgroundTransparency = 0.05
charSelect.BorderSizePixel = 0
charSelect.Visible = false
charSelect.Parent = screenGui

local csCorner = Instance.new("UICorner")
csCorner.CornerRadius = UDim.new(0, 16)
csCorner.Parent = charSelect

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 4)
topBar.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
topBar.BorderSizePixel = 0
topBar.Parent = charSelect

local csTitle = Instance.new("TextLabel")
csTitle.Name = "Title"
csTitle.Size = UDim2.new(1, 0, 0, 50)
csTitle.Position = UDim2.new(0, 0, 0, 12)
csTitle.BackgroundTransparency = 1
csTitle.Text = "상대를 선택하세요!"
csTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
csTitle.TextSize = 28
csTitle.Font = Enum.Font.GothamBlack
csTitle.Parent = charSelect

local charList = Instance.new("Frame")
charList.Name = "CharList"
charList.Size = UDim2.new(1, -40, 0, 300)
charList.Position = UDim2.new(0, 20, 0, 68)
charList.BackgroundTransparency = 1
charList.Parent = charSelect

local charLayout = Instance.new("UIGridLayout")
charLayout.CellSize = UDim2.new(0, 155, 0, 140)
charLayout.CellPadding = UDim2.new(0, 12, 0, 12)
charLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
charLayout.Parent = charList

local npcCharacters = {
	{ name = "건달",     userId = 261,        desc = "동네 양아치", color = Color3.fromRGB(180, 40, 40) },
	{ name = "학생",     userId = 156,        desc = "순진한 학생", color = Color3.fromRGB(40, 120, 200) },
	{ name = "할아버지", userId = 2407518839, desc = "동네 어르신", color = Color3.fromRGB(140, 110, 60) },
	{ name = "로봇",     userId = 4450258599, desc = "AI 로봇",    color = Color3.fromRGB(80, 80, 150) },
	{ name = "닌자",     userId = 13656149,   desc = "그림자 닌자", color = Color3.fromRGB(40, 40, 40) },
	{ name = "광대",     userId = 1,          desc = "서커스 광대", color = Color3.fromRGB(200, 100, 30) },
}

for _, npcData in ipairs(npcCharacters) do
	local charBtn = Instance.new("TextButton")
	charBtn.Name = npcData.name
	charBtn.Size = UDim2.new(0, 155, 0, 140)
	charBtn.BackgroundColor3 = npcData.color
	charBtn.Text = ""
	charBtn.BorderSizePixel = 0
	charBtn.AutoButtonColor = true
	charBtn.Parent = charList

	local charBtnCorner = Instance.new("UICorner")
	charBtnCorner.CornerRadius = UDim.new(0, 12)
	charBtnCorner.Parent = charBtn

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"
	avatarImg.Size = UDim2.new(0, 80, 0, 80)
	avatarImg.Position = UDim2.new(0.5, -40, 0, 8)
	avatarImg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	avatarImg.BackgroundTransparency = 0.3
	avatarImg.Image = ""
	avatarImg.Parent = charBtn

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 40)
	imgCorner.Parent = avatarImg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 0, 0, 92)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = charBtn

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0, 18)
	descLabel.Position = UDim2.new(0, 0, 0, 114)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = npcData.desc
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 13
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = charBtn

	task.spawn(function()
		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				npcData.userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		if success and content then
			avatarImg.Image = content
		end
	end)
end

local startBtn = Instance.new("TextButton")
startBtn.Name = "StartBtn"
startBtn.Size = UDim2.new(0, 220, 0, 50)
startBtn.Position = UDim2.new(0.5, -110, 1, -62)
startBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
startBtn.Text = "대결 시작!"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 24
startBtn.Font = Enum.Font.GothamBlack
startBtn.BorderSizePixel = 0
startBtn.Parent = charSelect

local startBtnCorner = Instance.new("UICorner")
startBtnCorner.CornerRadius = UDim.new(0, 12)
startBtnCorner.Parent = startBtn

-- 뒤로가기 버튼
local backBtn = Instance.new("TextButton")
backBtn.Name = "BackBtn"
backBtn.Size = UDim2.new(0, 100, 0, 40)
backBtn.Position = UDim2.new(1, -115, 0, 10)
backBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
backBtn.Text = "← 뒤로"
backBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
backBtn.TextSize = 16
backBtn.Font = Enum.Font.GothamBold
backBtn.BorderSizePixel = 0
backBtn.Parent = charSelect

local backBtnCorner = Instance.new("UICorner")
backBtnCorner.CornerRadius = UDim.new(0, 8)
backBtnCorner.Parent = backBtn

-----------------------------------------------
-- 연승 팝업
-----------------------------------------------
local streakPopup = Instance.new("TextLabel")
streakPopup.Name = "StreakPopup"
streakPopup.Size = UDim2.new(1, 0, 0, 80)
streakPopup.Position = UDim2.new(0, 0, 0.35, 0)
streakPopup.BackgroundTransparency = 1
streakPopup.Text = ""
streakPopup.TextColor3 = Color3.fromRGB(255, 80, 30)
streakPopup.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
streakPopup.TextStrokeTransparency = 0
streakPopup.TextSize = 48
streakPopup.Font = Enum.Font.GothamBlack
streakPopup.Visible = false
streakPopup.ZIndex = 50
streakPopup.Parent = screenGui
