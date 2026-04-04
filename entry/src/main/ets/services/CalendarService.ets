import { calendarManager } from '@kit.CalendarKit';
import { common } from '@kit.AbilityKit';

export class CalendarService {
  private static instance: CalendarService;
  private calendar:calendarManager.Calendar | undefined = undefined;
  private calendarMgr: calendarManager.CalendarManager | undefined = undefined;
  private constructor() {
  }

  public static getInstance() : CalendarService{
    if(!CalendarService.instance){
      CalendarService.instance = new CalendarService()
    }
    return CalendarService.instance
  }

  public getCalendar(): calendarManager.Calendar | undefined{
    return this.calendar
  }

  public getCalendarManager(): calendarManager.CalendarManager | undefined {
    return this.calendarMgr
  }

  async init(context: common.UIAbilityContext){
    const calendarAccount: calendarManager.CalendarAccount = {
      name: 'Pillendar',
      type: calendarManager.CalendarType.LOCAL,
      displayName: 'Pillendar'
    };
    const config: calendarManager.CalendarConfig = {
      enableReminder: true,
      color: '#6A00A9'
    };
    this.calendarMgr = calendarManager.getCalendarManager(context);

    try {
      this.calendar = await this.calendarMgr?.getCalendar(calendarAccount);
      console.log('成功获取已有日历')
    }catch(err){
      try {
        console.log('没有现成的日历: ',err,'，创建中...')
        this.calendar = await this.calendarMgr?.createCalendar(calendarAccount)
        console.log('成功创建日历')

      } catch (err) {
        console.log('创建日历失败：',err)
      }

    }
    console.log("配置日历中..");
    await this.calendar?.setConfig(config);
  }
}
