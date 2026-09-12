import { Popup } from '@kit.ArkUI';

@Component
export struct DeleteSchedulePopUp{
  @Prop title: string = '删除？！';
  @Prop message: string = '将会永久失去这一项（真的很久！）';
  @Prop confirmText: string = '删吧';
  confirmFontColor: ResourceColor = Color.Red;

  onConfirm: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Popup({
  title:{
    text: this.title
  },
  message:{
    text: this.message
  },
  showClose:true,
  onClose:() => {
    this.onClose()
  },
  buttons:[{
    text: this.confirmText,
    fontColor: this.confirmFontColor,
    action: () => {
      this.onConfirm()
    }
  }]
})
}
}
