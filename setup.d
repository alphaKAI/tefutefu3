import std.stdio,
       std.file;

void main(){
  writeln("Tefuftefu3 Setup Script");
  writeln("Copyright (c) 2015 alphaKAI http://alpha-kai-net.info");

  if(!exists("config")){
    writeln("[PROCESS] => Make Directory \'./config\'");
    mkdir("config");
  }

  if(!exists("config/setting.json")){
    writeln("[PROCESS] => Create File \'./config/setting.json\'");
    auto f = File("setting.json", "w");
    string fileLines[] = [
      "{",
        "  \"consumerKey\"       : \"Your Consumer Key\",",
        "  \"consumerSecret\"    : \"Your Consumer Secret\",",
        "  \"accessToken\"       : \"Your Access Token\",",
        "  \"accessTokenSecret\" : \"Your Access Token Secret\",",
        "  \"admins\"            : []\"",
      "}"];
    
    foreach(line; fileLines)
      f.writeln(line);

    writeln("Please configure your consumer & access tokens");
  }

  writeln("Setup finished");
  writeln("Before next step : You must configure \'./config/setting.json\'");
  writeln("Next step :");
  writeln(" $ dub");
  writeln("    => Tefutefu will be being build and launched");
}
