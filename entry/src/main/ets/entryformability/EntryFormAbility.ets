import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { TodoWidgetService } from '../services/TodoWidgetService';

// 待办卡片的生命周期入口：提供卡片数据、处理卡片上的完成操作
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    const service = TodoWidgetService.getInstance();
    // 卡片添加时先返回空列表，随后异步读取待办并推送最新数据
    this.prepareForm(service, formId);
    return formBindingData.createFormBindingData({ todosJson: '[]' });
  }

  onUpdateForm(formId: string) {
    this.pushUpdate(formId);
  }

  onFormEvent(formId: string, message: string) {
    const params = JSON.parse(message) as Record<string, Object>;
    // 系统把 postCardAction 的 params 单独放在 params 字段里，外层 action 固定为 message
    const payload = params['params'] as Record<string, Object>;
    if (payload['action'] !== 'complete') {
      return;
    }
    this.completeTodo(formId, payload['eventId'] as number);
  }

  onRemoveForm(formId: string) {
    const service = TodoWidgetService.getInstance();
    this.unregisterForm(service, formId);
  }

  /**
   * 初始化服务、登记卡片并推送首次数据
   * @param service 待办卡片服务
   * @param formId 卡片实例 id
   */
  private async prepareForm(service: TodoWidgetService, formId: string): Promise<void> {
    await service.init(this.context);
    await service.registerFormId(formId);
    await this.pushUpdate(formId);
  }

  /**
   * 注销卡片实例
   * @param service 待办卡片服务
   * @param formId 卡片实例 id
   */
  private async unregisterForm(service: TodoWidgetService, formId: string): Promise<void> {
    await service.init(this.context);
    await service.unregisterFormId(formId);
  }

  /**
   * 读取最新待办并推送给指定卡片
   * @param formId 卡片实例 id
   */
  private async pushUpdate(formId: string): Promise<void> {
    const service = TodoWidgetService.getInstance();
    await service.init(this.context);
    const bindingData = await service.buildBindingData();
    await formProvider.updateForm(formId, bindingData);
  }

  /**
   * 完成一条待办后刷新卡片
   * @param formId 卡片实例 id
   * @param eventId 日历事件 id
   */
  private async completeTodo(formId: string, eventId: number): Promise<void> {
    const service = TodoWidgetService.getInstance();
    await service.init(this.context);
    await service.completeTodo(eventId);
    await this.pushUpdate(formId);
  }
}
