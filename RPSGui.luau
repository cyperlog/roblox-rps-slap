-- RPSGui.luau
-- StarterGui > ScreenGui 안에 LocalScript로 넣기
-- UI 자동 생성 스크립트

local Players = game:GetService("Players")
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
-- 캐릭터 선택 화면 (아바타 썸네일 포함)
-----------------------------------------------
local charSelect = Instance.new("Frame")
charSelect.Name = "CharSelect"
charSelect.Size = UDim2.new(0, 560, 0, 440)
charSelect.Position = UDim2.new(0.5, -280, 0.5, -220)
charSelect.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
charSelect.BackgroundTransparency = 0.05
charSelect.BorderSizePixel = 0
charSelect.Visible = true
charSelect.Parent = screenGui

local csCorner = Instance.new("UICorner")
csCorner.CornerRadius = UDim.new(0, 16)
csCorner.Parent = charSelect

-- 상단 장식 바
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 4)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(255, 80, 50)
topBar.BorderSizePixel = 0
topBar.Parent = charSelect

-- 제목
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

-- 캐릭터 리스트 컨테이너
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

-- NPC 캐릭터 목록 (userId로 아바타 썸네일 로드)
local npcCharacters = {
	{ name = "건달",     userId = 261,        desc = "동네 양아치", color = Color3.fromRGB(180, 40, 40) },
	{ name = "학생",     userId = 156,        desc = "순진한 학생", color = Color3.fromRGB(40, 120, 200) },
	{ name = "할아버지", userId = 2407518839, desc = "동네 어르신", color = Color3.fromRGB(140, 110, 60) },
	{ name = "로봇",     userId = 4450258599, desc = "AI 로봇",    color = Color3.fromRGB(80, 80, 150) },
	{ name = "닌자",     userId = 13656149,   desc = "그림자 닌자", color = Color3.fromRGB(40, 40, 40) },
	{ name = "광대",     userId = 1,          desc = "서커스 광대", color = Color3.fromRGB(200, 100, 30) },
}

for _, npcData in ipairs(npcCharacters) do
	-- 카드 버튼
	local charBtn = Instance.new("TextButton")
	charBtn.Name = npcData.name
	charBtn.Size = UDim2.new(0, 155, 0, 140)
	charBtn.BackgroundColor3 = npcData.color
	charBtn.Text = ""  -- 텍스트는 별도 라벨로
	charBtn.BorderSizePixel = 0
	charBtn.AutoButtonColor = true
	charBtn.Parent = charList

	local charBtnCorner = Instance.new("UICorner")
	charBtnCorner.CornerRadius = UDim.new(0, 12)
	charBtnCorner.Parent = charBtn

	-- 아바타 이미지 (상단)
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"
	avatarImg.Size = UDim2.new(0, 80, 0, 80)
	avatarImg.Position = UDim2.new(0.5, -40, 0, 8)
	avatarImg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	avatarImg.BackgroundTransparency = 0.3
	avatarImg.Image = ""  -- 나중에 로드
	avatarImg.Parent = charBtn

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 40) -- 원형
	imgCorner.Parent = avatarImg

	-- 이름 라벨
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 0, 0, 92)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcData.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = charBtn

	-- 설명 라벨
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 0, 18)
	descLabel.Position = UDim2.new(0, 0, 0, 114)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = npcData.desc
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 13
	descLabel.Font = Enum.Font.Gotham
	descLabel.Parent = charBtn

	-- 아바타 썸네일 비동기 로드
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

-- 시작 버튼
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

-----------------------------------------------
-- 연승 팝업 (화면 중앙에 크게 뜨는 텍스트)
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
