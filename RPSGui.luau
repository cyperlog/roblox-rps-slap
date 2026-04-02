-- RPSGui.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- UI 자동 생성 스크립트 (싱글 + PvP) — 시네마틱 업그레이드

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local screenGui = script.Parent

-----------------------------------------------
-- 공통 스타일 헬퍼
-----------------------------------------------
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 1.5
	s.Transparency = 0.5
	s.Parent = parent
	return s
end

local function addGradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

local function addShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -10)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

-----------------------------------------------
-- 모드 선택 화면
-----------------------------------------------
local modeSelect = Instance.new("Frame")
modeSelect.Name = "ModeSelect"
modeSelect.Size = UDim2.new(0, 500, 0, 420)
modeSelect.Position = UDim2.new(0.5, -250, 0.5, -210)
modeSelect.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
modeSelect.BackgroundTransparency = 0.02
modeSelect.BorderSizePixel = 0
modeSelect.Visible = true
modeSelect.ZIndex = 10
modeSelect.Parent = screenGui

addCorner(modeSelect, 18)
addStroke(modeSelect, Color3.fromRGB(255, 80, 50), 2)
addShadow(modeSelect)

local msTopBar = Instance.new("Frame")
msTopBar.Size = UDim2.new(1, 0, 0, 4)
msTopBar.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
msTopBar.BorderSizePixel = 0
msTopBar.ZIndex = 11
msTopBar.Parent = modeSelect
addGradient(msTopBar, Color3.fromRGB(255, 50, 30), Color3.fromRGB(255, 180, 50), 0)

local msTitle = Instance.new("TextLabel")
msTitle.Name = "Title"
msTitle.Size = UDim2.new(1, 0, 0, 60)
msTitle.Position = UDim2.new(0, 0, 0, 15)
msTitle.BackgroundTransparency = 1
msTitle.Text = "가위바위보 뺨때리기!"
msTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
msTitle.TextSize = 34
msTitle.Font = Enum.Font.GothamBlack
msTitle.ZIndex = 11
msTitle.Parent = modeSelect

local msSubtitle = Instance.new("TextLabel")
msSubtitle.Size = UDim2.new(1, 0, 0, 30)
msSubtitle.Position = UDim2.new(0, 0, 0, 68)
msSubtitle.BackgroundTransparency = 1
msSubtitle.Text = "모드를 선택하세요"
msSubtitle.TextColor3 = Color3.fromRGB(160, 160, 180)
msSubtitle.TextSize = 18
msSubtitle.Font = Enum.Font.Gotham
msSubtitle.ZIndex = 11
msSubtitle.Parent = modeSelect

-- 싱글 버튼
local soloBtn = Instance.new("TextButton")
soloBtn.Name = "SoloBtn"
soloBtn.Size = UDim2.new(0, 210, 0, 140)
soloBtn.Position = UDim2.new(0.5, -225, 0, 115)
soloBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
soloBtn.Text = ""
soloBtn.BorderSizePixel = 0
soloBtn.ZIndex = 11
soloBtn.Parent = modeSelect

addCorner(soloBtn, 14)
addStroke(soloBtn, Color3.fromRGB(80, 160, 255), 1.5)
addGradient(soloBtn, Color3.fromRGB(40, 110, 200), Color3.fromRGB(30, 70, 140))

local soloEmoji = Instance.new("TextLabel")
soloEmoji.Size = UDim2.new(1, 0, 0, 50)
soloEmoji.Position = UDim2.new(0, 0, 0, 15)
soloEmoji.BackgroundTransparency = 1
soloEmoji.Text = "🤖"
soloEmoji.TextSize = 42
soloEmoji.ZIndex = 12
soloEmoji.Parent = soloBtn

local soloLabel = Instance.new("TextLabel")
soloLabel.Size = UDim2.new(1, 0, 0, 30)
soloLabel.Position = UDim2.new(0, 0, 0, 68)
soloLabel.BackgroundTransparency = 1
soloLabel.Text = "싱글플레이"
soloLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
soloLabel.TextSize = 22
soloLabel.Font = Enum.Font.GothamBlack
soloLabel.ZIndex = 12
soloLabel.Parent = soloBtn

local soloDesc = Instance.new("TextLabel")
soloDesc.Size = UDim2.new(1, 0, 0, 20)
soloDesc.Position = UDim2.new(0, 0, 0, 100)
soloDesc.BackgroundTransparency = 1
soloDesc.Text = "NPC 상대와 대결"
soloDesc.TextColor3 = Color3.fromRGB(180, 210, 255)
soloDesc.TextSize = 14
soloDesc.Font = Enum.Font.Gotham
soloDesc.ZIndex = 12
soloDesc.Parent = soloBtn

-- PvP 버튼
local pvpBtn = Instance.new("TextButton")
pvpBtn.Name = "PvPBtn"
pvpBtn.Size = UDim2.new(0, 210, 0, 140)
pvpBtn.Position = UDim2.new(0.5, 15, 0, 115)
pvpBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 40)
pvpBtn.Text = ""
pvpBtn.BorderSizePixel = 0
pvpBtn.ZIndex = 11
pvpBtn.Parent = modeSelect

