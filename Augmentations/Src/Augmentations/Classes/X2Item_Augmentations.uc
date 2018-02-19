class X2Item_Augmentations extends X2Item config (Augmentations);

struct SlotConfigMap
{
	var EInventorySlot InvSlot;
	var name Category;
};

struct CosmeticConfig
{
	var name CharacterTemplate;
	var EInventorySlot InvSlot;
	var name Arm;
	var name CosmeticTemplate;
	var name ArmorTemplate;
	var bool bStripAccessories;
	var bool bFemale;
};

var config bool bAddCosmeticOnAugmentation;
var config array<CosmeticConfig> AutoCosmeticConfig;

var config array<EInventorySlot> AugmentationSlots;
var config array<SlotConfigMap> SlotConfig;

var config WeaponDamageValue	CLAWS_BASEDAMAGE;
var config int					CLAWS_AIM;
var config int					CLAWS_CRITCHANCE;
var config int					CLAWS_ICLIPSIZE;
var config int					CLAWS_ISOUNDRANGE;
var config int					CLAWS_IENVIRONMENTDAMAGE;
var config int					CLAWS_UPGRADE_SLOTS;

var config WeaponDamageValue	CYBER_ARM_BASEDAMAGE;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;
	local X2DataTemplate Item;
	local array<name> Abilities;
	local int Index;

	Items.AddItem(AugmentationHead_Base_CV());
	Items.AddItem(AugmentationTorso_Base_CV());
	Items.AddItem(AugmentationArms_Base_CV());
	Items.AddItem(AugmentationLegs_Base_CV());
	
	Items.AddItem(AugmentationHead_NeuralGunlink_MG());
	Items.AddItem(AugmentationHead_NeuralTacticalProcessor_BM());
	Items.AddItem(AugmentationHead_WeakpointAnalyzer_MG());
	Items.AddItem(AugmentationHead_WeakpointAnalyzer_BM());

	Items.AddItem(AugmentationArms_Claws_MG());
	Items.AddItem(AugmentationArms_Claws_Left_MG());
	Items.AddItem(AugmentationArms_Grapple_MG());
	Items.AddItem(AugmentationArms_Launcher_BM());

	//Items.AddItem(AugmentationTorso_BodyCompartment_MG());
	Items.AddItem(AugmentationTorso_NanoCoating_MG());
	Items.AddItem(AugmentationTorso_NanoCoating_BM());
	
	Items.AddItem(AugmentationLegs_JumpModule_MG());

	Items.AddItem(AugmentationLegs_SilentRunners_BM());
	Items.AddItem(AugmentationLegs_JumpModule_BM());

	if (class'X2DownloadableContentInfo_Augmentations'.static.IsModInstalled('X2DownloadableContentInfo_XCOM2RPGOverhaul'))
	{
		Items.AddItem(AugmentationLegs_Muscles_MG());
	}
	
	
	// reverse ability order so the signature abilities are on top in the tactical ui
	foreach Items(Item)
	{
		Abilities = X2EquipmentTemplate(Item).Abilities;
		X2EquipmentTemplate(Item).Abilities.Length = 0;
		for (Index = Abilities.Length -1; Index >= 0; Index--)
		{
			X2EquipmentTemplate(Item).Abilities.AddItem(Abilities[Index]);
		}
	}

	return Items;
}

static function X2EquipmentTemplate AugmentationBase(X2EquipmentTemplate Template)
{
	Template.EquipSound = "StrategyUI_Mindshield_Equip";
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = false;
	Template.bShouldCreateDifficultyVariants = true;
	Template.Abilities.AddItem('ExMachina');
	Template.Abilities.AddItem('AugmentationBasePenalties');
	Template.SetUIStatMarkup(class'XLocalizedData'.default.WillLabel, eStat_Will, class'X2Ability_Augmentations_Abilities'.default.AUGMENTATION_BASE_WILL_LOSS);
	Template.OnEquippedFn = OnAugmentationEquipped;

	return Template;
}

