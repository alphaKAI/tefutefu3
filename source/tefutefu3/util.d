module tefutefu3.util;
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

  string readFile(string filePath){
   auto file = File(filePath, "r");
    string buf;

    foreach(line; file.byLine)
      buf = buf ~ cast(string)line;

    return buf;
  }

  
  void writeFile(string fileName, string text, string mode = "d"){
    if(mode == "d")
      mode = "a";
    File(fileName, mode).write(text);
  }

  string readSettingFile(){
    string settingFilePath = "config/setting.json";
    if(!exists(settingFilePath))
      throw new Exception("Please create file of config/setting.json and configure your consumer & access tokens");
    return readFile(settingFilePath);
  }

  string[] getCsvAsArray(string csv){
    return csv.split(",").map!(x => x.removechars(" ")).array;
  }

  string getJsonData(JSONValue parsedJson, string key){
    return parsedJson.object[key].to!string.replaceAll(regex("\"", "g") ,"");
  }
  
  string getJsonDataWithPath(JSONValue data, string path){
    return path.split("/").length == 0 ? data.to!string : getJsonDataWithPath(data.object[path.split("/")[0]], path.split("/")[1..$].join("/"));
  }

  JSONValue getJsonValueData(JSONValue data, string key){
    return data.object[key];
  }

  string[] getJsonArrayData(JSONValue parsedJson, string key){
    string[] array;
    foreach(size_t index, value; parsedJson.object[key])
      array ~= value.to!string.replaceAll(regex("\"", "g") ,"");
    return array;
  }

  string currentTime(){
    auto currentTime = Clock.currTime;
    with(currentTime)
      return year.to!string ~ "年" ~ (cast(int)month).to!string ~ "月" ~ day.to!string ~ "日" ~ hour.to!string ~ "時" ~ minute.to!string ~ "分" ~ second.to!string ~ "秒";
  }
  
  string convWithPattern(string str, string[string] convList){
   foreach(key, val; convList)
      str = str.replaceAll(regex(r"" ~ key, "g"), val);
    return str;
  }

  bool find(T)(T key, T[] array){
    foreach(e; array)
      if(e == key)
        return true;
    return false;
  }
}
