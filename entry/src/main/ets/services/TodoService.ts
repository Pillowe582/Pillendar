import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME: string = 'todo_settings';
const DDL_EVENT_IDS_KEY: string = 'ddl_event_ids';

// 待办状态持久化服务：记录哪些日历事件是只有截止时间的待办
export class TodoService {
  private static instance: TodoService;
  private store: preferences.Preferences | undefined = undefined;
  private ddlEventIds: number[] = [];

  public static getInstance(): TodoService {
    if (!TodoService.instance) {
      TodoService.instance = new TodoService();
    }
    return TodoService.instance;
  }

  /**
   * 初始化服务并读取已保存的待办状态
   * @param context 应用上下文
   */
  public async init(context: common.Context): Promise<void> {
    if (this.store !== undefined) {
      return;
    }
    this.store = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    const savedIds = await this.store.get(DDL_EVENT_IDS_KEY, '') as string;
    if (savedIds.length > 0) {
      this.ddlEventIds = JSON.parse(savedIds) as number[];
    }
  }

  /**
   * 判断指定日历事件是否为待办（只有截止时间）
   * @param eventId 日历事件 id
   */
  public isDdl(eventId: number): boolean {
    return this.ddlEventIds.includes(eventId);
  }

  /**
   * 设置指定日历事件是否为待办并持久化
   * @param eventId 日历事件 id
   * @param ddl 是否为待办
   */
  public async setDdl(eventId: number, ddl: boolean): Promise<void> {
    // 先移除旧记录，再按最新状态写回
    this.ddlEventIds = this.ddlEventIds.filter((id: number) => id !== eventId);
    if (ddl) {
      this.ddlEventIds.push(eventId);
    }
    await this.store?.put(DDL_EVENT_IDS_KEY, JSON.stringify(this.ddlEventIds));
    await this.store?.flush();
  }
}
