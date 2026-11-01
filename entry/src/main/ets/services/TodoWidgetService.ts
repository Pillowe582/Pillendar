import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { calendarManager } from '@kit.CalendarKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { TodoService } from './TodoService';

const PREFERENCES_NAME: string = 'todo_widget';
const FORM_IDS_KEY: string = 'form_ids';
const MILLISECONDS_PER_DAY: number = 24 * 60 * 60 * 1000;
const CALENDAR_ACCOUNT: calendarManager.CalendarAccount = {
  name: 'Pillendar',
  type: calendarManager.CalendarType.LOCAL,
  displayName: 'Pillendar'
};

// 待办卡片中单条待办的数据模型，卡片与卡片扩展共用同一份字段定义
export class TodoWidgetItem {
  id: number = 0;
  title: string = '';
  time: string = '';
  expired: boolean = false;
}

// 待办卡片服务：读取待办数据、登记卡片实例、推送卡片刷新
export class TodoWidgetService {
  private static instance: TodoWidgetService;
  private context: common.Context | undefined = undefined;
  private store: preferences.Preferences | undefined = undefined;
  private calendar: calendarManager.Calendar | undefined = undefined;

  public static getInstance(): TodoWidgetService {
    if (!TodoWidgetService.instance) {
      TodoWidgetService.instance = new TodoWidgetService();
    }
    return TodoWidgetService.instance;
  }

  /**
   * 记录上下文并打开卡片配置，应用与卡片扩展都需先调用
   * @param context 应用或卡片扩展的上下文
   */
  public async init(context: common.Context): Promise<void> {
    this.context = context;
    this.store = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  /**
   * 登记卡片实例，数据变化时向它推送刷新
   * @param formId 卡片实例 id
   */
  public async registerFormId(formId: string): Promise<void> {
    const formIds = await this.getFormIds();
    if (formIds.includes(formId)) {
      return;
    }
    formIds.push(formId);
    await this.saveFormIds(formIds);
  }

  /**
   * 注销卡片实例，卡片被移除后不再向它推送刷新
   * @param formId 卡片实例 id
   */
  public async unregisterFormId(formId: string): Promise<void> {
    const formIds = await this.getFormIds();
    await this.saveFormIds(formIds.filter((id: string) => id !== formId));
  }

  /**
   * 向所有已登记的卡片推送最新待办数据
   */
  public async updateAllForms(): Promise<void> {
    const formIds = await this.getFormIds();
    if (formIds.length === 0) {
      return;
    }
    const bindingData = await this.buildBindingData();
    for (const formId of formIds) {
      await formProvider.updateForm(formId, bindingData);
    }
  }

  /**
   * 构造卡片绑定数据（待办列表以 JSON 字符串传给卡片）
   */
  public async buildBindingData(): Promise<formBindingData.FormBindingData> {
    const items = await this.loadItems();
    return formBindingData.createFormBindingData({ todosJson: JSON.stringify(items) });
  }

  /**
   * 从卡片上完成一条待办：删除对应日历事件并清除待办标记
   * @param eventId 日历事件 id
   */
  public async completeTodo(eventId: number): Promise<void> {
    const calendar = await this.requireCalendar();
    await calendar.deleteEvent(eventId);
    const todoService = TodoService.getInstance();
    await todoService.init(this.getContext());
    await todoService.setDdl(eventId, false);
  }

  /**
   * 读取待办列表：日历中标记为待办的事件，按截止时间升序
   */
  private async loadItems(): Promise<TodoWidgetItem[]> {
    const calendar = await this.requireCalendar();
    const todoService = TodoService.getInstance();
    await todoService.init(this.getContext());
    const events = await calendar.getEvents();
    const todoEvents = events.filter((event: calendarManager.Event) => {
      return todoService.isDdl(event.id) && event.endTime !== undefined;
    });
    todoEvents.sort((left: calendarManager.Event, right: calendarManager.Event) => left.endTime - right.endTime);
    const now = Date.now();
    return todoEvents.map((event: calendarManager.Event) => {
      const item = new TodoWidgetItem();
      item.id = event.id;
      item.title = event.title ?? '未命名待办';
      item.time = this.formatDeadline(event.endTime);
      item.expired = event.endTime < now;
      return item;
    });
  }

  /**
   * 把截止时间格式化为卡片上显示的文字
   * @param endTime 截止时间（毫秒时间戳）
   */
  private formatDeadline(endTime: number): string {
    const now = new Date();
    const deadline = new Date(endTime);
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const deadlineStart = new Date(deadline.getFullYear(), deadline.getMonth(), deadline.getDate()).getTime();
    const dayOffset = Math.round((deadlineStart - todayStart) / MILLISECONDS_PER_DAY);
    const clock = `${this.pad(deadline.getHours())}:${this.pad(deadline.getMinutes())}`;
    if (dayOffset === 0) {
      return `今天 ${clock}`;
    }
    if (dayOffset === 1) {
      return `明天 ${clock}`;
    }
    if (dayOffset === -1) {
      return `昨天 ${clock}`;
    }
    return `${deadline.getMonth() + 1}月${deadline.getDate()}日 ${clock}`;
  }

  // 补齐分钟数到两位
  private pad(value: number): string {
    return value.toString().padStart(2, '0');
  }

  private getContext(): common.Context {
    if (this.context === undefined) {
      throw new Error('待办卡片服务未初始化');
    }
    return this.context;
  }

  private async requireCalendar(): Promise<calendarManager.Calendar> {
    if (this.calendar === undefined) {
      const calendarManagerInstance = calendarManager.getCalendarManager(this.getContext());
      this.calendar = await calendarManagerInstance.getCalendar(CALENDAR_ACCOUNT);
    }
    return this.calendar;
  }

  private async getFormIds(): Promise<string[]> {
    if (this.store === undefined) {
      throw new Error('待办卡片服务未初始化');
    }
    const savedFormIds = await this.store.get(FORM_IDS_KEY, '') as string;
    if (savedFormIds.length === 0) {
      return [];
    }
    return JSON.parse(savedFormIds) as string[];
  }

  private async saveFormIds(formIds: string[]): Promise<void> {
    if (this.store === undefined) {
      throw new Error('待办卡片服务未初始化');
    }
    await this.store.put(FORM_IDS_KEY, JSON.stringify(formIds));
    await this.store.flush();
  }
}
