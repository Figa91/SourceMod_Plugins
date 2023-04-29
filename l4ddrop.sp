#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define FL_PISTOL_PRIMARY (1<<6) //Is 1 when you have a primary weapon and dual pistols
#define FL_PISTOL (1<<7) //Is 1 when you have dual pistols
#define FAKS			1024
public Plugin:myinfo = 
{
	name = "L4D Drop Weapon",
	author = "Frustian",
	description = "Allows players to drop the weapon they are holding, or another weapon they have",
	version = "1.1",
	url = ""
}
new Handle:g_hSpecify;
new g_BeamSprite;
new g_HaloSprite;
//new Handle:FAK_Timer[FAKS+1]; 
public OnPluginStart()
{
	CreateConVar("l4d_drop_version", "1.1", "Drop Weapon Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hSpecify = CreateConVar("l4d_drop_specify", "1", "Allow people to drop weapons they have, but are not using",FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_med", Command_Drop2);
	RegConsoleCmd("sm_fak", Command_Drop2);
	RegConsoleCmd("sm_kit", Command_Drop2);
	LoadTranslations("drop.phrases");
}
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/glow08.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/glow08.vmt");
	PrecacheModel("particle/SmokeStack.vmt");
}
public Action:Command_Drop2(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;
	ClientCommand(client, "slot4");
	//DropSlot(client, 3);
	CreateTimer(1.0, DropFAK_Timer, client);
	return Plugin_Handled;
}
public Action:DropFAK_Timer(Handle:timer, any:client) 
{ 
	DropSlot(client, 3);
} 
public Action:Command_Drop(client, args)
{
	if (client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;
	new String:weapon[32];
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_drop [weapon]");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		if (GetConVarInt(g_hSpecify))
		{
			GetCmdArg(1, weapon, 32);
			if ((StrContains(weapon, "pump") != -1 || StrContains(weapon, "auto") != -1 || StrContains(weapon, "shot") != -1 || StrContains(weapon, "rifle") != -1 || StrContains(weapon, "smg") != -1 || StrContains(weapon, "uzi") != -1 || StrContains(weapon, "m16") != -1 || StrContains(weapon, "hunt") != -1) && GetPlayerWeaponSlot(client, 0) != -1)
				DropSlot(client, 0);
			else if ((StrContains(weapon, "pistol") != -1) && GetPlayerWeaponSlot(client, 1) != -1)
				DropSlot(client, 1);
			else if ((StrContains(weapon, "pipe") != -1 || StrContains(weapon, "mol") != -1) && GetPlayerWeaponSlot(client, 2) != -1)
				DropSlot(client, 2);
			else if ((StrContains(weapon, "kit") != -1 || StrContains(weapon, "pack") != -1 || StrContains(weapon, "med") != -1) && GetPlayerWeaponSlot(client, 3) != -1)
				DropSlot(client, 3);
			else if ((StrContains(weapon, "pill") != -1) && GetPlayerWeaponSlot(client, 4) != -1)
				DropSlot(client, 4);
			else
				PrintToChat(client, "%t", "drop_msg_1", weapon);
				//PrintToChat(client, "\x05Зелёный эльф: \x04Какой ещё \x03%s\x04! Мы же его ещё на прошлой карте пропили.", weapon);
		}
		else
			ReplyToCommand(client, "[SM] This server's settings do not allow you to drop a specific weapon.  Use sm_drop(/drop in chat) without a weapon name after it to drop the weapon you are holding.");
		return Plugin_Handled;
	}
	GetClientWeapon(client, weapon, 32);
	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle"))
		DropSlot(client, 0);
	else if (StrEqual(weapon, "weapon_pistol"))
		DropSlot(client, 1);
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov"))
		DropSlot(client, 2);
	else if (StrEqual(weapon, "weapon_first_aid_kit"))
		DropSlot(client, 3);
	else if (StrEqual(weapon, "weapon_pain_pills"))
		DropSlot(client, 4);
	return Plugin_Handled;
}
public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		decl String:username[MAX_NAME_LENGTH];
		GetClientName(client, username, sizeof(username));
		new String:sWeapon[32];
		new ammo;
		new clip;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), sWeapon, 32);
		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			ClientCommand(client, "vocalize PlayerSpotOtherWeapon");
			if (StrEqual(sWeapon, "weapon_pumpshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
				SetEntData(client, ammoOffset+(6*4), 0);
				PrintToChatAll("%t", "drop_msg_2", username);
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул помповый дробовик.", client);
			}
			else if (StrEqual(sWeapon, "weapon_autoshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
				SetEntData(client, ammoOffset+(6*4), 0);
				PrintToChatAll("%t", "drop_msg_22", username);
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул автоматический  дробовик.", client);
			}
			else if (StrEqual(sWeapon, "weapon_smg"))
			{
				ammo = GetEntData(client, ammoOffset+(5*4));
				SetEntData(client, ammoOffset+(5*4), 0);
				PrintToChatAll("%t", "drop_msg_3", username);
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул узи.", client);
			}
			else if (StrEqual(sWeapon, "weapon_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(3*4));
				SetEntData(client, ammoOffset+(3*4), 0);
				PrintToChatAll("%t", "drop_msg_4", username);
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул М16.", client);
			}
			else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(2*4));
				SetEntData(client, ammoOffset+(2*4), 0);
				PrintToChatAll("%t", "drop_msg_5", username);
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул винтовку.", client);
			}
		}
		if (slot == 1)
		{
			if ((GetEntProp(client, Prop_Send, "m_iAddonBits") & (FL_PISTOL|FL_PISTOL_PRIMARY)) > 0)
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1");
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol", sWeapon);
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
				if (clip < 15)
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", 0);
				else
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", clip-15);
				new index = CreateEntityByName(sWeapon);
				new Float:cllocation[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
				cllocation[2]+=20;
				TeleportEntity(index,cllocation, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(index);
				ActivateEntity(index);
				PrintToChatAll("%t", "drop_msg_6", username);
				ClientCommand(client, "vocalize PlayerSpotPistol");
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул пистолет.", client);
			}
			else 
				PrintToChat(client, "%t", "drop_msg_7");
				//PrintToChat(client, "\x05Зелёный эльф: \x04Это же наган твоей бабушки, твоя совесть не позволяет мне его выбросить.");
			return;
		}
		new index = CreateEntityByName(sWeapon);
		new Float:cllocation[3];
		new Float:kitangle[3] = {90.0, 0.0, 0.0};
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
		cllocation[2]+=20;
		if (StrEqual(sWeapon, "weapon_first_aid_kit"))
		{
			TeleportEntity(index,cllocation, kitangle, NULL_VECTOR);
		}
		else
		{
			TeleportEntity(index,cllocation, NULL_VECTOR, NULL_VECTOR);
		}
		decl item; 
		DispatchSpawn(index);
		ActivateEntity(index);
		RemovePlayerItem(client, item = GetPlayerWeaponSlot(client, slot));
		AcceptEntityInput(item, "Kill");
		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
		}
		if (slot == 3)
		{
			if (StrEqual(sWeapon, "weapon_first_aid_kit"))
			{
				PrintToChatAll("%t", "drop_msg_8", username);
				ClientCommand(client, "vocalize PlayerSpotFirstAid");
				//PrintToChatAll("\x05Зелёный эльф: \x04Игрок \x03%N\x04 выкинул anтeчкy.", client);
				//FAK_Timer[index] = CreateTimer(1.0, MedKitRing, index, TIMER_REPEAT);
				MedKitSmoke(index);
			}
		}
		if (slot == 2)
		{
			if (StrEqual(sWeapon, "weapon_pipe_bomb"))
			{
				PrintToChatAll("%t", "drop_msg_9", username);
				ClientCommand(client, "vocalize PlayerSpotGrenade");
			}
			else if (StrEqual(sWeapon, "weapon_molotov"))
			{
				PrintToChatAll("%t", "drop_msg_10", username);
				ClientCommand(client, "vocalize PlayerSpotMolotov");
			}
		}
		if (slot == 4)
		{
			if (StrEqual(sWeapon, "weapon_pain_pills"))
			{
				PrintToChatAll("%t", "drop_msg_11", username);
				ClientCommand(client, "vocalize PlayerSpotPills");
			}
		}
	}
	else if (GetPlayerWeaponSlot(client, slot) < 1)
	{
		if (slot == 3)
		{
			PrintToChat(client, "У Вас нет аптечки!");
		}
	}
}
public MedKitSmoke(index)
{
	new entity = CreateEntityByName("env_smokestack");
	new Float:kit_location[3];
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", kit_location);
	DispatchKeyValue(entity, "BaseSpread", "5");
	DispatchKeyValue(entity, "SpreadSpeed", "1");
	DispatchKeyValue(entity, "Speed", "30");
	DispatchKeyValue(entity, "StartSize", "10");
	DispatchKeyValue(entity, "EndSize", "1");
	DispatchKeyValue(entity, "Rate", "20");
	DispatchKeyValue(entity, "JetLength", "80");
	DispatchKeyValue(entity, "SmokeMaterial", "particle/SmokeStack.vmt");
	DispatchKeyValue(entity, "twist", "1");
	DispatchKeyValue(entity, "rendercolor", "255 0 0");
	DispatchKeyValue(entity, "renderamt", "255");
	DispatchKeyValue(entity, "roll", "0");
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchKeyValue(entity, "angles", "0 0 0");
	DispatchKeyValue(entity, "WindSpeed", "1");
	DispatchKeyValue(entity, "WindAngle", "1");
	TeleportEntity(entity, kit_location, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", index, entity);
	SetVariantString("OnUser1 !self:TurnOff::20.0:-1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	new iEnt = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEnt, "_light", "255 0 0");
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "6");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, kit_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	new String:szTarget[32];
	Format(szTarget, sizeof(szTarget), "lighthealthkit_%d", entity);
	DispatchKeyValue(entity, "targetname", szTarget);
	SetVariantString(szTarget);
	AcceptEntityInput(iEnt, "SetParent");
	AcceptEntityInput(iEnt, "TurnOn");
	SetVariantString("OnUser1 !self:TurnOff::20.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}

public Action:MedKitRing(Handle:timer, any:index) 
{
	static x = 0;
	if (++x < 10)
	{
		if (!IsValidEntity(index) || !IsValidEdict(index)) 
		{
			return Plugin_Stop;
		}
		new Float:cllocation[3];
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", cllocation);
		TE_SetupBeamRingPoint(	cllocation,	
								10.0,//10.0 - начальная диаметр
								50.0,//50.0 - конечная ширина
								g_BeamSprite,//g_BeamSprite - спрайт маяка
								g_HaloSprite,//g_HaloSprite - спрайт свечения
								0,
								15,
								1.0,//1.0 - время жизни маяка
								1.0,//2.0 - ширина линии
								0.0,//0.0 - колебания
								{255, 0, 0, 255},//{255, 0, 0, 255} - цвет
								10,//10 - скорость мерцания
								1);
		TE_SendToAll(); 		// Применяем
		return Plugin_Continue;
	}
	x = 0;
	return Plugin_Stop;
}
public OnClientPostAdminCheck(client)
{
	ClientCommand(client, "bind f3 sm_drop");
}