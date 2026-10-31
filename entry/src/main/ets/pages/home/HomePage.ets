import { BottomBuilderShowType, HdsNavigation, HdsNavigationAttribute, HideMode } from '@kit.UIDesignKit';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { ScheduleJson } from '../../data_types/ScheduleJson';
import { ScheduleItem } from './ScheduleItem';
import { LlmInputSheet } from './LlmInputSheet';

// 首页：展示日程列表
@Component
export struct HomePage {
  @StorageProp('subtitle') subtitle: string = "Strange";
  @StorageLink('mainItems') items: Array<ScheduleEvent> = [];
  @State isShowLlmInput: boolean = false;
  itemsScroller: Scroller = new Scroller()

  @Builder
  BottomBuilder() {
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

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 10 }) {
        HdsNavigation() { // 创建HdsNavigation组件
          Scroll(this.itemsScroller) {
            Column() {
              Blank().height('20%').width('100%')

              // 无日程时在列表顶部显示空状态提示
              if (this.items.length === 0) {
                Text('Nothing yet~')
                  .width('90%')
                  .fontSize(16)
                  .fontColor(Color.Gray)
                  .textAlign(TextAlign.Center)
              }

              Grid() {

                ForEach(this.items, (item: ScheduleEvent) => {

                  GridItem() {
                    ScheduleItem({
                      item: item,
                      onDelete: () => {
                        const targetIndex = this.items.findIndex((event: ScheduleEvent) => event.id === item.id)
                        if (targetIndex < 0) {
                          return
                        }
                        this.items.splice(targetIndex, 1)
                      }
                    });
                  }
                  .margin({ bottom: 12 })
                }, (item: ScheduleEvent) => item.id)

              }

              .height('auto')
              .width('90%')

              Blank().height('50%').width('100%')
            }
          }
          .edgeEffect(EdgeEffect.Spring)

        }.titleBar({
          content: {
            title: { mainTitle: 'Pillendar', subTitle: this.subtitle },

            // 设置HdsNavigation BottomBuilder区域，包括设置高度，显示类型
            bottomBuilder: {
              builder: (): void => this.BottomBuilder(),
              height: 0,
              showType: BottomBuilderShowType.DIRECTLY_SHOW
            },

          }
        })

        // 设置HdsNavigation标题栏动态显隐，包括设置标题区域，bottomBuilder区域，状态栏区域是否动态隐藏，隐藏模式以及开始隐藏时内容区的滚动距离。
        .dynamicHideTitleBar({
          hideTitleArea: true,
          hideBottomBuilder: true,
          hideStatusBar: false,
          mode: HideMode.SCROLL_UP_TO_BLEND_SCROLL_UP,
          hideOffset: 0
        })
        .height('100%')
        .bindToScrollable([this.itemsScroller]);

      }

      // 底部导航栏上方居中的新建按钮，点击后在按钮旁弹出选项菜单
      Button('+', { type: ButtonType.Circle })
        .width(60)
        .height(60)
        .fontSize(32)
        .fontColor(Color.White)
        .backgroundColor('#007DFF')
        .margin({ bottom: 16 })
        .bindMenu([
          {
            value: '模板日程',
            action: () => {
              this.createTemplateSchedule()
            }
          },
          {
            value: '问问神奇的大模型',
            action: () => {
              this.isShowLlmInput = true
            }
          }
        ])
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.isShowLlmInput, this.LlmInputSheetBuilder(), {
      detents: [320],
      preferType: SheetType.BOTTOM,
      onDisappear: () => {
        this.isShowLlmInput = false
      }
    })
  }
}
