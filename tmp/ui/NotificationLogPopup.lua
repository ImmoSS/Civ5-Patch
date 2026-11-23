-- edit:
--     Notification Log Search
-- for EUI & Vanilla UI
-------------------------------------------------
-- Notification Log Search START
g_NotificationEntries = {}
-- Notification Log Search END
-------------------------------------------------
-- Notification Log Popup
-------------------------------------------------
include( "IconSupport" );
include( "InstanceManager" );
local g_NotificationInstanceManager = InstanceManager:new( "NotificationButton", "Button", Controls.NotificationButtonStack );
local m_PopupInfo = nil;

-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	if( popupInfo.Type ~= ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG ) then
		return;
	end
	
	-- Set Civ Icon
	CivIconHookup( Game.GetActivePlayer(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );
	
	m_PopupInfo = popupInfo;
	
	g_NotificationInstanceManager:ResetInstances();

	local player = Players[Game.GetActivePlayer()];
	local numNotifications = player:GetNumNotifications();
	for i = 0, numNotifications - 1
	do
		local str = player:GetNotificationStr((numNotifications - 1) - i);
		local index = player:GetNotificationIndex((numNotifications - 1) - i);
		local turn = player:GetNotificationTurn((numNotifications - 1) - i);
		local dismissed = player:GetNotificationDismissed((numNotifications - 1) - i);
		AddNotificationButton(index, str, turn, dismissed);
	end
	
	Controls.NotificationButtonStack:CalculateSize();
	Controls.NotificationButtonStack:ReprocessAnchoring();
	Controls.NotificationScrollPanel:CalculateInternalSize();
	
	if( m_PopupInfo.Data1 == 1 ) then
    	if( ContextPtr:IsHidden() == false ) then
    	    OnClose();
        else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
    	end
	else
    	UIManager:QueuePopup( ContextPtr, PopupPriority.NotificationLog );
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AddNotificationButton( id, description, turn, dismissed )	

	local controlTable = g_NotificationInstanceManager:GetInstance();
	-- Notification Log Search START
	g_NotificationEntries[#g_NotificationEntries + 1] = controlTable
	-- Notification Log Search END
	controlTable.NotificationText:SetText(description);
	controlTable.NotificationTurnText:SetText(Locale.ConvertTextKey("TXT_KEY_TP_TURN_COUNTER", turn));
    controlTable.Button:SetVoid1( id ); -- indicates type
    controlTable.Button:SetVoid2( void );
    controlTable.Button:SetDisabled( dismissed );
    
    controlTable.TextStack:CalculateSize();
    controlTable.TextStack:ReprocessAnchoring();
    
    local sizeY = controlTable.TextStack:GetSizeY()
    controlTable.Button:SetSizeY(sizeY);
    controlTable.TextAnim:SetSizeY(sizeY);
    controlTable.TextHL:SetSizeY(sizeY);
    
    controlTable.Button:RegisterCallback( Mouse.eLClick, NotificationSelected );
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function NotificationSelected (id)
    OnClose();
	UI.ActivateNotification(id);
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnClose ()
    UIManager:DequeuePopup( ContextPtr );
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN then
            OnClose();
            return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_NOTIFICATION_LOG, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnClose);

-------------------------------------------------------------------------------
-- Notification Log Search
-------------------------------------------------------------------------------
local escape_matches = {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
}
function OnLogSearch( str )
    -- ctrl+backspace START
    if string.find(str, '\127') then
        local s1, s2 = string.match(str, '(.-)\127(.*)')
        local r = 0
        s1, r = s1:gsub('[^%p%s]+[%p%s]*$', function(m) return '\127'..m end)
        if r > 0 then
            s1 = s1:match('(.-)\127')
            Controls.LogSearchEdit:SetText(s1)
        else
            s1 = Locale.Substring(s1, 1, Locale.Length(s1) - 1)
            Controls.LogSearchEdit:SetText(s1)
        end
        UI.PostKeyMessage(Keys.VK_END)
        ContextPtr:SetUpdate(function() ContextPtr:ClearUpdate(); Controls.LogSearchEdit:SetText(string.format('%s%s', Controls.LogSearchEdit:GetText(), s2)) end)
        str = string.format('%s%s', s1, s2)
    end
    -- ctrl+backspace END
    if str and #str > 0 then
        Controls.LogSearchPlaceholder:SetHide(true);
    else
        Controls.LogSearchPlaceholder:SetHide(false);
    end
    for _, entry in next, g_NotificationEntries do
        local res = string.find(Locale.ToLower(entry.NotificationText:GetText():gsub('%b[]','')), Locale.ToLower(str:gsub('.', escape_matches)))
        entry.Button:SetHide( not res )
    end
    Controls.NotificationButtonStack:CalculateSize();
    Controls.NotificationButtonStack:ReprocessAnchoring();
    Controls.NotificationScrollPanel:CalculateInternalSize();
end
Controls.LogSearchEdit:RegisterCallback( OnLogSearch );
