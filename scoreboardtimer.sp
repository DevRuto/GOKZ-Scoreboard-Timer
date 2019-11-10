#define PLUGIN_AUTHOR "Ruto"
#define PLUGIN_VERSION "0.04"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gokz/core>

#pragma newdecls required
#pragma semicolon 1

Handle ScoreboardTimers[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "GOKZ Scoreboard Info", 
	author = PLUGIN_AUTHOR, 
	description = "Shows Time, Checkpoints, and Teleports in Kills/Assists/Death respectively in scoreboard", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/DevRuto/GOKZ-Scoreboard-Timer"
};


// CSGO/SM events

public APLRes AskPluginLoad2(Handle h, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	RegPluginLibrary("scoreboardtimer");
	return APLRes_Success;
}

public void GOKZ_OnFirstSpawn(int client)
{
	KillClientTimer(client);
}

public void GOKZ_OnJoinTeam(int client, int team)
{
	KillClientTimer(client);
}

public void OnClientDisconnect(int client)
{
	KillClientTimer(client);
}

public Action TimerHandler(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0)
	{
		return;
	}

	if (ScoreboardTimers[client] == INVALID_HANDLE)
	{
		return;
	}

	float time = GOKZ_GetTime(client);
	SetKills(client, RoundToNearest(time));
}


// GOKZ Events
public void GOKZ_OnTimerStart_Post(int client, int course)
{
	ResetClient(client);
	CreateClientTimer(client);
}

public void GOKZ_OnPause_Post(int client)
{
	// Kill timer on pause
	KillClientTimer(client);
}

public void GOKZ_OnResume_Post(int client)
{
	// Create new timer
	CreateClientTimer(client);
}

public void GOKZ_OnMakeCheckpoint_Post(int client)
{
	SetAssist(client, GOKZ_GetCheckpointCount(client));
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	SetDeath(client, GOKZ_GetTeleportCount(client));
}

public void GOKZ_OnTimerStopped(int client)
{
	ResetClient(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	ResetClient(client);
}

// helpers

void CreateClientTimer(int client)
{
	int userid = GetClientUserId(client);
	ScoreboardTimers[client] = CreateTimer(1.0, TimerHandler, userid, TIMER_REPEAT);
}

void KillClientTimer(int client)
{
	// https://forums.alliedmods.net/showthread.php?t=205039
	if (ScoreboardTimers[client] != null)
	{
		KillTimer(ScoreboardTimers[client]);
		ScoreboardTimers[client] = null;
	}
}

// Timer
void SetKills(int client, int kills)
{
	SetEntProp(client, Prop_Data, "m_iFrags", kills);
}

// Checkpoints
void SetAssist(int client, int assist)
{
	//https://forums.alliedmods.net/showthread.php?t=198659
	SetEntData(client, FindDataMapInfo(client, "m_iFrags") + 4, assist);
}

// Teleports
void SetDeath(int client, int death)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", death);
}

// Reset timer
void ResetClient(int client)
{
	KillClientTimer(client);
	SetKills(client, 0);
	SetAssist(client, 0);
	SetDeath(client, 0);
} 
