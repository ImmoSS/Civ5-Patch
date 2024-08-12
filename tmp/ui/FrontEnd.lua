-------------------------------------------------
-- FrontEnd
-------------------------------------------------

function ShowHideHandler( bIsHide, bIsInit )

		-- Check for game invites first.  If we have a game invite, we will have flipped 
		-- the Civ5App::eHasShownLegal and not show the legal/touch screens.
		UI:CheckForCommandLineInvitation();
		
    if( not UI:HasShownLegal() ) then
        UIManager:QueuePopup( Controls.LegalScreen, PopupPriority.LegalScreen );
    end

    if( not bIsHide ) then
        UIManager:SetUICursor( 0 );
        UIManager:QueuePopup( Controls.MainMenu, PopupPriority.MainMenu );
        --Controls.AtlasLogo:SetTexture( "CivilzationVAtlas.dds" );
        local rand = math.random(3);
        if (rand == 3) then
            Controls.AtlasLogo:SetTexture( string.format("3_loading_%d.dds", math.random(18)) );
        elseif (rand == 2) then
            Controls.AtlasLogo:SetTexture( string.format("2_loading_%d.dds", math.random(12)) );
        else
            Controls.AtlasLogo:SetTexture( string.format("1_loading_%d.dds", math.random(20)) );
        end
    else
        Controls.AtlasLogo:UnloadTexture();
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );
