#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
///r_drawothermodels   : 1        : , "cheat", "cl"  : 0=Off, 1=Normal, 2=Wireframe
///r_drawstaticprops                        : 1        : , "cheat"        : 0=Off, 1=Normal, 2=Wireframe
new ObjectOfObsession[MAXPLAYERS + 1];
new bool:ObjectControlCooldown[MAXPLAYERS + 1];
new ObjectControlLevel[MAXPLAYERS + 1];
new bool:UseCooldown[MAXPLAYERS + 1];
new bool:g_CustomEntity[2048];
new bool:g_EntityPhysics[2048];
new g_EntityFlag[2048];
new g_sprite;
new g_BeamSprite;
new g_HaloSprite;
new Handle:ScanEnt[MAXPLAYERS+1];
new FoundEnt[MAXPLAYERS+1];
new String:StringHammer[MAXPLAYERS+1][32];

new count = 0;

new String:L4D_ModelNames[2407][128];
new ClientModelPosition[MAXPLAYERS+1] = 0;

new String:Map_ModelNames[2049][256];
new ClientMapModelPosition[MAXPLAYERS+1] = 0;

new LastEntity[MAXPLAYERS+1];
public OnPluginStart()
{
	RegConsoleCmd("saveit", CMD_save);	
	RegConsoleCmd("build", CMD_build);	
	RegConsoleCmd("delete", CMD_delete);	
	RegConsoleCmd("findit", CMD_find);	
	RegConsoleCmd("killit", CMD_KillLast);
	RegConsoleCmd("weapon", CMD_Weapon);	
}
public OnMapStart()
{
	PrecacheSound("UI/menu_countdown.wav", true);
	PrecacheSound("UI/BeepClear.wav", true);
	PrecacheSound("UI/Beep07.wav", true);
	PrecacheSound("UI/menu_invalid.wav", true);
	PrecacheSound("player/orch_hit_Csharp_short.wav", true);
	PrecacheSound("UI/Beep_Error01.wav", true);	
	PrecacheSound("UI/BigReward.wav", true);	
	PrecacheSound("UI/Menu_Click01.wav", true);
	g_sprite = PrecacheModel("sprites/lgtning.vmt");
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	count = 0;
	CMD_load();
	
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))	
	{
		if (ScanEnt[client] != INVALID_HANDLE)
		{
			KillTimer(ScanEnt[client]);
			ScanEnt[client] = INVALID_HANDLE;
		}
	}
}
public Action:CMD_KillLast(client, args)
{
	if(LastEntity[client]>0 && IsValidEntity(LastEntity[client]))
	{
		AcceptEntityInput(LastEntity[client], "Kill");
	}
	return Plugin_Handled;
}	
public Action:CMD_delete(client, args)
{
	if(IsValidClient(client)) 
	{
		if (ScanEnt[client] != INVALID_HANDLE)
		{
			KillTimer(ScanEnt[client]);
			ScanEnt[client] = INVALID_HANDLE;
		}
		ScanEnt[client] = CreateTimer(0.1, ScanDisplay, client, TIMER_REPEAT);        
	}
	return Plugin_Handled;
}
public Action:ScanDisplay(Handle:timer, any:client)
{
	if(!IsValidAliveClient(client))
	{
		if (ScanEnt[client] != INVALID_HANDLE)
		{
			KillTimer(ScanEnt[client]);
			ScanEnt[client] = INVALID_HANDLE;
		}
	}
	else
	{

		new Float:pos[3];
		new Float:angle[3];
		new Float:hitpos[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, angle);	
		
		new ent=GetEntity(client, hitpos ,MASK_SHOT, angle, pos);

		if(ent>0 && !g_CustomEntity[ent])
		{
			if(ent != FoundEnt[client])
			{
				decl String:classname[64];
				GetEdictClassname(ent, classname, 64);

				decl String:hammerStr[32];
				new hammerInt = (GetEntProp(ent, Prop_Data, "m_iHammerID", 32));
				IntToString(hammerInt, hammerStr, 32);
				decl String:model[256];
				GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
				
				FoundEnt[client] = ent;
				StringHammer[client] = hammerStr;
				
				new Handle:panel = CreatePanel();
				new String:text[64];	
				Format(text, sizeof(text), " ENTITY termination radar ");	
				SetPanelTitle(panel, text);
				Format(text, sizeof(text), "=========================");	
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "Entity FOUND");
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "-------------------------");
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "%s", classname);
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "%s", model);
				DrawPanelText(panel, text);			
				if(StrEqual(hammerStr, "0"))
				{
					Format(text, sizeof(text), "Hammer ID - %s", hammerStr);
					DrawPanelText(panel, text);
					Format(text, sizeof(text), "WARNNING! not recommended to remove entity");
					DrawPanelText(panel, text);
				}
				else
				{
					Format(text, sizeof(text), "Hammer ID - %s", hammerStr);
					DrawPanelText(panel, text);					
				}	
				
				Format(text, sizeof(text), "-------------------------");
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "============================");
				DrawPanelText(panel, text);			
				Format(text, sizeof(text), "☞ Terminate Entity");
				DrawPanelItem(panel, text);
				Format(text, sizeof(text), "============================");
				DrawPanelText(panel, text);			
				Format(text, sizeof(text), "☞ Change Entity coordinates");
				DrawPanelItem(panel, text);
				Format(text, sizeof(text), "============================");			
				Format(text, sizeof(text), "➧ Stop proccessing of search");	
				DrawPanelItem(panel, text);
				Format(text, sizeof(text), "============================");
				DrawPanelText(panel, text);
				SendPanelToClient(panel, client, DeleteHandler, 30);
				CloseHandle(panel);			
				EmitSoundToClient(client, "UI/BigReward.wav");
			}
			
		}
		else
		{
			FoundEnt[client] = 0;
			StringHammer[client] = "";
			
			new Handle:panel = CreatePanel();
			new String:text[64];	
			Format(text, sizeof(text), " ENTITY termination radar ");	
			SetPanelTitle(panel, text);
			Format(text, sizeof(text), "=========================");	
			DrawPanelText(panel, text);
			Format(text, sizeof(text), "Searching ...");
			DrawPanelText(panel, text);
			Format(text, sizeof(text), "-------------------------");
			DrawPanelText(panel, text);
			Format(text, sizeof(text), " Please target an object ");
			DrawPanelText(panel, text);
			Format(text, sizeof(text), "============================");
			DrawPanelText(panel, text);			

			SendPanelToClient(panel, client, DeleteHandler, 1);
			CloseHandle(panel);	
		}		
	}
}
public DeleteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1: 
			{
				if(AddFilter(param1, ""))
				{
					if(IsValidEntity(FoundEnt[param1]))
					{
						if(!AcceptEntityInput(FoundEnt[param1], "Kill")) RemoveEdict(FoundEnt[param1]);
					}	
					FoundEnt[param1] = 0;
					StringHammer[param1] = "";
					PrintHintText(param1, "Removed");				
					EmitSoundToClient(param1, "UI/Beep07.wav");					
				}
			} 
		case 2:
			{
				if(AddFilter(param1, ""))
				{

					new String:AuthId[64];
					GetClientAuthString(param1, AuthId, sizeof(AuthId));
					if(DispatchKeyValue(FoundEnt[param1], "targetname", AuthId))
					{
						decl String:classname[64];
						GetEdictClassname(FoundEnt[param1], classname, 64);
						if(StrEqual(classname, "prop_physics")) g_EntityPhysics[FoundEnt[param1]] = true;
						
						if(StrEqual(classname, "prop_physics") ||
								StrEqual(classname, "prop_physics_override") ||
								StrEqual(classname, "prop_dynamic") ||
								StrEqual(classname, "prop_dynamic_override")) 
						{
							PrintToChat(param1, "\x03This Entity will be saved with \x01CORRECT \x03properties");
						}
						else
						{
							PrintToChat(param1, "\x05WARNNING! \x03This Entity will not be saved with \x01CORRECT \x03properties");							
						}	
						g_CustomEntity[FoundEnt[param1]] = true;
						FoundEnt[param1] = 0;
						StringHammer[param1] = "";
						PrintHintText(param1, "Hook this Entity by pressing USE");
						EmitSoundToClient(param1, "UI/Menu_Click01.wav");
					}
					else
					PrintHintText(param1, "Can not procceed this option");
				}				
			}
		case 3:
			{
				if (ScanEnt[param1] != INVALID_HANDLE)
				{
					KillTimer(ScanEnt[param1]);
					ScanEnt[param1] = INVALID_HANDLE;
				}
				FoundEnt[param1] = 0;
				StringHammer[param1] = "";
				new Handle:panel = CreatePanel();
				new String:text[64];	
				Format(text, sizeof(text), "=========================");	
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "Searching Canceled");
				DrawPanelText(panel, text);
				Format(text, sizeof(text), "=========================");
				DrawPanelText(panel, text);			
				SendPanelToClient(panel, param1, Handler, 1);
				CloseHandle(panel);					
			} 				 
		}
	}
	else if (action == MenuAction_Cancel) 
	{ 

	}	
}

