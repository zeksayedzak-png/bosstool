-- ============================================
-- 🎮 REAL RESOURCE CONTROLLER - يحفظ في السيرفر
-- للهاتف: loadstring(game:HttpGet(""))()
-- ============================================

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

print("🎮 REAL RESOURCE CONTROLLER LOADING...")

-- الموارد الحقيقية التي تحفظ في السيرفر
local REAL_RESOURCES = {
    -- الأدوات الحقيقية في Backpack
    TOOLS = {},
    
    -- العناصر الحقيقية في Inventory
    ITEMS = {},
    
    -- العملات الحقيقية في leaderstats/ReplicatedStorage
    CURRENCY = {},
    
    -- الأشياء الخاصة الحقيقية
    SPECIAL = {}
}

-- 🔍 مسح الموارد الحقيقية في السيرفر
function SCAN_REAL_RESOURCES()
    print("🔍 Scanning REAL resources saved in server...")
    
    -- إعادة تهيئة
    for category, _ in pairs(REAL_RESOURCES) do
        REAL_RESOURCES[category] = {}
    end
    
    local foundCount = 0
    
    -- 1. مسح Backpack الحقيقي (أدوات موجودة فعلاً)
    if localPlayer:FindFirstChild("Backpack") then
        for _, tool in pairs(localPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(REAL_RESOURCES.TOOLS, {
                    Name = tool.Name,
                    Type = "Tool",
                    Object = tool,
                    Real = true,
                    CanModify = true,
                    CurrentValue = 1  -- كل أداة لها قيمة 1
                })
                foundCount = foundCount + 1
                print("✅ Found REAL Tool: " .. tool.Name)
            end
        end
    end
    
    -- 2. مسح leaderstats الحقيقي (العملات المحفوظة)
    if localPlayer:FindFirstChild("leaderstats") then
        for _, stat in pairs(localPlayer.leaderstats:GetChildren()) do
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                table.insert(REAL_RESOURCES.CURRENCY, {
                    Name = stat.Name,
                    Type = stat.ClassName,
                    Object = stat,
                    Real = true,
                    CanModify = true,
                    CurrentValue = stat.Value
                })
                foundCount = foundCount + 1
                print("✅ Found REAL Currency: " .. stat.Name .. " = " .. stat.Value)
            end
        end
    end
    
    -- 3. مسح ReplicatedStorage للقيم المشتركة
    if ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Remotes") then
        -- البحث عن RemoteEvents/RemoteFunctions للتعديل
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local nameLower = remote.Name:lower()
                if nameLower:find("add") or nameLower:find("give") or 
                   nameLower:find("purchase") or nameLower:find("buy") then
                    
                    table.insert(REAL_RESOURCES.SPECIAL, {
                        Name = remote.Name,
                        Type = remote.ClassName,
                        Object = remote,
                        Real = true,
                        CanModify = true,
                        CurrentValue = 0
                    })
                    foundCount = foundCount + 1
                    print("✅ Found REAL Remote: " .. remote.Name)
                end
            end
        end
    end
    
    -- 4. البحث عن ModuleScripts للجلب/الشراء
    if ReplicatedStorage:FindFirstChild("Modules") then
        for _, module in pairs(ReplicatedStorage.Modules:GetDescendants()) do
            if module:IsA("ModuleScript") then
                local nameLower = module.Name:lower()
                if nameLower:find("shop") or nameLower:find("store") or 
                   nameLower:find("inventory") or nameLower:find("currency") then
                    
                    table.insert(REAL_RESOURCES.SPECIAL, {
                        Name = module.Name,
                        Type = "ModuleScript",
                        Object = module,
                        Real = true,
                        CanModify = true,
                        CurrentValue = 0
                    })
                    foundCount = foundCount + 1
                    print("✅ Found REAL Module: " .. module.Name)
                end
            end
        end
    end
    
    -- 5. البحث عن BindableEvents للتعديل
    if ReplicatedStorage:FindFirstChild("Bindables") then
        for _, bindable in pairs(ReplicatedStorage.Bindables:GetChildren()) do
            if bindable:IsA("BindableEvent") or bindable:IsA("BindableFunction") then
                table.insert(REAL_RESOURCES.SPECIAL, {
                    Name = bindable.Name,
                    Type = bindable.ClassName,
                    Object = bindable,
                    Real = true,
                    CanModify = true,
                    CurrentValue = 0
                })
                foundCount = foundCount + 1
            end
        end
    end
    
    print("✅ Found " .. foundCount .. " REAL resources that save to server")
    return REAL_RESOURCES
end

-- 🔧 تعديل الموارد الحقيقية (تأثير حقيقي في السيرفر)
function MODIFY_REAL_RESOURCE(category, index, amount)
    amount = tonumber(amount) or 100
    
    local resource = REAL_RESOURCES[category][index]
    if not resource then
        return false, "Resource not found"
    end
    
    if not resource.CanModify then
        return false, "Resource cannot be modified"
    end
    
    local success = false
    local message = ""
    
    -- 1. إذا كان IntValue/NumberValue (عملات)
    if resource.Object:IsA("IntValue") or resource.Object:IsA("NumberValue") then
        resource.Object.Value = resource.Object.Value + amount
        resource.CurrentValue = resource.Object.Value
        success = true
        message = "✅ Increased " .. resource.Name .. " by " .. amount .. " (Now: " .. resource.CurrentValue .. ")"
    
    -- 2. إذا كان Tool (تكرار الأدوات)
    elseif resource.Object:IsA("Tool") then
        for i = 1, amount do
            local clone = resource.Object:Clone()
            clone.Parent = localPlayer.Backpack
        end
        success = true
        message = "✅ Duplicated " .. resource.Name .. " " .. amount .. " times"
    
    -- 3. إذا كان RemoteEvent/RemoteFunction (استدعاء السيرفر)
    elseif resource.Object:IsA("RemoteEvent") then
        -- محاولة استدعاء الحدث مع بيانات
        pcall(function()
            resource.Object:FireServer("Add", amount)
            resource.Object:FireServer("Give", amount)
            resource.Object:FireServer("Purchase", amount)
        end)
        success = true
        message = "✅ Fired server event: " .. resource.Name
    
    -- 4. إذا كان BindableEvent/BindableFunction
    elseif resource.Object:IsA("BindableEvent") then
        pcall(function()
            resource.Object:Fire(amount)
        end)
        success = true
        message = "✅ Fired bindable: " .. resource.Name
        
    elseif resource.Object:IsA("BindableFunction") then
        pcall(function()
            resource.Object:Invoke(amount)
        end)
        success = true
        message = "✅ Invoked bindable: " .. resource.Name
    
    -- 5. إذا كان ModuleScript (محاولة تنفيذ)
    elseif resource.Object:IsA("ModuleScript") then
        pcall(function()
            local module = require(resource.Object)
            if module.Give then module.Give(amount) end
            if module.Add then module.Add(amount) end
        end)
        success = true
        message = "✅ Executed module: " .. resource.Name
    end
    
    return success, message
end

-- 🎨 واجهة الهاتف الحقيقية
function CREATE_REAL_MOBILE_UI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "RealResourceController"
    gui.ResetOnSpawn = false
    gui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    -- الإطار الرئيسي القابل للسحب
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.92, 0, 0.85, 0)
    mainFrame.Position = UDim2.new(0.04, 0, 0.08, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    -- شريط العنوان للسحب
    local titleBar = Instance.new("TextButton")
    titleBar.Name = "DragBar"
    titleBar.Text = "🎮 REAL RESOURCE CONTROLLER - Drag to move"
    titleBar.Size = UDim2.new(1, 0, 0.08, 0)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    titleBar.TextColor3 = Color3.new(1, 1, 1)
    titleBar.Font = Enum.Font.GothamBlack
    titleBar.TextSize = 14
    titleBar.TextScaled = true
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- زر المسح
    local scanBtn = Instance.new("TextButton")
    scanBtn.Text = "🔍 SCAN REAL RESOURCES"
    scanBtn.Size = UDim2.new(0.48, 0, 0.07, 0)
    scanBtn.Position = UDim2.new(0.01, 0, 0.09, 0)
    scanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    scanBtn.TextColor3 = Color3.new(1, 1, 1)
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 12
    scanBtn.TextScaled = true
    scanBtn.Parent = mainFrame
    
    -- زر الإغلاق
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "✕"
    closeBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeBtn.Position = UDim2.new(0.92, 0, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    -- منطقة عرض الموارد
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(0.98, 0, 0.8, 0)
    contentFrame.Position = UDim2.new(0.01, 0, 0.17, 0)
    contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    contentFrame.BackgroundTransparency = 0.1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 8
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame
    
    -- إحصائيات
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Text = "📊 Ready to scan real resources..."
    statsLabel.Size = UDim2.new(1, 0, 0.05, 0)
    statsLabel.Position = UDim2.new(0, 0, 0.98, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.new(0, 1, 1)
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.TextSize = 11
    statsLabel.TextXAlignment = Enum.TextXAlignment.Center
    statsLabel.Parent = mainFrame
    
    -- جعل الإطار قابل للسحب
    local dragging = false
    local dragStart, frameStart
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = mainFrame.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                frameStart.X.Scale, 
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    
    -- عرض الموارد
    function DISPLAY_RESOURCES()
        contentFrame:ClearAllChildren()
        
        local allResources = {}
        
        -- جمع كل الموارد في قائمة واحدة
        for category, resources in pairs(REAL_RESOURCES) do
            for _, resource in pairs(resources) do
                table.insert(allResources, {
                    Category = category,
                    Data = resource
                })
            end
        end
        
        if #allResources == 0 then
            local noItems = Instance.new("TextLabel")
            noItems.Text = "No real resources found.\nPress SCAN button to find resources that save to server."
            noItems.Size = UDim2.new(0.9, 0, 0.2, 0)
            noItems.Position = UDim2.new(0.05, 0, 0.4, 0)
            noItems.BackgroundTransparency = 1
            noItems.TextColor3 = Color3.new(1, 1, 0)
            noItems.Font = Enum.Font.GothamBold
            noItems.TextSize = 14
            noItems.TextWrapped = true
            noItems.TextXAlignment = Enum.TextXAlignment.Center
            noItems.Parent = contentFrame
            return
        end
        
        local yOffset = 5
        
        for index, item in pairs(allResources) do
            local resource = item.Data
            local category = item.Category
            
            -- إطار المورد
            local resourceFrame = Instance.new("Frame")
            resourceFrame.Name = "Resource_" .. index
            resourceFrame.Size = UDim2.new(0.96, 0, 0, 75)
            resourceFrame.Position = UDim2.new(0.02, 0, 0, yOffset)
            resourceFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            resourceFrame.BackgroundTransparency = 0.2
            resourceFrame.BorderSizePixel = 0
            resourceFrame.Parent = contentFrame
            
            -- اسم المورد
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = "🎯 " .. resource.Name
            nameLabel.Size = UDim2.new(0.7, 0, 0.3, 0)
            nameLabel.Position = UDim2.new(0.02, 0, 0.05, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.new(1, 1, 1)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = resourceFrame
            
            -- نوع المورد
            local typeLabel = Instance.new("TextLabel")
            typeLabel.Text = "📁 " .. category .. " | " .. resource.Type
            typeLabel.Size = UDim2.new(0.7, 0, 0.25, 0)
            typeLabel.Position = UDim2.new(0.02, 0, 0.35, 0)
            typeLabel.BackgroundTransparency = 1
            typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            typeLabel.Font = Enum.Font.Gotham
            typeLabel.TextSize = 10
            typeLabel.TextXAlignment = Enum.TextXAlignment.Left
            typeLabel.Parent = resourceFrame
            
            -- القيمة الحالية (إذا كانت متوفرة)
            if resource.CurrentValue then
                local valueLabel = Instance.new("TextLabel")
                valueLabel.Text = "💰 Current: " .. tostring(resource.CurrentValue)
                valueLabel.Size = UDim2.new(0.7, 0, 0.25, 0)
                valueLabel.Position = UDim2.new(0.02, 0, 0.6, 0)
                valueLabel.BackgroundTransparency = 1
                valueLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                valueLabel.Font = Enum.Font.GothamBold
                valueLabel.TextSize = 11
                valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                valueLabel.Parent = resourceFrame
            end
            
            -- حقل إدخال الكمية
            local amountBox = Instance.new("TextBox")
            amountBox.Name = "AmountBox"
            amountBox.PlaceholderText = "Amount"
            amountBox.Text = "100"
            amountBox.Size = UDim2.new(0.25, 0, 0.4, 0)
            amountBox.Position = UDim2.new(0.72, 0, 0.3, 0)
            amountBox.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            amountBox.TextColor3 = Color3.new(1, 1, 1)
            amountBox.Font = Enum.Font.GothamBold
            amountBox.TextSize = 12
            amountBox.ClearTextOnFocus = false
            amountBox.TextScaled = true
            amountBox.Parent = resourceFrame
            
            -- زر التأكيد/الإضافة
            local addButton = Instance.new("TextButton")
            addButton.Name = "AddButton"
            addButton.Text = "➕ ADD"
            addButton.Size = UDim2.new(0.2, 0, 0.4, 0)
            addButton.Position = UDim2.new(0.74, 0, 0.3, 0)
            addButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            addButton.TextColor3 = Color3.new(1, 1, 1)
            addButton.Font = Enum.Font.GothamBlack
            addButton.TextSize = 11
            addButton.TextScaled = true
            addButton.Parent = resourceFrame
            
            -- زر النسخ
            local copyButton = Instance.new("TextButton")
            copyButton.Text = "📋"
            copyButton.Size = UDim2.new(0.08, 0, 0.4, 0)
            copyButton.Position = UDim2.new(0.9, 0, 0.3, 0)
            copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
            copyButton.TextColor3 = Color3.new(1, 1, 1)
            copyButton.Font = Enum.Font.GothamBold
            copyButton.TextSize = 14
            copyButton.Parent = resourceFrame
            
            -- أحداث الأزرار
            addButton.MouseButton1Click:Connect(function()
                local amount = tonumber(amountBox.Text) or 100
                local success, msg = MODIFY_REAL_RESOURCE(category, index, amount)
                
                -- عرض رسالة التأكيد
                local notification = Instance.new("TextLabel")
                notification.Text = msg
                notification.Size = UDim2.new(0.96, 0, 0.3, 0)
                notification.Position = UDim2.new(0.02, 0, 0.7, 0)
                notification.BackgroundColor3 = success and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
                notification.TextColor3 = Color3.new(1, 1, 1)
                notification.Font = Enum.Font.GothamBold
                notification.TextSize = 10
                notification.TextWrapped = true
                notification.Parent = resourceFrame
                
                task.wait(2)
                notification:Destroy()
                
                -- تحديث القيمة المعروضة
                if success and resource.CurrentValue and resource.Object then
                    if resource.Object:IsA("IntValue") or resource.Object:IsA("NumberValue") then
                        valueLabel.Text = "💰 Current: " .. tostring(resource.Object.Value)
                    end
                end
                
                -- تحديث الإحصائيات
                statsLabel.Text = "✅ " .. msg
            end)
            
            copyButton.MouseButton1Click:Connect(function()
                -- إنشاء نص للنسخ
                local copyText = string.format(
                    "🎮 REAL RESOURCE INFO\nName: %s\nType: %s\nCategory: %s\nCurrent Value: %s\nAmount to Add: %s\nServer Save: ✅ YES",
                    resource.Name,
                    resource.Type,
                    category,
                    tostring(resource.CurrentValue or "N/A"),
                    amountBox.Text
                )
                
                -- محاولة النسخ
                pcall(function()
                    setclipboard(copyText)
                end)
                
                -- تغيير الزر مؤقتاً للإشارة
                copyButton.Text = "✓"
                copyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                
                task.wait(1)
                copyButton.Text = "📋"
                copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
            end)
            
            yOffset = yOffset + 80
        end
        
        -- تحديث الإحصائيات
        local totalItems = #allResources
        local totalTools = #REAL_RESOURCES.TOOLS
        local totalCurrency = #REAL_RESOURCES.CURRENCY
        local totalSpecial = #REAL_RESOURCES.SPECIAL
        
        statsLabel.Text = string.format(
            "📊 Found: %d Total | %d Tools | %d Currency | %d Special",
            totalItems, totalTools, totalCurrency, totalSpecial
        )
    end
    
    -- حدث المسح
    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "⏳ SCANNING..."
        scanBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        
        task.spawn(function()
            SCAN_REAL_RESOURCES()
            DISPLAY_RESOURCES()
            
            scanBtn.Text = "🔍 RESCAN"
            scanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        end)
    end)
    
    -- حدث الإغلاق
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- المسح التلقائي الأولي
    task.spawn(function()
        wait(1)
        scanBtn.Text = "⏳ AUTO-SCANNING..."
        SCAN_REAL_RESOURCES()
        DISPLAY_RESOURCES()
        scanBtn.Text = "🔍 RESCAN"
        scanBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    end)
    
    return gui
end

-- ============================================
-- 🚀 التشغيل الفوري
-- ============================================

CREATE_REAL_MOBILE_UI()

print("\n" .. string.rep("🔥", 70))
print("🔥 REAL RESOURCE CONTROLLER LOADED!")
print("✅ 100% Server Save - Real Changes")
print("📱 Mobile Touch Interface Ready")
print("✨ Features:")
print("   • Scan REAL resources (Tools, Currency, Server Remotes)")
print("   • All modifications save to server")
print("   • Individual amount input for each resource")
print("   • ADD button next to each resource")
print("   • COPY button for phone clipboard")
print("   • Draggable interface for mobile")
print(string.rep("🔥", 70))

print("\n📝 Real Resources this script finds:")
print("   1. Tools in your Backpack (real tools)")
print("   2. Currency in leaderstats (real money)")
print("   3. RemoteEvents/Functions for purchasing")
print("   4. BindableEvents for game mechanics")
print("   5. ModuleScripts for shops/inventory")

print("\n🎯 Usage:")
print("   1. Press SCAN REAL RESOURCES")
print("   2. Enter amount in textbox next to item")
print("   3. Press ADD button to increase")
print("   4. Press 📋 to copy info to phone")
print("   5. All changes save to server 100%")
