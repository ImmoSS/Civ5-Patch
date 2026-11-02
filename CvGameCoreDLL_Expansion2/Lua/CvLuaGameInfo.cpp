/*	-------------------------------------------------------------------------------------------------------
	© 1991-2012 Take-Two Interactive Software and its subsidiaries.  Developed by Firaxis Games.  
	Sid Meier's Civilization V, Civ, Civilization, 2K Games, Firaxis Games, Take-Two Interactive Software 
	and their respective logos are all trademarks of Take-Two interactive Software, Inc.  
	All other marks and trademarks are the property of their respective owners.  
	All rights reserved. 
	------------------------------------------------------------------------------------------------------- */
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//!	 \file		CvLuaGameInfo.cpp
//!  \brief     Public interface to CvLuaGameInfo.
//!
//!		This file includes the implementation for exposing game infos to Lua.
//!
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#include <CvGameCoreDLLPCH.h>
#include "CvLuaSupport.h"
#include "CvLuaGameInfo.h"
#include <LuaExposures.h>

// Namespace aliases to reduce typing.
namespace Lua = FLua::Details;
using FLua::Table;

//------------------------------------------------------------------------------
void CvLuaGameInfo::Register(lua_State* L)
{
	//Register other game info structures.
	Lua::CCallWithErrorHandling(L, pRegisterActions);
	Lua::CCallWithErrorHandling(L, pRegisterTypesInfo);
}