addCorner(pvpBtn, 14)
addStroke(pvpBtn, Color3.fromRGB(255, 100, 80), 1.5)
addGradient(pvpBtn, Color3.fromRGB(200, 60, 50), Color3.fromRGB(140, 30, 30))

local pvpEmoji = Instance.new("TextLabel")
pvpEmoji.Size = UDim2.new(1, 0, 0, 50)
pvpEmoji.Position = UDim2.new(0, 0, 0, 15)
pvpEmoji.BackgroundTransparency = 1
pvpEmoji.Text = "⚔️"
pvpEmoji.TextSize = 42
pvpEmoji.ZIndex = 12
pvpEmoji.Parent = pvpBtn

local pvpLabel = Instance.new("TextLabel")
pvpLabel.Size = UDim2.new(1, 0, 0, 30)
pvpLabel.Position = UDim2.new(0, 0, 0, 68)
pvpLabel.BackgroundTransparency = 1
pvpLabel.Text = "PvP 대전"
pvpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
pvpLabel.TextSize = 22
pvpLabel.Font = Enum.Font.GothamBlack
pvpLabel.ZIndex = 12
pvpLabel.Parent = pvpBtn

local pvpDesc = Instance.new("TextLabel")
pvpDesc.Size = UDim2.new(1, 0, 0, 20)
pvpDesc.Position = UDim2.new(0, 0, 0, 100)
pvpDesc.BackgroundTransparency = 1
pvpDesc.Text = "다른 플레이어와 대결"
pvpDesc.TextColor3 = Color3.fromRGB(255, 180, 180)
pvpDesc.TextSize = 14
pvpDesc.Font = Enum.Font.Gotham
pvpDesc.ZIndex = 12
pvpDesc.Parent = pvpBtn

-- 상점 버튼
local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopBtn"
shopBtn.Size = UDim2.new(0, 135, 0, 50)
shopBtn.Position = UDim2.new(0.5, -150, 0, 270)
shopBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 30)
shopBtn.Text = "상점"
shopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopBtn.TextSize = 20
shopBtn.Font = Enum.Font.GothamBlack
shopBtn.BorderSizePixel = 0
shopBtn.ZIndex = 11
shopBtn.Parent = modeSelect
addCorner(shopBtn, 10)
addGradient(shopBtn, Color3.fromRGB(200, 160, 30), Color3.fromRGB(150, 110, 10))

-- 관전 버튼
local spectateBtn = Instance.new("TextButton")
spectateBtn.Name = "SpectateBtn"
spectateBtn.Size = UDim2.new(0, 135, 0, 50)
spectateBtn.Position = UDim2.new(0.5, 15, 0, 270)
spectateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
spectateBtn.Text = "관전"
spectateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spectateBtn.TextSize = 20
spectateBtn.Font = Enum.Font.GothamBold
spectateBtn.BorderSizePixel = 0
spectateBtn.ZIndex = 11
spectateBtn.Parent = modeSelect
addCorner(spectateBtn, 10)

local onlineLabel = Instance.new("TextLabel")
onlineLabel.Name = "OnlineCount"
onlineLabel.Size = UDim2.new(1, 0, 0, 30)
onlineLabel.Position = UDim2.new(0, 0, 1, -40)
onlineLabel.BackgroundTransparency = 1
onlineLabel.Text = ""
onlineLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
onlineLabel.TextSize = 14
onlineLabel.Font = Enum.Font.Gotham
onlineLabel.ZIndex = 11
onlineLabel.Parent = modeSelect

-----------------------------------------------
-- PvP 대기 화면
-----------------------------------------------
local pvpWait = Instance.new("Frame")
pvpWait.Name = "PvPWait"
pvpWait.Size = UDim2.new(0, 420, 0, 220)
pvpWait.Position = UDim2.new(0.5, -210, 0.5, -110)
pvpWait.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
pvpWait.BackgroundTransparency = 0.02
pvpWait.BorderSizePixel = 0
pvpWait.Visible = false
pvpWait.ZIndex = 10
pvpWait.Parent = screenGui

addCorner(pvpWait, 18)
addStroke(pvpWait, Color3.fromRGB(255, 80, 50), 2)
addShadow(pvpWait)

local pwTitle = Instance.new("TextLabel")
pwTitle.Name = "Title"
pwTitle.Size = UDim2.new(1, 0, 0, 50)
pwTitle.Position = UDim2.new(0, 0, 0, 20)
pwTitle.BackgroundTransparency = 1
pwTitle.Text = "상대를 찾는 중..."
pwTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
pwTitle.TextSize = 26
pwTitle.Font = Enum.Font.GothamBold
pwTitle.ZIndex = 11
pwTitle.Parent = pvpWait

local pwDots = Instance.new("TextLabel")
pwDots.Name = "Dots"
pwDots.Size = UDim2.new(1, 0, 0, 50)
pwDots.Position = UDim2.new(0, 0, 0, 65)
pwDots.BackgroundTransparency = 1
pwDots.Text = "⚔️"
pwDots.TextSize = 40
pwDots.ZIndex = 11
pwDots.Parent = pvpWait

local cancelBtn = Instance.new("TextButton")
cancelBtn.Name = "CancelBtn"
cancelBtn.Size = UDim2.new(0, 170, 0, 48)
cancelBtn.Position = UDim2.new(0.5, -85, 1, -62)
cancelBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
cancelBtn.Text = "취소"
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.TextSize = 20
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.BorderSizePixel = 0
cancelBtn.ZIndex = 11
cancelBtn.Parent = pvpWait
addCorner(cancelBtn, 10)

