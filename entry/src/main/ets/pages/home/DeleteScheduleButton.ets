// 删除按钮：点击后弹出确认框，确认后才执行删除回调
@Component
export struct DeleteScheduleButton {
  onDelete: () => void = () => {
  };

  build() {
    Button('删除', { type: ButtonType.Capsule })
      .fontColor(Color.Red)
      .backgroundColor('rgba(255,128,128,0.3)')
      .onClick(async () => {
        const response = await this.getUIContext().getPromptAction().showDialog({
          title: '！？删除？！',
          message: '将会永久失去这一项（真的很久！）',
          buttons: [
            { text: '取消', color: '#808080' },
            { text: '删吧', color: '#FF5B5B' }
          ]
        });
        if (response.index !== 1) {
          return;
        }
        this.onDelete();
      })
  }
}
