import { AbilityConstant, StartupTask, UIAbility, Want } from '@kit.AbilityKit';
import { Popup, window } from '@kit.ArkUI';
import { HdsNavigation, BottomBuilderShowType, HideMode, HdsNavigationAttribute } from '@kit.UIDesignKit';
import { Prompts } from '../file_handler/LLMConfig'
import { ScheduleEvent } from '../data_types/ScheduleEvent'
import { CalendarService } from '../services/CalendarService';
import { calendarManager } from '@kit.CalendarKit';

const DOMAIN = 0x0001;

@Component
struct ScheduleItemBuilder {
  @ObjectLink item: ScheduleEvent;
  @State isShowEditSheet: boolean = false
  @State isShowDeletePopUp: boolean = false;
  onDelete: () => void = () => {
  }

  @Builder
  ScheduleItemEditor(){
    Column() {
      Row() {
        Text("标题：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextInput({placeholder:"请输入文本",text:this.item.title})
          .borderRadius(16)
          .fontSize(16)
          .width('80%')
          .onChange((newValue : string)=>{
            this.item.title=newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween);

      Row() {
        Text("地点：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextInput({placeholder:"请输入文本",text:this.item.location})
          .borderRadius(16)
          .fontSize(16)
          .width('80%')
          .onChange((newValue : string)=>{
            this.item.location = newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({top:12});

      Row() {
        Text("始于：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        Button(this.item.startTime ? this.item.startTime : "1145-01-04 19:19",{type:ButtonType.Capsule})
          .width('80%')
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date('1145-01-01'),
              end: new Date('2100-12-31'),
              selected: this.parseToDate(this.item.startTime),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: (value: Date) => {
                this.item.startTime = Prompts.getFormattedDate(value);
                console.info('新开始时间已保存: ' + this.item.startTime);
              }
            })
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({top:12});

      Row() {
        Text("终于：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        Button(this.item.endTime ? this.item.endTime : "1949-10-01 15:00",{type:ButtonType.Capsule})
          .width('80%')
          .onClick(() => {
            this.getUIContext().showDatePickerDialog({
              start: new Date('1145-01-01'),
              end: new Date('2100-12-31'),
              selected: this.parseToDate(this.item.endTime),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: (value: Date) => {
                this.item.endTime = Prompts.getFormattedDate(value);
                console.info('新开始时间已保存: ' + this.item.endTime);
              }
            })
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({top:12});

      Row() {
        Text("描述：  ")
          .fontSize(16)
          .textAlign(TextAlign.Start);
        TextArea({ placeholder: "请输入文本", text: this.item.description })

          .width('80%')
          .onChange((newValue : string)=>{
            this.item.description=newValue;
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 })

    }.width('90%').height('100%')
  }

  @Builder
  DeletePopUp(){
    Popup({
      title:{
        text:'删除？！'
      },
      message:{
        text:'将会永久失去这一项（真的很久！）'
      },
      showClose:true,
      onClose:()=>{
        this.isShowDeletePopUp=false;
      },
      buttons:[{
        text:'删吧',
        fontColor:'red',
        action:()=>{
          console.log("试图删除")
          this.onDelete();
          this.isShowDeletePopUp=false;
        }
      }]
    })
  }

  // 将字符串转换为 Date 对象，如果转换失败则返回当前时间作为兜底
  private parseToDate(dateStr: string | undefined): Date {
    if (!dateStr) {
      return new Date(); // 如果没有值，默认显示现在
    }
    const parsed = new Date(dateStr);
    // 检查转换后的 Date 是否有效
    return isNaN(parsed.getTime()) ? new Date() : parsed;
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
        Text(this.item.title ? this.item.title : 'Undefined')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)


        Text(this.item.location ? `@ ${this.item.location}` : '@ Galaxy')
          .padding({top:4})
          .fontSize(16)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Start)


        Text(this.item.startTime ? `◇ ${this.item.startTime}` : "1145-01-04 19:19")
          .fontSize(16)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)
          .padding({ top: 16 })

        Text("↓")
          .fontSize(16)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)

        Text(this.item.endTime ? `◈ ${this.item.endTime}` : "1949-10-01 15:00")
          .fontSize(16)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)

        Text(this.item.description ? this.item.description : 'What can I say?')
          .fontSize(16)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)
          .padding({ top: 8 })

        Row() {
          Button('删除', { type: ButtonType.Capsule })
            .fontColor(Color.Red)
            .backgroundColor('rgba(255,128,128,0.3)')
            .onClick(() => {
              this.isShowDeletePopUp=true
            })
            .bindPopup(this.isShowDeletePopUp,{
              builder:this.DeletePopUp(),
              placement:Placement.Bottom,
              onStateChange:(e)=>{
                if(!e.isVisible){
                  this.isShowDeletePopUp=false;
                }
              }
            });

          Button('编辑', { type: ButtonType.Capsule })
            .fontColor(Color.White)
            .buttonStyle(ButtonStyleMode.NORMAL)
            .onClick(() => {
              this.isShowEditSheet = true
              console.log("试图编辑")
            })
            .bindSheet(this.isShowEditSheet,this.ScheduleItemEditor(),{
              detents: [SheetSize.MEDIUM, SheetSize.LARGE, 600],
              preferType: SheetType.BOTTOM,
              title: { title: `编辑 ${this.item.title}` },
              onDisappear:()=>{this.isShowEditSheet=false},

            });

          Button('确认', { type: ButtonType.Capsule })
            .buttonStyle(ButtonStyleMode.EMPHASIZED)
            .width('50%')
            .backgroundColor(Color.Green)
            .onClick(() => {
              try{
                console.log('试图确认')
                let calendar = CalendarService.getInstance().getCalendar()
                let event: calendarManager.Event = {
                  type: calendarManager.EventType.NORMAL,
                  title: this.item.title,
                  location: {
                    location: this.item.location
                  },
                  startTime: this.parseToDate(this.item.startTime).getTime(),
                  endTime: this.parseToDate(this.item.endTime).getTime(),
                  reminderTime: [30],
                  description: this.item.description,
                }
                calendar?.addEvent(event).then(() => {
                  this.onDelete();
                }).catch((err : Error)=>{
                  console.log("添加日程失败：",err)
                })
              }catch (err){
                console.log("添加日程失败：",err)
              }

            })
        }
        .padding({ top: 16 })
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

      }
      .width('100%')

    }
  }
}


export default class PillendarAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }



  onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        windowStage.loadContent('pages/Index', (error) => {
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
  @StorageProp('subtitle') subtitle:string="Strange";
  @StorageLink('mainItems') items: Array<ScheduleEvent>=[new ScheduleEvent()];



  itemsScroller: Scroller=new Scroller()

  @Builder
  BottomBuilder(){}

  build() {

      Column({ space: 10 }) {
        HdsNavigation() { // 创建HdsNavigation组件
          Scroll(this.itemsScroller) {
            Column() {
              Blank().height('20%').width('100%')
              Grid() {

                ForEach(this.items, (item: ScheduleEvent, index:number) => {

                  GridItem() {
                    Column() {
                      ScheduleItemBuilder({
                        item:item,
                        onDelete: ()=> {
                          this.items.splice(index,1)
                        }
                      });
                    }
                    .width('100%')
                    .padding(16)
                    .backgroundColor('#303030')
                    .borderRadius(16)
                    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                  }
                  .margin({bottom:12})
                },(item:ScheduleEvent)=>item.id)

              }

              .height('auto')
              .width('90%')
              Blank().height('50%').width('100%')
            }
          }
          .edgeEffect(EdgeEffect.Spring)

        }.titleBar({
          content: {
            title: { mainTitle: 'Pillendar', subTitle: this.subtitle },

            // 设置HdsNavigation BottomBuilder区域，包括设置高度，显示类型
            bottomBuilder: {
              builder: (): void => this.BottomBuilder(),
              height: 0,
              showType: BottomBuilderShowType.DIRECTLY_SHOW
            },

          }
        })

        // 设置HdsNavigation标题栏动态显隐，包括设置标题区域，bottomBuilder区域，状态栏区域是否动态隐藏，隐藏模式以及开始隐藏时内容区的滚动距离。
        .dynamicHideTitleBar({
          hideTitleArea: true,
          hideBottomBuilder: true,
          hideStatusBar: false,
          mode: HideMode.SCROLL_UP_TO_BLEND_SCROLL_UP,
          hideOffset: 0
        })
        .height('100%')
        .bindToScrollable([this.itemsScroller]);

      }}
}