-----------------------------------------------
-- 도전장 팝업
-----------------------------------------------
local challengePopup = Instance.new("Frame")
challengePopup.Name = "ChallengePopup"
challengePopup.Size = UDim2.new(0, 440, 0, 210)
challengePopup.Position = UDim2.new(0.5, -220, 0.5, -105)
challengePopup.BackgroundColor3 = Color3.fromRGB(40, 8, 8)
challengePopup.BackgroundTransparency = 0.02
challengePopup.BorderSizePixel = 0
challengePopup.Visible = false
challengePopup.ZIndex = 60
challengePopup.Parent = screenGui

addCorner(challengePopup, 18)
addStroke(challengePopup, Color3.fromRGB(255, 50, 30), 2)

local cpTopBar = Instance.new("Frame")
cpTopBar.Size = UDim2.new(1, 0, 0, 4)
cpTopBar.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
cpTopBar.BorderSizePixel = 0
cpTopBar.ZIndex = 61
cpTopBar.Parent = challengePopup
addGradient(cpTopBar, Color3.fromRGB(255, 30, 10), Color3.fromRGB(255, 100, 20), 0)

local cpTitle = Instance.new("TextLabel")
cpTitle.Name = "Title"
cpTitle.Size = UDim2.new(1, 0, 0, 40)
cpTitle.Position = UDim2.new(0, 0, 0, 15)
cpTitle.BackgroundTransparency = 1
cpTitle.Text = "도전장이 날아왔습니다!"
cpTitle.TextColor3 = Color3.fromRGB(255, 80, 50)
cpTitle.TextSize = 26
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
cpAccept.Size = UDim2.new(0, 160, 0, 48)
cpAccept.Position = UDim2.new(0.5, -175, 1, -62)
cpAccept.BackgroundColor3 = Color3.fromRGB(220, 60, 50)
cpAccept.Text = "받아준다!"
cpAccept.TextColor3 = Color3.fromRGB(255, 255, 255)
cpAccept.TextSize = 20
cpAccept.Font = Enum.Font.GothamBlack
cpAccept.BorderSizePixel = 0
cpAccept.ZIndex = 61
cpAccept.Parent = challengePopup
addCorner(cpAccept, 10)
addGradient(cpAccept, Color3.fromRGB(240, 70, 50), Color3.fromRGB(180, 40, 30))

local cpDecline = Instance.new("TextButton")
cpDecline.Name = "DeclineBtn"
cpDecline.Size = UDim2.new(0, 160, 0, 48)
cpDecline.Position = UDim2.new(0.5, 15, 1, -62)
cpDecline.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
cpDecline.Text = "도망친다..."
cpDecline.TextColor3 = Color3.fromRGB(200, 200, 200)
cpDecline.TextSize = 18
cpDecline.Font = Enum.Font.GothamBold
cpDecline.BorderSizePixel = 0
cpDecline.ZIndex = 61
cpDecline.Parent = challengePopup
addCorner(cpDecline, 10)

-----------------------------------------------
-- 서버 공지 바 (상단)
-----------------------------------------------
local announceBar = Instance.new("TextLabel")
announceBar.Name = "AnnounceBar"
announceBar.Size = UDim2.new(1, 0, 0, 44)
announceBar.Position = UDim2.new(0, 0, 0, 0)
announceBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
announceBar.BackgroundTransparency = 0.3
announceBar.Text = ""
announceBar.TextColor3 = Color3.fromRGB(255, 220, 50)
announceBar.TextSize = 18
announceBar.Font = Enum.Font.GothamBold
announceBar.Visible = false
announceBar.ZIndex = 70
announceBar.Parent = screenGui

-----------------------------------------------
-- PvP 결과 후 버튼들
-----------------------------------------------
local pvpEndFrame = Instance.new("Frame")
pvpEndFrame.Name = "PvPEndFrame"
pvpEndFrame.Size = UDim2.new(0, 420, 0, 190)
pvpEndFrame.Position = UDim2.new(0.5, -210, 0.6, 0)
pvpEndFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
pvpEndFrame.BackgroundTransparency = 0.05
pvpEndFrame.BorderSizePixel = 0
pvpEndFrame.Visible = false
pvpEndFrame.ZIndex = 10
pvpEndFrame.Parent = screenGui

addCorner(pvpEndFrame, 16)
addStroke(pvpEndFrame, Color3.fromRGB(255, 255, 255), 1)
addShadow(pvpEndFrame)

local peResult = Instance.new("TextLabel")
peResult.Name = "ResultLabel"
peResult.Size = UDim2.new(1, 0, 0, 50)
peResult.Position = UDim2.new(0, 0, 0, 10)
peResult.BackgroundTransparency = 1
peResult.Text = ""
peResult.TextColor3 = Color3.fromRGB(255, 255, 255)
peResult.TextSize = 24
peResult.Font = Enum.Font.GothamBlack
peResult.ZIndex = 11
peResult.Parent = pvpEndFrame

