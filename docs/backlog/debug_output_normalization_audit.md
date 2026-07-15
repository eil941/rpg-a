# Debug出力通常化 Audit

## 目的

Step 12-A は、通常プレイ中に出る可能性がある debug 出力を棚卸しする調査-only Step です。

目的は、`print()`、`push_warning()`、`push_error()`、`DebugSettings` 配下の flag、DebugSettings 外の local debug 設定や debug dump を整理し、今後「残すもの」「DebugSettings 配下へ寄せるもの」「通常時はOFFにするもの」を判断しやすくすることです。

この Step では、ログ削除、flag 追加、default 値変更、挙動変更、リファクタは行っていません。

関連docs:

- [DebugSettings Deep Dive](../systems/debug_settings_deep_dive.md)
- [Current System Reading Order](../guides/current_system_reading_order.md)
- [Cognitive Debt Backlog](cognitive_debt_backlog.md)
- [GameDataRegistry Debug Dump Audit](gamedata_registry_debug_dump_audit.md)

## このStepで変更していないもの

今回変更したのは docs だけです。

以下は変更していません。

- `scripts/`
- `data/master/*.tsv`
- `master_data.xlsx`
- `project.godot`
- `scenes/`
- `tools/`
- `DebugSettings.gd` の値
- `print()` / `push_warning()` / `push_error()` の挙動

## 調査方法

主に静的検索で調査しました。実際の runtime 頻度は、今後 Godot 上で確認する必要があります。

```powershell
rg -n 'print\(' scripts --glob '*.gd'
rg -n "push_warning|push_error|printerr|print_debug" scripts --glob "*.gd"
rg -n "debug_" scripts --glob "*.gd"
rg -n "DebugSettings" scripts --glob "*.gd"
rg -n 'debug_|DebugSettings|print\(|push_warning|push_error' docs
```

PowerShell では `print()` 検索時に quote と escape の影響を受けやすいため、最終的には single quote の `rg -n 'print\(' ...` で確認しました。

静的検索の概算:

| 対象 | 件数 | 備考 |
| --- | ---: | --- |
| `print(` | 471 | debug log と player-facing message 経路が混在 |
| `push_warning(` | 132 | data validate / fallback / anomaly 系が多い |
| `push_error(` | 83 | missing scene / invalid data / hard error 系が多い |
| `printerr` | 0 | script内ヒットなし |
| `print_debug` | 0 | script内ヒットなし |
| `DebugSettings` | 44 | flag定義と直接参照の合計 |

この件数はテキスト検索結果であり、実際に通常プレイで出る頻度ではありません。

## 影響度の仮分類

| 分類 | 意味 | 今後の扱い |
| --- | --- | --- |
| A | 通常プレイ中に高頻度で出る可能性がある | 優先して通常化候補にする |
| B | 起動時、save/load、spawn batch、map遷移時にまとまって出る | startup/save debug gate 候補 |
| C | warning/error/anomaly として有用そう | 原則残すが、誤検知や過剰出力を確認 |
| D | `DebugSettings` など明示flagで制御されている | 基本は維持しつつ default 値を確認 |
| E | 静的検索だけでは用途不明、または未使用候補 | 個別Stepで追加調査 |

## DebugSettings 管理下の出力

