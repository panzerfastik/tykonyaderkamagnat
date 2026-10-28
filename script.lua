-- Alacrity.v2.lua
-- Solara · mouse aim (mousemoverel) + esp + fly/speed · Insert
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/Alacrity.v2.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local mouseMove = mousemoverel or mouse_move_rel
local writeFile, readFile = writefile, readfile
local isFile, isFolder, makeFolder = isfile, isfolder, makefolder
local hasDrawing = Drawing ~= nil

local WIDTH, HEIGHT = 660, 470
local alive = true

local Theme = {
	accent = Color3.fromRGB(124, 92, 255),
	accent2 = Color3.fromRGB(56, 189, 248),
	window = Color3.fromRGB(11, 12, 17),
	card = Color3.fromRGB(20, 21, 28),
	inset = Color3.fromRGB(30, 31, 42),
	stroke = Color3.fromRGB(46, 47, 62),
	text = Color3.fromRGB(238, 240, 248),
	dim = Color3.fromRGB(132, 137, 156),
	faint = Color3.fromRGB(84, 88, 106),
	good = Color3.fromRGB(74, 222, 128),
	bad = Color3.fromRGB(248, 113, 113),
}

local State = {
	aim = {
		enabled = true,
		always = false,
		key = Enum.UserInputType.MouseButton2,
		part = "Head",
		mode = "Crosshair",
		fov = 140,
		smooth = 3,
		prediction = 0,
		teamCheck = true,
		wallCheck = true,
		showFov = true,
	},
	esp = {
		enabled = true,
		box = true,
		name = true,
		distance = true,
		health = true,
		tracer = false,
		teamCheck = true,
		maxDistance = 800,
	},
	move = {
		speed = false,
		speedValue = 32,
		bypass = true,
		fly = false,
		flyKey = Enum.KeyCode.F,
		flySpeed = 48,
		jumpPower = 50,
		infiniteJump = false,
		noclip = false,
		antiAfk = false,
	},
	ui = {
		key = Enum.KeyCode.Insert,
	},
}

local Syncer = {}
local connections = {}

local function splitPath(path)
	local out = {}
	for piece in string.gmatch(path, "[^%.]+") do
		table.insert(out, piece)
	end
	return out
end

local function readPath(path)
	local node = State
	for _, key in ipairs(splitPath(path)) do
		if node == nil then
			return nil
		end
		node = node[key]
	end
	return node
end

local function writePath(path, value)
	local keys = splitPath(path)
	local node = State
	for index = 1, #keys - 1 do
		node = node[keys[index]]
	end
	node[keys[#keys]] = value
end

local function setFlag(path, value)
	writePath(path, value)
	local sync = Syncer[path]
	if sync then
		sync(value)
	end
end

local function bind(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function asInstance(value)
	if typeof(value) == "Instance" then
		return value
	end
	if type(value) == "table" and typeof(value.frame) == "Instance" then
		return value.frame
	end
	return nil
end

local function create(class, props, children)
	local instance = Instance.new(class)
	for key, value in next, props or {} do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in next, children or {} do
		if typeof(child) == "Instance" then
			child.Parent = instance
		end
	end
	local parent = props and asInstance(props.Parent)
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function corner(radius, parent)
	return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function outline(color, thickness, transparency, parent)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function tween(instance, duration, props, style, direction)
	local info = TweenInfo.new(
		duration or 0.14,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
	local animation = TweenService:Create(instance, info, props)
	animation:Play()
	return animation
end

local function textLabel(parent, props)
	local merged = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = false,
	}
	for key, value in next, props or {} do
		merged[key] = value
	end
	merged.Parent = parent
	return create("TextLabel", merged)
end

local function guiParent()
	local ok, hidden = pcall(gethui)
	if ok and hidden then
		return hidden
	end
	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and core then
		return core
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local screen = create("ScreenGui", {
	Name = "Alacrity",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 9999,
	Parent = guiParent(),
})

if syn and syn.protect_gui then
	pcall(syn.protect_gui, screen)
end

local root = create("CanvasGroup", {
	Name = "Root",
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.window,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 1,
	Parent = screen,
})
corner(16, root)
outline(Color3.fromRGB(62, 63, 82), 1, 0.4, root)

local scale = create("UIScale", { Scale = 0.97, Parent = root })

local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 66),
	BackgroundTransparency = 1,
	Active = true,
	Parent = root,
})

local mark = create("Frame", {
	Size = UDim2.fromOffset(9, 9),
	Position = UDim2.fromOffset(24, 26),
	BackgroundColor3 = Theme.accent,
	BorderSizePixel = 0,
	Parent = header,
})
corner(5, mark)
create("UIGradient", {
	Color = ColorSequence.new(Theme.accent, Theme.accent2),
	Rotation = 45,
	Parent = mark,
})

textLabel(header, {
	Text = "alacrity",
	Position = UDim2.fromOffset(40, 14),
	Size = UDim2.fromOffset(240, 24),
	Font = Enum.Font.GothamBold,
	TextSize = 19,
})

textLabel(header, {
	Text = "v2 · mouse aim · movement · insert",
	Position = UDim2.fromOffset(41, 36),
	Size = UDim2.fromOffset(320, 14),
	TextSize = 10,
	TextColor3 = Theme.dim,
	Font = Enum.Font.GothamMedium,
})

