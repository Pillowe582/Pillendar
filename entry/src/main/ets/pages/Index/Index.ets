import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { HomePage } from '../home/HomePage';
import { SchedulePage } from '../schedule/SchedulePage';
import { SettingsPage } from '../settings/SettingsPage';

const DOMAIN = 0x0001;

export default class PillendarAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }


  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    windowStage.loadContent('pages/Index/Index', (error) => {
      if (error.code) {
        console.error(`Failed to load the content. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      console.info('Succeeded in loading the content.');
    });
  }
}


@Entry
@Component
struct Index {
  @State fontColor: string = '#ffa0a0a0';
  @State selectedFontColor: string = '#007DFF';
  @State selectedIndex: number = 0;
  @State currentIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBuilder(0, '首页'))

      TabContent() {
        SchedulePage({ currentTabIndex: this.selectedIndex })
      }
      .tabBar(this.tabBuilder(1, '日程'))

      TabContent() {
        SettingsPage()
      }
      .tabBar(this.tabBuilder(2, '设置'))
    }
    .width('100%')
    .height('100%')
    .animationMode(AnimationMode.ACTION_FIRST)
    .onChange((index: number) => {
      console.info('onChange: ' + index)
      this.currentIndex = index
    })
    .onSelected((index: number) => {
      console.info('onSelected: ' + index)
      this.selectedIndex = index
    })
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
  }

  @Builder
  tabBuilder(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.selectedIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(16)
        .fontWeight(this.selectedIndex === index ? 500 : 400)
        .lineHeight(22)
        .margin({ top: 17, bottom: 7 })
      Divider()
        .strokeWidth(2)
        .color(this.selectedFontColor)
        .opacity(this.selectedIndex === index ? 1 : 0)
    }.width('100%')
  }
}

