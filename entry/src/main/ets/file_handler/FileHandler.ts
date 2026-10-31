
import { systemShare } from '@kit.ShareKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { http } from '@kit.NetworkKit';
import { buildRequestBody } from './LLMConfig';
import { LLMSettingsService } from '../services/LLMSettingsService';
import { ScheduleJson } from  '../data_types/ScheduleJson'
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import { WantAgent } from '@ohos.wantAgent';
import { wantAgent } from '@kit.AbilityKit';


export default class FileHandler{

    public static async fetchFile(data : systemShare.SharedData):Promise<ScheduleJson[]>{
      let lastFile:string="";
      try{

        const tasks = data.getRecords().map(async (record: systemShare.SharedRecord) => {
          lastFile = record.uri?.toString() || "";
          console.log("获取到文件：" + record.utd + "//" + record.content + "//" + record.uri);
          let file: fileIo.File = fileIo.openSync(record.uri, fileIo.OpenMode.READ_ONLY);
          let imageSource: image.ImageSource = image.createImageSource(file.fd);
          let pixelMap: image.PixelMap = await imageSource.createPixelMap();
          let visionInfo: textRecognition.VisionInfo = {
            pixelMap: pixelMap
          };

          let result: textRecognition.TextRecognitionResult = await textRecognition.recognizeText(visionInfo);
          pixelMap.release();
          fileIo.closeSync(file);
          console.log("OCR结果：",result.value);
          return await this.requestAI(result.value);
        });
      return (await Promise.all(tasks)).flat();
      }catch (err){
        AppStorage.setOrCreate('subtitle', 'Request Failed :(' );
        console.error("识别图片失败： ",err);
        return [];
      }
    }

    private static async requestAI(message: string):Promise<ScheduleJson[]>{
      let id:number;
      let delayInfo:backgroundTaskManager.DelaySuspendInfo;
      try {
        delayInfo =  backgroundTaskManager.requestSuspendDelay("Processing AI request",()=>{
          console.info("后台任务将过期...")
          try{
            backgroundTaskManager.cancelSuspendDelay(id)
          }catch (err){
            console.error("申请后台任务失败：")
          }
        })
        id = delayInfo.requestId

        console.info('Background task started');
      } catch (err) {
        console.error('Failed to start background task:', err);
      }

      try{
        const events = await this.requestSchedules(message)
        AppStorage.setOrCreate('subtitle', `Found ${events.length} New Schedules` );
        this.sendNotification("Analyze succeeded",`Found ${events.length} New Schedules`,'Woohoo!')
        return events;
      } catch (err){
        AppStorage.setOrCreate('subtitle', 'Request Failed :(' );
        console.error("调用大模型失败：",err);
        return [];
      } finally {
        if(delayInfo !== null){
          backgroundTaskManager.cancelSuspendDelay(id)
          console.info('后台任务完成');
        }
      }
    }

    /**
     * 请求大模型从文本中提取日程，失败时抛出异常
     * @param message 用户文本，如 OCR 识别结果或手动输入的描述
     */
    public static async requestSchedules(message: string):Promise<ScheduleJson[]>{
      const httpRequest = http.createHttp();
      const settings = LLMSettingsService.getInstance().get();

      try{
        const response = await httpRequest.request(
          settings.baseUrl,
          {
            method:http.RequestMethod.POST,
            header: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${settings.apiKey}`
            },
            extraData: buildRequestBody(settings, message)
          }
        );
        console.info("API返回HTTP Code：",response.responseCode);
        if (response.responseCode !== http.ResponseCode.OK) {
          throw new Error(`状态码 ${response.responseCode}`)
        }
        const json = JSON.parse(response.result as string) as Record<string,any>;
        const content = this.getOutputText(json);
        console.info("大模型返回：",content);
        const schedules = JSON.parse(content) as { events: ScheduleJson[] };
        return schedules.events;
      } finally {
        httpRequest.destroy();
      }
    }

    // 取出 Responses API 输出中 message 的文本内容
    private static getOutputText(responseJson: Record<string,any>):string{
      const outputItems = responseJson.output as Array<Record<string,any>>;
      let outputText = "";
      outputItems.forEach((item: Record<string,any>) => {
        if (item.type !== "message") {
          return;
        }

        const contentParts = item.content as Array<Record<string,string>>;
        contentParts.forEach((part: Record<string,string>) => {
          if (part.type === "output_text") {
            outputText += part.text;
          }
        });
      });
      return outputText;
    }

    private static async sendNotification(title: string='',text:string='',additionalText:string=''):Promise<void>{
      let notificationRequest: notificationManager.NotificationRequest = {
        id: 1,
        wantAgent:await this.getWantAgent(),
        notificationSlotType:notificationManager.SlotType.SERVICE_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
          normal: {
            title: title,
            text: text,
            additionalText: additionalText,
          }
        }
      };
      notificationManager.publish(notificationRequest, (err: BusinessError) => {
        if (err) {
          console.error(`发布通知失败： ${err.code}, ${err.message}`);
          return;
        }
        console.log("发布通知成功")
      });
    }

    private static async getWantAgent() : Promise<WantAgent>{
      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants:[
          {
            bundleName:'com.pillowe.pillendar',
            abilityName:'EntryAbility'
          }
        ],
        actionType:wantAgent.OperationType.START_ABILITY,
        requestCode:0,
        actionFlags:[wantAgent.WantAgentFlags.CONSTANT_FLAG]
      };
      return await wantAgent.getWantAgent(wantAgentInfo)
    }
}