static function OnAugmentationEquipped(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local UnitValue SeveredBodyPart;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local string GenderSuffix;
	local string Head;
	local CosmeticConfig AutoConfig;
	local bool bFemale;
	local X2ArmorTemplate ArmorTemplate;

	if (!UnitState.IsSoldier())
		return;

	if (UnitState.GetUnitValue('SeveredBodyPart', SeveredBodyPart))
	{
		if ((int(SeveredBodyPart.fValue) == eHead && X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot == eInvSlot_AugmentationHead) ||
			(int(SeveredBodyPart.fValue) == eTorso && X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot == eInvSlot_AugmentationTorso) ||
			(int(SeveredBodyPart.fValue) == eArms && X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot == eInvSlot_AugmentationArms) ||
			(int(SeveredBodyPart.fValue) == eLegs && X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot == eInvSlot_AugmentationLegs))
		{
			`LOG(GetFuncName() @ "SeveredBodyPart" @ GetEnum(Enum'ESeveredBodyPart', SeveredBodyPart.fValue),,'Augmentations');
			if (UnitState.IsInjured() && !UnitState.HasHealingProject())
			{
				XComHQ = GetAndAddXComHQ(NewGameState);
				ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
				ProjectState.SetProjectFocus(UnitState.GetReference(), NewGameState);
				XComHQ.Projects.AddItem(ProjectState.GetReference());
			}
			UnitState.ClearUnitValue('SeveredBodyPart');
		}
	}
	UnitState.ModifyCurrentStat(eStat_HP, UnitState.GetMaxStat(eStat_HP) / 3 * 2);

	if (default.bAddCosmeticOnAugmentation)
	{
		GenderSuffix = UnitState.kAppearance.iGender == eGender_Female ? "_F" : "";
		bFemale = UnitState.kAppearance.iGender == eGender_Female;
		
		switch (UnitState.kAppearance.iRace)
		{
			case eRace_Caucasian:
				Head = "MA_InvisHead_CAU";
				break;
			case eRace_African:
				Head = "MA_InvisHead_AFR";
				break;
			case eRace_Asian:
				Head = "MA_InvisHead_ASN";
				break;
			case eRace_Hispanic:
				Head = "MA_InvisHead_LAT";
				break;
		}

		ArmorTemplate = X2ArmorTemplate(UnitState.GetItemInSlot(eInvSlot_Armor).GetMyTemplate());

		foreach default.AutoCosmeticConfig(AutoConfig)
		{
			if (AutoConfig.CharacterTemplate == UnitState.GetMyTemplateName() &&
				AutoConfig.InvSlot == X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot &&
				AutoConfig.bFemale == bFemale)
			{
				if (ArmorTemplate.DataName != '' &&
					AutoConfig.ArmorTemplate != '' &&
					AutoConfig.ArmorTemplate != ArmorTemplate.DataName)
				{
					continue;
				}

				`LOG("Setting" @ AutoConfig.CosmeticTemplate @ "for" @ AutoConfig.CharacterTemplate @ AutoConfig.InvSlot,, 'Augmentations');
				switch (X2EquipmentTemplate(ItemState.GetMyTemplate()).InventorySlot)
				{
					case eInvSlot_AugmentationHead:
						if (AutoConfig.bStripAccessories)
						{
							UnitState.kAppearance.nmFacePropLower = '';
							UnitState.kAppearance.nmFacePropUpper = '';
						}
						UnitState.kAppearance.nmHead = name(Head $ GenderSuffix);
						UnitState.kAppearance.nmHelmet = AutoConfig.CosmeticTemplate;
						break;
					case eInvSlot_AugmentationTorso:
						if (AutoConfig.bStripAccessories)
						{
							UnitState.kAppearance.nmTorsoDeco = '';
						}
						UnitState.kAppearance.nmTorso = AutoConfig.CosmeticTemplate;
						break;
					case eInvSlot_AugmentationArms:
						if (AutoConfig.bStripAccessories)
						{
							UnitState.kAppearance.nmLeftForearm = '';
							UnitState.kAppearance.nmRightForearm = '';
							UnitState.kAppearance.nmLeftArmDeco = '';
							UnitState.kAppearance.nmRightArmDeco = '';
							UnitState.kAppearance.nmArms = '';
						}
						if (AutoConfig.Arm == 'L')
						{
							UnitState.kAppearance.nmLeftArm = AutoConfig.CosmeticTemplate;
						}
						else if (AutoConfig.Arm == 'R')
						{
							UnitState.kAppearance.nmRightArm = AutoConfig.CosmeticTemplate;
						}
						else
						{
							UnitState.kAppearance.nmArms = AutoConfig.CosmeticTemplate;
						}
						
						break;
					case eInvSlot_AugmentationLegs:
						if (AutoConfig.bStripAccessories)
						{
							UnitState.kAppearance.nmLegs_Underlay = '';
							UnitState.kAppearance.nmThighs = '';
							UnitState.kAppearance.nmShins = '';
						}
						UnitState.kAppearance.nmLegs = AutoConfig.CosmeticTemplate;
						break;
				}
			}
		}
	}
}

