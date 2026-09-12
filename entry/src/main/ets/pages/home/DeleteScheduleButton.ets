import { DeleteSchedulePopUp } from "./DeleteSchedulePopUp";

@Component
export struct DeleteScheduleButton {
  @State isShowDeletePopUp: boolean = false;
  onDelete: () => void = () => {
  };

  build() {
    Button('删除', { type: ButtonType.Capsule })
      .fontColor(Color.Red)
      .backgroundColor('rgba(255,128,128,0.3)')
      .onClick(() => {
        this.isShowDeletePopUp = true;
      })
      .bindPopup(this.isShowDeletePopUp, {
        builder: () => {
          DeleteSchedulePopUp({
            onConfirm: () => {
              this.onDelete();
              this.isShowDeletePopUp = false;
            },
            onClose: () => {
              this.isShowDeletePopUp = false;
            }
          })
        },
        placement: Placement.Bottom,
        onStateChange: (e) => {
          if (!e.isVisible) {
            this.isShowDeletePopUp = false;
          }
        }
      })
  }
}
