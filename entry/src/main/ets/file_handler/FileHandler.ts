
import { systemShare } from '@kit.ShareKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { http } from '@kit.NetworkKit';
import { Prompts, API_CONFIG } from './LLMConfig';
import { ScheduleJson } from  '../data_types/ScheduleJson'


enum dataTypes {SCHEDULE}

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
          return await this.requestAI(result.value,dataTypes.SCHEDULE);
        });
      return (await Promise.all(tasks)).flat();
      }catch (err){
        AppStorage.setOrCreate('subtitle', 'Request Failed :(' );
        console.error("识别图片失败： ",err);
        return [];
      }
    }

    private static async requestAI(message: string, type: dataTypes):Promise<any>{
      const httpRequest = http.createHttp();
      let prompt: string="";
      switch (type){
        case dataTypes.SCHEDULE:
          prompt=Prompts.schedule();
          break;
      }

      try{
        const response = await httpRequest.request(
          API_CONFIG.baseUrl,
          {
            method:http.RequestMethod.POST,
            header: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${API_CONFIG.apiKey}`
            },
          extraData: JSON.stringify({
            messages:[
              {
              role: "system",
              content: prompt
              },
              {
                role: "user",
                content:message
              }],
            model:API_CONFIG.model,
          })
          }
        );
        console.info("API返回HTTP Code：",response.responseCode);
        const json = JSON.parse(response.result as string) as Record<string,any>;
        const content = json.choices[0].message.content
          .replace("```json", "")
          .replace("```", "")
          .trim();
        console.info("大模型返回：",content);
        const schedules = JSON.parse(content) as { events: ScheduleJson[] };
        AppStorage.setOrCreate('subtitle', `Found ${schedules.events.length} New Schedules` );
        return schedules.events || [];
      } catch (err){
        AppStorage.setOrCreate('subtitle', 'Request Failed :(' );
        console.error("调用大模型失败：",err);
        return [];
      }
    }
}