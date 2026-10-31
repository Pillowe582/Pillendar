import { LLMSettings } from '../data_types/LLMSettings';

// 大模型默认配置与请求体构造：配置项由设置页修改，prompt 与请求 JSON 支持占位符

export const DEFAULT_LLM_SETTINGS: LLMSettings = {
  baseUrl: 'https://api.deepseek.com/chat/completions',
  apiKey: '',
  model: 'deepseek-flash',
  prompt: `你是一个日程提取助手。
请从文本中提取所有日程信息。
根据今天的日期**准确推断**日程的时间：{{now}}，{{weekday}}
返回JSON格式：
{
  "events":[
    {
      "title":"",
      "startTime":"YYYY-MM-DD HH:mm",
      "endTime":"YYYY-MM-DD HH:mm",
      "location":"",
      "description":""
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
只返回JSON，不要解释。`,
  requestJson: `{
  "model": "{{model}}",
  "messages": [
    {
      "role": "system",
      "content": "{{prompt}}"
    },
    {
      "role": "user",
      "content": "{{message}}"
    }
  ],
  "thinking": {
    "type": "enabled"
  },
  "reasoning_effort": "high",
  "response_format": {
    "type": "json_object"
  }
}`
};

/**
 * 构造大模型请求体
 * @param settings 当前大模型配置
 * @param message 用户文本，如 OCR 识别结果
 * @returns 占位符替换完成的 JSON 字符串
 */
export function buildRequestBody(settings: LLMSettings, message: string): string {
  const now = new Date();
  const variables: Record<string, string> = {
    now: Prompts.getFormattedDate(now),
    weekday: Prompts.getWeekday(now),
    model: settings.model,
    message: message,
    prompt: ''
  };

  // prompt 先展开日期占位符，再整体替换进请求 JSON
  variables.prompt = fillTemplate(settings.prompt, { now: variables.now, weekday: variables.weekday });

  const requestObject = JSON.parse(settings.requestJson);
  return JSON.stringify(fillTemplateDeep(requestObject, variables));
}

/**
 * 校验请求 JSON 是否为合法 JSON
 * @param requestJson 请求 JSON 文本
 */
export function isRequestJsonValid(requestJson: string): boolean {
  try {
    JSON.parse(requestJson);
    return true;
  } catch (err) {
    return false;
  }
}

// 替换字符串中的 {{占位符}}，未知占位符保持原样
function fillTemplate(text: string, variables: Record<string, string>): string {
  return text.replace(/\{\{(\w+)\}\}/g, (match: string, name: string) => variables[name] ?? match);
}

// 递归替换对象与数组中所有字符串的占位符
function fillTemplateDeep(value: any, variables: Record<string, string>): any {
  if (typeof value === 'string') {
    return fillTemplate(value, variables);
  }
  if (Array.isArray(value)) {
    return value.map((item) => fillTemplateDeep(item, variables));
  }
  if (value !== null && typeof value === 'object') {
    const result: Record<string, any> = {};
    Object.keys(value).forEach((key: string) => {
      result[key] = fillTemplateDeep(value[key], variables);
    });
    return result;
  }
  return value;
}

export class Prompts {
  /**
   * 返回星期名称
   * @param date 日期，默认当前时间
   */
  static getWeekday(date: Date = new Date()): string {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[date.getDay()];
  }

  /**
   * 返回 yyyy-mm-dd hh:mm 格式的时间
   * @param date 日期，默认当前时间
   */
  static getFormattedDate(date: Date = new Date()): string {
    const year = date.getFullYear(); // 四位年份
    const month = String(date.getMonth() + 1).padStart(2, '0'); // 月份补零
    const day = String(date.getDate()).padStart(2, '0'); // 日期补零
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`; // 拼接为 yyyy-mm-dd hh:mm
  }
}
