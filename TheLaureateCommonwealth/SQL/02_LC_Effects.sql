-- Native wounded-unit attack and post-combat military kill healing.
INSERT INTO UnitPromotions(Type,Description,Help,AttackWoundedMod,HPHealedIfDestroyEnemy,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_CROWNING_BLOW','TXT_KEY_LC_CROWN','TXT_KEY_LC_CROWN_HELP',15,15,0,1,0,'LC_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LC_CROWN');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_LAUREATE_CHAMPION','PROMOTION_CROWNING_BLOW');
INSERT INTO UnitPromotions(Type,Description,Help,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType) VALUES ('PROMOTION_LAUREL_LEVEL_REWARDED','TXT_KEY_LC_VETERAN','TXT_KEY_LC_VETERAN_HELP',0,0,1,0,0,'LC_CIV_ATLAS','PEDIA_ATTRIBUTES');
INSERT INTO UnitPromotions(Type,Description,Help,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType) VALUES ('PROMOTION_LC_PERSON_RECOGNIZED','TXT_KEY_LC_GP_MARK','TXT_KEY_LC_GP_MARK_HELP',0,0,1,0,0,'LC_CIV_ATLAS','PEDIA_ATTRIBUTES');
-- CP IsDummy excludes this policy from policy counts. No branch makes it unselectable.
INSERT INTO Policies(Type,Description,Help,IsDummy,GreatPeopleRateModifier,ExpModifier,PortraitIndex,IconAtlas,IconAtlasAchieved)
 VALUES ('POLICY_LC_GOLDEN_EXCELLENCE','TXT_KEY_LC_POLICY','TXT_KEY_LC_POLICY_HELP',1,15,15,0,'LC_CIV_ATLAS','LC_CIV_ATLAS');
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_FIRST_GREETING','TXT_KEY_LC_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_DECLAREWAR','TXT_KEY_LC_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_ATTACKED','TXT_KEY_LC_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_DEFEATED','TXT_KEY_LC_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_LC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_LC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_OFFER','TXT_KEY_LC_PEACE_OFFER_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_LC_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_LC_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_LC_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_LC_TRADE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_TRADE_ACCEPT_ACCEPTABLE','TXT_KEY_LC_TRADE_%',1);
UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='LEADER_LAUREA' AND FlavorType IN ('FLAVOR_CULTURE','FLAVOR_WONDER','FLAVOR_GREAT_PEOPLE');
