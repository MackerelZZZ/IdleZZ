local gif = require "gif" -- a pure-Lua GIF parser
local bit = require "bit"
local base64 = require "base64"
local json = require("dkjson")


--find a json library



is_fullscreen = false

-- gif stuff
local current_gif = nil
local current_gif_frame = nil
local elapsed = 0
local frame_duration = 0.1
local is_gif = false


function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest") -- set filter type
	background_red, background_green, background_blue= 1,1,1 --customizable
	background_music= nil	--customizable
	background_image=nil
	width, height = love.window.getDesktopDimensions(0)
	love.window.setMode(width, height, {fullscreen=is_fullscreen, fullscreentype="desktop"})

	width, height = love.graphics.getDimensions()
	
	--box setup
	bounce_image= nil	--cutomizable
	bounce_size = 0.20
	local min_dimension = math.min(width, height)
	box_width = min_dimension * bounce_size
	box_height = box_width


	box_x, box_y = (width - box_width) / 2, (height - box_height) / 2

	bounce_v = 200 --customizable

	--movement setup
	box_dx=bounce_v --horizontal speed
	box_dy=bounce_v --verticle speed
	
	settings = false
	corner_count=0
	
	drag_file=false
	current_image = nil
	selector=0

	--random fun stuff
	corner_hitbox=5
	corner_count=0
	in_corner=false
	print("Save directory:", love.filesystem.getSaveDirectory())

end

local imageData = nil


function love.update(dt)
	currentTime = os.date("%H:%M:%S") 
	fullDate = os.date("%Y-%m-%d")
	shortDay = os.date("%a")
	
	baseFontSize = 24
	referenceHeight = 1080
	scaledFontSize = math.floor(baseFontSize * (height / referenceHeight))
	uiFont = love.graphics.newFont(scaledFontSize)
	love.graphics.setFont(uiFont)

	
	uitext = tostring(fullDate .. "(" .. shortDay .. ") " .. currentTime)
	uitext_x, uitext_y = width-(0.60*scaledFontSize)*#uitext, 0
	textui_outline= 2
	
	--move box 
	box_x = box_x + box_dx * dt 
	box_y = box_y + box_dy * dt 
	if box_x <= 0 then 
		box_x = 0 
		box_dx = -box_dx
	elseif box_x + box_width >= width then
		box_x = width - box_width 
		box_dx = -box_dx
	end
	
	if box_y <= 0 then 
		box_y = 0 
		box_dy = -box_dy
	elseif box_y + box_height >= height then
		box_y = height - box_height
		box_dy = -box_dy
	end

	if box_x<corner_hitbox and box_y<corner_hitbox or box_x + box_width > width-corner_hitbox and box_y + box_height<corner_hitbox then -- dont actually know if this code works
		corner_count=corner_count+1
		in_corner=true
	else
		om_corner=false
	end
	
	if box_x<corner_hitbox and box_y>height+corner_hitbox or box_x +box_width > width-corner_hitbox and box_y>height-corner_hitbox then
		corner_count=corner_count+1
		in_corner=true
	else
		in_corner=false
	end


    -- GIF frame update 
    if is_gif and current_gif then
		elapsed = elapsed + dt
		if elapsed >= frame_duration then
			elapsed = elapsed - frame_duration
			if current_gif.next_image("always") then
				local w, h = current_gif.get_width_height()
				local matrix = current_gif.read_matrix()

				if not imageData then
					imageData = love.image.newImageData(w, h)
					current_gif_frame = love.graphics.newImage(imageData)
				end

				for y = 1, h do
					for x = 1, w do
						local color = matrix[y][x]
						if color == -1 then
							imageData:setPixel(x-1, y-1, 0,0,0,0)
						else
							local r = (bit.rshift(color, 16) % 256) / 255
							local g = (bit.rshift(color, 8) % 256) / 255
							local b = (color % 256) / 255
							imageData:setPixel(x-1, y-1, r, g, b, 1)
						end
					end
				end

				current_gif_frame:replacePixels(imageData)
				frame_duration = (current_gif.get_image_parameters().delay_in_ms or 100)/1000
			end
		end
	end
end


local f11Pressed = false --fulscreen


