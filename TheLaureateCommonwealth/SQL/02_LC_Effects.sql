-- Native wounded-unit attack and post-combat military kill healing.
INSERT INTO UnitPromotions(Type,Description,Help,AttackWoundedMod,HPHealedIfDestroyEnemy,LostWithUpgrade,CannotBeChosen,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_CROWNING_BLOW','TXT_KEY_LAUREATE_CROWN','TXT_KEY_LAUREATE_CROWN_HELP',15,15,0,1,0,'LAUREATE_OBJECT_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LAUREATE_CROWN');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_LAUREATE_CHAMPION','PROMOTION_CROWNING_BLOW');
INSERT INTO UnitPromotions(Type,Description,Help,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_LAUREL_LEVEL_REWARDED','TXT_KEY_LAUREATE_VETERAN','TXT_KEY_LAUREATE_VETERAN_HELP',0,0,1,0,0,'LAUREATE_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LAUREATE_VETERAN');
INSERT INTO UnitPromotions(Type,Description,Help,LostWithUpgrade,LostOnGifting,CannotBeChosen,ShowInUnitPanel,PortraitIndex,IconAtlas,PediaType,PediaEntry) VALUES ('PROMOTION_LC_PERSON_RECOGNIZED','TXT_KEY_LAUREATE_GP_MARK','TXT_KEY_LAUREATE_GP_MARK_HELP',0,0,1,0,0,'LAUREATE_CIV_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_LAUREATE_GP_MARK');
-- CP IsDummy excludes this policy from policy counts. No branch makes it unselectable.
INSERT INTO Policies(Type,Description,Help,IsDummy,GreatPeopleRateModifier,ExpModifier,PortraitIndex,IconAtlas,IconAtlasAchieved)
 VALUES ('POLICY_LC_GOLDEN_EXCELLENCE','TXT_KEY_LAUREATE_POLICY','TXT_KEY_LAUREATE_POLICY_HELP',1,15,15,0,'LAUREATE_CIV_ATLAS','LAUREATE_CIV_ATLAS');
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_FIRST_GREETING','TXT_KEY_LAUREATE_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_DECLAREWAR','TXT_KEY_LAUREATE_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_ATTACKED','TXT_KEY_LAUREATE_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_DEFEATED','TXT_KEY_LAUREATE_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_LAUREATE_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_LAUREATE_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_PEACE_OFFER','TXT_KEY_LAUREATE_PEACE_OFFER_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_LAUREATE_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_LAUREATE_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_LAUREATE_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_LAUREATE_TRADE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_LAUREA','RESPONSE_TRADE_ACCEPT_ACCEPTABLE','TXT_KEY_LAUREATE_TRADE_%',1);
UPDATE Leader_Flavors SET Flavor=8 WHERE LeaderType='LEADER_LAUREA' AND FlavorType IN ('FLAVOR_CULTURE','FLAVOR_WONDER','FLAVOR_GREAT_PEOPLE');