| Flag | 現在値 | 主なscript | Prefix / 出力 | 用途 | 通常プレイ影響 | 将来候補 |
| --- | --- | --- | --- | --- | --- | --- |
| `debug_enchant` | `true` | `scripts/item/item_database.gd`, `scripts/item/item_world_manager.gd` | `[ENCHANT][ItemDatabase]`, `[ENCHANT][ItemWorldManager]` | random equipment / chest enchantment 抽選確認 | A/D。flag管理だが現在ON | defaultをOFFに戻すか、確認用として残すか判断 |
| `debug_item_spawn` | `true` | `scripts/data/item_spawn_rule_database.gd` | `[ITEM SPAWN]` | item spawn rule の期待値/実績確認 | A/D。flag管理だが現在ON | item spawn確認が完了したら通常OFF候補 |
| `debug_give_player_start_items` | `true` | `scripts/core/unit.gd`, `scripts/data/player_data.gd` | `DEBUG START ITEM ADDED`, `DEBUG START ITEM FAILED` | new player にdebug開始アイテムを配布 | B/D。新規開始時に挙動とログへ影響 | fixture inventory と通常debug logを分ける候補 |
| `debug_damage_calculate` | `false` | `scripts/combat/damage_calculator.gd` | `----- Damage Calculate -----` | 命中、crit、防御、属性、最終damage計算の詳細 | D。通常はquiet | 維持でよい |
| `debug_equipment_effects` | `false` | `scripts/core/unit.gd` | `[EquipmentPassiveEffect]`, `[EquipmentPassiveStat]` | 装備中 passive apply_modifier 確認 | D。通常はquiet | 維持でよい |
| `debug_equipment_attack_effects` | `false` | `scripts/core/unit.gd`, `scripts/combat/combat_manager.gd` | `[EquipmentAttackEffects]`, `[EquipmentAttackEffectSkip]`, `[EquipmentAttackEffectApply]` | 装備攻撃効果の候補、proc、skip、適用確認 | D。通常はquiet | 維持でよい |
| `debug_player_death_drop_scope_test_enabled` | `false` | `scripts/core/unit.gd` | `[DEATH DROP SCOPE]`, `[DEATH DROP SCOPE RESULT]` | player死亡時drop scope確認 | D。通常はquiet | 回帰確認用にdefault OFFで維持 |
| `debug_player_death_drop_scope_mode` | `"all"` | `scripts/core/unit.gd` | enabled時のみ使用 | `none` / `inventory_only` / `all` 切替 | D。enabled OFF時は影響なし | 維持でよい |
| `print_tile_info` | `false` | `scripts/core/unit.gd` | `===== CURRENT TILE INFO =====` | player現在tile情報確認 | D。通常はquiet | 維持でよい |
| `debug_player_move_skill_exp` 系 | `false` | `scripts/core/unit.gd` | `[MoveSkillExp]`, `[MoveLegacySkillGrowth]` | 移動時skill growth確認 | D。通常はquiet | 維持でよい |
| `debug_action_skill_growth` | `false` | `scripts/core/unit.gd` | action skill growth log | action skill growth確認 | D。通常はquiet | 維持でよい |
| `debug_dynamic_skill_apply` | `false` | `scripts/core/skills.gd` | dynamic skill apply log | dynamic skill適用確認 | D。通常はquiet | 維持でよい |
| `debug_skill_exp` | `false` | `scripts/core/skills.gd` | skill exp log | skill growth確認 | D。通常はquiet | 維持でよい |
| `debug_ai_turn` | `false` | `scripts/controllers/ai_controller.gd` | `----- AI TURN START -----` | AI turn詳細 | D。通常はquiet | 維持でよい |
| `debug_ai_candidates` | `false` | `scripts/controllers/ai_controller.gd` | AI candidate log | AI候補行動確認 | D。通常はquiet | 維持でよい |
| `debug_ai_target` | `false` | `scripts/controllers/ai_controller.gd` | `----- AI TARGET -----` | AI target選択確認 | D。通常はquiet | 維持でよい |
| `debug_free_action` | `false` | `scripts/controllers/player_controller.gd`, `scripts/core/unit.gd` | 主に挙動変更 | free action / action cost確認 | D。ログflagではなく挙動flag | log通常化とは別扱い |
| AI系の未使用候補flag | mostly `false` or empty | 静的検索では参照不明なものあり | なし、または不明 | 将来AI確認用の残骸/予約に見える | E | AI作業時に削除/統合可否を判断 |

## DebugSettings 外の出力

DebugSettings で一括制御されていない出力です。warning/error として価値が高いものと、通常プレイログとして多そうなものが混在しています。

