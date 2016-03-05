
local alerts = {}
local timers = {}
local do_sound = true
local chanfile = hs.configdir .. "/tvmenu_channels.conf"
local chanlist = {}
local tvgidsBar = hs.menubar.new()


-- writeChanlist() - save a channel list to a config file (JSON formatted)
function writeChanlist()
	local f = io.open(chanfile, "w")
	f:write(hs.json.encode(chanlist))
	f:close()
end


-- strToTime() - convert a string into a time object
function strToTime(str)
	local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
	local runyear, runmonth, runday, runhour, runminute, runseconds = str:match(pattern)
	return os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
end


-- pairsByKeys() - iterate over a sorted table
-- taken from http://www.lua.org/pil/19.3.html
function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

-- tvgidsIcon() - generate an icon for a given genre/type
function tvgidsIcon(genre, soort)
    if     soort == "Weerbericht"       then return "☔️"
    elseif soort == "Reisprogramma"     then return "✈️"
    elseif soort == "Woonprogramma"     then return "🏠"
    elseif soort == "Misdaadserie"      then return "🔫"
    elseif soort == "Kookprogramma"     then return "🍴"
    elseif soort == "Nieuwsbulletin" or soort == "Actualiteiten" or soort == "News"   then return "📰"
    elseif soort == "Dramaserie" or soort == "Serie/Soap"        then return "👥"
    elseif soort == "Fantasyserie"      then return "👑"
    elseif soort == "Sf-serie"          then return "👽"
    elseif soort == "Horrorserie"       then return "💀"
    elseif soort == "Medisch programma" then return "🚑"
    elseif soort == "Animatieserie"     then return "👾"
    elseif soort == "Detectiveserie"    then return "🔍"
    elseif soort == "Kunstprogramma" or soort == "Kunst en cultuur"    then return "🎨"
    elseif soort == "Kinderprogramma"   or soort == "Jeugd" or soort == "Jeugdserie" then return "👨‍👩‍👧‍👦"
    elseif soort == "Documentaire"      then return "🎦"
    elseif soort == "Actieserie"        then return "🚔"
    elseif genre == "Muziek"            then return "🎵"
    elseif genre == "Sport"             then return "⚽️"
    elseif genre == "Natuur"            then return "🌻"
    elseif genre == "Film"              then return "🎥"
    elseif genre == "Informatief"       then return "ℹ️"
    elseif genre == "Amusement" or soort == "Comedyserie"        then return "🎉"
    elseif genre == "Wetenschap"        then return "💡"
    elseif genre == "Religieus"         then return "🙏"
    else return "❓"
    end
end


-- checkAlarm() - callback for alarms, check if it's still active, if so alert the user
function checkAlarm(time)
	for d, t in pairs(alerts) do
		if d == time then
			for a, alarm in pairs(t) do 
				if (do_sound == true) then
					hs.sound.getByName("Purr"):play()
				end
				hs.notify.new({title="TVGids", informativeText="Nu op " .. alarm[1] .. ": " .. alarm[2]}):send()
			end
			alerts[d] = nil
		end
	end
	updateTVMenuBar()
end	


-- toggleAlarm() - turn alerting for a given item on or off
function toggleAlarm(date, channel, title)
	local found = false
	local removed = false
	for d, v in pairs(alerts) do
		if d == date then
			for a, b in pairs(v) do
				-- this alarm was in the list, so we need to remove it
				if b[1] == channel and b[2] == title then
					als = alerts[d]
					table.remove(als, a)
					local next = next
					if next(als) == nil then
						alerts[d] = nil
					else
						alerts[d] = als
					end
					removed = true
					hs.notify.new({title="TVGids - alarm verwijderd", informativeText="'" .. title .. "'' om " .. date .. " op " .. channel }):send()
				end
			end
		end	
	end
	-- no alarm found, then we need to add it
	if not removed then
		if not found then 
			alerts[date] = { { channel, title } }
			local alerttime = string.sub(date, 12, 16)
			timer = hs.timer.doAt(alerttime, function() checkAlarm(date) end)
			timers[date] = timer
		else
			table.insert(alerts[date], { channel, title })
		end
		hs.notify.new({title="TVGids - alarm ingesteld", informativeText="'" .. title .. "'' om " .. date .. " op " .. channel }):send()
	end

	-- force an update of the menu
	updateTVMenuBar()
end


-- getGuide() - get a list of tvshows for all channels specified, run `callback` for it
function getGuide(chanlist, callback)
   local chan_url = 'http://www.tvgids.nl/json/lists/channels.php'

   -- get a list of channel IDs
   hs.http.asyncGet(chan_url, nil, function(status, json_chan)
      local channels = hs.json.decode(json_chan)
      local ids = {}
      for key, chan in pairs(channels) do
          for _, c in pairs(chanlist) do
            if chan["name"] == c then
              table.insert(ids, chan["id"])
            end
          end
      end

      -- request today's guide for all wanted channels
      local prog_url = 'http://www.tvgids.nl/json/lists/programs.php?day=0&channels='..table.concat(ids, ',')
      hs.http.asyncGet(prog_url, nil, function(status, json_prog)
        local proglist = hs.json.decode(json_prog)
        callback(status, channels, proglist)
      end)
   end)