private static function XComGameState_HeadquartersXCom GetAndAddXComHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	return XComHQ;
}

static function X2DataTemplate AugmentationHead_Base_CV()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationHead_Base_CV');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_head';
	Template.InventorySlot = eInvSlot_AugmentationHead;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentations_Head";
	
	Template.Abilities.AddItem('AugmentedHead');
	
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 1;

	return Template;
}

static function X2DataTemplate AugmentationTorso_Base_CV()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationTorso_Base_CV');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_torso';
	Template.InventorySlot = eInvSlot_AugmentationTorso;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Torso";
	
	Template.Abilities.AddItem('AugmentationTorsoBase');
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_Augmentations_Abilities'.default.AUGMENTATION_BASE_MITIGATION_AMOUNT);

	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	
	return Template;
}

static function X2DataTemplate AugmentationArms_Base_CV()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AugmentationArms_Base_CV');
	Template = X2WeaponTemplate(AugmentationBase(Template));

	Template.ItemCat = 'augmentation_arms';
	Template.InventorySlot = eInvSlot_AugmentationArms;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Arm";
	
	Template.BaseDamage = default.CYBER_ARM_BASEDAMAGE;
	Template.Abilities.AddItem('AugmentedShield');
	Template.Abilities.AddItem('CyberPunch');
	
	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 1;

	return Template;
}


static function X2DataTemplate AugmentationLegs_Base_CV()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationLegs_Base_CV');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_legs';
	Template.InventorySlot = eInvSlot_AugmentationLegs;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Leg";
	
	Template.Abilities.AddItem('AugmentedSpeed');

	Template.TradingPostValue = 25;
	Template.PointsToComplete = 0;
	Template.Tier = 1;

	return Template;
}


static function X2DataTemplate AugmentationArms_Claws_MG()
{
	local X2PairedWeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2PairedWeaponTemplate', Template, 'AugmentationArms_Claws_MG');
	Template = X2PairedWeaponTemplate(AugmentationBase(Template));
	
	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.
	Template.PairedSlot = eInvSlot_TertiaryWeapon;
	Template.PairedTemplateName = 'AugmentationArms_Claws_Left_MG';

	Template.ItemCat = 'augmentation_arms';
	Template.WeaponCat = 'cyberclaws';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_CyberClaws";
	Template.InventorySlot = eInvSlot_AugmentationArms;
	Template.StowedLocation = eSlot_Claw_R;

	Template.GameArchetype = "CyberClaws_Augmentations.Archetypes.WP_Claws_LG";
	Template.Tier = 2;

	Template.Abilities.AddItem('AugmentedShield');
	Template.Abilities.AddItem('ClawsSlash');
	
	Template.iRadius = 1;
	Template.NumUpgradeSlots = default.CLAWS_UPGRADE_SLOTS;
	Template.InfiniteAmmo = true;
	Template.iPhysicsImpulse = 5;

	Template.iRange = 0;
	Template.BaseDamage = default.CLAWS_BASEDAMAGE;
	Template.Aim = default.CLAWS_AIM;
	Template.CritChance = default.CLAWS_CRITCHANCE;
	Template.iSoundRange = default.CLAWS_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.CLAWS_IENVIRONMENTDAMAGE;
	Template.BaseDamage.DamageType='Melee';

	Template.TradingPostValue = 35;

	Template.DamageTypeTemplateName = 'Melee';

	return Template;
}

