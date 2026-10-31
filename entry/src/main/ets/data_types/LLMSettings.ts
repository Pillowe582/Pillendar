// 大模型接口配置，由设置页读写并持久化
export interface LLMSettings {
  baseUrl: string;
  apiKey: string;
  model: string;
  prompt: string;
  requestJson: string;
}
