-- RPSGui.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- UI 자동 생성 스크립트

local screenGui = script.Parent

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
-- 캐릭터 선택 화면
-----------------------------------------------
local charSelect = Instance.new("Frame")
charSelect.Name = "CharSelect"
charSelect.Size = UDim2.new(0, 500, 0, 380)
charSelect.Position = UDim2.new(0.5, -250, 0.5, -190)
charSelect.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
charSelect.BackgroundTransparency = 0.1
charSelect.BorderSizePixel = 0
charSelect.Visible = true
charSelect.Parent = screenGui

local csCorner = Instance.new("UICorner")
csCorner.CornerRadius = UDim.new(0, 16)
csCorner.Parent = charSelect

-- 제목
local csTitle = Instance.new("TextLabel")
csTitle.Name = "Title"
csTitle.Size = UDim2.new(1, 0, 0, 50)
csTitle.Position = UDim2.new(0, 0, 0, 10)
csTitle.BackgroundTransparency = 1
csTitle.Text = "상대를 선택하세요!"
csTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
csTitle.TextSize = 26
csTitle.Font = Enum.Font.GothamBold
csTitle.Parent = charSelect

-- 캐릭터 리스트 컨테이너
local charList = Instance.new("Frame")
charList.Name = "CharList"
charList.Size = UDim2.new(1, -40, 0, 220)
charList.Position = UDim2.new(0, 20, 0, 65)
charList.BackgroundTransparency = 1
charList.Parent = charSelect

local charLayout = Instance.new("UIGridLayout")
charLayout.CellSize = UDim2.new(0, 130, 0, 100)
charLayout.CellPadding = UDim2.new(0, 15, 0, 15)
charLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
charLayout.Parent = charList

-- NPC 캐릭터 목록
local npcCharacters = {
	{ name = "건달", emoji = "😎", desc = "동네 양아치", color = Color3.fromRGB(200, 50, 50) },
	{ name = "학생", emoji = "🧑‍🎓", desc = "순진한 학생", color = Color3.fromRGB(50, 150, 220) },
	{ name = "할아버지", emoji = "👴", desc = "동네 어르신", color = Color3.fromRGB(160, 130, 80) },
	{ name = "로봇", emoji = "🤖", desc = "AI 로봇", color = Color3.fromRGB(100, 100, 180) },
	{ name = "닌자", emoji = "🥷", desc = "그림자 닌자", color = Color3.fromRGB(50, 50, 50) },
	{ name = "광대", emoji = "🤡", desc = "서커스 광대", color = Color3.fromRGB(220, 120, 50) },
}

for _, npcData in ipairs(npcCharacters) do
	local charBtn = Instance.new("TextButton")
	charBtn.Name = npcData.name
	charBtn.Size = UDim2.new(0, 130, 0, 100)
	charBtn.BackgroundColor3 = npcData.color
	charBtn.Text = npcData.emoji .. "\n" .. npcData.name .. "\n" .. npcData.desc
	charBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	charBtn.TextSize = 16
	charBtn.Font = Enum.Font.GothamBold
	charBtn.BorderSizePixel = 0
	charBtn.Parent = charList

	local charBtnCorner = Instance.new("UICorner")
	charBtnCorner.CornerRadius = UDim.new(0, 12)
	charBtnCorner.Parent = charBtn
end

-- 시작 버튼
local startBtn = Instance.new("TextButton")
startBtn.Name = "StartBtn"
startBtn.Size = UDim2.new(0, 200, 0, 50)
startBtn.Position = UDim2.new(0.5, -100, 1, -65)
startBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
startBtn.Text = "대결 시작!"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 24
startBtn.Font = Enum.Font.GothamBold
startBtn.BorderSizePixel = 0
startBtn.Parent = charSelect

local startBtnCorner = Instance.new("UICorner")
startBtnCorner.CornerRadius = UDim.new(0, 12)
startBtnCorner.Parent = startBtn