local keyChip = create("Frame", {
	Size = UDim2.fromOffset(78, 24),
	Position = UDim2.new(1, -186, 0, 21),
	BackgroundColor3 = Theme.inset,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Parent = header,
})
corner(7, keyChip)
outline(Theme.stroke, 1, 0.45, keyChip)
local keyChipLabel = textLabel(keyChip, {
	Text = "INSERT",
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1, 1),
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	TextColor3 = Theme.dim,
	TextXAlignment = Enum.TextXAlignment.Center,
})

local tabStrip = create("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	Position = UDim2.fromOffset(0, 66),
	BackgroundTransparency = 1,
	Parent = root,
})

create("Frame", {
	Size = UDim2.new(1, -40, 0, 1),
	Position = UDim2.fromOffset(20, 43),
	BackgroundColor3 = Theme.stroke,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
	Parent = tabStrip,
})

local underline = create("Frame", {
	Size = UDim2.fromOffset(96, 2),
	Position = UDim2.fromOffset(22, 42),
	BackgroundColor3 = Theme.accent,
	BorderSizePixel = 0,
	Parent = tabStrip,
})
corner(1, underline)
create("UIGradient", {
	Color = ColorSequence.new(Theme.accent, Theme.accent2),
	Parent = underline,
})

local content = create("Frame", {
	Size = UDim2.new(1, -40, 1, -144),
	Position = UDim2.fromOffset(20, 112),
	BackgroundTransparency = 1,
	Parent = root,
})

local footer = create("Frame", {
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -32),
	BackgroundTransparency = 1,
	Parent = root,
})
create("Frame", {
	Size = UDim2.new(1, -40, 0, 1),
	Position = UDim2.fromOffset(20, 0),
	BackgroundColor3 = Theme.stroke,
	BackgroundTransparency = 0.65,
	BorderSizePixel = 0,
	Parent = footer,
})

local hints = textLabel(footer, {
	Text = "",
	Position = UDim2.fromOffset(22, 8),
	Size = UDim2.new(1, -44, 0, 14),
	TextSize = 10,
	TextColor3 = Theme.faint,
	Font = Enum.Font.GothamMedium,
})

local layoutOrder = 0

local function nextOrder()
	layoutOrder = layoutOrder + 1
	return layoutOrder
end

local pages = {}

local function addPage()
	local page = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.accent,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = content,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	create("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })
	table.insert(pages, page)
	return page
end

local tabButtons = {}
local activeTab
local activate

local function addTab(entry, label)
	local index = #tabButtons + 1
	local button = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(104, 44),
		Position = UDim2.fromOffset(22 + (index - 1) * 106, 0),
		Parent = tabStrip,
	})
	local label3d = textLabel(button, {
		Text = label,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Theme.dim,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local data = { entry = entry, button = button, label = label3d, index = index }

	button.MouseButton1Click:Connect(function()
		activate(data)
	end)
	button.MouseEnter:Connect(function()
		if activeTab ~= data then
			tween(label3d, 0.12, { TextColor3 = Color3.fromRGB(186, 192, 212) })
		end
	end)
	button.MouseLeave:Connect(function()
		if activeTab ~= data then
			tween(label3d, 0.12, { TextColor3 = Theme.dim })
		end
	end)

	table.insert(tabButtons, data)
	return data
end

activate = function(data)
	activeTab = data
	for _, other in ipairs(tabButtons) do
		local active = other == data
		tween(other.label, 0.16, { TextColor3 = active and Theme.text or Theme.dim })
		other.entry.Visible = active
	end
	local x = 22 + (data.index - 1) * 106 + 4
	tween(underline, 0.22, {
		Position = UDim2.fromOffset(x, 42),
		Size = UDim2.fromOffset(96, 2),
	}, Enum.EasingStyle.Quart)
end

local function addCard(parent, title)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.card,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	corner(12, card)
	outline(Theme.stroke, 1, 0.55, card)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = card,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = card,
	})

	local titleRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = card,
	})
	local dot = create("Frame", {
		Size = UDim2.fromOffset(4, 4),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = titleRow,
	})
	corner(2, dot)
	textLabel(titleRow, {
		Text = string.upper(title),
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -10, 1, 0),
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.dim,
	})
	return card
end

