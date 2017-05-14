#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d_stocks>

#define PLUGIN_VERSION				"1.7"
#define UPGRADEID					41
#define MAX_UPGRADES				41
#define UPGRADE_LOAD_TIME			0.5

#define	HUNTING_RIFLE_OFFSET_AMMO	8
#define	RIFLE_OFFSET_AMMO			12
#define	SMG_OFFSET_AMMO				20
#define	SHOTGUN_OFFSET_AMMO			24
#define MAXENTITIES 				2048
#define MAX_SPAWNS					32
#define VALVE_RAND_MAX 0x7fff
static g_iSpawns[MAX_SPAWNS][2];

static const String:SOUND_TP[] 		= "^UI/critical_event_1.wav";
static const String:SOUND_TP3[] 	= "^ambient/machines/steam_release_2.wav";

static const String:SOUND_ZOEY01[] 	= "^/player/survivor/voice/teengirl/cough02.wav";
static const String:SOUND_ZOEY02[] 	= "^/player/survivor/voice/teengirl/cough04.wav";
static const String:SOUND_ZOEY03[] 	= "^/player/survivor/voice/teengirl/cough05.wav";
static const String:SOUND_ZOEY04[] 	= "^/player/survivor/voice/teengirl/cough06.wav";

static const String:SOUND_BILL01[] 	= "^/player/survivor/voice/namvet/cough01.wav";
static const String:SOUND_BILL02[] 	= "^/player/survivor/voice/namvet/cough02.wav";
static const String:SOUND_BILL03[] 	= "^/player/survivor/voice/namvet/cough03.wav";
static const String:SOUND_BILL04[] 	= "^/player/survivor/voice/namvet/cough04.wav";
static const String:SOUND_BILL05[] 	= "^/player/survivor/voice/namvet/cough05.wav";

static const String:SOUND_FRANCIS01[] 	= "^/player/survivor/voice/biker/cough01.wav";
static const String:SOUND_FRANCIS02[] 	= "^/player/survivor/voice/biker/cough03.wav";
static const String:SOUND_FRANCIS03[] 	= "^/player/survivor/voice/biker/cough06.wav";
static const String:SOUND_FRANCIS04[] 	= "^/player/survivor/voice/biker/cough07.wav";

static const String:SOUND_LOUIS01[] 	= "^/player/survivor/voice/manager/cough02.wav";
static const String:SOUND_LOUIS02[] 	= "^/player/survivor/voice/manager/cough04.wav";
static const String:SOUND_LOUIS03[] 	= "^/player/survivor/voice/choke_4.wav";
static const String:SOUND_LOUIS04[] 	= "^/player/survivor/voice/choke_8.wav";

#define ENTITY_GASCAN	"models/props_junk/gascan001a.mdl"
#define ENTITY_PROPANE	"models/props_junk/propanecanister001a.mdl"

