import { common } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { CalendarService } from '../../services/CalendarService';
import { TodoService } from '../../services/TodoService';
import { TodoWidgetService } from '../../services/TodoWidgetService';
import { Prompts } from '../../file_handler/LLMConfig';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { ScheduleTypeSwitch } from '../home/ScheduleTypeSwitch';
import { ScheduleItemEditor } from '../home/ScheduleItemEditor';
import { parseToDate } from '../home/ScheduleDateUtils';
import { SwipeActionCard } from '../../components/SwipeActionCard';
import { TITLE_BAR_HEIGHT_FREE, TITLE_ACTION_HEIGHT, TITLE_ACTION_MARGIN_TOP_FREE,
  TITLE_ACTION_MARGIN_RIGHT, getTitleActionTranslateY } from '../../components/TitleBarMetrics';
import { HdsNavigation, HdsNavigationAttribute } from '@kit.UIDesignKit';

// 筛选模式
const FILTER_ALL: string = 'all';
const FILTER_ACTIVE: string = 'active';
const FILTER_EXPIRED: string = 'expired';

// 日程列表中的一条视图数据：日程取开始时间，待办取截止时间
class ScheduleCard {
  id: number = 0;
  title: string = '';
  startTime: number = 0;
  endTime: number = 0;
  location: string = '';
  description: string = '';
  ddl: boolean = false;
}

// 日程页：列出所有由本应用添加到日历的日程与待办，并允许切换每条的类型
@Component
export struct SchedulePage {
  @Prop @Watch('onTabIndexChange') currentTabIndex: number = 0;
  @State schedules: ScheduleCard[] = [];
  @State filterMode: string = FILTER_ACTIVE;
  @State refreshToken: number = 0;
  @State isShowEditSheet: boolean = false;
  @State editingEvent: ScheduleEvent = new ScheduleEvent();
  @State headerScroll: number = 0;
  private editingEventId: number = 0;
  private refreshTimer: number = -1;
  private schedulesScroller: Scroller = new Scroller();

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

