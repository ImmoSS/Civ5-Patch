----------------------------------------------------------------
-- edit:
--     MP voting system for EUI & vanilla UI
--     Civbot Integration
-- for EUI & vanilla UI
----------------------------------------------------------------
----------------------------------------------------------------
include( "IconSupport" );
include( "CommonBehaviors" );

local m_strAudio = "";
local m_bAllowBack = true;

----------------------------------------------------------------
----------------------------------------------------------------
function OnMainMenu()
	UIManager:DequeuePopup( ContextPtr );

	if (Game.IsHotSeat() and Game.CountHumanPlayersAlive() > 0) then
		local iActivePlayer = Game.GetActivePlayer();
		local pPlayer = Players[iActivePlayer];

		-- If the player is not alive, but there are other humans in the game that are
		-- find the next human player alive and make them the active player
		if (not pPlayer:IsAlive()) then
			local bFound = false;
			
			local iNextPlayer = iActivePlayer + 1;
			for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do		
				if (iNextPlayer >= GameDefines.MAX_MAJOR_CIVS) then
					iNextPlayer = 0;
				end 
				pPlayer = Players[iNextPlayer];
				if (iActivePlayer ~= iNextPlayer and pPlayer:IsAlive() and pPlayer:IsHuman()) then
					Game.SetActivePlayer( iNextPlayer );
					-- Restore the game state
					Game.SetGameState(GameplayGameStateTypes.GAMESTATE_ON);
					bFound = true;
					break;
				end
				iNextPlayer = iNextPlayer + 1;
			end
							
			UIManager:DequeuePopup( ContextPtr );
			Controls.BackgroundImage:UnloadTexture();	
			
			if (not bFound) then
				-- Fail safe
				Events.ExitToMainMenu();
			end
		else
			Events.ExitToMainMenu();
		end		
	else
		Events.ExitToMainMenu();
	end
end
Controls.MainMenuButton:RegisterCallback( Mouse.eLClick, OnMainMenu );

----------------------------------------------------------------
----------------------------------------------------------------
function OnBack()
	-- NEW: always allow back
	Network.SendExtendedGame();
	UIManager:DequeuePopup( ContextPtr );
	Controls.BackgroundImage:UnloadTexture();
end
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );

function GetVictoryAudio (strName) 
	for v in GameInfo.Victories() do 
		if (v.Type == strName) then
			return v.Audio;
		end
	end
	
	return nil;
end

----------------------------------------------------------------
----------------------------------------------------------------
local m_fTime = 0;
local deferredDisplayTime = 0;

function OnUpdate( fDTime )
	
	-- Cap the delta time to eliminate overshooting because of delays in processing.
	local fMaxDTime = fDTime;
	if (fMaxDTime > 0.1) then
		fMaxDTime = 0.1;
	end

	-- Delaying the display so we can see some animation?	
	if (deferredDisplayTime > 0) then
		-- Yes, hide the UI
		Controls.BGBlock:SetHide(true);
		Controls.BGWin:SetHide(true);
		deferredDisplayTime = deferredDisplayTime - fMaxDTime;
		if (deferredDisplayTime <= 0) then	
			Controls.BGBlock:SetHide(false);
			Controls.BGWin:SetHide(false);
			deferredDisplayTime = 0;
		end
	else
		local fNewTime = m_fTime + fMaxDTime;
		if (m_strAudio and m_fTime < 2 and fNewTime >= 2) then
			-- print("Play audio: " .. m_strAudio);
			Events.AudioPlay2DSound(m_strAudio);
		end
		
		if (g_AnimUpdate ~= nil) then
			if (g_AnimUpdate(fMaxDTime)) then
				g_AnimUpdate = nil;
			end
		end
		
		m_fTime = fNewTime;
	end	
	
end
ContextPtr:SetUpdate( OnUpdate );


