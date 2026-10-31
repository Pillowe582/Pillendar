import { ScheduleJson } from '../../data_types/ScheduleJson';
import FileHandler from '../../file_handler/FileHandler';

// 描述日程的输入弹层：输入描述后交给大模型生成日程，结果通过 onGenerated 回调交给父组件
@Component
export struct LlmInputSheet {
  @State llmDescription: string = '';
  @State isGenerating: boolean = false;
  onGenerated: (schedules: ScheduleJson[]) => void = () => {
  };

  /**
   * 把输入框里的描述交给大模型生成日程，成功后回调给父组件插入列表
   */
  async generateSchedules(): Promise<void> {
    if (this.llmDescription.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请先描述日程' })
      return
    }

    this.isGenerating = true
    try {
      const schedules = await FileHandler.requestSchedules(this.llmDescription)
      if (schedules.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: '没有识别到日程' })
        return
      }
      this.onGenerated(schedules)
      this.llmDescription = ''
    } catch (err) {
      this.getUIContext().getPromptAction().showToast({ message: `生成失败：${(err as Error).message}` })
    } finally {
      this.isGenerating = false
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('描述一下日程')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      TextArea({ placeholder: '例如：下周四下午6点去KFC吃疯狂星期四', text: this.llmDescription })
        .height(140)
        .borderRadius(12)
        .backgroundColor('#1C1C1C')
        .fontColor(Color.White)
        .onChange((newValue: string) => {
          this.llmDescription = newValue
        })

      Button(this.isGenerating ? '生成中…' : '生成日程', { type: ButtonType.Capsule })
        .width('100%')
        .height(44)
        .backgroundColor('#007DFF')
        .enabled(!this.isGenerating)
        .onClick(() => {
          this.generateSchedules()
        })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 16,
      right: 16,
      top: 24,
      bottom: 24
    })
  }
}
