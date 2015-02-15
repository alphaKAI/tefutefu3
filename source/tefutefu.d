import twitter4d;
import std.stdio,
       std.regex,
       std.array,
       std.file,
       std.json,
       std.conv;
import core.thread;
import reply,
       status,
       util,
       plugin;

class Tefutefu{
  mixin TefutefuReply;
  mixin Util;
  mixin StatusTemplate;

  struct TwitterBot{
    string botID;
    string[] functions;
    string[] friends;
  }
  
  //Define class vals
  private{
    Twitter4D t4d;
    TwitterBot tefutefu;
    bool firstTime = true;
  }

  this(){
    string[string] setting = readConfig;
    t4d = new Twitter4D(setting);
    tefutefu.botID = getJsonData(parseJSON(t4d.request("GET", "account/verify_credentials.json")), "screen_name");
  }

  void start(){
    foreach(status; t4d.stream){
      //get friends data from data at firsttime
      if(firstTime && status.to!string.match(regex(r"\{.*\}")) && status.to!string.match(regex(r"friends"))){
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
      else if("status" == status.kind){ 
        if(status.isReply(tefutefu.botID)){//ifReply
          sendReply(status);
        } else {
          //debug
          //writeln("[", status.kind ,"] [@", status.user["screen_name"], " - ", status.text, "]");
        }
      }
    }

    void processEvent(Status status){
      writeln("[event - ", status.event, "] ", status.source, " -> ", status.target);
      final switch(status.kind){
        case "follow":
          if(status.target == tefutefu.botID){
            writeln("[event - AUTO Folloback] ", tefutefu.botID, " -> ", status.target);
            //t4d.request("POST", "friendships/create.json", ["screen_name" : status.source]);
            //t4d.request("POST", "statuses/update.json", ["status" : "@" ~ status.target ~ " さん フォローありがとう！ これからよろしくお願いしますっ！"]);
            //Idea : フォロー返すときなどのメッセージをscript.yamlに定義してそれを読む
          }
          break;
        case "unfollow":
          if(status.target == tefutefu.botID){
            writeln("[event - AUTO Remove]", tefutefu.botID, " -> ", status.target);
            //t4d.request("POST", "friendships/destroy.json", ["screen_name" : status.source]);
          }
          break;
      }
    }

    void sendReply(Status status){
      
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
  }
}
