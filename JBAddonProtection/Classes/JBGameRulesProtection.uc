// ============================================================================
// JBGameRulesProtection
// Copyright 2003 by Christophe "Crokx" Cros <crokx@beyondunreal.com>
// $Id: JBGameRulesProtection.uc,v 1.1 2003/06/27 11:14:32 crokx Exp $
//
// The rules for the protection mutator.
// ============================================================================
class JBGameRulesProtection extends JBGameRules;


// ============================================================================
// Variables
// ============================================================================
var JBAddonProtection MyAddon;
var private JBInfoProtection MyProtection;
var private Shader RedHitEffect, BlueHitEffect;
var private sound ProtectionHitSound;


// ============================================================================
// NotifyPlayerJailed
//
// When a player was jailed, this player are protected.
// ============================================================================
function NotifyPlayerJailed(JBTagPlayer NewJailedPlayer)
{
    if(NewJailedPlayer.GetPlayerReplicationInfo().PlayerID == MyAddon.LastRestartedPlayerID)
    {
        MyAddon.LastRestartedPlayerID = -1;

        if(NewJailedPlayer.GetJail().IsReleaseActive(NewJailedPlayer.GetTeam()))
            GiveProtectionTo(NewJailedPlayer, TRUE);
    }

    Super.NotifyPlayerJailed(NewJailedPlayer);
}


// ============================================================================
// NotifyJailOpening
//
// Called when a jail start the opening, give protection to jailed players.
// ============================================================================
function NotifyJailOpening(JBInfoJail Jail)
{
    local JBTagPlayer JailedPlayer;

    for(JailedPlayer=GetFirstTagPlayer(); JailedPlayer!=None; JailedPlayer=JailedPlayer.NextTag)
    {
        if((JailedPlayer != None) // is not obligate to found jailed player
        && (JailedPlayer.GetJail() == Jail))
            GiveProtectionTo(JailedPlayer);
    }

    Super.NotifyJailOpening(Jail);
}


// ============================================================================
// NotifyPlayerReleased
//
// Called when a jailled player was escaped, start the protection delay.
// ============================================================================
function NotifyPlayerReleased(JBTagPlayer TagPlayer, JBInfoJail Jail)
{
    MyProtection = GetMyProtection(TagPlayer.GetPlayerReplicationInfo());
    if(MyProtection != None) MyProtection.StartProtectionLife();

    Super.NotifyPlayerReleased(TagPlayer, Jail);
}


