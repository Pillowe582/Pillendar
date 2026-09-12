// 将字符串转换为 Date 对象，如果转换失败则返回当前时间作为兜底
export function parseToDate(dateStr: string | undefined): Date {
  if (!dateStr) {
    return new Date(); // 如果没有值，默认显示现在
  }
  const parsed = new Date(dateStr);
  // 检查转换后的 Date 是否有效
  return isNaN(parsed.getTime()) ? new Date() : parsed;
}