| Script / area | Prefix / 出力 | 現在のgate | 出る場面 | 価値 | 分類 | 将来候補 |
| --- | --- | --- | --- | --- | --- | --- |
| `scripts/data/game_data_registry.gd` | `[GameData] ...` count / item / effect / link dump | Step 12-C以降、summary/detailsをDebugSettingsで制御 | 起動/TSV読込 | TSV移行・data auditでは有用 | B/D | summaryは通常ON、detailsは通常OFF。warning/errorは対象外 |
| `scripts/save_manager.gd` | `[SaveManager]`, `[UNIT DEBUG]` | local `debug_print_non_player_units_on_save = true` | save/load | persistence確認では有用 | B | DebugSettingsとは別に、local debugの扱いを決める |
| `scripts/managers/unit_spawn_manager.gd` | `SPAWN RANDOM ENEMY`, `SAVE ENEMY SPAWN DATA`, structure/identity dump | 無条件helper呼び出しあり | spawn/map entry | spawn persistence確認では有用 | A/B | spawn debug gate候補 |
| `scripts/core/unit.gd` | `READY`, `[INTERACT]`, `[DEATH]`, `[DEATH DROP]`, `[STATUS ...]`, `[HUNGER]`, `[MODIFIER]`, pickup message | 無条件printとflag付きprintが混在 | 通常行動全般 | player feedbackとdebug traceが混在 | A | player-facing messageとdebug logを分離 |
| `scripts/core/stats.gd` | damage/heal/death/stat up系print | 無条件 | combat / heal / growth | feedbackとして有用だがconsole noiseになり得る | A | HUD/message logへ寄せるかgate化 |
| `scripts/combat/combat_manager.gd` | `攻撃ダメージ: ...` | 無条件 | 通常攻撃 | combat確認には有用 | A | combat debug gate候補 |
| `scripts/combat/damage_calculator.gd` | 詳細damage計算 | `DebugSettings.debug_damage_calculate` | enabled時のみ | 診断価値が高い | D | 現状維持 |
| `scripts/item/item_effect_manager.gd` | `[ITEM EFFECT]`, `[CURSE]` | 主に無条件 | item use / effect apply | effect確認では有用 | A | detailed effect logのgate化候補 |
| `scripts/trade_price_calculator.gd` | `[PRICE][BUY]`, `[PRICE][SELL]`, `[PRICE][BASE]`, `[PRICE][ENCHANT]` | 無条件 | trade price計算 | price調整では有用 | A | trade price debug flag候補 |
| `scripts/item/item_database.gd`, `scripts/item/item_world_manager.gd` | `[ENCHANT]...` | `DebugSettings.debug_enchant`、現在ON | chest/equipment spawn | enchant確認では有用 | A/D | default見直し候補 |
| `scripts/data/item_spawn_rule_database.gd` | `[ITEM SPAWN]...` | `DebugSettings.debug_item_spawn`、現在ON | item spawn | spawn balancingでは有用 | A/D | default見直し候補 |
| `scripts/world/world_state.gd` | `[WorldState]...` | 無条件 | reset/load/map lifecycle | WorldState確認では有用 | B | WorldState debug gate候補 |
| `scripts/hud/game_and_hud.gd` | `OPEN INVENTORY`, restore/open UI logs | 無条件 | UI open / scene transition | UI遷移確認では有用 | A/B | Inventory transition debug gate候補 |
| `scripts/map/map_scene_scripts/*.gd` | `save_all_units called`, `child = ...`, area difficulty / spawn skip logs | 無条件 | map transition / save batch | map persistence確認では有用 | B | map persistence debug gate候補 |
| `scripts/managers/quest_board_manager.gd`, `scripts/object/questboard/quest_board.gd` | `[QBM]`, `[QUEST BOARD]` | 無条件 | quest board操作 | generated quest確認では有用 | A | quest debug gate候補 |
| `scripts/trade_ui.gd` | `[TRADE_UI] ...` | 無条件 | trade UI open/setup | narrowだが有用 | B | trade/chest debug gate候補 |
| 各所の `push_warning()` / `push_error()` | Godot warning/error | 基本無条件 | anomaly発生時 | invalid data / missing scene / unknown stat等の保護 | C | 消さずにfalse positiveだけ確認 |

