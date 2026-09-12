import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { HomePage } from '../home/HomePage';
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

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        HomePage()
      }
      .tabBar('首页')

      TabContent() {
        SettingsPage()
      }
      .tabBar('设置')
    }
    .width('100%')
    .height('100%')
  }
}
