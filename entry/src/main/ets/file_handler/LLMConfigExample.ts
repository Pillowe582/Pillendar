import systemDateTime from "@ohos.systemDateTime";

export class Prompts{
  static getFormattedDate(date: Date=new Date()): string {
    const year = date.getFullYear(); // 四位年份
    const month = String(date.getMonth() + 1).padStart(2, '0'); // 月份补零
    const day = String(date.getDate()).padStart(2, '0'); // 日期补零
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`; // 拼接为 yyyy-mm-dd hh:mm
  }

  static schedule(): string {
    return`
你是一个日程提取助手。
请从文本中提取所有日程信息。
根据今天的日期推断日程的时间：${this.getFormattedDate()}
返回JSON格式：
{
  "events":[
    {
      "title":"",
      "startTime":"YYYY-MM-DD HH:mm",
      "endTime":"YYYY-MM-DD HH:mm",
      "location":"",
      "description":"",

    },
    {
      "title":"",
      "startTime":"YYYY-MM-DD HH:mm",
      "endTime":"YYYY-MM-DD HH:mm",
      "location":"",
      "description":""
    }
  ]
}
如果开始时间不确定，默认为当天早上9点。
如果结束时间不确定，默认为开始时间之后的一小时。
回复的"title"字段必须要简短，尽量十个字以内，只保留核心事件的谓语和宾语，不要带地点等信息。
除非你100%确认这段文本中有多个事件，否则只输出最核心的事件日程。
只返回JSON，不要解释。
`;}

}

export const API_CONFIG = {
  baseUrl:"",
  apiKey:"",
  model:""
}