static function X2DataTemplate AugmentationArms_Claws_Left_MG()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AugmentationArms_Claws_Left_MG');
	Template = X2WeaponTemplate(AugmentationBase(Template));

	Template.WeaponPanelImage = "_Pistol";                       // used by the UI. Probably determines iconview of the weapon.

	Template.ItemCat = 'augmentation_arms';
	Template.WeaponCat = 'cyberclaws';
	Template.WeaponTech = 'magnetic';
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_CyberClaws";
	Template.InventorySlot = eInvSlot_TertiaryWeapon;
	Template.StowedLocation = eSlot_Claw_L;
	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "CyberClaws_Augmentations.Archetypes.WP_Claws_Left_LG";
	Template.Tier = 2;

	Template.iRadius = 1;
	Template.iPhysicsImpulse = 5;

	Template.iRange = 0;
	Template.BaseDamage.DamageType='Melee';

	Template.DamageTypeTemplateName = 'Melee';

	return Template;
}

static function X2DataTemplate AugmentationArms_Grapple_MG()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AugmentationArms_Grapple_MG');
	Template = X2WeaponTemplate(AugmentationBase(Template));

	Template.ItemCat = 'augmentation_arms';
	Template.InventorySlot = eInvSlot_AugmentationArms;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Arm";

	Template.BaseDamage = default.CYBER_ARM_BASEDAMAGE;
	
	Template.BaseDamage = default.CYBER_ARM_BASEDAMAGE;
	Template.Abilities.AddItem('AugmentedShield');
	Template.Abilities.AddItem('CyberPunch');
	Template.Abilities.AddItem('GrapplePowered');
	
	Template.TradingPostValue = 35;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationArms_Launcher_BM()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AugmentationArms_Launcher_BM');
	Template = X2WeaponTemplate(AugmentationBase(Template));

	Template.ItemCat = 'augmentation_arms';
	Template.InventorySlot = eInvSlot_AugmentationArms;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Arm";

	Template.BaseDamage = default.CYBER_ARM_BASEDAMAGE;
	
	Template.Abilities.AddItem('AugmentedShield');
	Template.Abilities.AddItem('CyberPunch');
	
	Template.TradingPostValue = 50;
	Template.PointsToComplete = 0;
	Template.Tier = 3;

	return Template;
}

static function X2DataTemplate AugmentationTorso_BodyCompartment_MG()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'AugmentationTorso_BodyCompartment_MG');
	Template = X2ArmorTemplate(AugmentationBase(Template));

	Template.bAddsUtilitySlot = true;
	Template.ItemCat = 'augmentation_torso';
	Template.InventorySlot = eInvSlot_AugmentationTorso;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Torso";
	
	Template.Abilities.AddItem('AugmentationTorsoBase');

	Template.TradingPostValue = 35;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationTorso_NanoCoating_MG()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationTorso_NanoCoating_MG');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_torso';
	Template.InventorySlot = eInvSlot_AugmentationTorso;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Torso";
	
	Template.Abilities.AddItem('AugmentationTorsoBase');
	Template.Abilities.AddItem('NanoCoatingMK1');

	Template.TradingPostValue = 35;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationTorso_NanoCoating_BM()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationTorso_NanoCoating_BM');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_torso';
	Template.InventorySlot = eInvSlot_AugmentationTorso;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Torso";
	
	Template.Abilities.AddItem('AugmentationTorsoBase');
	Template.Abilities.AddItem('NanoCoatingMK2');

	Template.TradingPostValue = 50;
	Template.Tier = 3;

	return Template;
}