public Handler(Handle:menu, MenuAction:action, param1, param2)
{
}
bool:AddFilter(client, String:HammerID[])
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));

	new String:path[255];
	Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);

	new Handle:file = OpenFile(path, "a");
	if (file == INVALID_HANDLE)
	{
		PrintToChatAll("Could not open Stripper config file \"%s\" for writing.", path);
		return false;
	}

	WriteFileLine(file, "filter:");
	WriteFileLine(file, "{");
	if(StrEqual(HammerID, "")) WriteFileLine(file, "\"hammerid\" \"%s\"", StringHammer[client]);
	else WriteFileLine(file, "\"hammerid\" \"%s\"", HammerID);
	WriteFileLine(file, "}");
	CloseHandle(file);
	return true;
}
GetEntity(client,  Float:hitpos[3],  flag, Float:angle[3], Float:pos[3], Float:offset=-50.0)
{
	new Handle:trace=TR_TraceRayFilterEx(pos, angle, flag, RayType_Infinite, TraceRayDontHitSelf, client); 
	new ent=-1; 
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		ent=TR_GetEntityIndex(trace); 
		decl Float:vec[3];
		GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec, vec);
		ScaleVector(vec,  offset);
		AddVectors(hitpos, vec, hitpos);
	}
	CloseHandle(trace);  
	return ent;
}

public Action:CMD_build(client, args)
{
	if(IsValidClient(client)) 
	{
		ClientModelPosition[client] = 0;
		OpenBuildMenu(client);
	}
	return Plugin_Handled;
}	

