// 设置页：占位实现，后续补充具体设置项
@Component
export struct SettingsPage {

  build() {
    Column() {
      Text('设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .padding({ top: 32 })

      Text('设置项开发中…')
        .fontSize(16)
        .fontColor(Color.Gray)
        .padding({ top: 16 })
    }
    .width('100%')
    .height('100%')
  }
}
