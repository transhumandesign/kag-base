
// Someday we'll have string support for enums :(
// Split between a few enums so func overloads understand whats going on
enum StatsNumber {
    Bomb_KT,
    Bomb_KC,

    Keg_KT,
    Keg_KC,
}

enum StatsBool {
    Bomb_KS,
    Bomb_S,

    KilledAs_Builder,
    KilledAs_Archer,
    KilledAs_Knight,

    TDM_OMA,
}


string[] InternalNumberStats = {
    "BombKillTime",
    "BombKillCount",

    "KegKillTime",
    "KegKillCount"
};

string[] InternalBoolStats = {
    "BombKillSuicide",
    "BombSuicide",

    "KilledAsBuilder",
    "KilledAsArcher",
    "KilledAsKnight",

    "TDM_OMA"
};


u32 GetStat(StatsNumber stat) {
    return getRules().get_u32(InternalNumberStats[stat]);
}

void SetStat(StatsNumber stat, u32 value) {
    getRules().set_u32(InternalNumberStats[stat], value);
}

void IncrementStat(StatsNumber stat) {
    SetStat(stat, GetStat(stat) + 1);
}

bool GetStat(StatsBool stat) {
    return getRules().get_bool(InternalBoolStats[stat]);
}

void SetStat(StatsBool stat, bool value) {
    getRules().set_bool(InternalBoolStats[stat], value);
}

