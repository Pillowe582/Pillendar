import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { addScheduleToCalendar } from './ScheduleCalendarHelper';
import { TodoService } from '../../services/TodoService';
import { TodoWidgetService } from '../../services/TodoWidgetService';

// 日程卡片的操作行：确认写入日历
@Component
export struct ScheduleItemActions {
  @ObjectLink item: ScheduleEvent;
  onDelete: () => void = () => {
  }

  build() {
    Row() {
      Button('确认', { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .width('50%')
        .backgroundColor(Color.Green)
        .onClick(() => {
          addScheduleToCalendar(this.item)
            .then(async (eventId: number) => {
              // 记录这条日程是日程还是待办
              await TodoService.getInstance().setDdl(eventId, this.item.ddl);
              // 新日程入日历后同步刷新桌面卡片
              await TodoWidgetService.getInstance().updateAllForms();
              this.getUIContext().getPromptAction().showToast({ message: '已添加到日历' });
              this.onDelete();
            })
            .catch((err: Error) => {
              this.getUIContext().getPromptAction().showToast({ message: `添加到日历失败：${err.message}` });
            })
        })
    }
    .padding({ top: 16 })
    .width('100%')
    .justifyContent(FlexAlign.End)
  }
}
