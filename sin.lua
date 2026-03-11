--[[
    RACKET RIVALS by skeether
]]

local Drawing = Drawing or (getgenv and getgenv().Drawing)
if not Drawing then warn("Drawing library not found.") end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")
local RootPart    = Character:WaitForChild("HumanoidRootPart")

local Ball        = nil
local isSearching = false
local SEARCH_INTERVAL = 60

local Settings = {
    SpeedHack       = false,
    JumpHack        = false,
    ESPPlayers      = false,
    SpeedMultiplier = 2.077,
    JumpMultiplier  = 0.775,
}

local function FindBall()
    if isSearching then return end
    isSearching = true
    task.spawn(function()
        if Ball and Ball.Parent then isSearching = false; return end
        local found = nil
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local lname = obj.Name:lower()
            if obj:IsA("BasePart") and (obj.Name == "Ball" or lname:find("ball") or lname:find("bola")) then
                found = obj; break
            end
        end
        Ball = found
        isSearching = false
    end)
end

local function TeleportToBall()
    if not Ball or not Ball.Parent then return end
    RootPart.CFrame = CFrame.new(Ball.Position + Vector3.new(0, 3, 0))
end

local function UpdateSpeed()
    if not Humanoid or not Humanoid.Parent then return end
    Humanoid.WalkSpeed = Settings.SpeedHack and (16 * Settings.SpeedMultiplier) or 16
end

local function UpdateJump()
    if not Humanoid or not Humanoid.Parent then return end
    Humanoid.JumpPower = Settings.JumpHack and (50 * Settings.JumpMultiplier) or 50
end

-- CHAMS
local ChamsData = {}

local function CreateChams(player, char)
    if not char then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(220, 30, 30); hl.OutlineColor = Color3.fromRGB(255, 80, 80)
    hl.FillTransparency = 0.35; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char; hl.Parent = Workspace
    ChamsData[player] = { highlight = hl }
end

local function RemoveChams(player)
    if ChamsData[player] then
        if ChamsData[player].highlight then ChamsData[player].highlight:Destroy() end
        ChamsData[player] = nil
    end
end

local function UpdateChams()
    if not Settings.ESPPlayers then
        for _, data in pairs(ChamsData) do
            if data.highlight then data.highlight.Parent = nil end
        end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                if not ChamsData[player] then
                    CreateChams(player, char)
                else
                    local hl = ChamsData[player].highlight
                    if hl then
                        if hl.Parent == nil then hl.Parent = Workspace end
                        if hl.Adornee ~= char then hl.Adornee = char end
                    end
                end
            else
                if ChamsData[player] and ChamsData[player].highlight then
                    ChamsData[player].highlight.Parent = nil
                end
            end
        end
    end
    for player, _ in pairs(ChamsData) do
        if not player or not player.Parent then RemoveChams(player) end
    end
end

