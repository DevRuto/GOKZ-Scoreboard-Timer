#define DEBUG

#define PLUGIN_AUTHOR "Ruto"
#define PLUGIN_VERSION "0.01"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <gokz/core>

#pragma newdecls required
#pragma semicolon 1

bool g_bGOKZ = false; 
Handle ScoreboardTimers[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "GOKZ Scoreboard Info",
	author = PLUGIN_AUTHOR,
	description = "Shows Time, Checkpoints, and Teleports in Kills/Assists/Death respectively in scoreboard",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle h, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin is only for CS:GO.");
	}
	
	RegPluginLibrary("scoreboardtimer");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// TODO: do something with this
	g_bGOKZ = LibraryExists("gokz-core");
}

public void OnPluginStart()
{
	
}

public void OnClientDisconnect(int client)
{
	KillClientTimer(client);
}

public Action TimerHandler(Handle timer, int client) {
	float time = GOKZ_GetCurrentTime(client);
	SetScore(client, RoundToNearest(time));
}


// GOKZ Events
public void GOKZ_OnTimerStart_Post(int client, int course) {
	ResetClient(client);
	ReplyToCommand(client, "OnTimerStart");
	ScoreboardTimers[client] = CreateTimer(1.0, TimerHandler, client, TIMER_REPEAT);
}

public void GOKZ_OnPause_Post(int client) {
	ReplyToCommand(client, "OnPause");
	// Kill timer on pause
	KillClientTimer(client);
}

public void GOKZ_OnResume_Post(int client) {
	ReplyToCommand(client, "OnResume");
	// Create new timer
	ScoreboardTimers[client] = CreateTimer(1.0, TimerHandler, client, TIMER_REPEAT);
}

public void GOKZ_OnMakeCheckpoint_Post(int client) {
	ReplyToCommand(client, "OnMakeCheckpoint");
	SetAssist(client, GOKZ_GetCheckpointCount(client)); 
}

public void GOKZ_OnCountedTeleport_Post(int client) {
	ReplyToCommand(client, "OnCountedTeleport");
	SetDeath(client, GOKZ_GetTeleportCount(client));
}

public void GOKZ_OnTimerStopped(int client) {
	ReplyToCommand(client, "OnTimerStop");
	ResetClient(client);
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed) {
	ResetClient(client);
}

// things

void KillClientTimer(int client) {
	// https://forums.alliedmods.net/showthread.php?t=205039
	if (ScoreboardTimers[client] != INVALID_HANDLE)
	{
		KillTimer(ScoreboardTimers[client]);
		ScoreboardTimers[client] = INVALID_HANDLE;
	}
}

// Timer
void SetScore(int client, int score) {
	SetEntProp(client, Prop_Data, "m_iFrags", score);
}

// Checkpoints
void SetAssist(int client, int assist) {
	//https://forums.alliedmods.net/showthread.php?t=198659
	SetEntData(client, FindDataMapOffs(client, "m_iFrags") + 4, assist);
}

// Teleports
void SetDeath(int client, int death) {
	SetEntProp(client, Prop_Data, "m_iDeaths", death);
}

// Reset timer
void ResetClient(int client) {
	if (ScoreboardTimers[client] != null)
	{
		KillTimer(ScoreboardTimers[client]);
		ScoreboardTimers[client] = null;
	}
	SetScore(client, 0);
	SetAssist(client, 0); 
	SetDeath(client, 0);
}