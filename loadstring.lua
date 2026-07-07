-- Groq AI Auto-Reply with WindUI
-- Press F5 to toggle UI when closed

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Config
local CONFIG_FILE = "GroqAI_Config.json"
local GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

-- Better default prompt - tells it to be natural and not use usernames
local DEFAULT_PROMPT = [[You're a regular Roblox player. Keep responses short (under 60 chars), casual and natural. Don't use usernames. Don't act like an AI. Use slang, abbreviations, lowercase sometimes. React like a real person would. Be chill, funny, or whatever fits the vibe. No robotic formal speech.]]

-- State
local AIEnabled = false
local ResponseRange = 50
local ApiKey = ""
local CustomPrompt = DEFAULT_PROMPT
local IsProcessing = false
local LastChatted = {}
local CurrentStatus = "Idle"
local Window = nil

-- Load saved config
local function LoadConfig()
    if isfile(CONFIG_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and data then
            ApiKey = data.apiKey or ""
            ResponseRange = data.range or 50
            CustomPrompt = data.prompt or DEFAULT_PROMPT
        end
    end
end

local function SaveConfig()
    writefile(CONFIG_FILE, HttpService:JSONEncode({
        apiKey = ApiKey,
        range = ResponseRange,
        prompt = CustomPrompt
    }))
end

pcall(LoadConfig)

-- Create Window
Window = WindUI:CreateWindow({
    Title = "Groq AI Auto-Reply",
    Folder = "GroqAI",
    Icon = "bot",
    NewElements = true,
    OpenButton = {
        Title = "Open AI Settings",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#00AAFF"), Color3.fromHex("#00FF88")),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- Keybind to toggle UI (F5)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F5 then
        if Window then
            Window:Toggle()
        end
    end
end)

-- Main Tab
local MainTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
    Border = true,
})

-- API Section
local ApiSection = MainTab:Section({
    Title = "Groq API Configuration",
    Box = true,
    BoxBorder = true,
})

local ApiInput = ApiSection:Input({
    Title = "Groq API Key",
    Desc = "Enter your Groq API key (gsk_...)",
    Value = ApiKey,
    Type = "Input",
    Placeholder = "gsk_xxxxxxxxxxxxxxxxxxxxxxxx",
    Callback = function(value)
        ApiKey = value
    end,
})

ApiSection:Button({
    Title = "Save API Key",
    Desc = "Saves your API key locally",
    Icon = "save",
    Color = Color3.fromHex("#00FF88"),
    Callback = function()
        SaveConfig()
        WindUI:Notify({Title = "Saved!", Content = "API Key saved", Icon = "check", Duration = 3})
    end,
})

-- AI Prompt Section
local PromptSection = MainTab:Section({
    Title = "AI Personality",
    Box = true,
    BoxBorder = true,
})

PromptSection:Section({
    Title = "Tell the AI how to act:",
    TextSize = 13,
    TextTransparency = 0.4,
})

local PromptInput = PromptSection:Input({
    Title = "Instructions",
    Desc = "How should it talk? What vibe?",
    Value = CustomPrompt,
    Type = "Textarea",
    Placeholder = "Enter personality...",
    Callback = function(value)
        CustomPrompt = value
    end,
})

-- Better presets that don't force usernames
PromptSection:Dropdown({
    Title = "Quick Presets",
    Desc = "Choose a vibe",
    Values = {
        {
            Title = "Normal/Chill",
            Callback = function()
                CustomPrompt = "You're a regular Roblox player. Keep it short (under 60 chars), casual, natural. Don't use usernames. Use slang sometimes. Be chill."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Chill mode", Icon = "check"})
            end,
        },
        {
            Title = "Sassy",
            Callback = function()
                CustomPrompt = "You're witty and slightly sarcastic but playful. Short responses under 60 chars. No usernames. Roast lightly. Be funny."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Sassy mode", Icon = "flame"})
            end,
        },
        {
            Title = "Hype/Excited",
            Callback = function()
                CustomPrompt = "You're super enthusiastic and energetic. Short responses. Use words like 'lets go', 'no way', 'fr fr', 'bussin'. No usernames. All caps sometimes."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Hype mode", Icon = "zap"})
            end,
        },
        {
            Title = "Chaotic",
            Callback = function()
                CustomPrompt = "You're random and unhinged. Say weird funny stuff. Short responses. No usernames. Be unpredictable and entertaining."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Chaos mode", Icon = "zap"})
            end,
        },
        {
            Title = "Sigma",
            Callback = function()
                CustomPrompt = "You're confident and keep it real. Short responses under 60 chars. No usernames. Motivational but chill. 'stay winning' vibe."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Sigma mode", Icon = "trophy"})
            end,
        },
        {
            Title = "Quiet/Sus",
            Callback = function()
                CustomPrompt = "You're quiet, mysterious, slightly sus. Short 1-3 word responses sometimes. '...', 'sus', 'nah'. No usernames. Minimal."
                PromptInput:Set(CustomPrompt)
                WindUI:Notify({Title = "Preset", Content = "Quiet mode", Icon = "eye"})
            end,
        },
    },
})

PromptSection:Button({
    Title = "Save Prompt",
    Icon = "save",
    Color = Color3.fromHex("#AA00FF"),
    Callback = function()
        SaveConfig()
        WindUI:Notify({Title = "Saved!", Content = "Personality saved", Icon = "check", Duration = 3})
    end,
})

-- Range Section
local RangeSection = MainTab:Section({
    Title = "Proximity",
    Box = true,
    BoxBorder = true,
})

RangeSection:Slider({
    Title = "Response Range",
    Desc = "How close (studs)",
    Step = 5,
    Value = {Min = 10, Max = 500, Default = ResponseRange},
    Callback = function(value)
        ResponseRange = value
    end,
})

RangeSection:Button({
    Title = "Save Settings",
    Icon = "save",
    Callback = function()
        SaveConfig()
        WindUI:Notify({Title = "Saved!", Content = "Settings saved", Icon = "check", Duration = 3})
    end,
})

-- Toggle Section
local ToggleSection = MainTab:Section({
    Title = "Control",
    Box = true,
    BoxBorder = true,
})

local AIToggle = ToggleSection:Toggle({
    Title = "Enable AI Auto-Reply",
    Desc = "Auto-respond to nearby chat",
    Value = false,
    Callback = function(state)
        AIEnabled = state
        CurrentStatus = state and "Listening..." or "Idle"
        WindUI:Notify({
            Title = state and "AI Enabled" or "AI Disabled",
            Content = state and ("Range: " .. ResponseRange .. " studs") or "Auto-reply off",
            Icon = state and "bot" or "power",
            Duration = 3,
        })
    end,
})

-- Status
local StatusParagraph = ToggleSection:Paragraph({
    Title = "Status: Idle",
    Desc = "AI status",
})

-- Functions
local function GetDistance(player)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    return (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
end

local function SendToGroq(message, playerName)
    if ApiKey == "" or ApiKey:sub(1, 4) ~= "gsk_" then
        return nil
    end
    
    local payload = {
        model = "llama-3.1-8b-instant",
        messages = {
            {
                role = "system",
                content = CustomPrompt .. "\n\nSomeone said: '" .. message .. "'. Reply naturally without using their name."
            },
            {
                role = "user",
                content = message
            }
        },
        max_tokens = 80,
        temperature = 0.9
    }
    
    local success, result = pcall(function()
        local response = request({
            Url = GROQ_API_URL,
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. ApiKey,
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
        
        if response.StatusCode == 200 then
            local decoded = HttpService:JSONDecode(response.Body)
            if decoded.choices and decoded.choices[1] then
                return decoded.choices[1].message.content
            end
        else
            warn("API Error: " .. response.StatusCode)
        end
        return nil
    end)
    
    return success and result or nil
end

-- FIXED: No [AI] prefix, just raw message
local function SendAIChat(message)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local textChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if textChannel then
                textChannel:SendAsync(message)  -- Just the message, no prefix
            end
        else
            local chatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
            local sayMessageRequest = chatEvents:WaitForChild("SayMessageRequest")
            if sayMessageRequest then
                sayMessageRequest:FireServer(message, "All")  -- Just the message, no prefix
            end
        end
    end)
end

local function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    pcall(function()
        if StatusParagraph then
            StatusParagraph:Set("Status: " .. newStatus)
        end
    end)
end

local function ProcessMessage(player, message)
    if not AIEnabled then return end
    if player == LocalPlayer then return end
    if IsProcessing then return end
    
    if GetDistance(player) > ResponseRange then return end
    
    local currentTime = tick()
    if LastChatted[player.UserId] and (currentTime - LastChatted[player.UserId]) < 2 then
        return
    end
    LastChatted[player.UserId] = currentTime
    
    IsProcessing = true
    UpdateStatus("Thinking...")
    
    task.spawn(function()
        local response = SendToGroq(message, player.Name)
        
        if response then
            -- Clean up response
            response = response:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
            if #response > 0 then
                SendAIChat(response)
                UpdateStatus("Replied")
            end
        else
            UpdateStatus("Failed")
        end
        
        task.wait(0.5)
        IsProcessing = false
        UpdateStatus(AIEnabled and "Listening..." or "Idle")
    end)
end

-- Chat detection
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local generalChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
    generalChannel.MessageReceived:Connect(function(textChatMessage)
        local sender = textChatMessage.TextSource
        if sender then
            local player = Players:GetPlayerByUserId(sender.UserId)
            if player then
                ProcessMessage(player, textChatMessage.Text)
            end
        end
    end)
else
    local chatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
    chatEvents:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
        local player = Players:FindFirstChild(data.FromSpeaker)
        if player then
            ProcessMessage(player, data.Message)
        end
    end)
end

-- Info Tab
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
    Border = true,
})

InfoTab:Paragraph({
    Title = "Controls",
    Desc = "F5 = Toggle UI\n\nThe AI responds naturally without usernames or [AI] tags. Just normal chat. IF YOU MINIMIZE CLICK F5 TO BRING BACK",
    Image = "bot",
})

-- Load saved values
if ApiKey ~= "" then ApiInput:Set(ApiKey) end
if CustomPrompt ~= DEFAULT_PROMPT then PromptInput:Set(CustomPrompt) end

print("AI Auto-Reply loaded! Press RightShift to toggle UI.")
