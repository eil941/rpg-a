# GameDataRegistry Debug Dump Audit

## 目的

Step 12-B は、`GameDataRegistry` の起動時 / TSV読込時 debug dump を通常化するための調査-only Stepでした。

このdocsの目的は、`scripts/data/game_data_registry.gd` がどこで何を出力しているかを整理し、後続Stepで以下を判断しやすくすることです。

- 通常時OFFにするか
- `DebugSettings` 配下へ寄せるか
- summaryだけ残すか
- warning/errorはそのまま残すか

Step 12-C では、この調査をもとに `DebugSettings` へ `debug_game_data_load_summary` / `debug_game_data_load_details` を追加し、`debug_print_loaded_data()` の summary / details を小さくgate化しました。

Step 12-C後の通常状態:

- `debug_game_data_load_summary = true`
- `debug_game_data_load_details = false`
- 件数summaryは起動時に出ます。
- Items / Effects / Links / Enemies / Quests などの詳細dumpは通常OFFです。
- `push_warning()` / `push_error()` はこのflagでは止めません。
- loader順、TSV読込仕様、`validate_all()` の呼び出し順と内容は変更していません。

関連docs:

- [Debug Output Normalization Audit](debug_output_normalization_audit.md)
- [DebugSettings Deep Dive](../systems/debug_settings_deep_dive.md)
- [GameDataRegistry Loader Map](../systems/data/game_data_registry_loader_map.md)
- [Data / Spawn / Save System Deep Dive](../systems/data/data_spawn_save_system_deep_dive.md)
- [TSV Migration Audit](../migration/tsv_migration_audit.md)
- [TSV Migration Completion](../migration/tsv_migration_completion.md)

## 調査対象

主な対象は `scripts/data/game_data_registry.gd` です。

重点的に見た入口:

| 対象 | 役割 | 今回の観点 |
| --- | --- | --- |
| `_ready()` | Autoload初期化時に `load_all()` と `validate_all()` を呼ぶ | 起動時出力の入口 |
| `load_all()` | TSVを順番に読み込み、辞書やResourceへ変換する | 末尾で debug dump を呼ぶか |
| `debug_print_loaded_data()` | 読込後の件数summaryと詳細dumpを出す | 通常化の主対象 |
| `validate_all()` | runtime側の限定的validate | warning/errorの役割 |
| `_load_tsv()` | TSV必須読込 | load failure時の `push_error()` |
| `_load_resource_or_null()` | resource path読込 | missing resource時の `push_warning()` |
| `_warn_*()` / `_normalize_*()` / `_validate_*()` 系 | fallbackや参照欠けを通知 | debug dumpとは分ける |

## 調査方法

実行した主な検索:

```powershell
rg -n "debug_print_loaded_data|\[GameData\]|print\(|push_warning|push_error|validate_all|load_all" scripts/data/game_data_registry.gd
rg -n "debug_print_loaded_data|\[GameData\]" scripts docs
rg -n "GameDataRegistry" docs scripts
rg -n "GameDataRegistry|debug_print_loaded_data|\[GameData\]" docs/backlog/debug_output_normalization_audit.md docs/systems/debug_settings_deep_dive.md docs/systems/data/game_data_registry_loader_map.md
```

補助的に、`load_all()`、`validate_all()`、`debug_print_loaded_data()`、`_load_tsv()`、`_load_resource_or_null()` 周辺を行番号付きで確認しました。

## 起動時の呼び出し経路

現在の入口は次の通りです。

```text
GameDataRegistry._ready()
↓
load_all()
↓
各 _load_*() を順番に実行
↓
debug_print_loaded_data()
↓
validate_all()
↓
_validate_items()
_validate_item_effects()
_validate_quests()
```

重要点:

- `_ready()` は `load_all()` のあとに `validate_all()` を呼びます。
- `load_all()` の末尾で `debug_print_loaded_data()` が無条件に呼ばれています。
- `debug_print_loaded_data()` 自体は引き続き `load_all()` の末尾で呼ばれます。
- Step 12-C以降、summary / details の出力は `DebugSettings` の `debug_game_data_load_summary` / `debug_game_data_load_details` で制御されます。
- warning/errorはこのflagの対象外です。
- `validate_all()` は debug dump ではなく runtime保護用の限定的validateです。

