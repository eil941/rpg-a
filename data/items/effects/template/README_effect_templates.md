# effect template 整理版

このフォルダは、既存の effect `.tres` を「重複をまとめたテンプレート/見本」用に整理したものです。

## ルール
- ファイル名は `OO_effect_template.tres` に統一
- 同じ型のものは1つに統合
- 数値はそのまま使える見本寄りの値を残しています
- 実運用ではテンプレート本体を直接編集せず、**複製してから使う**のがおすすめです

## テンプレート一覧
- `restore_hp_effect_template.tres`
- `restore_hunger_effect_template.tres`
- `cure_status_effect_template.tres`
- `apply_dot_status_effect_template.tres`
- `apply_control_status_effect_template.tres`
- `buff_percent_modifier_effect_template.tres`
- `buff_flat_modifier_effect_template.tres`
- `debuff_percent_modifier_effect_template.tres`
- `debuff_flat_modifier_effect_template.tres`
- `deal_damage_effect_template.tres`
- `teleport_effect_template.tres`
- `permanent_stat_growth_effect_template.tres`

## 使い分けの目安
- HP回復 → `restore_hp_effect_template`
- 空腹回復 → `restore_hunger_effect_template`
- 毒/麻痺/睡眠治療 → `cure_status_effect_template`
- 毒/炎上/凍傷付与 → `apply_dot_status_effect_template`
- 睡眠/混乱付与 → `apply_control_status_effect_template`
- 攻撃/防御/速度の割合バフ → `buff_percent_modifier_effect_template`
- 命中/回避/会心率の固定値バフ → `buff_flat_modifier_effect_template`
- 攻撃/防御/速度の割合デバフ → `debuff_percent_modifier_effect_template`
- 命中/回避/会心率の固定値デバフ → `debuff_flat_modifier_effect_template`
- 爆弾などの直接ダメージ → `deal_damage_effect_template`
- テレポート石系 → `teleport_effect_template`
- 種・木の実などの恒久成長 → `permanent_stat_growth_effect_template`
