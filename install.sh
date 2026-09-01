#!/usr/bin/env bash
# 万象颜文字功能安装脚本
# 用途：将颜文字功能安装到万象拼音方案
# 用法：bash install.sh [rime_user_dir]
#   不带参数时自动检测默认路径 ~/.local/share/fcitx5/rime
set -uo pipefail

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
info()   { printf '%s\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 定位 rime 用户目录
if [ -n "${1:-}" ]; then
    RIME_DIR="$1"
else
    RIME_DIR="$HOME/.local/share/fcitx5/rime"
fi

echo ""
info "════════════════════════════════════════════"
info " 万象颜文字功能安装"
info " RIME_DIR: $RIME_DIR"
info "════════════════════════════════════════════"
echo ""

# 检查目标目录
if [ ! -d "$RIME_DIR" ]; then
    red "错误: rime 目录不存在: $RIME_DIR"
    red "请确认万象方案已安装，或手动指定路径: bash install.sh /path/to/rime"
    exit 1
fi

if [ ! -f "$RIME_DIR/wanxiang.schema.yaml" ]; then
    red "错误: $RIME_DIR 下未找到 wanxiang.schema.yaml"
    red "请确认这是万象方案的 rime 用户目录"
    exit 1
fi

fail_count=0

# ── 步骤 1：复制数据文件 ──
info "【1/3】复制颜文字数据文件"
mkdir -p "$RIME_DIR/lua/data"
for f in kaomoji.txt kaomoji_replacer.txt; do
    src="$SCRIPT_DIR/lua/data/$f"
    dst="$RIME_DIR/lua/data/$f"
    if [ -f "$src" ]; then
        if cp -f "$src" "$dst"; then
            green "  ✓ $f → lua/data/$f"
        else
            red "  ✗ $f 复制失败"
            fail_count=$((fail_count+1))
        fi
    else
        red "  ✗ 源文件不存在: $src"
        fail_count=$((fail_count+1))
    fi
done

echo ""

# ── 步骤 2：应用 lua 补丁（super_symbols.lua 加载 kaomoji）──
info "【2/3】应用 lua 补丁（super_symbols.lua）"
TARGET="$RIME_DIR/lua/wanxiang/super_symbols.lua"
PATCH="$SCRIPT_DIR/patches/super_symbols_kaomoji.patch"

if [ ! -f "$TARGET" ]; then
    yellow "  ! 目标文件不存在: $TARGET"
    yellow "    跳过补丁（新版万象可能已支持或文件结构变化）"
    yellow "    请手动检查是否需要修改 super_symbols.lua 添加 kaomoji 数据加载"
elif grep -q "data_kaomoji" "$TARGET" 2>/dev/null; then
    green "  ✓ 补丁已应用过（检测到 data_kaomoji），跳过"
else
    # 优先 -p1（新补丁格式带 a/ 前缀），回退 -p0（旧补丁格式）
    local p_level="-p1"
    if ! patch --dry-run -p1 -d "$RIME_DIR" < "$PATCH" >/dev/null 2>&1; then
        if patch --dry-run -p0 -d "$RIME_DIR" < "$PATCH" >/dev/null 2>&1; then
            p_level="-p0"
        fi
    fi
    if patch --dry-run $p_level -d "$RIME_DIR" < "$PATCH" >/dev/null 2>&1; then
        if patch $p_level -d "$RIME_DIR" < "$PATCH"; then
            green "  ✓ 补丁已应用"
        else
            red "  ✗ 补丁应用失败"
            fail_count=$((fail_count+1))
        fi
    else
        yellow "  ! 无法自动应用补丁（新版代码已变动）"
        yellow "    请手动修改 super_symbols.lua，在数据加载处添加 kaomoji 支持"
        yellow "    参考: $PATCH"
        yellow "    关键改动: 添加 kaomoji_path 和 kaomoji store"
        fail_count=$((fail_count+1))
    fi
fi

echo ""

# ── 步骤 3：提示合并配置 ──
info "【3/3】配置合并说明"
CUSTOM="$RIME_DIR/wanxiang.custom.yaml"
PATCH_CONFIG="$SCRIPT_DIR/config/wanxiang.custom.yaml.kaomoji_patch"

if [ -f "$CUSTOM" ] && grep -q "kaomoji" "$CUSTOM" 2>/dev/null && grep -q "_kk_" "$CUSTOM" 2>/dev/null; then
    green "  ✓ wanxiang.custom.yaml 已包含颜文字配置"
else
    yellow "  ! 需要手动合并配置到 wanxiang.custom.yaml"
    echo ""
    info "  将以下文件的内容合并到 $CUSTOM :"
    info "    $PATCH_CONFIG"
    echo ""
    info "  合并方法:"
    info "    1. 打开 $PATCH_CONFIG"
    info "    2. 将内容追加到你的 $CUSTOM 的 patch: 节点下"
    info "    3. 注意: 如果已有 super_symbols/triggers，需整体替换（不能重复）"
    fail_count=$((fail_count+1))
fi

echo ""
echo "════════════════════════════════════════════"
if [ "$fail_count" -eq 0 ]; then
    green "安装完成"
    echo ""
    yellow "下一步：重新部署 fcitx5"
    info "  fcitx5 -r &"
    echo ""
    info "测试:"
    info "  1. 输入 /kk          → 提示「颜文字」"
    info "  2. 输入 /kk.happy    → 开心类颜文字"
    info "  3. 输入 /kk?kaixin   → 模糊搜索"
    info "  4. 输入 开心          → 候选区直接出现颜文字"
else
    red "安装完成，但有 $fail_count 项需手动处理（见上方黄色提示）"
fi
echo "════════════════════════════════════════════"
echo ""
