surface.CreateFont("GPic_ButtonFont", {
	font = "Arial",
	size = 24,
	weight = 600,
})

-- mouse.X and mouse.Y aren't exact
local function mouseX()
	return gui.MouseX()+8
end

local function mouseY()
	return gui.MouseY()+8
end

local function screenshot(callback,cropSelection)
	hook.Add("PostRender","GPic_TakeScreenshot",function()
		hook.Remove("PostRender","GPic_TakeScreenshot")
		local settings = {
			format = "jpeg",
			quality = 70
		}
		if cropSelection then
			settings.h = cropSelection[4] - cropSelection[3]
			settings.w = cropSelection[5]
			settings.x = cropSelection[1]-8
			settings.y = cropSelection[3]-8
		else
			settings.h = ScrH()
			settings.w = ScrW()
			settings.x = 0
			settings.y = 0
		end
		callback( render.Capture(settings) )
	end)
end

local function openScreenMenu(screen)
	local screenH = ScrH()+8 -- frame is a little bit shifted
	local screenW = ScrW()+8

	local html = vgui.Create("DHTML")
	html:SetSize(screenW,screenH)
	html:SetHTML([[<img src="data:image/jpeg;base64, ]]..util.Base64Encode(screen)..[["/><style>body{overflow:hidden;}</style>]])
	html:SetPos(-8,-8)
	html:MakePopup()
	local close = vgui.Create("DButton", html)
	function close:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,Color(255,0,0))
	end
	close:SetText("❌")
	close:SetColor(Color(255,255,255))
	close:SetSize(20,20)
	close:AlignRight(20)
	close:AlignTop(20)
	close:SetZPos(1) -- Set it over overPanel
	function close.DoClick()
		html:Remove()
	end

	local pencilMode = false
	local pixelToDo = {}
	local currentColor = Color(255,255,255,255)
	local cropMode = false
	local cropSelection = {}

	local overPanel = vgui.Create("DPanel",html)
	overPanel:SetPos(0, 0)
	overPanel:SetSize(screenW,screenH)
	function overPanel:Paint()
		for i=1, #pixelToDo do
			draw.RoundedBox(0, pixelToDo[i].x, pixelToDo[i].y,5,5, pixelToDo[i].c)
		end
		if pencilMode then
			draw.RoundedBox(0, mouseX()-2,mouseY()-3,5,5, currentColor)
			if input.IsMouseDown(MOUSE_FIRST) and self:IsHovered() then -- if mouse down & not clicking on a button
				table.insert(pixelToDo, {
					x = mouseX()-2,
					y = mouseY()-3,
					c = currentColor
				})
			end
		end
		if cropMode and cropSelection[1] then

			-- I wonder if there's a more optimized way

			local negX = cropSelection[1][1] < mouseX()
			local negY = cropSelection[1][2] < mouseY()

			local minX = negX and cropSelection[1][1] or mouseX()
			local maxX = negX and mouseX() or cropSelection[1][1]
			local minY = negY and cropSelection[1][2] or mouseY()
			local maxY = negY and mouseY() or cropSelection[1][2]

			local width = maxX - minX

			surface.SetDrawColor(0,0,0,150)

			-- left rect
			surface.DrawRect( 0,0, minX, screenH )
			
			-- right rect
			surface.DrawRect( maxX, 0, screenW - (maxX), screenH )

			-- upper rect
			surface.DrawRect( minX, 0, width, minY )

			-- lower rect
			surface.DrawRect( minX, maxY, width, screenH - (maxY) )


		elseif cropSelection[3] then
			surface.SetDrawColor(0,0,0,150)
			surface.DrawRect( 0,0, cropSelection[3][1], screenH )
			surface.DrawRect( cropSelection[3][2], 0, cropSelection[3][6], screenH )
			surface.DrawRect( cropSelection[3][1], 0, cropSelection[3][5], cropSelection[3][3] )
			surface.DrawRect( cropSelection[3][1], cropSelection[3][4], cropSelection[3][5], cropSelection[3][7] )
		end
	end
	function overPanel:OnMousePressed(code)
		if !cropMode or code ~= MOUSE_FIRST then return end
		cropSelection[3] = nil
		cropSelection[1] = { mouseX(), mouseY() }
	end
	function overPanel:OnMouseReleased(code)
		if !cropMode or code ~= MOUSE_FIRST then return end
		cropSelection[2] = { mouseX(), mouseY() }
		cropMode = false

		local negX = cropSelection[1][1] < mouseX()
		local negY = cropSelection[1][2] < mouseY()

		local minX = negX and cropSelection[1][1] or mouseX()
		local maxX = negX and mouseX() or cropSelection[1][1]
		local minY = negY and cropSelection[1][2] or mouseY()
		local maxY = negY and mouseY() or cropSelection[1][2]

		local width = maxX - minX

		cropSelection[3] = {
			minX,
			maxX,
			minY,
			maxY,
			width,
			screenW - (maxX),
			screenH - (maxY)
		}

		cropSelection[1] = nil
		cropSelection[2] = nil
	end

	local colorButton = vgui.Create("DButton",html)
	function colorButton:Paint(w,h)
		draw.RoundedBox(4,0,0,w,h,currentColor)
	end
	colorButton:SetFont("GPic_ButtonFont")
	colorButton:SetText("Color")
	colorButton:SetColor(Color(0,0,0))
	colorButton:SetSize(90,30)
	colorButton:SetPos(ScrW()-90, ScrH()/2-55)
	local colorChoser = vgui.Create("DColorMixer",html)
	colorChoser:SetSize(300,250)
	colorChoser:SetPos(ScrW()-300, ScrH()/2-320)
	colorChoser:SetColor(currentColor)
	colorChoser:SetVisible(false)
	function colorChoser:ValueChanged( color )
		currentColor = color
	end
	function colorButton.DoClick()
		colorChoser:SetVisible( !colorChoser:IsVisible() )
	end

	local pencil = vgui.Create("DButton",html)
	function pencil:Paint(w,h)
		if pencilMode then
			draw.RoundedBox(4,0,0,w,h,Color(229,57,53))
		else
			draw.RoundedBox(4,0,0,w,h,Color(240,240,240))
		end
	end
	pencil:SetFont("GPic_ButtonFont")
	pencil:SetText("Pencil")
	pencil:SetColor(Color(0,0,0))
	pencil:SetSize(90,30)
	pencil:SetPos(ScrW() - 90, ScrH()/2-15)
	function pencil.DoClick()
		cropMode = false
		pencilMode = !pencilMode
	end

	local isCropped = false
	local cropButton = vgui.Create("DButton",html)
	function cropButton:Paint(w,h)
		if isCropped or cropMode then
			draw.RoundedBox(4,0,0,w,h,Color(229,57,53))
		else
			draw.RoundedBox(4,0,0,w,h,Color(240,240,240))
		end
	end
	cropButton:SetFont("GPic_ButtonFont")
	cropButton:SetText("Crop")
	cropButton:SetColor(Color(0,0,0))
	cropButton:SetSize(90,30)
	cropButton:SetPos(ScrW()-90, ScrH()/2 + 25)
	function cropButton.DoClick()
		pencilMode = false
		if isCropped then
			cropSelection = {}
			isCropped = false
		else
			isCropped = true
			cropMode = !cropMode
		end
	end

	local send = vgui.Create("DButton", html)
	send:SetText("Share")
	function send:Paint(w,h)
		if self:IsHovered() then
			draw.RoundedBox(5,0,0,w,h,Color(55,148,59))
		else
			draw.RoundedBox(5,0,0,w,h,Color(67,160,71))
		end
	end
	send:SetColor(Color(224,224,224))
	send:SetFont("GPic_ButtonFont")
	send:SetSize(100,30)
	send:AlignRight(20)
	send:AlignBottom(20)
	function send.DoClick()
		local Menu = DermaMenu()
		Menu:AddOption("Save to data", function()
			close:SetVisible(false)
			send:SetVisible(false)
			pencil:SetVisible(false)
			colorButton:SetVisible(false)
			colorChoser:SetVisible(false)
			cropButton:SetVisible(false)
			timer.Simple(0.5, function() -- Make sure only the screenshot is visible
				local num = 0
				while true do
					if !file.Exists("screenshot_" .. num .. ".jpg", "DATA") then
						screenshot( function(screen) 
							file.Write("screenshot_" .. num .. ".jpg", screen)
							html:Remove()
							notification.AddLegacy("Screenshot saved to " .. "screenshot_" .. num .. ".jpg", NOTIFY_GENERIC, 5)
						end, cropSelection[3])
						break
					end
					num = num + 1
				end
			end)
		end):SetIcon("icon16/picture_save.png")
		Menu:AddOption("Upload", function()
			close:SetVisible(false)
			send:SetVisible(false)
			pencil:SetVisible(false)
			colorButton:SetVisible(false)
			timer.Simple(0.5, function() -- Make sure only the screenshot is visible
				screenshot( function(screen)
					notification.AddProgress(1, "Uploading your screenshot...")
					http.Post("https://g-pic.com/upload.php", { base64 = util.Base64Encode(screen) }, function(response, _,_, code)
						notification.Kill(1)
						local response = util.JSONToTable(response)
						if code == 200 then
							if !response["shareUrl"] then
								notification.AddLegacy("Error: check console", NOTIFY_ERROR, 5)
								print("Unknown response from website :")
								if istable(response) then
									PrintTable(response)
								else
									print(response)
									return
								end
							end
							notification.AddLegacy("Screenshot uploaded to: " .. response["shareUrl"], NOTIFY_GENERIC, 5)

							-- Show copy / open window

							local copyWindow = vgui.Create("DFrame")
							copyWindow:SetSize(200,40)
							copyWindow:SetPos(ScrW() - copyWindow:GetWide() - 20, ScrH() - copyWindow:GetTall() - 20)
							copyWindow:SetTitle("")
							copyWindow:ShowCloseButton(false)
							copyWindow:SetDraggable(false)
							copyWindow:MakePopup()
							function copyWindow:Paint(w,h)
								draw.RoundedBox(4,0,0,w,h,Color(48,48,48))
								surface.SetTextColor(Color(0,0,0))
							end

							local copyButton = vgui.Create("DButton",copyWindow)
							copyButton:SetText("Copy")
							copyButton:SetFont("Trebuchet24")
							copyButton:SetSize(copyWindow:GetWide() / 2 - 6, copyWindow:GetTall() - 8)
							copyButton:SetPos(4,4)
							copyButton:SetTextColor(Color(255,255,255))
							copyButton:SetTooltip(response["shareUrl"])
							function copyButton:Paint(w,h)
								if self:IsHovered() then
									draw.RoundedBox(4,0,0,w,h,Color(35, 132, 198))
								else
									draw.RoundedBox(4,0,0,w,h,Color(52, 152, 219))
								end
							end
							function copyButton:DoClick()
								SetClipboardText(response["shareUrl"])
								copyWindow:Close()
							end

							local openButton = vgui.Create("DButton",copyWindow)
							openButton:SetText("Open")
							openButton:SetFont("Trebuchet24")
							openButton:SetSize(copyWindow:GetWide() / 2 - 6,copyWindow:GetTall() - 8)
							openButton:SetPos(copyButton:GetWide() + 8, 4)
							openButton:SetTextColor(Color(255,255,255))
							openButton:SetTooltip(response["shareUrl"])
							function openButton:Paint(w,h)
								if self:IsHovered() then
									draw.RoundedBox(4,0,0,w,h,Color(29,29,29))
								else
									draw.RoundedBox(4,0,0,w,h,Color(0,0,0,0))
								end
							end
							function openButton:DoClick()
								gui.OpenURL(response["shareUrl"])
								copyWindow:Close()
							end
						elseif code == 500 then
							notification.AddLegacy("Error when creating screenshot file, please try again", NOTIFY_ERROR, 5)
						else
							notification.AddLegacy("Error while uploading your screenshot", NOTIFY_ERROR, 5)
						end
					end, function(response)
						notification.Kill(1)
						notification.AddLegacy("Error while uploading your screenshot", NOTIFY_ERROR, 5)
					end)
					html:Remove()
				end, cropSelection[3])
			end)
		end):SetIcon("icon16/picture_link.png")
		Menu:Open()
	end
