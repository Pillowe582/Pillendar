import { http } from '@kit.NetworkKit';

// 大模型接口请求：连通性测试与可用模型列表
export class LLMService {
  /**
   * 拉取可用模型列表，失败时抛出异常
   * @param baseUrl 大模型baseUrl
   * @param apiKey API Key
   * @returns 模型名称列表
   */
  public static async fetchModels(baseUrl: string, apiKey: string): Promise<string[]> {
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(this.getModelsUrl(baseUrl), {
      method: http.RequestMethod.GET,
      header: {
        'Authorization': `Bearer ${apiKey}`
      },
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 10000,
      readTimeout: 10000
    });
    httpRequest.destroy();

    if (response.responseCode !== http.ResponseCode.OK) {
      throw new Error(`状态码 ${response.responseCode}`);
    }

    const result = JSON.parse(response.result as string) as { data: Array<Record<string, string>> };
    return result.data.map((model: Record<string, string>) => model.id);
  }

  // 由聊天接口地址推导模型列表地址，如 https://api.deepseek.com/chat/completions -> https://api.deepseek.com/models
  private static getModelsUrl(baseUrl: string): string {
    const chatCompletionsPath = '/chat/completions';
    const trimmedUrl = baseUrl.replace(/\/+$/, '');
    const modelsBaseUrl = trimmedUrl.endsWith(chatCompletionsPath)
      ? trimmedUrl.slice(0, -chatCompletionsPath.length)
      : trimmedUrl;
    return `${modelsBaseUrl}/models`;
  }
}