OpenBuildMenu(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), " MODEL  %d / %d", ClientModelPosition[client]+1, count);	
	SetPanelTitle(panel, text);
	
	Format(text, sizeof(text), "↑⇧");	
	DrawPanelItem(panel, text);
	
	if(ClientModelPosition[client]>0)
	{
		Format(text, sizeof(text), "%s", L4D_ModelNames[ClientModelPosition[client]-1]);
		DrawPanelText(panel, text);
	}	
	
	Format(text, sizeof(text), "------------------------------------------------");
	DrawPanelText(panel, text);

	Format(text, sizeof(text), "☞ %s", L4D_ModelNames[ClientModelPosition[client]]);
	DrawPanelText(panel, text);
	
	Format(text, sizeof(text), "------------------------------------------------");
	DrawPanelText(panel, text);
	
	if(ClientModelPosition[client]<2406)
	{
		Format(text, sizeof(text), "%s", L4D_ModelNames[ClientModelPosition[client]+1]);
		DrawPanelText(panel, text);	
	}	
	
	Format(text, sizeof(text), "↓⇩");	
	DrawPanelItem(panel, text);
	
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ overview object");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);
	
	
	if((ClientModelPosition[client]+100)<count)
	{
		Format(text, sizeof(text), "➦ jump to +100");	
		DrawPanelItem(panel, text);
	}
	else
	{
		Format(text, sizeof(text), "➧⏎ jump to first object");	
		DrawPanelItem(panel, text);
	}	
	SendPanelToClient(panel, client, ChooseActionHandler, 60);
	CloseHandle(panel);
}
public ChooseActionHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1: 
			{
				if(ClientModelPosition[param1]>0) ClientModelPosition[param1]--;
				OpenBuildMenu(param1);
			} 
		case 2:
			{
				if(ClientModelPosition[param1]<count) ClientModelPosition[param1]++;
				OpenBuildMenu(param1);
			}
		case 3:
			{
				ChooseEntityProperty(param1);
			} 				 
		case 4:
			{
				if((ClientModelPosition[param1]+100)<count) ClientModelPosition[param1]+=100;
				else ClientModelPosition[param1] = 0;
				OpenBuildMenu(param1);
			} 	
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");
	}
	else if (action == MenuAction_Cancel) 
	{ 

	}	
}

ChooseEntityProperty(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), " Entity property menu");	
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ spawn as prop_dynamic_override");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ spawn as prop_physics_override");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);	
	
	SendPanelToClient(panel, client, ChoosePropertyHandler, 60);
	CloseHandle(panel);
}

public ChoosePropertyHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1:
			{
				PropDymanic(param1);
			} 
		case 2:
			{
				PropPhysics(param1);
			}
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");

	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}	
}


PropDymanic(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), "❖ Choose entity spawn Flags");	
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ 64");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Use Hitboxes for Renderbox ");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 256");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Start with collision disabled");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "---BreakableProp:---");
	DrawPanelText(panel, text);	
	Format(text, sizeof(text), "➧ 16");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Break on Touch");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 32");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Break on Pressure");
	DrawPanelText(panel, text);	
	
	SendPanelToClient(panel, client, PropDynamicHandler, 60);
	CloseHandle(panel);
}

public PropDynamicHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 0, "64");
			} 
		case 2:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 0, "256");
			}
		case 3:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 0, "16");
			} 	
		case 4:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 0, "32");
			} 				
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");

	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}	
}

PropPhysics(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), "❖ Choose entity spawn Flags");	
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ 1");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Start Asleep");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 2");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Don't take physics damage");
	DrawPanelText(panel, text);	
	Format(text, sizeof(text), "➧ 4");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Debris - Don't collide with the player or other debris");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 8");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Motion Disabled");
	DrawPanelText(panel, text);	
	Format(text, sizeof(text), "➧ 64");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Enable motion on Physcannon grab");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ 128");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Not affected by rotor wash");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 256");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Generate output on +USE ");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 512");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Prevent pickup");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 1024");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Prevent motion enable on player bump");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➫ More ...");	
	DrawPanelItem(panel, text);	
	
	SendPanelToClient(panel, client, PropPhysicsHandler, 60);
	CloseHandle(panel);
}

public PropPhysicsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "1");
			} 
		case 2:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "2");
			}
		case 3:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "4");
			} 	
		case 4:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "8");
			} 	
		case 5:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "64");
			} 
		case 6:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "128");
			}
		case 7:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "256");
			} 	
		case 8:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "512");
			} 	
		case 9:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "1024");
			}
		case 10:
			{
				MorePhysicsFlag(param1);
			}			
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");

	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}	
}
MorePhysicsFlag(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), "❖ Choose entity spawn Flags");	
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ 4096");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Debris with trigger interaction");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "➧ 8192");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Force server-side (Multiplayer only; see sv_pushaway_clientside_size)");
	DrawPanelText(panel, text);	
	Format(text, sizeof(text), "➧ 1048576");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Physgun can ALWAYS pick up. No matter what.");
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "⠶ Return");	
	DrawPanelItem(panel, text);	
	
	SendPanelToClient(panel, client, PropPhysicsHandler2, 60);
	CloseHandle(panel);
}

public PropPhysicsHandler2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "4096");
			} 
		case 2:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "8192");
			}
		case 3:
			{
				SpawnNewObject(param1, L4D_ModelNames[ClientModelPosition[param1]], 1, "1048576");
			} 
		case 4:
			{
				PropPhysics(param1);
			} 			
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");
	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}	
}



CMD_load()
{

	decl String:sPath[PLATFORM_MAX_PATH];
	decl String:line[128];
	Format(sPath, sizeof(sPath), "data/models/l4dmodels.txt");
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", sPath);
	new Handle:fileHandle = OpenFile(sPath,"r");                
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		TrimString(line);

		L4D_ModelNames[count] = line;
		
		count++;
	}
	CloseHandle(fileHandle);

}


public Action:CMD_save(client, args)
{
	SaveObjects();
	return Plugin_Handled;
}

