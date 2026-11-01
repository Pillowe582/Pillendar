import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { ScheduleJson } from '../../data_types/ScheduleJson';
import { ScheduleItem } from './ScheduleItem';
import { ScheduleItemEditor } from './ScheduleItemEditor';
import { LlmInputSheet } from './LlmInputSheet';
import { SwipeActionCard } from '../../components/SwipeActionCard';
import {
  TITLE_BAR_HEIGHT_WITH_SUBTITLE,
  TITLE_ACTION_HEIGHT,
  TITLE_ACTION_MARGIN_TOP_WITH_SUBTITLE,
  TITLE_ACTION_MARGIN_RIGHT,
  getTitleActionTranslateY
} from '../../components/TitleBarMetrics';
import { HdsNavigation, HdsNavigationAttribute } from '@kit.UIDesignKit';

// 首页：展示日程列表
@Component
export struct HomePage {
  @StorageProp('subtitle') subtitle: string = "Strange";
  @StorageProp('showCreateMenu') @Watch('onShowCreateMenuChange') isRequestCreateMenu: boolean = false;
  @StorageLink('mainItems') items: Array<ScheduleEvent> = [];
  @State isShowLlmInput: boolean = false;
  @State isShowCreateMenu: boolean = false;
  @State isShowEditSheet: boolean = false;
  @State editingItem: ScheduleEvent = new ScheduleEvent();
  @State headerScroll: number = 0;
  itemsScroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.consumeCreateMenuRequest()
  }

  // 桌面卡片的 + 号拉起应用后，展开首页的新建菜单
  onShowCreateMenuChange(): void {
    this.consumeCreateMenuRequest()
  }

  // 消费一次性新建菜单请求
  private consumeCreateMenuRequest(): void {
    if (!this.isRequestCreateMenu) {
      return
    }
    this.isShowCreateMenu = true
    AppStorage.setOrCreate('showCreateMenu', false)
  }

  // 新建菜单内容，供 + 号按钮弹出
  @Builder
  CreateMenuBuilder() {
    Column() {
      Text('模板日程')
        .width('100%')
        .fontSize(16)
        .fontColor(Color.White)
        .padding({
          left: 24,
          right: 24,
          top: 18,
          bottom: 18
        })
        .onClick(() => {
          this.isShowCreateMenu = false
          this.createTemplateSchedule()
        })
      Divider()
        .strokeWidth(0.5)
        .color('#3A3A3A')
      Text('问问神奇的大模型')
        .width('100%')
        .fontSize(16)
        .fontColor(Color.White)
        .padding({
          left: 24,
          right: 24,
          top: 18,
          bottom: 18
        })
        .onClick(() => {
          this.isShowCreateMenu = false
          this.isShowLlmInput = true
        })
    }
    .width(180)
    .backgroundColor('#1C1C1C')
    .borderRadius(12)
  }

  // 输入描述让大模型生成日程的弹层
  @Builder
  LlmInputSheetBuilder() {
    LlmInputSheet({
      onGenerated: (schedules: ScheduleJson[]) => {
        this.insertGeneratedSchedules(schedules)
      }
    })
  }

  // 卡片编辑弹层
  @Builder
  EditorSheet() {
    ScheduleItemEditor({ item: this.editingItem })
  }

  /**
   * 在列表顶部插入一张使用默认值的模板日程卡片
   */
  createTemplateSchedule(): void {
    this.items.unshift(new ScheduleEvent())
    this.itemsScroller.scrollEdge(Edge.Top)
  }

  /**
   * 把大模型生成的日程插入列表顶部并提示结果
   */
  insertGeneratedSchedules(schedules: ScheduleJson[]): void {
    // 逐条插入列表顶部，保持大模型返回的顺序
    const newEvents = schedules.map((schedule: ScheduleJson) => new ScheduleEvent(schedule))
    for (let index = newEvents.length - 1; index >= 0; index--) {
      this.items.unshift(newEvents[index])
    }
    this.itemsScroller.scrollEdge(Edge.Top)
    this.isShowLlmInput = false
    this.getUIContext().getPromptAction().showToast({ message: `已生成 ${newEvents.length} 条日程` })
  }

  // 打开卡片编辑弹层
  private openEditor(item: ScheduleEvent): void {
    this.editingItem = item
    this.isShowEditSheet = true
  }

  // 从首页列表移除一条日程
  private removeItem(item: ScheduleEvent): void {
    const targetIndex = this.items.findIndex((event: ScheduleEvent) => event.id === item.id)
    if (targetIndex < 0) {
      return
    }
    this.items.splice(targetIndex, 1)
  }

  // 右滑删除：确认后从列表移除
  private async requestDelete(item: ScheduleEvent): Promise<void> {
    const response = await this.getUIContext().getPromptAction().showDialog({
      title: '！？删除？！',
      message: '将会永久失去这一项（真的很久！）',
      buttons: [
        { text: '取消', color: '#808080' },
        { text: '删吧', color: '#FF5B5B' }
      ]
    });
    if (response.index !== 1) {
      return
    }
    this.removeItem(item)
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      HdsNavigation() {
        List({ space: 12, scroller: this.itemsScroller }) {
          // 顶部留出 HDS 标题栏的高度，滚动时这块空白会滑到标题栏下面
          ListItem() {
            Column().height(TITLE_BAR_HEIGHT_WITH_SUBTITLE)
          }

          // 无日程时在列表顶部显示空状态提示
          if (this.items.length === 0) {
            ListItem() {
              Text('Nothing yet~')
                .width('100%')
                .fontSize(16)
                .fontColor(Color.Gray)
                .textAlign(TextAlign.Center)
                .margin({ top: 20 })
            }
          }

          ForEach(this.items, (item: ScheduleEvent) => {
            ListItem() {
              SwipeActionCard({
                onDelete: () => {
                  this.requestDelete(item)
                },
                onEdit: () => {
                  this.openEditor(item)
                }
              }) {
                ScheduleItem({
                  item: item,
                  onDelete: () => {
                    this.removeItem(item)
                  }
                })
              }
            }
          }, (item: ScheduleEvent) => item.id)
        }
        .width('100%')
        .height('100%')
        .padding({ left: '5%', right: '5%' })
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .scrollBar(BarState.Off)
        // 记录滚动偏移，让标题栏按钮跟着标题一起上移
        .onDidScroll(() => {
          this.headerScroll = this.itemsScroller.currentOffset().yOffset
        })
        .bindSheet(this.isShowEditSheet, this.EditorSheet(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE],
          preferType: SheetType.BOTTOM,
          title: { title: `编辑 ${this.editingItem.title}` },
          onDisappear: () => {
            this.isShowEditSheet = false
          }
        })
      }
      .titleBar({
        content: {
          title: {
            mainTitle: 'Pillendar',
            subTitle: this.subtitle
          }
        }
      })
      .dynamicHideTitleBar({
        hideTitleArea: false
      })
      .bindToScrollable([this.itemsScroller])
      .width('100%')
      .height('100%')
      .bindSheet(this.isShowLlmInput, this.LlmInputSheetBuilder(), {
        detents: [320],
        preferType: SheetType.BOTTOM,
        onDisappear: () => {
          this.isShowLlmInput = false
        }
      })

      // 标题右上角的新建按钮，和标题文字垂直对齐
      Button('+', { type: ButtonType.Capsule })
        .width(1.5 * TITLE_ACTION_HEIGHT)
        .height(TITLE_ACTION_HEIGHT)
        .fontSize(24)
        .fontColor(Color.White)
        .backgroundColor('#007DFF')
        .margin({ top: TITLE_ACTION_MARGIN_TOP_WITH_SUBTITLE, right: TITLE_ACTION_MARGIN_RIGHT })
        .translate({ y: getTitleActionTranslateY(this.headerScroll, TITLE_ACTION_MARGIN_TOP_WITH_SUBTITLE) })
        .onClick(() => {
          this.isShowCreateMenu = !this.isShowCreateMenu
        })
        .bindPopup(this.isShowCreateMenu, {
          builder: () => {
            this.CreateMenuBuilder()
          },
          placement: Placement.BottomRight,
          popupColor: '#1C1C1C',
          enableArrow: false,
          // 从右上角锚点缩放展开、反向缩放淡出收起，贴近系统菜单动画
          transition: TransitionEffect.asymmetric(
            TransitionEffect.OPACITY
              .combine(TransitionEffect.scale({
                x: 0.5,
                y: 0.5,
                centerX: '100%',
                centerY: '20%'
              }))
              .animation({ duration: 160, curve: Curve.Friction }),
            TransitionEffect.OPACITY
              .combine(TransitionEffect.scale({
                x: 0.5,
                y: 0.5,
                centerX: '100%',
                centerY: '20%'
              }))
              .animation({ duration: 160, curve: Curve.Friction })
          ),
          onStateChange: (event: PopupStateChangeParam) => {
            if (!event.isVisible) {
              this.isShowCreateMenu = false
            }
          }
        })
    }
    .width('100%')
    .height('100%')
  }
}
