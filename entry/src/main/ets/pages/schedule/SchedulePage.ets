import { common } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { CalendarService } from '../../services/CalendarService';
import { TodoService } from '../../services/TodoService';
import { Prompts } from '../../file_handler/LLMConfig';

// 日程列表中的一条日程视图数据
class ScheduleCard {
  id: number = 0;
  title: string = '';
  endTime: number = 0;
  showInTodo: boolean = false;
}

// 日程页：列出所有由本应用添加到日历的日程，并控制每条日程是否在待办中显示
@Component
export struct SchedulePage {
  @Prop @Watch('onTabIndexChange') currentTabIndex: number = 0;
  @State schedules: ScheduleCard[] = [];

  aboutToAppear(): void {
    this.loadSchedules();
  }

  // 切换到日程页时刷新列表
  onTabIndexChange(): void {
    if (this.currentTabIndex === 1) {
      this.loadSchedules();
    }
  }

  // 读取本应用日历里的全部日程，组装成列表数据
  private async loadSchedules(): Promise<void> {
    const todoService = TodoService.getInstance();
    await todoService.init(this.getUIContext().getHostContext() as common.Context);
    const calendar = CalendarService.getInstance().getCalendar();
    if (calendar === undefined) {
      return;
    }

    const events = await calendar.getEvents();
    const cards: ScheduleCard[] = events.map((event: calendarManager.Event) => {
      const card = new ScheduleCard();
      card.id = event.id ?? 0;
      card.title = event.title ?? '未命名日程';
      card.endTime = event.endTime;
      card.showInTodo = todoService.isShownInTodo(card.id);
      return card;
    });
    // 按截止时间从早到晚排列
    cards.sort((left: ScheduleCard, right: ScheduleCard) => left.endTime - right.endTime);
    this.schedules = cards;
  }

  // 切换某条日程是否在待办中显示
  private async changeShowInTodo(card: ScheduleCard, showInTodo: boolean): Promise<void> {
    card.showInTodo = showInTodo;
    await TodoService.getInstance().setShownInTodo(card.id, showInTodo);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('日程')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('90%')
      .padding({ top: 24, bottom: 16 })

      List({ space: 12 }) {
        if (this.schedules.length === 0) {
          ListItem() {
            Text('Nothing yet~')
              .width('100%')
              .fontSize(16)
              .fontColor(Color.Gray)
              .textAlign(TextAlign.Center)
              .margin({ top: 40 })
          }
        }

        ForEach(this.schedules, (schedule: ScheduleCard) => {
          ListItem() {
            Column() {
              // 标题与待办开关
              Row() {
                Text(schedule.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Toggle({ type: ToggleType.Switch, isOn: schedule.showInTodo })
                  .onChange(async (isOn: boolean) => {
                    await this.changeShowInTodo(schedule, isOn);
                  })
              }
              .width('100%')

              // 截止时间
              Text(`${Prompts.getFormattedDate(new Date(schedule.endTime))}`)
                .fontSize(14)
                .fontColor(Color.Gray)
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#1C1C1C')
            .borderRadius(16)
          }
        }, (schedule: ScheduleCard) => String(schedule.id))
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: '5%', right: '5%', bottom: 24 })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}
