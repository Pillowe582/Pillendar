import { BottomBuilderShowType, HdsNavigation, HideMode, HdsNavigationAttribute } from '@kit.UIDesignKit';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { ScheduleItem } from './ScheduleItem';

// 首页：展示日程列表
@Component
export struct HomePage {
  @StorageProp('subtitle') subtitle: string = "Strange";
  @StorageLink('mainItems') items: Array<ScheduleEvent> = [];
  itemsScroller: Scroller = new Scroller()

  @Builder
  BottomBuilder() {
  }

  build() {

    Column({ space: 10 }) {
      HdsNavigation() { // 创建HdsNavigation组件
        Scroll(this.itemsScroller) {
          Column() {
            Blank().height('20%').width('100%')
            Grid() {

              ForEach(this.items, (item: ScheduleEvent, index: number) => {

                GridItem() {
                  ScheduleItem({
                    item: item,
                    onDelete: () => {
                      this.items.splice(index, 1)
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
  }
}
