// HDS 标题栏（FREE 模式）的尺寸与操作按钮的摆放位置

// 只有主标题时标题栏高度
export const TITLE_BAR_HEIGHT_FREE: number = 112;

// 主标题加副标题时标题栏高度
export const TITLE_BAR_HEIGHT_WITH_SUBTITLE: number = 138;

// 操作按钮高度
export const TITLE_ACTION_HEIGHT: number = 36;

// 只有主标题时，操作按钮顶部距离标题栏顶部的距离，按钮与标题文字垂直居中对齐
export const TITLE_ACTION_MARGIN_TOP_FREE: number = 66;

// 带副标题时，操作按钮顶部距离标题栏顶部的距离
export const TITLE_ACTION_MARGIN_TOP_WITH_SUBTITLE: number = 70;

// 操作按钮距离屏幕右边缘的距离
export const TITLE_ACTION_MARGIN_RIGHT: number = 16;

// 标题栏收起后（只有一行小标题）的高度
export const TITLE_BAR_HEIGHT_MINI: number = 56;

/**
 * 计算滚动时操作按钮需要跟随标题移动的距离
 * @param scrollOffset 列表当前的滚动偏移
 * @param actionMarginTop 未滚动时操作按钮顶部距离标题栏顶部的距离
 * @returns 按钮的垂直位移，负值表示向上
 */
export function getTitleActionTranslateY(scrollOffset: number, actionMarginTop: number): number {
  // 标题文字从展开位置移动到收起后的标题栏中间
  const expandedCenter = actionMarginTop + TITLE_ACTION_HEIGHT / 2;
  const miniCenter = TITLE_BAR_HEIGHT_MINI / 2;
  const maxRise = expandedCenter - miniCenter;
  const clampedOffset = Math.min(Math.max(scrollOffset, -maxRise), maxRise);
  return -clampedOffset;
}
