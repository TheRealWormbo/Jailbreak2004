// ============================================================================
// JBMutator
// Copyright 2006 by Jrubzjeknf <rrvanolst@hotmail.com>
// $Id: JBMutator.uc,v 1.1 2006-12-20 17:11:24 jrubzjeknf Exp $
//
// Jailbreak's base mutator.
// ============================================================================


class JBMutator extends DMMutator
  HideDropDown
  CacheExempt;


// ============================================================================
// Variables
// ============================================================================

var array<String> VariableNames;


// ============================================================================
// CheckReplacement
//
// All sentinels are passed through this function. Checks if we want to
// replace it with our own.
// ============================================================================

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
  if (ASVehicleFactory(Other) != None &&
      Mid(Other, InStr(Level, ".")+1, 37) ~= "ASVehicleFactory_SentinelCeiling_Proj") {
    ReplaceSentinelFactory(Other);
    return False;
  }

  return True;
}


// ============================================================================
// ReplaceSentinelFactory
//
// Stop the current factory from spawning sentinels, spawn our own factory and
// copy the custom variables.
// ============================================================================

function ReplaceSentinelFactory(Actor OldFactory)
{
  local class<Actor> NewFactoryClass;
  local Actor NewFactory;
  local int i;

  // Prevent the old factory from spawning more sentinels.
  SVehicleFactory(OldFactory).VehicleClass = None;

  // Spawn our own sentinel fctory.
  NewFactoryClass = class<Actor>(DynamicLoadObject("JBToolbox2.JBSentinelCeilingFactory", class'Class'));
  NewFactory = Spawn(NewFactoryClass,, OldFactory.Tag, OldFactory.Location, OldFactory.Rotation);

  // Copy the custom variables.
  for (i=0; i<VariableNames.length; ++i)
    NewFactory.SetPropertyText(VariableNames[i], OldFactory.GetPropertyText(VariableNames[i]));
}


// ============================================================================
// Default properties
// ============================================================================

defaultproperties
{
  VariableNames(0) = "bSleepWhenDisabled"
  VariableNames(1) = "ProjectileClass"
  VariableNames(2) = "ProjectileSpawnOffset"
  VariableNames(3) = "FireRate"
  VariableNames(4) = "FireSound"
  VariableNames(5) = "AttachmentClass"
  VariableNames(6) = "FlashEmitterClass"
  VariableNames(7) = "SmokeEmitterClass"
}