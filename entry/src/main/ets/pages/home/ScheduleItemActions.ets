import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { DeleteScheduleButton } from './DeleteScheduleButton';
import { ScheduleItemEditor } from './ScheduleItemEditor';
import { addScheduleToCalendar } from './ScheduleCalendarHelper';
import { TodoService } from '../../services/TodoService';

// 日程卡片的操作行：删除 / 编辑（含编辑弹层）/ 确认写入日历
@Component
export struct ScheduleItemActions {
  @ObjectLink item: ScheduleEvent;
  @State isShowEditSheet: boolean = false;
  onDelete: () => void = () => {
  }

  @Builder
  EditorSheet() {
    ScheduleItemEditor({ item: this.item })
  }

  build() {
    Row() {
      DeleteScheduleButton({
        onDelete: () => {
          this.onDelete();
        }
      })

      Button('编辑', { type: ButtonType.Capsule })
        .fontColor(Color.White)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .onClick(() => {
          this.isShowEditSheet = true
          console.log("试图编辑")
        })
        .bindSheet(this.isShowEditSheet, this.EditorSheet(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE, 600],
          preferType: SheetType.BOTTOM,
          title: { title: `编辑 ${this.item.title}` },
          onDisappear: () => {
            this.isShowEditSheet = false
          },

        });

      Button('确认', { type: ButtonType.Capsule })
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .width('50%')
        .backgroundColor(Color.Green)
        .onClick(() => {
          addScheduleToCalendar(this.item)
            .then(async (eventId: number) => {
              // 按设置项决定这条日程是否默认出现在待办中
              const todoService = TodoService.getInstance();
              await todoService.setShownInTodo(eventId, todoService.getDefaultShowInTodo());
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
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