local function addToggle(parent, spec)
	local row = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.inset,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	textLabel(row, {
		Text = spec.text,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -46, 1, 0),
		TextSize = 12,
	})
	local track = create("Frame", {
		Size = UDim2.fromOffset(34, 16),
		Position = UDim2.new(1, -34, 0.5, -8),
		BackgroundColor3 = Theme.inset,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(8, track)
	local knob = create("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(148, 152, 170),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(6, knob)

	local function render(value)
		tween(track, 0.16, { BackgroundColor3 = value and Theme.accent or Theme.inset })
		tween(knob, 0.16, {
			Position = UDim2.fromOffset(value and 20 or 2, 2),
			BackgroundColor3 = value and Color3.new(1, 1, 1) or Color3.fromRGB(148, 152, 170),
		})
	end

	render(readPath(spec.path) and true or false)
	Syncer[spec.path] = function(value)
		render(value and true or false)
	end

	row.MouseButton1Click:Connect(function()
		local value = not readPath(spec.path)
		writePath(spec.path, value)
		render(value)
	end)
	row.MouseEnter:Connect(function()
		tween(row, 0.12, { BackgroundTransparency = 0.85 })
	end)
	row.MouseLeave:Connect(function()
		tween(row, 0.12, { BackgroundTransparency = 1 })
	end)
end

local function formatNumber(value, decimals)
	local factor = 10 ^ (decimals or 0)
	return string.format("%." .. tostring(decimals or 0) .. "f", math.floor(value * factor + 0.5) / factor)
end

local function addSlider(parent, spec)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	textLabel(row, {
		Text = spec.text,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, -90, 0, 14),
		TextSize = 12,
	})
	local valueLabel = textLabel(row, {
		Text = "",
		Position = UDim2.new(1, -90, 0, 2),
		Size = UDim2.fromOffset(90, 14),
		TextSize = 11,
		TextColor3 = Theme.dim,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = create("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = Theme.inset,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(2, track)
	local fill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(2, fill)
	create("UIGradient", {
		Color = ColorSequence.new(Theme.accent, Theme.accent2),
		Parent = fill,
	})
	local ring = create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = track,
	})
	corner(8, ring)
	outline(Theme.accent, 1, 0.6, ring)
	local knob = create("Frame", {
		Size = UDim2.fromOffset(8, 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(4, knob)

	local hit = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 22),
		Parent = row,
	})

	local decimals = spec.decimals or 0
	local step = spec.step or ((spec.max - spec.min) / 100)

	local function render(value)
		local alpha = math.clamp((value - spec.min) / (spec.max - spec.min), 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		ring.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = formatNumber(value, decimals) .. (spec.suffix or "")
	end

	local function fromX(absoluteX)
		local origin = track.AbsolutePosition.X
		local width = math.max(track.AbsoluteSize.X, 1)
		local alpha = math.clamp((absoluteX - origin) / width, 0, 1)
		local raw = spec.min + (spec.max - spec.min) * alpha
		local snapped = math.clamp(math.floor(raw / step + 0.5) * step, spec.min, spec.max)
		return math.floor(snapped * 100 + 0.5) / 100
	end

	render(readPath(spec.path))
	Syncer[spec.path] = function(value)
		render(value)
	end

	local dragging = false

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local value = fromX(input.Position.X)
			writePath(spec.path, value)
			render(value)
		end
	end)

	bind(UserInputService.InputChanged, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local value = fromX(input.Position.X)
			writePath(spec.path, value)
			render(value)
		end
	end)

	bind(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	hit.MouseEnter:Connect(function()
		tween(ring, 0.12, { Size = UDim2.fromOffset(20, 20) })
	end)
	hit.MouseLeave:Connect(function()
		if not dragging then
			tween(ring, 0.12, { Size = UDim2.fromOffset(16, 16) })
		end
	end)
end

local function addSegmented(parent, spec)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	textLabel(row, {
		Text = spec.text,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -180, 1, 0),
		TextSize = 12,
	})

	local containerWidth = 168
	local containerHeight = 24
	local count = #spec.options
	local segWidth = (containerWidth - 6) / count

	local container = create("Frame", {
		Size = UDim2.fromOffset(containerWidth, containerHeight),
		Position = UDim2.new(1, -containerWidth, 0.5, -containerHeight / 2),
		BackgroundColor3 = Theme.inset,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(7, container)

	local pill = create("Frame", {
		Size = UDim2.fromOffset(segWidth, containerHeight - 6),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Parent = container,
	})
	corner(5, pill)
	create("UIGradient", {
		Color = ColorSequence.new(Theme.accent, Theme.accent2),
		Parent = pill,
	})

	local buttons = {}

	local function render(value)
		for index, button in ipairs(buttons) do
			local active = spec.options[index] == value
			button.TextColor3 = active and Color3.new(1, 1, 1) or Theme.dim
			if active then
				tween(pill, 0.16, {
					Position = UDim2.fromOffset(3 + (index - 1) * segWidth, 3),
				})
			end
		end
	end

	for index, option in ipairs(spec.options) do
		local button = create("TextButton", {
			Text = option,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(segWidth, containerHeight),
			Position = UDim2.fromOffset(3 + (index - 1) * segWidth, 0),
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = Theme.dim,
			Parent = container,
		})
		button.MouseButton1Click:Connect(function()
			writePath(spec.path, option)
			render(option)
		end)
		table.insert(buttons, button)
	end

	render(readPath(spec.path))
	Syncer[spec.path] = function(value)
		render(value)
	end
end

local MOUSE_LABELS = {
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	MouseButton3 = "M3",
}

local function bindName(value)
	if typeof(value) ~= "EnumItem" then
		return "none"
	end
	if value.EnumType == Enum.UserInputType then
		return MOUSE_LABELS[value.Name] or value.Name
	end
	return value.Name
end

local function addKeybind(parent, spec)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	textLabel(row, {
		Text = spec.text,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -96, 1, 0),
		TextSize = 12,
	})

	local button = create("TextButton", {
		Text = bindName(readPath(spec.path)),
		AutoButtonColor = false,
		Size = UDim2.fromOffset(84, 22),
		Position = UDim2.new(1, -84, 0.5, -11),
		BackgroundColor3 = Theme.inset,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = row,
	})
	corner(6, button)
	local line = outline(Theme.stroke, 1, 0.4, button)

	local listening = false
	local armedAt = 0

	local function stop()
		listening = false
		button.Text = bindName(readPath(spec.path))
		tween(line, 0.14, { Color = Theme.stroke, Transparency = 0.4 })
	end

	button.MouseButton1Click:Connect(function()
		listening = true
		armedAt = os.clock()
		button.Text = "..."
		tween(line, 0.14, { Color = Theme.accent, Transparency = 0 })
	end)

	bind(UserInputService.InputBegan, function(input)
		if not listening or os.clock() - armedAt < 0.12 then
			return
		end
		local chosen
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				stop()
				return
			end
			chosen = input.KeyCode
		elseif input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3 then
			chosen = input.UserInputType
		end
		if chosen then
			setFlag(spec.path, chosen)
			stop()
		end
	end)

	Syncer[spec.path] = function(value)
		if not listening then
			button.Text = bindName(value)
		end
	end
end

local function addButton(parent, spec)
	local button = create("TextButton", {
		Text = spec.text,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = spec.accent and Theme.accent or Theme.inset,
		BackgroundTransparency = spec.accent and 0.02 or 0.25,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = spec.accent and Color3.new(1, 1, 1) or Theme.text,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
	corner(7, button)
	if spec.accent then
		create("UIGradient", {
			Color = ColorSequence.new(Theme.accent, Theme.accent2),
			Rotation = 20,
			Parent = button,
		})
	else
		outline(Theme.stroke, 1, 0.45, button)
	end
	local overlay = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	})
	corner(7, overlay)
	button.MouseEnter:Connect(function()
		tween(overlay, 0.12, { BackgroundTransparency = 0.92 })
	end)
	button.MouseLeave:Connect(function()
		tween(overlay, 0.12, { BackgroundTransparency = 1 })
	end)
	button.MouseButton1Click:Connect(function()
		if spec.callback then
			spec.callback()
		end
	end)
	return button
end

local function addNote(parent, text)
	local label = textLabel(parent, {
		Text = text,
		Size = UDim2.new(1, 0, 0, 14),
		TextSize = 10,
		TextColor3 = Theme.faint,
		Font = Enum.Font.GothamMedium,
		LayoutOrder = nextOrder(),
	})
	return label
end

local function addSpacer(parent, height)
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = parent,
	})
end

local aimPage = addPage()
local visualPage = addPage()
local movePage = addPage()
local configPage = addPage()

addTab(aimPage, "aim")
addTab(visualPage, "visuals")
addTab(movePage, "movement")
addTab(configPage, "config")

local card = addCard(aimPage, "aimbot")
addToggle(card, { text = "enabled", path = "aim.enabled" })
addToggle(card, { text = "always on · ignore key", path = "aim.always" })
addKeybind(card, { text = "aim key", path = "aim.key" })

card = addCard(aimPage, "targeting")
addSegmented(card, { text = "part", path = "aim.part", options = { "Head", "Torso", "Auto" } })
addSegmented(card, { text = "priority", path = "aim.mode", options = { "Crosshair", "Distance" } })
addToggle(card, { text = "team check", path = "aim.teamCheck" })
addToggle(card, { text = "wall check", path = "aim.wallCheck" })

card = addCard(aimPage, "tuning")
addSlider(card, {
	text = "fov radius",
	path = "aim.fov",
	min = 20,
	max = 420,
	step = 1,
	decimals = 0,
	suffix = " px",
})
addSlider(card, {
	text = "smoothing",
	path = "aim.smooth",
	min = 1,
	max = 20,
	step = 1,
	decimals = 0,
})
addSlider(card, {
	text = "prediction",
	path = "aim.prediction",
	min = 0,
	max = 250,
	step = 5,
	decimals = 0,
	suffix = " ms",
})
addToggle(card, { text = "draw fov circle", path = "aim.showFov" })

card = addCard(visualPage, "esp")
addToggle(card, { text = "enabled", path = "esp.enabled" })
addToggle(card, { text = "boxes", path = "esp.box" })
addToggle(card, { text = "names", path = "esp.name" })
addToggle(card, { text = "distance", path = "esp.distance" })
addToggle(card, { text = "health bar", path = "esp.health" })
addToggle(card, { text = "tracers", path = "esp.tracer" })
addToggle(card, { text = "team check", path = "esp.teamCheck" })
addSlider(card, {
	text = "max distance",
	path = "esp.maxDistance",
	min = 50,
	max = 3000,
	step = 50,
	decimals = 0,
	suffix = " m",
})

card = addCard(movePage, "speed")
addToggle(card, { text = "walk speed", path = "move.speed" })
addSlider(card, {
	text = "speed value",
	path = "move.speedValue",
	min = 16,
	max = 120,
	step = 1,
	decimals = 0,
})
addToggle(card, { text = "bypass · cap at 40", path = "move.bypass" })
addNote(card, "veloclamp + reassert every 200 ms, no gravity writes")

card = addCard(movePage, "fly")
addToggle(card, { text = "fly", path = "move.fly" })
addKeybind(card, { text = "fly key", path = "move.flyKey" })
addSlider(card, {
	text = "fly speed",
	path = "move.flySpeed",
	min = 10,
	max = 140,
	step = 1,
	decimals = 0,
})
addNote(card, "w a s d · space up · lctrl down")

card = addCard(movePage, "jump")
addSlider(card, {
	text = "jump power",
	path = "move.jumpPower",
	min = 50,
	max = 300,
	step = 5,
	decimals = 0,
})
addToggle(card, { text = "infinite jump", path = "move.infiniteJump" })

card = addCard(movePage, "utility")
addToggle(card, { text = "noclip", path = "move.noclip" })
addToggle(card, { text = "anti-afk", path = "move.antiAfk" })

card = addCard(configPage, "interface")
addKeybind(card, { text = "menu key", path = "ui.key" })
addNote(card, "insert toggles · esc cancels a bind")

card = addCard(configPage, "config")
addButton(card, {
	text = "save config",
	callback = function()
		if saveConfig() then
			toast("config saved")
		else
			toast("config save failed")
		end
	end,
})
addButton(card, {
	text = "load config",
	callback = function()
		if loadConfig() then
			toast("config loaded")
		else
			toast("no config found")
		end
	end,
})
addSpacer(card, 4)
addButton(card, {
	text = "unload",
	callback = function()
		unload()
	end,
})

local closeButton = create("TextButton", {
	Text = "×",
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = Theme.dim,
	BackgroundColor3 = Theme.inset,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -42, 0, 20),
	Parent = header,
})
corner(7, closeButton)

local minButton = create("TextButton", {
	Text = "—",
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = Theme.dim,
	BackgroundColor3 = Theme.inset,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(1, -74, 0, 20),
	Parent = header,
})
corner(7, minButton)

for _, button in ipairs({ closeButton, minButton }) do
	button.MouseEnter:Connect(function()
		tween(button, 0.12, { BackgroundTransparency = 0.15, TextColor3 = Theme.text })
	end)
	button.MouseLeave:Connect(function()
		tween(button, 0.12, { BackgroundTransparency = 1, TextColor3 = Theme.dim })
	end)
end

local minimized = false

local function setMinimized(value)
	minimized = value
	if value then
		tween(root, 0.2, { Size = UDim2.fromOffset(WIDTH, 66) }, Enum.EasingStyle.Quart)
		task.delay(0.2, function()
			if minimized then
				tabStrip.Visible = false
				content.Visible = false
				footer.Visible = false
			end
		end)
	else
		tabStrip.Visible = true
		content.Visible = true
		footer.Visible = true
		tween(root, 0.2, { Size = UDim2.fromOffset(WIDTH, HEIGHT) }, Enum.EasingStyle.Quart)
	end
end

local menuOpen = true

local function setMenuOpen(open)
	menuOpen = open
	if open then
		root.Visible = true
		tween(root, 0.16, { GroupTransparency = 0 })
	else
		tween(root, 0.14, { GroupTransparency = 1 })
		task.delay(0.16, function()
			if not menuOpen then
				root.Visible = false
			end
		end)
	end
end

local function toggleMenu()
	setMenuOpen(not menuOpen)
end

local toastCount = 0

function toast(message, duration)
	toastCount = toastCount + 1
	local index = toastCount
	local box = create("CanvasGroup", {
		Name = "Toast",
		Size = UDim2.fromOffset(320, 34),
		Position = UDim2.new(0.5, 0, 0, 18 + (index % 3) * 40),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.card,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = screen,
	})
	corner(9, box)
	outline(Theme.stroke, 1, 0.35, box)
	textLabel(box, {
		Text = message,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamMedium,
	})
	tween(box, 0.2, { GroupTransparency = 0 })
	task.delay(duration or 2.2, function()
		if box and box.Parent then
			tween(box, 0.25, { GroupTransparency = 1 })
			task.delay(0.3, function()
				if box and box.Parent then
					box:Destroy()
				end
			end)
		end
	end)
end

local function encodeBind(value)
	if typeof(value) ~= "EnumItem" then
		return nil
	end
	return {
		enum = string.gsub(tostring(value.EnumType), "Enum%.", ""),
		name = value.Name,
	}
end

local function decodeBind(raw)
	if type(raw) ~= "table" or type(raw.enum) ~= "string" or type(raw.name) ~= "string" then
		return nil
	end
	local enumType = Enum[raw.enum]
	if not enumType then
		return nil
	end
	return enumType[raw.name]
end

local CONFIG_DIR = "alacrity"
local CONFIG_FILE = "alacrity/config_v2.json"

function saveConfig()
	if not writeFile then
		return false
	end
	local snapshot = {}
	for group, values in pairs(State) do
		snapshot[group] = {}
		for key, value in pairs(values) do
			if typeof(value) == "EnumItem" then
				snapshot[group][key] = encodeBind(value)
			elseif type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
				snapshot[group][key] = value
			end
		end
	end
	local ok = pcall(function()
		if makeFolder and isFolder and not isFolder(CONFIG_DIR) then
			makeFolder(CONFIG_DIR)
		end
		writeFile(CONFIG_FILE, HttpService:JSONEncode(snapshot))
	end)
	return ok
end

function loadConfig()
	if not readFile or not isFile then
		return false
	end
	local okRead, raw = pcall(function()
		if not isFile(CONFIG_FILE) then
			return nil
		end
		return readFile(CONFIG_FILE)
	end)
	if not okRead or type(raw) ~= "string" or #raw == 0 then
		return false
	end
	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not okDecode or type(data) ~= "table" then
		return false
	end
	for group, values in pairs(data) do
		if type(values) == "table" and State[group] then
			for key, value in pairs(values) do
				if key == "key" then
					local decoded = decodeBind(value)
					if decoded then
						setFlag(group .. ".key", decoded)
					end
				elseif State[group][key] ~= nil then
					if type(value) == type(State[group][key]) then
						setFlag(group .. "." .. key, value)
					end
				end
			end
		end
	end
	return true
end

local fovRing
if hasDrawing then
	local okCircle, circle = pcall(Drawing.new, "Circle")
	if okCircle and circle then
		fovRing = circle
		pcall(function()
			circle.Thickness = 1
			circle.NumSides = 96
			circle.Radius = State.aim.fov
			circle.Filled = false
			circle.Transparency = 0.7
			circle.Color = Theme.accent
			circle.Visible = false
		end)
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function characterAlive(character)
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function partVisible(character, part)
	local filter = { Camera }
	if LocalPlayer.Character then
		table.insert(filter, LocalPlayer.Character)
	end
	rayParams.FilterDescendantsInstances = filter
	local origin = Camera.CFrame.Position
	local hit = workspace:Raycast(origin, part.Position - origin, rayParams)
	if not hit then
		return true
	end
	return hit.Instance:IsDescendantOf(character)
end

local function candidateParts(character)
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local mode = State.aim.part
	if mode == "Head" then
		return head and { head } or {}
	elseif mode == "Torso" then
		return torso and { torso } or {}
	end
	local list = {}
	if head then
		table.insert(list, head)
	end
	if torso then
		table.insert(list, torso)
	end
	return list
end

local function isFriendly(player)
	if not State.aim.teamCheck then
		return false
	end
	local mine = LocalPlayer.Team
	local theirs = player.Team
	return mine ~= nil and theirs ~= nil and mine == theirs
end

local function findTarget()
	local viewport = Camera.ViewportSize
	local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
	local bestPart
	local bestScore = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not isFriendly(player) then
			local character = player.Character
			if characterAlive(character) then
				for _, part in ipairs(candidateParts(character)) do
					local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
					if onScreen then
						local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
						if distance <= State.aim.fov then
							local score = distance
							if State.aim.mode == "Distance" then
								score = (Camera.CFrame.Position - part.Position).Magnitude
							end
							if score < bestScore and (not State.aim.wallCheck or partVisible(character, part)) then
								bestScore = score
								bestPart = part
							end
						end
					end
				end
			end
		end
	end

	return bestPart
end

local function aimAt(part)
	if not mouseMove then
		return
	end
	local viewport = Camera.ViewportSize
	local position = part.Position
	if State.aim.prediction > 0 then
		local velocity = part.AssemblyLinearVelocity
		if velocity then
			position = position + velocity * (State.aim.prediction / 1000)
		end
	end
	local screen, onScreen = Camera:WorldToViewportPoint(position)
	if not onScreen then
		return
	end
	local delta = Vector2.new(screen.X - viewport.X * 0.5, screen.Y - viewport.Y * 0.5)
	if delta.Magnitude < 0.75 then
		return
	end
	local step = delta * (1 / math.max(State.aim.smooth, 1))
	if step.Magnitude > 220 then
		step = step.Unit * 220
	end
	pcall(mouseMove, step.X, step.Y)
end

local espObjects = {}

local function resolveDrawing(candidates)
	if not hasDrawing then
		return nil
	end
	for _, name in ipairs(candidates) do
		local ok, object = pcall(Drawing.new, name)
		if ok and object then
			pcall(function()
				object.Visible = false
			end)
			pcall(function()
				object:Remove()
			end)
			return name
		end
	end
	return nil
end

local BOX_CLASS = resolveDrawing({ "Rectangle", "Square", "Quad" })
local TEXT_CLASS = resolveDrawing({ "Text" })
local LINE_CLASS = resolveDrawing({ "Line" })
local espLimited = hasDrawing and (BOX_CLASS == nil or TEXT_CLASS == nil or LINE_CLASS == nil)

local function nullDrawing()
	return setmetatable({}, {
		__index = function()
			return nil
		end,
		__newindex = function() end,
	})
end

local function newDrawing(class)
	if not class then
		return nullDrawing()
	end
	local ok, object = pcall(Drawing.new, class)
	if ok and object then
		return object
	end
	return nullDrawing()
end

local function newEspObjects()
	local objects = {
		box = newDrawing(BOX_CLASS),
		health = newDrawing(BOX_CLASS),
		name = newDrawing(TEXT_CLASS),
		distance = newDrawing(TEXT_CLASS),
		tracer = newDrawing(LINE_CLASS),
	}
	objects.box.Thickness = 1
	objects.box.Filled = false
	objects.box.Transparency = 0.9
	objects.box.Color = Theme.accent

	objects.health.Filled = true
	objects.health.Transparency = 0.9
	objects.health.Color = Theme.good

	objects.name.Size = 13
	objects.name.Center = true
	objects.name.Outline = true
	objects.name.OutlineColor = Color3.new(0, 0, 0)
	objects.name.Transparency = 1
	objects.name.Color = Theme.text

	objects.distance.Size = 11
	objects.distance.Center = true
	objects.distance.Outline = true
	objects.distance.OutlineColor = Color3.new(0, 0, 0)
	objects.distance.Transparency = 1
	objects.distance.Color = Theme.dim

	objects.tracer.Thickness = 1
	objects.tracer.Transparency = 0.55
	objects.tracer.Color = Theme.accent
	return objects
end

local function hideEsp(objects)
	objects.box.Visible = false
	objects.health.Visible = false
	objects.name.Visible = false
	objects.distance.Visible = false
	objects.tracer.Visible = false
end

function colorFor(player, isFriendlyPlayer)
	if isFriendlyPlayer then
		return Theme.good
	end
	local ok, color = pcall(function()
		return player.TeamColor.Color
	end)
	if ok and typeof(color) == "Color3" then
		return color
	end
	return Theme.accent
end

local function updateEsp()
	if not hasDrawing then
		return
	end
	local viewport = Camera.ViewportSize
	local eye = Camera.CFrame.Position

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local objects = espObjects[player]
			if objects then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local head = character and character:FindFirstChild("Head")
				local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
				local drawn = false

				if State.esp.enabled and humanoid and head and root and humanoid.Health > 0 then
					local distance = (eye - root.Position).Magnitude
					local friendlyPlayer = player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
					if distance <= State.esp.maxDistance and not (State.esp.teamCheck and friendlyPlayer) then
						local top, topOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.55, 0))
						local bottom, bottomOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
						if topOn and bottomOn then
							local height = bottom.Y - top.Y
							local width = height * 0.5
							if height > 8 and height < 1600 then
								drawn = true
								local x = top.X - width * 0.5
								local y = top.Y
								local color = colorFor(player, friendlyPlayer)

								if State.esp.box then
									objects.box.Visible = true
									objects.box.Position = Vector2.new(x, y)
									objects.box.Size = Vector2.new(width, height)
									objects.box.Color = color
								else
									objects.box.Visible = false
								end

								if State.esp.health then
									local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
									objects.health.Visible = true
									objects.health.Position = Vector2.new(x - 5, y + height * (1 - ratio))
									objects.health.Size = Vector2.new(2, math.max(height * ratio, 1))
									objects.health.Color = Color3.fromRGB(
										math.floor(255 * (1 - ratio)),
										math.floor(255 * ratio),
										95
									)
								else
									objects.health.Visible = false
								end

								if State.esp.name then
									objects.name.Visible = true
									objects.name.Text = player.Name
									objects.name.Position = Vector2.new(top.X, y - 15)
									objects.name.Color = color
								else
									objects.name.Visible = false
								end

								if State.esp.distance then
									objects.distance.Visible = true
									objects.distance.Text = string.format("%dm", math.floor(distance))
									objects.distance.Position = Vector2.new(top.X, y + height + 2)
								else
									objects.distance.Visible = false
								end

								if State.esp.tracer then
									objects.tracer.Visible = true
									objects.tracer.From = Vector2.new(viewport.X * 0.5, viewport.Y)
									objects.tracer.To = Vector2.new(top.X, y + height)
									objects.tracer.Color = color
								else
									objects.tracer.Visible = false
								end
							end
						end
					end
				end

				if not drawn then
					hideEsp(objects)
				end
			end
		end
	end
