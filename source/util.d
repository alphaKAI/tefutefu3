import std.json,
       std.file,
       std.regex,
       std.traits;

mixin template Util(){
 string[string] readConfig(){
      string[string] hash;
      auto setting = readSettingFile;
      auto parsed  = parseJSON(setting);
      hash = ["consumerKey"       : getJsonData(parsed, "consumerKey"),
              "consumerSecret"    : getJsonData(parsed, "consumerSecret"),
              "accessToken"       : getJsonData(parsed, "accessToken"),
              "accessTokenSecret" : getJsonData(parsed, "accessTokenSecret")];
      return hash;
    }

    string readSettingFile(){
      string settingFilePath = "config/setting.json";
      if(!exists(settingFilePath))
        throw new Error("Please create file of config/setting.json and configure your consumer & access tokens");

      auto file = File(settingFilePath, "r");
      string buf;

      foreach(line; file.byLine)
        buf = buf ~ cast(string)line;

      return buf;
    }

    string getJsonData(JSONValue parsedJson, string key){
      return parsedJson.object[key].to!string.replaceAll(regex("\"", "g") ,"");
    }
    string[] getJsonArrayData(JSONValue parsedJson, string key){
      string[] array;
      foreach(size_t index, value; parsedJson.object[key])
        array ~= value.to!string.replaceAll(regex("\"", "g") ,"");
      return array;
    }
}
