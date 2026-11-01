import { display } from '@kit.ArkUI';

// 可滑动的卡片容器：右滑露出删除、左滑露出编辑，滑动超过半屏宽度时直接触发对应操作
@Component
export struct SwipeActionCard {
  @BuilderParam content: () => void = this.EmptyContent;
  onDelete: () => void = () => {
  };
  onEdit: () => void = () => {
  };
  @State offsetX: number = 0;
  // 卡片实测高度，滑动时露出的操作区与卡片保持同高
  @State cardHeight: number = 0;
  private startDistance: number = 0;
  private triggerDistance: number = 0;
  private holdDistance: number = 0;
  private gestureStartOffset: number = 0;

  aboutToAppear(): void {
    this.triggerDistance = px2vp(display.getDefaultDisplaySync().width) / 3;
    this.holdDistance = px2vp(display.getDefaultDisplaySync().width) / 5;
    this.startDistance = px2vp(display.getDefaultDisplaySync().width) / 8;
  }

  @Builder
  EmptyContent() {
  }

  // 把偏移量限制在触发距离内，避免卡片被拖出屏幕
  private clampOffset(offset: number): number {
    if (offset > this.triggerDistance) {
      return this.triggerDistance
    }
    if (offset < -this.triggerDistance) {
      return -this.triggerDistance
    }
    return offset
  }

  // 滑动结束：达到触发距离就执行操作，否则回弹
  private finishSwipe(): void {
    const passed: boolean = Math.abs(this.offsetX) >= this.triggerDistance - 1;
    const started: boolean = Math.abs(this.offsetX) >= this.startDistance;
    const isDelete: boolean = this.offsetX > 0;
    this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.offsetX = (passed || !started) ? 0 : isDelete ? this.holdDistance : -this.holdDistance;
    })
    if (!passed) {
      return
    }
    if (isDelete) {
      this.onDelete()
    } else {
      this.onEdit()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      // 卡片下方的操作区域：哪一侧露出来就显示对应颜色，外侧没有边界，由外层圆角遮罩裁切
      Row() {
        Row() {
          Text('删除')
            .fontSize(this.offsetX > this.holdDistance ? 15 : 15 * this.offsetX / this.holdDistance)
            .fontColor(Color.White)
        }
        .width(this.offsetX > 0 ? this.offsetX : 0)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FF5B5B')
        .clip(true)

        Blank()

        Row() {
          Text('编辑')
            .fontSize(this.offsetX < -this.holdDistance ? 15 : -15 * this.offsetX / this.holdDistance)
            .fontColor(Color.White)
        }
        .width(this.offsetX < 0 ? -this.offsetX : 0)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#007DFF')
      }
      .width('100%')
      .height(this.cardHeight)

      // 卡片本身保持直角，靠外层圆角遮罩裁出整体轮廓
      Column() {
        this.content()
      }
      .width('100%')
      .translate({ x: this.offsetX })
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.cardHeight = Number(newValue.height)
      })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal, distance: 10 })
          .onActionStart(() => {
            this.gestureStartOffset = this.offsetX
          })
          .onActionUpdate((event: GestureEvent) => {
            this.offsetX = this.clampOffset(this.gestureStartOffset + event.offsetX)
          })
          .onActionEnd(() => {
            this.finishSwipe()
          })
          .onActionCancel(() => {
            this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
              this.offsetX = 0
            })
          })
      )
    }
    .width('100%')
    .borderRadius(16)
    .clip(true)
  }
}