end

local function inputMatches(input, target)
	if typeof(target) ~= "EnumItem" then
		return false
	end
	if target.EnumType == Enum.KeyCode then
		return input.KeyCode == target
	end
	if target.EnumType == Enum.UserInputType then
		return input.UserInputType == target
	end
	return false
end

local function isAimHeld()
	local target = State.aim.key
	if typeof(target) ~= "EnumItem" then
		return false
	end
	if target.EnumType == Enum.KeyCode then
		return UserInputService:IsKeyDown(target)
	end
	if target.EnumType == Enum.UserInputType then
		return UserInputService:IsMouseButtonPressed(target)
	end
	return false
end

local function effectiveSpeed()
	local value = State.move.speedValue
	if State.move.bypass then
		return math.min(value, 40)
	end
	return value
end

local function localCharacter()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return humanoid, rootPart
end

local baseWalkSpeed
local baseJumpPower
local baseUseJumpPower
local speedWasOn = false
local jumpWasOn = false

local function applyMovementState()
	local humanoid = localCharacter()
	if not humanoid then
		return
	end
	if baseWalkSpeed == nil then
		baseWalkSpeed = humanoid.WalkSpeed
	end
	if baseJumpPower == nil then
		baseJumpPower = humanoid.JumpPower
	end
	if baseUseJumpPower == nil then
		baseUseJumpPower = humanoid.UseJumpPower
	end

	if State.move.speed then
		local target = effectiveSpeed()
		if humanoid.WalkSpeed ~= target then
			humanoid.WalkSpeed = target
		end
	elseif speedWasOn then
		humanoid.WalkSpeed = baseWalkSpeed
	end
	speedWasOn = State.move.speed

	if State.move.jumpPower ~= 50 then
		humanoid.UseJumpPower = true
		if humanoid.JumpPower ~= State.move.jumpPower then
			humanoid.JumpPower = State.move.jumpPower
		end
		jumpWasOn = true
	elseif jumpWasOn then
		humanoid.UseJumpPower = baseUseJumpPower
		humanoid.JumpPower = baseJumpPower or 50
		jumpWasOn = false
	end