## GameDataRegistry Debug出力一覧

| 関数 / 場所 | Prefix / 出力 | 内容 | 起動時に毎回出るか | `load_all()`経由か | DebugSettings配下か | local flag配下か | 種別 | 通常プレイ必要性 | TSV移行・監査価値 | 後続候補 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debug_print_loaded_data()` 冒頭 | `========== GameData Loaded ==========` | dump開始marker | summary/detailsどちらかがONなら出る | はい | はい | いいえ | Summary marker | 低 | 中 | Step 12-Cでgate化済み |
| `debug_print_loaded_data()` summary | `[GameData] items`, `effects`, `quests` など | 各registryの件数 | summary ON時 | はい | はい | いいえ | Summary | 中 | 高 | Step 12-Cで `debug_game_data_load_summary` 配下 |
| `debug_print_loaded_data()` Items section | `---------- Items ----------`, `item:` | itemごとのID/name/category/price/can_sell/effects数 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 高 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Effects section | `---------- Effects ----------`, `effect:` | effectごとのID/type | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 高 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Item Effect Links section | `links for item:` | item_idごとのeffect link配列 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 高 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` NPCs section | `npc:` | NPCのname/roles/trade/request | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Unit Spawn Rules section | `unit_spawn_rule:` | unit spawn rule概要 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Dungeon Spawn Rules section | `dungeon_rule:` | dungeon spawn rule概要 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Enchantments section | `enchantment:` | enchantment概要 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Enemies section | `enemy:` | enemyのname/difficulty/hp/atk/tags | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 高 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Quests section | `quest:` | questのobjective/candidate/reward概要 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` Item Spawn Rules section | `spawn_rule:` | item spawn rule概要 | details ON時 | はい | はい | いいえ | Detailed dump | 低 | 中 | Step 12-Cで通常OFF |
| `debug_print_loaded_data()` ItemDatabase section | `[ItemDatabase] ...` | ItemDatabase wrapperの簡易アクセス確認 | details ON時 | はい | はい | いいえ | Detailed/debug probe | 低 | 中 | Step 12-Cで通常OFF |
| `_load_tsv()` | `TSV not found:` | 必須TSVがない | 異常時のみ | loader経由 | いいえ | いいえ | Error | 高 | 高 | 残す候補 |
| `_load_resource_or_null()` | `resource load failed:` | resource pathがloadできない | 異常時のみ | loader経由 | いいえ | いいえ | Warning | 高 | 高 | 残す候補 |
| `_validate_items()` | `item is null`, `item icon is null` など | item runtime validate | 異常時のみ | `validate_all()`経由 | いいえ | いいえ | Warning/Error | 高 | 高 | 残す候補 |
| `_validate_item_effects()` | `item_effect_links item_id/effect_id not found` | effect link参照検証 | 異常時のみ | `validate_all()`経由 | いいえ | いいえ | Error | 高 | 高 | 残す候補 |
| `_validate_quests()` | `quest candidate/reward item not found` など | quest item参照検証 | 異常時のみ | `validate_all()`経由 | いいえ | いいえ | Error | 高 | 高 | 残す候補 |
| loader/build/normalize各所 | `unknown ... -> fallback`, `deprecated`, `duplicate ...` など | fallback、deprecated、参照欠け、重複通知 | 異常/互換fallback時のみ | loader経由 | いいえ | いいえ | Warning/Error | 高 | 高 | 原則残す候補 |

## Summary / Detailed / Warning / Error 分類

### Summary

該当:

- `========== GameData Loaded ==========`
- `[GameData] items:`
- `[GameData] effects:`
- `[GameData] item_effect_links:`
- `[GameData] quests:`
- `[GameData] enemies:`
- `[GameData] npcs:`
- `[GameData] initial_inventory_entries:`
- `[GameData] skills:`
- その他 count 系

特徴:

- 起動時に毎回まとまって出ます。
- 行数は固定に近く、現在のコードでは `[GameData]` countだけで35行程度あります。
- 通常プレイでも「データが読み込まれた」確認として残す選択肢はあります。
- ただし通常ログを静かにしたい場合は、summaryもDebugSettings配下へ寄せる候補です。

### Detailed dump

該当:

- `Items`
- `Effects`
- `Item Effect Links`
- `NPCs`
- `Unit Spawn Rules`
- `Dungeon Spawn Rules`
- `Enchantments`
- `Enemies`
- `Quests`
- `Item Spawn Rules`
- `ItemDatabase TSV access`

特徴:

- TSV件数に比例して増えます。
- 現在のmaster data規模でも、静的見積もりではsummary込みで200行超になる可能性があります。
- item / effect / link / enemy が増えるほど起動ログが伸びます。
- TSV移行・data audit時は非常に有用です。
- 通常プレイではOFF候補です。

### Warning

該当:

- `resource load failed`
- `unknown item category -> fallback`
- `unknown unit race/faction/element/damage/status -> fallback`
- `missing faction relation -> fallback`
- `unknown initial_inventory_table_id -> fallback columns`
- `initial_inventory_table_id has no entries -> fallback columns`
- `deprecated` / legacy fallback系
- 各TSVの空IDや参照欠けの一部

特徴:

- debug dumpではなく、欠損検知・互換fallback通知です。
- 単純に不要ログ扱いしない方が安全です。
- 通常化するとしても、details dumpとは別に扱うべきです。

### Error

該当:

- `TSV not found`
- `item_id is empty`
- `duplicate item_id`
- `equipment item_id not found`
- `effect_id is empty`
- `duplicate effect_id`
- `unknown effect_type`
- `item_effect_links has empty item_id or effect_id`
- `effect not found`
- `enemy_type_id is empty`
- `duplicate enemy_type_id`
- `npc_type_id is empty`
- `duplicate npc_type_id`
- quest reward/candidate item missingなど

特徴:

- required data missing / invalid reference / load failure に近いものです。
- 原則残すべきです。
- debug dump通常化と同じStepで消さない方が安全です。

## 起動時ログ量への影響

静的調査から分かる範囲:

- `debug_print_loaded_data()` は `load_all()` 末尾で毎回呼ばれるため、起動時/TSV再読込時にまとまって出ます。
- summary部分は固定行数に近いです。
- detailed部分は `items`, `effects`, `item_effect_links`, `enemies`, `quests`, `item_spawn_rules` などの件数に比例します。
- 現在のmaster data規模でも、summary 35行前後に加えて、item/effect/link/enemyなどの詳細行が多数出る構造です。
- 今後 item / effect / enemy / quest が増えるほど、起動時ログ量は増えます。
- `debug_print_loaded_data()` 自体は毎frame出るものではありません。
- 実際に何行出るかはGodot実行ログを見ないと確定できません。

## DebugSettings配下へ寄せたflag

| 候補名 | 役割 | default候補 | コメント |
| --- | --- | --- | --- |
| `debug_game_data_load_summary` | `[GameData]` count summaryだけ出す | `true` | Step 12-Cで追加済み。軽量summaryとして通常ON |
| `debug_game_data_load_details` | item/effect/link/enemyなど詳細dumpを出す | `false` | Step 12-Cで追加済み。通常OFF、data audit時だけON |
| `debug_game_data_registry_dump` | summary + detailsをまとめて出す | なし | 採用しませんでした。粒度を分けるため未追加 |
| `debug_game_data_validate` | runtime `validate_all()` の追加詳細を出す | なし | 未追加。現状 `validate_all()` はwarning/errorのみで十分 |

判断観点:

- summaryとdetailsは分けた方が、通常ログとdata auditの両立がしやすいです。
- warning/errorはflagに関係なく残す方が安全です。
- `DebugSettings` に置く方針を採用しました。
- detailed dump は default OFF になりました。
- summary は default ON です。完全に静かにしたい場合は、一時的に `debug_game_data_load_summary = false` にできます。

## 通常化候補の優先度

| 対象 | 分類 | 理由 |
| --- | --- | --- |
| `debug_print_loaded_data()` の detailed dump全体 | A | Step 12-Cで `debug_game_data_load_details=false` 配下へ移動済み |
| `Items` / `Effects` / `Item Effect Links` / `Enemies` section | A | Step 12-Cで通常OFF化済み |
| `ItemDatabase TSV access` probe | A | Step 12-Cでdetails ON時のみ出る |
| `[GameData]` count summary | B | `debug_game_data_load_summary=true` で通常ON。必要なら後続Stepでdefault見直し候補 |
| `push_warning()` fallback/deprecated系 | C | 欠損検知として価値が高い。消さない候補 |
| `push_error()` required data/duplicate/invalid refs | C | 原則残す候補 |
| TSV移行・data audit時のfull dump | D | 必要時だけONにしたい |
| `debug_game_data_validate` 相当の新flag | E | 現時点では必要性不明。実装前に用途確認が必要 |

## `tools/validate_master_data.py` との役割分担

`GameDataRegistry` runtime warning/error と `tools/validate_master_data.py` は別の層です。

| 層 | 役割 | 変更時の注意 |
| --- | --- | --- |
| `tools/validate_master_data.py` | 開発時の事前検証。TSVの参照、範囲、重複、deprecated列などを強めに確認する | このStepでは変更しない |
| `GameDataRegistry.validate_all()` | Godot起動時の限定的runtime保護。item/effect/questの重要参照を確認する | debug dump通常化と混ぜない |
| loader中の `push_warning()` | fallbackや欠損をruntimeで知らせる | warning/errorとして残す価値が高い |
| `debug_print_loaded_data()` | 読み込んだdataを人間が目視確認するdebug dump | summaryは通常ON、detailsは通常OFF |

重要:

- debug dump通常化と validator削減は別問題です。
- warning/errorは、起動時ログ量が多くても安易に消す対象ではありません。
- `validate_master_data.py` が通っていても、runtime resource load failureやfallback warningが出る可能性はあります。

## 後続Stepで実装するなら確認すること

実装前に確認したいこと:

- `debug_print_loaded_data()` detailsをOFFにしても、`push_warning()` / `push_error()` は出ること。
- summaryだけONにする場合、起動ログが読みやすくなること。
- detailsをONにした時、Step 8〜11で使っていた確認情報をまだ追えること。
- `validate_master_data.py` の結果に影響がないこと。
- TSV読み込み失敗時の原因追跡が難しくならないこと。
- DebugSettings値を変えても通常プレイ挙動に影響しないこと。
- Web export / release buildで起動ログをどう扱うか。
- `DebugSettings` に追加する場合、flag名が他のdebug flagと混ざらないこと。

## Step 12以降の小さい候補

| 候補Step | 内容 | 備考 |
| --- | --- | --- |
| Step 12-C | `debug_print_loaded_data()` detailed dumpをDebugSettings配下へ寄せる実装 | 完了。summary/detailsを分離し、details default OFF |
| Step 12-D | GameDataRegistry summaryのdefaultや文面の見直し | summaryを通常ONのまま残すか、将来OFFにするか判断 |
| Step 12-E | GameDataRegistry warning/error prefix整理の調査 | 消すのではなく読みやすくする方向 |
| Step 12-F | SaveManager local debug通常化調査 | Step 12-Aで見えた別の大きな出力源 |
| Step 12-G | UnitSpawnManager spawn debug通常化調査 | map spawnログ量の確認 |

## よくある誤解・注意点

- Step 12-Bでは `GameDataRegistry` を変更していません。
- Step 12-Cでは `debug_print_loaded_data()` のsummary/details gateだけを追加しました。
- `DebugSettings.gd` の値は変更しません。
- Step 12-Cで `DebugSettings.gd` に `debug_game_data_load_summary` / `debug_game_data_load_details` を追加しました。
- `load_all()` / `validate_all()` の読み込み順や内容は変更しません。
- `print()` は削除しません。
- `push_warning()` / `push_error()` は削除しません。
- warning/errorはdebug dumpとは役割が違います。
- runtime warning と `validate_master_data.py` は役割が違います。
- 起動時dumpが多くても、まずは候補として記録します。
- Godot実行確認はこの調査-only Stepでは不要です。
- scripts差分が出ていたら、このStepとしては誤りです。

## このdocsで分かること

- GameDataRegistryのdebug dump入口。
- 起動時に出そうなGameData系出力。
- summary / detailed / warning / error の分類。
- 通常化候補の優先度。
- 後続Stepで実装する場合の確認項目。

## このdocsでは分からないこと

- 実際のGodot起動時に何行出るか。
- どの出力を本当にOFFにしてよいか。
- DebugSettings配下に寄せる具体的な実装名。
- release / export時の最終方針。
- 起動ログをどの粒度で残すべきか。

これらは後続Stepで扱います。
