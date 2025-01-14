// ============================================================================
// JBAddonProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBAddonProtection.uc,v 1.14 2004/05/28 16:09:55 mychaeel Exp $
//
// This add-on protects players released from jail.
// ============================================================================


class JBAddonProtection extends JBAddon config cacheexempt;


//=============================================================================
// Constants
//=============================================================================

//const DEFAULT_PROTECTION_TIME = 3;
//const DEFAULT_PROTECTION_TYPE = 1;
//const DEFAULT_PROTECT_ARENA   = True;
//const DEFAULT_LLAMAIZE_CAMPERS= True;


// ============================================================================
// Variables
// ============================================================================

var() const editconst string Build;
var() config int  ProtectionTime;      // how long protection lasts for
var() config byte ProtectionType;       // 0: can't damage while protected
                                        // 1: protection drops when damage done
var() config bool bProtectArenaWinner;  // protect the arena winner
var() config bool bLlamaizeCampers;     // if killing damage to protectee

var PlayerReplicationInfo LastRestartedPRI;
var localized string caption_ProtectionType;
var localized string caption_ProtectionTime;
var localized string caption_ProtectArenaWinner;
var localized string caption_LlamaizeCampers;

var localized string desc_ProtectionType;
var localized string desc_ProtectionTime;
var localized string desc_ProtectArenaWinner;
var localized string desc_LlamaizeCampers;

var localized string options_ProtectionType;


// ============================================================================
// PostBeginPlay
//
// Spawn and register the additional rules.
// ============================================================================

function PostBeginPlay()
{
    local JBGameRulesProtection ProtectionRules;

    Super.PostBeginPlay();

    ProtectionRules = Spawn(class'JBGameRulesProtection');
    if(ProtectionRules != None)
    {
        ProtectionRules.MyAddon = SELF;
        if(Level.Game.GameRulesModifiers == None)
            Level.Game.GameRulesModifiers = ProtectionRules;
        else Level.Game.GameRulesModifiers.AddGameRules(ProtectionRules);
    }
    else
    {
        LOG("!!!!!"@name$".PostBeginPlay() : Fail to spawn JBGameRulesProtection !!!!!");
        Destroy();
    }
}


// ============================================================================
// ModifyPlayer
//
// When a player restart, save his PRI.
// ============================================================================

function ModifyPlayer(Pawn P)
{
    LastRestartedPRI = P.PlayerReplicationInfo;

    Super.ModifyPlayer(P);
}


// ============================================================================
// FillPlayInfo
//
// Adds configurable addon properties to the web admin interface.
// ============================================================================

static function FillPlayInfo(PlayInfo PlayInfo)
{
    PlayInfo.AddClass(default.class);
    PlayInfo.AddSetting(PlayInfoGroup(), "ProtectionTime", default.caption_ProtectionTime, 0, 1, "Text", "2;0:10");
    PlayInfo.AddSetting(PlayInfoGroup(), "ProtectionType", default.caption_ProtectionType, 0, 2, "Select", default.options_ProtectionType);
    PlayInfo.AddSetting(PlayInfoGroup(), "bProtectArenaWinner", default.caption_ProtectArenaWinner , 0, 3, "Check");
    PlayInfo.AddSetting(PlayInfoGroup(), "bLlamaizeCampers", default.caption_LlamaizeCampers , 0, 4, "Check");
    PlayInfo.PopClass();
}


//=============================================================================
// GetDescriptionText
//
// Returns the description text for a configurable property.
//=============================================================================

static event string GetDescriptionText(string PropName)
{
  switch (PropName) {
    case "ProtectionType":      return default.desc_ProtectionType;
    case "ProtectionTime":      return default.desc_ProtectionTime;
    case "bProtectArenaWinner": return default.desc_ProtectArenaWinner;
    case "bLlamaizeCampers":    return default.desc_LlamaizeCampers;
  }
  
  return Super.GetDescriptionText(PropName);
}


//=============================================================================
// ResetConfiguration
//
// Resets the Avenger configuration.
//=============================================================================

/*static function ResetConfiguration()
{
  default.ProtectionTime      = DEFAULT_PROTECTION_TIME;
  default.ProtectionType      = DEFAULT_PROTECTION_TYPE;
  default.bProtectArenaWinner = DEFAULT_PROTECT_ARENA;
  default.bLlamaizeCampers    = DEFAULT_LLAMAIZE_CAMPERS;
  StaticSaveConfig();
}*/


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    Build = "%%%%-%%-%% %%:%%";
    ProtectionTime      =3
    ProtectionType      =0
    bProtectArenaWinner =True
    bLlamaizeCampers    =True
    FriendlyName="Release Protection"
    Description="Players released from jail are protected from enemy fire."
    ConfigMenuClassName="JBAddonProtection.JBGUIPanelConfigProtection"
    caption_ProtectionTime    ="Protection time"
    caption_ProtectionType    ="Protection type"
    caption_ProtectArenaWinner="Protect the arena winner"
    caption_LlamaizeCampers   ="Make jail campers llamas"
    desc_ProtectionTime    ="Duration of protection in seconds."
    desc_ProtectionType    ="Whether your weapons do no damage while you are protected or protection is removed when you hit a player."
    desc_ProtectArenaWinner="When enabled, the arena winner gains protection."
    desc_LlamaizeCampers   ="When enabled, players causing lethal damage to protected players are made llamas."
    options_ProtectionType="0;You can't inflict damage;1;Drop when you inflict damage"
}