function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
	
	if key == "f11" and not f11Pressed then
		toggleFullscreen()
        f11Pressed = true
    end
	
	if key == "i" then
		if settings == false then
			settings=true
		else
			settings=false
		end
	end
	
	if settings == true then
		if key == "1" then --bounce image select
			drag_file=true
			selector=1
		elseif key == "2" then --background color select
			drag_file=true
			selector=2
		elseif key=="3" then --background music select
			drag_file=true
			selector=3
		elseif key=="4" then --save theme
			save_theme()
		end
	end
end

function love.keyreleased(key)
    if key == "f11" then
        f11Pressed = false
    end
end

local function loadGIF(filename)
    current_gif = gif(filename)
    elapsed = 0
    frame_duration = (current_gif.get_image_parameters().delay_in_ms or 100) / 1000
    is_gif = true

    -- Decode the first frame into an Image
    local w, h = current_gif.get_width_height()
    local matrix = current_gif.read_matrix()
    local imageData = love.image.newImageData(w, h)

    for y = 1, h do
        for x = 1, w do
            local color = matrix[y][x]
            if color == -1 then
                imageData:setPixel(x-1, y-1, 0,0,0,0)
            else
                local r = (bit.rshift(color, 16) % 256)/255
                local g = (bit.rshift(color, 8) % 256)/255
                local b = (color % 256)/255
                imageData:setPixel(x-1, y-1, r,g,b,1)
            end
        end
    end

    current_gif_frame = love.graphics.newImage(imageData)
end


function love.filedropped(file)	--file  dropped stuffed
    if drag_file then
        local name = file:getFilename()

        if name:match("%.png$") or name:match("%.jpg$") or name:match("%.jpeg$") then
            local success, image_data = pcall(love.image.newImageData, file)
            if success then
                local image = love.graphics.newImage(image_data)
                print("Dropped file: " .. name)
                print("Selector is: " .. tostring(selector))

                if selector == 1 then
                    bounce_image = image
                    bounce_image_data = image_data
                elseif selector == 2 then
                    background_image = image
                    background_image_data = image_data
                end

                drag_file = false
            else
                print("Failed to load image:", image_data)
            end
        elseif name:lower():match("%.gif$") then
            if selector == 1 then
				print("Dropped file: " .. name)
				print("Selector is: " .. tostring(selector))

				loadGIF(file:getFilename())  
				bounce_image = nil
				current_image = nil
			end
			drag_file = false
        elseif name:lower():match("%.mp3$") or name:lower():match("%.wav$") then
            local success, music = pcall(love.audio.newSource, file, "stream")
            if success then
                background_music = music
                background_music_path = file:getFilename()
                local f = io.open(background_music_path, "rb")
                if f then
                    background_music_bytes = f:read("*all")
                    f:close()
                end

                if selector == 3 then
                    background_music:setLooping(true)
                    background_music:play()
                end
                drag_file = false
            else
                print("Failed to load background music:", music)
                drag_file = false
            end
        end
    end
end





function toggleFullscreen()
    is_fullscreen = not is_fullscreen

    local desktop_w, desktop_h = love.window.getDesktopDimensions(0)
    local new_w, new_h = 800, 600

    if is_fullscreen then new_w, new_h = desktop_w, desktop_h end

    
    love.window.setMode(new_w, new_h, {fullscreen = is_fullscreen, fullscreentype = "desktop"})

    
    width, height = love.graphics.getDimensions()

    
    local min_dimension = math.min(width, height)
    box_width = min_dimension * bounce_size
    box_height = box_width

    
    box_x = math.min(math.max(box_x, 0), width - box_width)
    box_y = math.min(math.max(box_y, 0), height - box_height)
end


