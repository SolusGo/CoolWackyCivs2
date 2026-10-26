-- Native generic modifier checks the battle plot on attack and defense.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,FriendlyLandsModifier,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_THRESHOLD_DEFENDER','TXT_KEY_THC_DEFENDER','TXT_KEY_THC_DEFENDER_HELP','AS2D_IF_LEVELUP',1,0,15,0,'THC_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_THC_DEFENDER');
-- OnlyDefensive prevents melee offense even with Blitz/restored movement; defense is normal.
INSERT INTO UnitPromotions(Type,Description,Help,Sound,CannotBeChosen,LostWithUpgrade,LostOnGifting,OnlyDefensive,PortraitIndex,IconAtlas,PediaType,PediaEntry)
 VALUES ('PROMOTION_THRESHOLD_EXHAUSTED','TXT_KEY_THC_EXHAUSTED','TXT_KEY_THC_EXHAUSTED_HELP','AS2D_IF_LEVELUP',1,0,0,1,1,'THC_PROMOTION_ATLAS','PEDIA_ATTRIBUTES','TXT_KEY_THC_EXHAUSTED');
INSERT INTO Unit_FreePromotions(UnitType,PromotionType) VALUES ('UNIT_THRESHOLD_HINGEGUARD','PROMOTION_THRESHOLD_DEFENDER');
UPDATE Building_YieldChanges SET Yield=Yield+1 WHERE BuildingType='BUILDING_THRESHOLD_HOUSE' AND YieldType='YIELD_CULTURE';
INSERT INTO Building_YieldChanges(BuildingType,YieldType,Yield) SELECT 'BUILDING_THRESHOLD_HOUSE','YIELD_CULTURE',1 WHERE NOT EXISTS(SELECT 1 FROM Building_YieldChanges WHERE BuildingType='BUILDING_THRESHOLD_HOUSE' AND YieldType='YIELD_CULTURE');
-- CP requires a per-type opt-in to dispatch CanMoveInto. This changes no unit
-- statistics/permissions. The veto returns true for every unmarked unit.
UPDATE Units SET SendCanMoveIntoEvent=1 WHERE Domain='DOMAIN_LAND' AND Combat>0;
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_FIRST_GREETING','TXT_KEY_THC_GREETING_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_DECLAREWAR','TXT_KEY_THC_WAR_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_ATTACKED','TXT_KEY_THC_ATTACKED_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_DEFEATED','TXT_KEY_THC_DEFEAT_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_PEACE_MADE_BY_HUMAN_GRACIOUS','TXT_KEY_THC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_PEACE_MADE_BY_HUMAN_UNGRACIOUS','TXT_KEY_THC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_PEACE_OFFER','TXT_KEY_THC_PEACE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_GREETING_POLITE_HELLO','TXT_KEY_THC_FRIENDLY_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_GREETING_NEUTRAL_HELLO','TXT_KEY_THC_NEUTRAL_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_GREETING_HOSTILE_HELLO','TXT_KEY_THC_HOSTILE_%',1);
INSERT INTO Diplomacy_Responses(LeaderType,ResponseType,Response,Bias) VALUES ('LEADER_QUEEN_ELSEWHERE','RESPONSE_TRADE_ACCEPT_GENEROUS','TXT_KEY_THC_TRADE_%',1);
