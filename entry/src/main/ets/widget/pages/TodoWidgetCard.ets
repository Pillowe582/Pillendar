let storage = new LocalStorage();

// 卡片上单条待办的数据结构，字段与 TodoWidgetService 推送的 JSON 保持一致
class TodoItem {
  id: number = 0;
  title: string = '';
  time: string = '';
  expired: boolean = false;
}

@Entry(storage)
@Component
struct TodoWidgetCard {
  @LocalStorageProp('todosJson') todosJson: string = '[]';

  /**
   * 解析待办列表 JSON
   */
  private getTodos(): TodoItem[] {
    return JSON.parse(this.todosJson) as TodoItem[];
  }

  build() {
    Column() {
      // 顶栏：左侧标题，右侧新建按钮，点击后打开应用并展开新建菜单
      Row() {
        Text('待办')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')


        Blank()

        Button('+', { type: ButtonType.Capsule })
          .width(28)
          .height(20)
          .fontSize(12)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .padding(0)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              bundleName: 'com.pillowe.pillendar',
              abilityName: 'EntryAbility',
              params: {
                showCreateMenu: 'true'
              }
            });
          })
      }
      .width('100%')
      .height(26)
      .alignItems(VerticalAlign.Center)

      // 待办列表，可上下滚动以显示全部待办
      if (this.getTodos().length === 0) {
        Text('暂无待办')
          .fontSize(15)
          .fontColor('#A0A0A0')
          .margin({ top: 8 })
      } else {
        List({ space: 0 }) {
          ForEach(this.getTodos(), (item: TodoItem, index: number) => {
            ListItem() {
              Column() {
                Row({ space: 8 }) {
                  Column() {
                    Text(item.title)
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#FFFFFF')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.time)
                      .fontSize(10)
                      .fontColor(item.expired ? '#FF5B5B' : '#A0A0A0')
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Button({ type: ButtonType.Circle })
                    .width(18)
                    .height(18)
                    .backgroundColor(Color.Transparent)
                    .border({ width: 1.5, color: '#808080' })
                    .onClick(() => {
                      postCardAction(this, {
                        action: 'message',
                        params: {
                          action: 'complete',
                          eventId: item.id
                        }
                      });
                    })
                }
                .width('100%')
                .height(36)
                .alignItems(VerticalAlign.Center)

                // 相邻两条待办之间用细分隔线隔开
                if (index < this.getTodos().length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color('#3A3A3A')
                }
              }
              .width('100%')
            }
          }, (item: TodoItem) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 5 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
    .backgroundColor('#1C1C1C')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
  }
}