static function X2DataTemplate AugmentationLegs_JumpModule_MG()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationLegs_JumpModule_MG');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_legs';
	Template.InventorySlot = eInvSlot_AugmentationLegs;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Leg";
	
	Template.Abilities.AddItem('AugmentedSpeed');
	Template.Abilities.AddItem('CyberJumpMKOne');

	Template.TradingPostValue = 35;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationLegs_JumpModule_BM()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationLegs_JumpModule_BM');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_legs';
	Template.InventorySlot = eInvSlot_AugmentationLegs;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Leg";
	
	Template.Abilities.AddItem('AugmentedSpeed');
	Template.Abilities.AddItem('CyberJumpMKTwo');

	Template.TradingPostValue = 50;
	Template.Tier = 3;

	return Template;
}

static function X2DataTemplate AugmentationHead_NeuralGunlink_MG()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationHead_NeuralGunlink_MG');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_head';
	Template.InventorySlot = eInvSlot_AugmentationHead;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentations_Head";
	
	Template.Abilities.AddItem('AugmentedHead');
	Template.Abilities.AddItem('NeuralGunLink');
	
	Template.TradingPostValue = 35;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationHead_NeuralTacticalProcessor_BM()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationHead_NeuralTacticalProcessor_BM');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_head';
	Template.InventorySlot = eInvSlot_AugmentationHead;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentations_Head";
	
	Template.Abilities.AddItem('AugmentedHead');
	Template.Abilities.AddItem('NeuralTacticalProcessor');
	
	Template.TradingPostValue = 50;
	Template.PointsToComplete = 0;
	Template.Tier = 3;

	return Template;
}

static function X2DataTemplate AugmentationLegs_Muscles_MG()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationLegs_Muscles_MG');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_legs';
	Template.InventorySlot = eInvSlot_AugmentationLegs;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Leg";
	
	Template.Abilities.AddItem('AugmentedSpeed');
	Template.Abilities.AddItem('SyntheticLegMuscles');

	Template.TradingPostValue = 35;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationLegs_SilentRunners_BM()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationLegs_SilentRunners_BM');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_legs';
	Template.InventorySlot = eInvSlot_AugmentationLegs;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentation_Leg";
	
	Template.Abilities.AddItem('AugmentedSpeed');
	Template.Abilities.AddItem('Shadow');

	Template.TradingPostValue = 50;
	Template.Tier = 3;

	return Template;
}

static function X2DataTemplate AugmentationHead_WeakpointAnalyzer_MG()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationHead_WeakpointAnalyzer_MG');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_head';
	Template.InventorySlot = eInvSlot_AugmentationHead;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentations_Head";
	
	Template.Abilities.AddItem('AugmentedHead');
	Template.Abilities.AddItem('WeakpointAnalyzerMK1');
	
	Template.TradingPostValue = 35;
	Template.PointsToComplete = 0;
	Template.Tier = 2;

	return Template;
}

static function X2DataTemplate AugmentationHead_WeakpointAnalyzer_BM()
{
	local X2EquipmentTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, 'AugmentationHead_WeakpointAnalyzer_BM');
	Template = AugmentationBase(Template);

	Template.ItemCat = 'augmentation_head';
	Template.InventorySlot = eInvSlot_AugmentationHead;
	Template.strImage = "img:///UILibrary_Augmentations.Inv_Augmentations_Head";
	
	Template.Abilities.AddItem('AugmentedHead');
	Template.Abilities.AddItem('WeakpointAnalyzerMK2');
	
	Template.TradingPostValue = 50;
	Template.PointsToComplete = 0;
	Template.Tier = 3;

	return Template;
}



defaultproperties
{
	bShouldCreateDifficultyVariants = true
}