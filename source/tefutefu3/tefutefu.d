module tefutefu3.tefutefu;
import twitter4d;
import std.algorithm,
       std.datetime,
       std.string,
       std.stdio,
       std.regex,
       std.array,
       std.file,
       std.json,
       std.conv;
import core.thread;
import tefutefu3.reply,
       tefutefu3.status,
       tefutefu3.util;

class Tefutefu{
  mixin Util;

  struct TwitterBot{
    string botID;
    string[] functions;
    string[] friends;
  }

  //Define class vals
  private{
    Twitter4D  t4d;
    TwitterBot tefutefu;
    EventReply eventReply;
    Reply      reply;
    bool firstTime = true;
    string[] admins;
  }

  this(){
    JSONValue setting = parseJSON(readFile("config/setting.json"));
    if("admins" in setting.object)
      admins = getJsonArrayData(setting, "admins");
    t4d               = new Twitter4D(readConfig);
    eventReply        = new EventReply;
    reply             = new Reply(t4d, admins);
    tefutefu.botID    = getJsonData(parseJSON(t4d.request("GET", "account/verify_credentials.json")), "screen_name");

    if(admins.length){
      writeln("admins");
      foreach(admin; admins)
        writeln("  - @", admin);
    }
  }

  void start(){
    writeln("[BOOT] - ", currentTime);
    tweet(eventReply.get("boot", ["DATE" : currentTime]));
    foreach(status; t4d.stream){
      //get friends data from data at firsttime
      if(firstTime && status.to!string.match(regex(r"\{.*\}"))
                   && status.to!string.match(regex(r"friends"))){
        tefutefu.friends = getJsonArrayData(parseJSON(status.to!string), "friends").dup;
        firstTime = false;
      } else if(status.to!string.match(regex(r"\{.*\}"))){
        Status argStatus = new Status(parseJSON(status.to!string));
        new core.thread.Thread(() => processStatus(argStatus)).start;
      }
    }
  }

  //tefutefu core
  private{
    void processStatus(Status status){
      if("event" == status.kind)
        processEvent(status);
      else if("status" == status.kind && find(status.user["id_str"], tefutefu.friends)){
        if(status.isReply(tefutefu.botID)){
          writeln("[Reply recived] @" ~ status.user["screen_name"] ~ " -> @" ~ tefutefu.botID ~ " : " ~ status.text);
          sendReply(status);
        } else {
          reply.parseStatus(status);
          writeln("[", status.kind ,"] [@", status.user["screen_name"], " - ", status.text, "]");
        }
      }
    }

    void processEvent(Status status){
      writeln("[event - ", status.event, "] ", status.source["screen_name"], " -> ", status.target["screen_name"]);
      switch(status.event){
        default: break;
      }
    }

    void sendReply(Status status){
      bool execed;
      if(find(status.user["screen_name"], admins)){//ifAdmin
        switch(status.text.split[1]){
          case "say":
            writeln("[admin command] - say : ", status.text.split[2..$].join);
            tweet("管理者より " ~ status.text.split[2..$].join);
            execed = true;
            break;
          case "stop":
            writeln("[admin command] - stop ", currentTime);
            tweet(eventReply.get("stop", ["DATE" : currentTime]));
            //Todo: exit
            execed = true;
            break;
          //Todo : reboot
          default: break;
        }
      }

      if(!execed)
        reply.replyParse(status);
    }
  }

  //Twitter API
  private{
    void tweet(string text, string inReplyToStatusId = null){
      if(inReplyToStatusId == null)
        t4d.request("POST", "statuses/update.json", ["status" : text]);
      else
        t4d.request("POST", "statuses/update.json", ["status"                : text,
                                                     "in_reply_to_status_id" : inReplyToStatusId]);
    }

    void follow(string target){
      t4d.request("POST", "friendships/create.json", ["screen_name" : target]);
    }

    void unfollow(string target){
      t4d.request("POST", "friendships/destroy.json", ["screen_name" : target]);
    }
  }
}
