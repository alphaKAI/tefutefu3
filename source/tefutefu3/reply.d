module tefutefu3.reply;
import twitter4d;
import std.conv,
       std.json,
       std.file,
       std.regex,
       std.stdio,
       std.array,
       std.string,
       std.random,
       std.datetime,
       std.algorithm;
import tefutefu3.util,
       tefutefu3.status;
import weatherd;

class EventReply{
  mixin Util;

  static string[] keys = ["follow",
                          "reboot",
                          "boot",
                          "stop"];
  string[string] lists;

  this(){
    bool[string] result;
    auto node     = parseJSON(readFile("resource/script.json")),
         defaults = parseJSON(readFile("resource/defaults.json"));

    foreach(key; keys)
      result[key] = key in node.object ? true : false;

    foreach(key, val; result)
      lists[key] = val ? node.object[key].to!string.removechars("\"") : defaults.object.to!string.removechars("\"");
  }

  string get(string method, string[string]convList = null)
  in {
    assert(method in lists);
  } body {
    string str = lists[method];

    return convWithPattern(str, convList);
  }
}

class Reply{
  mixin Util;

  static string[] funcs = ["weather",
                           "omikuji",
                           "study"];
  string[string][string] replyPattern,
                         reactionPattern;
  string blackListPath = "resource/blackList.csv",
         studyFilePath = "resource/study.csv",
         tweetFilePath = "resource/tweet.csv";
  string[] functions,
           blackList,
           studyList;
  Twitter4D t4d;
  WeatherD weather;

  struct Weather{
    string place,
           date,
           weather,
           tempMax,
           tempMin;
  }

  this(Twitter4D twitter4dInstance){
    JSONValue replys    = parseJSON(readFile("resource/replyPatterns.json")),
              reactions = parseJSON(readFile("resource/reactionPatterns.json"));
    functions = replys.object.keys ~ reactions.object.keys ~ funcs;

    foreach(key; replys.object.keys){
      foreach(ename; ["regex", "text"])
        replyPattern[key][ename] = replys.object[key].object[ename].to!string.removechars("\"").removechars("\\");
    }

    foreach(key; reactions.object.keys){
      foreach(ename; ["regex", "text"])
        reactionPattern[key][ename] = reactions.object[key].object[ename].to!string.removechars("\"").removechars("\\");
    }

    t4d = twitter4dInstance;
    weather = new WeatherD;

    if(!exists(blackListPath))
      writeFile(blackListPath, "");
    if(!exists(studyFilePath))
      writeFile(studyFilePath, "");

    blackList = getCsvAsArray(readFile(blackListPath));
    studyList = getCsvAsArray(readFile(studyFilePath));
  }

  void parseStatus(Status status){
   writeln("[start parseStatus]");
    foreach(pattern; replyPattern){
      if(status.text.match(regex(r"@")) || status.text.match(regex(r"^@"))){
        writeln("[parseStatus] - Ignore this status");
      } else {
        writeln("[parseStatus] - [check pattern] => ", pattern);
        if(match(status.text, regex(r"" ~ convWithPattern(pattern["regex"], ["BOTNAME" : "てふてふ"]).removechars("/")))){
          writeln("[parseStatus] -> found pattern => ", pattern);
          writeln("@" ~ status.user["screen_name"] ~ " " ~ convWithPattern(pattern["text"], ["USERNAME" : status.user["name"]]), status.in_reply_to_status_id);
          tweet("@" ~ status.user["screen_name"] ~ " " ~ convWithPattern(pattern["text"], ["USERNAME" : status.user["name"]]), status.in_reply_to_status_id);
        }
      }
    }
  }

