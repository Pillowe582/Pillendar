import { abilityAccessCtrl, AbilityConstant,
  bundleManager,
  common,
  ConfigurationConstant,
  Permissions,
  UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import FileHandler from '../file_handler/FileHandler';
import { ScheduleEvent } from '../data_types/ScheduleEvent'
import { ScheduleJson } from  '../data_types/ScheduleJson'
import { CalendarService } from '../services/CalendarService';
import { notificationManager } from '@kit.NotificationKit';

const permissions: Array<Permissions> = [
  'ohos.permission.READ_CALENDAR',
  'ohos.permission.WRITE_CALENDAR',
  'ohos.permission.MEDIA_LOCATION',
  'ohos.permission.READ_MEDIA',
  'ohos.permission.INTERNET',

];
const DOMAIN = 0x0000;


async function checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // 获取应用程序的accessTokenID。
  let tokenId: number = 0;
  try {
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get bundle info for self, code: ${err.code}, message: ${err.message}`);
  }

  // 校验应用是否被授予权限。
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check access token, code: ${err.code}, message: ${err.message}`);
  }

  return grantStatus;
}

async function checkPermissions(context: common.UIAbilityContext): Promise<void> {
  let grantStatuses: Array<boolean>=new Array(permissions.length)
  let hasAllPermission:boolean=true;
  for(let i=0;i<permissions.length;i++){
    grantStatuses[i]=await checkPermissionGrant(permissions[i]) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    console.log("Has " + permissions[i]+": "+grantStatuses[i])
    hasAllPermission &&= grantStatuses[i];
  }
  let atManager:abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  if(!hasAllPermission){
    await atManager.requestPermissionsFromUser(context,permissions).then((data)=>
    {
      let grantStatus: number[] = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          console.info(`${permissions[i]} is granted by user.`);
        } else {
          context.terminateSelf();
          return;
        }
      }
    });
  }
}



export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {


    try {
      await checkPermissions(this.context);
      // 请求通知权限
      try{
        await notificationManager.requestEnableNotification(this.context);
        notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION)
        console.info('已授权通知权限');
      }catch (error){
        const err: BusinessError = error as BusinessError;
        console.error(`通知权限请求失败：${err.code}，${err.message}`);
      }
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    await CalendarService.getInstance().init(this.context)

    console.info('被拉起原因：'+launchParam.launchReasonMessage);
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      AppStorage.setOrCreate('subtitle', 'Requesting LLM...' );
      // 识别为被系统分享拉起
      try {
        const data = await systemShare.getSharedData(want);
        const fetchedEvents: ScheduleJson[] = await FileHandler.fetchFile(data);
        let items = AppStorage.get<Array<ScheduleEvent>>('mainItems');
        fetchedEvents.forEach(event=>{
          if(items) {
            items.push(new ScheduleEvent(event))
          }
        })
      } catch (error)
        {
          AppStorage.setOrCreate('subtitle', '? Whasssup' );
          console.error("获取分享数据失败："+error);
          let fileName="获取分享数据失败";
        }
    }

  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    console.info('被拉起原因：'+launchParam.launchReasonMessage);
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      AppStorage.setOrCreate('subtitle', 'Requesting LLM...' );
      // 识别为被系统分享拉起
      try {
        const data = await systemShare.getSharedData(want);
        const fetchedEvents: ScheduleJson[] = await FileHandler.fetchFile(data);
        let items = AppStorage.get<Array<ScheduleEvent>>('mainItems');
        fetchedEvents.forEach(event=>{
          if(items) {
            items.push(new ScheduleEvent(event))
          }
        })
      } catch (error)
      {
        AppStorage.setOrCreate('subtitle', '? Whasssup' );
        console.error("获取分享数据失败："+error);
        let fileName="获取分享数据失败";
      }
    }
  }

}