# 万象拼音 · 颜文字功能扩展

为 [万象拼音](https://github.com/amzxyz/rime-wanxiang) 添加颜文字（kaomoji）支持。

提供两种输入方式：
- **打字直接出** — 输入「开心」「哈哈」等中文词，候选区自动追加颜文字
- **`/kk` 指令搜索** — 输入 `/kk.happy` 或 `/kk?kaixin` 精确/模糊搜索颜文字

## 功能演示

```
输入「开心」→  1.开心  2.(◕‿◕)  3.(*´▽`*)
输入「爱你」→  1.爱你  2.(♡´▽`♡)
输入「哭」  →  1.哭    2.(╥﹏╥)

输入 /kk              → 提示「颜文字」
输入 /kk.happy        → 开心类颜文字列表
输入 /kk?kaixin       → 模糊搜索拼音（等价 /kk/kaixin）
输入 /kk?love         → 爱心类
```

## 文件结构

```
wxpy-Kaomoji/
├── README.md                                    ← 本文件
├── install.sh                                   ← 一键安装脚本
├── lua/data/
│   ├── kaomoji.txt                              ← /kk 指令数据（141 条，分类+拼音 key）
│   └── kaomoji_replacer.txt                     ← 候选区颜文字映射（约 70 条，中文词 key）
├── patches/
│   └── super_symbols_kaomoji.patch              ← super_symbols.lua 补丁（添加 kaomoji 加载）
└── config/
    └── wanxiang.custom.yaml.kaomoji_patch       ← 配置片段（合并到 wanxiang.custom.yaml）
```

## 前置要求

- 已安装 [万象拼音](https://github.com/amzxyz/rime-wanxiang) 方案（v17.1.0 ~ v17.2.2 已验证）
- fcitx5 + rime（librime）
- **v17.1.0 用户注意**：如果你遇到 emoji 候选不显示的问题（输入「开心」没有 😄），需先修复 super_replacer 的 Config 兼容性 bug，详见下方「已知问题」章节。**v17.2.0+ 官方已修复，无需处理。**

## 安装方法

### 方式一：一键安装（推荐）

```bash
cd /path/to/wxpy-Kaomoji
bash install.sh
```

脚本会自动：
1. 复制数据文件到 `lua/data/`
2. 应用 lua 补丁
3. 提示配置合并（如需）

### 方式二：手动安装

#### 1. 复制数据文件

```bash
cp lua/data/kaomoji.txt      ~/.local/share/fcitx5/rime/lua/data/
cp lua/data/kaomoji_replacer.txt ~/.local/share/fcitx5/rime/lua/data/
```

#### 2. 应用 lua 补丁

```bash
cd ~/.local/share/fcitx5/rime
patch -p0 < /path/to/wxpy-Kaomoji/patches/super_symbols_kaomoji.patch
```

补丁作用：修改 `lua/wanxiang/super_symbols.lua`，使其加载 `data_kaomoji` 数据文件。

如果补丁无法应用（新版万象代码变动），手动修改 `super_symbols.lua` 的数据加载部分，添加：

```lua
local kaomoji_path = config:get_string("super_symbols/data_kaomoji") or "lua/data/kaomoji.txt"

STATE.stores = {
    sym = read_store(sym_path, "super_sym"),
    emoji = read_store(emoji_path, "super_emoji"),
    kaomoji = read_store(kaomoji_path, "super_kaomoji")  -- 新增此行
}
```

#### 3. 合并配置

将 `config/wanxiang.custom.yaml.kaomoji_patch` 的内容追加到你的 `wanxiang.custom.yaml` 的 `patch:` 节点下。

**注意**：如果你已有 `super_symbols/triggers` 配置，需要**整体替换**（不能重复定义），把 kaomoji 那条加进去：

```yaml
  super_symbols/triggers:
    - { kind: sym,      exact: /sym,   label: 超级符号, marks: ["?", "/"] }
    - { kind: emoji,    exact: /emoji, label: 超级表情, marks: ["?", "/"] }
    - { kind: kaomoji,  exact: /kk,    label: 颜文字,   marks: ["?", "/"] }  # 新增
```

#### 4. 重新部署

```bash
fcitx5 -r &
```

## 使用方法

### 方式一：打字直接出（super_replacer）

输入颜文字映射表中的中文词，候选区会自动追加对应颜文字。

覆盖的词类（见 `kaomoji_replacer.txt`）：
- 开心类：开心、高兴、快乐、哈哈、嘿嘿、可爱、么么哒…
- 爱心类：爱你、爱心、亲亲、抱抱、喜欢你、比心…
- 哭/伤心：哭、伤心、难过、呜呜、委屈…
- 生气类：生气、哼、掀桌、怒…
- 惊讶类：惊讶、震惊、哇、什么…
- 无语类：无语、汗、无奈、叹气、尴尬…
- 问候类：你好、再见、拜拜、晚安…
- 其他：加油、好的、同意、饿了、好吃…

### 方式二：/kk 指令搜索（super_symbols）

| 输入 | 作用 | 示例 |
|------|------|------|
| `/kk` | 显示颜文字分类提示 | 提示「颜文字」 |
| `/kk.happy` | 精确查找分类 | 开心类颜文字 |
| `/kk.kaixin` | 拼音精确查找 | 同上 |
| `/kk?kaixin` | 模糊搜索（拼音） | 匹配含 kaixin 的条目 |
| `/kk?love` | 模糊搜索（英文） | 匹配含 love 的条目 |
| `/kk/kaixin` | 模糊搜索（等价 `?`） | 同上 |

数据文件 `kaomoji.txt` 的分类（name 同时支持英文和拼音，两种都能搜到）：

| 分类 | 英文 key | 拼音 key |
|------|----------|----------|
| 开心 | happy | kaixin |
| 笑 | laugh | xiao |
| 爱心 | love | ai |
| 哭 | cry | ku |
| 生气 | angry | shengqi |
| 惊讶 | surprise | jingya |
| 无语 | speechless | wuyu |
| 害羞 | shy | haixiu |
| 困惑 | confused | kunhuo |
| 点赞 | thumbsup / ok / agree / good | zan / haode / tongyi / hao |
| 招手 | wave / bye | zhaoshou / zaijian / baibai |
| 睡觉 | sleep | shuijiao |
| 吃货 | eat | chi |
| 玩闹 | playful | wannao |
| 鼓励 | cheer | jiayou |
| 问候 | hello / hi | nihao / ninhao / aniong |

## 自定义颜文字

### 添加候选区颜文字（打字直接出）

编辑 `lua/data/kaomoji_replacer.txt`，格式：

```
中文词<TAB>颜文字
```

示例：
```
嘿嘿	(￣▽￣)"
牛掰	666
```

修改后需删除缓存让其重建：
```bash
rm -rf ~/.local/share/fcitx5/rime/replacer.userdb
fcitx5 -r &
```

### 添加 /kk 指令颜文字

编辑 `lua/data/kaomoji.txt`，格式：

```
分类.子类<TAB>颜文字
```

示例：
```
happy.dance	＼(＾▽＾)／
kaixin.tiaowu	＼(＾▽＾)／
```

修改后重新部署即可（`fcitx5 -r &`），无需删除 userdb。

## 数据文件格式说明

### kaomoji.txt（/kk 指令用）

```
# 注释行
happy	(◕‿◕)
happy.smile	(｡◕‿◕｡)
kaixin	(◕‿◕)
```

- 用 TAB 分隔 name 和颜文字
- name 支持 `.` 分层：`分类.子类`
- 同一个颜文字可以有多个 key（英文 + 拼音）

### kaomoji_replacer.txt（候选区用）

```
# 注释行
开心	(◕‿◕)
开心	(*´▽`*)
```

- 用 TAB 分隔中文词和颜文字
- 同一个中文词可以对应多个颜文字（多行），会作为多个候选追加

## 已知问题

### emoji 候选不显示（super_replacer Config bug）

> **v17.2.0+ 已官方修复**：万象作者在 v17.2.x 改用 `wanxiang.load_file_with_fallback("build/default.yaml")` 直接读取文件，彻底绕开了 `Config()` 调用。**以下内容仅适用于 v17.1.0 及更早版本。**

**现象**：输入「开心」时，不仅没有颜文字，连 emoji（😄）也没有。

**原因**：万象 v17.1.0 的 `super_replacer.lua` 调用全局 `Config("default")`，但 librime 1.10.0 的 lua 绑定未导出此函数，导致 `M.init` 崩溃，`replacer.userdb` 无法构建。

**判断方法**：检查 `~/.local/share/fcitx5/rime/` 下是否存在 `replacer.userdb`。如果不存在且其他 userdb（tips.userdb、en.userdb 等）正常，即为此 bug。

**修复（仅 v17.1.0）**：修改 `lua/wanxiang/super_replacer.lua` 的 `enabled_schema_ids()` 函数，将：

```lua
local config = Config("default")
```

改为：

```lua
local config
if type(Config) == "function" then
    local ok_cfg, cfg = pcall(Config, "default")
    if ok_cfg then config = cfg end
end
```

**升级用户**：如果你遇到此问题，最简单的解决方案是升级万象到 v17.2.0+，官方已修复。


## 卸载

1. 删除数据文件：
   ```bash
   rm ~/.local/share/fcitx5/rime/lua/data/kaomoji.txt
   rm ~/.local/share/fcitx5/rime/lua/data/kaomoji_replacer.txt
   ```

2. 还原 lua 补丁：
   ```bash
   cd ~/.local/share/fcitx5/rime
   patch -R -p0 < /path/to/wxpy-Kaomoji/patches/super_symbols_kaomoji.patch
   ```

3. 从 `wanxiang.custom.yaml` 中删除颜文字相关配置

4. 删除缓存并重新部署：
   ```bash
   rm -rf ~/.local/share/fcitx5/rime/replacer.userdb
   fcitx5 -r &
   ```

## 兼容性

- 万象版本：v17.1.0 ~ v17.2.2 已验证（Config bug 仅影响 v17.1.0，v17.2.0+ 官方已修复）
- librime：1.10.0
- 系统：Ubuntu 24.04（fcitx5）

新版万象如果修改了 `super_symbols.lua` 的数据加载逻辑，kaomoji 补丁可能需要手动适配，参考手动安装章节。

## 许可

颜文字数据为公开常用收集整理。如有版权顾虑请联系删除。