local revengeBtn = Instance.new("TextButton")
revengeBtn.Name = "RevengeBtn"
revengeBtn.Size = UDim2.new(0, 175, 0, 52)
revengeBtn.Position = UDim2.new(0.5, -185, 0, 72)
revengeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
revengeBtn.Text = "🔥 복수하기!"
revengeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
revengeBtn.TextSize = 20
revengeBtn.Font = Enum.Font.GothamBlack
revengeBtn.BorderSizePixel = 0
revengeBtn.Visible = false
revengeBtn.ZIndex = 11
revengeBtn.Parent = pvpEndFrame
addCorner(revengeBtn, 12)
addGradient(revengeBtn, Color3.fromRGB(220, 40, 30), Color3.fromRGB(150, 20, 20))

local menuBtn = Instance.new("TextButton")
menuBtn.Name = "MenuBtn"
menuBtn.Size = UDim2.new(0, 175, 0, 52)
menuBtn.Position = UDim2.new(0.5, 10, 0, 72)
menuBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
menuBtn.Text = "메뉴로"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.TextSize = 20
menuBtn.Font = Enum.Font.GothamBold
menuBtn.BorderSizePixel = 0
menuBtn.ZIndex = 11
menuBtn.Parent = pvpEndFrame
addCorner(menuBtn, 12)

local rematchBtn = Instance.new("TextButton")
rematchBtn.Name = "RematchBtn"
rematchBtn.Size = UDim2.new(0, 175, 0, 52)
rematchBtn.Position = UDim2.new(0.5, -185, 0, 72)
rematchBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
rematchBtn.Text = "한판 더!"
rematchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rematchBtn.TextSize = 20
rematchBtn.Font = Enum.Font.GothamBlack
rematchBtn.BorderSizePixel = 0
rematchBtn.Visible = false
rematchBtn.ZIndex = 11
rematchBtn.Parent = pvpEndFrame
addCorner(rematchBtn, 12)
addGradient(rematchBtn, Color3.fromRGB(50, 200, 110), Color3.fromRGB(30, 140, 70))

local pvpWaitNote = Instance.new("TextLabel")
pvpWaitNote.Name = "WaitNote"
pvpWaitNote.Size = UDim2.new(1, 0, 0, 25)
pvpWaitNote.Position = UDim2.new(0, 0, 1, -35)
pvpWaitNote.BackgroundTransparency = 1
pvpWaitNote.Text = "상대의 응답을 기다리는 중..."
pvpWaitNote.TextColor3 = Color3.fromRGB(130, 130, 150)
pvpWaitNote.TextSize = 14
pvpWaitNote.Font = Enum.Font.Gotham
pvpWaitNote.Visible = false
pvpWaitNote.ZIndex = 11
pvpWaitNote.Parent = pvpEndFrame

-----------------------------------------------
-- 가위바위보 프레임
-----------------------------------------------
local frame = Instance.new("Frame")
frame.Name = "RPSFrame"
frame.Size = UDim2.new(0, 420, 0, 260)
frame.Position = UDim2.new(0.5, -210, 0.72, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Visible = false
frame.ZIndex = 20
frame.Parent = screenGui

addCorner(frame, 18)
addStroke(frame, Color3.fromRGB(255, 200, 50), 2)
addShadow(frame)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "가위 바위 보!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 30
title.Font = Enum.Font.GothamBlack
title.ZIndex = 21
title.Parent = frame

local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "Buttons"
buttonContainer.Size = UDim2.new(1, -40, 0, 90)
buttonContainer.Position = UDim2.new(0, 20, 0, 65)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 21
buttonContainer.Parent = frame

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 18)
layout.Parent = buttonContainer

local choices = {
	{ name = "가위", emoji = "✌️", c1 = Color3.fromRGB(220, 60, 50), c2 = Color3.fromRGB(160, 30, 30) },
	{ name = "바위", emoji = "✊", c1 = Color3.fromRGB(50, 140, 220), c2 = Color3.fromRGB(30, 80, 150) },
	{ name = "보",   emoji = "🖐️", c1 = Color3.fromRGB(50, 190, 110), c2 = Color3.fromRGB(30, 130, 70) },
}

for _, choice in ipairs(choices) do
	local btn = Instance.new("TextButton")
	btn.Name = choice.name
	btn.Size = UDim2.new(0, 110, 0, 90)
	btn.BackgroundColor3 = choice.c1
	btn.Text = choice.emoji .. "\n" .. choice.name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 24
	btn.Font = Enum.Font.GothamBlack
	btn.ZIndex = 22
	btn.Parent = buttonContainer

	addCorner(btn, 14)
	addStroke(btn, Color3.fromRGB(255, 255, 255), 1)
	addGradient(btn, choice.c1, choice.c2)
end

local result = Instance.new("TextLabel")
result.Name = "Result"
result.Size = UDim2.new(1, 0, 0, 45)
result.Position = UDim2.new(0, 0, 0, 165)
result.BackgroundTransparency = 1
result.Text = ""
result.TextColor3 = Color3.fromRGB(255, 255, 100)
result.TextSize = 22
result.Font = Enum.Font.GothamBold
result.ZIndex = 21
result.Parent = frame