stock SpawnNewObject(client, String:Name[], mode, String:flag[])
{
	new entity;
	if(!IsModelPrecached(Name))
	{
		PrecacheModel(Name);
	}
	if(mode==0)entity = CreateEntityByName("prop_dynamic_override");
	if(mode==1) entity = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue(entity, "spawnflags", flag);

	new String:AuthId[64];
	GetClientAuthString(client, AuthId, sizeof(AuthId));

	DispatchKeyValue(entity, "solid", "6");

	DispatchKeyValue(entity, "targetname", AuthId);
	DispatchKeyValue(entity, "model", Name);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	
	if(mode==0)
	{
		SetEntityMoveType(entity, MOVETYPE_NOCLIP);
		g_EntityPhysics[entity] = false;
	}
	else if(mode==1)
	{
		SetEntProp(entity, Prop_Data, "m_iHealth", 1000);
		g_EntityPhysics[entity] = true;
	}
	else
	{
		g_EntityPhysics[entity] = false;
	}	
	new FL = StringToInt(flag);
	g_EntityFlag[entity] = FL;
	g_CustomEntity[entity]=true;
	
	SetObjectPosition(client, entity);
	new String:property[32];
	if(mode==0) property = "prop_dynamic_override";
	else if(mode==1) property = "prop_physics_override";	

	CheckWait(client);
	
	new Handle:h;	
	
	CreateDataTimer(1.5, IsEntity, h);
	WritePackCell(h, client);
	WritePackCell(h, entity);	
	WritePackString(h, property);
}
stock SetObjectPosition(client, entity)
{
	if (!IsValidEntity(entity))
	{
		return;
	}	
	new Float:Angles[3];
	GetClientEyeAngles(client, Angles);
	new Float:Eyepos[3];
	GetClientEyePosition(client, Eyepos);
	new Float:Offset[3];
	GetAngleVectors(Angles, Offset, NULL_VECTOR, NULL_VECTOR);

	decl Float:mins[3], Float:maxs[3];
	new Float:point[3];
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	CopyVector(Eyepos, point);
	point[0] += (mins[0] + maxs[0]) * 0.5;
	point[1] += (mins[1] + maxs[1]) * 0.5;
	point[2] += (mins[2] + maxs[2]) * 0.5;
	
	new Float:dist = GetVectorDistance(Eyepos, point);

	ScaleVector(Offset, 120.0+dist);

	new Float:Origin[3];
	AddVectors(Eyepos, Offset, Origin);

	new Float:PlayerOrigin[3];
	GetClientAbsOrigin(client, PlayerOrigin);
	if (Origin[2] - 16.0 < PlayerOrigin[2]) Origin[2] = PlayerOrigin[2] + 16.0;
	TeleportEntity(entity, Float:Origin, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValueFloat(entity, "fademindist", 10000.0);
	DispatchKeyValueFloat(entity, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(entity, "fadescale", 0.0);
	
}

public Action:IsEntity(Handle:timer, Handle:h)
{
	ResetPack(h);
	new client = ReadPackCell(h);
	new entity = ReadPackCell(h);	
	decl String:property[32];
	ReadPackString(h, property, sizeof(property));
	if(!IsValidClient(client)) return;
	if(!IsValidEntity(entity))
	{
		EmitSoundToClient(client, "UI/Beep_Error01.wav");
		new Handle:panel = CreatePanel();
		new String:text[64];	

		Format(text, sizeof(text), "-------------------");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "Entity is not valid!");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "the property %s cannot be used on this model", property);
		DrawPanelText(panel, text);	
		Format(text, sizeof(text), "try to spawn using other");
		DrawPanelText(panel, text);		
		Format(text, sizeof(text), "-------------------");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "⏎➧ Back to main menu");	
		DrawPanelItem(panel, text);

		SendPanelToClient(panel, client, InvalidEntityHandler, 30);
		CloseHandle(panel);
	}
	else
	{
		EmitSoundToClient(client, "player/orch_hit_Csharp_short.wav");
		decl String:class[64];
		GetEdictClassname(entity, class, sizeof(class));
		new Handle:panel = CreatePanel();
		new String:text[64];	

		Format(text, sizeof(text), "-------------------");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "Entity is valid!");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "Entity spawned as %s", class);
		DrawPanelText(panel, text);	
		Format(text, sizeof(text), "-------------------");
		DrawPanelText(panel, text);
		Format(text, sizeof(text), "⏎➧ Back to main menu");	
		DrawPanelItem(panel, text);
		LastEntity[client] = entity;
		SendPanelToClient(panel, client, ValidEntityHandler, 30);
		CloseHandle(panel);
	}	
}	
CheckWait(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	

	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ Checking entity validation ,please wait...");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "===============");
	DrawPanelText(panel, text);
	
	SendPanelToClient(panel, client, CheckHandler, 1);
	CloseHandle(panel);
}

public CheckHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		CheckWait(param1);
	}
}
public InvalidEntityHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		OpenBuildMenu(param1);
	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}		
}
public ValidEntityHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		OpenBuildMenu(param1);
	}
	else if (action == MenuAction_Cancel) 
	{ 
		OpenBuildMenu(param1);
	}		
}
public OnClientPutInServer(client)
{
	if (IsClientConnected(client)) 
	{
		if(!IsFakeClient(client))
		{
			ResetBuild(client);
		}
	}	
}
ResetBuild(client)
{
	ObjectControlCooldown[client]=false;
	ObjectControlLevel[client]=0;
	UseCooldown[client]=false;
	ObjectOfObsession[client]=-1;
}

stock DropObject(client, entity)
{
	if (!IsValidEntity(entity)) return;
	if(g_EntityPhysics[entity])
	{
		SetEntityGravity(entity, 1.0);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);	
	}	
	ObjectOfObsession[client]=-1;
	SetEntityMoveType(client, MOVETYPE_WALK);	
	ObjectControlLevel[client]=0;
}
public Action:Timer_ObjectControlCooldown(Handle:timer, any:client)
{
	if (IsValidAliveClient(client)) ObjectControlCooldown[client]=false;
}