## 領域別まとめ

| 領域 | 主なscript | 出力の性質 | 影響分類 | コメント |
| --- | --- | --- | --- | --- |
| Startup / GameDataRegistry | `scripts/data/game_data_registry.gd` | `[GameData]` dump、loader warning/error | B/C | debug dumpは大きい。warning/errorは基本維持候補 |
| Save / Load / WorldState | `scripts/save_manager.gd`, `scripts/world/world_state.gd`, map scene scripts | `[SaveManager]`, `[UNIT DEBUG]`, `[WorldState]`, `save_all_units called` | B | persistence作業では有用だが通常時は多い可能性 |
| Unit / Stats / Death / Drop | `scripts/core/unit.gd`, `scripts/core/stats.gd` | interaction、status、damage/heal、death/drop、pickup | A/C/D | 最も混在が大きい。player-facing messageとdebugを先に分ける |
| Item / ItemEffect / EquipmentEffect | `scripts/item/item_effect_manager.gd`, `scripts/core/unit.gd`, `scripts/combat/combat_manager.gd` | `[ITEM EFFECT]`, `[CURSE]`, equipment effect log | A/D | equipment effectは概ねgated。consumable/item effect側は通常出力候補 |
| ItemWorldManager / pickup / chest / spawn | `scripts/item/item_world_manager.gd`, `scripts/item/item_database.gd`, `scripts/data/item_spawn_rule_database.gd` | `[ENCHANT]`, `[ITEM SPAWN]`, warning/error | A/C/D | `debug_enchant` と `debug_item_spawn` が現在true |
| InventoryUI / trade / chest / held item | `scripts/item/inventory_ui.gd`, `scripts/hud/game_and_hud.gd`, `scripts/trade_price_calculator.gd`, `scripts/trade_ui.gd` | UI open log、notify message、price log | A/B/C | price logが高頻度候補。notifyはplayer feedbackの可能性あり |
| Combat / DamageCalculator | `scripts/combat/combat_manager.gd`, `scripts/combat/damage_calculator.gd` | `攻撃ダメージ`、詳細damage formula | A/D | DamageCalculatorはgated。CombatManager側に無条件combat printあり |
| Quest / Dialogue | `scripts/managers/quest_board_manager.gd`, `scripts/object/questboard/quest_board.gd`, dialogue系 | `[QBM]`, `[QUEST BOARD]`, warning/error | A/C | generated quest作業では有用。通常化は別Step |
| AI / Spawn / UnitSpawnManager | `scripts/controllers/ai_controller.gd`, `scripts/managers/unit_spawn_manager.gd` | AI flag log、spawn structure/identity log | A/B/D/E | AIはgated中心。UnitSpawnManagerは無条件候補が多い |
| UI lock / PlayerController | `scripts/controllers/player_controller.gd` など | 主に挙動flag | D/E | `debug_free_action` はlogではなく挙動確認flag |
| その他 warning/error | 複数 | `push_warning`, `push_error` | C | 一括OFFしない。false positiveだけ個別確認 |

## 通常プレイ影響が大きそうな候補

今後の実装Stepではなく、調査候補です。