-- 점수 표시
local score = Instance.new("TextLabel")
score.Name = "Score"
score.Size = UDim2.new(0, 220, 0, 44)
score.Position = UDim2.new(0.5, -110, 0, 10)
score.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
score.BackgroundTransparency = 0.15
score.Text = "연승: 0"
score.TextColor3 = Color3.fromRGB(255, 200, 50)
score.TextSize = 24
score.Font = Enum.Font.GothamBlack
score.ZIndex = 15
score.Parent = screenGui

addCorner(score, 12)
addStroke(score, Color3.fromRGB(255, 200, 50), 1.5)

-----------------------------------------------
-- ★ 라운드 스코어 (3판 2선승)
-----------------------------------------------
local roundFrame = Instance.new("Frame")
roundFrame.Name = "RoundScore"
roundFrame.Size = UDim2.new(0, 280, 0, 65)
roundFrame.Position = UDim2.new(0.5, -140, 0, 58)
roundFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
roundFrame.BackgroundTransparency = 0.1
roundFrame.BorderSizePixel = 0
roundFrame.Visible = false
roundFrame.ZIndex = 25
roundFrame.Parent = screenGui

addCorner(roundFrame, 12)
addStroke(roundFrame, Color3.fromRGB(255, 150, 50), 1.5)

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.Size = UDim2.new(1, 0, 0, 25)
roundLabel.Position = UDim2.new(0, 0, 0, 5)
roundLabel.BackgroundTransparency = 1
roundLabel.Text = "라운드 1 / 3"
roundLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
roundLabel.TextSize = 16
roundLabel.Font = Enum.Font.GothamBold
roundLabel.ZIndex = 26
roundLabel.Parent = roundFrame

local roundDots = Instance.new("TextLabel")
roundDots.Name = "RoundDots"
roundDots.Size = UDim2.new(1, 0, 0, 30)
roundDots.Position = UDim2.new(0, 0, 0, 28)
roundDots.BackgroundTransparency = 1
roundDots.Text = "○ ○  VS  ○ ○"
roundDots.TextColor3 = Color3.fromRGB(255, 255, 255)
roundDots.TextSize = 22
roundDots.Font = Enum.Font.GothamBlack
roundDots.ZIndex = 26
roundDots.Parent = roundFrame

-----------------------------------------------
-- 캐릭터 선택 화면 (싱글모드용)
-----------------------------------------------
local charSelect = Instance.new("Frame")
charSelect.Name = "CharSelect"
charSelect.Size = UDim2.new(0, 580, 0, 460)
charSelect.Position = UDim2.new(0.5, -290, 0.5, -230)
charSelect.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
charSelect.BackgroundTransparency = 0.02
charSelect.BorderSizePixel = 0
charSelect.Visible = false
charSelect.ZIndex = 10
charSelect.Parent = screenGui

addCorner(charSelect, 18)
addStroke(charSelect, Color3.fromRGB(255, 80, 50), 2)
addShadow(charSelect)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 4)
topBar.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
topBar.BorderSizePixel = 0
topBar.ZIndex = 11
topBar.Parent = charSelect
addGradient(topBar, Color3.fromRGB(255, 50, 30), Color3.fromRGB(255, 180, 50), 0)

local csTitle = Instance.new("TextLabel")
csTitle.Name = "Title"
csTitle.Size = UDim2.new(1, 0, 0, 50)
csTitle.Position = UDim2.new(0, 0, 0, 12)
csTitle.BackgroundTransparency = 1
csTitle.Text = "상대를 선택하세요!"
csTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
csTitle.TextSize = 28
csTitle.Font = Enum.Font.GothamBlack
csTitle.ZIndex = 11
csTitle.Parent = charSelect

local charList = Instance.new("Frame")
charList.Name = "CharList"
charList.Size = UDim2.new(1, -40, 0, 310)
charList.Position = UDim2.new(0, 20, 0, 68)
charList.BackgroundTransparency = 1
charList.ZIndex = 11
charList.Parent = charSelect

local charLayout = Instance.new("UIGridLayout")
charLayout.CellSize = UDim2.new(0, 160, 0, 145)
charLayout.CellPadding = UDim2.new(0, 12, 0, 12)
charLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
charLayout.Parent = charList

local npcCharacters = {
	{ name = "건달",     userId = 261,        desc = "바위 좋아함", c1 = Color3.fromRGB(180, 40, 40), c2 = Color3.fromRGB(120, 20, 20) },
	{ name = "학생",     userId = 156,        desc = "쉬움 ★☆☆", c1 = Color3.fromRGB(40, 120, 200), c2 = Color3.fromRGB(25, 70, 140) },
	{ name = "할아버지", userId = 2407518839, desc = "보를 자주 냄", c1 = Color3.fromRGB(140, 110, 60), c2 = Color3.fromRGB(90, 70, 30) },
	{ name = "로봇",     userId = 4450258599, desc = "보통 ★★☆", c1 = Color3.fromRGB(80, 80, 150), c2 = Color3.fromRGB(50, 50, 100) },
	{ name = "닌자",     userId = 13656149,   desc = "어려움 ★★★", c1 = Color3.fromRGB(50, 50, 60), c2 = Color3.fromRGB(20, 20, 25) },
	{ name = "광대",     userId = 1,          desc = "카오스 ???", c1 = Color3.fromRGB(200, 100, 30), c2 = Color3.fromRGB(140, 60, 15) },
}

