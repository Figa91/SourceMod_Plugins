#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

int i_RestartRound;
int i_LevelDiff;
int i_NumOfPlayers;
int i_SaveLevelDiff;
int i_TempLevelDiff;
int i_CompareLevelDiff;

bool b_LockDifficulty;
bool b_MissionFalse;
bool b_TimeOutVote;
bool b_ExpertDifficulty;
bool g_votetype;

Handle h_Timer;
Handle h_Difficulty;
Handle h_GameMode;

public Plugin myinfo = {
	name = "AutoDifficulty",
	author = "Ren89, Figa",
	description = "Auto-balance difficulty.",
	version = "1.0",
	url = "http://fiksiki.3dn.ru"
};
public void OnPluginStart()
{
	RegConsoleCmd("callvote", Call_Vote_Handler);
	RegConsoleCmd("sm_diff", CallVoteChangeDifficulty);
	
	RegAdminCmd("sm_updiff", ADifficultyUp, ADMFLAG_ROOT, "Up Difficulty");
	RegAdminCmd("sm_downdiff", ADifficultyDown, ADMFLAG_ROOT, "Down Difficulty");
	RegAdminCmd("sm_check", CheckDifficulty, ADMFLAG_ROOT);
	RegAdminCmd("sm_info", AutoDifficultyInfo, ADMFLAG_RESERVATION);
	
	h_Difficulty = FindConVar("z_difficulty");
	h_GameMode = FindConVar("mp_gamemode");
	SetConVarString(FindConVar("hostname"), "L4D ghUB");
	
	//HookEvent("round_end",  Event_RoundEnd, EventHookMode_Pre);
	HookEvent("mission_lost",  Event_RoundEnd, EventHookMode_Pre);
	HookEvent("map_transition",  Event_MapTransition, EventHookMode_Pre);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
	
	HookConVarChange(h_Difficulty, ConVarChange_GameDifficulty);
	HookConVarChange(h_GameMode, ConVarChange_GameMode);
	
	LoadTranslations("AutoDifficulty.phrases");
}
public void OnMapStart()
{
	if (g_bFirstMap() && i_SaveLevelDiff != 0) i_SaveLevelDiff = 0;
	
	//i_LevelDiff = i_SaveLevelDiff;
	i_NumOfPlayers = 0;
	i_RestartRound = 0;
	b_LockDifficulty = false;
	b_MissionFalse = false;
	b_TimeOutVote = false;
	
	char s_zdifficulty[32];
	GetConVarString(FindConVar("z_difficulty"), s_zdifficulty, sizeof(s_zdifficulty));
	if (strcmp(s_zdifficulty, "easy", false) == 0 || strcmp(s_zdifficulty, "normal", false) == 0) ServerCommand("z_difficulty hard");
	
	char s_mpgamemode[32];
	GetConVarString(FindConVar("mp_gamemode"), s_mpgamemode, sizeof(s_mpgamemode));
	if (strcmp(s_mpgamemode, "coop", false) != 0) ServerCommand("mp_gamemode coop");
}
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	i_RestartRound++;
	b_MissionFalse = true;
	if (i_RestartRound == 1 && i_LevelDiff > 0)
	{
		DifficultyDown(false);
		i_RestartRound = 0;
	}
}
public Action Event_FinaleWin(Event event, const char[]name, bool dontBroadcast){i_SaveLevelDiff = 0;}
public Action Event_MapTransition(Event event, const char[]name, bool dontBroadcast)
{
	b_LockDifficulty = true;
	Count_TempLevelDiff();
	if (b_MissionFalse) i_SaveLevelDiff = i_LevelDiff - i_TempLevelDiff;
	else  i_SaveLevelDiff = (i_LevelDiff - i_TempLevelDiff) + 1;
	if (i_SaveLevelDiff < 0) i_SaveLevelDiff = 0;
}
public void OnClientConnected(int client)
{
	if (b_LockDifficulty) return;
	if (!IsFakeClient(client))
	{
		i_NumOfPlayers++;
		if (i_LevelDiff != 6) DifficultyUp(true);
	}
}
public Action ADifficultyUp(int client, int args)
{
	if (i_LevelDiff == 6)
	{
		if (client) PrintToChat(client, "[ROOT] Установлена максимальная сложность.");
		else PrintToServer("[CONSOLE] Установлена максимальная сложность.");
		return;
	}
	DifficultyUp(false);
	if (client) PrintToChat(client, "[ROOT] Сложность увеличена. %t", "DIFFICULTY_MSG_LEVEL", i_LevelDiff);
	else PrintToServer("[CONSOLE] Level Difficulty Up = %d", i_LevelDiff);
}
void DifficultyUp(bool b_connect = false)
{
	if (b_connect)
	{
		Count_TempLevelDiff();
		i_LevelDiff = i_TempLevelDiff + i_SaveLevelDiff;
		if (b_MissionFalse) i_LevelDiff -= i_RestartRound;
	}
	else
	{
		i_LevelDiff++;
		if (i_SaveLevelDiff < 5)i_SaveLevelDiff++;
	}
	SetDifficulty();
}
public void OnClientDisconnect(int client)
{
	if (b_LockDifficulty) return;
	if (!IsFakeClient(client))
	{
		i_NumOfPlayers--;
		if (i_LevelDiff != 0) DifficultyDown(true);
		if (i_NumOfPlayers == 0)
		{
			i_LevelDiff = 0;
			i_SaveLevelDiff = 0;
			SetDifficulty();
		}
	}
}
public Action ADifficultyDown(int client, int args)
{
	if (i_LevelDiff <= 1)
	{
		if (client) PrintToChat(client, "[ROOT] Установлена минимальная сложность.");
		else PrintToServer("[CONSOLE] Установлена минимальная сложность.");
		return;
	}
	DifficultyDown(false);
	if (client) PrintToChat(client, "[ROOT] Сложность уменьшена. %t", "DIFFICULTY_MSG_LEVEL", i_LevelDiff);
	else PrintToServer("[CONSOLE] Level Difficulty Down = %d", i_LevelDiff);
}
void DifficultyDown(bool b_disconnect = false)
{
	if (b_disconnect)
	{
		Count_TempLevelDiff();
		i_LevelDiff = i_TempLevelDiff + i_SaveLevelDiff;
		if (b_MissionFalse) i_LevelDiff -= i_RestartRound;
	}
	else
	{
		i_LevelDiff--;
		if (i_SaveLevelDiff > 0) i_SaveLevelDiff--;
	}
	SetDifficulty();
}
void SetDifficulty()
{
	if (i_LevelDiff > 6) i_LevelDiff = 6;
	if (i_LevelDiff < 0) i_LevelDiff = 0;
	if (i_LevelDiff == i_CompareLevelDiff) return;
	switch(i_LevelDiff)
	{
		case 0,1:
		{
			i_CompareLevelDiff = 1;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 50);
			SetConVarInt(FindConVar("z_common_limit"), 20);
			SetConVarInt(FindConVar("z_background_limit"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 15);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 180);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 180);
			SetConVarInt(FindConVar("z_mega_mob_size"), 60);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 420);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 900);
			SetConVarInt(FindConVar("z_must_wander"), -1);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 100);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 200);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 6);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 50);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 4);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 150);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 4);
			SetConVarInt(FindConVar("tongue_range"), 750);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 850);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 20);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 15);
			SetConVarInt(FindConVar("director_force_tank"), 0);
			SetConVarInt(FindConVar("director_ai_tanks"), 0);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 50);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 15);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 4);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 1);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 15);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 25);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 200);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 0);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 1);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 1);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 1);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 1);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 8000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 4000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 3);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 30);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 40);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 10.0");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.7");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 1.0");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 1.0");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 1.0");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 1.0");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 2.0");
			ServerCommand("sm_damage_weaponmulti weapon_smg 2.0");
		}
		case 2:
		{
			i_CompareLevelDiff = 2;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 90);
			SetConVarInt(FindConVar("z_common_limit"), 25);
			SetConVarInt(FindConVar("z_background_limit"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 15);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 180);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 180);
			SetConVarInt(FindConVar("z_mega_mob_size"), 75);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 420);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 900);
			SetConVarInt(FindConVar("z_must_wander"), 1);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 100);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 250);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 6);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 75);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 6);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 200);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 6);
			SetConVarInt(FindConVar("tongue_range"), 1000);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 1000);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 40);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 1);
			SetConVarInt(FindConVar("director_force_tank"), 1);
			SetConVarInt(FindConVar("director_ai_tanks"), 1);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 50);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 60);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 8);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 2);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 30);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 35);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 200);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 0);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 1);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 1);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 14000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 4000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 5);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 40);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 60);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 9.0");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.6");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 0.9");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 0.9");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 0.9");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 0.9");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 1.9");
			ServerCommand("sm_damage_weaponmulti weapon_smg 1.9");
		}
		case 3:
		{
			i_CompareLevelDiff = 3;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 90);
			SetConVarInt(FindConVar("z_common_limit"), 25);
			SetConVarInt(FindConVar("z_background_limit"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 25);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 180);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 180);
			SetConVarInt(FindConVar("z_mega_mob_size"), 75);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 420);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 900);
			SetConVarInt(FindConVar("z_must_wander"), 1);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 1);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 300);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 8);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 100);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 6);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 250);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 6);
			SetConVarInt(FindConVar("tongue_range"), 1200);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 1000);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 50);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 1);
			SetConVarInt(FindConVar("director_force_tank"), 1);
			SetConVarInt(FindConVar("director_ai_tanks"), 1);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 50);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 90);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 10);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 2);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 30);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 35);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 200);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 1);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 12000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 12000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 12000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 8000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 6000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 7);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 60);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 70);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 8.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 0.85");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 0.85");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 0.85");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 0.85");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 1.8");
			ServerCommand("sm_damage_weaponmulti weapon_smg 1.8");
		}
		case 4:
		{
			i_CompareLevelDiff = 4;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 90);
			SetConVarInt(FindConVar("z_common_limit"), 30);
			SetConVarInt(FindConVar("z_background_limit"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mega_mob_size"), 90);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 200);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 450);
			SetConVarInt(FindConVar("z_must_wander"), 0);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 1);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 300);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 10);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 100);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 8);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 250);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 8);
			SetConVarInt(FindConVar("tongue_range"), 1300);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 1000);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 70);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 1);
			SetConVarInt(FindConVar("director_force_tank"), 1);
			SetConVarInt(FindConVar("director_ai_tanks"), 1);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 30);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 150);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 12);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 2);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 25);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 30);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 150);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 100);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 1);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 16000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 16000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 12000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 10000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 10);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 70);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 90);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 8.0");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.4");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 0.8");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 1.7");
			ServerCommand("sm_damage_weaponmulti weapon_smg 1.7");
		}
		case 5:
		{
			i_CompareLevelDiff = 5;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 85);
			SetConVarInt(FindConVar("z_common_limit"), 30);
			SetConVarInt(FindConVar("z_background_limit"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 0);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 0);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mega_mob_size"), 150);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 90);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 450);
			SetConVarInt(FindConVar("z_must_wander"), 0);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 1);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 400);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 12);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 180);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 10);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 350);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 10);
			SetConVarInt(FindConVar("tongue_range"), 1400);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 1500);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 90);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 1);
			SetConVarInt(FindConVar("director_force_tank"), 1);
			SetConVarInt(FindConVar("director_ai_tanks"), 1);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 10);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 210);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 14);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 3);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 25);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 30);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 150);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 100);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 1);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 18000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 10000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 8000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 9);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 90);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 100);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 8.0");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.3");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 0.8");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 0.8");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 1.6");
			ServerCommand("sm_damage_weaponmulti weapon_smg 1.6");
		}
		case 6:
		{
			i_CompareLevelDiff = 6;
			// Mobs
			SetConVarInt(FindConVar("z_health"), 100);
			SetConVarInt(FindConVar("z_common_limit"), 30);
			SetConVarInt(FindConVar("z_background_limit"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), 20);
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_hard"), 0);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_hard"), 90);
			SetConVarInt(FindConVar("z_mob_spawn_min_interval_expert"), 0);
			SetConVarInt(FindConVar("z_mob_spawn_max_interval_expert"), 90);
			SetConVarInt(FindConVar("z_mega_mob_size"), 150);
			SetConVarInt(FindConVar("z_mega_mob_spawn_min_interval"), 90);
			SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), 450);
			SetConVarInt(FindConVar("z_must_wander"), 0);
			SetConVarInt(FindConVar("z_respawn_interval"), 1);
			SetConVarInt(FindConVar("z_respawn_distance"), 1);
			// Hunter
			SetConVarInt(FindConVar("z_hunter_health"), 500);
			SetConVarInt(FindConVar("hunter_pz_claw_dmg"), 12);
			SetConVarInt(FindConVar("z_pounce_stumble_force"), 5);
			// Boomer
			SetConVarInt(FindConVar("z_exploding_health"), 180);
			SetConVarInt(FindConVar("boomer_pz_claw_dmg"), 10);
			// Smooker
			SetConVarInt(FindConVar("z_gas_health"), 400);
			SetConVarInt(FindConVar("smoker_pz_claw_dmg"), 10);
			SetConVarInt(FindConVar("tongue_range"), 1500);
			// Witch
			SetConVarInt(FindConVar("z_witch_health"), 2000);
			SetConVarInt(FindConVar("l4d_witch_chance_attacknext"), 100);
			// Tank
			SetConVarInt(FindConVar("director_tank_checkpoint_interval"), 1);
			SetConVarInt(FindConVar("director_force_tank"), 1);
			SetConVarInt(FindConVar("director_ai_tanks"), 1);
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), b_ExpertDifficulty ? 100 : 0);
			SetConVarInt(FindConVar("tank_throw_allow_range"), 250);
			// l4d_autoIS
			SetConVarInt(FindConVar("l4d_ais_limit"), 14);
			SetConVarInt(FindConVar("l4d_ais_spawn_size"), 3);
			SetConVarInt(FindConVar("l4d_ais_time_min"), 15);
			SetConVarInt(FindConVar("l4d_ais_time_max"), 25);
			SetConVarInt(FindConVar("l4d_ais_boomer_weight"), 50);
			SetConVarInt(FindConVar("l4d_ais_hunter_weight"), 150);
			SetConVarInt(FindConVar("l4d_ais_smoker_weight"), 100);
			SetConVarInt(FindConVar("l4d_ais_safe_spawn"), 1);
			// l4d_multitanks
			SetConVarInt(FindConVar("mt_count_regular_coop"), 2);
			SetConVarInt(FindConVar("mt_health_regular_coop"), 24000);
			SetConVarInt(FindConVar("mt_count_finale_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finale_coop"), 24000);
			SetConVarInt(FindConVar("mt_count_finalestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart_coop"), 20000);
			SetConVarInt(FindConVar("mt_count_finalestart2_coop"), 2);
			SetConVarInt(FindConVar("mt_health_finalestart2_coop"), 14000);
			SetConVarInt(FindConVar("mt_count_escapestart_coop"), 2);
			SetConVarInt(FindConVar("mt_health_escapestart_coop"), 10000);
			// l4d_doorlock
			SetConVarInt(FindConVar("l4d_doorlock_rush"), 10);
			SetConVarInt(FindConVar("l4d_doorlock_secmin"), 100);
			SetConVarInt(FindConVar("l4d_doorlock_secmax"), 110);
			// weapon damage
			ServerCommand("sm_damage_tank_weaponmulti weapon_pumpshotgun 7.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_hunting_rifle 1.2");
			ServerCommand("sm_damage_tank_weaponmulti weapon_autoshotgun 0.7");
			ServerCommand("sm_damage_tank_weaponmulti weapon_rifle 2.5");
			ServerCommand("sm_damage_tank_weaponmulti weapon_smg 3.5");
			
			ServerCommand("sm_damage_weaponmulti weapon_pumpshotgun 0.7");
			ServerCommand("sm_damage_weaponmulti weapon_hunting_rifle 0.7");
			ServerCommand("sm_damage_weaponmulti weapon_autoshotgun 0.7");
			ServerCommand("sm_damage_weaponmulti weapon_rifle 1.5");
			ServerCommand("sm_damage_weaponmulti weapon_smg 1.5");
		}
	}
}
public Action AutoDifficultyInfo(int client, int args)
{
	if (client)
	{
		PrintToChat(client, "%t", "DIFFICULTY_MSG_TITLE");
		PrintToChat(client, "%t", "DIFFICULTY_MSG_LEVEL", i_LevelDiff);
		PrintToChat(client, "%t", "DIFFICULTY_MSG_1", i_NumOfPlayers, GetConVarInt(FindConVar("z_health")));
		PrintToChat(client, "%t", "DIFFICULTY_MSG_3", GetConVarInt(FindConVar("z_hunter_health")), GetConVarInt(FindConVar("z_gas_health")));
		PrintToChat(client, "%t", "DIFFICULTY_MSG_4", GetConVarInt(FindConVar("z_exploding_health")), GetConVarInt(FindConVar("z_witch_health")));
		PrintToChat(client, "%t", "DIFFICULTY_MSG_5", GetConVarInt(FindConVar("mt_count_regular_coop")), GetConVarInt(FindConVar("mt_health_regular_coop")));
		PrintToChat(client, "%t", "DIFFICULTY_MSG_END");
	}
	else
	{
		PrintToServer("%t", "DIFFICULTY_MSG_TITLE");
		PrintToServer("%t", "DIFFICULTY_MSG_LEVEL", i_LevelDiff);
		PrintToServer("%t", "DIFFICULTY_MSG_1", i_NumOfPlayers, GetConVarInt(FindConVar("z_health")));
		PrintToServer("%t", "DIFFICULTY_MSG_3", GetConVarInt(FindConVar("z_hunter_health")), GetConVarInt(FindConVar("z_gas_health")));
		PrintToServer("%t", "DIFFICULTY_MSG_4", GetConVarInt(FindConVar("z_exploding_health")), GetConVarInt(FindConVar("z_witch_health")));
		PrintToServer("%t", "DIFFICULTY_MSG_5", GetConVarInt(FindConVar("mt_count_regular_coop")), GetConVarInt(FindConVar("mt_health_regular_coop")));
		PrintToServer("%t", "DIFFICULTY_MSG_END");
	}
}
public Action CheckDifficulty(int client, int args)
{
	PrintToServer("Level Difficulty = %d", i_LevelDiff);
}
public Action Timer_FuncOut(Handle timer)
{
	b_TimeOutVote = false;
}
public Action CallVoteChangeDifficulty(int client, int args)
{
	Menu menu = new Menu(SelectAction);
	char SelectActionTitle[64], Value[64];
	
	Format(SelectActionTitle, sizeof(SelectActionTitle), "%T \n \n", "DIFFICULTY_MSG_SELECTDIFTITLE", client, i_LevelDiff);
	menu.SetTitle(SelectActionTitle);
	
	Format(Value, sizeof(Value), "⇑%T⇑", "DIFFICULTY_MSG_UPDIF", client);
	menu.AddItem("0", Value);
	
	Format(Value, sizeof(Value), "⇓%T⇓", "DIFFICULTY_MSG_DOWNDIF", client);
	menu.AddItem("1", Value);
	menu.ExitButton = false;
	menu.Display(client, 0);
}
public int SelectAction(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_Select)
	{
		if (option == 0) CallVoteUpDifficulty(client);
		else if (option == 1) CallVoteDownDifficulty(client);
	}
	else if (action == MenuAction_End) delete menu;
}
public Action CallVoteUpDifficulty(int client)
{
	if (h_Timer != null)
	{
		KillTimer(h_Timer);
		h_Timer = null;
	}
	if (IsVoteInProgress())
	{
		PrintToChat(client, "%t", "DIFFICULTY_MSG_VOTEALREADY");
		return;
	}
	if (b_TimeOutVote)
	{
		PrintToChat(client, "%t", "DIFFICULTY_MSG_TIMEOUT");
		return;
	}
	g_votetype = false;
	CreateTimer(60.0, Timer_FuncOut);
	b_TimeOutVote = true;
	
	//Считаем и записываем нужное число игроков по условиям
	int i_Clients[32], i_Count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) i_Clients[i_Count++] = i;
	}
	char name[64];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("%t", "DIFFICULTY_MSG_VOTESTART", name);
	
	Menu menu = new Menu(Handle_VoteMenu);
	
	char ChTitle[64];
	Format(ChTitle, sizeof(ChTitle), "⇑%T?⇑\n \n", "DIFFICULTY_MSG_UPDIF", client);
	menu.SetTitle(ChTitle);

	menu.AddItem("0", "Yes");
	menu.AddItem("1", "No");

	menu.ExitButton = false;

	//Показываем меню голосования нужным игрокам (Число и ID которых, ранее записали в цикле)
	menu.DisplayVote(i_Clients, i_Count, 15);
}
public Action CallVoteDownDifficulty(int client)
{
	if (h_Timer != null)
	{
		KillTimer(h_Timer);
		h_Timer = null;
	}
	if (IsVoteInProgress())
	{
		PrintToChat(client, "%t", "DIFFICULTY_MSG_VOTEALREADY");
		return;
	}
	if (b_TimeOutVote)
	{
		PrintToChat(client, "%t", "DIFFICULTY_MSG_TIMEOUT");
		return;
	}
	g_votetype = true;
	CreateTimer(60.0, Timer_FuncOut);
	b_TimeOutVote = true;
	
	//Считаем и записываем нужное число игроков по условиям
	int i_Clients[64], i_Count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) i_Clients[i_Count++] = i;
	}
	char name[64];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("%t", "DIFFICULTY_MSG_VOTESTART", name);
	
	Menu menu = new Menu(Handle_VoteMenu);
	
	char ChTitle[64];
	Format(ChTitle, sizeof(ChTitle), "⇓%T?⇓\n \n", "DIFFICULTY_MSG_DOWNDIF", client);
	menu.SetTitle(ChTitle);

	menu.AddItem("0", "Yes");
	menu.AddItem("1", "No");

	menu.ExitButton = false;

	//Показываем меню голосования нужным игрокам (Число и ID которых, ранее записали в цикле)
	menu.DisplayVote(i_Clients, i_Count, 15);
}
public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	//param1 - победивший пункт голосования (Голосование закончилось)
	else if (action == MenuAction_VoteEnd)
	{
		if (!g_votetype)
		{
			switch (param1)
			{
				case 0:
				{
					if (i_LevelDiff >= 6) PrintToChatAll("%t", "DIFFICULTY_MSG_GOD", i_LevelDiff);
					else
					{
						DifficultyUp(false);
						PrintToChatAll("%t", "DIFFICULTY_MSG_MOST_UP", i_LevelDiff);
					}
				}
				case 1:
				{
					PrintToChatAll("%t", "DIFFICULTY_MSG_MOST_CONST", i_LevelDiff);
				}
			}
		}
		else
		{
			switch (param1)
			{
				case 0:
				{
					if (i_LevelDiff <= 1)
					{
						PrintToChatAll("%t", "DIFFICULTY_MSG_NOOB", i_LevelDiff);
					}
					else
					{
						DifficultyDown(false);
						PrintToChatAll("%t", "DIFFICULTY_MSG_MOST_DOWN", i_LevelDiff);
					}
				}
				case 1:
				{
					PrintToChatAll("%t", "DIFFICULTY_MSG_MOST_CONST", i_LevelDiff);
				}
			}
		}
		if (h_Timer != null)
		{
			KillTimer(h_Timer);
			h_Timer = null;
		}
	}
}
public Action Call_Vote_Handler(int client, int args)
{
	char vote_Name[32];
	GetCmdArg(2,vote_Name,sizeof(vote_Name));
	if (strcmp(vote_Name,"easy",false) == 0 || strcmp(vote_Name,"normal",false) == 0)
	{
		if (IsClientInGame(client))
		{
			PrintToChat (client, "%t", "DIFFICULTY_MSG_BLOCK");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public void ConVarChange_GameDifficulty(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
	{
		char s_GameDifficulty[16];
		GetConVarString(h_Difficulty, s_GameDifficulty, sizeof(s_GameDifficulty));
		
		if (strcmp(s_GameDifficulty, "easy", false) == 0 || strcmp(s_GameDifficulty, "normal", false) == 0) SetConVarString(FindConVar("z_difficulty"), "hard");
		else if (strcmp(s_GameDifficulty, "hard", false) == 0)
		{
			b_ExpertDifficulty = false;
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), 50);
		}
		else if (strcmp(s_GameDifficulty, "impossible", false) == 0)
		{
			b_ExpertDifficulty = true;
			SetConVarInt(FindConVar("tank_rock_overhead_percent"), 100);
		}
	}
}
public void ConVarChange_GameMode(Handle convar, const char[]oldValue, const char[]newValue)
{
	if (strcmp(oldValue, newValue) != 0)
	{
		char s_GameMode[16];
		GetConVarString(h_GameMode, s_GameMode, sizeof(s_GameMode));
		if (strcmp(s_GameMode, "coop", false) != 0) SetConVarString(FindConVar("mp_gamemode"), "coop");
	}
}
void Count_TempLevelDiff()
{
	switch(i_NumOfPlayers)
	{
		case 0,1,2,3: i_TempLevelDiff = 1;
		case 4,5: i_TempLevelDiff = 2;
		case 6,7: i_TempLevelDiff = 3;
		case 8,9,10: i_TempLevelDiff = 4;
	}
}
bool g_bFirstMap()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (StrEqual(mapname, "l4d_river01_docks")			|| 
	StrEqual(mapname, "l4d_smalltown01_caves")			|| 
	StrEqual(mapname, "l4d_hospital01_apartment")		|| 
	StrEqual(mapname, "l4d_garage01_alleys")			||
	StrEqual(mapname, "l4d_farm01_hilltop")				||
	StrEqual(mapname, "l4d_airport01_greenhouse")		||
	StrEqual(mapname, "c3m1_plankcountry")				||
	StrEqual(mapname, "l4d_149_1")						||
	StrEqual(mapname, "l4d_city17_01")					||
	StrEqual(mapname, "l4d_coaldblood01")				||
	StrEqual(mapname, "l4d_de01_sewers")				||
	StrEqual(mapname, "l4d_deadcity01_riverside")		||
	StrEqual(mapname, "l4d_deathaboard01_prison")		||
	StrEqual(mapname, "l4d_stadium1_apartment")			||
	StrEqual(mapname, "l4d_ravenholmwar_1")				||
	StrEqual(mapname, "l4d_ihm01_forest")				||
	StrEqual(mapname, "Tunel")							||
	StrEqual(mapname, "Ulice")							||
	StrEqual(mapname, "l4d_derailed_highway3ver")		||
	StrEqual(mapname, "youcallthatalanding")			||
	StrEqual(mapname, "l4d_dbd_citylights")				||
	StrEqual(mapname, "l4d_viennacalling_city")			||
	StrEqual(mapname, "AirCrash")						||
	StrEqual(mapname, "l4d_cine")						||
	StrEqual(mapname, "l4d_nt01_mansion")				||
	StrEqual(mapname, "l4d_sh01_oldsh")) return true;
	return false;
}