----------------------------------------------------------------
----------------------------------------------------------------
function OnDisplay( type, team )
	-- NEW: skip sound and animations if opened again via button
	local bSkipIntro = false;
	if team == -2 then
		bSkipIntro = true;
		team = Game.GetWinner();
	end

	if(not ContextPtr:IsHidden()) then
		return;
	end

	-- Civbot Integration START
	if PreGame.IsInternetGame() then
		local victory = Game.GetVictory()
		local winner = Game.GetWinner()
		if victory == GameInfoTypes.VICTORY_SCRAP then
			winner = -1
		end
		if victory == GameInfoTypes.VICTORY_SCRAP or winner > -1 then
			netSendGameResult( winner, victory )
		end
	end
	-- Civbot Integration END
	
	UIManager:SetUICursor( 0 );
	m_strAudio = nil;
	m_bAllowBack = true;
	local bTutorialGame = false;
	local playerID = Game.GetActivePlayer();
	local player = Players[playerID];

	-- Hide the Beyond Earth button by default.
	if(Controls.BeyondButton ~= nil) then
		Controls.BeyondButton:SetHide(true);
		Controls.ButtonStack:CalculateSize();
		Controls.ButtonStack:ReprocessAnchoring();
	end

	if( team == Game.GetActiveTeam() ) then
    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_BANG" ) );
		local victoryType = nil;
		if( type == EndGameTypes.Tutorial1 ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_TUTORIAL_1_COMPLETE" ) );
	    	bTutorialGame = true;
		elseif( type == EndGameTypes.Tutorial2 ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_TUTORIAL_2_COMPLETE" ) );
	    	bTutorialGame = true;
		elseif( type == EndGameTypes.Tutorial3 ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_TUTORIAL_3_COMPLETE" ) );
	    	bTutorialGame = true;
		elseif( type == EndGameTypes.Tutorial4 ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_TUTORIAL_4_COMPLETE" ) );
	    	bTutorialGame = true;
		elseif( type == EndGameTypes.Tutorial5 ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_TUTORIAL_5_COMPLETE" ) );
	    	bTutorialGame = true;
		elseif( type == EndGameTypes.Technology ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_TECHNOLOGY" ) );
	    	victoryType = "VICTORY_SPACE_RACE";
	    	deferredDisplayTime = 7;
	    	
	    	-- Space victory, show BE button.
	    	if(Controls.BeyondButton ~= nil) then
	    		Controls.BeyondButton:SetHide(false);
	    		Controls.ButtonStack:CalculateSize();
				Controls.ButtonStack:ReprocessAnchoring();
	    	end
	    	
		elseif( type == EndGameTypes.Domination ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_DOMINATION" ) );
	    	victoryType = "VICTORY_DOMINATION";
		elseif( type == EndGameTypes.Culture ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_CULTURE" ) );
	    	victoryType = "VICTORY_CULTURAL";
		elseif( type == EndGameTypes.Diplomatic ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_DIPLOMACY" ) );
	    	victoryType = "VICTORY_DIPLOMATIC";
		elseif( type == EndGameTypes.Time ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_TIME" ) );
	    	victoryType = "VICTORY_TIME";
	    end
	    -- NEW: scrap victory
		if( Game.GetVictory() == GameInfoTypes.VICTORY_SCRAP ) then
	    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_SCRAP" ) );
	    	victoryType = "VICTORY_SCRAP";
		end
		
		if(victoryType ~= nil and PreGame.GetGameOption("GAMEOPTION_NO_EXTENDED_PLAY") ~= 1)then
			Controls.BackButton:SetDisabled( false );
		else
			-- NEW: always allow back
			--Controls.BackButton:SetDisabled( true );
			m_bAllowBack = false;
		end
			
		--print(victoryType);
		if(victoryType)then
			m_strAudio = GetVictoryAudio(victoryType);
			Controls.BackgroundImage:SetTexture(GameInfo.Victories[victoryType].VictoryBackground);    		
		else
			m_strAudio = GetVictoryAudio("VICTORY_TIME");
			Controls.BackgroundImage:SetTexture(GameInfo.Victories["VICTORY_TIME"].VictoryBackground); 		
		end
	else
		m_bAllowBack = false;
    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_DEFEAT_BANG" ) );
    	Controls.EndGameText:SetText( Locale.ConvertTextKey( "TXT_KEY_VICTORY_FLAVOR_LOSS" ) );
    	Controls.BackgroundImage:UnloadTexture();
    	Controls.BackgroundImage:SetTexture( "Victory_Defeat.dds" );
    	-- NEW: always allow back
		--Controls.BackButton:SetDisabled( true );
		if (not Game:IsNetworkMultiPlayer() and player:IsAlive() and PreGame.GetGameOption("GAMEOPTION_NO_EXTENDED_PLAY") ~= 1) then
			if( type == EndGameTypes.Technology ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == EndGameTypes.Domination ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == EndGameTypes.Culture ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == EndGameTypes.Diplomatic ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == EndGameTypes.Time ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == -1 ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			elseif( type == EndGameTypes.Loss ) then
				Controls.BackButton:SetDisabled( false );
				m_bAllowBack = true;
			end
		end

		m_strAudio = "AS2D_VICTORY_SPEECH_LOSS";
	end 

	Controls.RankingButton:SetHide( bTutorialGame );
	Controls.ReplayButton:SetHide( bTutorialGame );
	Controls.DemographicsButton:SetHide( bTutorialGame );
	
	local sizeY = Controls.EndGameText:GetSizeY();
	Controls.GameOverContainer:SetSizeY(sizeY + 30);
	
	-- NEW: skip sound and animations if opened again via button
	if bSkipIntro == true then
		m_strAudio = nil;
	else
		g_AnimUpdate = ZoomOutEffect{
			SplashControl = Controls.BackgroundImage, 
			ScaleFactor = 0.5,
			AnimSeconds = Game.GetVictory() == GameInfoTypes.VICTORY_SCRAP and 25 or 3
		};
	end
	
	UIManager:QueuePopup( ContextPtr, PopupPriority.EndGameMenu );
	
end
Events.EndGameShow.Add( OnDisplay );


----------------------------------------------------------------
----------------------------------------------------------------
function OnGameOver()
    Controls.Ranking:SetHide( true );
    Controls.EndGameReplay:SetHide( true );
    Controls.EndGameDemographics:SetHide( true );
    Controls.GameOverContainer:SetHide( false );
    Controls.BackgroundImage:SetColor({x=1,y=1,z=1,w=1});
end
Controls.GameOverButton:RegisterCallback( Mouse.eLClick, OnGameOver );


----------------------------------------------------------------
----------------------------------------------------------------
function OnDemographics()
    Controls.Ranking:SetHide( true );
    Controls.EndGameReplay:SetHide( true );
    Controls.EndGameDemographics:SetHide( false );
    Controls.GameOverContainer:SetHide( true );
    Controls.BackgroundImage:SetColor({x=1,y=1,z=1,w=0.125});
end
Controls.DemographicsButton:RegisterCallback( Mouse.eLClick, OnDemographics );


----------------------------------------------------------------
----------------------------------------------------------------
function OnReplay()
    Controls.Ranking:SetHide( true );
    Controls.EndGameReplay:SetHide( false );
    Controls.EndGameDemographics:SetHide( true );
    Controls.GameOverContainer:SetHide( true );
    Controls.BackgroundImage:SetColor({x=1,y=1,z=1,w=0.125});
end
Controls.ReplayButton:RegisterCallback( Mouse.eLClick, OnReplay );


----------------------------------------------------------------
----------------------------------------------------------------
function OnRanking()
    Controls.Ranking:SetHide( false );
    Controls.EndGameReplay:SetHide( true );
    Controls.EndGameDemographics:SetHide( true );
    Controls.GameOverContainer:SetHide( true );
    Controls.BackgroundImage:SetColor({x=1,y=1,z=1,w=0.125});
end
Controls.RankingButton:RegisterCallback( Mouse.eLClick, OnRanking );


----------------------------------------------------------------
-- Key Down Processing
----------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if( uiMsg == KeyEvents.KeyDown )
    then
        if( wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE ) then
			OnBack();
        end
    end
    return true;
end
ContextPtr:SetInputHandler( InputHandler );


----------------------------------------------------------------        
----------------------------------------------------------------        
function ShowHideHandler( bIsHide, bIsInit )

	CivIconHookup( Game.GetActivePlayer(), 80, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
    if( not bIsInit ) then
        if( not bIsHide ) then
            UI.incTurnTimerSemaphore();
			-- Display a continue button if there are other players left in the game
			local pPlayer = Players[Game.GetActivePlayer()];
			if (Game.IsHotSeat() and Game.CountHumanPlayersAlive() > 0 and not pPlayer:IsAlive()) then
				Controls.MainMenuButton:SetText( Locale.ConvertTextKey( "TXT_KEY_MP_PLAYER_CHANGE_CONTINUE" ) );
			else
				Controls.MainMenuButton:SetText( Locale.ConvertTextKey( "TXT_KEY_MENU_EXIT_TO_MAIN" ) );
			end
            ContextPtr:SetUpdate( OnUpdate );
			m_fTime = 0;
        else
            UI.decTurnTimerSemaphore();
        end
    end

end
ContextPtr:SetShowHideHandler( ShowHideHandler );


function ShowBeyondEarthStorePage()
	Steam.ActivateGameOverlayToStore(65980);
end
Controls.BeyondButton:RegisterCallback( Mouse.eLClick, ShowBeyondEarthStorePage);

-------------------------------------------------------------------------------
-- Civbot integration START
-------------------------------------------------------------------------------

-- lua json helpers
local function kind_of(obj)
	if type(obj) ~= 'table' then return type(obj) end
	local i = 1
	for _ in pairs(obj) do
		if obj[i] ~= nil then i = i + 1 else return 'table' end
	end
	if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
	for i, c in ipairs(in_char) do
		s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

local function skip_delim(str, pos, delim, err_if_missing)
	pos = pos + #str:match('^%s*', pos)
	if str:sub(pos, pos) ~= delim then
		if err_if_missing then
			error('Expected ' .. delim .. ' near position ' .. pos)
		end
		return pos, false
	end
	return pos + 1, true
end

local function parse_str_val(str, pos, val)
	val = val or ''
	local early_end_error = 'End of input found while parsing string.'
	if pos > #str then error(early_end_error) end
	local c = str:sub(pos, pos)
	if c == '"'  then return val, pos + 1 end
	if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
	-- We must have a \ character.
	local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
	local nextc = str:sub(pos + 1, pos + 1)
	if not nextc then error(early_end_error) end
	return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

local function parse_num_val(str, pos)
	local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
	local val = tonumber(num_str)
	if not val then error('Error parsing number at position ' .. pos .. '.') end
	return val, pos + #num_str
end

json = {}
function json.stringify(obj, as_key)
	local s = {}  -- We'll build the string as an array of strings to be concatenated.
	local kind = kind_of(obj)  -- This is 'array' if it's an array or type(obj) otherwise.
	if kind == 'array' then
		if as_key then error('Can\'t encode array as key.') end
		s[#s + 1] = '['
		for i, val in ipairs(obj) do
			if i > 1 then s[#s + 1] = ', ' end
			s[#s + 1] = json.stringify(val)
		end
		s[#s + 1] = ']'
	elseif kind == 'table' then
		if as_key then error('Can\'t encode table as key.') end
		s[#s + 1] = '{'
		for k, v in pairs(obj) do
			if #s > 1 then s[#s + 1] = ', ' end
			s[#s + 1] = json.stringify(k, true)
			s[#s + 1] = ':'
			s[#s + 1] = json.stringify(v)
		end
		s[#s + 1] = '}'
	elseif kind == 'string' then
		return '"' .. escape_str(obj) .. '"'
	elseif kind == 'number' then
		if as_key then return '"' .. tostring(obj) .. '"' end
		return tostring(obj)
	elseif kind == 'boolean' then
		return tostring(obj)
	elseif kind == 'nil' then
		return 'null'
	else
		error('Unjsonifiable type: ' .. kind .. '.')
	end
	return table.concat(s)
end

json.null = {}  -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
	pos = pos or 1
	if pos > #str then error('Reached unexpected end of input.') end
	local pos = pos + #str:match('^%s*', pos)  -- Skip whitespace.
	local first = str:sub(pos, pos)
	if first == '{' then  -- Parse an object.
		local obj, key, delim_found = {}, true, true
		pos = pos + 1
		while true do
			key, pos = json.parse(str, pos, '}')
			if key == nil then return obj, pos end
			if not delim_found then error('Comma missing between object items.') end
			pos = skip_delim(str, pos, ':', true)  -- true -> error if missing.
			obj[key], pos = json.parse(str, pos)
			pos, delim_found = skip_delim(str, pos, ',')
		end
	elseif first == '[' then  -- Parse an array.
		local arr, val, delim_found = {}, true, true
		pos = pos + 1
		while true do
			val, pos = json.parse(str, pos, ']')
			if val == nil then return arr, pos end
			if not delim_found then error('Comma missing between array items.') end
			arr[#arr + 1] = val
			pos, delim_found = skip_delim(str, pos, ',')
		end
	elseif first == '"' then  -- Parse a string.
		return parse_str_val(str, pos + 1)
	elseif first == '-' or first:match('%d') then  -- Parse a number.
		return parse_num_val(str, pos)
	elseif first == end_delim then  -- End of an object or array.
		return nil, pos + 1
	else  -- Parse true, false, or null.
		local literals = {['true'] = true, ['false'] = false, ['null'] = json.null}
		for lit_str, lit_val in pairs(literals) do
			local lit_end = pos + #lit_str - 1
			if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
		end
		local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10)
		error('Invalid json syntax starting at ' .. pos_info_str)
	end
end



if ExposedTypes.UIManager.Drafts == nil then
	PreGame.SetLeaderKey(7 * 2 ^ 28, "")  -- request dll to provide ExposedTypes.UIManager.Drafts
end
Drafts = ExposedTypes.UIManager.Drafts
Utils = ExposedTypes.UIManager.Utils
CivbotData = Modding.OpenUserData( 'CivbotIntegration', 1)
req1 = { tdelta = 0, pending = false, request = {} }
req2 = { tdelta = 0, pending = false, request = {} }

function netSendGameResult( winnerTeamID, winType )
	-- post draft data
	local key = CivbotData.GetValue('Key') or ''
	local frame = {
		Patch = Locale.Lookup('TXT_KEY_PATCH_VERSION'),
		Map = PreGame.GetMapScript(),
		Seed = Network.GetMapRandSeed(),
		LobbyID = Utils.GetLobbyID(),
		WorldSize = PreGame.GetWorldSize(),
		GameSpeed = PreGame.GetGameSpeed(),
		MinorCivs = PreGame.GetNumMinorCivs(),
		Era = PreGame.GetEra(),
		PlayerCount = Matchmaking.GetPlayerCount(),
		Draft = Drafts.GetDraftCurrentProgress() == 3 and 1 or 0,
		Players = {},
		WinnerTeam = winnerTeamID,
		WinType = winType,
	}
	for i = 0, GameDefines.MAX_MAJOR_CIVS do
		if( PreGame.GetSlotStatus( i ) == SlotStatus.SS_TAKEN and PreGame.GetSlotClaim( i ) == SlotClaim.SLOTCLAIM_ASSIGNED) then
			local pdata = Drafts.GetDraftPlayerData(i)
			local pbans = {}
			local ppicks = {}
			for civId in string.gmatch(pdata.Bans, '([^,]+)') do
				pbans[#pbans + 1] = tonumber(civId)
			end
			for civId in string.gmatch(pdata.Picks, '([^,]+)') do
				ppicks[#ppicks + 1] = tonumber(civId)
			end
			frame.Players[i] = {
				Slot = i,
				Name = Matchmaking.GetPlayerList()[i + 1].playerName or Locale.Lookup('TXT_KEY_MULTIPLAYER_DEFAULT_PLAYER_NAME', i + 1),
				Civ = PreGame.GetCivilization(i),
				Handicap = PreGame.GetHandicap(i),
				Draft = {
					Bans = pbans,
					Picks = ppicks,
				},
				Team = PreGame.GetTeam(i),
			}
		end
	end
	local strdata = json.stringify(frame)
	print('> req1', string.format('Api-Key: %s POSTDATA: %s', key, strdata))
	req1.tdelta = 0
	req1.pending = true
	req1.request = Network.HttpRequest({
		url='https://apitest.civ5.workers.dev/api/integration/game/result',
		method='POST',
		headers={
			'accept: application/json',
			string.format('Api-Key: %s', key),
		},
		postdata=strdata,
	})
end

Controls.NetLoop:RegisterAnimCallback(function()
	if req1.pending then
		req1.tdelta = req1.tdelta + 1
		if req1.request.Finished() then
			req1.pending = false
			local data = req1.request.PopReceivedData()
			print('< req1 finished:', data)
		elseif req1.tdelta == 10 then
			print('< req1 timeout')
			req1.pending = false
		end
	end
end)

-------------------------------------------------------------------------------
-- Civbot integration END
-------------------------------------------------------------------------------