for _, npcData in ipairs(npcCharacters) do
	local charBtn = Instance.new("TextButton")
	charBtn.Name = npcData.name
	charBtn.Size = UDim2.new(0, 160, 0, 145)
	charBtn.BackgroundColor3 = npcData.c1
	charBtn.Text = ""
	charBtn.BorderSizePixel = 0
	charBtn.AutoButtonColor = true
	charBtn.ZIndex = 12
	charBtn.Parent = charList

	addCorner(charBtn, 14)
	addStroke(charBtn, Color3.fromRGB(255, 255, 255), 1)
	addGradient(charBtn, npcData.c1, npcData.c2)

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"
	avatarImg.Size = UDim2.new(0, 80, 0, 80)
	avatarImg.Position = UDim2.new(0.5, -40, 0, 8)
	avatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	avatarImg.BackgroundTransparency = 0.3
	avatarImg.Image = ""
	avatarImg.ZIndex = 13
	avatarImg.Parent = charBtn

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 40)
	imgCorner.Parent = avatarImg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 0, 0, 92)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.ZIndex = 13
	nameLabel.Parent = charBtn

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0, 18)
	descLabel.Position = UDim2.new(0, 0, 0, 116)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = npcData.desc
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	descLabel.TextSize = 13
	descLabel.Font = Enum.Font.Gotham
	descLabel.ZIndex = 13
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
startBtn.Size = UDim2.new(0, 230, 0, 54)
startBtn.Position = UDim2.new(0.5, -115, 1, -66)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 110)
startBtn.Text = "대결 시작!"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 26
startBtn.Font = Enum.Font.GothamBlack
startBtn.BorderSizePixel = 0
startBtn.ZIndex = 11
startBtn.Parent = charSelect
addCorner(startBtn, 14)
addGradient(startBtn, Color3.fromRGB(50, 210, 120), Color3.fromRGB(30, 150, 70))

local backBtn = Instance.new("TextButton")
backBtn.Name = "BackBtn"
backBtn.Size = UDim2.new(0, 100, 0, 40)
backBtn.Position = UDim2.new(1, -115, 0, 12)
backBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
backBtn.Text = "← 뒤로"
backBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
backBtn.TextSize = 16
backBtn.Font = Enum.Font.GothamBold
backBtn.BorderSizePixel = 0
backBtn.ZIndex = 11
backBtn.Parent = charSelect
addCorner(backBtn, 8)

-----------------------------------------------
-- 연승 팝업
-----------------------------------------------
local streakPopup = Instance.new("TextLabel")
streakPopup.Name = "StreakPopup"
streakPopup.Size = UDim2.new(1, 0, 0, 90)
streakPopup.Position = UDim2.new(0, 0, 0.32, 0)
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

-----------------------------------------------
-- ★ VS 오버레이 (신규)
-----------------------------------------------
local vsOverlay = Instance.new("Frame")
vsOverlay.Name = "VSOverlay"
vsOverlay.Size = UDim2.new(1, 0, 1, 0)
vsOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
vsOverlay.BackgroundTransparency = 0.25
vsOverlay.BorderSizePixel = 0
vsOverlay.Visible = false
vsOverlay.ZIndex = 80
vsOverlay.Parent = screenGui

-- 왼쪽 배경 (빨간)
local vsLeftBg = Instance.new("Frame")
vsLeftBg.Name = "LeftBg"
vsLeftBg.Size = UDim2.new(0.5, 0, 1, 0)
vsLeftBg.Position = UDim2.new(-0.5, 0, 0, 0)
vsLeftBg.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
vsLeftBg.BackgroundTransparency = 0.3
vsLeftBg.BorderSizePixel = 0
vsLeftBg.ZIndex = 81
vsLeftBg.Parent = vsOverlay

-- 오른쪽 배경 (파란)
local vsRightBg = Instance.new("Frame")
vsRightBg.Name = "RightBg"
vsRightBg.Size = UDim2.new(0.5, 0, 1, 0)
vsRightBg.Position = UDim2.new(1, 0, 0, 0)
vsRightBg.BackgroundColor3 = Color3.fromRGB(30, 80, 200)
vsRightBg.BackgroundTransparency = 0.3
vsRightBg.BorderSizePixel = 0
vsRightBg.ZIndex = 81
vsRightBg.Parent = vsOverlay

-- 플레이어 이름 (왼쪽)
local vsNameLeft = Instance.new("TextLabel")
vsNameLeft.Name = "NameLeft"
vsNameLeft.Size = UDim2.new(0.4, 0, 0, 60)
vsNameLeft.Position = UDim2.new(-0.4, 0, 0.38, 0)
vsNameLeft.BackgroundTransparency = 1
vsNameLeft.Text = "Player1"
vsNameLeft.TextColor3 = Color3.fromRGB(255, 255, 255)
vsNameLeft.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
vsNameLeft.TextStrokeTransparency = 0
vsNameLeft.TextSize = 36
vsNameLeft.Font = Enum.Font.GothamBlack
vsNameLeft.TextXAlignment = Enum.TextXAlignment.Center
vsNameLeft.ZIndex = 83
vsNameLeft.Parent = vsOverlay