end

concommand.Add("screen", function()
	screenshot( openScreenMenu )
end) -- bind f6 screen

hook.Add("OnPlayerChat","GPic_ChatScreenshot",function(ply, text)
	if string.Trim(text) == "!screen" then
		if ply ~= LocalPlayer() then return true end
		timer.Simple(0.5, function() -- wait for the chat to be fully closed
			screenshot( openScreenMenu )
		end)
		return true
	end
end)

if game.SinglePlayer() then -- Bind F6 to screen
	local isKeyStill = false
	hook.Add("Think","GPic_F6Press",function()
		if !isKeyStill and input.IsKeyDown(KEY_F6) then
			isKeyStill = true
			screenshot( openScreenMenu )
		elseif isKeyStill and !input.IsKeyDown(KEY_F6) then
			isKeyStill = false
		end
	end)
else
	hook.Add("Move","GPic_F6Press",function(ply)
		if input.WasKeyPressed(KEY_F6) and !gui.IsGameUIVisible() then
			screenshot( openScreenMenu )
		end
	end)
end

local icon = "icon16/pictures.png"
icon = file.Exists("materials/"..icon,'GAME') and icon or "icon64/playermodel.png"

list.Set(
	"DesktopWindows",
	"Screenshot",
	{
		title = "Screenshot",
		icon = icon,
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()
			icn:GetParent():GetParent():Close()
			RunConsoleCommand("screen")
		end
	}
)