end

local function movementDirection()
	local look = Camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		flatLook = Vector3.new(0, 0, -1)
	end
	flatLook = flatLook.Unit
	local right = Camera.CFrame.RightVector
	local flatRight = Vector3.new(right.X, 0, right.Z)
	if flatRight.Magnitude < 0.01 then
		flatRight = Vector3.new(1, 0, 0)
	end
	flatRight = flatRight.Unit

	local forward = 0
	local strafe = 0
	local lift = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		forward += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		forward -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		strafe += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		strafe -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		lift += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		lift -= 1
	end

	local direction = flatLook * forward + flatRight * strafe + Vector3.new(0, lift, 0)
	if direction.Magnitude < 0.01 then
		return nil
	end
	return direction.Unit
end

function refreshHints()
	if not hints then
		return
	end
	hints.Text = table.concat({
		string.format("%s · menu", bindName(State.ui.key)),
		string.format("%s · aim", bindName(State.aim.key)),
		string.format("%s · fly", bindName(State.move.flyKey)),
		State.move.speed and string.format("%d · speed", math.floor(effectiveSpeed())) or "speed off",
	}, "     ")
	if keyChipLabel then
		keyChipLabel.Text = string.upper(bindName(State.ui.key))
	end
end

bind(UserInputService.InputBegan, function(input, processed)
	if processed then
		return
	end
	if inputMatches(input, State.ui.key) then
		toggleMenu()
	end
	if inputMatches(input, State.move.flyKey) then
		setFlag("move.fly", not State.move.fly)
		toast(State.move.fly and "fly on" or "fly off", 1.2)
	end
	if State.move.infiniteJump and input.KeyCode == Enum.KeyCode.Space then
		local humanoid = localCharacter()
		if humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

bind(Players.PlayerRemoving, function(player)
	local objects = espObjects[player]
	if objects then
		for _, object in pairs(objects) do
			pcall(function()
				object:Remove()
			end)
		end
		espObjects[player] = nil
	end
end)

bind(RunService.Stepped, function(_, delta)
	if workspace.CurrentCamera ~= Camera then
		Camera = workspace.CurrentCamera
	end
	if not Camera then
		return
	end

	local humanoid, rootPart = localCharacter()

	if State.move.fly and rootPart then
		local direction = movementDirection()
		local distance = State.move.flySpeed * delta
		if State.move.bypass then
			distance = math.min(distance, 2.4)
		end
		if direction then
			rootPart.CFrame = rootPart.CFrame + direction * distance
		end
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	elseif State.move.bypass and rootPart and State.move.speed then
		local velocity = rootPart.AssemblyLinearVelocity
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		local cap = effectiveSpeed() * 1.35
		if flat.Magnitude > cap then
			local corrected = flat.Unit * cap
			rootPart.AssemblyLinearVelocity = Vector3.new(corrected.X, velocity.Y, corrected.Z)
		end
	end

	if State.move.noclip and humanoid and humanoid.Parent then
		for _, part in ipairs(humanoid.Parent:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end
	end
end)

bind(RunService.RenderStepped, function()
	if workspace.CurrentCamera ~= Camera then
		Camera = workspace.CurrentCamera
	end
	if not Camera then
		return
	end
	local viewport = Camera.ViewportSize

	if fovRing then
		pcall(function()
			fovRing.Position = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
			fovRing.Radius = State.aim.fov
			fovRing.Visible = State.aim.showFov and not minimized
			fovRing.Color = Theme.accent
		end)
	end

	if State.aim.enabled and (State.aim.always or isAimHeld()) then
		local okAim, target = pcall(findTarget)
		if okAim and target then
			aimAt(target)
		end
	end

	if hasDrawing and State.esp.enabled then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not espObjects[player] then
				local okCreate, objects = pcall(newEspObjects)
				if okCreate and objects then
					espObjects[player] = objects
				end
			end
		end
	end

	pcall(updateEsp)
end)

task.spawn(function()
	while alive do
		task.wait(0.2)
		applyMovementState()
		if State.move.noclip and not LocalPlayer.Character then
			task.wait(0.4)
		end
	end
end)

task.spawn(function()
	while alive do
		task.wait(0.5)
		refreshHints()
	end
end)

task.spawn(function()
	while alive do
		task.wait(40)
		if State.move.antiAfk then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:CaptureController()
				VirtualUser:ClickButton1(Vector2.new(2, 2))
			end)
		end
	end
end)

bind(LocalPlayer.CharacterAdded, function(character)
	character:WaitForChild("Humanoid", 10)
	task.wait(0.3)
	applyMovementState()
end)

local dragging = false
local dragStart
local dragOrigin

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		dragOrigin = root.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

bind(UserInputService.InputChanged, function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		root.Position = UDim2.new(
			dragOrigin.X.Scale,
			dragOrigin.X.Offset + delta.X,
			dragOrigin.Y.Scale,
			dragOrigin.Y.Offset + delta.Y
		)
	end
end)

closeButton.MouseButton1Click:Connect(function()
	setMenuOpen(false)
end)

minButton.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)

