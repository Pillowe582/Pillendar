import { ScheduleJson } from  './ScheduleJson'

@Observed
export class ScheduleEvent {
  id: string = Math.random().toString();
  title: string = 'Undefined';
  startTime: string = '1145-01-04 19:19';
  endTime: string = '1949-10-01 15:00';
  location?: string = 'Galaxy';
  description?: string = 'What can I say?';

  constructor(event?:ScheduleJson) {
    try{
      if(event){
        this.title = event.title;
        this.startTime = event.startTime;
        this.endTime = event.endTime;
        this.location = event.location ?? '';
        this.description = event.description ?? '';
      }
    } catch (err){
      console.error('JSON Parse Error');
      this.title = 'JSON解析失败';
    }
  }

}