local function HookPlayer(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if Settings.ESPPlayers then RemoveChams(player); CreateChams(player, char) end
    end)
    player.CharacterRemoving:Connect(function()
        if ChamsData[player] and ChamsData[player].highlight then
            ChamsData[player].highlight.Parent = nil
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then HookPlayer(player) end
end
Players.PlayerAdded:Connect(HookPlayer)
Players.PlayerRemoving:Connect(RemoveChams)

-- ESP
local ESPObjects = {}

local function GetOrCreateESP(player)
    if ESPObjects[player] then return ESPObjects[player] end
    if not Drawing then return nil end
    local box = Drawing.new("Square")
    box.Thickness = 1.5; box.Color = Color3.fromRGB(220, 30, 30)
    box.Filled = false; box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 12; name.Color = Color3.fromRGB(255, 255, 255)
    name.Outline = true; name.Text = player.DisplayName; name.Visible = false
    ESPObjects[player] = { box = box, name = name }
    return ESPObjects[player]
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].box  then ESPObjects[player].box:Remove()  end
        if ESPObjects[player].name then ESPObjects[player].name:Remove() end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    if not Drawing then return end
    if not Settings.ESPPlayers then
        for _, esp in pairs(ESPObjects) do
            if esp.box  then esp.box.Visible  = false end
            if esp.name then esp.name.Visible = false end
        end
        return
    end
    local cam = Workspace.CurrentCamera
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local esp = GetOrCreateESP(player)
            if not esp then continue end
            local char = player.Character
            if not char then esp.box.Visible = false; esp.name.Visible = false; continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then esp.box.Visible = false; esp.name.Visible = false; continue end
            local ok, cframe, size = pcall(function() return char:GetBoundingBox() end)
            if not ok then continue end
            local corners = {
                cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                cframe * CFrame.new( size.X/2, -size.Y/2, -size.Z/2),
                cframe * CFrame.new(-size.X/2,  size.Y/2, -size.Z/2),
                cframe * CFrame.new( size.X/2,  size.Y/2, -size.Z/2),
                cframe * CFrame.new(-size.X/2, -size.Y/2,  size.Z/2),
                cframe * CFrame.new( size.X/2, -size.Y/2,  size.Z/2),
                cframe * CFrame.new(-size.X/2,  size.Y/2,  size.Z/2),
                cframe * CFrame.new( size.X/2,  size.Y/2,  size.Z/2),
            }
            local rootInCam = cam.CFrame:PointToObjectSpace(root.Position)
            local inFront = rootInCam.Z < 0
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            for _, cf in ipairs(corners) do
                local pos = cam:WorldToViewportPoint(cf.Position)
                if pos.X < minX then minX = pos.X end
                if pos.Y < minY then minY = pos.Y end
                if pos.X > maxX then maxX = pos.X end
                if pos.Y > maxY then maxY = pos.Y end
            end
            local boxW = maxX - minX; local boxH = maxY - minY
            if inFront and boxW > 0 and boxH > 0 then
                esp.box.Position = Vector2.new(minX, minY); esp.box.Size = Vector2.new(boxW, boxH)
                esp.box.Visible = true; esp.name.Text = player.DisplayName
                esp.name.Position = Vector2.new(minX, minY - 16); esp.name.Visible = true
            else
                esp.box.Visible = false; esp.name.Visible = false
            end
        end
    end
    for player, _ in pairs(ESPObjects) do
        if not player or not player.Parent then RemoveESP(player) end
    end
end

Players.PlayerRemoving:Connect(function(p) RemoveESP(p); RemoveChams(p) end)

-- BALL ESP
local BallCircle, BallLabel

local function InitBallESP()
    if not Drawing then return end
    BallCircle = Drawing.new("Circle"); BallCircle.Radius = 12; BallCircle.Thickness = 2
    BallCircle.Color = Color3.fromRGB(0, 255, 80); BallCircle.Filled = false; BallCircle.Visible = false
    BallLabel = Drawing.new("Text"); BallLabel.Text = "BALL"; BallLabel.Size = 13
    BallLabel.Color = Color3.fromRGB(0, 255, 80); BallLabel.Outline = true; BallLabel.Visible = false
end

local function UpdateBallESP()
    if not Drawing or not BallCircle then return end
    if not Ball or not Ball.Parent then BallCircle.Visible = false; BallLabel.Visible = false; return end
    local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(Ball.Position)
    if onScreen then
        BallCircle.Position = Vector2.new(pos.X, pos.Y)
        BallCircle.Radius = math.clamp(400 / pos.Z, 6, 40); BallCircle.Visible = true
        BallLabel.Position = Vector2.new(pos.X - 12, pos.Y + BallCircle.Radius + 2); BallLabel.Visible = true
    else
        BallCircle.Visible = false; BallLabel.Visible = false
    end
end

InitBallESP()

