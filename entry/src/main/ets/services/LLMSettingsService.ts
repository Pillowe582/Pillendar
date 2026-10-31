import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { LLMSettings } from '../data_types/LLMSettings';
import { DEFAULT_LLM_SETTINGS } from '../file_handler/LLMConfig';

const PREFERENCES_NAME: string = 'llm_settings_responses';
const SETTINGS_KEY: string = 'settings';

// 大模型配置持久化服务：Preferences 存储 + 内存缓存
export class LLMSettingsService {
  private static instance: LLMSettingsService;
  private store: preferences.Preferences | undefined = undefined;
  private settings: LLMSettings = { ...DEFAULT_LLM_SETTINGS };

  public static getInstance(): LLMSettingsService {
    if (!LLMSettingsService.instance) {
      LLMSettingsService.instance = new LLMSettingsService();
    }
    return LLMSettingsService.instance;
  }

  /**
   * 初始化服务并读取已保存配置
   * @param context 应用上下文
   */
  public async init(context: common.Context): Promise<void> {
    if (this.store !== undefined) {
      return;
    }
    this.store = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    const savedSettings = await this.store.get(SETTINGS_KEY, '') as string;
    if (savedSettings.length > 0) {
      // 旧版本配置可能缺少新增字段，用默认值补全
      this.settings = { ...DEFAULT_LLM_SETTINGS, ...(JSON.parse(savedSettings) as LLMSettings) };
    }
  }

  /**
   * 获取当前生效的配置
   */
  public get(): LLMSettings {
    return this.settings;
  }

  /**
   * 保存配置并写入持久化存储
   * @param settings 待保存的配置
   */
  public async save(settings: LLMSettings): Promise<void> {
    this.settings = settings;
    await this.store?.put(SETTINGS_KEY, JSON.stringify(settings));
    await this.store?.flush();
  }
}
