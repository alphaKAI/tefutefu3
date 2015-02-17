import std.json,
       std.conv,
       std.regex;
import util;

mixin template StatusTemplate(){
  class Status{
    mixin Util;
    string kind;//event or status
    bool forMe;//flag of event target
    string id,
           text,
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
        target = getJsonData(json.object["target"], "screen_name");
        source = getJsonData(json.object["source"], "screen_name");
      } else if("text" in json.object){
        kind = "status"; 
        foreach(key; user.keys)
          user[key] = key in json.object["user"].object ? getJsonData(json.object["user"], key) : "null";
        in_reply_to_status_id = getJsonData(json, "in_reply_to_status_id_str");
        text                  = getJsonData(json, "text");
        id                    = getJsonData(json, "id_str");
        _protected            = getJsonData(json.object["user"], "protected").to!bool;
      }
    }

    bool isReply(string botID){
      return text.match(r"^@" ~ botID) ? true : false;
    }
  }
}