public Plugin:myinfo =
{
    name = "[L4D] Survivor Upgrades Reloaded",
    author = "Marcus101RR, Whosat & Jerrith",
    description = "Survivor Upgrades Returns, Reloaded!",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net"
}
new Handle:uClientTakeAssault;
new Handle:uClientDropAssault;
new Handle:uClientTakeSupport;
new Handle:uClientDropSupport;
new Handle:uClientTakeEngineer;
new Handle:uClientDropEngineer;
new Handle:uClientTakeMedic;
new Handle:uClientDropMedic;
new Handle:SetClientUpgrades[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:HP_Timer_OnWeaponCanUse[MAXPLAYERS+1];
new Handle:HP_Timer_OnWeaponCanUse2[MAXPLAYERS+1];
new Handle:h_SpectatorAnnonce[MAXPLAYERS+1];
new Handle:h_Difficulty;
new UserMsg:g_FadeUserMsgIdP;

new bool:MedicHandle[MAXPLAYERS+1];
new bool:AssaultHandle[MAXPLAYERS+1];
new bool:EngineerHandle[MAXPLAYERS+1];
//new bool:ReconHandle[MAXPLAYERS+1];
new bool:SupportHandle[MAXPLAYERS+1];
new bool:ScientistHandle[MAXPLAYERS+1];
new FirstKitHandle[MAXPLAYERS+1][2];
new iTPIndex[MAXPLAYERS+1][5];
new iPillsIndex[MAXPLAYERS+1];

new iBitsUpgrades[MAXPLAYERS + 1];
new iUpgrade[MAXPLAYERS + 1][UPGRADEID + 1];
new iUpgradeDisabled[MAXPLAYERS + 1][UPGRADEID + 1];

new bool:b_round_end;
new bool:MedicCheck[MAXPLAYERS + 1] = false;
new bool:AssaultCheck[MAXPLAYERS + 1] = false;
new bool:EngineerCheck[MAXPLAYERS + 1] = false;
//new bool:ReconCheck[MAXPLAYERS + 1] = false;
new bool:SupportCheck[MAXPLAYERS + 1] = false;
new bool:ScientistCheck[MAXPLAYERS + 1] = false;
new bool:kitCheck2[MAXPLAYERS + 1] = false;
new bool:TranquilizerTimeout[MAXPLAYERS + 1] = false;
new bool:IsTranquilizer[MAXPLAYERS + 1] = false;
new Float:InfectedSpeedUsual[MAXPLAYERS + 1];
new Float:ScientistStartPos[MAXPLAYERS + 1][3];
new Float:ScientistEndPos[MAXPLAYERS + 1][3];
new Float:ScientistHealPos[MAXPLAYERS + 1][3];
new Float:BasicSpeed[MAXPLAYERS + 1];
new bool:classCheck[MAXPLAYERS + 1] = false;
new bool:b_ExpertDifficulty;
bool b_LockDifficulty;
new bool:dp[MAXPLAYERS + 1];
new bool:se[MAXPLAYERS + 1];
new bool:KitTimeOut[MAXENTITIES + 1];
new bool:EmitSoundPlay[MAXENTITIES + 1];
new bool:ScientistTPStart[MAXENTITIES + 1];
new Handle:ScientistPillsLock[MAXENTITIES + 1];
new GasSpawn;
new CountHold[MAXPLAYERS+1] = 0;
//new pills_Spawns[MAXPLAYERS+1] = 0;
new bool:IsClientTouch[MAXPLAYERS + 1][MAXENTITIES + 1];
new bool:IsInfectedSlow[MAXPLAYERS + 1];
new bool:IsSurvivorBoost[MAXPLAYERS + 1];
new bool:IsSurvivorGravity[MAXPLAYERS + 1];
//static InfectedPowerCount[MAXPLAYERS] = 0;

new Handle:GravityCheck[MAXPLAYERS + 1];
new Handle:BoostCheck[MAXPLAYERS + 1];
new Handle:SlowCheck[MAXPLAYERS + 1];

// Single CVAR Variables
new Float:PipeBombDuration;
new iGrenadePouch[MAXPLAYERS + 1];
new String:g_msgType[64];

new iCountTimer[MAXPLAYERS + 1];
new iLightIndex[MAXPLAYERS + 1];
new i_CountMedic, i_CountAssault, i_CountEngineer, i_CountSupport, i_CountScientist, i_CountNothing;
//new i_CountRecon;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin Supports Left 4 Dead Only.");
	}

	CreateConVar("sm_upgradesreloaded_version", PLUGIN_VERSION, "Survivor Upgrades Reloaded Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//RegAdminCmd("sm_upgrades", PrintToChatUpgrades, ADMFLAG_CHEATS, "List Upgrades.");
	RegConsoleCmd("sm_laser", UpgradeLaserSightToggle, "Toggle the Laser Sight.");
	RegConsoleCmd("sm_silent", UpgradeSilencerToggle, "Toggle the Silencer.");
	RegConsoleCmd("sm_silencer", UpgradeSilencerToggle, "Toggle the Silencer.");
	//RegConsoleCmd("sm_night", UpgradeNightVisionToggle, "Toggle the Night Vision Goggles.");
	RegConsoleCmd("sm_class", SuperMeatServerPanel, "Select class.");
	RegConsoleCmd("sm_menu", SelectClassMenu, "Player menu.");
	RegConsoleCmd("sm_myclass", PrintPlayerClass, "Print player class.");
	
	RegConsoleCmd("sm_ammo", ClassCheckEnable, "Print player class.");
	RegConsoleCmd("sm_jetpack", ClassCheckEnable, "Print player class.");
	RegConsoleCmd("sm_mg", ClassCheckEnable, "Print player class.");
	RegConsoleCmd("sm_tp", CreateTeleportField, "Create teleport");
	RegConsoleCmd("sm_grav", CreateGravityField, "Create gravity feild");
	RegConsoleCmd("sm_boost", CreateBoostField, "Create boost feild");
	RegConsoleCmd("sm_slow", CreateSlowField, "Create slowmo feild");
	RegConsoleCmd("sm_sci", ScientistSkills, "Create skills menu");
	
	g_FadeUserMsgIdP = GetUserMessageId("Fade");
	//UpgradeIndex[0] = 1;
	//UpgradeTitle[0] = "\x03Bottle Satchel \x01(\x04Increased Pain Pills Capacity\x01)";
	//UpgradeShort[0] = "\x03Bottle Satchel\x01";
	//UpgradeEnabled[0] = CreateConVar("survivor_upgrade_bottle_satchel_enable", "1", "Enable/Disable Bottle Satchel", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[0] = "Bottle Satchel";
	//доп таблы

	//UpgradeIndex[1] = 2;
	//UpgradeTitle[1] = "\x03Kevlar Body Armor \x01(\x04Decreased Damage\x01)";
	//UpgradeShort[1] = "\x03Kevlar Body Armor\x01";
	//UpgradeEnabled[1] = CreateConVar("survivor_upgrade_kevlar_armor_enable", "1", "Enable/Disable Kevlar Body Armor", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[1] = "Kevlar Body Armor";
	//Бронежелет

	//UpgradeIndex[2] = 4;
	//UpgradeTitle[2] = "\x03Steroids \x01(\x04Increased Pain Pills Effect\x01)";
	//UpgradeShort[2] = "\x03Steroids\x01";
	//UpgradeEnabled[2] = CreateConVar("survivor_upgrade_steroids_enable", "1", "Enable/Disable Steroids", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[2] = "Steroids";

	//UpgradeIndex[3] = 8;
	//UpgradeTitle[3] = "\x03Bandages \x01(\x04Increased Revive Buffer\x01)";
	//UpgradeShort[3] = "\x03Bandages\x01";
	//UpgradeEnabled[3] = CreateConVar("survivor_upgrade_bandages_enable", "1", "Enable/Disable Bandages", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[3] = "Bandages";
	//(new медик)

	//UpgradeIndex[4] = 16;
	//UpgradeTitle[4] = "\x03Beta-Blockers \x01(\x04Increased Incapacitation Health\x01)";
	//UpgradeShort[4] = "\x03Beta-Blockers\x01";
	//UpgradeEnabled[4] = CreateConVar("survivor_upgrade_beta_blockers_enable", "1", "Enable/Disable Beta-Blockers", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[4] = "Beta-Blockers";

	//UpgradeIndex[5] = 32;
	//UpgradeTitle[5] = "\x03Morphogenic Cells \x01(\x04Limited Health Regeneration\x01)";
	//UpgradeShort[5] = "\x03Morphogenic Cells\x01";
	//UpgradeEnabled[5] = CreateConVar("survivor_upgrade_morphogenic_cells_enable", "1", "Enable/Disable Morphogenic Cells", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[5] = "Morphogenic Cells";
	//автовосстановление при низком хп

	//UpgradeIndex[6] = 64;
	//UpgradeTitle[6] = "\x03Air Boots \x01(\x04Increased Jump Height\x01)";
	//UpgradeShort[6] = "\x03Air Boots\x01";
	//UpgradeEnabled[6] = CreateConVar("survivor_upgrade_air_boots_enable", "1", "Enable/Disable Air Boots", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[6] = "Air Boots";

	//UpgradeIndex[7] = 128;
	//UpgradeTitle[7] = "\x03Ammo Pouch \x01(\x04Increased Ammunition Reserve\x01)";
	//UpgradeShort[7] = "\x03Ammo Pouch\x01";
	//UpgradeEnabled[7] = CreateConVar("survivor_upgrade_ammo_pouch_enable", "1", "Enable/Disable Ammo Pouch", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[7] = "Ammo Pouch";
	//боекомплект(общее к-во патронов)

	//UpgradeIndex[8] = 256;
	//UpgradeTitle[8] = "\x03Boomer Neutralizer \x01(\x04Anti-Boomer Special Attack\x01)";
	//UpgradeShort[8] = "\x03Boomer Neutralizer\x01";
	//UpgradeEnabled[8] = CreateConVar("survivor_upgrade_boomer_neutralizer_enable", "1", "Enable/Disable Boomer Neutralizer", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[8] = "Boomer Neutralizer";
	//Плащ

	//UpgradeIndex[9] = 512;
	//UpgradeTitle[9] = "\x03Smoker Neutralizer \x01(\x04Anti-Smoker Special Attack\x01)";
	//UpgradeShort[9] = "\x03Smoker Neutralizer\x01";
	//UpgradeEnabled[9] = CreateConVar("survivor_upgrade_smoker_neutralizer_enable", "1", "Enable/Disable Smoker Neutralizer", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[9] = "Smoker Neutralizer";
	//Ловкость

	//UpgradeIndex[10] = 1024;
	//UpgradeTitle[10] = "\x03Dual Satchel \x01(\x04Increased First Aid Kit Capacity\x01)";
	//UpgradeShort[10] = "\x03Dual Satchel\x01";
	//UpgradeEnabled[10] = CreateConVar("survivor_upgrade_dual_satchel_enable", "1", "Enable/Disable Dual Satchel", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[10] = "Dual Satchel";
	//Медик

	//UpgradeIndex[11] = 2048;
	//UpgradeTitle[11] = "\x03Climbing Chalk \x01(\x04Self-Ledge Save\x01)";
	//UpgradeShort[11] = "\x03Climbing Chalk\x01";
	//UpgradeEnabled[11] = CreateConVar("survivor_upgrade_climbing_chalk_enable", "1", "Enable/Disable Climbing Chalk", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[11] = "Climbing Chalk";
	//штурм

	//UpgradeIndex[12] = 4096;
	//UpgradeTitle[12] = "\x03Second Wind \x01(\x04Self-Revive Save\x01)";
	//UpgradeShort[12] = "\x03Second Wind\x01";
	//UpgradeEnabled[12] = CreateConVar("survivor_upgrade_second_wind_enable", "1", "Enable/Disable Second Wind", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[12] = "Second Wind";
	//Второе дыхание

	//UpgradeIndex[13] = 8192;
	//UpgradeTitle[13] = "\x03Goggles \x01(\x04See-Through Boomer Vomit\x01)";
	//UpgradeShort[13] = "\x03Goggles\x01";
	//UpgradeEnabled[13] = CreateConVar("survivor_upgrade_goggles_enable", "1", "Enable/Disable Goggles", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[13] = "Goggles";

	//UpgradeIndex[14] = 16384;
	//UpgradeTitle[14] = "\x03Morphine \x01(\x04Resistant Against Limp Pain\x01)";
	//UpgradeShort[14] = "\x03Morphine\x01";
	//UpgradeEnabled[14] = CreateConVar("survivor_upgrade_morphine_enable", "1", "Enable/Disable Morphine", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[14] = "Morphine";
	//Морфин

	//UpgradeIndex[15] = 32768;
	//UpgradeTitle[15] = "\x03Adrenaline Implant \x01(\x04Increased Movement Speed\x01)";
	//UpgradeShort[15] = "\x03Adrenaline Implant\x01";
	//UpgradeEnabled[15] = CreateConVar("survivor_upgrade_adrenaline_implant_enable", "1", "Enable/Disable Adrenaline Implant", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[15] = "Adrenaline Implant";
	//Адриналин

	//UpgradeIndex[16] = 65536;
	//UpgradeTitle[16] = "\x03Hot Meal \x01(\x04Restore Health On Next Saferoom\x01)";
	//UpgradeShort[16] = "\x03Hot Meal\x01";
	//UpgradeEnabled[16] = CreateConVar("survivor_upgrade_hot_meal_enable", "1", "Enable/Disable Hot Meal", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[16] = "Hot Meal";
	//Еда дома

	//UpgradeIndex[17] = 131072;
	//UpgradeTitle[17] = "\x03Laser Sight \x01(\x04Increased Accuracy\x01)";
	//UpgradeShort[17] = "\x03Laser Sight\x01";
	//UpgradeEnabled[17] = CreateConVar("survivor_upgrade_laser_sight_enable", "1", "Enable/Disable Laser Sight", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[17] = "Laser Sight";

	//UpgradeIndex[18] = 262144;
	//UpgradeTitle[18] = "\x03Silencer \x01(\x04Silenced Gunfire & Muzzle Flash\x01)";
	//UpgradeShort[18] = "\x03Silencer\x01";
	//UpgradeEnabled[18] = CreateConVar("survivor_upgrade_silencer_enable", "1", "Enable/Disable Silencer", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[18] = "Silencer";

	//UpgradeIndex[19] = 524288;
	//UpgradeTitle[19] = "\x03Combat Sling \x01(\x04Reduced Recoil\x01)";
	//UpgradeShort[19] = "\x03Combat Sling\x01";
	//UpgradeEnabled[19] = CreateConVar("survivor_upgrade_combat_sling_enable", "1", "Enable/Disable Combat Sling", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[19] = "Combat Sling";
	//Снижение отдачи

	//UpgradeIndex[20] = 1048576;
	//UpgradeTitle[20] = "\x03High Capacity Magazine \x01(\x04Increased Magazine Size\x01)";
	//UpgradeShort[20] = "\x03High Capacity Magazine\x01";
	//UpgradeEnabled[20] = CreateConVar("survivor_upgrade_extended_magazine_enable", "1", "Enable/Disable High Capacity Magazine", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[20] = "High Capacity Magazine";
	//Двойной магазин

	//UpgradeIndex[21] = 2097152;
	//UpgradeTitle[21] = "\x03Hollow Point Ammunition \x01(\x04Increased Bullet Damage\x01)";
	//UpgradeShort[21] = "\x03Hollow Point Ammunition\x01";
	//UpgradeEnabled[21] = CreateConVar("survivor_upgrade_hollow_point_enable", "1", "Enable/Disable Hollow Point Ammunition", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[21] = "Hollow Point Ammunition";
	//разрывные патроны

	//UpgradeIndex[22] = 4194304;
	//UpgradeTitle[22] = "\x03Night Vision Goggles \x01(\x04Increased Dark Vision\x01)";
	//UpgradeShort[22] = "\x03Night Vision Goggles\x01";
	//UpgradeEnabled[22] = CreateConVar("survivor_upgrade_night_vision_enable", "1", "Enable/Disable Night Vision Goggles", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[22] = "Night Vision Goggles";

	//UpgradeIndex[23] = 8388608;
	//UpgradeTitle[23] = "\x03Safety Fuse \x01(\x04Increased Pipebomb Duration\x01)";
	//UpgradeShort[23] = "\x03Safety Fuse\x01";
	//UpgradeEnabled[23] = CreateConVar("survivor_upgrade_safety_fuse_enable", "1", "Enable/Disable Safety Fuse", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[23] = "Safety Fuse";
	//Предохронитель

	//UpgradeIndex[24] = 16777216;
	//UpgradeTitle[24] = "\x03Sniper Scope \x01(\x04Sniper Zoom Attachment\x01)";
	//UpgradeShort[24] = "\x03Sniper Scope\x01";
	//UpgradeEnabled[24] = CreateConVar("survivor_upgrade_scope_enable", "1", "Enable/Disable Sniper Scope", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[24] = "Sniper Scope";

	//UpgradeIndex[25] = 33554432;
	//UpgradeTitle[25] = "\x03Sniper Scope Accuracy \x01(\x04Increased Zoom Accuracy\x01)";
	//UpgradeShort[25] = "\x03Sniper Scope Accuracy\x01";
	//UpgradeEnabled[25] = CreateConVar("survivor_upgrade_scope_accuracy_enable", "1", "Enable/Disable Sniper Scope Accuracy", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[25] = "Sniper Scope Accuracy";
	//Снайперский прицел

	//UpgradeIndex[26] = 67108864;
	//UpgradeTitle[26] = "\x03Knife \x01(\x04Self-Save Pinned\x01)";
	//UpgradeShort[26] = "\x03Knife\x01";
	//UpgradeEnabled[26] = CreateConVar("survivor_upgrade_knife_enable", "1", "Enable/Disable Knife", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[26] = "Knife";
	//Нож

	//UpgradeIndex[27] = 134217728;
	//UpgradeTitle[27] = "\x03Smelling Salts \x01(\x04Reduced Revive Duration\x01)";
	//UpgradeShort[27] = "\x03Smelling Salts\x01";
	//UpgradeEnabled[27] = CreateConVar("survivor_upgrade_smelling_salts_enable", "1", "Enable/Disable Smelling Salts", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[27] = "Smelling Salts";
	//Медик (Нашатырь)

	//UpgradeIndex[28] = 268435456;
	//UpgradeTitle[28] = "\x03Ointment \x01(\x04Increased Healing Effect\x01)";
	//UpgradeShort[28] = "\x03Ointment\x01";
	//UpgradeEnabled[28] = CreateConVar("survivor_upgrade_ointment_enable", "1", "Enable/Disable Ointment", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[28] = "Ointment";

	//UpgradeIndex[29] = 536870912;
	//UpgradeTitle[29] = "\x03Slight of Hand \x01(\x04Increase Reload Speed\x01)";
	//UpgradeShort[29] = "\x03Slight of Hand\x01";
	//UpgradeEnabled[29] = CreateConVar("survivor_upgrade_reloader_enable", "1", "Enable/Disable Slight of Hand", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[29] = "Slight of Hand";
	//Ловкость рук

	//UpgradeIndex[30] = 1073741824;
	//UpgradeTitle[30] = "\x03Stimpacks \x01(\x04Reduced Healing Duration\x01)";
	//UpgradeShort[30] = "\x03Stimpacks\x01";
	//UpgradeEnabled[30] = CreateConVar("survivor_upgrade_quick_heal_enable", "1", "Enable/Disable Stimpacks", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[30] = "Stimpacks";
	//Медик (самолечение)

	//UpgradeIndex[31] = 1;
	//UpgradeTitle[31] = "\x03Grenade Pouch \x01(\x04Increased Grenade Slots\x01)";
	//UpgradeShort[31] = "\x03Grenade Pouch\x01";
	//UpgradeEnabled[31] = CreateConVar("survivor_upgrade_grenade_pouch_enable", "1", "Enable/Disable Grenade Pouch", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[31] = "Grenade Pouch";

	//UpgradeIndex[32] = 1;
	//UpgradeTitle[32] = "\x03Pickpocket Hook \x01(\x04Steal Items On Stealth Kills\x01)";
	//UpgradeShort[32] = "\x03Pickpocket Hook\x01";
	//UpgradeEnabled[32] = CreateConVar("survivor_upgrade_pickpocket_hook_enable", "1", "Enable/Disable Pickpocket Hook", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[32] = "Pickpocket Hook";
	//фарм Hitman
	

	//UpgradeIndex[33] = 1;
	//UpgradeTitle[33] = "\x03Ocular Implants \x01(\x04Infected Drop Items\x01)";
	//UpgradeShort[33] = "\x03Ocular Implants\x01";
	//UpgradeEnabled[33] = CreateConVar("survivor_upgrade_ocular_implants_enable", "1", "Enable/Disable Ocular Implants", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[33] = "Ocular Implants";
	//фарм

	//UpgradeIndex[34] = 1;
	//UpgradeTitle[34] = "\x03Pyro Pouch \x01(\x04Explosives Are More Effective\x01)";
	//UpgradeShort[34] = "\x03Pyro Pouch\x01";
	//UpgradeEnabled[34] = CreateConVar("survivor_upgrade_pyro_pouch_enable", "1", "Enable/Disable Pyro Pouch", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[34] = "Pyro Kit";
	//Инженер (больше взрывов)

	//UpgradeIndex[35] = 1;
	//UpgradeTitle[35] = "\x03Transfusion Box \x01(\x04Allow Health Recovery From Melee\x01)";
	//UpgradeShort[35] = "\x03Transfusion Box\x01";
	//UpgradeEnabled[35] = CreateConVar("survivor_upgrade_transfusion_box_enable", "1", "Enable/Disable Transfusion Box", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[35] = "Transfusion Box";
	//Медик (высасывание энергии)

	//UpgradeIndex[36] = 1;
	//UpgradeTitle[36] = "\x03Arm Guards \x01(\x04Increased Maximum Health\x01)";
	//UpgradeShort[36] = "\x03Arm Guards\x01";
	//UpgradeEnabled[36] = CreateConVar("survivor_upgrade_arm_guards_enable", "1", "Enable/Disable Arm Guards", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[36] = "Arm Guards";

	//UpgradeIndex[37] = 1;
	//UpgradeTitle[37] = "\x03Shin Guards \x01(\x04Increased Maximum Health\x01)";
	//UpgradeShort[37] = "\x03Shin Guards\x01";
	//UpgradeEnabled[37] = CreateConVar("survivor_upgrade_shin_guards_enable", "1", "Enable/Disable Shin Guards", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[37] = "Shin Guards";

	//UpgradeIndex[38] = 1;
	//UpgradeTitle[38] = "\x03Autoinjectors \x01(\x04Increased Incapacitation Limit\x01)";
	//UpgradeShort[38] = "\x03Autoinjectors\x01";
	//UpgradeEnabled[38] = CreateConVar("survivor_upgrade_autoinjectors_enable", "1", "Enable/Disable Autoinjectors", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[38] = "Autoinjectors";

	//UpgradeIndex[39] = 1;
	//UpgradeTitle[39] = "\x03Kerosene \x01(\x04Increased Molotov Burn Duration\x01)";
	//UpgradeShort[39] = "\x03Kerosene\x01";
	//UpgradeEnabled[39] = CreateConVar("survivor_upgrade_kerosene_enable", "1", "Enable/Disable Kerosene", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[39] = "Kerosene";
	//Инженер

	//UpgradeIndex[40] = 1;
	//UpgradeTitle[40] = "\x03Weapon Holster \x01(\x04Increased Primary Weapon Capacity\x01)";
	//UpgradeShort[40] = "\x03Weapon Holster\x01";
	//UpgradeEnabled[40] = CreateConVar("survivor_upgrade_weapon_holster_enable", "1", "Enable/Disable Weapon Holster", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//PerkTitle[40] = "Weapon Holster";

	HookUserMessage(GetUserMessageId("SayText"), SayTextHook, true);

	HookEvent("player_death", event_PlayerDeath, EventHookMode_Pre);
	HookEvent("survivor_rescued", event_Rescued);
	//HookEvent("round_start", round_start);
	HookEvent("round_freeze_end", round_freeze_end);
	//HookEvent("round_end", round_end, EventHookMode_Pre);
	HookEvent("mission_lost", round_end, EventHookMode_Pre);
	HookEvent("heal_success", event_HealSuccess);

	HookEvent("map_transition", map_transition, EventHookMode_Pre);
	HookEvent("finale_win", map_transition, EventHookMode_Pre);

	HookEvent("weapon_fire", event_WeaponFire, EventHookMode_Pre);
	HookEvent("player_use", event_PlayerUse, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("item_pickup", event_ItemPickup, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("ammo_pickup", event_AmmoPickup, EventHookMode_Post); // Left 4 Dead 2 Style Ammo Pickup
	HookEvent("break_prop", event_BreakProp, EventHookMode_Post);
	HookEvent("melee_kill", event_MeleeKill, EventHookMode_Pre);
	HookEvent("tank_spawn", Event_TankSpawn);
	//HookEvent("player_left_start_area", player_left_start_area);
	HookEvent("player_bot_replace", player_bot_replace );//игрок ушёл афк 
	HookEvent("bot_player_replace", bot_player_replace );//игрок заменил бота.
	HookEvent("finale_vehicle_leaving", finale_vehicle_leaving);

	PipeBombDuration = GetConVarFloat(FindConVar("pipe_bomb_timer_duration"));
	uClientTakeAssault = CreateGlobalForward("ClientTakeAssault", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientDropAssault = CreateGlobalForward("ClientDropAssault", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientTakeSupport = CreateGlobalForward("ClientTakeSupport", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientDropSupport = CreateGlobalForward("ClientDropSupport", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientTakeEngineer = CreateGlobalForward("ClientTakeEngineer", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientDropEngineer = CreateGlobalForward("ClientDropEngineer", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientTakeMedic = CreateGlobalForward("ClientTakeMedic", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	uClientDropMedic = CreateGlobalForward("ClientDropMedic", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	//uClientTakeRecon = CreateGlobalForward("ClientTakeRecon", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	//uClientDropRecon = CreateGlobalForward("ClientDropRecon", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	h_Difficulty = FindConVar("z_difficulty");
	HookConVarChange(h_Difficulty, ConVarChange_GameDifficulty);
	AutoExecConfig(true, "l4d_upgradesreloaded2");
	LoadTranslations("l4d_upgrades2.phrases");
}
public OnMapStart()
{
	b_LockDifficulty = false;
	PrecacheModel("models/error.mdl", true);
	PrecacheSound(SOUND_TP, true);
	PrecacheSound(SOUND_TP3, true);
	
	PrecacheSound(SOUND_ZOEY01, true);
	PrecacheSound(SOUND_ZOEY02, true);
	PrecacheSound(SOUND_ZOEY03, true);
	PrecacheSound(SOUND_ZOEY04, true);
	
	PrecacheSound(SOUND_BILL01, true);
	PrecacheSound(SOUND_BILL02, true);
	PrecacheSound(SOUND_BILL03, true);
	PrecacheSound(SOUND_BILL04, true);
	PrecacheSound(SOUND_BILL05, true);
	
	PrecacheSound(SOUND_FRANCIS01, true);
	PrecacheSound(SOUND_FRANCIS02, true);
	PrecacheSound(SOUND_FRANCIS03, true);
	PrecacheSound(SOUND_FRANCIS04, true);
	
	PrecacheSound(SOUND_LOUIS01, true);
	PrecacheSound(SOUND_LOUIS02, true);
	PrecacheSound(SOUND_LOUIS03, true);
	PrecacheSound(SOUND_LOUIS04, true);
}
public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		DeleteLight(i);
		DeleteTP(i);
		ScientistPillsLock[i] = INVALID_HANDLE;
		CountHold[i] = 0;
		//InfectedPowerCount[i] = 0;
		GravityCheck[i] = INVALID_HANDLE;
		BoostCheck[i] = INVALID_HANDLE;
		SlowCheck[i] = INVALID_HANDLE;
	}
}
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	//ClientCommand(client, "bind f4 sm_menu");
	dp[client] = false;
	se[client] = false;
}
public Action:PrintPlayerClass(client, args)
{
	if (IsPlayerAlive(client))
	{
		if (MedicCheck[client])
		{
			PrintToChat(client, "%t", "youMedic");
			PrintToChat(client, "%t", "aboutMedic");
		}
		else if (AssaultCheck[client])
		{
			PrintToChat(client, "%t", "youAssault");
			PrintToChat(client, "%t", "aboutAssault");
			CreateTimer(5.0, AmmoSpawnAnnonce, client);
		}
		else if (EngineerCheck[client])
		{
			PrintToChat(client, "%t", "youEngineer");
			PrintToChat(client, "%t", "aboutEngineer");
			CreateTimer(5.0, JetPackSpawnAnnonce, client);
		}
		//else if (ReconCheck[client]) PrintToChat(client, "%t", "youRecon");
		else if (SupportCheck[client])
		{
			PrintToChat(client, "%t", "youSupport");
			PrintToChat(client, "%t", "aboutSupport");
		}
		else if (ScientistCheck[client])
		{
			PrintToChat(client, "%t", "youScientist");
			PrintToChat(client, "%t", "aboutScientist");
		}
		else if (!classCheck[client]) PrintToChat(client, "%t", "youNothing");
	}
	else PrintToChat(client, "%t", "youDeath");
}
public Action:SuperMeatServerPanel(client, args)
{
	if (GetClientTeam(client) != 2) return;
	CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
ResetCountClass()
{
	i_CountMedic = 0;
	i_CountAssault = 0;
	i_CountEngineer = 0;
	//i_CountRecon = 0;
	i_CountSupport = 0;
	i_CountScientist = 0;
	i_CountNothing = 0;
}
public Action:BuildSuperMeatServerPanel(Handle:timer, any:client)
{
	if (!IsClientInGame(client)) return Plugin_Handled;
	if (classCheck[client] && !MedicCheck[client] && !AssaultCheck[client] && !EngineerCheck[client] && !SupportCheck[client] && !ScientistCheck[client]) classCheck[client] = false;
	ResetCountClass();
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			if (MedicCheck[i]) i_CountMedic++;
			if (AssaultCheck[i]) i_CountAssault++;
			if (EngineerCheck[i]) i_CountEngineer++;
			//if (ReconCheck[i]) i_CountRecon++;
			if (SupportCheck[i]) i_CountSupport++;
			if (ScientistCheck[i]) i_CountScientist++;
			if (!classCheck[i]) i_CountNothing++;
		}
	}
	new Handle:smsmenu = CreateMenu(SMSMenuHandler);
	decl String:mTitle[32];
	new String:Value[64];
	
	if (!classCheck[client] && IsPlayerAlive(client))
	{
		Format(mTitle, sizeof(mTitle), "%T\n \n", "tSelectTitle", client);
		SetMenuTitle(smsmenu, mTitle);
		
		Format(Value, sizeof(Value), "%T \n-------------------", "m_Refresh", client);
		AddMenuItem(smsmenu, "0", Value);
		
		if (MedicCheck[client])	Format(Value, sizeof(Value), "%T", "uMedic", client, i_CountMedic);
		else Format(Value, sizeof(Value), "%T (%d)", "tMedic", client, i_CountMedic);
		AddMenuItem(smsmenu, "1", Value);
		
		if (AssaultCheck[client]) Format(Value, sizeof(Value), "%T", "uAssault", client, i_CountAssault);
		else Format(Value, sizeof(Value), "%T (%d)", "tAssault", client, i_CountAssault);
		AddMenuItem(smsmenu, "2", Value);
		
		if (EngineerCheck[client]) Format(Value, sizeof(Value), "%T", "uEngineer", client, i_CountEngineer);
		else Format(Value, sizeof(Value), "%T (%d)", "tEngineer", client, i_CountEngineer);
		AddMenuItem(smsmenu, "3", Value);
		
		/*if (ReconCheck[client]) Format(Value, sizeof(Value), "%T", "uRecon", client, i_CountRecon);
		else Format(Value, sizeof(Value), "%T (%d)", "tRecon", client, i_CountRecon);
		AddMenuItem(smsmenu, "4", Value);*/
		
		if (SupportCheck[client]) Format(Value, sizeof(Value), "%T", "uSupport", client, i_CountSupport);
		else Format(Value, sizeof(Value), "%T (%d)", "tSupport", client, i_CountSupport);
		AddMenuItem(smsmenu, "4", Value);
		
		if (ScientistCheck[client]) Format(Value, sizeof(Value), "%T\n-------------------", "uScientist", client, i_CountScientist);
		else Format(Value, sizeof(Value), "%T (%d)\n-------------------", "tScientist", client, i_CountScientist);
		AddMenuItem(smsmenu, "5", Value);
		
		if (!classCheck[client]) Format(Value, sizeof(Value), "%T", "uNothing", client, i_CountNothing);
		else Format(Value, sizeof(Value), "%T (%d)", "tNothing", client, i_CountNothing);
		AddMenuItem(smsmenu, "6", Value);
			
		SetMenuExitButton(smsmenu, true);
		DisplayMenu(smsmenu, client, 0);
	}
	else if (classCheck[client] || !IsPlayerAlive(client))
	{
		Format(mTitle, sizeof(mTitle), "%T\n \n", "tListTitle", client);
		SetMenuTitle(smsmenu, mTitle);
		
		Format(Value, sizeof(Value), "%T \n-------------------", "m_Refresh", client);
		AddMenuItem(smsmenu, "0", Value);
		
		if (MedicCheck[client])	Format(Value, sizeof(Value), "%T", "uMedicS", client, i_CountMedic);
		else Format(Value, sizeof(Value), "%T (%d)", "tMedicS", client, i_CountMedic);
		AddMenuItem(smsmenu, "1", Value);
		
		if (AssaultCheck[client]) Format(Value, sizeof(Value), "%T", "uAssaultS", client, i_CountAssault);
		else Format(Value, sizeof(Value), "%T (%d)", "tAssaultS", client, i_CountAssault);
		AddMenuItem(smsmenu, "2", Value);
		
		if (EngineerCheck[client]) Format(Value, sizeof(Value), "%T", "uEngineerS", client, i_CountEngineer);
		else Format(Value, sizeof(Value), "%T (%d)", "tEngineerS", client, i_CountEngineer);
		AddMenuItem(smsmenu, "3", Value);
		
		/*if (ReconCheck[client]) Format(Value, sizeof(Value), "%T", "uReconS", client, i_CountRecon);
		else Format(Value, sizeof(Value), "%T (%d)", "tReconS", client, i_CountRecon);
		AddMenuItem(smsmenu, "4", Value);*/
		
		if (SupportCheck[client]) Format(Value, sizeof(Value), "%T", "uSupportS", client, i_CountSupport);
		else Format(Value, sizeof(Value), "%T (%d)", "tSupportS", client, i_CountSupport);
		AddMenuItem(smsmenu, "4", Value);
		
		if (ScientistCheck[client]) Format(Value, sizeof(Value), "%T\n-------------------", "uScientistS", client, i_CountScientist);
		else Format(Value, sizeof(Value), "%T (%d)\n-------------------", "tScientistS", client, i_CountScientist);
		AddMenuItem(smsmenu, "5", Value);
		
		if (!classCheck[client]) Format(Value, sizeof(Value), "%T", "tNothing", client, i_CountNothing);
		else Format(Value, sizeof(Value), "%T (%d)", "tNothing", client, i_CountNothing);
		AddMenuItem(smsmenu, "6", Value);
			
		SetMenuExitButton(smsmenu, true);
		DisplayMenu(smsmenu, client, 0);
	}
	return Plugin_Handled;
}
public Action:RdropSlotItem(client, Float:vPos[3], Float:vAng[3])
{
	decl item;
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	if ((item = GetPlayerWeaponSlot(client, 3)) > 0 && IsClientInGame(client))
	{
		SDKHooks_DropWeapon(client, item, vPos, vAng);
		//PrintToChat(client, "Вы сменили класс и были разоружены.");
	}
}
/*
public Action:RdropSlotItemRec(client)
{
	decl item;
	if ((item = GetPlayerWeaponSlot(client, 0)) > 0 && IsClientInGame(client))
	{
		decl String:weapon[25];
		GetEdictClassname(item, weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SDKHooks_DropWeapon(client, item, NULL_VECTOR, NULL_VECTOR);
		}
	}
}*/
public SMSMenuHandler(Handle:smsmenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		new mode;
		switch (option)
		{
			case 0:	CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			case 1:
			{
				mode = 1;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectMedic(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}
			case 2:
			{
				mode = 2;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectAssault(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}
			case 3:
			{
				mode = 3;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectEngineer(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}
			/*case 4:
			{
				mode = 4;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectRecon(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}*/
			case 4:
			{
				mode = 4;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectSupport(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}
			case 5:
			{
				mode = 5;
				if (!classCheck[client] && IsPlayerAlive(client)) SelectScientist(client);
				else if (classCheck[client] || !IsPlayerAlive(client)) CreateTimer(0.5, BuildSuperMeatServerPanel, client);
			}
			case 6:
			{
				mode = 6;
				if (!classCheck[client] && IsPlayerAlive(client)) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
			}
		}
		GetClassList(mode, client);
	}
}
SelectMedic(client)
{
	new Handle:pMenu = CreateMenu(ConfirmMedic);
	decl String:ConfirmMedicTitle[40];
	Format(ConfirmMedicTitle, sizeof(ConfirmMedicTitle), "%T\n \n", "ConfirmMedicTitle", client);
	SetMenuTitle(pMenu, ConfirmMedicTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmMedic(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeMedic(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeMedic(client)
{
	if (iLightIndex[client] != 0)DeleteLight(client);
	//RdropSlotItemRec(client);
	//16384+134217728+4096+32768
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 134270976, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 1);
	MedLight(client);
	MedicCheck[client] = true;
	classCheck[client] = true;
	Call_StartForward(uClientTakeMedic);
	Call_PushCell(client);
	Call_Finish();
	PrintToChatAll("%t", "cMedic", ClientUserName);
	PrintToChat(client, "%t", "aboutMedic");
	//PrintToChat(client, "\x05Медик \x04- перенос аптек/табл. по 2, морфин, развитое самолечение.");
}
SelectAssault(client)
{
	new Handle:pMenu = CreateMenu(ConfirmAssault);
	decl String:ConfirmAssaultTitle[40];
	Format(ConfirmAssaultTitle, sizeof(ConfirmAssaultTitle), "%T\n \n", "ConfirmAssaultTitle", client);
	SetMenuTitle(pMenu, ConfirmAssaultTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmAssault(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeAssault(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeAssault(client)
{
	if (iLightIndex[client] != 0)DeleteLight(client);
	new Float:vPos[3], Float:vAng[3];
	RdropSlotItem(client, vPos, vAng);
	//RdropSlotItemRec(client);
	//128+524288+536870912=
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 537395200, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 2);
	AssLight(client);
	AssaultCheck[client] = true;
	classCheck[client] = true;
	Call_StartForward(uClientTakeAssault);
	Call_PushCell(client);
	Call_Finish();
	PrintToChatAll("%t", "cAssault", ClientUserName);
	PrintToChat(client, "%t", "aboutAssault");
	CreateTimer(10.0, AmmoSpawnAnnonce, client);
	//PrintToChat(client, "\x05Штурмовик \x04- перенос патронов, повышенный боекомплект, общая ловкость.");
}
SelectEngineer(client)
{
	new Handle:pMenu = CreateMenu(ConfirmEngineer);
	decl String:ConfirmEngineerTitle[40];
	Format(ConfirmEngineerTitle, sizeof(ConfirmEngineerTitle), "%T\n \n", "ConfirmEngineerTitle", client);
	SetMenuTitle(pMenu, ConfirmEngineerTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmEngineer(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeEngineer(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeEngineer(client)
{
	if (iLightIndex[client] != 0)DeleteLight(client);
	FakeClientCommandEx(client, "sm_jetpack");
	new Float:vPos[3], Float:vAng[3];
	RdropSlotItem(client, vPos, vAng);
	//RdropSlotItemRec(client);
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 9830402, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 3);
	EngLight(client);
	EngineerCheck[client] = true;
	classCheck[client] = true;
	Call_StartForward(uClientTakeEngineer);
	Call_PushCell(client);
	Call_Finish();
	PrintToChatAll("%t", "cEngineer", ClientUserName);
	PrintToChat(client, "%t", "aboutEngineer");
	//CreateTimer(10.0, JetPackSpawnAnnonce, client);
	//PrintToChat(client, "\x05Инженер \x04- расширенный магазин, глушитель, лазер, усиленная взрывчатка, джетпак.");
}
/*
SelectRecon(client)
{
	new Handle:pMenu = CreateMenu(ConfirmRecon);
	decl String:ConfirmReconTitle[40];
	Format(ConfirmReconTitle, sizeof(ConfirmReconTitle), "%T\n \n", "ConfirmReconTitle", client);
	SetMenuTitle(pMenu, ConfirmReconTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmRecon(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeRecon(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeRecon(client)
{
	Give_HuntingRifle(client);
	new Float:vPos[3], Float:vAng[3];
	RdropSlotItem(client, vPos, vAng);
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 117442816, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 4);
	ReconCheck[client] = true;
	classCheck[client] = true;
	Call_StartForward(uClientTakeRecon);
	Call_PushCell(client);
	Call_Finish();
	PrintToChatAll("%t", "cRecon", ClientUserName);
	PrintToChat(client, "%t", "aboutRecon");
	//PrintToChat(client, "\x05Снайпер \x04- плащ, нож, снайперский прицел на всём оружии, фарм.");
}
*/
SelectSupport(client)
{
	new Handle:pMenu = CreateMenu(ConfirmSupport);
	decl String:ConfirmSupportTitle[40];
	Format(ConfirmSupportTitle, sizeof(ConfirmSupportTitle), "%T\n \n", "ConfirmSupportTitle", client);
	SetMenuTitle(pMenu, ConfirmSupportTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmSupport(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeSupport(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeSupport(client)
{
	if (iLightIndex[client] != 0)DeleteLight(client);
	new Float:vPos[3], Float:vAng[3];
	RdropSlotItem(client, vPos, vAng);
	//RdropSlotItemRec(client);
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 128, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 4);
	SupLight(client);
	SupportCheck[client] = true;
	classCheck[client] = true;
	SetArmor(client);
	Call_StartForward(uClientTakeSupport);
	Call_PushCell(client);
	Call_Finish();
	PrintToChatAll("%t", "cSupport", ClientUserName);
	PrintToChat(client, "%t", "aboutSupport");
}
SelectScientist(client)
{
	new Handle:pMenu = CreateMenu(ConfirmScientist);
	decl String:ConfirmScientistTitle[40];
	Format(ConfirmScientistTitle, sizeof(ConfirmScientistTitle), "%T\n \n", "ConfirmScientistTitle", client);
	SetMenuTitle(pMenu, ConfirmScientistTitle);
	AddMenuItem(pMenu, "0", "Yes");
	AddMenuItem(pMenu, "1", "No back");
	DisplayMenu(pMenu, client, 0);
}
public ConfirmScientist(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) TakeScientist(client);
	if (option == 1) CreateTimer(0.1, BuildSuperMeatServerPanel, client);
}
public Action:TakeScientist(client)
{
	if (iLightIndex[client] != 0)DeleteLight(client);
	new Float:vPos[3], Float:vAng[3];
	RdropSlotItem(client, vPos, vAng);
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));
	ResetClass(client, 5);
	SciLight(client);
	ScientistCheck[client] = true;
	classCheck[client] = true;

	//Call_StartForward(uClientTakeScientist);
	//Call_PushCell(client);
	//Call_Finish();
	PrintToChatAll("%t", "cScientist", ClientUserName);
	PrintToChat(client, "%t", "aboutScientist");
}
ResetClass(client, mode)
{
	if (MedicCheck[client] || MedicHandle[client])
	{
		if (mode != 1)
		{
			Call_StartForward(uClientDropMedic);
			Call_PushCell(client);
			Call_Finish();
			MedicCheck[client] = false;
		}
	}
	if (AssaultCheck[client] || AssaultHandle[client])
	{
		if (mode != 2)
		{
			Call_StartForward(uClientDropAssault);
			Call_PushCell(client);
			Call_Finish();
			AssaultCheck[client] = false;
		}
	}
	if (EngineerCheck[client] || EngineerHandle[client])
	{
		if (mode != 3)
		{
			Call_StartForward(uClientDropEngineer);
			Call_PushCell(client);
			Call_Finish();
			EngineerCheck[client] = false;
		}
	}
	if (SupportCheck[client] || SupportHandle[client])
	{
		if (mode != 4)
		{
			Call_StartForward(uClientDropSupport);
			Call_PushCell(client);
			Call_Finish();
			SupportCheck[client] = false;
			SetArmor(client);
		}
	}
	if (ScientistCheck[client] || ScientistHandle[client])
	{
		if (mode != 5)
		{
			//Call_StartForward(uClientDropScientist);
			//Call_PushCell(client);
			//Call_Finish();
			ScientistCheck[client] = false;
		}
	}
	/*else if (ReconCheck[client])
	{
		Call_StartForward(uClientDropRecon);
		Call_PushCell(client);
		Call_Finish();
		ReconCheck[client] = false;
	}*/
}
ResetClass2(client)
{
	if (MedicCheck[client] && !MedicHandle[client])
	{
		Call_StartForward(uClientDropMedic);
		Call_PushCell(client);
		Call_Finish();
		MedicCheck[client] = false;
	}
	if (AssaultCheck[client] && !AssaultHandle[client])
	{
		Call_StartForward(uClientDropAssault);
		Call_PushCell(client);
		Call_Finish();
		AssaultCheck[client] = false;
	}
	if (EngineerCheck[client] && !EngineerHandle[client])
	{
		Call_StartForward(uClientDropEngineer);
		Call_PushCell(client);
		Call_Finish();
		EngineerCheck[client] = false;
	}
	if (SupportCheck[client] && !SupportHandle[client])
	{
		Call_StartForward(uClientDropSupport);
		Call_PushCell(client);
		Call_Finish();
		SupportCheck[client] = false;
		SetArmor(client);
	}
	if (ScientistCheck[client] && !ScientistHandle[client])
	{
		//Call_StartForward(uClientDropScientist);
		//Call_PushCell(client);
		//Call_Finish();
		ScientistCheck[client] = false;
	}
	/*else if (ReconCheck[client])
	{
		Call_StartForward(uClientDropRecon);
		Call_PushCell(client);
		Call_Finish();
		ReconCheck[client] = false;
	}*/
}
SetArmor(client)
{
	if (SupportCheck[client]) SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4000, 4, true);
	else SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 0, 4, true);
}
public Action:Timer_kit2(Handle:timer, any:client)
{
	kitCheck2[client] = false;
}
HP_StopTimer(client)
{
	if (HP_Timer_OnWeaponCanUse[client] != INVALID_HANDLE)
	{
		KillTimer(HP_Timer_OnWeaponCanUse[client]);
		HP_Timer_OnWeaponCanUse[client] = INVALID_HANDLE;
	}
}
HP_StopTimer_3(client)
{
	if (HP_Timer_OnWeaponCanUse2[client] != INVALID_HANDLE)
	{
		KillTimer(HP_Timer_OnWeaponCanUse2[client]);
		HP_Timer_OnWeaponCanUse2[client] = INVALID_HANDLE;
	}
}
public Action:HP_Timer_PermRegen(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		HP_Timer_OnWeaponCanUse[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	new hp = GetEntProp(client, Prop_Send, "m_iHealth") + 5;
	new tempHp = L4D_GetPlayerTempHealth(client);
	new totalHp = hp + tempHp;
	if (totalHp > 100) totalHp = 100;
	SetEntProp(client, Prop_Send, "m_iHealth", hp);
	if (totalHp < 100) return Plugin_Continue;
	HP_Timer_OnWeaponCanUse[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public Action:HP_Timer_BuffRegen(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		HP_Timer_OnWeaponCanUse2[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	new Float:hp3 = 1.0*L4D_GetPlayerTempHealth(client) + 7.0;
	L4D_SetPlayerTempHealth(client, any:hp3);
	if (hp3 > 100.0) hp3 = 100.0;
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", hp3);
	if (hp3 < 100.0) return Plugin_Continue;
	
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 1 && GetEntProp(client, Prop_Send, "m_currentReviveCount") != 2)
	{
		new ReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
		CheatCommand(client, "give", "health", "");
		SetEntityHealth(client, 15);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 85.0);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", ReviveCount);
	}
	
	HP_Timer_OnWeaponCanUse2[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public Action:OnWeaponCanUse(client, weapon)
{
	new String:iWeaponName[32];
	GetEdictClassname(weapon, iWeaponName, sizeof(iWeaponName));
	if (StrContains(iWeaponName, "weapon_first_aid_kit", false) != -1)
	{
		if (MedicCheck[client] && IsFakeClient(client) || KitTimeOut[weapon]) return Plugin_Handled;
		if (!MedicCheck[client]) return Plugin_Handled;
	}
	return Plugin_Continue;
}
stock CheatCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
public Action:SayTextHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadShort(bf);
	BfReadShort(bf);
	BfReadString(bf, g_msgType, sizeof(g_msgType), false);	

	if(StrContains(g_msgType, "prevent_it_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 8);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "Smoker's Tongue attack") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 9);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "ledge_save_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 11);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "revive_self_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 12);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "knife_expire") != -1)
	{
		CreateTimer(0.1, DelayPrintExpire, 26);
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "_expire") != -1)
	{
		return Plugin_Handled;
	}
	if(StrContains(g_msgType, "#L4D_Upgrade") != -1 && StrContains(g_msgType, "description") != -1)
	{
		return Plugin_Handled;
	}	
	if(StrContains(g_msgType, "NOTIFY_VOMIT_ON") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:DelayPrintExpire(Handle:hTimer, any:type)
{
	new client = GetClientUsedUpgrade(type);
	if(client == 0)
		return;

	decl String:ClientUserName[MAX_TARGET_LENGTH];
	GetClientName(client, ClientUserName, sizeof(ClientUserName));

	if(type == 8)
	{
		PrintToChatAll("%t", "BoomerNeut", ClientUserName);
	}
	else if(type == 9)
	{
		PrintToChatAll("%t", "TongueNeut", ClientUserName);
	}
	else if(type == 11)
	{
		PrintToChatAll("%t", "Chalk", ClientUserName);
	}
	else if(type == 12)
	{
		PrintToChatAll("%t", "Wind", ClientUserName);
	}
	else if(type == 26)
	{
		PrintToChatAll("%t", "Knife", ClientUserName);
	}
}
public OnMapEnd()
{
	OnGameEnd();
}
OnGameEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(SetClientUpgrades[i] != INVALID_HANDLE)
		{
			CloseHandle(SetClientUpgrades[i]);
			SetClientUpgrades[i] = INVALID_HANDLE;
		}
		if(h_SpectatorAnnonce[i] != INVALID_HANDLE)
		{
			CloseHandle(h_SpectatorAnnonce[i]);
			h_SpectatorAnnonce[i] = INVALID_HANDLE;
		}
		HP_StopTimer(i);
		HP_StopTimer_3(i);
	}
}
public SetClientUpgradesCheck(client)
{
	if(SetClientUpgrades[client] != INVALID_HANDLE)
	{
		CloseHandle(SetClientUpgrades[client]);
		SetClientUpgrades[client] = INVALID_HANDLE;
	}
	if(SetClientUpgrades[client] == INVALID_HANDLE)
	{
		SetClientUpgrades[client] = CreateTimer(UPGRADE_LOAD_TIME, SetSurvivorUpgrades, client);
	}
}
public event_PlayerDeath(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsClientInGame(client))
	{
		if (classCheck[client]) 
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
			classCheck[client] = false;
		}
		if (MedicCheck[client]) MedicCheck[client] = false;
		if (AssaultCheck[client]) AssaultCheck[client] = false;
		if (EngineerCheck[client]) EngineerCheck[client] = false;
		//if (ReconCheck[client]) ReconCheck[client] = false;
		if (SupportCheck[client])
		{
			SupportCheck[client] = false;
			SetArmor(client);
		}
		if (ScientistCheck[client]) ScientistCheck[client] = false;
		if (iLightIndex[client] != 0)DeleteLight(client);
		if (FirstKitHandle[client][0])
		{
			new entity = FirstKitHandle[client][1];
			if (IsValidEdict(entity))
			{
				decl String:item[64];
				GetEdictClassname(entity, item, sizeof(item));
				if(StrContains(item, "weapon_first_aid_kit", false) != -1)
				{	
					MedKitSmoke(entity);
					StartTrigger(entity);
					CreateTimer(15.0, Timer_KitReset, entity);
					KitTimeOut[entity] = true;
				}
			}
			FirstKitHandle[client][0] = 0;
			FirstKitHandle[client][1] = -1;
		}
		HP_StopTimer(client);
		HP_StopTimer_3(client);
		if (EmitSoundPlay[client]) EmitSoundPlay[client] = false;
		if(iTPIndex[client][0] != 0 || ScientistStartPos[client][0] != 0.0) DeleteTP(client);
		if (ScientistPillsLock[client] != INVALID_HANDLE)
		{
			KillTimer(ScientistPillsLock[client]);
			ScientistPillsLock[client] = INVALID_HANDLE;
		}
		if (CountHold[client]) CountHold[client] = 0;
		if (IsInfectedSlow[client])
		{
			IsInfectedSlow[client] = false;
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
		if (IsSurvivorBoost[client]) 
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			IsSurvivorBoost[client] = false;
		}
		if (IsSurvivorGravity[client]) 
		{
			SetEntityGravity(client, 1.0);
			IsSurvivorGravity[client] = false;
		}
		/*if(InfectedPowerCount[client])
		{
			InfectedPowerCount[client] = 0;
		}*/
		if (GravityCheck[client] != INVALID_HANDLE)
		{
			KillTimer(GravityCheck[client]);
			GravityCheck[client] = INVALID_HANDLE;
		}
		if (BoostCheck[client]!= INVALID_HANDLE)
		{
			KillTimer(BoostCheck[client]);
			BoostCheck[client] = INVALID_HANDLE;
		}
		if (SlowCheck[client]!= INVALID_HANDLE)
		{
			KillTimer(SlowCheck[client]);
			SlowCheck[client] = INVALID_HANDLE;
		}
	}
	/*new entityid = GetEventInt(event, "entityid");
	new bool:headshot = GetEventBool(event, "headshot");

	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 3) return;
		
	if(headshot == true && entityid > 0)
	{
		UpgradeOcularImplants(entityid);
	}*/
}
public event_Rescued(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		CreateTimer(1.0, BuildSuperMeatServerPanel, client);
	}
}
public Action:SetSurvivorUpgrades(Handle:timer, any:client)
{
	SetClientUpgrades[client] = INVALID_HANDLE;
	if(b_round_end == true)
	{
		return;
	}
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !HasIdlePlayer(client))
	{
		if(IsFakeClient(client) && iUpgradeDisabled[client][18] != 1)
		{
			if(iUpgrade[client][18] > 0)
			{
				iUpgrade[client][18] = 0;
			}
			iUpgradeDisabled[client][18] = 1;
		}
		iBitsUpgrades[client] = SetUpgradeBitVec(client);
		if(GetEntProp(client, Prop_Send, "m_upgradeBitVec") != iBitsUpgrades[client])
		{
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", iBitsUpgrades[client]);
		}
		if(iUpgrade[client][1] > 0)
		{
			//SetEntProp(client, Prop_Send, "m_ArmorValue", 4000);
			SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 4000, 4, true);
		}
		else
		{
			SetEntData(client, FindDataMapOffs(client, "m_ArmorValue"), 0, 4, true);
		}
		if(iUpgrade[client][36] > 0 || iUpgrade[client][37] > 0)
		{
			new iMaxHealth = 0;
			if(iUpgrade[client][36] > 0)
				iMaxHealth += 50;
			if(iUpgrade[client][37] > 0)
				iMaxHealth += 50;

			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + iMaxHealth);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iMaxHealth", 100);
		}
		if(iUpgrade[client][22] > 0)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 4);

		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0, 4);
			SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 4);
		}
		if(iUpgrade[client][31] > 0 && iGrenadePouch[client] == 1)
		{
			iGrenadePouch[client] = 1;
		}
		else
		{
			iGrenadePouch[client] = 0;
		}
	}
}
public event_ItemPickup(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:iWeaponName[32];
	GetEventString(event, "item", iWeaponName, 32);
	
	if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1)
	{
		GiveClientAmmo(client);
	}
	if(StrContains(iWeaponName, "first_aid_kit", false) != -1)
	{
		new targetid = GetPlayerWeaponSlot(client, 3);
		FirstKitHandle[client][1] = targetid;
		targetid = EntIndexToEntRef(targetid);
		new arrindex = -1;
		for( new i = 0; i < MAX_SPAWNS; i++ )
		{
			if(g_iSpawns[i][0] == targetid)
			{
				arrindex = i;
				break;
			}
		}
		if (arrindex != -1)
		{
			new entity = g_iSpawns[arrindex][1];
			if (IsValidEntRef(entity))
			{
				AcceptEntityInput(entity, "kill");
				g_iSpawns[arrindex][1] = 0;
				g_iSpawns[arrindex][0] = 0;
			}
		}
		FirstKitHandle[client][0] = 1;
		CreateTimer(1.0, HP_Timer_ItemPickup, client);
	}
}
public Action:HP_Timer_ItemPickup(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		new Hp = GetEntProp(client, Prop_Data, "m_iHealth");
		new tempHp = L4D_GetPlayerTempHealth(client);
		new totalHp = Hp + tempHp;
		
		if (Hp > 1)
		{
			if (totalHp < 90)
			{
				//PrintToChatAll("totalHp = (%d)", totalHp);
				if(!EmitSoundPlay[client])
				{
					EmitSoundToClient(client, "player/survivor/heal/bandaging_1.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundPlay[client] = true;
					CreateTimer(8.0, EmitSoundReset, client);
				}
				HP_StopTimer(client);
				HP_Timer_OnWeaponCanUse[client] = CreateTimer(3.0, HP_Timer_PermRegen, client, TIMER_REPEAT);
			}
		}
		else if (Hp <= 1)
		{
			if (totalHp < 90)
			{
				if(!EmitSoundPlay[client])
				{
					EmitSoundToClient(client, "player/survivor/heal/bandaging_1.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundPlay[client] = true;
					CreateTimer(8.0, EmitSoundReset, client);
				}
				HP_StopTimer_3(client);
				HP_Timer_OnWeaponCanUse2[client] = CreateTimer(3.0, HP_Timer_BuffRegen, client, TIMER_REPEAT);
			}
			else if (totalHp >= 90 && !IsFakeClient(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 1 && GetEntProp(client, Prop_Send, "m_currentReviveCount") != 2)
			{
				new ReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				CheatCommand(client, "give", "health", "");
				SetEntityHealth(client, 15);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 85.0);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", ReviveCount);
			}
		}
	}
}
public event_AmmoPickup(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GiveClientAmmo(client);
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if (iLightIndex[client] != 0) DeleteLight(client);
	if(iTPIndex[client][0] != 0 || ScientistStartPos[client][0] != 0.0) DeleteTP(client);
	if (!h_SpectatorAnnonce[client]) h_SpectatorAnnonce[client] = CreateTimer(10.0, t_SpecJoinAnnonce, client, TIMER_REPEAT);
	FirstKitHandle[client][0] = 0;
	FirstKitHandle[client][1] = -1;
}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !MedicCheck[client])
	{
		new Float:vPos[3], Float:vAng[3];
		RdropSlotItem(client, vPos, vAng);
	}
	if (MedicCheck[client] && !iLightIndex[client]) MedLight(client);
	else if (AssaultCheck[client] && !iLightIndex[client]) AssLight(client);
	else if (EngineerCheck[client] && !iLightIndex[client]) EngLight(client);
	else if (SupportCheck[client] && !iLightIndex[client]) SupLight(client);
	else if (ScientistCheck[client] && !iLightIndex[client]) SciLight(client);
	new ent;
	if ((ent = GetPlayerWeaponSlot(client, 3)) > 0)
	{
		FirstKitHandle[client][0] = 1;
		FirstKitHandle[client][1] = ent;
	}
}
public Action:t_SpecJoinAnnonce(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 1)
	{
		h_SpectatorAnnonce[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	PrintHintText(client, "%t", "JoinInGame");
	return Plugin_Continue;
}
public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!TranquilizerTimeout[client] && !IsInfectedSlow[client])
	{
		if (inflictor <= 32 && damagetype == -2147483646 && GetClientTeam(attacker) == 2 && !IsFakeClient(attacker) && MedicCheck[attacker])
		{
			decl String:weapons[32];
			GetClientWeapon(attacker, weapons, sizeof(weapons));
			if (strcmp(weapons, "weapon_hunting_rifle", false) == 0)
			{
				if (!IsTranquilizer[client])
				{
					InfectedSpeedUsual[client] = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
				}
				
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", InfectedSpeedUsual[client]-GetRandomFloat(0.1, 0.2));
				IsTranquilizer[client] = true;
				TranquilizerTimeout[client] = true;
				CreateTimer(10.0, Timer_Timeout, client);
				CreateTimer(15.0, Timer_Timeout2, client);
				
				SetEntityRenderColor(client, 66, 205, 255, 0);
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "5");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "10");
				DispatchKeyValue(ent_smoke, "Speed", "30");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "1");
				DispatchKeyValue(ent_smoke, "Rate", "20");
				DispatchKeyValue(ent_smoke, "JetLength", "20");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "10");
				DispatchKeyValue(ent_smoke, "rendercolor", "0 123 167");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "10");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "1");
				DispatchKeyValue(ent_smoke, "WindAngle", "1");
				TeleportEntity(ent_smoke, damagePosition, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				AcceptEntityInput(ent_smoke, "SetParent", client, ent_smoke);
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");

				if (!b_ExpertDifficulty)
				{
					decl String:attacker_name[MAX_NAME_LENGTH];
					decl String:victim_name[MAX_NAME_LENGTH];
					GetClientName(attacker, attacker_name, sizeof(attacker_name));
					GetClientName(client, victim_name, sizeof(victim_name));
					PrintToChatAll("%t", "MedicTranquilizer", attacker_name, victim_name);
				}
			}
		}
	}
}
public Action:Timer_Timeout(Handle:timer, any:client)
{
	if (IsClientInGame(client)) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", InfectedSpeedUsual[client]);
}
public Action:Timer_Timeout2(Handle:timer, any:client)
{
	TranquilizerTimeout[client] = false;
	if (IsClientInGame(client)) SetEntityRenderColor(client, 255, 255, 255, 255);
}
public Action:event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:item[64];
	new targetid = GetEventInt(event, "targetid");
	if (targetid < 0 || !IsValidEntity(targetid) || !IsValidEdict(targetid))
	{
		return;
	}
	GetEdictClassname(targetid, item, sizeof(item));

	if(StrContains(item, "ammo", false) != -1)
	{
		ClearPlayerAmmo(client);
		CheatCommand(client, "give", "ammo", "");
		GiveClientAmmo(client);
	}
	else if(StrContains(item, "smg", false) != -1 || StrContains(item, "rifle", false) != -1 || StrContains(item, "shotgun", false) != -1)
	{
		if(MedicCheck[client])
		{
			new iWEAPON = GetPlayerWeaponSlot(client, 0);
			if (iWEAPON > 0)
			{
				new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
				if(StrContains(item, "smg", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(5*4)) > ammo)SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "hunting_rifle", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(2*4)) > ammo)SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "weapon_rifle", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(3*4)) > ammo)SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "shotgun", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(6*4)) > ammo)SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, ammo);
				}
			}
		}
		else if(AssaultCheck[client])
		{
			new iWEAPON = GetPlayerWeaponSlot(client, 0);
			if (iWEAPON > 0)
			{
				new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
				if(StrContains(item, "smg", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(5*4)) > ammo)SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "hunting_rifle", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(2*4)) > ammo)SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "weapon_rifle", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(3*4)) > ammo)SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, ammo);
				}
				else if(StrContains(item, "shotgun", false) != -1)
				{
					new ammo = RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1"));
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(6*4)) > ammo)SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, ammo);
				}
			}
		}
		else if(SupportCheck[client])
		{
			new iWEAPON = GetPlayerWeaponSlot(client, 0);
			if (iWEAPON > 0)
			{
				new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
				if(StrContains(item, "smg", false) != -1)
				{
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(5*4)) == GetConVarInt(FindConVar("ammo_smg_max")))SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				}
				else if(StrContains(item, "hunting_rifle", false) != -1)
				{
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(2*4)) == GetConVarInt(FindConVar("ammo_huntingrifle_max")))SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				}
				else if(StrContains(item, "weapon_rifle", false) != -1)
				{
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(3*4)) == GetConVarInt(FindConVar("ammo_assaultrifle_max")))SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				}
				else if(StrContains(item, "shotgun", false) != -1)
				{
					if (GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo")+(6*4)) == GetConVarInt(FindConVar("ammo_buckshot_max")))SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				}
			}
		}
	}
	else if(StrContains(item, "first_aid_kit", false) != -1)
	{
		if (kitCheck2[client] == false && !MedicCheck[client])
		{
			PrintToChat(client, "%t", "onlyMedic");
			PrintToChat(client, "%t", "onlyMedic2");
			CreateTimer(5.0, Timer_kit2, client);
			kitCheck2[client] = true;
		}
		
	}
}
bool:IsPillsWeapon(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:item[64];
		GetEdictClassname(ent, item, sizeof(item));
		{
			if(StrEqual(item, "weapon_pain_pills"))
			{
				return true;
			}
		}
	}
	return false;
}
bool:IsFIKWeapon(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:item[64];
		GetEdictClassname(ent, item, sizeof(item));
		{
			if(StrEqual(item, "weapon_first_aid_kit"))
			{
				return true;
			}
		}
	}
	return false;
}
public Action:Timer_KitReset(Handle:timer, any:item) 
{
	KitTimeOut[item] = false;
}
public Action:OnPlayerRunCmd(client, &buttons, &impuls, Float:vel[3], Float:angles[3], &weapon)
{
	if (client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client)) return;
	new weapons=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsFIKWeapon(weapons))
	{
		if (buttons & IN_ATTACK)
		{
			decl item;
			if ((item = GetPlayerWeaponSlot(client, 3)) > 0)
			{
				SDKHooks_DropWeapon(client, item, NULL_VECTOR, NULL_VECTOR);
				FirstKitHandle[client][0] = 0;
				FirstKitHandle[client][1] = -1;
				HP_StopTimer(client);
				HP_StopTimer_3(client);
				FakeClientCommandEx(client, "vocalize PlayerSpotFirstAid");
				MedKitSmoke(item);
				StartTrigger(item);
				CreateTimer(15.0, Timer_KitReset, item);
				KitTimeOut[item] = true;
				if (!b_ExpertDifficulty)
				{
					decl String:username[MAX_NAME_LENGTH];
					GetClientName(client, username, sizeof(username));
					PrintToChatAll("%t", "MedDropKit", username);
				}
			}
		}
	}
	if (IsPillsWeapon(weapons) && ScientistCheck[client])
	{
		if (buttons & IN_ATTACK2)
		{
			decl item;
			//таймаут использования
			if ((item = GetPlayerWeaponSlot(client, 4)) > 0)
			{
				if (!ScientistPillsLock[client])
				{
					RemovePlayerItem(client, item);
					AcceptEntityInput(item, "Kill");
					
					CountHold[client] = 0;
					
					ScientistPillsLock[client] = CreateTimer (300.0, PillsUseUnLock, client);
					CreateTimer (1.0, PillsSmoke, client, TIMER_REPEAT);
				}
				else
				{
					if (CountHold[client] == 0 || CountHold[client] == 115)
					{
						PrintToChat(client, "%t", "wait_pills");
						CountHold[client] = 1;
						return;
					}
					CountHold[client]++;
					//ClientCommand(client, "lastinv");
					return;
				}
			}
		}
	}
	if (MedicCheck[client] || (MedicHandle[client] && !classCheck[client]))
	{
		if (buttons & IN_SCORE)
		{
			if (se[client]) return;
			
			if (se[client] == false)
			{
				se[client] = true;
				
				CreateTimer(1.0, PAe, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(2.0, PAe, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, PAe, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.5, Reset, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}
MedKitSmoke(index)
{
	new entity = CreateEntityByName("env_smokestack");
	new Float:kit_location[3];
	new Float:kitangle[3] = {0.0, 0.0, 90.0};
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
	TeleportEntity(entity, kit_location, kitangle, NULL_VECTOR);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", index, entity);
	SetVariantString("OnUser1 !self:TurnOff::15.0:-1");
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
	SetVariantString("OnUser1 !self:TurnOff::15.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
GiveClientAmmo(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	new iWEAPON = GetPlayerWeaponSlot(client, 0);

	if(iWEAPON > 0)
	{
		new String:iWeaponName[32];
		GetEdictClassname(iWEAPON, iWeaponName, 32);

		if(SupportCheck[client])
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1 || StrContains(iWeaponName, "sniper", false) != -1)
			{
				SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 1.5)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			}
		}
		else if(MedicCheck[client])
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1)
			{
				SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 0.7)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			}
		}
		else if(AssaultCheck[client])
		{
			if(StrContains(iWeaponName, "smg", false) != -1 || StrContains(iWeaponName, "rifle", false) != -1 || StrContains(iWeaponName, "shotgun", false) != -1)
			{
				SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_huntingrifle_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_assaultrifle_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_smg_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
				SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, RoundToNearest((GetConVarInt(FindConVar("ammo_buckshot_max")) * 0.8)) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			}
		}
		else
		{
			SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_huntingrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_assaultrifle_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_smg_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
			SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, GetConVarInt(FindConVar("ammo_buckshot_max")) + (CheckWeaponUpgradeLimit(iWEAPON, client) - GetEntProp(iWEAPON, Prop_Send, "m_iClip1")));
		}
	}
}
ClearPlayerAmmo(client)
{
	new m_iAmmo = FindDataMapOffs(client, "m_iAmmo");
	SetEntData(client, m_iAmmo+HUNTING_RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+RIFLE_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SMG_OFFSET_AMMO, 0);
	SetEntData(client, m_iAmmo+SHOTGUN_OFFSET_AMMO, 0);
}
CheckWeaponUpgradeLimit(weapon, client)
{
	new UpgradeLimit = 0;
	if(weapon>0 && IsValidEdict(weapon) && IsValidEntity(weapon))
	{
		decl String:WEAPON_NAME[64];
		GetEdictClassname(weapon, WEAPON_NAME, 32);

		if(StrEqual(WEAPON_NAME, "weapon_rifle") || StrEqual(WEAPON_NAME, "weapon_smg"))
		{
			UpgradeLimit = 50;
		}
		else if(StrEqual(WEAPON_NAME, "weapon_pumpshotgun"))
		{
			UpgradeLimit = 8;
		}
		else if(StrEqual(WEAPON_NAME, "weapon_autoshotgun"))
		{
			UpgradeLimit = 10;
		}
		else if(StrEqual(WEAPON_NAME, "weapon_hunting_rifle"))
		{
			UpgradeLimit = 15;
		}
	}
	if (EngineerCheck[client])
	{
		UpgradeLimit = RoundFloat(UpgradeLimit * 1.5);
	}
	return UpgradeLimit;
}
public RemoveUpgrade(client, upgrade)
{
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(i == upgrade)
		{
			iUpgrade[client][upgrade] = 0;
			SetClientUpgradesCheck(client);
		}
	}
}
public SetUpgradeBitVec(client)
{
	new upgradeBitVec = 0;
	for(new i = 0; i < 31; i++)
	{
		if(iUpgrade[client][i] > 0 && iUpgradeDisabled[client][i] != 1)
		{
			upgradeBitVec += iUpgrade[client][i];
		}
	}
	return upgradeBitVec;
}
public MissingSurvivorUpgrades(client)
{
	new upgrades = 0;
	for(new i = 0; i < MAX_UPGRADES; i++)
	{
		if(iUpgrade[client][i] <= 0)
		{
			upgrades++;
		}
	}
	return upgrades;
}
public Action:UpgradeLaserSightToggle(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client)) return;
	if(GetClientTeam(client) == 2 && EngineerCheck[client])
	{
		new upDates = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if((upDates == 9699330) || (upDates == 9437186))
		{
			PrintToChat(client, "%t", "LaserOn");
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", upDates + 131072, 4);
		}
		else if((upDates == 9830402) || (upDates == 9568258))
		{
			PrintToChat(client, "%t", "LaserOff");
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", upDates - 131072, 4);
		}
		else return;
	}
	else if(!EngineerCheck[client])
	{
		PrintToChat(client, "%t", "only_engineers");
	}
}
public Action:UpgradeSilencerToggle(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client)) return;
	if(GetClientTeam(client) == 2 && EngineerCheck[client])
	{
		new upDates = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
		if((upDates == 9568258) || (upDates == 9437186))
		{
			PrintToChat(client, "%t", "SilencerOn");
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", upDates + 262144, 4);
		}
		else if((upDates == 9830402) || (upDates == 9699330))
		{
			PrintToChat(client, "%t", "SilencerOff");
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", upDates - 262144, 4);
		}
		else return;
	}
	else if(!EngineerCheck[client])
	{
		PrintToChat(client, "%t", "only_engineers");
	}
}
public OnClientPutInServer(client)
{
	if (IsFakeClient(client) || !client) return;
	classCheck[client] = false;
	if(iTPIndex[client][0] != 0 || ScientistStartPos[client][0] != 0.0) DeleteTP(client);
	SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
	CreateTimer(10.0, BuildSuperMeatServerPanel, client);
	CreateTimer(1.0, m_upgradeClass, client);
	if (ScientistPillsLock[client] != INVALID_HANDLE)
	{
		KillTimer(ScientistPillsLock[client]);
		ScientistPillsLock[client] = INVALID_HANDLE;
	}
	CountHold[client] = 0;
	//InfectedPowerCount[client] = 0;
	if (GravityCheck[client] != INVALID_HANDLE)
	{
		KillTimer(GravityCheck[client]);
		GravityCheck[client] = INVALID_HANDLE;
	}
	if (BoostCheck[client]!= INVALID_HANDLE)
	{
		KillTimer(BoostCheck[client]);
		BoostCheck[client] = INVALID_HANDLE;
	}
	if (SlowCheck[client]!= INVALID_HANDLE)
	{
		KillTimer(SlowCheck[client]);
		SlowCheck[client] = INVALID_HANDLE;
	}
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = true;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if (EmitSoundPlay[i]) EmitSoundPlay[i] = false;
			SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0, 4);
			if(iGrenadePouch[i] == 1)
			{
				iGrenadePouch[i] = 2;
			}
			ResetClass2(i);
			if (iLightIndex[i] != 0)DeleteLight(i);
			if(iTPIndex[i][0] != 0 || ScientistStartPos[i][0] != 0.0) DeleteTP(i);
			//if (ScientistPillsLock[i]) ScientistPillsLock[i] = false;
			if (ScientistPillsLock[i] != INVALID_HANDLE)
			{
				KillTimer(ScientistPillsLock[i]);
				ScientistPillsLock[i] = INVALID_HANDLE;
			}
			if (CountHold[i]) CountHold[i] = 0;
			if (IsSurvivorBoost[i])
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
				IsSurvivorBoost[i] = false;
			}
			if (IsSurvivorGravity[i]) 
			{
				SetEntityGravity(i, 1.0);
				IsSurvivorGravity[i] = false;
			}
			/*if(InfectedPowerCount[i])
			{
				InfectedPowerCount[i] = 0;
			}*/
			if (GravityCheck[i] != INVALID_HANDLE)
			{
				KillTimer(GravityCheck[i]);
				GravityCheck[i] = INVALID_HANDLE;
			}
			if (BoostCheck[i]!= INVALID_HANDLE)
			{
				KillTimer(BoostCheck[i]);
				BoostCheck[i] = INVALID_HANDLE;
			}
			if (SlowCheck[i]!= INVALID_HANDLE)
			{
				KillTimer(SlowCheck[i]);
				SlowCheck[i] = INVALID_HANDLE;
			}
		}
	}
	OnGameEnd();
}
public Action:map_transition(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_LockDifficulty = true;
	b_round_end = true;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (EmitSoundPlay[i]) EmitSoundPlay[i] = false;
			SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0, 4);
			if (iLightIndex[i] != 0)DeleteLight(i);
			if(iTPIndex[i][0] != 0 || ScientistStartPos[i][0] != 0.0) DeleteTP(i);
			//if (ScientistPillsLock[i]) ScientistPillsLock[i] = false;
			if (ScientistPillsLock[i] != INVALID_HANDLE)
			{
				KillTimer(ScientistPillsLock[i]);
				ScientistPillsLock[i] = INVALID_HANDLE;
			}
			if (CountHold[i]) CountHold[i] = 0;
			if (IsSurvivorBoost[i])
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
				IsSurvivorBoost[i] = false;
			}
			if (IsSurvivorGravity[i]) 
			{
				SetEntityGravity(i, 1.0);
				IsSurvivorGravity[i] = false;
			}
			if(iGrenadePouch[i] == 1)
			{
				iGrenadePouch[i] = 2;
			}
			/*if (InfectedPowerCount[i])
			{
				InfectedPowerCount[i] = 0;
			}*/
			if (GravityCheck[i] != INVALID_HANDLE)
			{
				KillTimer(GravityCheck[i]);
				GravityCheck[i] = INVALID_HANDLE;
			}
			if (BoostCheck[i]!= INVALID_HANDLE)
			{
				KillTimer(BoostCheck[i]);
				BoostCheck[i] = INVALID_HANDLE;
			}
			if (SlowCheck[i]!= INVALID_HANDLE)
			{
				KillTimer(SlowCheck[i]);
				SlowCheck[i] = INVALID_HANDLE;
			}
			if(MedicCheck[i])
			{
				MedicHandle[i] = true;
				AssaultHandle[i] = false;
				EngineerHandle[i] = false;
				//ReconHandle[i] = false;
				SupportHandle[i] = false;
				ScientistHandle[i] = false;
				if (GetPlayerWeaponSlot(i, 3) > 0) FirstKitHandle[i][0] = 1;
			}
			else if (AssaultCheck[i])
			{
				AssaultHandle[i] = true;
				MedicHandle[i] = false;
				EngineerHandle[i] = false;
				//ReconHandle[i] = false;
				SupportHandle[i] = false;
				ScientistHandle[i] = false;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}
			else if (EngineerCheck[i])
			{
				EngineerHandle[i] = true;
				MedicHandle[i] = false;
				AssaultHandle[i] = false;
				//ReconHandle[i] = false;
				SupportHandle[i] = false;
				ScientistHandle[i] = false;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}
			/*else if (ReconCheck[i])
			{
				ReconHandle[i] = true;
				MedicHandle[i] = false;
				AssaultHandle[i] = false;
				EngineerHandle[i] = false;
				SupportHandle[i] = false;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}*/
			else if (SupportCheck[i])
			{
				SupportHandle[i] = true;
				MedicHandle[i] = false;
				AssaultHandle[i] = false;
				EngineerHandle[i] = false;
				//ReconHandle[i] = false;
				ScientistHandle[i] = false;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}
			else if (ScientistCheck[i])
			{
				MedicHandle[i] = false;
				AssaultHandle[i] = false;
				EngineerHandle[i] = false;
				//ReconHandle[i] = false;
				SupportHandle[i] = false;
				ScientistHandle[i] = true;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}
			else 
			{
				MedicHandle[i] = false;
				AssaultHandle[i] = false;
				EngineerHandle[i] = false;
				//ReconHandle[i] = false;
				SupportHandle[i] = false;
				ScientistHandle[i] = false;
				FirstKitHandle[i][0] = 0;
				FirstKitHandle[i][1] = -1;
			}
		}
	}
	OnGameEnd();
}
public event_WeaponFire(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new WeaponID = GetEventInt(event, "weaponid");
	if(WeaponID == 9)
	{
		iGrenadePouch[client] -= 1;
		UpgradeKerosene(client);
	}	
	if(WeaponID == 10)
	{
		UpgradeSafetyFuse(client);
		iGrenadePouch[client] -= 1;
		CreateTimer(1.0, timer_SafetyFuseStop, client);
	}
}
public event_HealSuccess(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!classCheck[client]) classCheck[client] = true;

	FirstKitHandle[client][0] = 0;
	FirstKitHandle[client][1] = -1;
}
public event_MeleeKill(Handle:event, const String:name[], bool:Broadcast) 
{
	new entityid = GetEventInt(event, "entityid");
	new bool:ambush = GetEventBool(event, "ambush");
	if(ambush == true) UpgradePickpocketHook(entityid);
}
public event_BreakProp(Handle:event, const String:name[], bool:Broadcast) 
{
	new entindex = GetEventInt(event, "entindex");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	UpgradeKeroseneSpray(client, entindex);
}
public UpgradeSafetyFuse(client)
{
	if(EngineerCheck[client])
	{
		SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration*1.5, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
		SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.6, false, false);
	}
}
public Action:timer_SafetyFuseStop(Handle:timer, any:client)
{
	SetConVarFloat(FindConVar("pipe_bomb_timer_duration"), PipeBombDuration, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_interval_delta"), 0.025, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_beep_min_interval"), 0.1, false, false);
	SetConVarFloat(FindConVar("pipe_bomb_initial_beep_interval"), 0.5, false, false);
	return Plugin_Handled;
}
public UpgradePickpocketHook(entityid)
{
	new iChance[9];
	iChance[1] = 7;
	iChance[2] = 5;
	iChance[3] = 6;
	iChance[4] = 7;
	iChance[5] = 4;
	iChance[6] = 7;
	iChance[7] = 7;
	iChance[8] = 7;

	for(new iRandom = 1; iRandom < 8; iRandom++)
	{
		decl Float:fOrigin[3];
		GetEntPropVector(entityid, Prop_Data, "m_vecOrigin", fOrigin);
		new iDrop;

		fOrigin[2] += 40.0;
		new Float:vel[3];
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(40.0, 80.0);

		if(GetRandomInt(0, 200) < iChance[iRandom])
		{
			if(iRandom <= 1)	iDrop = CreateEntityByName("weapon_pistol");
			else if(iRandom == 2)	iDrop = CreateEntityByName("weapon_pipe_bomb");
			else if(iRandom == 3)	iDrop = CreateEntityByName("weapon_molotov");
			else if(iRandom == 4)	iDrop = CreateEntityByName("weapon_pain_pills");
			else if(iRandom == 5)	iDrop = CreateEntityByName("weapon_first_aid_kit");
			else if(iRandom == 6)	iDrop = CreateEntityByName("weapon_rifle");
			else if(iRandom == 7)	iDrop = CreateEntityByName("weapon_autoshotgun");
			else if(iRandom >= 8)	iDrop = CreateEntityByName("weapon_hunting_rifle");

			DispatchSpawn(iDrop);
			ActivateEntity(iDrop);
			TeleportEntity(iDrop, fOrigin, NULL_VECTOR, vel);
		}
	}
}
/*public UpgradeOcularImplants(entityid)
{
	new iChance[9];
	iChance[1] = 7;
	iChance[2] = 5;
	iChance[3] = 6;
	iChance[4] = 7;
	iChance[5] = 4;
	iChance[6] = 7;
	iChance[7] = 7;
	iChance[8] = 7;

	for(new iRandom = 1; iRandom < 8; iRandom++)
	{
		decl Float:fOrigin[3];
		GetEntPropVector(entityid, Prop_Data, "m_vecOrigin", fOrigin);
		new iDrop;

		fOrigin[2] += 40.0;
		new Float:vel[3];
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(40.0, 80.0);

		if(GetRandomInt(0, 200) < iChance[iRandom])
		{
			if(iRandom <= 1)	iDrop = CreateEntityByName("weapon_pistol");
			else if(iRandom == 2)	iDrop = CreateEntityByName("weapon_pipe_bomb");
			else if(iRandom == 3)	iDrop = CreateEntityByName("weapon_molotov");
			else if(iRandom == 4)	iDrop = CreateEntityByName("weapon_pain_pills");
			else if(iRandom == 5)	iDrop = CreateEntityByName("weapon_first_aid_kit");
			else if(iRandom == 6)	iDrop = CreateEntityByName("weapon_rifle");
			else if(iRandom == 7)	iDrop = CreateEntityByName("weapon_autoshotgun");
			else if(iRandom >= 8)	iDrop = CreateEntityByName("weapon_hunting_rifle");

			if(iRandom > 5 && iRandom < 9)
				SetEntProp(iDrop, Prop_Send, "m_iExtraPrimaryAmmo", GetRandomInt(50, 128));

			DispatchSpawn(iDrop);
			ActivateEntity(iDrop);
			TeleportEntity(iDrop, fOrigin, NULL_VECTOR, vel);
		}
	}
}*/
public UpgradeKeroseneSpray(client, entindex)
{
	if(EngineerCheck[client])
	{
		decl String:sModelFile[256];
		GetEntPropString(entindex, Prop_Data, "m_ModelName", sModelFile, sizeof(sModelFile));

		if(StrEqual(sModelFile, ENTITY_GASCAN, false))
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entindex, Prop_Data, "m_vecOrigin", fOrigin);

			new Handle:pack = CreateDataPack();
			WritePackFloat(pack, fOrigin[0]);
			WritePackFloat(pack, fOrigin[1]);
			WritePackFloat(pack, fOrigin[2]);
			//WritePackCell(pack, client);
			CreateTimer(10.0, timer_PyroPouchGasCan, pack);
		}
		if(StrEqual(sModelFile, ENTITY_PROPANE, false))
		{
			decl Float:fOrigin[3];
			GetEntPropVector(entindex, Prop_Data, "m_vecOrigin", fOrigin);

			new Handle:pack = CreateDataPack();
			WritePackFloat(pack, fOrigin[0]);
			WritePackFloat(pack, fOrigin[1]);
			WritePackFloat(pack, fOrigin[2]);
			WritePackCell(pack, client);
			CreateTimer(0.8, timer_PyroPouchPropane, pack, TIMER_REPEAT);
		}
	}
}
public UpgradeKerosene(client)
{
	if(EngineerCheck[client]) CreateTimer(0.3, CreateMolotovTimer);
}
public Action:CreateMolotovTimer(Handle:hTimer, any:type)
{
	new iEntity = INVALID_ENT_REFERENCE;
	while ((iEntity = FindEntityByClassname(iEntity, "molotov_projectile")) != INVALID_ENT_REFERENCE)
	{
		HookSingleEntityOutput(iEntity, "OnKilled", MolotovBreak);
	}
}
public MolotovBreak(const String:output[], caller, activator, Float:delay)
{
	decl Float:fOrigin[3];
	GetEntPropVector(caller, Prop_Data, "m_vecOrigin", fOrigin);
	new Handle:pack = CreateDataPack();
	WritePackFloat(pack, fOrigin[0]);
	WritePackFloat(pack, fOrigin[1]);
	WritePackFloat(pack, fOrigin[2]);
	//WritePackCell(pack, activator);
	CreateTimer(10.0, timer_PyroPouchGasCan, pack);
}
public Action:timer_PyroPouchGasCan(Handle:timer, any:pack)
{
	decl Float:fOrigin[3];
	ResetPack(pack);
	fOrigin[0] = ReadPackFloat(pack);
	fOrigin[1] = ReadPackFloat(pack);
	fOrigin[2] = ReadPackFloat(pack);

	new entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		fOrigin[2] += 30.0;
		DispatchKeyValue(entity, "model", ENTITY_GASCAN);
		DispatchKeyValue(entity, "rendermode", "1");
		DispatchKeyValue(entity, "renderamt", "0");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		GasSpawn = 0;
		//AddNormalSoundHook(NormalSHook:SoundHook);
		CreateTimer(2.0, Timer_Func); 
		ActivateEntity(entity);
	}
}
public Action:Timer_Func(Handle:timer) 
{ 
	AddNormalSoundHook(NormalSHook:SoundHook);
}
public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) 
{
	if (StrContains(sample, "molotov_detonate_3", false) != -1 && GasSpawn == 0)
	{
		//PrintToChatAll("sample = [%s]",sample);
		volume = 0.0;
		GasSpawn = 1;
		CreateTimer(0.5, timer_RemoveNormalSoundHook);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action:timer_RemoveNormalSoundHook(Handle:timer)
{
	RemoveNormalSoundHook(NormalSHook:SoundHook);
}
public Action:timer_PyroPouchPropane(Handle:timer, any:pack)
{
	decl Float:fOrigin[3];

	ResetPack(pack);
	fOrigin[0] = ReadPackFloat(pack);
	fOrigin[1] = ReadPackFloat(pack);
	fOrigin[2] = ReadPackFloat(pack);
	new client = ReadPackCell(pack);

	new entity = CreateEntityByName("prop_physics");
	if(IsValidEntity(entity))
	{
		fOrigin[2] += 30.0;
		DispatchKeyValue(entity, "model", ENTITY_PROPANE);
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
	iCountTimer[client] += 1;
	if(iCountTimer[client] > 2)
	{
		iCountTimer[client] = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
stock bool:HasIdlePlayer(bot)
{
    new userid = GetEntData(bot, FindSendPropInfo("SurvivorBot", "m_humanSpectatorUserID"));
    new client = GetClientOfUserId(userid);
    
    if(client > 0)
    {
        if(IsClientConnected(client) && !IsFakeClient(client))
            return true;
    }    
    return false;
}
stock GetClientUsedUpgrade(upgrade)
{
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			new used = GetEntProp(i, Prop_Send, "m_upgradeBitVec");
			if(iUpgrade[i][upgrade] > 0 && (used & 1 << upgrade != 1 << upgrade))
			{
				RemoveUpgrade(i, upgrade);
				return i;
			}
		}
	}
	return 0;
}
public OnClientDisconnect(client)
{
	if (!IsFakeClient(client))
	{
		if(SetClientUpgrades[client] != INVALID_HANDLE)
		{
			CloseHandle(SetClientUpgrades[client]);
			SetClientUpgrades[client] = INVALID_HANDLE;
		}
		HP_StopTimer(client);
		HP_StopTimer_3(client);
		IsTranquilizer[client] = false;
		TranquilizerTimeout[client] = false;
		if (iLightIndex[client] != 0) DeleteLight(client);
		if(iTPIndex[client][0] != 0 || ScientistStartPos[client][0] != 0.0) DeleteTP(client);
		if (ScientistPillsLock[client] != INVALID_HANDLE)
		{
			KillTimer(ScientistPillsLock[client]);
			ScientistPillsLock[client] = INVALID_HANDLE;
		}
		if (CountHold[client]) CountHold[client] = 0;
		if (IsSurvivorBoost[client])
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			IsSurvivorBoost[client] = false;
		}
		if (IsSurvivorGravity[client]) 
		{
			SetEntityGravity(client, 1.0);
			IsSurvivorGravity[client] = false;
		}
		/*if(InfectedPowerCount[client])
		{
			InfectedPowerCount[client] = 0;
		}*/
		if (GravityCheck[client] != INVALID_HANDLE)
		{
			KillTimer(GravityCheck[client]);
			GravityCheck[client] = INVALID_HANDLE;
		}
		if (BoostCheck[client]!= INVALID_HANDLE)
		{
			KillTimer(BoostCheck[client]);
			BoostCheck[client] = INVALID_HANDLE;
		}
		if (SlowCheck[client]!= INVALID_HANDLE)
		{
			KillTimer(SlowCheck[client]);
			SlowCheck[client] = INVALID_HANDLE;
		}
		if (!b_LockDifficulty)
		{
			AssaultHandle[client] = false;
			MedicHandle[client] = false;
			EngineerHandle[client] = false;
			SupportHandle[client] = false;
			ScientistHandle[client] = false;
			EmitSoundPlay[client] = false;
			FirstKitHandle[client][0] = 0;
			FirstKitHandle[client][1] = -1;
			ResetClass2(client);
		}
		dp[client] = false;
		se[client] = false;
	}
}
public Action:SelectClassMenu(client, args)
{
	if (MedicCheck[client]) MedicPanel(client);
	else if (AssaultCheck[client]) AssaultPanel(client);
	else if (EngineerCheck[client]) EngineerPanel(client);
	//else if (ReconCheck[client]) ReconPanel(client);
	else if (SupportCheck[client]) SupportPanel(client);
	else if (ScientistCheck[client]) ScientistPanel(client);
	else PlayerPanel(client);
}
public Action:MedicPanel(client) 
{
	new Handle:MedicMenu = CreateMenu(MedicMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleMedic", client);
	SetMenuTitle(MedicMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(MedicMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(MedicMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(MedicMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(MedicMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(MedicMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(MedicMenu, "5", Value);

	SetMenuExitButton(MedicMenu, true);
	DisplayMenu(MedicMenu, client, 30);
	
	return Plugin_Handled;
}
public MedicMenuHandler(Handle:MedicMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: FakeClientCommandEx(client, "sm_diff");
			case 5: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
public Action:AssaultPanel(client) 
{
	new Handle:AssaultMenu = CreateMenu(AssaultMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleAssault", client);
	SetMenuTitle(AssaultMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(AssaultMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(AssaultMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(AssaultMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(AssaultMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Ammo", client);
	AddMenuItem(AssaultMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(AssaultMenu, "5", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(AssaultMenu, "6", Value);

	SetMenuExitButton(AssaultMenu, true);
	DisplayMenu(AssaultMenu, client, 30);
	
	return Plugin_Handled;
}
public AssaultMenuHandler(Handle:AssaultMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: 
			{
				FakeClientCommandEx(client, "sm_ammo");
				if (!classCheck[client])
				{
					classCheck[client] = true;
				}
			}
			case 5: FakeClientCommandEx(client, "sm_diff");
			case 6: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
public Action:EngineerPanel(client) 
{
	new Handle:EngineerMenu = CreateMenu(EngineerMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleEngineer", client);
	SetMenuTitle(EngineerMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(EngineerMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(EngineerMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(EngineerMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(EngineerMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Jetpack", client);
	AddMenuItem(EngineerMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(EngineerMenu, "5", Value);

	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(EngineerMenu, "6", Value);

	SetMenuExitButton(EngineerMenu, true);
	DisplayMenu(EngineerMenu, client, 30);
	
	return Plugin_Handled;
}
public EngineerMenuHandler(Handle:EngineerMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: 
			{
				FakeClientCommandEx(client, "sm_jetpack");
				if (!classCheck[client])
				{
					classCheck[client] = true;
				}
			}
			case 5: FakeClientCommandEx(client, "sm_diff");
			case 6: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
/*
public Action:ReconPanel(client) 
{
	new Handle:ReconMenu = CreateMenu(ReconMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleRecon", client);
	SetMenuTitle(ReconMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(ReconMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(ReconMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(ReconMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(ReconMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(ReconMenu, "4", Value);

	SetMenuExitButton(ReconMenu, true);
	DisplayMenu(ReconMenu, client, 30);
	
	return Plugin_Handled;
}
public ReconMenuHandler(Handle:ReconMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_maps");
			case 3: FakeClientCommandEx(client, "sm_rankmenu");
			case 4: FakeClientCommandEx(client, "sm_diff");
		}
	}
}
*/
public Action:SupportPanel(client) 
{
	new Handle:SupportMenu = CreateMenu(SupportMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleSupport", client);
	SetMenuTitle(SupportMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(SupportMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(SupportMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(SupportMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(SupportMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Minigun", client);
	AddMenuItem(SupportMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(SupportMenu, "5", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(SupportMenu, "6", Value);
	
	SetMenuExitButton(SupportMenu, true);
	DisplayMenu(SupportMenu, client, 30);
	
	return Plugin_Handled;
}
public SupportMenuHandler(Handle:SupportMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: 
			{
				FakeClientCommandEx(client, "sm_mg");
				if (!classCheck[client])
				{
					classCheck[client] = true;
					SetArmor(client);
					//if (iLightIndex[client] != 0) DeleteLight(client);
					//SupLight(client);
				}
			}
			case 5: FakeClientCommandEx(client, "sm_diff");
			case 6: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
public Action:ScientistPanel(client) 
{
	new Handle:ScientistMenu = CreateMenu(ScientistMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitleScientist", client);
	SetMenuTitle(ScientistMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(ScientistMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(ScientistMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(ScientistMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(ScientistMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Skills", client);
	AddMenuItem(ScientistMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(ScientistMenu, "5", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(ScientistMenu, "6", Value);
	
	SetMenuExitButton(ScientistMenu, true);
	DisplayMenu(ScientistMenu, client, 30);
	
	return Plugin_Handled;
}
public ScientistMenuHandler(Handle:ScientistMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: ScientistSkills(client, 0);
			case 5: FakeClientCommandEx(client, "sm_diff");
			case 6: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
public Action:PlayerPanel(client) 
{
	new Handle:PlayerMenu = CreateMenu(PlayerMenuHandler);
	decl String:ClTitle[32];
	Format(ClTitle, sizeof(ClTitle), "%T\n \n", "ClassTitle", client);
	SetMenuTitle(PlayerMenu, ClTitle);
	new String:Value[38];
	
	Format(Value, sizeof(Value), "%T", "Character_select", client);
	AddMenuItem(PlayerMenu, "0", Value);
	
	Format(Value, sizeof(Value), "%T", "Votekick", client);
	AddMenuItem(PlayerMenu, "1", Value);
	
	Format(Value, sizeof(Value), "%T", "Votemute", client);
	AddMenuItem(PlayerMenu, "2", Value);
	
	Format(Value, sizeof(Value), "%T", "Campaign", client);
	AddMenuItem(PlayerMenu, "3", Value);
	
	Format(Value, sizeof(Value), "%T", "Difficulty", client);
	AddMenuItem(PlayerMenu, "4", Value);
	
	Format(Value, sizeof(Value), "%T", "Stats", client);
	AddMenuItem(PlayerMenu, "5", Value);
	
	SetMenuExitButton(PlayerMenu, true);
	DisplayMenu(PlayerMenu, client, 30);
	
	return Plugin_Handled;
}
public PlayerMenuHandler(Handle:PlayerMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: FakeClientCommandEx(client, "sm_csp");
			case 1: FakeClientCommandEx(client, "sm_vk");
			case 2: FakeClientCommandEx(client, "sm_votesilence");
			case 3: FakeClientCommandEx(client, "sm_maps");
			case 4: FakeClientCommandEx(client, "sm_diff");
			case 5: FakeClientCommandEx(client, "sm_rankmenu");
		}
	}
}
public Action:AmmoSpawnAnnonce(Handle:timer, any:client)
{
	if(IsClientInGame(client)) PrintToChat(client, "%t", "AmmoAnnonce");
}
public Action:JetPackSpawnAnnonce(Handle:timer, any:client)
{
	if(IsClientInGame(client)) PrintToChat(client, "%t", "JetPackAnnonce");
}
public Action:m_upgradeClass(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(MedicHandle[client])
		{
			if (iLightIndex[client] != 0)DeleteLight(client);
			MedLight(client);
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 134270976, 4);
			MedicCheck[client] = true;
			if (FirstKitHandle[client][0] && IsPlayerAlive(client) && GetPlayerWeaponSlot(client, 3) < 1) EquipPlayerWeapon(client, GivePlayerItem(client, "weapon_first_aid_kit"));
			Call_StartForward(uClientTakeMedic);
			Call_PushCell(client);
			Call_Finish();
			return;
		}
		else if(AssaultHandle[client])
		{
			if (iLightIndex[client] != 0)DeleteLight(client);
			AssLight(client);
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 537395200, 4);
			AssaultCheck[client] = true;
			Call_StartForward(uClientTakeAssault);
			Call_PushCell(client);
			Call_Finish();
			return;
		}
		else if(EngineerHandle[client])
		{
			if (iLightIndex[client] != 0)DeleteLight(client);
			EngLight(client);
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 9830402, 4);
			EngineerCheck[client] = true;
			Call_StartForward(uClientTakeEngineer);
			Call_PushCell(client);
			Call_Finish();
			return;
		}
		//else if(ReconHandle[client]) SetEntProp(client, Prop_Send, "m_upgradeBitVec", 117442816, 4);
		else if(SupportHandle[client])
		{
			if (iLightIndex[client] != 0)DeleteLight(client);
			SupLight(client);
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 128, 4);
			SupportCheck[client] = true;
			Call_StartForward(uClientTakeSupport);
			Call_PushCell(client);
			Call_Finish();
			return;
		}
		else if(ScientistHandle[client])
		{
			if (iLightIndex[client] != 0)DeleteLight(client);
			SciLight(client);
			SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
			ScientistCheck[client] = true;
			//Call_StartForward(uClientTakeScientist);
			//Call_PushCell(client);
			//Call_Finish();
			return;
		}
	}
}
public Action:round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	b_round_end = false;
	for(new i=1; i<=MaxClients; i++)
	{
		if(h_SpectatorAnnonce[i] != INVALID_HANDLE)
		{
			CloseHandle(h_SpectatorAnnonce[i]);
			h_SpectatorAnnonce[i] = INVALID_HANDLE;
		}
		if (IsClientInGame(i) && GetClientTeam(i) == 1) h_SpectatorAnnonce[i] = CreateTimer(10.0, t_SpecJoinAnnonce, i, TIMER_REPEAT);
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			classCheck[i] = false;
			CreateTimer(5.0, BuildSuperMeatServerPanel, i);
			
			if (MedicHandle[i])
			{
				if (!MedicCheck[i]) MedLight(i);
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 134270976, 4);
				MedicCheck[i] = true;
				if (FirstKitHandle[i][0] && IsPlayerAlive(i) && GetPlayerWeaponSlot(i, 3) < 1) EquipPlayerWeapon(i, GivePlayerItem(i, "weapon_first_aid_kit"));
				Call_StartForward(uClientTakeMedic);
				Call_PushCell(i);
				Call_Finish();
				continue;
			}
			else if (AssaultHandle[i])
			{
				if (!AssaultCheck[i]) AssLight(i);
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 537395200, 4);
				AssaultCheck[i] = true;
				Call_StartForward(uClientTakeAssault);
				Call_PushCell(i);
				Call_Finish();
				continue;
			}
			else if (EngineerHandle[i])
			{
				if (!EngineerCheck[i]) EngLight(i);
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 9830402, 4);
				EngineerCheck[i] = true;
				Call_StartForward(uClientTakeEngineer);
				Call_PushCell(i);
				Call_Finish();
				continue;
			}
			/*else if	(ReconHandle[i])
			{
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 117442816, 4);
				ReconCheck[i] = true;
				Call_StartForward(uClientTakeRecon);
				Call_PushCell(i);
				Call_Finish();
				continue;
			}*/
			else if (SupportHandle[i])
			{
				if (!SupportCheck[i]) SupLight(i);
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 128, 4);
				SupportCheck[i] = true;
				SetArmor(i);
				Call_StartForward(uClientTakeSupport);
				Call_PushCell(i);
				Call_Finish();
				continue;
			}
			else if(ScientistHandle[i])
			{
				if (!ScientistCheck[i]) SciLight(i);
				SetEntProp(i, Prop_Send, "m_upgradeBitVec", 0, 4);
				ScientistCheck[i] = true;
				//Call_StartForward(uClientTakeScientist);
				//Call_PushCell(i);
				//Call_Finish();
				continue;
			}
		}
	}
	for(new i = 0; i < MAX_SPAWNS; i++)
	{
		g_iSpawns[i][0] = 0;
		g_iSpawns[i][1] = 0;
	}
}
/*Give_HuntingRifle(client)
{
	if (!IsClientInGame(client)) return;
	decl item;
	if ((item = GetPlayerWeaponSlot(client, 0)) > 0)
	{
		decl String:weapon[25];
		GetEdictClassname(item, weapon, sizeof(weapon));
		if (!StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SDKHooks_DropWeapon(client, item, NULL_VECTOR, NULL_VECTOR);
			CreateTimer(0.5, Give_Hunting_Rifle, client);
		}
	}
	else CreateTimer(0.1, Give_Hunting_Rifle, client);
}
public Action:Give_Hunting_Rifle(Handle:timer, any:client)
{
	BypassAndExecuteCommand(client, "give", "hunting_rifle");
	BypassAndExecuteCommand(client, "give", "ammo");
}
BypassAndExecuteCommand(client, String: strCommand[], String: strParam1[])
{
	new flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}*/
GetClassList(mode, client)
{
	new String:Message[256];
	new String:TempMessage[256];
	new String:sComma[] = "\x01, \x05";
	switch (mode)
	{
		case 1:
		{
			if (!i_CountMedic) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && MedicCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountMedic > 1) 
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
				}
			}
			decl String:medics[32];
			Format(medics, sizeof(medics), "%T", "medics", client);
			Message = medics;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
		case 2:
		{
			if (!i_CountAssault) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && AssaultCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountAssault > 1)
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
				}
			}
			decl String:assaults[32];
			Format(assaults, sizeof(assaults), "%T", "assaults", client);
			Message = assaults;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
		case 3:
		{
			if (!i_CountEngineer) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && EngineerCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountEngineer > 1)
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
				}
			}
			decl String:engineers[32];
			Format(engineers, sizeof(engineers), "%T", "engineers", client);
			Message = engineers;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
		/*case 4:
		{
			if (!i_CountRecon) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && ReconCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					{
						if (i_CountRecon > 1) 
						{
							StrCat(TempMessage, sizeof(TempMessage), sName);
							StrCat(TempMessage, sizeof(TempMessage), sComma);
						}
						else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
					}
				}
			}
			decl String:recons[32];
			Format(recons, sizeof(recons), "%T", "recons", client);
			Message = recons;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}*/
		case 4:
		{
			if (!i_CountSupport) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && SupportCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountSupport > 1)
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
				}
			}
			decl String:supports[32];
			Format(supports, sizeof(supports), "%T", "supports", client);
			Message = supports;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
		case 5:
		{
			if (!i_CountScientist) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && ScientistCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountScientist > 1)
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
				}
			}
			decl String:scientist[32];
			Format(scientist, sizeof(scientist), "%T", "scientist", client);
			Message = scientist;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
		case 6:
		{
			if (!i_CountNothing) return;
			for(new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && !classCheck[i])
				{
					decl String:sName[24];
					GetClientName(i, sName, sizeof(sName));
					if (i_CountNothing > 1)
					{
						StrCat(TempMessage, sizeof(TempMessage), sName);
						StrCat(TempMessage, sizeof(TempMessage), sComma);
					}
					else Format(TempMessage, sizeof(TempMessage), "\x05%N", i);
					
					/*new Float:not_location[3];
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", not_location);
					new iEnt = CreateEntityByName("light_dynamic");
					DispatchKeyValue(iEnt, "_light", "255 255 255");
					DispatchKeyValue(iEnt, "brightness", "0");
					DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
					DispatchKeyValueFloat(iEnt, "distance", 100.0);
					DispatchKeyValue(iEnt, "style", "9");
					DispatchSpawn(iEnt);
					TeleportEntity(iEnt, not_location, NULL_VECTOR, NULL_VECTOR);
					SetVariantString("!activator");
					AcceptEntityInput(iEnt, "SetParent", i, iEnt);
					SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
					AcceptEntityInput(iEnt, "AddOutput");
					AcceptEntityInput(iEnt, "FireUser1");*/
				}
			}
			decl String:noclasses[40];
			Format(noclasses, sizeof(noclasses), "%T", "noclasses", client);
			Message = noclasses;
			StrCat(String:Message, sizeof(Message), TempMessage);
			PrintToChat(client, Message);
		}
	}
}
public ConVarChange_GameDifficulty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		decl String:s_GameDifficulty[16];
		GetConVarString(h_Difficulty, s_GameDifficulty, sizeof(s_GameDifficulty));
		if (strcmp(s_GameDifficulty, "hard", false) == 0) b_ExpertDifficulty = false;
		else if (strcmp(s_GameDifficulty, "impossible", false) == 0) b_ExpertDifficulty = true;
	}
}
MedLight(client)
{
	new Float:med_location[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", med_location);
	
	new iColorLight[2];
	iColorLight[0] = GetRandomInt(150, 255);
	iColorLight[1] = GetRandomInt(0, 60);
	new String:sColorLight[12];
	Format(sColorLight, sizeof(sColorLight), "%d %d %d", iColorLight[0], iColorLight[1], iColorLight[1]); 
	
	new iEnt = CreateEntityByName("light_dynamic");
	iLightIndex[client] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", sColorLight);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "0");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, med_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
AssLight(client)
{
	new Float:ass_location[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ass_location);
	
	new iColorLight[2];
	iColorLight[0] = GetRandomInt(0, 60);
	iColorLight[1] = GetRandomInt(150, 255);
	new String:sColorLight[12];
	Format(sColorLight, sizeof(sColorLight), "%d %d %d", iColorLight[0], iColorLight[1], iColorLight[0]); 
	
	new iEnt = CreateEntityByName("light_dynamic");
	iLightIndex[client] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", sColorLight);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "0");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, ass_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
EngLight(client)
{
	new Float:eng_location[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", eng_location);
	
	new iColorLight[2];
	iColorLight[0] = GetRandomInt(0, 60);
	iColorLight[1] = GetRandomInt(150, 255);
	new String:sColorLight[12];
	Format(sColorLight, sizeof(sColorLight), "%d %d %d", iColorLight[0], iColorLight[0], iColorLight[1]); 
	
	new iEnt = CreateEntityByName("light_dynamic");
	iLightIndex[client] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", sColorLight);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "0");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, eng_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
SupLight(client)
{
	new Float:sup_location[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", sup_location);
	
	new iColorLight[2];
	iColorLight[0] = GetRandomInt(150, 255);
	iColorLight[1] = GetRandomInt(0, 60);
	new String:sColorLight[12];
	Format(sColorLight, sizeof(sColorLight), "%d %d %d", iColorLight[0], iColorLight[0], iColorLight[1]); 
	
	new iEnt = CreateEntityByName("light_dynamic");
	iLightIndex[client] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", sColorLight);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "0");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, sup_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
SciLight(client)
{
	new Float:sup_location[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", sup_location);
	
	new String:sColorLight[12];
	Format(sColorLight, sizeof(sColorLight), "%d %d %d", 255, 255, 255); 
	
	new iEnt = CreateEntityByName("light_dynamic");
	iLightIndex[client] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", sColorLight);
	DispatchKeyValue(iEnt, "brightness", "0");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(iEnt, "distance", 100.0);
	DispatchKeyValue(iEnt, "style", "0");
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, sup_location, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iEnt, "SetParent", client, iEnt);
	SetVariantString("OnUser1 !self:TurnOn::0.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}
DeleteLight(client)
{
	new entity = iLightIndex[client];
	iLightIndex[client] = 0;
	if(IsValidEntRef(entity))AcceptEntityInput(entity, "Kill");
}
bool:IsValidEntRef(entity)
{
	if(entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE) return true;
	return false;
}
public Action:ClassCheckEnable(client, args)
{
	if (IsPlayerAlive(client) && !classCheck[client])
	{
		char args_Name[32];
		GetCmdArg(0, args_Name, sizeof(args_Name));
		if (strcmp(args_Name,"sm_ammo",false) == 0 && AssaultCheck[client])
		{
			classCheck[client] = true;
		}
		else if (strcmp(args_Name,"sm_jetpack",false) == 0 && EngineerCheck[client])
		{
			classCheck[client] = true;
		}
		else if (strcmp(args_Name,"sm_mg",false) == 0 && SupportCheck[client])
		{
			classCheck[client] = true;
			SetArmor(client);
		}
	}
}
public Teampanel(client)
{
	if(GetClientTeam(client) != 3)
	{
		new Handle:TeamPanel = CreatePanel();
		new String:Text[64];
		
		Format(Text, sizeof(Text), "%T \n \n", "Displayer", client);
		SetPanelTitle(TeamPanel, Text);
		new String: name[64];
		new health;
		new buffer_health;
		new String: addoutput[64];
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (!IsPlayerAlive(i))
					{
						GetClientName(i, name, sizeof(name));
						Format(addoutput, sizeof(addoutput), " [dead] %s", name);
						DrawPanelText(TeamPanel, addoutput);
					}
					else if (IsPlayerAlive(i))
					{
						if (!IsPlayerIncapped(i))
						{
							new ReviveCount = GetEntProp(i, Prop_Send, "m_currentReviveCount");
							GetClientName(i, name, sizeof(name));
							health = GetClientHealth(i);
							buffer_health = L4D_GetPlayerTempHealth(i);
							
							if (ReviveCount == 2)
							{
								if (!buffer_health) Format(addoutput, sizeof(addoutput), " ‼[%d %T, %T] %s", health, "hp", client, "bw", client, name);
								else Format(addoutput, sizeof(addoutput), " ‼[%d %T, %d %T, %T] %s", health, "hp", client, buffer_health, "temp", client, "bw", client, name);
							}
							else
							{
								if (!buffer_health)
								{
									if (health == 1) Format(addoutput, sizeof(addoutput), " ![%d %T] %s", health, "hp", client, name);
									else Format(addoutput, sizeof(addoutput), " [%d %T] %s", health, "hp", client, name);
								}
								else 
								{
									if (health == 1) Format(addoutput, sizeof(addoutput), " ![%d %T, %d %T] %s", health, "hp", client, buffer_health, "temp", client, name);
									else Format(addoutput, sizeof(addoutput), " [%d %T, %d %T] %s", health, "hp", client, buffer_health, "temp", client, name);
								}
							}
							DrawPanelText(TeamPanel, addoutput);
						}
						else if (IsPlayerIncapped(i))
						{
							GetClientName(i, name, sizeof(name));
							health = GetClientHealth(i) + L4D_GetPlayerTempHealth(i);
							Format(addoutput, sizeof(addoutput), " ![%d %T, %T] %s", health, "hp", client, "incapped", client, name);
							DrawPanelText(TeamPanel, addoutput);
						}
					}
				}
			}
		}
		Format(addoutput, sizeof(addoutput), " \n ! - %T", "player_help", client);
		DrawPanelText(TeamPanel, addoutput);
		Format(addoutput, sizeof(addoutput), " ‼ - %T", "player_bw", client);
		DrawPanelText(TeamPanel, addoutput);
		
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, 1);
		CloseHandle(TeamPanel);
	}
}
public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		dp[param1] = false;
	}
}
stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
public Action:Reset(Handle:Timer, any:client)
{
	if (se[client])
	{
		se[client] = false;
	}
}
public Action:PAe(Handle:Timer, any:client)
{
	if (IsClientInGame(client)) Teampanel(client);
	return Plugin_Stop;
}
StartTrigger(item)
{
	new iSpawnIndex = -1;
	for( new i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}
	if( iSpawnIndex == -1 ) return;
	
	new Float:kit_location[3];
	GetEntPropVector(item, Prop_Send, "m_vecOrigin", kit_location);
	
	new trigger_health = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger_health, "spawnflags", "1");
	DispatchKeyValue(trigger_health, "wait", "0");
	DispatchSpawn(trigger_health);
	ActivateEntity(trigger_health);
	TeleportEntity(trigger_health, kit_location, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(trigger_health, "models/error.mdl");
	SetEntPropVector(trigger_health, Prop_Send, "m_vecMins", Float: {-50.0, -50.0, -30.0});
	SetEntPropVector(trigger_health, Prop_Send, "m_vecMaxs", Float: {50.0, 50.0, 30.0});
	SetEntProp(trigger_health, Prop_Send, "m_nSolidType", 2);
	//AcceptEntityInput(trigger_health, "SetParent", item, trigger_health);
	HookSingleEntityOutput(trigger_health, "OnStartTouch", OnStartTouch);
	HookSingleEntityOutput(trigger_health, "OnEndTouch", OnEndTouch);
	
	SetParentEx(item, trigger_health);
	
	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(item);
	g_iSpawns[iSpawnIndex][1] = EntIndexToEntRef(trigger_health);
}
stock SetParentEx(iParent, iChild)
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);
}
stock SetParent(iParent, iChild, const String:szAttachment[] = "", Float:vOffsets[3] = {0.0,0.0,0.0})
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);

	if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs.
	{
		SetVariantString(szAttachment); // "head"

		if (!AreVectorsEqual(vOffsets, Float:{0.0,0.0,0.0})) // NULL_VECTOR
		{
			decl Float:vPos[3];
			GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", vPos);
			AddVectors(vPos, vOffsets, vPos);
			TeleportEntity(iChild, vPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild);
		}
		else
		{
			AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild);
		}
	}
}
stock bool:AreVectorsEqual(Float:vVec1[3], Float:vVec2[3])
{
	return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]);
}
public OnStartTouch(const String:output[], ent, client, Float:delay)
{
	//PrintToChat(client, "Start Touch!");
	IsClientTouch[client][ent] = true;
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		new Hp = GetEntProp(client, Prop_Data, "m_iHealth");
		new tempHp = L4D_GetPlayerTempHealth(client);
		new totalHp = Hp + tempHp;
		
		if (Hp > 1)
		{
			if (totalHp < 90)
			{
				//PrintToChatAll("totalHp = (%d)", totalHp);
				if(!EmitSoundPlay[client])
				{
					EmitSoundToClient(client, "player/survivor/heal/bandaging_1.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundPlay[client] = true;
					CreateTimer(8.0, EmitSoundReset, client);
				}
				HP_StopTimer(client);
				HP_Timer_OnWeaponCanUse[client] = CreateTimer(1.0, HP_Timer_PermRegen, client, TIMER_REPEAT);
			}
		}
		else if (Hp <= 1)
		{
			if (totalHp < 90)
			{
				if(!EmitSoundPlay[client])
				{
					EmitSoundToClient(client, "player/survivor/heal/bandaging_1.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 0.7, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
					EmitSoundPlay[client] = true;
					CreateTimer(8.0, EmitSoundReset, client);
				}
				HP_StopTimer_3(client);
				HP_Timer_OnWeaponCanUse2[client] = CreateTimer(1.0, HP_Timer_BuffRegen, client, TIMER_REPEAT);
			}
			else if (totalHp >= 90 && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) != 1 && GetEntProp(client, Prop_Send, "m_currentReviveCount") != 2)
			{
				new ReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
				CheatCommand(client, "give", "health", "");
				SetEntityHealth(client, 15);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 85.0);
				SetEntProp(client, Prop_Send, "m_currentReviveCount", ReviveCount);
			}
		}
	}
}
public OnEndTouch(const String:output[], ent, client, Float:delay)
{
	//PrintToChat(client, "End Touch!");
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		IsClientTouch[client][ent] = false;
		HP_StopTimer(client);
		HP_StopTimer_3(client);
	}
}
public ClientDropKit(client, args) 
{
	FirstKitHandle[client][0] = 0;
	FirstKitHandle[client][1] = -1;
	HP_StopTimer(client);
	HP_StopTimer_3(client);
}
public Action:EmitSoundReset(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	EmitSoundPlay[client] = false;
	return Plugin_Continue;
}
public Action:finale_vehicle_leaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			if (AssaultCheck[i] || AssaultHandle[i])
			{
				Call_StartForward(uClientDropAssault);
				Call_PushCell(i);
				Call_Finish();
				AssaultCheck[i] = false;
				AssaultHandle[i] = false;
			}
		}
	}
}
public Action:CreateTeleportField(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) && GetClientTeam(client) != 2) return;
	if(ScientistCheck[client])
	{
		if (!classCheck[client]) classCheck[client] = true;
		if (ScientistTPStart[client])
		{
			PrintToChat(client, "%t", "wait_tp_close");
			return;
		}
		if (ScientistStartPos[client][0] == 0.0 &&
		ScientistStartPos[client][1] == 0.0 && 
		ScientistStartPos[client][2] == 0.0)//нет координат
		{
			SpawnTPEnd(client);
			
			/*new Handle:pMenu = CreateMenu(ConfirmStartTP);
			decl String:ConfirmStartTPTitle[40];
			Format(ConfirmStartTPTitle, sizeof(ConfirmStartTPTitle), "%T\n \n", "ConfirmStartTPTitle", client);
			SetMenuTitle(pMenu, ConfirmStartTPTitle);
			AddMenuItem(pMenu, "0", "Yes");
			AddMenuItem(pMenu, "1", "No back");
			DisplayMenu(pMenu, client, 0);*/
		}
		else
		{
			new String:Value[38];
			new Handle:pMenu = CreateMenu(ConfirmRunTP);
			decl String:ConfirmRunTPTitle[40];
			Format(ConfirmRunTPTitle, sizeof(ConfirmRunTPTitle), "%T\n \n", "ConfirmRunTPTitle", client);
			SetMenuTitle(pMenu, ConfirmRunTPTitle);
			Format(Value, sizeof(Value), "%T", "OpenTP", client);
			AddMenuItem(pMenu, "0", Value);
			Format(Value, sizeof(Value), "%T", "SpawnNew", client);
			AddMenuItem(pMenu, "1", Value);
			Format(Value, sizeof(Value), "%T", "ButtBack", client);
			AddMenuItem(pMenu, "2", Value);
			DisplayMenu(pMenu, client, 0);
		}
	}
	else PrintToChat(client, "%t", "only_scientists");
}
/*public ConfirmStartTP(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) SpawnTPEnd(client);
	if (option == 1) ScientistPanel(client);
}*/
public ConfirmRunTP(Handle:menu, MenuAction:action, client, option)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
		return;
	}
	if (action != MenuAction_Select) return; 
	if (option == 0) SpawnTPStart(client);
	if (option == 1) SpawnTPEnd(client);
	if (option == 2) ScientistSkills(client, 0);
}
public SpawnTPEnd(client)
{
	if(iTPIndex[client][0] != 0 || ScientistStartPos[client][0] != 0.0) DeleteTP(client);
	GetClientAbsOrigin(client, ScientistStartPos[client]);
	
	new ent_smoke = CreateEntityByName("env_smokestack");
	iTPIndex[client][0] = EntIndexToEntRef(ent_smoke);
	DispatchKeyValue(ent_smoke, "BaseSpread", "50");
	DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
	DispatchKeyValue(ent_smoke, "Speed", "100");
	DispatchKeyValue(ent_smoke, "StartSize", "10");
	DispatchKeyValue(ent_smoke, "EndSize", "10");
	DispatchKeyValue(ent_smoke, "Rate", "50");
	DispatchKeyValue(ent_smoke, "JetLength", "50");
	DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
	DispatchKeyValue(ent_smoke, "twist", "100");
	DispatchKeyValue(ent_smoke, "rendercolor", "255 255 255");
	DispatchKeyValue(ent_smoke, "renderamt", "255");
	DispatchKeyValue(ent_smoke, "roll", "100");
	DispatchKeyValue(ent_smoke, "InitialState", "1");
	DispatchKeyValue(ent_smoke, "angles", "0 0 0");
	DispatchKeyValue(ent_smoke, "WindSpeed", "0");
	DispatchKeyValue(ent_smoke, "WindAngle", "0");
	TeleportEntity(ent_smoke, ScientistStartPos[client], NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent_smoke);
	AcceptEntityInput(ent_smoke, "TurnOn");
	
	EmitSoundToAll(SOUND_TP3, ent_smoke);
	
	new iEnt = CreateEntityByName("light_dynamic");
	iTPIndex[client][1] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", "255 255 255 255");
	DispatchKeyValue(iEnt, "brightness", "1");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
	DispatchKeyValueFloat(iEnt, "distance", 255.0);
	DispatchKeyValue(iEnt, "style", "0");
	new Float:VecOrg[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", VecOrg);
	
	VecOrg[2] += 50.0;
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "TurnOn");
	TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
}
SpawnTPStart(client)
{
	ScientistTPStart[client] = true;
	new Float:VecOrg[3];
	GetClientAbsOrigin(client, VecOrg);
	GetClientAbsOrigin(client, ScientistEndPos[client]);
	
	new ent_smoke = CreateEntityByName("env_smokestack");
	iTPIndex[client][2] = EntIndexToEntRef(ent_smoke);
	DispatchKeyValue(ent_smoke, "BaseSpread", "50");
	DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
	DispatchKeyValue(ent_smoke, "Speed", "100");
	DispatchKeyValue(ent_smoke, "StartSize", "10");
	DispatchKeyValue(ent_smoke, "EndSize", "10");
	DispatchKeyValue(ent_smoke, "Rate", "50");
	DispatchKeyValue(ent_smoke, "JetLength", "350");
	DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
	DispatchKeyValue(ent_smoke, "twist", "100");
	DispatchKeyValue(ent_smoke, "rendercolor", "255 255 255");
	DispatchKeyValue(ent_smoke, "renderamt", "255");
	DispatchKeyValue(ent_smoke, "roll", "100");
	DispatchKeyValue(ent_smoke, "InitialState", "1");
	DispatchKeyValue(ent_smoke, "angles", "0 0 0");
	DispatchKeyValue(ent_smoke, "WindSpeed", "0");
	DispatchKeyValue(ent_smoke, "WindAngle", "0");
	TeleportEntity(ent_smoke, ScientistEndPos[client], NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(ent_smoke);
	AcceptEntityInput(ent_smoke, "TurnOn");
	
	EmitSoundToAll(SOUND_TP3, ent_smoke);
	
	new iEnt = CreateEntityByName("light_dynamic");
	iTPIndex[client][3] = EntIndexToEntRef(iEnt);
	DispatchKeyValue(iEnt, "_light", "255 255 255 255");
	DispatchKeyValue(iEnt, "brightness", "1");
	DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
	DispatchKeyValueFloat(iEnt, "distance", 255.0);
	DispatchKeyValue(iEnt, "style", "0");
	VecOrg[2] += 50.0;
	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "TurnOn");
	TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
	
	CreateTimer(3.0, SpawnPort, client);
}
public Action:SpawnPort(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2) return Plugin_Stop;
	
	new trigger_multiple = CreateEntityByName("trigger_multiple");
	iTPIndex[client][4] = EntIndexToEntRef(trigger_multiple);
	DispatchKeyValue(trigger_multiple, "spawnflags", "1");
	DispatchKeyValue(trigger_multiple, "wait", "0");
	DispatchSpawn(trigger_multiple);
	ActivateEntity(trigger_multiple);
	TeleportEntity(trigger_multiple, ScientistEndPos[client], NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(trigger_multiple, "models/error.mdl");
	SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMins", Float: {-30.0, -30.0, 0.0});
	SetEntPropVector(trigger_multiple, Prop_Send, "m_vecMaxs", Float: {30.0, 30.0, 30.0});
	SetEntProp(trigger_multiple, Prop_Send, "m_nSolidType", 2);
	HookSingleEntityOutput(trigger_multiple, "OnStartTouch", OnStartTouch2);
	
	CreateTimer(20.0, DeleteTPtimer, client);
	return Plugin_Stop;
}
public OnStartTouch2(const String:output[], ent, client, Float:delay)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(iTPIndex[i][4] == EntIndexToEntRef(ent) && IsValidEntRef(iTPIndex[i][4]) && ScientistStartPos[i][0] != 0.0)
			{
				if(!ScientistCheck[client] && !(GetEntityFlags(client) & FL_DUCKING)) return;
			
				new Float:speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
				if (speed != 0.7) BasicSpeed[client] = speed;
				if (speed == 1.21 || speed ==  1.1) BasicSpeed[client] = speed - 0.21;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.7);
				EmitSoundToAll(SOUND_TP, client);
				
				new clients[2];
				clients[0] = client;
				new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
				BfWriteShort(message, 255);
				BfWriteShort(message, 255);
				BfWriteShort(message, (0x0002));
				BfWriteByte(message, 255);
				BfWriteByte(message, 255);
				BfWriteByte(message, 255);
				BfWriteByte(message, 128);
				EndMessage();
				
				CreateTimer(1.0, Point_Hurt, client, TIMER_REPEAT);
				switch (GetEntProp(client, Prop_Send, "m_survivorCharacter"))
				{
					case 0: switch(GetRandomInt(0,4))
					{
						case 0: EmitSoundToAll(SOUND_BILL01, client);
						case 1: EmitSoundToAll(SOUND_BILL02, client);
						case 2: EmitSoundToAll(SOUND_BILL03, client);
						case 3: EmitSoundToAll(SOUND_BILL04, client);
						case 4: EmitSoundToAll(SOUND_BILL05, client);
					}
					case 1: switch(GetRandomInt(0,3))
					{
						case 0: EmitSoundToAll(SOUND_ZOEY01, client);
						case 1: EmitSoundToAll(SOUND_ZOEY02, client);
						case 2: EmitSoundToAll(SOUND_ZOEY03, client);
						case 3: EmitSoundToAll(SOUND_ZOEY04, client);
					}
					case 2: switch(GetRandomInt(0,3))
					{
						case 0: EmitSoundToAll(SOUND_FRANCIS01, client);
						case 1: EmitSoundToAll(SOUND_FRANCIS02, client);
						case 2: EmitSoundToAll(SOUND_FRANCIS03, client);
						case 3: EmitSoundToAll(SOUND_FRANCIS04, client);
					}
					case 3: switch(GetRandomInt(0,3))
					{
						case 0: EmitSoundToAll(SOUND_LOUIS01, client);
						case 1: EmitSoundToAll(SOUND_LOUIS02, client);
						case 2: EmitSoundToAll(SOUND_LOUIS03, client);
						case 3: EmitSoundToAll(SOUND_LOUIS04, client);			
					}
				}
				TeleportEntity(client, ScientistStartPos[i], NULL_VECTOR, NULL_VECTOR);
				HealthPenalty(client);
			}
		}
	}
	return;
}
public Action:DeleteTPtimer(Handle:timer, any:client)
{
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	DeleteTP(client);
}
DeleteTP(client)
{
	new entity1 = iTPIndex[client][0];
	new entity2 = iTPIndex[client][1];
	new entity3 = iTPIndex[client][2];
	new entity4 = iTPIndex[client][3];
	new entity5 = iTPIndex[client][4];
	
	iTPIndex[client][0] = 0;
	iTPIndex[client][1] = 0;
	iTPIndex[client][2] = 0;
	iTPIndex[client][3] = 0;
	iTPIndex[client][4] = 0;
	
	if(IsValidEntRef(entity1))AcceptEntityInput(entity1, "TurnOff");
	if(IsValidEntRef(entity2))AcceptEntityInput(entity2, "TurnOff");
	if(IsValidEntRef(entity3))AcceptEntityInput(entity3, "TurnOff");
	if(IsValidEntRef(entity4))AcceptEntityInput(entity4, "TurnOff");
	if(IsValidEntRef(entity5))AcceptEntityInput(entity5, "Kill");
	
	ScientistStartPos[client][0] = 0.0;
	ScientistStartPos[client][1] = 0.0;
	ScientistStartPos[client][2] = 0.0;
	
	ScientistTPStart[client] = false;
}
public Action:Point_Hurt(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client)) return Plugin_Stop;
	static x = 0; 
	if (++x < 4) 
	{
		new clients[2];
		clients[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		BfWriteByte(message, 128);
		EndMessage();
		switch (GetEntProp(client, Prop_Send, "m_survivorCharacter"))
		{
			case 0: switch(GetRandomInt(0,4))
			{
				case 0: EmitSoundToAll(SOUND_BILL01, client);
				case 1: EmitSoundToAll(SOUND_BILL02, client);
				case 2: EmitSoundToAll(SOUND_BILL03, client);
				case 3: EmitSoundToAll(SOUND_BILL04, client);
				case 4: EmitSoundToAll(SOUND_BILL05, client);
			}
			case 1: switch(GetRandomInt(0,3))
			{
				case 0: EmitSoundToAll(SOUND_ZOEY01, client);
				case 1: EmitSoundToAll(SOUND_ZOEY02, client);
				case 2: EmitSoundToAll(SOUND_ZOEY03, client);
				case 3: EmitSoundToAll(SOUND_ZOEY04, client);
			}
			case 2: switch(GetRandomInt(0,3))
			{
				case 0: EmitSoundToAll(SOUND_FRANCIS01, client);
				case 1: EmitSoundToAll(SOUND_FRANCIS02, client);
				case 2: EmitSoundToAll(SOUND_FRANCIS03, client);
				case 3: EmitSoundToAll(SOUND_FRANCIS04, client);
			}
			case 3: switch(GetRandomInt(0,3))
			{
				case 0: EmitSoundToAll(SOUND_LOUIS01, client);
				case 1: EmitSoundToAll(SOUND_LOUIS02, client);
				case 2: EmitSoundToAll(SOUND_LOUIS03, client);
				case 3: EmitSoundToAll(SOUND_LOUIS04, client);
			}
		}
		return Plugin_Continue;
	}
	x = 0;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", BasicSpeed[client]);
	return Plugin_Stop;
}
public Action:PillsSmoke(Handle:timer, any:client)
{
	if (client < 0 || !IsClientInGame(client) || IsFakeClient(client) || (GetClientTeam(client) != 2 && ScientistHealPos[client][0] == 0.0)) return Plugin_Stop;
	
	static x = 0;
	if (x == 0)
	{
		GetClientAbsOrigin(client, ScientistHealPos[client]);
		new Float:VecOrg[3];
		VecOrg[0] = ScientistHealPos[client][0];
		VecOrg[1] = ScientistHealPos[client][1];
		VecOrg[2] = ScientistHealPos[client][2] + 25.0;
		
		new ent_smoke = CreateEntityByName("env_smokestack");
		iPillsIndex[client] = ent_smoke;
		DispatchKeyValue(ent_smoke, "BaseSpread", "10");
		DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
		DispatchKeyValue(ent_smoke, "Speed", "100");
		DispatchKeyValue(ent_smoke, "StartSize", "10");
		DispatchKeyValue(ent_smoke, "EndSize", "10");
		DispatchKeyValue(ent_smoke, "Rate", "50");
		DispatchKeyValue(ent_smoke, "JetLength", "50");
		DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
		DispatchKeyValue(ent_smoke, "twist", "100");
		DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
		DispatchKeyValue(ent_smoke, "renderamt", "255");
		DispatchKeyValue(ent_smoke, "roll", "100");
		DispatchKeyValue(ent_smoke, "InitialState", "1");
		DispatchKeyValue(ent_smoke, "angles", "0 0 0");
		DispatchKeyValue(ent_smoke, "WindSpeed", "0");
		DispatchKeyValue(ent_smoke, "WindAngle", "0");
		TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent_smoke);
		AcceptEntityInput(ent_smoke, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
		AcceptEntityInput(ent_smoke, "AddOutput");
		AcceptEntityInput(ent_smoke, "FireUser1");
		
		new trigger_health = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_health, "spawnflags", "1");
		DispatchKeyValue(trigger_health, "wait", "0");
		DispatchSpawn(trigger_health);
		ActivateEntity(trigger_health);
		TeleportEntity(trigger_health, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_health, "models/error.mdl");
		SetEntPropVector(trigger_health, Prop_Send, "m_vecMins", Float: {-60.0, -60.0, 0.0});
		SetEntPropVector(trigger_health, Prop_Send, "m_vecMaxs", Float: {60.0, 60.0, 30.0});
		SetEntProp(trigger_health, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_health, "OnStartTouch", OnStartTouch);
		HookSingleEntityOutput(trigger_health, "OnEndTouch", OnEndTouch);
		HookSingleEntityOutput(trigger_health, "OnKilled", EntityOutput:OnKilled);
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:Kill::13.0:-1");
		AcceptEntityInput(trigger_health, "AddOutput");
		AcceptEntityInput(trigger_health, "FireUser1");
		
		new iEnt = CreateEntityByName("light_dynamic");
		iTPIndex[client][1] = EntIndexToEntRef(iEnt);
		DispatchKeyValue(iEnt, "_light", "255 0 0 255");
		DispatchKeyValue(iEnt, "brightness", "1");
		DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
		DispatchKeyValueFloat(iEnt, "distance", 255.0);
		DispatchKeyValue(iEnt, "style", "0");
		TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::13.0:-1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
		
		EmitSoundToAll(SOUND_TP3, ent_smoke);
	}
	if (++x < 6)
	{
		switch (x)
		{
			case 1:
			{
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "20");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
				DispatchKeyValue(ent_smoke, "Speed", "100");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "10");
				DispatchKeyValue(ent_smoke, "Rate", "50");
				DispatchKeyValue(ent_smoke, "JetLength", "50");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "100");
				DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "100");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "0");
				DispatchKeyValue(ent_smoke, "WindAngle", "0");
				TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");
			}
			case 2:
			{
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "30");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
				DispatchKeyValue(ent_smoke, "Speed", "100");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "10");
				DispatchKeyValue(ent_smoke, "Rate", "50");
				DispatchKeyValue(ent_smoke, "JetLength", "50");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "100");
				DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "100");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "0");
				DispatchKeyValue(ent_smoke, "WindAngle", "0");
				TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");
			}
			case 3:
			{
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "40");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
				DispatchKeyValue(ent_smoke, "Speed", "100");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "10");
				DispatchKeyValue(ent_smoke, "Rate", "50");
				DispatchKeyValue(ent_smoke, "JetLength", "50");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "100");
				DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "100");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "0");
				DispatchKeyValue(ent_smoke, "WindAngle", "0");
				TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");
			}
			case 4:
			{
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "50");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
				DispatchKeyValue(ent_smoke, "Speed", "100");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "10");
				DispatchKeyValue(ent_smoke, "Rate", "50");
				DispatchKeyValue(ent_smoke, "JetLength", "50");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "100");
				DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "100");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "0");
				DispatchKeyValue(ent_smoke, "WindAngle", "0");
				TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");
			}
			case 5:
			{
				new ent_smoke = CreateEntityByName("env_smokestack");
				DispatchKeyValue(ent_smoke, "BaseSpread", "60");
				DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
				DispatchKeyValue(ent_smoke, "Speed", "100");
				DispatchKeyValue(ent_smoke, "StartSize", "10");
				DispatchKeyValue(ent_smoke, "EndSize", "10");
				DispatchKeyValue(ent_smoke, "Rate", "50");
				DispatchKeyValue(ent_smoke, "JetLength", "50");
				DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
				DispatchKeyValue(ent_smoke, "twist", "100");
				DispatchKeyValue(ent_smoke, "rendercolor", "255 0 0");
				DispatchKeyValue(ent_smoke, "renderamt", "255");
				DispatchKeyValue(ent_smoke, "roll", "100");
				DispatchKeyValue(ent_smoke, "InitialState", "1");
				DispatchKeyValue(ent_smoke, "angles", "0 0 0");
				DispatchKeyValue(ent_smoke, "WindSpeed", "0");
				DispatchKeyValue(ent_smoke, "WindAngle", "0");
				TeleportEntity(ent_smoke, ScientistHealPos[client], NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(ent_smoke);
				AcceptEntityInput(ent_smoke, "TurnOn");
				SetVariantString("!activator");
				SetVariantString("OnUser1 !self:TurnOff::10.0:-1");
				AcceptEntityInput(ent_smoke, "AddOutput");
				AcceptEntityInput(ent_smoke, "FireUser1");
			}
		}
		return Plugin_Continue;
	}
	x = 0;
	return Plugin_Stop;
}
public Action:PillsUseUnLock(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !ScientistPillsLock[client]) return Plugin_Stop;
	ScientistPillsLock[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public Action:GravityUseUnLock(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !GravityCheck[client]) return Plugin_Stop;
	GravityCheck[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public Action:BoostUseUnLock(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !BoostCheck[client]) return Plugin_Stop;
	BoostCheck[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public Action:SlowUseUnLock(Handle:timer, any:client)
{
	if (!client || !IsClientInGame(client) || !SlowCheck[client]) return Plugin_Stop;
	SlowCheck[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
public OnKilled(const String:output[], ent, client, Float:delay)
{
	for( new i = 1; i <=MaxClients; i++ )
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsClientTouch[i][ent])
		{
			HP_StopTimer(i);
			HP_StopTimer_3(i);
		}
	}
}
public Action:CreateGravityField(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	if(ScientistCheck[client])
	{
		if (!classCheck[client]) classCheck[client] = true;
		if (GravityCheck[client])
		{
			PrintToChat(client,"%t", "timeout_field");
			return;
		}
		new Float:VecOrg[3], Float:VecAngles[3], Float:VecDirection[3];
		GetClientAbsOrigin(client, VecOrg);
		GetClientEyeAngles(client, VecAngles);
		GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
		VecOrg[0] += VecDirection[0] * 128;
		VecOrg[1] += VecDirection[1] * 128;
		VecOrg[2] += VecDirection[2] * 1;
		
		new trigger_gravity = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_gravity, "spawnflags", "1");
		DispatchKeyValue(trigger_gravity, "wait", "0");
		DispatchSpawn(trigger_gravity);
		ActivateEntity(trigger_gravity);
		TeleportEntity(trigger_gravity, VecOrg, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_gravity, "models/error.mdl");
		SetEntPropVector(trigger_gravity, Prop_Send, "m_vecMins", Float: {-60.0, -60.0, 0.0});
		SetEntPropVector(trigger_gravity, Prop_Send, "m_vecMaxs", Float: {60.0, 60.0, 30.0});
		SetEntProp(trigger_gravity, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_gravity, "OnStartTouch", OnStartTouch4);
		//HookSingleEntityOutput(trigger_gravity, "OnEndTouch", OnEndTouch4);
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:Kill::12.0:-1");
		AcceptEntityInput(trigger_gravity, "AddOutput");
		AcceptEntityInput(trigger_gravity, "FireUser1");
		
		new ent_smoke = CreateEntityByName("env_smokestack");
		DispatchKeyValue(ent_smoke, "BaseSpread", "60");
		DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
		DispatchKeyValue(ent_smoke, "Speed", "100");
		DispatchKeyValue(ent_smoke, "StartSize", "10");
		DispatchKeyValue(ent_smoke, "EndSize", "10");
		DispatchKeyValue(ent_smoke, "Rate", "50");
		DispatchKeyValue(ent_smoke, "JetLength", "50");
		DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
		DispatchKeyValue(ent_smoke, "twist", "100");
		DispatchKeyValue(ent_smoke, "rendercolor", "255 255 0");
		DispatchKeyValue(ent_smoke, "renderamt", "255");
		DispatchKeyValue(ent_smoke, "roll", "100");
		DispatchKeyValue(ent_smoke, "InitialState", "1");
		DispatchKeyValue(ent_smoke, "angles", "0 0 0");
		DispatchKeyValue(ent_smoke, "WindSpeed", "0");
		DispatchKeyValue(ent_smoke, "WindAngle", "0");
		TeleportEntity(ent_smoke, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent_smoke);
		AcceptEntityInput(ent_smoke, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::12.0:-1");
		AcceptEntityInput(ent_smoke, "AddOutput");
		AcceptEntityInput(ent_smoke, "FireUser1");
		
		new iEnt = CreateEntityByName("light_dynamic");
		iTPIndex[client][1] = EntIndexToEntRef(iEnt);
		DispatchKeyValue(iEnt, "_light", "255 255 0 255");
		DispatchKeyValue(iEnt, "brightness", "1");
		DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
		DispatchKeyValueFloat(iEnt, "distance", 255.0);
		DispatchKeyValue(iEnt, "style", "0");
		VecOrg[2] += 25.0;
		TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::12.0:-1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
		
		EmitSoundToAll(SOUND_TP3, ent_smoke);
		HealthPenalty(client);
		
		GravityCheck[client] = CreateTimer (30.0, GravityUseUnLock, client);
	}
	else PrintToChat(client, "%t", "only_scientists");
}
public OnStartTouch4(const String:output[], ent, client, Float:delay)
{
	if (client && IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		if (team == 3)
		{
		//InfectedPowerCount[client] = 0;
		//if (++InfectedPowerCount[client] < 4)
		//{
		
			new Float:VecOrg[3];
			GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", VecOrg);

			VecOrg[0] += ((GetRandomInt(0, VALVE_RAND_MAX) % 180) + 50) * (((GetRandomInt(0, VALVE_RAND_MAX) % 2) == 1) ?  -1 : 1);
			VecOrg[1] += ((GetRandomInt(0, VALVE_RAND_MAX) % 180) + 50) * (((GetRandomInt(0, VALVE_RAND_MAX) % 2) == 1) ?  -1 : 1);
			VecOrg[2] += 800.0;

			TeleportEntity (client, NULL_VECTOR, NULL_VECTOR, Float:VecOrg);
		}
		else if (team == 2 && !EngineerCheck[client] && !IsSurvivorGravity[client])
		{
			SetEntityGravity(client, 0.6);
			IsSurvivorGravity[client] = true;
			CreateTimer(30.0, GravityStop, client);
			
			new clients[2];
			clients[0] = client;
			new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
			BfWriteShort(message, 255);
			BfWriteShort(message, 255);
			BfWriteShort(message, (0x0002));
			BfWriteByte(message, 255);
			BfWriteByte(message, 255);
			BfWriteByte(message, 0);
			BfWriteByte(message, 128);
			EndMessage();
		}
		//return;
		//	}
		//	//x = 0;
		//	//AcceptEntityInput(ent, "kill");
		//	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 5) SetEntityRenderColor(client, 255, 255, 0, 255);
		//}
		//return Plugin_Continue;
	}
}
public Action:GravityStop(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && IsSurvivorGravity[client])
	{
		SetEntityGravity(client, 1.0);
		IsSurvivorGravity[client] = false;
	}
}
public Action:CreateBoostField(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	if(ScientistCheck[client])
	{
		if (!classCheck[client]) classCheck[client] = true;
		if (BoostCheck[client])
		{
			PrintToChat(client,"%t", "timeout_field");
			return;
		}
		new Float:VecOrg[3], Float:VecAngles[3], Float:VecDirection[3];
		GetClientAbsOrigin(client, VecOrg);
		GetClientEyeAngles(client, VecAngles);
		GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
		VecOrg[0] += VecDirection[0] * 128;
		VecOrg[1] += VecDirection[1] * 128;
		VecOrg[2] += VecDirection[2] * 1;

		new trigger_speedy = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_speedy, "spawnflags", "1");
		DispatchKeyValue(trigger_speedy, "wait", "0");
		DispatchSpawn(trigger_speedy);
		ActivateEntity(trigger_speedy);
		TeleportEntity(trigger_speedy, VecOrg, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_speedy, "models/error.mdl");
		SetEntPropVector(trigger_speedy, Prop_Send, "m_vecMins", Float: {-60.0, -60.0, 0.0});
		SetEntPropVector(trigger_speedy, Prop_Send, "m_vecMaxs", Float: {60.0, 60.0, 30.0});
		SetEntProp(trigger_speedy, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_speedy, "OnStartTouch", OnStartTouch5);
		//HookSingleEntityOutput(trigger_speedy, "OnEndTouch", OnEndTouch5);
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:Kill::20.0:-1");
		AcceptEntityInput(trigger_speedy, "AddOutput");
		AcceptEntityInput(trigger_speedy, "FireUser1");
		
		new ent_smoke = CreateEntityByName("env_smokestack");
		DispatchKeyValue(ent_smoke, "BaseSpread", "60");
		DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
		DispatchKeyValue(ent_smoke, "Speed", "100");
		DispatchKeyValue(ent_smoke, "StartSize", "10");
		DispatchKeyValue(ent_smoke, "EndSize", "10");
		DispatchKeyValue(ent_smoke, "Rate", "50");
		DispatchKeyValue(ent_smoke, "JetLength", "50");
		DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
		DispatchKeyValue(ent_smoke, "twist", "100");
		DispatchKeyValue(ent_smoke, "rendercolor", "0 255 0");
		DispatchKeyValue(ent_smoke, "renderamt", "255");
		DispatchKeyValue(ent_smoke, "roll", "100");
		DispatchKeyValue(ent_smoke, "InitialState", "1");
		DispatchKeyValue(ent_smoke, "angles", "0 0 0");
		DispatchKeyValue(ent_smoke, "WindSpeed", "0");
		DispatchKeyValue(ent_smoke, "WindAngle", "0");
		TeleportEntity(ent_smoke, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent_smoke);
		AcceptEntityInput(ent_smoke, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::20.0:-1");
		AcceptEntityInput(ent_smoke, "AddOutput");
		AcceptEntityInput(ent_smoke, "FireUser1");
		
		new iEnt = CreateEntityByName("light_dynamic");
		iTPIndex[client][1] = EntIndexToEntRef(iEnt);
		DispatchKeyValue(iEnt, "_light", "0 255 0 255");
		DispatchKeyValue(iEnt, "brightness", "1");
		DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
		DispatchKeyValueFloat(iEnt, "distance", 255.0);
		DispatchKeyValue(iEnt, "style", "0");
		VecOrg[2] += 25.0;
		TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::20.0:-1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
		
		EmitSoundToAll(SOUND_TP3, ent_smoke);
		HealthPenalty(client);
		
		BoostCheck[client] = CreateTimer (30.0, BoostUseUnLock, client);
	}
	else PrintToChat(client, "%t", "only_scientists");
}
public OnStartTouch5(const String:output[], ent, client, Float:delay)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2 && !MedicCheck[client] && !IsSurvivorBoost[client])
	{
		new Float:speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
		//PrintToChatAll("Speed = %f", speed);
		if (speed == 0.7 || speed == 1.01 || speed == 1.21) return;
		BasicSpeed[client] = speed;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed + 0.21);
		IsSurvivorBoost[client] = true;
		CreateTimer(30.0, SpeedyStop, client);
		
		new clients[2];
		clients[0] = client;
		new Handle:message = StartMessageEx(g_FadeUserMsgIdP, clients, 1);
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, 0);
		BfWriteByte(message, 255);
		BfWriteByte(message, 0);
		BfWriteByte(message, 128);
		EndMessage();
	}
}
public Action:SpeedyStop(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && IsSurvivorBoost[client])
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", BasicSpeed[client]);
		IsSurvivorBoost[client] = false;
	}
}
public Action:CreateSlowField(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	if(ScientistCheck[client])
	{
		if (!classCheck[client]) classCheck[client] = true;
		if (SlowCheck[client])
		{
			PrintToChat(client,"%t", "timeout_field");
			return;
		}
		new Float:VecOrg[3], Float:VecAngles[3], Float:VecDirection[3];
		GetClientAbsOrigin(client, VecOrg);
		GetClientEyeAngles(client, VecAngles);
		GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
		VecOrg[0] += VecDirection[0] * 128;
		VecOrg[1] += VecDirection[1] * 128;
		VecOrg[2] += VecDirection[2] * 1;

		new trigger_speedy = CreateEntityByName("trigger_multiple");
		DispatchKeyValue(trigger_speedy, "spawnflags", "1");
		DispatchKeyValue(trigger_speedy, "wait", "0");
		DispatchSpawn(trigger_speedy);
		ActivateEntity(trigger_speedy);
		TeleportEntity(trigger_speedy, VecOrg, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(trigger_speedy, "models/error.mdl");
		SetEntPropVector(trigger_speedy, Prop_Send, "m_vecMins", Float: {-60.0, -60.0, 0.0});
		SetEntPropVector(trigger_speedy, Prop_Send, "m_vecMaxs", Float: {60.0, 60.0, 30.0});
		SetEntProp(trigger_speedy, Prop_Send, "m_nSolidType", 2);
		HookSingleEntityOutput(trigger_speedy, "OnStartTouch", OnStartTouch6);
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:Kill::12.0:-1");
		AcceptEntityInput(trigger_speedy, "AddOutput");
		AcceptEntityInput(trigger_speedy, "FireUser1");
		
		new ent_smoke = CreateEntityByName("env_smokestack");
		DispatchKeyValue(ent_smoke, "BaseSpread", "60");
		DispatchKeyValue(ent_smoke, "SpreadSpeed", "0");
		DispatchKeyValue(ent_smoke, "Speed", "100");
		DispatchKeyValue(ent_smoke, "StartSize", "10");
		DispatchKeyValue(ent_smoke, "EndSize", "10");
		DispatchKeyValue(ent_smoke, "Rate", "50");
		DispatchKeyValue(ent_smoke, "JetLength", "50");
		DispatchKeyValue(ent_smoke, "SmokeMaterial", "particle/SmokeStack.vmt");
		DispatchKeyValue(ent_smoke, "twist", "100");
		DispatchKeyValue(ent_smoke, "rendercolor", "0 0 255");
		DispatchKeyValue(ent_smoke, "renderamt", "255");
		DispatchKeyValue(ent_smoke, "roll", "100");
		DispatchKeyValue(ent_smoke, "InitialState", "1");
		DispatchKeyValue(ent_smoke, "angles", "0 0 0");
		DispatchKeyValue(ent_smoke, "WindSpeed", "0");
		DispatchKeyValue(ent_smoke, "WindAngle", "0");
		TeleportEntity(ent_smoke, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent_smoke);
		AcceptEntityInput(ent_smoke, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::12.0:-1");
		AcceptEntityInput(ent_smoke, "AddOutput");
		AcceptEntityInput(ent_smoke, "FireUser1");
		
		new iEnt = CreateEntityByName("light_dynamic");
		iTPIndex[client][1] = EntIndexToEntRef(iEnt);
		DispatchKeyValue(iEnt, "_light", "0 0 255 255");
		DispatchKeyValue(iEnt, "brightness", "1");
		DispatchKeyValueFloat(iEnt, "spotlight_radius", 1.0);
		DispatchKeyValueFloat(iEnt, "distance", 255.0);
		DispatchKeyValue(iEnt, "style", "0");
		VecOrg[2] += 25.0;
		TeleportEntity(iEnt, VecOrg, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iEnt);
		AcceptEntityInput(iEnt, "TurnOn");
		SetVariantString("!activator");
		SetVariantString("OnUser1 !self:TurnOff::12.0:-1");
		AcceptEntityInput(iEnt, "AddOutput");
		AcceptEntityInput(iEnt, "FireUser1");
		
		EmitSoundToAll(SOUND_TP3, ent_smoke);
		HealthPenalty(client);
		
		SlowCheck[client] = CreateTimer (30.0, SlowUseUnLock, client);
	}
	else PrintToChat(client, "%t", "only_scientists");
}
public OnStartTouch6(const String:output[], ent, client, Float:delay)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsInfectedSlow[client] && !TranquilizerTimeout[client])
	{
		new Float:speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
		if (speed == 0.9) return;
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed - 0.1);
		if (GetEntProp(client, Prop_Send, "m_zombieClass") == 5) SetEntityRenderColor(client, 66, 205, 255, 255);
		IsInfectedSlow[client] = true;
		CreateTimer(30.0, SlowStop, client);
	}
}
public Action:SlowStop(Handle:timer, any:client)
{
	if (client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3 && IsInfectedSlow[client])
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")) + 0.1);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		IsInfectedSlow[client] = false;
	}
}
public Action:ScientistSkills(client, args)
{
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2) return;
	
	if(ScientistCheck[client])
	{
		new Handle:ScientistMenu = CreateMenu(ScillsMenuHandler);
		decl String:ClTitle[32];
		Format(ClTitle, sizeof(ClTitle), "%T", "ScillsTitleScientist", client);
		SetMenuTitle(ScientistMenu, ClTitle);
		new String:Value[38];
		
		Format(Value, sizeof(Value), "%T\n \n", "m_Refresh", client);
		AddMenuItem(ScientistMenu, "0", Value);
		
		Format(Value, sizeof(Value), "%T", "Teleport", client);
		AddMenuItem(ScientistMenu, "1", Value);
		
		if (!GravityCheck[client])Format(Value, sizeof(Value), "%T ☑", "GravityField", client);
		else Format(Value, sizeof(Value), "%T ☐", "GravityField", client);
		AddMenuItem(ScientistMenu, "2", Value);
		
		if (!BoostCheck[client])Format(Value, sizeof(Value), "%T ☑", "AcceleratField", client);
		else Format(Value, sizeof(Value), "%T ☐", "AcceleratField", client);
		AddMenuItem(ScientistMenu, "3", Value);
		
		if (!SlowCheck[client])Format(Value, sizeof(Value), "%T ☑\n \n", "SlowingField", client);
		else Format(Value, sizeof(Value), "%T ☐\n \n", "SlowingField", client);
		AddMenuItem(ScientistMenu, "4", Value);
		
		Format(Value, sizeof(Value), "%T", "ButtBack", client);
		AddMenuItem(ScientistMenu, "5", Value);
		
		SetMenuExitButton(ScientistMenu, true);
		DisplayMenu(ScientistMenu, client, 35);
		
		return;
	}
	else PrintToChat(client, "%t", "only_scientists");
}
//Кнопка назад
public ScillsMenuHandler(Handle:ScientistMenu, MenuAction:action, client, option) 
{
	if (action == MenuAction_Select) 
	{
		switch (option)
		{
			case 0: ScientistSkills(client, 0);
			case 1: CreateTeleportField(client, 0);
			case 2: CreateGravityField(client, 0);
			case 3: CreateBoostField(client, 0);
			case 4: CreateSlowField(client, 0);
			case 5: ScientistPanel(client);
		}
	}
}
public HealthPenalty(client)
{
	new hp = GetEntProp(client, Prop_Data, "m_iHealth");
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
	{
		SetEntProp(client, Prop_Data, "m_iHealth", hp-50);
		return;
	}
	if (hp > 5) SetEntProp(client, Prop_Data, "m_iHealth", hp-5);
	else 
	{
		new buffer_health = L4D_GetPlayerTempHealth(client);
		new totalHp = hp + buffer_health;
		if (buffer_health > 5)
		{
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", buffer_health - 5.0);
		}
		else if (totalHp > 5)
		{
			SetEntProp(client, Prop_Data, "m_iHealth", 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 4.0);
		}
		else
		{
			if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == 2)
			{
				ForcePlayerSuicide(client);
				return;
			}
			SetEntProp(client, Prop_Data, "m_iHealth", 100);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 150.0);
			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		}
	}
}





















