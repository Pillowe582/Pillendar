import { CalendarService } from '../../services/CalendarService';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { calendarManager } from '@kit.CalendarKit';
import { parseToDate } from './ScheduleDateUtils';

// 将日程条目写入系统日历，写入后确认，并返回新事件的 id
export async function addScheduleToCalendar(item: ScheduleEvent): Promise<number> {
  let calendar = CalendarService.getInstance().getCalendar()
  if (calendar === undefined) {
    throw new Error('日历未初始化')
  }

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

  // 写入日历并回查，确认日程确实已添加
  let eventId = await calendar.addEvent(event)
  let addedEvents = await calendar.getEvents(calendarManager.EventFilter.filterById([eventId]))
  if (addedEvents.length === 0) {
    throw new Error('日历中未找到刚添加的日程')
  }
  return eventId
}