function love.draw()
	if background_image then
		love.graphics.setColor(1, 1, 1)
		

		local img_w = background_image:getWidth()
		local img_h = background_image:getHeight()
		local scale_x = width / img_w
		local scale_y = height / img_h

		love.graphics.draw(background_image, 0, 0, 0, scale_x, scale_y)
	else
		love.graphics.clear(background_red, background_green, background_blue) --clears the screen
	end
	if drag_file==false then
		if bounce_image then --box image
		
			width, height = love.graphics.getDimensions()

			local min_dimension = math.min(width, height)
			box_width = min_dimension * bounce_size
			box_height = box_width
		
			local img_w = bounce_image:getWidth()
			local img_h = bounce_image:getHeight()
			local scale_x = box_width / img_w
			local scale_y = box_height / img_h
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(bounce_image, math.floor(box_x + 0.5), math.floor(box_y + 0.5), 0, scale_x, scale_y)

		elseif is_gif and current_gif_frame then --gif stuff
			local scale_x = box_width / current_gif_frame:getWidth()
			local scale_y = box_height / current_gif_frame:getHeight()
			love.graphics.setColor(1,1,1)
			love.graphics.draw(current_gif_frame, box_x, box_y, 0, scale_x, scale_y)
		else
			love.graphics.setColor(1, 0, 0) -- red color set
			love.graphics.rectangle("fill", box_x, box_y, box_width, box_height)
		end
		
	
	love.graphics.setColor(0, 0, 0) --outline
	love.graphics.print(uitext, uitext_x - textui_outline, uitext_y)
	love.graphics.print(uitext, uitext_x + textui_outline, uitext_y)
	love.graphics.print(uitext, uitext_x, uitext_y - textui_outline)
	love.graphics.print(uitext, uitext_x, uitext_y + textui_outline)
	
	love.graphics.setColor(1,1,1) --main text
	love.graphics.print(uitext,uitext_x,uitext_y)

				
		if settings == true then
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("(1)set box image/gif (2)set background image (3)set background music  (4)save layout (5)load layout", 0,0)
			
		else
			love.graphics.setColor(0, 0, 0)
			love.graphics.print("corner_count:" .. corner_count, 0,0)
		end
		
	else
		love.graphics.setColor(0, 0, 0)
		love.graphics.print("drag file here")
	end
end

--save stuff


function save_theme()
    print("Starting save_theme()")
    local theme = {
        box_size = bounce_size,
        box_speed = bounce_v
    }

    -- Save box image
    if bounce_image_data then
        print("Encoding box image...")
        local pngdata = bounce_image_data:encode("png")
        theme.box_image = base64.encode(pngdata:getString())
        print("Box image saved!")
    else
        print("No valid box image data found.")
    end

    -- Save background image
    if background_image_data then
        print("Encoding background image...")
        local pngdata = background_image_data:encode("png")
        theme.bg_image = base64.encode(pngdata:getString())
        print("Background image saved!")
    else
        print("No valid background image data found.")
    end

    -- Save background music
    if background_music_bytes then
        theme.bg_music = base64.encode(background_music_bytes)
        print("Background music saved!")
    else
        print("No background music data found.")
    end

    print("Encoding JSON...")
    local encoded, err = json.encode(theme, { indent = true })
    if not err then
        love.filesystem.write("theme.json", encoded)
        print("Theme saved successfully at:", love.filesystem.getSaveDirectory())
    else
        print("Error saving theme:", err)
    end
end



function load_theme()
    if not love.filesystem.getInfo("theme.json") then print("No saved theme found.") return end

    local contents = love.filesystem.read("theme.json")
    local theme = json.decode(contents)

    -- Decode box image
    if theme.box_image then
        local bytes = base64.decode(theme.box_image)
        local fileData = love.filesystem.newFileData(bytes, "box.png")
        local imgData = love.image.newImageData(fileData)
        bounce_image_data = imgData
        bounce_image = love.graphics.newImage(imgData)
    end

    -- Decode background image
    if theme.bg_image then
        local bytes = base64.decode(theme.bg_image)
        local fileData = love.filesystem.newFileData(bytes, "bg.png")
        local imgData = love.image.newImageData(fileData)
        background_image_data = imgData
        background_image = love.graphics.newImage(imgData)
    end

    -- Decode background music
    if theme.bg_music then
        local bytes = base64.decode(theme.bg_music)
        local fileData = love.filesystem.newFileData(bytes, "music.mp3")
        background_music_bytes = bytes
        background_music = love.audio.newSource(fileData, "stream")
        background_music:setLooping(true)
    end

    bounce_size = theme.box_size or 0.2
    bounce_v = theme.box_speed or 200

    print("✅ Theme loaded successfully!")
end
