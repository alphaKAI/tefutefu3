import std.json,
       std.conv,
       std.regex;
import std.algorithm,
       std.datetime,
       std.string,
       std.stdio,
       std.regex,
       std.array,
       std.file,
       std.json,
       std.conv;
import util;

class Status{
  mixin Util;
  string kind;//event or status
  string text,
         in_reply_to_status_id;
  string event,
         target,
         source;           
  bool _protected;
  string[string] user;

  this(JSONValue json){
    user = ["name"        : "",
            "screen_name" : "",
            "id_str"      : ""];

    if("event" in json.object){
      kind  = "event";
      event  = getJsonData(json, "event");
      target = json.object["target"].object["screen_name"].str;
      source = json.object["source"].object["screen_name"].str;
    } else if("text" in json.object){
      kind = "status"; 
      foreach(key; user.keys)
        user[key] = key in json.object["user"].object ? json.object["user"].object[key].str : "null";
      in_reply_to_status_id = getJsonData(json, "id_str");
      text                  = json.object["text"].str;
      _protected            = getJsonData(json.object["user"], "protected").to!bool;
    }
  }

  bool isReply(string botID){
    return text.match(regex(r"^@" ~ botID)).empty ? false: true;
  }
}