//------------------------------------------------------------------------------
int CvLuaGameInfo::pRegisterActions(lua_State* L)
{
	lua_newtable(L);
	lua_pushvalue(L, -1);
	lua_setglobal(L, "GameInfoActions");

	const int t = lua_gettop(L);
	int idx = 0;

	typedef std::vector<CvActionInfo*> ActionInfos;
	ActionInfos& infos = GC.getActionInfo();
	for(ActionInfos::const_iterator it = infos.begin();
	        it != infos.end(); ++it)
	{
		CvActionInfo* pEntry = (*it);
		lua_createtable(L, 0, 0);

		Table kEntry(L, -1);

		kEntry["MissionData"]		= pEntry->getMissionData();
		kEntry["CommandData"]		= pEntry->getCommandData();

		kEntry["AutomateType"]		= pEntry->getAutomateType();
		kEntry["InterfaceModeType"]	= pEntry->getInterfaceModeType();
		kEntry["MissionType"]		= pEntry->getMissionType();
		kEntry["CommandType"]		= pEntry->getCommandType();
		kEntry["ControlType"]		= pEntry->getControlType();
		kEntry["OriginalIndex"]		= pEntry->getOriginalIndex();

		kEntry["ConfirmCommand"]	= pEntry->isConfirmCommand();
		kEntry["Visible"]			= pEntry->isVisible();
		kEntry["SubType"]			= (int)pEntry->getSubType();

		kEntry["Type"]				= pEntry->GetType();
		kEntry["TextKey"]			= pEntry->GetTextKey();

		kEntry["ActionInfoIndex"]	= pEntry->getActionInfoIndex();
		kEntry["HotKeyVal"]			= pEntry->getHotKeyVal();
		kEntry["HotKeyPriority"]	= pEntry->getHotKeyPriority();
		kEntry["HotKeyValAlt"]		= pEntry->getHotKeyValAlt();
		kEntry["HotKeyPriorityAlt"]	= pEntry->getHotKeyPriorityAlt();
		kEntry["OrderPriority"]		= pEntry->getOrderPriority();

		kEntry["AltDown"]			= pEntry->isAltDown();
		kEntry["ShiftDown"]			= pEntry->isShiftDown();
		kEntry["CtrlDown"]			= pEntry->isCtrlDown();
		kEntry["AltDownAlt"]		= pEntry->isAltDownAlt();
		kEntry["ShiftDownAlt"]		= pEntry->isShiftDownAlt();
		kEntry["CtrlDownAlt"]		= pEntry->isCtrlDownAlt();

		kEntry["HotKey"]			= pEntry->getHotKeyString();
		kEntry["Help"]				= pEntry->GetHelp();
		kEntry["DisabledHelp"]		= pEntry->GetDisabledHelp();

		lua_rawseti(L, t, idx);

		++idx;
	}

	return 0;
}
//------------------------------------------------------------------------------
int CvLuaGameInfo::pRegisterTypesInfo(lua_State* L)
{
	lua_newtable(L);
	lua_pushvalue(L, -1);
	lua_setglobal(L, "GameInfoTypes");

	const CvGlobals::InfosMap& kInfosMap = GC.GetInfoTypes();
	for(CvGlobals::InfosMap::const_iterator it = kInfosMap.begin();
	        it != kInfosMap.end(); ++ it)
	{
		lua_pushinteger(L, (*it).second);
		lua_setfield(L, -2, (*it).first.c_str());
	}

	return 0;
}
#ifdef INGAME_CIV_DRAFTER
void CvLuaDrafts::Register(lua_State* L)
{
	FLua::Details::CCallWithErrorHandling(L, pRegister);
}
//-----------------------------------------------------------------------------------
int CvLuaDrafts::pRegister(lua_State* L)
{
	lua_getglobal(L, "ExposedTypes");
	if (!lua_istable(L, -1))
	{
		SLOG("WARN table not found: ExposedTypes");
		return 0;
	}

	lua_pushstring(L, "UIManager");
	lua_gettable(L, -2);  // get ExposedTypes.UIManager
	if (!lua_istable(L, -1))
	{
		SLOG("WARN table not found: ExposedTypes.UIManager");
		return 0;
	}

	lua_createtable(L, 0, 6);

	lua_pushcclosure(L, lGetDraftPlayerData, 0);
	lua_setfield(L, -2, "GetDraftPlayerData");

	lua_pushcclosure(L, lGetDraftLocalSecret, 0);
	lua_setfield(L, -2, "GetDraftLocalSecret");
	
	lua_pushcclosure(L, lGetDraftLocalSecretHash, 0);
	lua_setfield(L, -2, "GetDraftLocalSecretHash");

	lua_pushcclosure(L, lGetDraftSettings, 0);
	lua_setfield(L, -2, "GetDraftSettings");

	//lua_pushcclosure(L, lGetDraftRemapVoteThreshold, 0);
	//lua_setfield(L, -2, "GetDraftRemapVoteThreshold");

	//lua_pushcclosure(L, lGetDraftRemapYesVotes, 0);
	//lua_setfield(L, -2, "GetDraftRemapYesVotes");

	lua_pushcclosure(L, lGetDraftCurrentProgress, 0);
	lua_setfield(L, -2, "GetDraftCurrentProgress");

	lua_pushcclosure(L, lIsPlayerReadyForDraft, 0);
	lua_setfield(L, -2, "IsPlayerReadyForDraft");

	//lua_pushcclosure(L, lIsPlayerReadyForRemap, 0);
	//lua_setfield(L, -2, "IsPlayerReadyForRemap");

	lua_setfield(L, -2, "Drafts");  // set ExposedTypes.UIManager.Drafts

	SLOG("FINISHED")

	return 0;
}
//------------------------------------------------------------------------------
int CvLuaDrafts::lGetDraftPlayerData(lua_State* L)
{
	int iPlayerID = lua_tointeger(L, 1);
	if (iPlayerID < 0 || iPlayerID >= MAX_MAJOR_CIVS)
		return 0;

	std::vector<CvString> vBans = CvPreGame::getDraftPlayerBans();
	std::vector<CvString> vPicks = CvPreGame::getDraftPlayerPicks();
	std::vector<CvString> vDiscPicks = CvPreGame::getDraftPlayerDiscardedPicks();

	size_t pos = 0;
	uint id;
	int k = 0;
	std::vector<CvString> vstr;
	CvString strBans;
	for (uint j = 0; j < vBans.size(); j++)
	{
		if ((pos = vBans[j].find(':')) != std::string::npos)
		{
			if (sscanf(vBans[j].substr(0, pos).c_str(), "%d", &id) == 1)
			{
				if (iPlayerID == id)
				{
					vstr.push_back(vBans[j].substr(pos + 1, vBans[j].length() - pos - 2));
				}
			}
		}
	}

	for (size_t j = 0; j < vstr.size(); j++) {
		strBans += vstr[j];
		strBans += ",";
	}

	//bool bHasVoted = false;
	//CvMPVotingSystem::Proposal* pProposal = GC.getGame().GetMPVotingSystem()->GetProposalByType(PROPOSAL_REMAP2);
	//if (pProposal != NULL) {
	//	bHasVoted = GC.getGame().GetMPVotingSystem()->GetVoterHasVoted(pProposal->iID, static_cast<PlayerTypes>(iPlayerID));
	//}

	lua_createtable(L, 0, 4);
	const int t = lua_gettop(L);

	lua_pushstring(L, strBans.substr(0, strBans.size() - 1).c_str());
	lua_setfield(L, t, "Bans");

	lua_pushstring(L, vPicks.at(iPlayerID).c_str());
	lua_setfield(L, t, "Picks");

	lua_pushstring(L, vDiscPicks.at(iPlayerID).c_str());
	lua_setfield(L, t, "DiscardedPicks");

	//lua_pushboolean(L, bHasVoted == true ? 1 : 0);
	//lua_setfield(L, t, "HasVotedRemap");

	return 1;
}
//------------------------------------------------------------------------------
int CvLuaDrafts::lGetDraftLocalSecret(lua_State* L)
{
	lua_pushstring(L, CvPreGame::getDraftLocalSecret().c_str());

	return 1;
}
//------------------------------------------------------------------------------
int CvLuaDrafts::lGetDraftLocalSecretHash(lua_State* L)
{
	lua_pushstring(L, CvPreGame::getDraftLocalSecretHash().c_str());

	return 1;
}
//------------------------------------------------------------------------------
int CvLuaDrafts::lGetDraftSettings(lua_State* L)
{
	lua_createtable(L, 0, 5);
	const int t = lua_gettop(L);

	lua_pushinteger(L, CvPreGame::getDraftNumBans());
	lua_setfield(L, t, "numBans");

	lua_pushinteger(L, CvPreGame::getDraftMinBans());
	lua_setfield(L, t, "minBans");

	lua_pushinteger(L, CvPreGame::getDraftNumPicks());
	lua_setfield(L, t, "numPicks");

	//lua_pushboolean(L, CvPreGame::getDraftDiscardPicks());
	//lua_setfield(L, t, "discardPicks");

	//lua_pushboolean(L, CvPreGame::getDraftIncrementVoteThreshold());
	//lua_setfield(L, t, "incVoteThreshold");

	return 1;
}
//------------------------------------------------------------------------------
//int CvLuaDrafts::lGetDraftRemapVoteThreshold(lua_State* L)
//{
//	lua_pushinteger(L, CvPreGame::getDraftRemapVoteThreshold());
//
//	return 1;
//}
//------------------------------------------------------------------------------
int CvLuaDrafts::lGetDraftCurrentProgress(lua_State* L)
{
	lua_pushinteger(L, CvPreGame::getDraftCurrentProgress());

	return 1;
}
//------------------------------------------------------------------------------
int CvLuaDrafts::lIsPlayerReadyForDraft(lua_State* L)
{
	int iPlayerID = lua_tointeger(L, 1);
	lua_pushboolean(L, (iPlayerID >= 0 && iPlayerID < MAX_CIV_PLAYERS && CvPreGame::IsDraftPlayerReady(static_cast<PlayerTypes>(iPlayerID))) ? 1 : 0);

	return 1;
}
//------------------------------------------------------------------------------
//int CvLuaDrafts::lIsPlayerReadyForRemap(lua_State* L)
//{
//	int iPlayerID = lua_tointeger(L, 1);
//	lua_pushboolean(L, (iPlayerID >= 0 && iPlayerID < MAX_CIV_PLAYERS && CvPreGame::IsDraftRemapPlayerReady(static_cast<PlayerTypes>(iPlayerID))) ? 1 : 0);
//
//	return 1;
//}
#endif