  // 卡片编辑弹层
  @Builder
  EditorSheet() {
    ScheduleItemEditor({ item: this.editingEvent })
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
      if (event.location !== undefined) {
        card.location = event.location.location ?? '';
      }
      card.description = event.description ?? '';
      card.ddl = todoService.isDdl(card.id);
      return card;
    });
    // 日程按开始时间、待办按截止时间，合并后从早到晚排列
    cards.sort((left: ScheduleCard, right: ScheduleCard) => this.getSortTime(left) - this.getSortTime(right));
    this.schedules = cards;
    // 列表重建时让每张卡片的滑动操作闭包指向这次的数据
    this.refreshToken += 1;
  }

  // 切换某条事件是日程还是待办
  private async changeDdl(card: ScheduleCard, ddl: boolean): Promise<void> {
    card.ddl = ddl;
    await TodoService.getInstance().setDdl(card.id, ddl);
    // 待办状态变化后同步刷新桌面卡片
    await TodoWidgetService.getInstance().updateAllForms();
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

  // 打开编辑弹层，用卡片当前内容填充临时事件
  private openEditor(card: ScheduleCard): void {
    this.editingEvent = new ScheduleEvent({
      title: card.title,
      startTime: Prompts.getFormattedDate(new Date(card.startTime)),
      endTime: Prompts.getFormattedDate(new Date(card.endTime)),
      location: card.location,
      description: card.description,
      ddl: card.ddl
    });
    this.editingEventId = card.id;
    this.isShowEditSheet = true;
  }

  // 编辑弹层关闭后把改动写回系统日历
  private async saveScheduleEdit(): Promise<void> {
    const calendar = CalendarService.getInstance().getCalendar();
    if (calendar === undefined) {
      return;
    }
    const event: calendarManager.Event = {
      id: this.editingEventId,
      type: calendarManager.EventType.NORMAL,
      title: this.editingEvent.title,
      location: { location: this.editingEvent.location },
      startTime: parseToDate(this.editingEvent.startTime).getTime(),
      endTime: parseToDate(this.editingEvent.endTime).getTime(),
      description: this.editingEvent.description,
      reminderTime: [30]
    };
    await calendar.updateEvent(event);
    // 编辑后同步刷新桌面卡片
    await TodoWidgetService.getInstance().updateAllForms();
    await this.loadSchedules();
  }

  // 右滑删除：确认后从系统日历里删掉这条事件
  private async requestDelete(card: ScheduleCard): Promise<void> {
    const response = await this.getUIContext().getPromptAction().showDialog({
      title: '！？删除？！',
      message: '会从系统日历里永久删掉（真的很久！）',
      buttons: [
        { text: '取消', color: '#808080' },
        { text: '删吧', color: '#FF5B5B' }
      ]
    });
    if (response.index !== 1) {
      return;
    }
    const calendar = CalendarService.getInstance().getCalendar();
    if (calendar === undefined) {
      return;
    }
    await calendar.deleteEvent(card.id);
    await TodoService.getInstance().setDdl(card.id, false);
    // 删除后同步刷新桌面卡片
    await TodoWidgetService.getInstance().updateAllForms();
    this.getUIContext().getPromptAction().showToast({ message: '已删除' });
    await this.loadSchedules();
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      HdsNavigation() {
      List({ space: 12, scroller: this.schedulesScroller }) {
        // 顶部留出 HDS 标题栏的高度，滚动时这块空白会滑到标题栏下面
        ListItem() {
          Column().height(TITLE_BAR_HEIGHT_FREE)
        }

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
            SwipeActionCard({
              onDelete: () => {
                this.requestDelete(schedule)
              },
              onEdit: () => {
                this.openEditor(schedule)
              }
            }) {
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

                // 地点
                if (schedule.location.length > 0) {
                  Text(`@ ${schedule.location}`)
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .width('100%')
                    .margin({ top: 4 })
                }

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
            }
          }

          // key 带上刷新标记、类型与过期状态，状态变化时强制重建卡片
        }, (schedule: ScheduleCard) => `${this.refreshToken}-${schedule.id}-${schedule.ddl}-${schedule.endTime <=
        Date.now()}`)
      }
      .width('100%')
      .height('100%')
      .padding({ left: '5%', right: '5%' })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      // 记录滚动偏移，让标题栏按钮跟着标题一起上移
      .onDidScroll(() => {
        this.headerScroll = this.schedulesScroller.currentOffset().yOffset
      })
      .bindSheet(this.isShowEditSheet, this.EditorSheet(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.BOTTOM,
        title: { title: '编辑日程' },
        onDisappear: () => {
          this.isShowEditSheet = false
          this.saveScheduleEdit()
        }
      })
    }
      .titleBar({
        content: {
          title: {
            mainTitle: '日程'
          }
        }
      })
      .dynamicHideTitleBar({
        hideTitleArea: false
      })
      .bindToScrollable([this.schedulesScroller])
      .width('100%')
      .height('100%')

      // 标题右上角的筛选按钮，和标题文字垂直对齐
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
      .height(TITLE_ACTION_HEIGHT)
      .padding({ left: 14, right: 14 })
      .backgroundColor('#1C1C1C')
      .margin({ top: TITLE_ACTION_MARGIN_TOP_FREE, right: TITLE_ACTION_MARGIN_RIGHT })
      .translate({ y: getTitleActionTranslateY(this.headerScroll, TITLE_ACTION_MARGIN_TOP_FREE) })
      .bindMenu([
        {
          value: '全部',
          action: () => {
            this.filterMode = FILTER_ALL
          }
        },
        {
          value: '活跃',
          action: () => {
            this.filterMode = FILTER_ACTIVE
          }
        },
        {
          value: '已过期',
          action: () => {
            this.filterMode = FILTER_EXPIRED
          }
        }
      ])
    }
    .width('100%')
    .height('100%')
  }
}