// ============================================================================
// NotifyJailClosed
//
// Called when the jail door was re-closed, remove evantual protection.
// ============================================================================
function NotifyJailClosed(JBInfoJail Jail)
{
    local JBTagPlayer ReJailedPlayer;

    for(ReJailedPlayer=GetFirstTagPlayer(); ReJailedPlayer!=None; ReJailedPlayer=ReJailedPlayer.NextTag)
    {
        if((ReJailedPlayer != None) // is not obligate to found re-jailed player
        && (ReJailedPlayer.GetJail() == Jail))
        {
            MyProtection = GetMyProtection(ReJailedPlayer.GetPlayerReplicationInfo());
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    Super.NotifyJailClosed(Jail);
}


// ============================================================================
// NotifyExecutionCommit
//
// When a team are captured, remove all evantual protection.
// ============================================================================
function NotifyExecutionCommit(TeamInfo Team)
{
    foreach DynamicActors(class'JBInfoProtection', MyProtection)
        if(MyProtection != None)
            MyProtection.Destroy();

    Super.NotifyExecutionCommit(Team);
}


// ============================================================================
// NotifyArenaStart
//
// When a player go fight in arena, this player lost his evantual protection.
// ============================================================================
function NotifyArenaStart(JBInfoArena Arena)
{
    local JBTagPlayer Fighter;

    for(Fighter=GetFirstTagPlayer(); Fighter!=None; Fighter=Fighter.NextTag)
    {
        if(Fighter.GetArena() == Arena)
        {
            MyProtection = GetMyProtection(Fighter.GetPlayerReplicationInfo());
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    Super.NotifyArenaStart(Arena);
}


// ============================================================================
// NotifyArenaEnd
//
// The winner of arena was protected.
// ============================================================================
function NotifyArenaEnd(JBInfoArena Arena, JBTagPlayer TagPlayerWinner)
{
    if(class'JBAddonProtection'.default.bProtectArenaWinner)
        GiveProtectionTo(TagPlayerWinner, TRUE);

    Super.NotifyArenaEnd(Arena, TagPlayerWinner);
}


// ============================================================================
// GiveProtectionTo
//
// Protect a player from his JBTagPlayer.
// ============================================================================
function GiveProtectionTo(JBTagPlayer TagPlayer, optional bool bProtectNow)
{
    if((TagPlayer.GetController() != None) // for make sure no GetPawn() here
    && (TagPlayer.GetController().Pawn != None)
    && (TagPlayer.GetController().Pawn.ReducedDamageType == None))
    {
        MyProtection = Spawn(class'JBInfoProtection', TagPlayer.GetController().Pawn);
        if(MyProtection != None)
        {
            MyProtection.RelatedID = TagPlayer.GetPlayerReplicationInfo().PlayerID;
            if(bProtectNow) MyProtection.StartProtectionLife();
        }
    }
}


// ============================================================================
// HitShieldEffect
//
// Make a shield effect for see the damage absorption.
// ============================================================================
function HitShieldEffect(Pawn ProtectedPawn)
{
    local xPawn xProtectedPawn;

    if(ProtectedPawn.IsA('xPawn') == FALSE) return;

    xProtectedPawn = xPawn(ProtectedPawn);
    xProtectedPawn.PlaySound(ProtectionHitSound, SLOT_Pain, TransientSoundVolume*2,, 400);

    if(xProtectedPawn.PlayerReplicationInfo.Team.TeamIndex == 0)
        xProtectedPawn.SetOverlayMaterial(RedHitEffect, xProtectedPawn.ShieldHitMatTime, FALSE);
    else xProtectedPawn.SetOverlayMaterial(BlueHitEffect, xProtectedPawn.ShieldHitMatTime, FALSE);
}


// ============================================================================
// NetDamage
//
// Called when a player receive damage.
// ============================================================================
function int NetDamage(int OriginalDamage, int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    if(Injured.ReducedDamageType == class'JBDamageTypeNone')
    {
        HitShieldEffect(Injured);
        Momentum = vect(0,0,0);
        return 0;
    }

    if((InstigatedBy != None)
    && (InstigatedBy.ReducedDamageType == class'JBDamageTypeNone')
    && (InstigatedBy != Injured))
    {
        if(class'JBAddonProtection'.default.ProtectionType == 0)
        {
            Momentum = vect(0,0,0);
            return 0;
        }
        else if(class'JBAddonProtection'.default.ProtectionType == 1)
        {
            MyProtection = GetMyProtection(InstigatedBy.PlayerReplicationInfo);
            if(MyProtection != None) MyProtection.Destroy();
        }
    }

    if(NextGameRules != None)
        return NextGameRules.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
}


// ============================================================================
// Accessors
// ============================================================================
final function JBTagPlayer GetFirstTagPlayer() {
    return (JBGameReplicationInfo(Level.Game.GameReplicationInfo).FirstTagPlayer); }

final function JBInfoProtection GetMyProtection(PlayerReplicationInfo PRI)
{
    foreach DynamicActors(class'JBInfoProtection', MyProtection)
    {
        if((MyProtection != None)
        && (MyProtection.RelatedID == PRI.PlayerID))
            return MyProtection;
    }

    return None;
}


// ============================================================================
// Default properties
// ============================================================================
defaultproperties
{
    RedHitEffect=Shader'XGameShaders.PlayerShaders.PlayerTransRed'
    BlueHitEffect=Shader'XGameShaders.PlayerShaders.PlayerTrans'
    ProtectionHitSound=Sound'WeaponSounds.BaseImpactAndExplosions.bShieldReflection'
}