stock DestroyGrabbedObject(client)
{
	g_CustomEntity[ObjectOfObsession[client]]=false;
	if (!AcceptEntityInput(ObjectOfObsession[client], "Kill")) RemoveEdict(ObjectOfObsession[client]);
	ObjectOfObsession[client]=-1;
	ObjectControlLevel[client] = 0;
	PrintHintText(client, "✕ Entity destroyed!");
	EmitSoundToClient(client, "UI/menu_countdown.wav");
}
public Action:Timer_UseCooldown(Handle:timer, any:client)
{
	if (IsValidAliveClient(client)) UseCooldown[client]=false;
}

public Action:OnPlayerRunCmd(client, &buttons)
{

	if(IsValidAliveClient(client) && IsFakeClient(client)) return Plugin_Continue;
	
	else if (!IsValidAliveClient(client))
	{
		if (ObjectOfObsession[client] != -1)
		{
			DropObject(client, ObjectOfObsession[client]);
		}
	}
	else
	{
		if ((buttons & IN_ZOOM) && ObjectOfObsession[client] != -1)
		{
			if(!ObjectControlCooldown[client])
			{
				if(ObjectControlLevel[client]==0)	ObjectControlLevel[client]=1;
				else if(ObjectControlLevel[client]==1) ObjectControlLevel[client]=2;
				else if(ObjectControlLevel[client]==2) ObjectControlLevel[client]=1;
				
				ObjectControlCooldown[client]=true;
				CreateTimer(0.5, Timer_ObjectControlCooldown, client, TIMER_FLAG_NO_MAPCHANGE);

			}	
			switch(ObjectControlLevel[client])
			{
			case 1:
				{
					PrintHintText(client, "✔ ROTATE hooked!");
					EmitSoundToClient(client, "UI/Beep07.wav");				
				}	
			case 2: 
				{
					PrintHintText(client, "✔ MOVE hooked!");
					EmitSoundToClient(client, "UI/BeepClear.wav");
				}	
			}		
		}

		if (ObjectOfObsession[client] != -1 && IsValidEntity(ObjectOfObsession[client]))
		{
			decl Float:Origin[3];
			GetClientAbsOrigin(client, Origin);
			Origin[2] += 50;
			if ((buttons & IN_FORWARD) || (buttons & IN_BACK) ||
					(buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT) || 
					(buttons & IN_SPEED) || (buttons & IN_DUCK))
			{
				new Float:VecOrigin[3];
				GetEntPropVector(ObjectOfObsession[client], Prop_Data, "m_vecOrigin", VecOrigin);
				
				decl Float:mins[3], Float:maxs[3], Float:point[3];	
				GetEntPropVector(ObjectOfObsession[client],Prop_Send,"m_vecMins",mins);
				GetEntPropVector(ObjectOfObsession[client],Prop_Send,"m_vecMaxs",maxs);
				
				CopyVector(VecOrigin, point);
				
				point[0] += (mins[0] + maxs[0]) * GetRandomFloat(0.0, 1.0);
				point[1] += (mins[1] + maxs[1]) * GetRandomFloat(0.0, 1.0);
				point[2] += (mins[2] + maxs[2]) * GetRandomFloat(0.0, 1.0);
				
				if (ObjectControlLevel[client]==1)
				{				
					new Float:VecAngles[3];
					GetEntPropVector(ObjectOfObsession[client], Prop_Data, "m_angRotation", VecAngles);
					if (buttons & IN_FORWARD) VecAngles[0] += 1;
					else if (buttons & IN_BACK) VecAngles[0] -= 1;
					if (buttons & IN_MOVELEFT) VecAngles[1] += 1;
					else if (buttons & IN_MOVERIGHT) VecAngles[1] -= 1;
					if (buttons & IN_SPEED) VecAngles[2] += 1;
					else if (buttons & IN_DUCK) VecAngles[2] -= 1;

					TeleportEntity(ObjectOfObsession[client], VecOrigin, VecAngles, NULL_VECTOR);

					TE_SetupBeamPoints(Origin, point, g_sprite, 0, 0, 0, 0.2, 0.2, 0.3, 1, 12.5, {70, 85, 255, 255}, 3);
					TE_SendToAll();
					EmitSoundToAll("physics/metal/metal_chainlink_impact_hard1.wav", 0, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER, SND_NOFLAGS, SNDVOL_NORMAL, 255, _, VecOrigin, NULL_VECTOR, false, 0.0);
				}
				if (ObjectControlLevel[client]==2)
				{	
					if (buttons & IN_FORWARD) VecOrigin[0] += 1;
					else if (buttons & IN_BACK) VecOrigin[0] -= 1;
					if (buttons & IN_MOVELEFT) VecOrigin[1] += 1;
					else if (buttons & IN_MOVERIGHT) VecOrigin[1] -= 1;
					if (buttons & IN_SPEED) VecOrigin[2] += 1;
					else if (buttons & IN_DUCK) VecOrigin[2] -= 1;

					TeleportEntity(ObjectOfObsession[client], VecOrigin, NULL_VECTOR, NULL_VECTOR); 

					TE_SetupBeamPoints(Origin, point, g_sprite, 0, 0, 0, 0.11, 0.2, 0.3, 1, 11.5, {250, 55, 55, 255}, 3);
					TE_SendToAll();
					EmitSoundToAll("physics/metal/metal_chainlink_impact_hard1.wav", 0, SNDCHAN_WEAPON, SNDLEVEL_DISHWASHER, SND_NOFLAGS, SNDVOL_NORMAL, 55, _, VecOrigin, NULL_VECTOR, false, 0.0);
				}	
			}
		}
		if ((buttons & IN_ATTACK2) && ObjectOfObsession[client] != -1 && IsValidEntity(ObjectOfObsession[client]))
		{
			DestroyGrabbedObject(client);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		if ((buttons & IN_USE) && !UseCooldown[client])
		{
			UseCooldown[client] = true;
			CreateTimer(1.0, Timer_UseCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
			if (ObjectOfObsession[client] != -1)
			{
				DropObject(client, ObjectOfObsession[client]);
				PrintHintText(client, "✕ Entity dropped!");
				EmitSoundToClient(client, "UI/menu_invalid.wav");
			}
			else
			{
				new String:AuthId[64];
				GetClientAuthString(client, AuthId, sizeof(AuthId));
				new entity=GetEnt(client);
				if (entity != -1 && IsValidEntity(entity) && g_CustomEntity[entity])
				{
					new Float:playerPos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);

					decl Float:pos[3];

					GetEntPropVector(entity,Prop_Send,"m_vecOrigin",pos);

					if (GetVectorDistance(playerPos, pos) <= 1000.0)
					{
						new String:EntityName[64];
						GetEntPropString(entity, Prop_Data, "m_iName", EntityName, sizeof(EntityName));

						if (StrEqual(AuthId, EntityName))
						{

							ObjectOfObsession[client]	= entity;
							PrintHintText(client, "★ Entity hooked!\n► Press ZOOM!");
							SetEntityMoveType(client, MOVETYPE_NONE);
							TE_SetupBeamRingPoint(pos, 200.0, 1.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 1.0, 9.5, {250, 150, 230, 230}, 80, 0);
							TE_SendToAll();
							EmitSoundToAll("physics/metal/metal_chainlink_impact_hard1.wav", 0, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, 99, _, pos, NULL_VECTOR, false, 0.0);
						}	
						else
						{
							HasOwner(client, EntityName);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

GetEnt(client)
{
	new ent=0;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		ent=TR_GetEntityIndex(trace);

	}
	CloseHandle(trace);	
	return ent;
}

stock HasOwner(Receiver, String:Name[])
{
	new String:AuthId[64];
	new String:Owner[512];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			GetClientAuthString(client, AuthId, sizeof(AuthId));
			if (StrEqual(Name, AuthId))
			{
				GetClientName(client, Owner, sizeof(Owner));
				PrintHintText(Receiver, "Its %s object!", Owner);
			}
		}
	}
}

SaveObjects()
{
	new MaxEntities = 2048;
	new num = 0;
	for (new i = MaxClients; i <= MaxEntities; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			if(g_CustomEntity[i])
			{
				decl Float:pos[3], Float:ang[3];
				decl String:modelname[128];
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", pos);
				GetEntPropVector(i, Prop_Data, "m_angRotation", ang);					
				GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
				new flag = g_EntityFlag[i];
				if(g_EntityPhysics[i])
				{
					if(WriteItemToStripperFile(pos, ang, modelname, 1, flag)==true)
					{
						num++;
						g_CustomEntity[i] = false;
					}
				}
				else
				{
					if(WriteItemToStripperFile(pos, ang, modelname, 0, flag)==true)
					{
						num++;
						g_CustomEntity[i] = false;
					}
				}	
			}
		}
	}
	new String:multi[1] = "s";
	if(num == 1) multi[0] = 0;
	PrintToChatAll("\x05[ \x01%d \x05] \x03 object%s saved \x01!", num, multi);
}

bool:WriteItemToStripperFile(Float:g_Origin[3], Float:g_Angle[3], String:ModelName[], mode, flag)
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));

	new String:path[255];
	Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);

	new Handle:file = OpenFile(path, "a");
	if (file == INVALID_HANDLE)
	{
		PrintToChatAll("Could not open Stripper config file \"%s\" for writing.", path);
		return false;
	}

	WriteFileLine(file, "add:");
	WriteFileLine(file, "{");


	WriteFileLine(file, "\"spawnflags\" \"%d\"", flag);
	WriteFileLine(file, "\"solid\" \"6\"");

	WriteFileLine(file, "\"fademindist\" \"10000.0\"");
	WriteFileLine(file, "\"fademaxdist\" \"20000.0\"");
	WriteFileLine(file, "\"fadescale\" \"0.0\"");	

	WriteFileLine(file, "\"origin\" \"%1.1f %1.1f %1.1f\"", g_Origin[0], g_Origin[1], g_Origin[2]);
	WriteFileLine(file, "\"angles\" \"%1.1f %1.1f %1.1f\"", g_Angle[0], g_Angle[1], g_Angle[2]);

	WriteFileLine(file, "\"model\" \"%s\"", ModelName);
	if(mode==0) 
	{
		WriteFileLine(file, "\"classname\" \"prop_dynamic_override\"");
	}	
	if(mode==1) 
	{
		WriteFileLine(file, "\"forcetoenablemotion\" \"1\"");
		WriteFileLine(file, "\"classname\" \"prop_physics_override\"");
	}	


	WriteFileLine(file, "}");
	CloseHandle(file);
	return true;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
stock bool:IsValidClient(client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsValidEntity(client))	return false;
	return true;
}
stock bool:IsValidAliveClient(client)
{
	if (client <= 0) return false;
	else if (client > MaxClients) return false;
	else if(!IsClientInGame(client))return false;
	else if (!IsPlayerAlive(client)) return false;
	else return true;
}