| 候補 | 理由 | 次にやるなら |
| --- | --- | --- |
| `GameDataRegistry.debug_print_loaded_data()` | 起動時dumpが大きかった | Step 12-Cでsummary/details flagを追加済み。detailsは通常OFF |
| `SaveManager.debug_print_non_player_units_on_save` | local debugが現在true | DebugSettingsへ寄せるか、local default quiet化を検討 |
| `UnitSpawnManager` spawn logs | map生成/復元時に出やすい | spawn persistence debug gateを検討 |
| `DebugSettings.debug_enchant=true` | flag管理だが通常時にも出る | default OFF化するか確認用途を残すか判断 |
| `DebugSettings.debug_item_spawn=true` | flag管理だが通常時にも出る | default OFF化するか確認用途を残すか判断 |
| `Unit.gd` の gameplay prints | interaction/status/death/drop/pickup/hungerが混在 | player feedbackとdebug console logを分離 |
| `Stats.gd` の damage/heal/death prints | combatで高頻度になり得る | HUD/message logまたはcombat debug gateへ |
| `CombatManager.try_bump_attack()` | 通常攻撃ごとに出る可能性 | combat debug gate候補 |
| `ItemEffectManager` | item/effect使用時に出る | detailed effect logのgate化候補 |
| `TradePriceCalculator` | trade中にprice計算ごとに出る | trade price debug flag候補 |
| Quest board logs | quest board操作時に出る | quest debug gate候補 |

## 今すぐ直さない理由

今回のStepでは出力を変更しません。

理由:

- 現在も確認中の機能に必要なログが含まれている可能性がある。
- `print()` の一部は、仮のplayer-facing feedbackとして使われている可能性がある。
- `push_warning()` / `push_error()` は data integrity guard として有用なものが多い。
- `debug_enchant` / `debug_item_spawn` のように、flag管理だが現在trueのものは、確認完了タイミングを決めてから戻す方が安全。
- runtimeで本当に高頻度かどうかは、Godot実行ログで確認する必要がある。
- ログ整理は挙動変更と混ぜると、バグ修正や仕様確認が難しくなる。

## Step 12以降の小分け候補

| 候補Step | 範囲 | 期待結果 |
| --- | --- | --- |
| Step 12-B | `GameDataRegistry` startup dump と data-load warning方針 | [gamedata_registry_debug_dump_audit.md](gamedata_registry_debug_dump_audit.md) を作成し、summary/details/warning/errorを分類済み |
| Step 12-C | `GameDataRegistry.debug_print_loaded_data()` のsummary/details gate | 完了。summaryは通常ON、detailsは通常OFF |
| Step 12-D | `SaveManager`, `WorldState`, map persistence系batch logs | save/loadとmap遷移ログを通常化 |
| Step 12-E | `debug_enchant`, `debug_item_spawn` の現在true default | defaultをどうするか判断 |
| Step 12-F | `Unit.gd`, `Stats.gd`, `CombatManager`, `ItemEffectManager` の通常gameplay print | player feedbackとdebug logを分離 |
| Step 12-G | Trade / Chest / Inventory price and UI logs | price/UI遷移diagnosticをgate化 |
| Step 12-H | `push_warning()` / `push_error()` policy | anomaly reportingは残し、false positiveだけ整理 |
| Step 12-I | 未使用/用途不明の `DebugSettings` flag | AI系などを個別に確認し、削除/維持/統合を判断 |

## よくある誤解

- `DebugSettings` はすべてのdebug出力を制御していない。
- 関数名に `debug_` が入っていても、DebugSettings flagでgatedとは限らない。
- `push_warning()` は単なるノイズとは限らない。dataやsceneの異常検知として残すべきものが多い。
- `debug_enchant` と `debug_item_spawn` はflag管理だが、現在値が `true` なので通常プレイ中にも出る。
- `debug_give_player_start_items` はログflagではなく、開始所持品を変える挙動flagである。
- `InventoryUI.notify_message()` の `print()` は、player-facing messageの代替経路として使われている可能性があるため、単純に消さない。

## このdocで分かること

- DebugSettings管理の出力。
- DebugSettings外の出力。
- 通常プレイでログ量が増えそうな領域。
- 今後のStep 12系をどの順で小分けにすると安全か。

## このdocでは分からないこと

- Godot実行時の実際の出力頻度。
- どのログを削除してよいか。
- どのflag defaultを変更すべきか。
- player-facing messageを専用message logへ寄せるべきか。
- unified logging utilityを導入すべきか。

これらは、今後のStep 12で個別に扱います。