  void replyParse(Status status){
    writeln("[start replyParse]");
    foreach(pattern; reactionPattern){
      writeln("[replyParse] - [check pattern] => ", pattern);
      if(match(status.text, regex(r"" ~ convWithPattern(pattern["regex"], ["BOTNAME" : "てふてふ"]).removechars("/")))){
        writeln("[replyParse] -> found pattern => ", pattern);
        tweet("@" ~ status.user["screen_name"] ~ " " ~ convWithPattern(pattern["text"], ["USERNAME" : status.user["name"]]));
        break;
      }
    }

    if(status.text.match(regex(r"(今日|明日|明後日)?.*天気"))){//weather
      writeln("[parseStatus] -> [weather]");
      string pref,
             city;
      bool findFlag;

      foreach(ePref, cities; weather.prefs){
        foreach(eCity; cities.keys){
          if(match(status.text, regex(r"" ~ eCity))){
            pref = ePref;
            city = eCity;
            findFlag = true;
            break;
          }
          if(findFlag)
            break;
        }
      }

      if(!findFlag){//NotFound the place
        tweet("@" ~ status.user["screen_name"] ~ "地名が登録されていないよ！><", status.in_reply_to_status_id);
      } else {
        string[] dateLabels = ["今日", "明日", "明後日"];
        string dateLabel    = "今日";
        Weather weatherStruct;
        foreach(date; dateLabels){
          if(match(status.text, regex(r"" ~ date))){
            dateLabel = date;
            break;
          }
        }

        foreach(forecast; getJsonValueData(weather.getWeatherData(pref, city), "forecasts").array){
          if(getJsonData(forecast, "dateLabel") == dateLabel){
            weatherStruct.place = pref ~ city;
            weatherStruct.date  = dateLabel ~ "(" ~ getJsonData(forecast, "date") ~ ")";
            weatherStruct.weather = getJsonData(forecast, "telop");
            weatherStruct.tempMax = getJsonDataWithPath(forecast, "temperature/max") == "null"
              ? "null" : getJsonDataWithPath(forecast, "temperature/max/celsius");
            weatherStruct.tempMin = getJsonDataWithPath(forecast, "temperature/min") == "null"
              ? "null" : getJsonDataWithPath(forecast, "temperature/min/celsius");
          }

          //generateTweet
          tweet("@" ~  status.user["screen_name"] ~ " " ~ weatherStruct.place ~ "の" ~ weatherStruct.date ~ "の天気は" ~ weatherStruct.weather
              ~ (weatherStruct.tempMax == "null" || weatherStruct.tempMin == "null"
              ? "です♪" : "で 最高気温/最低気温は" ~ weatherStruct.tempMax ~ "/" ~ weatherStruct.tempMin ~ " です♪"), status.in_reply_to_status_id);
        }
      }
    } else if(match(status.text, regex(r"おみくじ"))){
      writeln("[parseStatus] -> omikuji");
      Mt19937 mt;
      string result;

      mt.seed(unpredictableSeed);

      switch(mt.front % 20 + 1){
        case 1: .. case 2:
                result = "大吉です！ おめでとうございます♪";
                break;
        case 3: .. case 4:
                result = "大凶です (´・ω・`)。 ドンマイ！";
                break;
        case 5: .. case 8:
                result = "中吉です！";
                break;
        case 9: .. case 12:
                result = "吉です！";
                break;
        case 13: .. case 17:
                 result = "末吉です";
                 break;
        case 18: .. case 20:
                 result = "凶です ドンマイ！";
                 break;
        default: break;
      }

      tweet("@" ~ status.user["screen_name"] ~ " " ~ result, status.in_reply_to_status_id);
    } else if(status.text.match(regex(r"study"))){
      string newWord = status.text.split("study")[$ - 1][1..$];//[1..$] means : delete space
      if(newWord.length == 0){
        tweet(convWithPattern("@USERNAME 空白は学習できないの！ ごめんね！", ["USERNAME" : status.user["screen_name"]]), status.in_reply_to_status_id);
        return;
      }

      foreach(elem; blackList){
        if(newWord.match(regex(r"" ~ elem))){
          tweet(convWithPattern("@USERNAME ブラックリストに含まれる単語が含まれていたので破棄しました！ ごめんなさい！", ["USERNAME" : status.user["screen_name"]]), status.in_reply_to_status_id);
          return;
        }
      }

      foreach(elem; studyList){
        if(newWord.match(regex(r"" ~ elem))){
          tweet(convWithPattern("@USERNAME その単語はすでに学習済みでした！", ["USERNAME" : status.user["screen_name"]]), status.in_reply_to_status_id);
          return;
        }
      }

      writeln("[study] - ", newWord);
      writeFile(studyFilePath, ", " ~ newWord);
      tweet(convWithPattern("@USERNAME \"" ~ newWord ~ "\" 学習したよっ♪", ["USERNAME" : status.user["screen_name"]]), status.in_reply_to_status_id);
      studyList = getCsvAsArray(readFile(studyFilePath));
    } else {
      Mt19937 mt;
      mt.seed(unpredictableSeed);
      writeln("[default]");
      tweet(convWithPattern("@USERNAME " ~ studyList[mt.front % studyList.length + 1], ["USERNAME" : status.user["screen_name"]]), status.in_reply_to_status_id);
    }
  }

  private{
    void tweet(string text, string inReplyToStatusId = null){
      writeln("[tweet] : " ~ text);
      if(inReplyToStatusId == null)
        t4d.request("POST", "statuses/update.json", ["status" : text]);
      else
        t4d.request("POST", "statuses/update.json", ["status"                : text,
                                                     "in_reply_to_status_id" : inReplyToStatusId]);
    }
  }
}