activate(tabButtons[1])

function unload()
	alive = false
	saveConfig()
	local humanoid = localCharacter()
	if humanoid then
		humanoid.WalkSpeed = baseWalkSpeed or 16
		humanoid.JumpPower = baseJumpPower or 50
		if baseUseJumpPower ~= nil then
			humanoid.UseJumpPower = baseUseJumpPower
		end
	end
	if State.move.noclip and LocalPlayer.Character then
		for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	for _, objects in pairs(espObjects) do
		for _, object in pairs(objects) do
			pcall(function()
				object:Remove()
			end)
		end
	end
	if fovRing then
		pcall(function()
			fovRing:Remove()
		end)
	end
	pcall(function()
		screen:Destroy()
	end)
end

task.spawn(function()
	loadConfig()
	applyMovementState()
	refreshHints()
end)

tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Quart)
tween(root, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quart)

if hasDrawing then
	print(string.format(
		"[alacrity] drawing: box=%s text=%s line=%s",
		tostring(BOX_CLASS),
		tostring(TEXT_CLASS),
		tostring(LINE_CLASS)
	))
end

task.delay(0.35, function()
	if mouseMove then
		toast("alacrity loaded · insert opens", 2.4)
	else
		toast("mousemoverel unavailable in this executor", 4)
	end
	if espLimited then
		local missing = {}
		if not BOX_CLASS then
			table.insert(missing, "box")
		end
		if not TEXT_CLASS then
			table.insert(missing, "text")
		end
		if not LINE_CLASS then
			table.insert(missing, "line")
		end
		toast("esp: no " .. table.concat(missing, "/") .. " in drawing api", 3.4)
	end
end)