-- 상대 이름 (오른쪽)
local vsNameRight = Instance.new("TextLabel")
vsNameRight.Name = "NameRight"
vsNameRight.Size = UDim2.new(0.4, 0, 0, 60)
vsNameRight.Position = UDim2.new(1, 0, 0.48, 0)
vsNameRight.BackgroundTransparency = 1
vsNameRight.Text = "Player2"
vsNameRight.TextColor3 = Color3.fromRGB(255, 255, 255)
vsNameRight.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
vsNameRight.TextStrokeTransparency = 0
vsNameRight.TextSize = 36
vsNameRight.Font = Enum.Font.GothamBlack
vsNameRight.TextXAlignment = Enum.TextXAlignment.Center
vsNameRight.ZIndex = 83
vsNameRight.Parent = vsOverlay

-- VS 텍스트
local vsText = Instance.new("TextLabel")
vsText.Name = "VSText"
vsText.Size = UDim2.new(0, 200, 0, 120)
vsText.Position = UDim2.new(0.5, -100, 0.5, -60)
vsText.BackgroundTransparency = 1
vsText.Text = "VS"
vsText.TextColor3 = Color3.fromRGB(255, 220, 50)
vsText.TextStrokeColor3 = Color3.fromRGB(180, 80, 0)
vsText.TextStrokeTransparency = 0
vsText.TextSize = 0
vsText.Font = Enum.Font.GothamBlack
vsText.TextTransparency = 1
vsText.ZIndex = 84
vsText.Parent = vsOverlay

-- 하단 "대결!" 텍스트
local vsFightText = Instance.new("TextLabel")
vsFightText.Name = "FightText"
vsFightText.Size = UDim2.new(1, 0, 0, 40)
vsFightText.Position = UDim2.new(0, 0, 0.65, 0)
vsFightText.BackgroundTransparency = 1
vsFightText.Text = "대결 시작!"
vsFightText.TextColor3 = Color3.fromRGB(255, 150, 50)
vsFightText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
vsFightText.TextStrokeTransparency = 0
vsFightText.TextSize = 0
vsFightText.Font = Enum.Font.GothamBlack
vsFightText.TextTransparency = 1
vsFightText.ZIndex = 84
vsFightText.Parent = vsOverlay

-----------------------------------------------
-- ★ 카운트다운 라벨 (신규)
-----------------------------------------------
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 0, 200)
countdownLabel.Position = UDim2.new(0, 0, 0.3, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "3"
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
countdownLabel.TextStrokeTransparency = 0
countdownLabel.TextSize = 72
countdownLabel.Font = Enum.Font.GothamBlack
countdownLabel.TextTransparency = 1
countdownLabel.Visible = false
countdownLabel.ZIndex = 85
countdownLabel.Parent = screenGui

-----------------------------------------------
-- ★ 임팩트 텍스트 (신규) — "퍽!" 등
-----------------------------------------------
local impactText = Instance.new("TextLabel")
impactText.Name = "ImpactText"
impactText.Size = UDim2.new(1, 0, 0, 200)
impactText.Position = UDim2.new(0, 0, 0.25, 0)
impactText.BackgroundTransparency = 1
impactText.Text = "퍽!"
impactText.TextColor3 = Color3.fromRGB(255, 50, 30)
impactText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
impactText.TextStrokeTransparency = 0
impactText.TextSize = 0
impactText.Font = Enum.Font.GothamBlack
impactText.TextTransparency = 1
impactText.Visible = false
impactText.Rotation = -10
impactText.ZIndex = 90
impactText.Parent = screenGui

-----------------------------------------------
-- ★ 승리/패배 배너 (신규)
-----------------------------------------------
local winBanner = Instance.new("Frame")
winBanner.Name = "WinBanner"
winBanner.Size = UDim2.new(1, 0, 0, 100)
winBanner.Position = UDim2.new(0, 0, -0.15, 0)
winBanner.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
winBanner.BackgroundTransparency = 0.1
winBanner.BorderSizePixel = 0
winBanner.Visible = false
winBanner.ZIndex = 75
winBanner.Parent = screenGui
addGradient(winBanner, Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 150, 30), 0)

local winBannerText = Instance.new("TextLabel")
winBannerText.Name = "Text"
winBannerText.Size = UDim2.new(1, 0, 1, 0)
winBannerText.BackgroundTransparency = 1
winBannerText.Text = ""
winBannerText.TextColor3 = Color3.fromRGB(40, 20, 0)
winBannerText.TextStrokeColor3 = Color3.fromRGB(255, 255, 200)
winBannerText.TextStrokeTransparency = 0.5
winBannerText.TextSize = 36
winBannerText.Font = Enum.Font.GothamBlack
winBannerText.ZIndex = 76
winBannerText.Parent = winBanner

-----------------------------------------------
-- ★ 코인 표시 (우측 상단)
-----------------------------------------------
local coinDisplay = Instance.new("TextLabel")
coinDisplay.Name = "CoinDisplay"
coinDisplay.Size = UDim2.new(0, 160, 0, 36)
coinDisplay.Position = UDim2.new(1, -170, 0, 10)
coinDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
coinDisplay.BackgroundTransparency = 0.2
coinDisplay.Text = "0"
coinDisplay.TextColor3 = Color3.fromRGB(255, 220, 50)
coinDisplay.TextSize = 20
coinDisplay.Font = Enum.Font.GothamBlack
coinDisplay.ZIndex = 15
coinDisplay.Parent = screenGui
addCorner(coinDisplay, 10)

