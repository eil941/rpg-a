# Cognitive Debt Backlog

Step 11-B 時点で見えている認知的負債の整理候補です。これは修正指示ではなく、「将来どこを深掘り・整理すると楽になるか」のメモです。

## 整理候補一覧

| 領域 | 現状のしんどさ | 理由 | 今すぐ直すべきか | 将来の整理案 | リスク |
| --- | --- | --- | --- | --- | --- |
| `scripts/core/unit.gd` | 非常に大きい | 移動、interaction、装備、initial inventory、effects、death drop、save/loadが同居 | いいえ | まずは「Unit lifecycle」「equipment/stat」「death/save」などdocsで分ける。将来helper分割を検討 | 無理に分けるとsave/loadや死亡処理を壊しやすい |
| `scripts/item/inventory_ui.gd` | 高密度 | normal/trade/chest/held item/keyboard/tooltipが同居 | いいえ | [../systems/inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md) を足場に、将来 side panel / held item helper 分離を検討 | UI操作の退行、item消失、free済み参照 |
| `scripts/data/game_data_registry.gd` | loaderが多い | 全TSVのload/build/validate/debug dumpが集中 | いいえ | TSVカテゴリ別のloader map docsを追加。将来 registry sub-loader 化を検討 | 読み込み順・fallback互換性を壊す |
| map scene scripts | 似たspawn/save処理が複数 | `main.gd`, `FiledMap.gd`, `dungeon_main.gd` に似た責務がある | いいえ | Map spawn/persistence deep dive docsを作り、共通化候補だけ棚卸し | mapごとの例外を消してしまう |
| `QuestManager` | 広い | template/generated quest、受注、完了、報酬、WorldState連携がある | いいえ | Quest lifecycle deep dive docsを作る | quest resetやsave互換性の破損 |
| Save / WorldState 境界 | 分かりづらい | PlayerData、WorldState、GlobalDungeon、GlobalDetailMap、map scene saveが絡む | いいえ | 保存対象一覧とowner docsを追加 | 状態消失、二重復元、new game reset漏れ |
| DebugSettings | 確認機能が増えている | Stepごとのdebug flag/start item/scope設定が蓄積 | 急ぎではない | DebugSettings inventory docsを作り、default ON/OFF履歴を整理 | debug defaultを誤ると通常プレイに影響 |
| Equipment effect | 仕様は安定したが入口が複数 | passiveはUnit、attackはCombatManager、dataはitem_effect_links | いいえ | Equipment effect spec docsを追加 | consumable effectと混同しやすい |
| Death drop | docsはあるが実装入口がUnitに埋まる | `Unit.handle_death()` と `drop_inventory_items_on_death_if_needed()` が大きい | いいえ | death path diagramを追加 | 二重drop、装備drop漏れ |
| Initial inventory | death dropと名前が混同されやすい | spawn時所持品でありdeath時lootではない | いいえ | Data docsに「spawn-time carried inventory」と繰り返し明記 | drop tableを早く作りすぎる |
| Trade / Chest ownership | 不正取得リスクが見えづらい | held item sourceがscene跨ぎで無効になることがある | 中 | trade/chest item ownershipの小docs作成 | item消失、不正取得、free済み参照 |
| UI lock | 通常inventoryだけ移動可という例外がある | `is_ui_locked()` と `is_inventory_open()` の意味が違う | 中 | UI lock matrixを維持する | 通常inventory中移動を誤って止める |

## 今すぐ直さない理由

- 現在の目的は認知的負債の可視化であり、実装変更ではありません。
- 高密度ファイルほど、目的なしの分割は退行リスクが高いです。
- まずはdocsで「どこが危ないか」を共有し、次に小さいStepで深掘り・検証・分割候補を決める方が安全です。

## 近い将来の深掘り候補

| 候補Step | 内容 | 期待効果 |
| --- | --- | --- |
| Step 11-D | `Unit.gd` の lifecycle別読み方docsを作る | Unit変更時の入口が分かる |
| Step 11-E | `GameDataRegistry` loaderカテゴリ別一覧を作る | TSV追加時に迷いにくくなる |
| Step 11-F | Save/WorldState/PlayerData の保存対象一覧を作る | save/load系の変更が安全になる |
| Step 11-G | Map spawn/persistence deep diveを作る | field/detail/dungeonの違いを把握しやすくなる |

## Codex依頼時に指定するとよいこと

- 対象サブシステム名。
- 触ってよいファイルと触らないファイル。
- データ変更あり/なし。
- scene跨ぎやsave/load確認が必要か。
- Godot実行確認の範囲。
- debug flagを一時ONにしてよいか、最後にOFFへ戻すか。
