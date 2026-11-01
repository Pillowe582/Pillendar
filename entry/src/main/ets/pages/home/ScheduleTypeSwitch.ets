// 日程 / 待办两档开关：整个开关可点，点一下在两种状态之间切换
@Component
export struct ScheduleTypeSwitch {
  @Prop ddl: boolean = false;
  onToggle: (ddl: boolean) => void = () => {
  }

  build() {
    Row() {
      Text('日程')
        .layoutWeight(1)
        .height('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.ddl ? Color.Gray : Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.ddl ? Color.Transparent : '#007DFF')
        .borderRadius(20)

      Text('待办')
        .layoutWeight(1)
        .height('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.ddl ? Color.White : Color.Gray)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.ddl ? '#007DFF' : Color.Transparent)
        .borderRadius(20)
    }
    .width(132)
    .height(40)
    .alignItems(VerticalAlign.Center)
    .padding(3)
    .backgroundColor('#1C1C1C')
    .borderRadius(13)
    .onClick(() => {
      this.onToggle(!this.ddl);
    })
  }
}
