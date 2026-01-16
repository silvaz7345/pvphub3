--// SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// CONFIG
local AimlockEnabled = false
local ESPEnabled = false
local AimPart = "Head"
local AimRadius = 250
local DrawingTracers = {}

-- HOTKEY CONFIG: altere aqui a tecla para ligar/desligar Aimlock
local AimlockKey = Enum.KeyCode.E

--// FUNÇÕES

-- Alterna Aimlock
local function ToggleAimlock()
    AimlockEnabled = not AimlockEnabled
    print("Aimlock", AimlockEnabled and "Ligado" or "Desligado")
end

-- Detectar tecla
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == AimlockKey then
                ToggleAimlock()
            end
        end
    end
end)

-- Pegar jogador mais próximo (para Aimlock)
local function GetClosestPlayer()
    local closest, dist = nil, AimRadius
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(AimPart) then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character[AimPart].Position)
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if mag < dist then
                    dist = mag
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- ESP Tracer
local function CreateTracer(player)
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(0, 255, 0)
    line.Transparency = 1
    line.Visible = false
    DrawingTracers[player] = line
end

local function UpdateESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if ESPEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if not DrawingTracers[plr] then
                    CreateTracer(plr)
                end

                local hrp = plr.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenSize = Camera.ViewportSize
                    DrawingTracers[plr].From = Vector2.new(screenSize.X/2, screenSize.Y)
                    DrawingTracers[plr].To = Vector2.new(pos.X, pos.Y)
                    DrawingTracers[plr].Visible = true
                else
                    DrawingTracers[plr].Visible = false
                end
            else
                if DrawingTracers[plr] then
                    DrawingTracers[plr].Visible = false
                end
            end
        end
    end
end

--// GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "PvPHub"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
Title.Text = "PvP Hub (Privado)"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- Botão Fechar
local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 35, 1, 0)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)

-- Botão Ocultar
local HideBtn = Instance.new("TextButton", Title)
HideBtn.Size = UDim2.new(0, 35, 1, 0)
HideBtn.Position = UDim2.new(1, -70, 0, 0)
HideBtn.Text = "-"
HideBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)

local Content = Instance.new("Frame", MainFrame)
Content.Position = UDim2.new(0, 0, 0, 35)
Content.Size = UDim2.new(1, 0, 1, -35)
Content.BackgroundTransparency = 1

-- Função criar Toggle
local function CreateToggle(text, posY, callback)
    local btn = Instance.new("TextButton", Content)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.TextColor3 = Color3.new(1,1,1)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

-- Toggles padrão
CreateToggle("ESP", 10, function(v)
    ESPEnabled = v
    if not v then
        for _, line in pairs(DrawingTracers) do
            line.Visible = false
        end
    end
end)

-- Reflete o Aimlock no GUI
CreateToggle("Aimlock (Hotkey: E)", 55, function(v)
    AimlockEnabled = v
end)

-- Botões principais
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

HideBtn.MouseButton1Click:Connect(function()
    Content.Visible = not Content.Visible
end)

--// LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    -- Aimlock
    if AimlockEnabled then
        local target = GetClosestPlayer()
        if target and target.Character then
            Camera.CFrame = CFrame.new(
                Camera.CFrame.Position,
                target.Character[AimPart].Position
            )
        end
    end

    -- ESP Tracer
    UpdateESP()
end)
