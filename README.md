
#AI for Games III course project

A bot team for Heroes of Newerth. 

Course page: http://tkt-hon.github.io/midwars/

HoN Bot Repository for reference: https://github.com/honteam/Heroes-of-Newerth-Bots


# tkt-hon Midwars Tourney

Use the following command to start midwars match. It will reset the state and enable variables to support all the features.

    Alias "create_midwars_botmatch" "set teambotmanager_legion; set teambotmanager_hellbourne; StartGame practice tournament mode:botmatch map:midwars teamsize:5 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000; g_perks true;"

## Teams

### Default bots by organizers

    Alias "team_default_legion" "set teambotmanager_legion default; AddBot 1 Default_Devourer; AddBot 1 Default_MonkeyKing; AddBot 1 Default_Nymphora; AddBot 1 Default_PuppetMaster; AddBot 1 Default_Valkyrie"

    Alias "team_default_hellbourne" "set teambotmanager_hellbourne default; AddBot 2 Default_Devourer; AddBot 2 Default_MonkeyKing; AddBot 2 Default_Nymphora; AddBot 2 Default_PuppetMaster; AddBot 2 Default_Valkyrie"

### RETK
    Alias "team_retk_legion" "set teambotmanager_legion retk; AddBot 1 RETK_Devourer; AddBot 1 RETK_MonkeyKing; AddBot 1 RETK_Nymphora; AddBot 1 RETK_PuppetMaster; AddBot 1 RETK_Valkyrie"

    Alias "team_retk_hellbourne" "set teambotmanager_hellbourne retk; AddBot 2 RETK_Devourer; AddBot 2 RETK_MonkeyKing; AddBot 2 RETK_Nymphora; AddBot 2 RETK_PuppetMaster; AddBot 2 RETK_Valkyrie"

### MidXORFeed

    Alias "team_MidXORFeed_legion" "set teambotmanager_legion mid_xor_feed; AddBot 1 MidXORFeed_Valkyrie; AddBot 1 MidXORFeed_Devourer; AddBot 1 MidXORFeed_PuppetMaster; AddBot 1 MidXORFeed_Nymphora; AddBot 1 MidXORFeed_MonkeyKing;"

    Alias "team_MidXORFeed_hellbourne" "set teambotmanager_hellbourne mid_xor_feed; AddBot 2 MidXORFeed_Valkyrie; AddBot 2 MidXORFeed_Devourer; AddBot 2 MidXORFeed_PuppetMaster; AddBot 2 MidXORFeed_Nymphora; AddBot 2 MidXORFeed_MonkeyKing;"

### xxx_CodeEveryDay420_xxx by Aleksi, Atte, Jesse

    Alias "team_xxx_legion" "set teambotmanager_legion xxx_CodeEveryDay420_xxx; AddBot 1 xxx_CodeEveryDay420_xxx_Devourer; AddBot 1 xxx_CodeEveryDay420_xxx_MonkeyKing; AddBot 1 xxx_CodeEveryDay420_xxx_Nymphora; AddBot 1 xxx_CodeEveryDay420_xxx_PuppetMaster; AddBot 1 xxx_CodeEveryDay420_xxx_Valkyrie"

    Alias "team_xxx_hellbourne" "set teambotmanager_hellbourne xxx_CodeEveryDay420_xxx; AddBot 2 xxx_CodeEveryDay420_xxx_Devourer; AddBot 2 xxx_CodeEveryDay420_xxx_MonkeyKing; AddBot 2 xxx_CodeEveryDay420_xxx_Nymphora; AddBot 2 xxx_CodeEveryDay420_xxx_PuppetMaster; AddBot 2 xxx_CodeEveryDay420_xxx_Valkyrie"

### TietokoneJoukkueParas

    Alias "team_TietokoneJoukkueParas_legion" "set teambotmanager_legion TietokoneJoukkueParas_team; AddBot 1 TietokoneJoukkueParas_Devourer; AddBot 1 TietokoneJoukkueParas_MonkeyKing; AddBot 1 TietokoneJoukkueParas_Nymphora; AddBot 1 TietokoneJoukkueParas_PuppetMaster; AddBot 1 TietokoneJoukkueParas_Valkyrie"

    Alias "team_TietokoneJoukkueParas_hellbourne" "set teambotmanager_hellbourne TietokoneJoukkueParas_team; AddBot 2 TietokoneJoukkueParas_Devourer; AddBot 2 TietokoneJoukkueParas_MonkeyKing; AddBot 2 TietokoneJoukkueParas_Nymphora; AddBot 2 TietokoneJoukkueParas_PuppetMaster; AddBot 2 TietokoneJoukkueParas_Valkyrie"