-----------------------------------------------
-- ★ 상점 프레임
-----------------------------------------------
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 500, 0, 400)
shopFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
shopFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
shopFrame.BackgroundTransparency = 0.02
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 30
shopFrame.Parent = screenGui
addCorner(shopFrame, 18)
addStroke(shopFrame, Color3.fromRGB(255, 200, 50), 2)
addShadow(shopFrame)

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 45)
shopTitle.Position = UDim2.new(0, 0, 0, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "뺨 이펙트 상점"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 50)
shopTitle.TextSize = 26
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.ZIndex = 31
shopTitle.Parent = shopFrame

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopList"
shopList.Size = UDim2.new(1, -30, 1, -110)
shopList.Position = UDim2.new(0, 15, 0, 55)
shopList.BackgroundTransparency = 1
shopList.ScrollBarThickness = 4
shopList.ZIndex = 31
shopList.Parent = shopFrame

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.Parent = shopList

local shopCloseBtn = Instance.new("TextButton")
shopCloseBtn.Name = "CloseBtn"
shopCloseBtn.Size = UDim2.new(0, 160, 0, 44)
shopCloseBtn.Position = UDim2.new(0.5, -80, 1, -55)
shopCloseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
shopCloseBtn.Text = "닫기"
shopCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopCloseBtn.TextSize = 20
shopCloseBtn.Font = Enum.Font.GothamBold
shopCloseBtn.BorderSizePixel = 0
shopCloseBtn.ZIndex = 31
shopCloseBtn.Parent = shopFrame
addCorner(shopCloseBtn, 10)

-----------------------------------------------
-- ★ 관전 프레임
-----------------------------------------------
local spectateFrame = Instance.new("Frame")
spectateFrame.Name = "SpectateFrame"
spectateFrame.Size = UDim2.new(0, 420, 0, 300)
spectateFrame.Position = UDim2.new(0.5, -210, 0.5, -150)
spectateFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
spectateFrame.BackgroundTransparency = 0.02
spectateFrame.BorderSizePixel = 0
spectateFrame.Visible = false
spectateFrame.ZIndex = 30
spectateFrame.Parent = screenGui
addCorner(spectateFrame, 18)
addStroke(spectateFrame, Color3.fromRGB(150, 150, 200), 2)
addShadow(spectateFrame)

local specTitle = Instance.new("TextLabel")
specTitle.Size = UDim2.new(1, 0, 0, 40)
specTitle.Position = UDim2.new(0, 0, 0, 10)
specTitle.BackgroundTransparency = 1
specTitle.Text = "진행 중인 대전"
specTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
specTitle.TextSize = 24
specTitle.Font = Enum.Font.GothamBlack
specTitle.ZIndex = 31
specTitle.Parent = spectateFrame

local specList = Instance.new("ScrollingFrame")
specList.Name = "SpecList"
specList.Size = UDim2.new(1, -30, 1, -110)
specList.Position = UDim2.new(0, 15, 0, 50)
specList.BackgroundTransparency = 1
specList.ScrollBarThickness = 4
specList.ZIndex = 31
specList.Parent = spectateFrame

local specLayout = Instance.new("UIListLayout")
specLayout.Padding = UDim.new(0, 8)
specLayout.Parent = specList

local specCloseBtn = Instance.new("TextButton")
specCloseBtn.Name = "CloseBtn"
specCloseBtn.Size = UDim2.new(0, 160, 0, 44)
specCloseBtn.Position = UDim2.new(0.5, -80, 1, -55)
specCloseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
specCloseBtn.Text = "닫기"
specCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
specCloseBtn.TextSize = 20
specCloseBtn.Font = Enum.Font.GothamBold
specCloseBtn.BorderSizePixel = 0
specCloseBtn.ZIndex = 31
specCloseBtn.Parent = spectateFrame
addCorner(specCloseBtn, 10)

-- 관전 중 나가기 버튼 (관전 중 화면)
local specExitBtn = Instance.new("TextButton")
specExitBtn.Name = "SpectateExit"
specExitBtn.Size = UDim2.new(0, 160, 0, 44)
specExitBtn.Position = UDim2.new(0.5, -80, 1, -55)
specExitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
specExitBtn.Text = "관전 종료"
specExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
specExitBtn.TextSize = 20
specExitBtn.Font = Enum.Font.GothamBold
specExitBtn.BorderSizePixel = 0
specExitBtn.Visible = false
specExitBtn.ZIndex = 35
specExitBtn.Parent = screenGui
addCorner(specExitBtn, 10)

-- 관전 정보 바
local specInfoBar = Instance.new("TextLabel")
specInfoBar.Name = "SpectateInfo"
specInfoBar.Size = UDim2.new(0, 350, 0, 40)
specInfoBar.Position = UDim2.new(0.5, -175, 0, 50)
specInfoBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
specInfoBar.BackgroundTransparency = 0.2
specInfoBar.Text = ""
specInfoBar.TextColor3 = Color3.fromRGB(200, 200, 255)
specInfoBar.TextSize = 18
specInfoBar.Font = Enum.Font.GothamBold
specInfoBar.Visible = false
specInfoBar.ZIndex = 35
specInfoBar.Parent = screenGui
addCorner(specInfoBar, 10)