public Action:CMD_find(client, args)
{
	if(IsValidClient(client)) 
	{
		FindEntities(); 
		CreateTimer(1.0, OpenItems, client);
	}
	return Plugin_Handled;
}
new addit;
new IndexEnt[2048];
new bool:Tracker = false;
FindEntities()
{
	decl MaxEntities, String:mName[256];
	MaxEntities = 2048;
	for (new i = 1; i <= MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));
			if (strncmp(mName, "models", 6) == 0 ||
					strncmp(mName, "*", 1) == 0)
			{
				addit++;
				Map_ModelNames[addit] = mName;
				IndexEnt[i] = i;
			}	
		}
	}
}	
public Action:OpenItems(Handle:timer, any:client)
{
	if(!IsValidClient(client)) return;
	if(!IsClientInGame(client)) return;
	ClientMapModelPosition[client] = 0;
	OpenDeleteMenu(client);
}
OpenDeleteMenu(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), " MODEL  %d / %d", ClientMapModelPosition[client]+1, addit);	
	SetPanelTitle(panel, text);
	
	Format(text, sizeof(text), "↑⇧");	
	DrawPanelItem(panel, text);
	
	if(ClientMapModelPosition[client]>0)
	{
		Format(text, sizeof(text), "%s", Map_ModelNames[ClientMapModelPosition[client]-1]);
		DrawPanelText(panel, text);
	}	
	
	Format(text, sizeof(text), "------------------------------------------------");
	DrawPanelText(panel, text);

	Format(text, sizeof(text), "☞ %s", Map_ModelNames[ClientMapModelPosition[client]]);
	DrawPanelText(panel, text);
	
	Format(text, sizeof(text), "------------------------------------------------");
	DrawPanelText(panel, text);
	
	if(ClientMapModelPosition[client]<2406)
	{
		Format(text, sizeof(text), "%s", Map_ModelNames[ClientMapModelPosition[client]+1]);
		DrawPanelText(panel, text);	
	}	
	
	Format(text, sizeof(text), "↓⇩");	
	DrawPanelItem(panel, text);
	
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);		
	if(!Tracker) Format(text, sizeof(text), "➧ Mark object");	
	else Format(text, sizeof(text), "➧ UnMark object");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);
	
	
	if((ClientModelPosition[client]+10)<addit)
	{
		Format(text, sizeof(text), "➦ jump to +10");	
		DrawPanelItem(panel, text);
	}
	else
	{
		Format(text, sizeof(text), "➧⏎ jump to first object");	
		DrawPanelItem(panel, text);
	}	
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ delete object");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);	
	SendPanelToClient(panel, client, ChooseActionDeleteHandler, 60);
	CloseHandle(panel);
}
public ChooseActionDeleteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1: 
			{
				if(ClientMapModelPosition[param1]>0) ClientMapModelPosition[param1]--;
				OpenDeleteMenu(param1);
			} 
		case 2:
			{
				if(ClientMapModelPosition[param1]<addit) ClientMapModelPosition[param1]++;
				OpenDeleteMenu(param1);
			}
		case 3:
			{
				if(!Tracker) MarkEnt(param1);
				else Tracker = false;
				OpenDeleteMenu(param1);
			} 				 
		case 4:
			{
				if((ClientMapModelPosition[param1]+10)<addit) ClientMapModelPosition[param1]+=10;
				else ClientMapModelPosition[param1] = 0;
				OpenDeleteMenu(param1);
			} 	
		case 5:
			{
				Delete(param1);
				OpenDeleteMenu(param1);
			} 			
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");
	}
	else if (action == MenuAction_Cancel) 
	{ 

	}	
}
Delete(client)
{
	decl MaxEntities, String:mName[256];
	MaxEntities = 2048;
	for (new i = 1; i <= MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			if(i == IndexEnt[i])
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));

				if(StrEqual(mName, Map_ModelNames[ClientMapModelPosition[client]]))
				{
					decl String:hammerStr[32];
					new hammerInt = (GetEntProp(i, Prop_Data, "m_iHammerID", 32));
					IntToString(hammerInt, hammerStr, 32);
					if(AddFilter(client, hammerStr))
					{
						if(!AcceptEntityInput(i, "Kill")) RemoveEdict(i);
						PrintToChatAll("\x03 %d Entity \x01 deleted \x05!", i);
					}	
				}
			}				
		}
	}
}
MarkEnt(client)
{
	decl MaxEntities, String:mName[256];
	MaxEntities = 2048;
	for (new i = 1; i <= MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			if(i == IndexEnt[i])
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", mName, sizeof(mName));
				if(StrEqual(mName, Map_ModelNames[ClientMapModelPosition[client]]))
				{
					CreateTimer(1.0, RingEffect, i, TIMER_REPEAT);
					Tracker = true;
				}
			}				
		}
	}
}
public Action:RingEffect(Handle:timer, any:ent)
{
	if(!IsValidEntity(ent)) return Plugin_Stop;
	if(!Tracker) return Plugin_Stop;
	if (Tracker)
	{
		new Float:origin[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", origin);
		TE_SetupBeamRingPoint(origin, 10.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, {255,255,255,200}, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(origin, 10.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, {255,50,0,255}, 10, 0);
		TE_SendToAll();
		EmitAmbientSound("UI/Beep07.wav", origin, ent, SNDLEVEL_GUNFIRE);
	}	
	return Plugin_Continue;
}	


public Action:CMD_Weapon(client, args)
{
	if(IsValidClient(client)) 
	{
		OpenWeaponMenu(client);
	}
	return Plugin_Handled;
}	

OpenWeaponMenu(client)
{	
	new Handle:panel = CreatePanel();
	new String:text[64];	
	Format(text, sizeof(text), " Choose Weapon");	
	SetPanelTitle(panel, text);
	
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);		
	Format(text, sizeof(text), "➧ Pistol");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Smg");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ PumpShotgun");	
	DrawPanelItem(panel, text);	
	Format(text, sizeof(text), "➧ AutoShotgun");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Rifle");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Hunting Rifle");	
	DrawPanelItem(panel, text);	
	Format(text, sizeof(text), "➧ MiniGun");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Ammo Stack");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Pills");	
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "➧ Medkit");	
	DrawPanelItem(panel, text);
	
	Format(text, sizeof(text), "============================");
	DrawPanelText(panel, text);

	SendPanelToClient(panel, client, ChooseWeaponHandler, 60);
	CloseHandle(panel);
}
public ChooseWeaponHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1: CreateWeapon(param1, 1);
		case 2: CreateWeapon(param1, 2);
		case 3: CreateWeapon(param1, 3);
		case 4: CreateWeapon(param1, 4);
		case 5: CreateWeapon(param1, 5);
		case 6: CreateWeapon(param1, 6);
		case 7: CreateWeapon(param1, 7);
		case 8: CreateWeapon(param1, 8);
		case 9: CreateWeapon(param1, 9);
		case 0: CreateWeapon(param1, 0);
		}
		EmitSoundToClient(param1, "UI/Beep07.wav");
	}
	else if (action == MenuAction_Cancel) 
	{ 

	}	
}
CreateWeapon(client, weapon)
{
	new entity;
	new String:class[128];
	switch(weapon)
	{
	case 1:
		{
			entity = CreateEntityByName("weapon_pistol_spawn");
			class = "weapon_pistol_spawn";
		}	
	case 2:
		{
			entity = CreateEntityByName("weapon_smg_spawn");
			class = "weapon_smg_spawn";
		}	
	case 3:
		{
			entity = CreateEntityByName("weapon_pumpshotgun_spawn");
			class = "weapon_pumpshotgun_spawn";
		}	
	case 4:
		{
			entity = CreateEntityByName("weapon_autoshotgun_spawn");
			class = "weapon_autoshotgun_spawn";
		}	
	case 5:
		{
			entity = CreateEntityByName("weapon_rifle_spawn");
			class = "weapon_rifle_spawn";
		}	
	case 6:
		{
			entity = CreateEntityByName("weapon_hunting_rifle_spawn");
			class = "weapon_hunting_rifle_spawn";
		}	
	case 7:
		{
			entity = CreateEntityByName("prop_minigun");
			class = "prop_minigun";
		}	
	case 8:
		{
			entity = CreateEntityByName("weapon_ammo_spawn");
			class = "weapon_ammo_spawn";
		}	
	case 9:
		{
			entity = CreateEntityByName("weapon_pain_pills_spawn");
			class = "weapon_pain_pills_spawn";
		}	
	case 0:
		{
			entity = CreateEntityByName("weapon_first_aid_kit");
			class = "weapon_first_aid_kit";
		}	
	}
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchKeyValue(entity, "solid", "6");
	if(weapon == 7) DispatchKeyValue(entity, "model", "models/w_models/weapons/w_minigun.mdl");	
	if(weapon == 8) DispatchKeyValue(entity, "model", "models/props/terror/ammo_stack.mdl");
	DispatchSpawn(entity);
	ActivateEntity(entity);
	new Float:Angles[3];
	GetClientEyeAngles(client, Angles);
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);	
	TeleportEntity(entity, pos, Angles, NULL_VECTOR);	
	SaveCurrentWeapon(class, weapon, pos, Angles);
}
SaveCurrentWeapon(String:class[], weapon, Float:g_Origin[3], Float:g_Angle[3])
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));

	new String:path[255];
	Format(path, sizeof(path), "addons/stripper/maps/%s.cfg", map);

	new Handle:file = OpenFile(path, "a");
	if (file == INVALID_HANDLE)
	{
		PrintToChatAll("Could not open Stripper config file \"%s\" for writing.", path);
		return;
	}

	WriteFileLine(file, "add:");
	WriteFileLine(file, "{");

	WriteFileLine(file, "\"origin\" \"%1.1f %1.1f %1.1f\"", g_Origin[0], g_Origin[1], g_Origin[2]);
	if(weapon==7) 	WriteFileLine(file, "\"StartDisabled\" \"0\"");
	WriteFileLine(file, "\"spawnflags\" \"0\"");
	WriteFileLine(file, "\"solid\" \"6\"");

	if(weapon==7)
	{
		WriteFileLine(file, "\"skin\" \"0\"");
		WriteFileLine(file, "\"SetBodyGroup\" \"0\"");
		WriteFileLine(file, "\"rendercolor\" \"255 255 255\"");
		WriteFileLine(file, "\"renderamt\" \"255\"");
		WriteFileLine(file, "\"RandomAnimation\" \"0\"");
		WriteFileLine(file, "\"pressuredelay\" \"0\"");
		WriteFileLine(file, "\"PerformanceMode\" \"0\"");
		WriteFileLine(file, "\"model\" \"models/w_models/weapons/w_minigun.mdl\"");		
	}
	if(weapon==8) WriteFileLine(file, "\"model\" \"models/props/terror/ammo_stack.mdl\"");
	if(weapon==7)
	{
		WriteFileLine(file, "\"MinPitch\" \"-30\"");	
		WriteFileLine(file, "\"mindxlevel\" \"0\"");
		WriteFileLine(file, "\"MinAnimTime\" \"5\"");
		WriteFileLine(file, "\"MaxYaw\" \"90\"");
		WriteFileLine(file, "\"MaxPitch\" \"30\"");
		WriteFileLine(file, "\"maxdxlevel\" \"0\"");
		WriteFileLine(file, "\"MaxAnimTime\" \"10\"");
		WriteFileLine(file, "\"fadescale\" \"1\"");
		WriteFileLine(file, "\"fademindist\" \"1280\"");
		WriteFileLine(file, "\"fademaxdist\" \"1536\"");
		WriteFileLine(file, "\"ExplodeRadius\" \"0\"");	
		WriteFileLine(file, "\"ExplodeDamage\" \"0\"");
	}	
	WriteFileLine(file, "\"disableshadows\" \"1\"");	
	WriteFileLine(file, "\"angles\" \"%1.1f %1.1f %1.1f\"", g_Angle[0], g_Angle[1], g_Angle[2]);
	WriteFileLine(file, "\"classname\" \"%s\"", class);

	WriteFileLine(file, "}");
	CloseHandle(file);
}	