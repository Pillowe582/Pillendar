import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { ScheduleItemActions } from './ScheduleItemActions';

// 日程卡片：只负责展示条目信息，操作按钮与编辑弹层在 ScheduleItemActions 中
@Component
export struct ScheduleItem {
  @ObjectLink item: ScheduleEvent;
  onDelete: () => void = () => {
  }

  build() {
    Column() {
      Column() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
          Text(this.item.title ? this.item.title : 'Undefined')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Start)


          Text(this.item.location ? `@ ${this.item.location}` : '@ Galaxy')
            .padding({ top: 4 })
            .fontSize(16)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.Start)


          Text(this.item.startTime ? `◇ ${this.item.startTime}` : "1145-01-04 19:19")
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)
            .padding({ top: 16 })

          Text("↓")
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)

          Text(this.item.endTime ? `◈ ${this.item.endTime}` : "1949-10-01 15:00")
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)

          Text(this.item.description ? this.item.description : 'What can I say?')
            .fontSize(16)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)
            .padding({ top: 8 })

          ScheduleItemActions({
            item: this.item,
            onDelete: () => {
              this.onDelete();
            }
          })

        }
        .width('100%')

      }
      .width('100%')
      .padding(16)
      .backgroundColor('#303030')
      .borderRadius(16)
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    }
  }
}
