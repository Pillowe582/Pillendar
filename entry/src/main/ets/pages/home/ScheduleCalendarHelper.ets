import { CalendarService } from '../../services/CalendarService';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { calendarManager } from '@kit.CalendarKit';
import { parseToDate } from './ScheduleDateUtils';

// 将日程条目写入系统日历，成功后回调 onSuccess
export function addScheduleToCalendar(item: ScheduleEvent, onSuccess: () => void): void {
  try {
    console.log('试图确认')
    let calendar = CalendarService.getInstance().getCalendar()
    let event: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: item.title,
      location: {
        location: item.location
      },
      startTime: parseToDate(item.startTime).getTime(),
      endTime: parseToDate(item.endTime).getTime(),
      reminderTime: [30],
      description: item.description,
    }
    calendar?.addEvent(event).then(() => {
      onSuccess();
    }).catch((err: Error) => {
      console.log("添加日程失败：", err)
    })
  } catch (err) {
    console.log("添加日程失败：", err)
  }
}