-- GUI
if Drawing then

    local C = {
        bg      = Color3.fromRGB(8,   8,   8),
        border  = Color3.fromRGB(38,  38,  38),
        titlebg = Color3.fromRGB(13,  13,  13),
        ttxt    = Color3.fromRGB(255, 255, 255),
        accent  = Color3.fromRGB(190, 20,  20),
        btn_off = Color3.fromRGB(22,  22,  22),
        btn_on  = Color3.fromRGB(150, 18,  18),
        btxt    = Color3.fromRGB(155, 155, 155),
        btxt_on = Color3.fromRGB(255, 255, 255),
        sep     = Color3.fromRGB(35,  35,  35),
        track   = Color3.fromRGB(35,  35,  35),
        fill    = Color3.fromRGB(170, 18,  18),
        thumb   = Color3.fromRGB(235, 235, 235),
        val     = Color3.fromRGB(255, 200, 50),
        cbg     = Color3.fromRGB(30,  30,  30),
        tri     = Color3.fromRGB(210, 210, 210),
    }

    local PAD   = 16
    local TH    = 34
    local BTH   = 30
    local SRH   = 42
    local IBTH  = 30
    local RGAP  = 8
    local WIN_W = 360
    local IW    = WIN_W - PAD * 2

    local TGLW      = 110
    local VALW      = 52
    local TRK_PAD_L = TGLW + 14
    local TRK_PAD_R = VALW + 10
    local TRK_W     = IW - TRK_PAD_L - TRK_PAD_R

    local CONTENT_H = SRH + RGAP + SRH + RGAP + 1 + RGAP + IBTH + RGAP + IBTH + PAD
    local WIN_H_FULL = TH + PAD + CONTENT_H
    local WIN_H_MIN  = TH

    local ANIM_SPEED = 700

    -- animate popeee
    local collapsed    = false
    local animH        = WIN_H_FULL
    local animTarget   = WIN_H_FULL
    local animRunning  = false
    local showContent  = true

    local win = { x = 60, y = 60, w = WIN_W, drag = false, offX = 0, offY = 0 }

    local ro = {}
    ro[1] = 0
    ro[2] = SRH + RGAP
    ro[3] = (SRH + RGAP) * 2
    ro[4] = (SRH + RGAP) * 2 + 1 + RGAP
    ro[5] = (SRH + RGAP) * 2 + 1 + RGAP + IBTH + RGAP

    local function rowY(idx)
        return win.y + TH + PAD + ro[idx]
    end

    local allD        = {}
    local contentList = {}

    local function D(t)
        local d = Drawing.new(t)
        table.insert(allD, d)
        return d
    end

    local function CD(t)
        local d = Drawing.new(t)
        table.insert(allD, d)
        table.insert(contentList, d)
        return d
    end

    -- applier
    local function applyContentVisible()
        for _, d in ipairs(contentList) do
            d.Visible = showContent
        end
    end

    -- ── background ─────────────────────────────────
    local bgRect     = D("Square")
    bgRect.Color = C.bg; bgRect.Filled = true; bgRect.Transparency = 0.88; bgRect.Visible = true

    local borderRect = D("Square")
    borderRect.Color = C.border; borderRect.Filled = false; borderRect.Thickness = 1; borderRect.Visible = true

    -- ── Title bar ────────────────────────────────────
    local titleBg = D("Square")
    titleBg.Color = C.titlebg; titleBg.Filled = true; titleBg.Visible = true

    local accentLine = D("Line")
    accentLine.Color = C.accent; accentLine.Thickness = 1; accentLine.Visible = true

    local titleTxt = D("Text")
    titleTxt.Text = "RACKET RIVALS"; titleTxt.Size = 14
    titleTxt.Color = C.ttxt; titleTxt.Visible = true

    -- ── openbutton ───────────────────────────
    local CBW, CBH = 26, 20

    local colBg = D("Square")
    colBg.Color = C.cbg; colBg.Filled = true; colBg.Visible = true; colBg.Size = Vector2.new(CBW, CBH)

    -- triangle
    local triL1 = D("Line"); triL1.Thickness = 1.5; triL1.Color = C.tri; triL1.Visible = true
    local triL2 = D("Line"); triL2.Thickness = 1.5; triL2.Color = C.tri; triL2.Visible = true
    local triL3 = D("Line"); triL3.Thickness = 1.5; triL3.Color = C.tri; triL3.Visible = true

    local function drawTriangle(bx, by, pointDown)
        local cx = bx + CBW / 2
        local cy = by + CBH / 2
        local hw = 7
        local hh = 4
        local p1, p2, p3
        if pointDown then
            p1 = Vector2.new(cx - hw, cy - hh)
            p2 = Vector2.new(cx + hw, cy - hh)
            p3 = Vector2.new(cx,      cy + hh)
        else
            p1 = Vector2.new(cx - hw, cy + hh)
            p2 = Vector2.new(cx + hw, cy + hh)
            p3 = Vector2.new(cx,      cy - hh)
        end
        triL1.From = p1; triL1.To = p2
        triL2.From = p2; triL2.To = p3
        triL3.From = p3; triL3.To = p1
    end

    -- ── Slider rows ──────────────────────────────────
    local TRACK_H = 4
    local THUMB_W = 8
    local THUMB_H = 18

    local function makeSliderRow(rowIdx, label, minVal, maxVal, initVal, onSlide)
        local tglBg  = CD("Square"); tglBg.Color  = C.btn_off; tglBg.Filled  = true; tglBg.Visible  = true
        local tglLbl = CD("Text");   tglLbl.Text  = label .. "  OFF"; tglLbl.Size = 13
        tglLbl.Color = C.btxt; tglLbl.Visible = true

        local trackBg   = CD("Square"); trackBg.Color   = C.track; trackBg.Filled   = true; trackBg.Visible   = true
        local trackFill = CD("Square"); trackFill.Color = C.fill;  trackFill.Filled = true; trackFill.Visible = true
        local thumb     = CD("Square"); thumb.Color     = C.thumb; thumb.Filled     = true; thumb.Visible     = true
        local valLbl    = CD("Text");   valLbl.Size = 13; valLbl.Color = C.val; valLbl.Visible = true

        local value  = initVal
        local isDrag = false

        local function tglX()     return win.x + PAD end
        local function trkX0()    return win.x + PAD + TRK_PAD_L end
        local function trkX1()    return win.x + PAD + TRK_PAD_L + TRK_W end
        local function rowCY()    return rowY(rowIdx) + SRH / 2 end
        local function tglByTop() return rowY(rowIdx) + (SRH - BTH) / 2 end

        local function valToX(v)
            return trkX0() + ((v - minVal) / (maxVal - minVal)) * TRK_W
        end

        local function xToVal(x)
            local t = math.clamp((x - trkX0()) / TRK_W, 0, 1)
            return math.floor((minVal + t * (maxVal - minVal)) * 1000 + 0.5) / 1000
        end

        local function refreshPos()
            local by     = tglByTop()
            local cy     = rowCY()
            local tx     = trkX0()
            local thumbX = valToX(value)

            tglBg.Position  = Vector2.new(tglX(), by); tglBg.Size = Vector2.new(TGLW, BTH)
            tglLbl.Position = Vector2.new(tglX() + 10, by + 8)

            trackBg.Position = Vector2.new(tx, cy - TRACK_H/2); trackBg.Size = Vector2.new(TRK_W, TRACK_H)

            local fw = math.max(0, thumbX - tx)
            trackFill.Position = Vector2.new(tx, cy - TRACK_H/2); trackFill.Size = Vector2.new(fw, TRACK_H)
            thumb.Position = Vector2.new(thumbX - THUMB_W/2, cy - THUMB_H/2); thumb.Size = Vector2.new(THUMB_W, THUMB_H)

            valLbl.Text     = string.format("x%.3f", value)
            valLbl.Position = Vector2.new(trkX1() + 8, cy - 8)
        end

        local function setValue(v)
            value = math.clamp(math.floor(v * 1000 + 0.5) / 1000, minVal, maxVal)
            refreshPos()
            onSlide(value)
        end

        local function hitToggle(m)
            local by = tglByTop()
            return m.X >= tglX() and m.X <= tglX() + TGLW and m.Y >= by and m.Y <= by + BTH
        end

        local function hitTrack(m)
            local cy = rowCY()
            return m.X >= trkX0() - 4    and m.X <= trkX1() + 4
               and m.Y >= cy - THUMB_H/2 - 4 and m.Y <= cy + THUMB_H/2 + 4
        end

        refreshPos()

        return {
            refresh    = refreshPos,
            setValue   = setValue,
            hitToggle  = hitToggle,
            hitTrack   = hitTrack,
            startDrag  = function() isDrag = true end,
            stopDrag   = function() isDrag = false end,
            drag       = function(m) if isDrag then setValue(xToVal(m.X)) end end,
            clickTrack = function(m) setValue(xToVal(m.X)) end,
            tglBg = tglBg, tglLbl = tglLbl, label = label,
        }
    end

    local function makeBtn(rowIdx, text)
        local bg2 = CD("Square"); bg2.Color = C.btn_off; bg2.Filled = true; bg2.Visible = true
        local lbl = CD("Text");   lbl.Text = text; lbl.Size = 13; lbl.Color = C.btxt; lbl.Visible = true
        local function refresh()
            local by = rowY(rowIdx)
            bg2.Position = Vector2.new(win.x + PAD, by); bg2.Size = Vector2.new(IW, IBTH)
            lbl.Position = Vector2.new(win.x + PAD + 10, by + 8)
        end
        local function hit(m)
            local by = rowY(rowIdx)
            return m.X >= win.x+PAD and m.X <= win.x+PAD+IW and m.Y >= by and m.Y <= by+IBTH
        end
        refresh()
        return bg2, lbl, refresh, hit
    end

    local sep = CD("Line"); sep.Color = C.sep; sep.Thickness = 1; sep.Visible = true

    local speedRow = makeSliderRow(1, "Speed", 1.0, 10.0, Settings.SpeedMultiplier,
        function(v) Settings.SpeedMultiplier = v; if Settings.SpeedHack then UpdateSpeed() end end)

    local jumpRow = makeSliderRow(2, "Jump", 0.0, 10.0, Settings.JumpMultiplier,
        function(v) Settings.JumpMultiplier = v; if Settings.JumpHack then UpdateJump() end end)

    local tpBg,  tpLbl,  tpRefresh,  tpHit  = makeBtn(4, "Teleport to Ball  [R]")
    local espBg, espLbl, espRefresh, espHit  = makeBtn(5, "ESP Players  OFF")

    local speedOn = false
    local jumpOn  = false

    local function setToggle(row, on)
        row.tglBg.Color  = on and C.btn_on  or C.btn_off
        row.tglLbl.Color = on and C.btxt_on or C.btxt
        row.tglLbl.Text  = row.label .. "  " .. (on and "ON" or "OFF")
    end

    -- ── helped ─────
    local function refreshCollapseBtn()
        local cbx = win.x + win.w - CBW - 8
        local cby = win.y + (TH - CBH) / 2
        colBg.Position = Vector2.new(cbx, cby)
        drawTriangle(cbx, cby, not collapsed)
    end

    local function refreshTitleBar()
        local h = math.floor(animH)
        bgRect.Position     = Vector2.new(win.x, win.y); bgRect.Size     = Vector2.new(win.w, h)
        borderRect.Position = Vector2.new(win.x, win.y); borderRect.Size = Vector2.new(win.w, h)
        titleBg.Position    = Vector2.new(win.x, win.y); titleBg.Size    = Vector2.new(win.w, TH)
        accentLine.From     = Vector2.new(win.x,         win.y + TH)
        accentLine.To       = Vector2.new(win.x + win.w, win.y + TH)
        titleTxt.Position   = Vector2.new(win.x + PAD,   win.y + 10)
        refreshCollapseBtn()
    end

    local function refreshContent()
        speedRow.refresh(); jumpRow.refresh()
        tpRefresh(); espRefresh()
        local sepY = rowY(3)
        sep.From = Vector2.new(win.x + PAD,         sepY)
        sep.To   = Vector2.new(win.x + win.w - PAD, sepY)
    end

    local function fullRefresh()
        refreshTitleBar()
        if showContent then refreshContent() end
    end

    fullRefresh()

    -- ── animation ──────────────────────────────────────
    -- top
    --   close
    --   open

    local function startCollapse()
        collapsed   = true
        -- hide
        showContent = false
        applyContentVisible()
        animTarget  = WIN_H_MIN
        animRunning = true
    end

    local function startExpand()
        collapsed   = false
        -- show
        animTarget  = WIN_H_FULL
        animRunning = true
    end

    local function toggleCollapse()
        if animRunning then return end
        if collapsed then
            startExpand()
        else
            startCollapse()
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        if not animRunning then return end

        local delta = animTarget - animH
        local step  = math.sign(delta) * math.min(math.abs(delta), ANIM_SPEED * dt)
        animH = animH + step

        -- end check
        if math.abs(animH - animTarget) < 0.5 then
            animH       = animTarget
            animRunning = false

            -- show
            if not collapsed then
                showContent = true
                applyContentVisible()
                refreshContent()
            end
        end

        refreshTitleBar()
    end)

    -- ── Hit test buttons collapse ──────────────────────
    local function hitCollapseBtn(m)
        local cbx = win.x + win.w - CBW - 8
        local cby = win.y + (TH - CBH) / 2
        return m.X >= cbx and m.X <= cbx + CBW and m.Y >= cby and m.Y <= cby + CBH
    end

    -- ── Input ─────────────────────────────────────────
    local activeSlider = nil

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local m = UserInputService:GetMouseLocation()

            -- Collapse button
            if hitCollapseBtn(m) then
                toggleCollapse(); return
            end

            -- Title drag
            if m.X >= win.x and m.X <= win.x + win.w
            and m.Y >= win.y and m.Y <= win.y + TH then
                win.drag = true; win.offX = m.X - win.x; win.offY = m.Y - win.y; return
            end

            -- block
            if collapsed or animRunning or not showContent then return end

            if speedRow.hitTrack(m)  then activeSlider = "speed"; speedRow.startDrag(); speedRow.clickTrack(m); return end
            if jumpRow.hitTrack(m)   then activeSlider = "jump";  jumpRow.startDrag();  jumpRow.clickTrack(m);  return end

            if speedRow.hitToggle(m) then
                speedOn = not speedOn; Settings.SpeedHack = speedOn
                setToggle(speedRow, speedOn); UpdateSpeed(); return
            end
            if jumpRow.hitToggle(m) then
                jumpOn = not jumpOn; Settings.JumpHack = jumpOn
                setToggle(jumpRow, jumpOn); UpdateJump(); return
            end

            if tpHit(m)  then TeleportToBall(); return end

            if espHit(m) then
                Settings.ESPPlayers = not Settings.ESPPlayers
                espBg.Color  = Settings.ESPPlayers and C.btn_on  or C.btn_off
                espLbl.Color = Settings.ESPPlayers and C.btxt_on or C.btxt
                espLbl.Text  = "ESP Players  " .. (Settings.ESPPlayers and "ON" or "OFF")
                if not Settings.ESPPlayers then
                    for _, data in pairs(ChamsData) do if data.highlight then data.highlight.Parent = nil end end
                    for _, esp in pairs(ESPObjects) do
                        if esp.box  then esp.box.Visible  = false end
                        if esp.name then esp.name.Visible = false end
                    end
                end
                return
            end
        end

        if input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode.R then TeleportToBall() end
    end)

    UserInputService.InputChanged:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local m = UserInputService:GetMouseLocation()
            if win.drag then
                win.x = m.X - win.offX; win.y = m.Y - win.offY; fullRefresh()
            elseif activeSlider == "speed" then speedRow.drag(m)
            elseif activeSlider == "jump"  then jumpRow.drag(m)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            win.drag = false
            if activeSlider == "speed" then speedRow.stopDrag() end
            if activeSlider == "jump"  then jumpRow.stopDrag()  end
            activeSlider = nil
        end
    end)

else
    print("No Drawing. R=Teleport F4=Speed F5=Jump F6=ESP")
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if     input.KeyCode == Enum.KeyCode.R  then TeleportToBall()
            elseif input.KeyCode == Enum.KeyCode.F4 then Settings.SpeedHack = not Settings.SpeedHack; UpdateSpeed()
            elseif input.KeyCode == Enum.KeyCode.F5 then Settings.JumpHack  = not Settings.JumpHack;  UpdateJump()
            elseif input.KeyCode == Enum.KeyCode.F6 then Settings.ESPPlayers = not Settings.ESPPlayers
            end
        end
    end)
end

-- GENERAL
local frame = 0
RunService.RenderStepped:Connect(function()
    frame = frame + 1
    if frame % SEARCH_INTERVAL == 0 or (Ball and not Ball.Parent) then FindBall() end
    UpdateSpeed(); UpdateJump(); UpdateChams(); UpdateESP(); UpdateBallESP()
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = Character:WaitForChild("Humanoid")
    RootPart  = Character:WaitForChild("HumanoidRootPart")
    UpdateSpeed(); UpdateJump()
end)


print("loaded")


