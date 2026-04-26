# effect template 整理版

このフォルダは、既存の effect `.tres` を  
「重複をまとめたテンプレート / 見本」として整理したものです。

ItemData に直接 effect を `sub_resource` として持たせる場合でも、  
ここにある `.tres` を見本として使えます。

---

## 基本ルール

- ファイル名は `OO_effect_template.tres` に統一する
- 同じ型の effect は、なるべく1つのテンプレートにまとめる
- 数値は、そのまま使える見本寄りの値を入れている
- 実運用ではテンプレート本体を直接編集せず、**複製してから使う**
- 実際の ItemData 側では、effect を外部 `.tres` として参照しても、item 内に `sub_resource` として直接持たせてもOK

---

## テンプレート一覧

### 回復系

| テンプレート | 用途 |
|---|---|
| `restore_hp_effect_template.tres` | HP回復 |
| `restore_hunger_effect_template.tres` | 空腹度回復 |

### 状態異常系

| テンプレート | 用途 |
|---|---|
| `cure_status_effect_template.tres` | 毒・麻痺・睡眠などの治療 |
| `apply_dot_status_effect_template.tres` | 毒・炎上・凍傷などの継続ダメージ付与 |
| `apply_control_status_effect_template.tres` | 睡眠・混乱・盲目・幻覚などの行動妨害付与 |

### バフ / デバフ系

| テンプレート | 用途 |
|---|---|
| `buff_percent_modifier_effect_template.tres` | 攻撃・防御・速度などの割合バフ |
| `buff_flat_modifier_effect_template.tres` | 命中・回避・会心率などの固定値バフ |
| `debuff_percent_modifier_effect_template.tres` | 攻撃・防御・速度などの割合デバフ |
| `debuff_flat_modifier_effect_template.tres` | 命中・回避・会心率などの固定値デバフ |

### ダメージ / 移動 / 成長系

| テンプレート | 用途 |
|---|---|
| `deal_damage_effect_template.tres` | 爆弾などの直接ダメージ |
| `teleport_effect_template.tres` | テレポート石などの移動効果 |
| `permanent_stat_growth_effect_template.tres` | 種・木の実などの恒久ステータス成長 |

### 取得系

| テンプレート | 用途 |
|---|---|
| `grant_item_effect_template.tres` | 補給袋などのランダムアイテム取得 |
| `grant_currency_effect_template.tres` | 小金袋などのランダム金額取得 |

---

# 使い分けの目安

## 回復系

### HPを回復するアイテム

使用テンプレート：

```txt
restore_hp_effect_template.tres
