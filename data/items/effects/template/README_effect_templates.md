# effect template 整理版

このフォルダは、既存の effect `.tres` を「重複をまとめたテンプレート/見本」用に整理したものです。

## ルール
- ファイル名は `OO_effect_template.tres` に統一
- 同じ型のものは1つに統合
- 数値はそのまま使える見本寄りの値を残しています
- 実運用ではテンプレート本体を直接編集せず、**複製してから使う**のがおすすめです
- **テンプレートは作り方の見本です。実際の ItemData は effect を外部参照せず、item 内に直接 sub_resource として持たせる運用でもOKです**

## テンプレート一覧
- `restore_hp_effect_template.tres`
- `restore_hunger_effect_template.tres`
- `cure_status_effect_template.tres`
- `apply_dot_status_effect_template.tres`
- `apply_control_status_effect_template.tres`
- `curse_status_effect_template.tres`
- `buff_percent_modifier_effect_template.tres`
- `buff_flat_modifier_effect_template.tres`
- `debuff_percent_modifier_effect_template.tres`
- `debuff_flat_modifier_effect_template.tres`
- `deal_damage_effect_template.tres`
- `teleport_effect_template.tres`
- `permanent_stat_growth_effect_template.tres`
- `grant_item_effect_template.tres`
- `grant_currency_effect_template.tres`

## 使い分けの目安
- HP回復 → `restore_hp_effect_template`
- 空腹回復 → `restore_hunger_effect_template`
- 毒/麻痺/睡眠治療 → `cure_status_effect_template`
- 毒/炎上/凍傷付与 → `apply_dot_status_effect_template`
- 睡眠/混乱/盲目/幻覚付与 → `apply_control_status_effect_template`
- 呪い玉など、複数の状態異常をランダム付与 → `curse_status_effect_template`
- 攻撃/防御/速度の割合バフ → `buff_percent_modifier_effect_template`
- 命中/回避/会心率の固定値バフ → `buff_flat_modifier_effect_template`
- 攻撃/防御/速度の割合デバフ → `debuff_percent_modifier_effect_template`
- 命中/回避/会心率の固定値デバフ → `debuff_flat_modifier_effect_template`
- 爆弾などの直接ダメージ → `deal_damage_effect_template`
- テレポート石系 → `teleport_effect_template`
- 種・木の実などの恒久成長 → `permanent_stat_growth_effect_template`
- 補給袋系のランダムアイテム取得 → `grant_item_effect_template`
- 小金袋系のランダム金額取得 → `grant_currency_effect_template`

## 状態異常付与テンプレートの使い方
### `apply_control_status_effect_template`
- `status_id` を付与したい状態異常IDに変更する
  - 例: `&"blind"`, `&"hallucination"`, `&"confusion"`, `&"sleep"`
- `duration_type` で効果時間の扱いを決める
- `duration_value` で効果時間を決める
- `blind_sand` や `hallucination_powder` のような「敵1体に状態異常を付与する消費アイテム」の effect 見本

### `curse_status_effect_template`
- `status_id = &"curse"` の呪い付与用テンプレート
- `curse_status_pool` に、呪いからランダム付与される状態異常候補を入れる
- `curse_status_power_overrides` で、状態異常ごとの強さ補正を設定する
- `curse_orb` のような「複数の状態異常をランダムでばらまく」アイテムの effect 見本

## 取得系テンプレートの使い方
### `grant_item_effect_template`
- `grant_item_ids` に個別候補を入れる
- `grant_item_categories` にカテゴリ候補を入れる
- `grant_item_kind_min / max` で「何種類出るか」を決める
- `grant_item_amount_min / max` で「各種類が何個出るか」を決める
- 個別候補とカテゴリ候補は**両方同時に使える**
- 候補プールからは**重複なしでランダム抽選**される

### `grant_currency_effect_template`
- `grant_currency_amount_min / max` で、獲得goldのランダム範囲を決める
- 固定値にしたいなら `min` と `max` を同じ値にする
