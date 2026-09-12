import { Prompts } from '../../file_handler/LLMConfig';
import { ScheduleEvent } from '../../data_types/ScheduleEvent';
import { parseToDate } from './ScheduleDateUtils';

// 日程编辑面板，作为半屏弹层（bindSheet）的内容展示
@Component
export struct ScheduleItemEditor {
  @ObjectLink item: ScheduleEvent;

  build() {
    Column() {
      Row() {
        Text("标题：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextInput({ placeholder: "请输入文本", text: this.item.title })
          .borderRadius(16)
          .fontSize(16)
          .width('80%')
          .onChange((newValue: string) => {
            this.item.title = newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween);

      Row() {
        Text("地点：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextInput({ placeholder: "请输入文本", text: this.item.location })
          .borderRadius(16)
          .fontSize(16)
          .width('80%')
          .onChange((newValue: string) => {
            this.item.location = newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 });

      Row() {
        Text("始于：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        Button(this.item.startTime ? this.item.startTime : "1145-01-04 19:19", { type: ButtonType.Capsule })
          .width('80%')
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date('1145-01-01'),
              end: new Date('2100-12-31'),
              selected: parseToDate(this.item.startTime),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: (value: Date) => {
                this.item.startTime = Prompts.getFormattedDate(value);
                console.info('新开始时间已保存: ' + this.item.startTime);
              }
            })
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 });

      Row() {
        Text("终于：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        Button(this.item.endTime ? this.item.endTime : "1949-10-01 15:00", { type: ButtonType.Capsule })
          .width('80%')
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date('1145-01-01'),
              end: new Date('2100-12-31'),
              selected: parseToDate(this.item.endTime),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: (value: Date) => {
                this.item.endTime = Prompts.getFormattedDate(value);
                console.info('新开始时间已保存: ' + this.item.endTime);
              }
            })
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 });

      Row() {
        Text("描述：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextArea({ placeholder: "请输入文本", text: this.item.description })

          .width('80%')
          .onChange((newValue: string) => {
            this.item.description = newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 })

    }.width('90%').height('100%')
  }
}
