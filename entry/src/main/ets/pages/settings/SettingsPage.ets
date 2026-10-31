import { common } from '@kit.AbilityKit';
import { DEFAULT_LLM_SETTINGS, isRequestJsonValid } from '../../file_handler/LLMConfig';
import { LLMSettings } from '../../data_types/LLMSettings';
import { LLMSettingsService } from '../../services/LLMSettingsService';
import { LLMService } from '../../services/LLMService';

// 设置页：大模型接口参数收在可展开的 section 中，保存按钮在标题栏，恢复默认在列表底部
@Component
export struct SettingsPage {
  @State baseUrl: string = DEFAULT_LLM_SETTINGS.baseUrl;
  @State apiKey: string = DEFAULT_LLM_SETTINGS.apiKey;
  @State model: string = DEFAULT_LLM_SETTINGS.model;
  @State models: string[] = [];
  @State prompt: string = DEFAULT_LLM_SETTINGS.prompt;
  @State requestJson: string = DEFAULT_LLM_SETTINGS.requestJson;
  @State apiExpanded: boolean = false;

  aboutToAppear(): void {
    this.loadSettings();
  }

  // 读取已保存的配置
  private async loadSettings(): Promise<void> {
    const service = LLMSettingsService.getInstance();
    await service.init(this.getUIContext().getHostContext() as common.Context);
    const settings = service.get();
    this.baseUrl = settings.baseUrl;
    this.apiKey = settings.apiKey;
    this.model = settings.model;
    this.prompt = settings.prompt;
    this.requestJson = settings.requestJson;
  }

  // 校验请求 JSON 后保存配置
  private async saveSettings(): Promise<void> {
    if (!isRequestJsonValid(this.requestJson)) {
      this.getUIContext().getPromptAction().showToast({ message: '请求 JSON 格式错误，请检查' });
      return;
    }

    const settings: LLMSettings = {
      baseUrl: this.baseUrl,
      apiKey: this.apiKey,
      model: this.model,
      prompt: this.prompt,
      requestJson: this.requestJson
    };
    await LLMSettingsService.getInstance().save(settings);
    this.getUIContext().getPromptAction().showToast({ message: '已保存' });
  }

  // 确认后恢复默认配置并立即保存
  private async resetSettings(): Promise<void> {
    // 恢复默认会覆盖现有配置，先弹确认框
    const response = await this.getUIContext().getPromptAction().showDialog({
      title: '恢复默认设置',
      message: '当前配置将被覆盖并恢复为默认值，确定继续吗？',
      buttons: [
        { text: '取消', color: '#808080' },
        { text: '确定', color: '#FF5B5B' }
      ]
    });
    if (response.index !== 1) {
      return;
    }

    this.baseUrl = DEFAULT_LLM_SETTINGS.baseUrl;
    this.apiKey = DEFAULT_LLM_SETTINGS.apiKey;
    this.model = DEFAULT_LLM_SETTINGS.model;
    this.models = [];
    this.prompt = DEFAULT_LLM_SETTINGS.prompt;
    this.requestJson = DEFAULT_LLM_SETTINGS.requestJson;
    await LLMSettingsService.getInstance().save(DEFAULT_LLM_SETTINGS);
    this.getUIContext().getPromptAction().showToast({ message: '已恢复默认设置' });
  }

  // 测试 API Key 连通性
  private async testApiKey(): Promise<void> {
    const models = await this.requestModels();
    if (models === undefined) {
      return;
    }
    this.getUIContext().getPromptAction().showToast({ message: `连接成功，可用模型 ${models.length} 个` });
  }

  // 拉取可用模型列表，供用户选择
  private async loadModels(): Promise<void> {
    const models = await this.requestModels();
    if (models === undefined) {
      return;
    }
    this.models = models;
    this.getUIContext().getPromptAction().showToast({ message: `已拉取 ${models.length} 个可用模型` });
  }

  // 请求模型列表，失败时提示并返回 undefined
  private async requestModels(): Promise<string[] | undefined> {
    try {
      const models = await LLMService.fetchModels(this.baseUrl, this.apiKey);
      this.models = models;
      return models;
    } catch (err) {
      this.getUIContext().getPromptAction().showToast({ message: `请求失败：${(err as Error).message}` });
      return undefined;
    }
  }

