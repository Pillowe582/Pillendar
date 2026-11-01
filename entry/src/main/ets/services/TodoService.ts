import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREFERENCES_NAME: string = 'todo_settings';
const DEFAULT_SHOW_IN_TODO_KEY: string = 'default_show_in_todo';
const SHOWN_EVENT_IDS_KEY: string = 'shown_event_ids';

// 待办设置持久化服务：保存新日程是否默认进待办，以及每条日程的在待办中显示开关
export class TodoService {
  private static instance: TodoService;
  private store: preferences.Preferences | undefined = undefined;
  private defaultShowInTodo: boolean = true;
  private shownEventIds: number[] = [];

  public static getInstance(): TodoService {
    if (!TodoService.instance) {
      TodoService.instance = new TodoService();
    }
    return TodoService.instance;
  }

  /**
   * 初始化服务并读取已保存的待办设置
   * @param context 应用上下文
   */
  public async init(context: common.Context): Promise<void> {
    if (this.store !== undefined) {
      return;
    }
    this.store = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    this.defaultShowInTodo = await this.store.get(DEFAULT_SHOW_IN_TODO_KEY, true) as boolean;
    const savedShownIds = await this.store.get(SHOWN_EVENT_IDS_KEY, '') as string;
    if (savedShownIds.length > 0) {
      this.shownEventIds = JSON.parse(savedShownIds) as number[];
    }
  }

  /**
   * 获取新添加的日程是否默认加入待办
   */
  public getDefaultShowInTodo(): boolean {
    return this.defaultShowInTodo;
  }

  /**
   * 修改新添加日程的默认待办设置并持久化
   * @param showInTodo 是否默认加入待办
   */
  public async setDefaultShowInTodo(showInTodo: boolean): Promise<void> {
    this.defaultShowInTodo = showInTodo;
    await this.store?.put(DEFAULT_SHOW_IN_TODO_KEY, showInTodo);
    await this.store?.flush();
  }

  /**
   * 判断指定日程是否在待办中显示
   * @param eventId 日历事件 id
   */
  public isShownInTodo(eventId: number): boolean {
    return this.shownEventIds.includes(eventId);
  }

  /**
   * 设置指定日程是否在待办中显示并持久化
   * @param eventId 日历事件 id
   * @param shown 是否在待办中显示
   */
  public async setShownInTodo(eventId: number, shown: boolean): Promise<void> {
    // 先移除旧记录，再按最新状态写回
    this.shownEventIds = this.shownEventIds.filter((id: number) => id !== eventId);
    if (shown) {
      this.shownEventIds.push(eventId);
    }
    await this.store?.put(SHOWN_EVENT_IDS_KEY, JSON.stringify(this.shownEventIds));
    await this.store?.flush();
  }
}
