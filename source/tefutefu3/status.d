module tefutefu3.status;
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
import tefutefu3.util;

class Status{
  mixin Util;
  string kind;//event or status
  string text,
         in_reply_to_status_id;
  string event;
  bool _protected;
  string[string] user;
  string[string] source;
  string[string] target;

  this(JSONValue json){
    user = ["name"        : "",
            "screen_name" : "",
            "id_str"      : ""];
    source = user.dup;
    target = user.dup;

    if("event" in json.object){
      kind  = "event";
      event  = getJsonData(json, "event");

      foreach(key; source.keys)
        source[key] = key in json.object["source"].object ? json.object["source"].object[key].str : "null";
      foreach(key; target.keys)
        target[key] = key in json.object["target"].object ? json.object["target"].object[key].str : "null";

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
