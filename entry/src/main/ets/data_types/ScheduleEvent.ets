import { ScheduleJson } from './ScheduleJson'
import { Prompts } from '../file_handler/LLMConfig'

@Observed
export class ScheduleEvent {
  id: string = Math.random().toString();
  title: string = 'Undefined';
  startTime: string = '1145-01-04 19:19';
  endTime: string = '1949-10-01 15:00';
  location?: string = 'Galaxy';
  description?: string = 'What can I say?';
  ddl: boolean = false;

  constructor(event?: ScheduleJson) {
    try {
      if (event) {
        this.title = event.title;
        this.startTime = event.startTime;
        this.endTime = event.endTime;
        this.location = event.location ?? '';
        this.description = event.description ?? '';
        this.ddl = event.ddl === true;
      } else {
        // 模板日程默认从当前时间开始，持续一小时
        const start = new Date();
        const end = new Date(start.getTime() + 60 * 60 * 1000);
        this.startTime = Prompts.getFormattedDate(start);
        this.endTime = Prompts.getFormattedDate(end);
      }
    } catch (err) {
      console.error('JSON Parse Error');
      this.title = 'JSON解析失败';
    }
  }

}