end


-- updateTVMenuBar() - update the menubar
function updateTVMenuBar()
	tvgidsBar:setTitle("📺")
	getGuide(chanlist, function(status, chans, progs)
		local menu = {}
		local chan_menu = {}
		local nu_menu = {}
		local straks_menu = {}

		for _, chan in pairs(chans) do
			local skip = false
			for _, c in pairs(chanlist) do
				if c == chan["name"] then
					skip = true
				end
			end	
			-- channel is not in favorites, so add it to the "Kanaal toevoegen" list
			if not skip then	
				table.insert(chan_menu, { title = chan["name"], fn=function()
					table.insert(chanlist, chan["name"])
					updateTVMenuBar()
					hs.notify.new({title="TVGids", informativeText="'" .. chan["name"] .. "' is toegevoegd aan het menu"}):send()
					writeChanlist()
				end
				})
			end
			for _, cl in pairsByKeys(chanlist) do
				if cl == chan["name"] then
					local submenu = {}
					local idx = 0
					for _, prog in pairsByKeys(progs[chan["id"]]) do
						local end_time = strToTime(prog["datum_end"])
						if (os.time() < end_time) then
							-- no alert function for the current programme
							if idx == 0 then
								table.insert(submenu, { title = string.sub(prog["datum_start"], 12, 16) .. "-" .. string.sub(prog["datum_end"], 12, 16) .. "\t" .. tvgidsIcon(prog["genre"], prog["soort"]) .."\t" .. prog["titel"] .. " (" ..prog["soort"] .. ")"})
							else
								table.insert(submenu, { title = string.sub(prog["datum_start"], 12, 16) .. "-" .. string.sub(prog["datum_end"], 12, 16) .. "\t" .. tvgidsIcon(prog["genre"], prog["soort"]) .."\t" .. prog["titel"] .. " (" ..prog["soort"] .. ")", fn = function()
									toggleAlarm(prog["datum_start"], chan["name"], prog["titel"]) 
								end})
							end

							-- add current and upcoming programme to menus
							if (idx == 0) then
								table.insert(nu_menu, { title = string.format("%6s\t", string.sub(chan["name_short"], 1, 6)) .. string.sub(prog["datum_start"], 12, 16) .. "-" .. string.sub(prog["datum_end"], 12, 16) .. "\t" .. tvgidsIcon(prog["genre"], prog["soort"]) .."\t" .. prog["titel"] .. " (" ..prog["soort"] .. ")"})
							elseif (idx == 1) then
								table.insert(straks_menu, { title = string.format("%6s\t", string.sub(chan["name_short"], 1, 6)) .. string.sub(prog["datum_start"], 12, 16) .. "-" .. string.sub(prog["datum_end"], 12, 16) .. "\t" .. tvgidsIcon(prog["genre"], prog["soort"]) .."\t" .. prog["titel"] .. " (" ..prog["soort"] .. ")", fn = function()
									toggleAlarm(prog["datum_start"], chan["name"], prog["titel"])
								end})
							end
							idx = idx + 1
						end
					end
					table.insert(submenu, {title = "-"})
					table.insert(submenu, {title = "Kanaal uit menu verwijderen", fn=function()
							for k, c in pairs(chanlist) do
								if c == chan["name"] then
									table.remove(chanlist, k)
								end
							end
							updateTVMenuBar()
							writeChanlist()
						end})
					table.insert(menu, {title = chan["name"], menu = submenu})
				end
			end
		end

		table.insert(menu, {title = "-"})
		table.insert(menu, {title = "Kanaal toevoegen", menu = chan_menu})
		local alarm_menu = {}
		local i = 0
		for d, a in pairs(alerts) do
			for k, i in pairs(a) do
				table.insert(alarm_menu, { title = string.sub(d, 12, 16) .. "\t" .. i[2] .. " op " .. i[1], fn=function()
					toggleAlarm(d, i[1], i[2])
				end})
			end
			i = i + 1
		end
		if next(chanlist) then
			table.insert(menu, {title = "-"})
			table.insert(menu, {title = "Nu op TV", menu = nu_menu})
			table.insert(menu, {title = "Straks op TV", menu = straks_menu})
		end
		table.insert(menu, {title = "-"})
		table.insert(menu, {title = "Alarmgeluid", checked = do_sound, fn=function() do_sound = not do_sound ; tvmenu.updateTVMenuBar();  end})
		if i > 0 then
			table.insert(menu, {title = "Alarmen", menu = alarm_menu})
		end		
		tvgidsBar:setMenu(menu)
	end)
end


-- read config file if it exists
local f = io.open(chanfile,"r")
if f ~= nil then 
	local content = f:read("*all")
	f:close()
	chanlist = hs.json.decode(content)
end

-- generate the menubar
updateTVMenuBar()

-- automatically update the menubar every 60 sec
t = hs.timer.doEvery(60, function() 
	updateTVMenuBar() 
end)
