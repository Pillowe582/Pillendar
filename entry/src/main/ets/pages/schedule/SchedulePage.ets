import { common } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { CalendarService } from '../../services/CalendarService';
import { TodoService } from '../../services/TodoService';
import { Prompts } from '../../file_handler/LLMConfig';
import { ScheduleTypeSwitch } from '../home/ScheduleTypeSwitch';

// 日程筛选模式
const FILTER_ALL: string = 'all';
const FILTER_ACTIVE: string = 'active';
const FILTER_EXPIRED: string = 'expired';

// 日程列表中的一条视图数据：日程取开始时间，待办取截止时间
class ScheduleCard {
  id: number = 0;
  title: string = '';
  startTime: number = 0;
  endTime: number = 0;
  ddl: boolean = false;
}

// 日程页：列出所有由本应用添加到日历的日程与待办，并允许切换每条的类型
@Component
export struct SchedulePage {
  @Prop @Watch('onTabIndexChange') currentTabIndex: number = 0;
  @State schedules: ScheduleCard[] = [];
  @State filterMode: string = FILTER_ACTIVE;
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    this.loadSchedules();
    // 定时动一下数组，让过期状态随时间生效
    this.refreshTimer = setInterval(() => {
      this.schedules = this.schedules.slice();
    }, 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.refreshTimer);
  }

  // 切换到日程页时刷新列表
  onTabIndexChange(): void {
    if (this.currentTabIndex === 1) {
      this.loadSchedules();
    }
  }

  // 读取本应用日历里的全部事件，组装成列表数据
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
      card.startTime = event.startTime;
      card.endTime = event.endTime;
      card.ddl = todoService.isDdl(card.id);
      return card;
    });
    // 日程按开始时间、待办按截止时间，合并后从早到晚排列
    cards.sort((left: ScheduleCard, right: ScheduleCard) => this.getSortTime(left) - this.getSortTime(right));
    this.schedules = cards;
  }

  // 切换某条事件是日程还是待办
  private async changeDdl(card: ScheduleCard, ddl: boolean): Promise<void> {
    card.ddl = ddl;
    await TodoService.getInstance().setDdl(card.id, ddl);
    // 类型改变后排序键变化，重新排序并刷新界面
    const cards = this.schedules.slice();
    cards.sort((left: ScheduleCard, right: ScheduleCard) => this.getSortTime(left) - this.getSortTime(right));
    this.schedules = cards;
  }

  // 排序用的时间：待办取截止时间，日程取开始时间
  private getSortTime(card: ScheduleCard): number {
    return card.ddl ? card.endTime : card.startTime;
  }

  // 当前筛选模式下需要显示的事件
  private getVisibleSchedules(): ScheduleCard[] {
    const now = Date.now();
    return this.schedules.filter((card: ScheduleCard) => {
      const expired = card.endTime <= now;
      if (this.filterMode === FILTER_ALL) {
        return true;
      }
      if (this.filterMode === FILTER_ACTIVE) {
        return !expired || card.ddl;
      }
      return expired && !card.ddl;
    });
  }

  // 筛选按钮上显示的文字
  private getFilterLabel(): string {
    if (this.filterMode === FILTER_ALL) {
      return '全部';
    }
    if (this.filterMode === FILTER_EXPIRED) {
      return '已过期';
    }
    return '活跃';
  }

  // 截止时间已经过去的事件
  private isExpired(card: ScheduleCard): boolean {
    return card.endTime <= Date.now();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('日程')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Blank()
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 4 }) {
            Text(this.getFilterLabel())
              .fontSize(14)
              .fontColor(Color.Gray)
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(16)
              .fontColor([Color.Gray])
          }
          .justifyContent(FlexAlign.Center)
        }
        .height(32)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#1C1C1C')
        .bindMenu([
          {
            value: '全部',
            action: () => {
              this.filterMode = FILTER_ALL;
            }
          },
          {
            value: '活跃',
            action: () => {
              this.filterMode = FILTER_ACTIVE;
            }
          },
          {
            value: '已过期',
            action: () => {
              this.filterMode = FILTER_EXPIRED;
            }
          }
        ])
      }
      .width('90%')
      .padding({ top: 24, bottom: 16 })

      List({ space: 12 }) {
        if (this.getVisibleSchedules().length === 0) {
          ListItem() {
            Text('Nothing yet~')
              .width('100%')
              .fontSize(16)
              .fontColor(Color.Gray)
              .textAlign(TextAlign.Center)
              .margin({ top: 40 })
          }
        }

        ForEach(this.getVisibleSchedules(), (schedule: ScheduleCard) => {
          ListItem() {
            Column() {
              // 标题与「日程 / 待办」切换按钮
              Row() {
                Text(schedule.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                ScheduleTypeSwitch({
                  ddl: schedule.ddl,
                  onToggle: (ddl: boolean) => {
                    this.changeDdl(schedule, ddl);
                  }
                })
              }
              .width('100%')

              // 待办显示截止时间，日程显示开始时间；已过期时标红
              Text(schedule.ddl ? `截止 ${Prompts.getFormattedDate(new Date(schedule.endTime))}` :
                `开始 ${Prompts.getFormattedDate(new Date(schedule.startTime))}`)
                .fontSize(14)
                .fontColor(this.isExpired(schedule) ? '#FF5B5B' : Color.Gray)
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#1C1C1C')
            .borderRadius(16)
          }
        // key 带上类型与过期状态，状态变化时强制重建卡片
        }, (schedule: ScheduleCard) => `${schedule.id}-${schedule.ddl}-${schedule.endTime <= Date.now()}`)
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