  build() {
    Column() {
      // 标题栏：左侧标题，右侧保存按钮
      Row() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Blank()
        Button('保存')
          .height(36)
          .fontSize(15)
          .backgroundColor('#007DFF')
          .onClick(() => {
            this.saveSettings();
          })
      }
      .width('90%')
      .padding({ top: 24, bottom: 16 })

      List({ space: 18 }) {
        // 大模型 API 设置 section，点击标题展开或收起
        ListItem() {
          Column() {
            Row() {
              Text('大模型 API 设置')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Blank()
              Text(this.apiExpanded ? '收起' : '展开')
                .fontSize(14)
                .fontColor(Color.Gray)
            }
            .width('100%')
            .onClick(() => {
              this.apiExpanded = !this.apiExpanded;
            })

            if (this.apiExpanded) {
              Column({ space: 16 }) {
                // 接口地址
                Column() {
                  Text('Base URL')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  TextInput({ text: this.baseUrl, placeholder: 'https://api.deepseek.com/chat/completions' })
                    .height(48)
                    .margin({ top: 6 })
                    .fontSize(15)
                    .fontColor(Color.White)
                    .placeholderColor(Color.Gray)
                    .backgroundColor('#303030')
                    .borderRadius(12)
                    .padding({ left: 12, right: 12 })
                    .onChange((value: string) => {
                      this.baseUrl = value;
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)

                // API Key，右侧按钮测试连通性
                Column() {
                  Text('API Key')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  Row({ space: 8 }) {
                    TextInput({ text: this.apiKey, placeholder: 'sk-...' })
                      .type(InputType.Password)
                      .showPasswordIcon(true)
                      .layoutWeight(1)
                      .height(48)
                      .fontSize(15)
                      .fontColor(Color.White)
                      .placeholderColor(Color.Gray)
                      .backgroundColor('#303030')
                      .borderRadius(12)
                      .padding({ left: 12, right: 12 })
                      .onChange((value: string) => {
                        this.apiKey = value;
                      })
                    Button('测试')
                      .height(48)
                      .fontSize(14)
                      .fontColor(Color.White)
                      .backgroundColor('#303030')
                      .borderRadius(12)
                      .onClick(() => {
                        this.testApiKey();
                      })
                  }
                  .width('100%')
                  .margin({ top: 6 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)

                // 模型：拉取可用模型后点击选择
                Column() {
                  Row({ space: 8 }) {
                    Text('模型')
                      .fontSize(14)
                      .fontColor(Color.Gray)
                    Blank()
                    Text(this.model)
                      .fontSize(14)
                      .fontColor(Color.White)
                    Button('拉取模型')
                      .height(32)
                      .fontSize(13)
                      .fontColor(Color.White)
                      .backgroundColor('#303030')
                      .borderRadius(12)
                      .onClick(() => {
                        this.loadModels();
                      })
                  }
                  .width('100%')

                  if (this.models.length > 0) {
                    Flex({ wrap: FlexWrap.Wrap }) {
                      ForEach(this.models, (modelName: string) => {
                        Text(modelName)
                          .fontSize(13)
                          .fontColor(this.model === modelName ? Color.White : Color.Gray)
                          .backgroundColor(this.model === modelName ? '#007DFF' : '#303030')
                          .borderRadius(14)
                          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                          .margin({ top: 8, right: 8 })
                          .onClick(() => {
                            this.model = modelName;
                          })
                      }, (modelName: string) => modelName)
                    }
                    .width('100%')
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)

                // 系统提示词
                Column() {
                  Text('Prompt')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  Text('支持 {{now}} 与 {{weekday}} 占位符')
                    .fontSize(12)
                    .fontColor('#808080')
                    .margin({ top: 2 })
                  TextArea({ text: this.prompt, placeholder: '系统提示词' })
                    .height(220)
                    .margin({ top: 6 })
                    .fontSize(14)
                    .fontColor(Color.White)
                    .placeholderColor(Color.Gray)
                    .backgroundColor('#303030')
                    .borderRadius(12)
                    .padding(12)
                    .onChange((value: string) => {
                      this.prompt = value;
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)

                // 请求体 JSON
                Column() {
                  Text('请求 JSON')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  Text('支持 {{prompt}}、{{message}}、{{model}} 占位符，模型由上方选择填充')
                    .fontSize(12)
                    .fontColor('#808080')
                    .margin({ top: 2 })
                  TextArea({ text: this.requestJson, placeholder: '请求体 JSON' })
                    .height(280)
                    .margin({ top: 6 })
                    .fontSize(14)
                    .fontColor(Color.White)
                    .placeholderColor(Color.Gray)
                    .backgroundColor('#303030')
                    .borderRadius(12)
                    .padding(12)
                    .onChange((value: string) => {
                      this.requestJson = value;
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .margin({ top: 16 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#1C1C1C')
          .borderRadius(16)
        }

        // 列表最底部的恢复默认按钮
        ListItem() {
          Button('恢复默认')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FF5B5B')
            .backgroundColor('#1C1C1C')
            .onClick(() => {
              this.resetSettings();
            })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: '5%', right: '5%', bottom: 24 })
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}
