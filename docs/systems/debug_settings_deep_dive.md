# DebugSettings Deep Dive

## 目的

このdocsは、`scripts/debug/DebugSettings.gd` に集まっている debug flag、debug start item、確認用ログの現状を理解するための地図です。

今回のStepでは値を変更しません。flagの追加・削除、start itemの追加・削除、runtime挙動の変更も行いません。

DebugSettingsは `project.godot` の Autoload として登録されており、多くのscriptから `DebugSettings.xxx` として直接参照されます。そのため、1つのflag変更が通常プレイ、ログ量、開始所持品、検証挙動へ影響することがあります。

## 全体像

| 分類 | 設定 | 現在値 | 主な用途 | 主な参照先 | 通常状態の注意 |
| --- | --- | --- | --- | --- | --- |
| 行動・tile確認 | `debug_free_action` | `false` | player行動消費を緩める確認 | `player_controller.gd`, `unit.gd` | 通常プレイではOFF |
| 行動・tile確認 | `print_tile_info` | `false` | player現在tile情報のログ | `unit.gd` | ログが多くなるためOFF |
| ダメージ確認 | `debug_damage_calculate` | `false` | 命中・ダメージ計算ログ | `damage_calculator.gd` | 通常プレイではOFF |
| エンチャント確認 | `debug_enchant` | `true` | 装備エンチャント抽選ログ | `item_database.gd`, `item_world_manager.gd` | 現状true。ログ整理は別Stepで扱う |
| AI確認 | `debug_ai` | `false` | AI全体用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| AI確認 | `debug_ai_turn` | `false` | AIターン進行ログ | `ai_controller.gd` | 通常プレイではOFF |
| AI確認 | `debug_ai_target` | `false` | AI target選定ログ | `ai_controller.gd` | 通常プレイではOFF |
| AI確認 | `debug_ai_candidates` | `false` | AI候補ログ | `ai_controller.gd` | 通常プレイではOFF |
| AI確認 | `debug_ai_attack` | `false` | AI攻撃ログ用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| AI確認 | `debug_ai_move` | `false` | AI移動ログ用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| Unit/data確認 | `debug_ai_style_apply` | `false` | AI style適用確認用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| Unit/data確認 | `debug_npc_ai` | `false` | NPC AI確認用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| Unit/data確認 | `debug_enemy_ai` | `false` | enemy AI確認用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| Skill確認 | `debug_dynamic_skill_apply` | `false` | dynamic skill適用ログ | `skills.gd` | 通常プレイではOFF |
| Skill確認 | `debug_skill_exp` | `false` | skill exp/growthログ | `skills.gd` | 通常プレイではOFF |
| Skill確認 | `debug_action_skill_growth` | `false` | `gain_action_skill_growth()` ログ | `unit.gd` | 通常プレイではOFF |
| 装備効果確認 | `debug_equipment_effects` | `false` | 装備中passive apply_modifierログ | `unit.gd` | 通常プレイではOFF |
| 装備攻撃効果確認 | `debug_equipment_attack_effects` | `false` | 攻撃時装備効果候補・適用・skipログ | `unit.gd`, `combat_manager.gd` | 通常プレイではOFF |
| 移動skill確認 | `debug_player_move_skill_exp` | `false` | player移動時に指定skillへgrowth付与 | `unit.gd` | 通常プレイではOFF |
| 移動skill確認 | `debug_player_move_skill_id` | `"test_foraging"` | 移動時growth対象skill | `unit.gd` | flag OFF時は使われない |
| 移動skill確認 | `debug_player_move_skill_exp_amount` | `1` | 移動時growth量 | `unit.gd` | flag OFF時は使われない |
| 移動skill確認 | `debug_player_move_skill_exp_verbose` | `false` | `[MoveSkillExp]` 詳細ログ | `unit.gd` | 通常プレイではOFF |
| 移動skill確認 | `debug_player_move_legacy_gathering_growth` | `false` | 旧gathering確認用growth | `unit.gd` | 通常プレイではOFF |
| 移動skill確認 | `debug_player_move_legacy_gathering_skill_id` | `"gathering"` | legacy growth対象skill | `unit.gd` | flag OFF時は使われない |
| 移動skill確認 | `debug_player_move_legacy_gathering_growth_amount` | `1` | legacy growth量 | `unit.gd` | flag OFF時は使われない |
| 移動skill確認 | `debug_player_move_legacy_gathering_verbose` | `false` | `[MoveLegacySkillGrowth]` 詳細ログ | `unit.gd` | 通常プレイではOFF |
| player死亡drop scope確認 | `debug_player_death_drop_scope_test_enabled` | `false` | player死亡時drop対象scopeの上書き | `unit.gd` | 必ずdefault OFF |
| player死亡drop scope確認 | `debug_player_death_drop_scope_mode` | `"all"` | `none` / `inventory_only` / `all` | `unit.gd` | enabled OFF時は使われない |
| flee AI確認 | `debug_flee_ai` | `false` | 逃走AI確認用に見えるflag | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| AI filter | `debug_ai_unit_name_filter` | `""` | AIログfilter用に見える設定 | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| AI filter | `debug_ai_unit_id_filter` | `""` | AIログfilter用に見える設定 | 現状 `rg` では参照なし | 削除せず未使用候補として扱う |
| debug start items | `debug_give_player_start_items` | `true` | player初回生成時に確認用itemを配布 | `unit.gd`, `player_data.gd` | 現状true。配布内容変更時は影響が大きい |
| debug start items | `debug_player_start_items` | `Array[Dictionary]` | 配布するitem_id/amount一覧 | `unit.gd` | Step確認品は完了後に外す |
| item spawn確認 | `debug_item_spawn` | `true` | item spawn ruleの期待/実績ログ | `item_spawn_rule_database.gd` | 現状true。ログ整理は別Stepで扱う |

## DebugSettings外のdebug出力

DebugSettingsではなく、個別script内にdebug設定やdebug dumpがあるものもあります。

| 場所 | 設定・関数 | 現在の扱い | 注意 |
| --- | --- | --- | --- |
| `scripts/save_manager.gd` | `debug_print_non_player_units_on_save`, `debug_print_non_player_units_limit` | SaveManager内のlocal debug設定 | DebugSettingsではないため、一括OFF対象と混同しない |
| `scripts/data/game_data_registry.gd` | `debug_print_loaded_data()` | `load_all()` 後に呼ばれるdebug dump | DebugSettings flagでは制御されていない |
| `scripts/managers/unit_spawn_manager.gd` | `debug_unit_structure()`, `debug_unit_identity()` | spawn時debug helper | DebugSettings flagでは制御されていない |
| `scripts/item/inventory_ui.gd` | `debug_` を含む関数名はあるが、DebugSettings参照はなし | held item / quest dialog lock等の通常ロジック名 | DebugSettingsのflagとは別物 |

## Debug Start Item の仕組み

`debug_player_start_items` は、player Unit生成時に一度だけplayer inventoryへ入る確認用アイテムです。

流れ:

1. player `Unit._ready()` で `apply_debug_start_items_if_needed()` が呼ばれる。
2. `is_player_unit` でないUnitは何もしない。
3. `DebugSettings.debug_give_player_start_items` が `false` なら何もしない。
4. `PlayerData.debug_start_items_applied` が `true` なら再配布しない。
5. `DebugSettings.debug_player_start_items` の各entryを `inventory.add_item_entry()` でplayer inventoryへ入れる。
6. `PlayerData.inventory_data = save_inventory_persistence_data()` でPlayerDataへ反映する。
7. `PlayerData.debug_start_items_applied = true` にする。

`PlayerData.debug_start_items_applied` は `SaveManager.PLAYER_DATA_PROPS` に含まれます。save/load後も「配布済み」状態が維持されるため、ロードのたびにdebug itemが増えることは避けられています。

`PlayerData.reset_for_new_game()` では `debug_start_items_applied = false` に戻ります。new gameでは再配布されます。

現在有効なdebug start item:

| item_id | amount | 用途の目安 |
| --- | ---: | --- |
| `bow` | 1 | 装備・遠隔確認 |
| `healing_potion` | 10 | 回復item確認 |
| `mushroom_bad` | 10 | 状態異常系item確認 |
| `potion_of_strength` | 10 | buff系item確認 |
| `teleport_stone` | 10 | teleport系item確認 |
| `poison_cure_potion` | 10 | cure系item確認 |
| `fire_bottle` | 50 | damage item確認 |
| `frost_bottle` | 10 | damage/status item確認 |
| `sleep_orb` | 10 | status item確認 |
| `blast_stone` | 50 | damage item確認 |
| `curse_orb` | 10 | curse系item確認 |
| `bread` | 10 | 食料item確認 |
| `apple` | 10 | 食料item確認 |
| `meat_skewer` | 10 | 食料item確認 |
| `travel_ration` | 10 | 食料item確認 |
| `test_iron_ore` | 5 | 確認用素材 |
| `test_small_heal_herb` | 10 | 確認用消耗品 |

コメントアウトされているentryは配布されません。

### Debug Start Item 変更時のリスク

- `debug_give_player_start_items=true` のまま大量itemを増やすと、new game時の通常確認に影響します。
- `debug_start_items_applied=true` のsaveを使っている場合、DebugSettingsのitem listを変えても既存saveには自動再配布されません。
- 確認用の `test_*` / `sample_*` itemを追加したStepでは、確認完了後にstart itemから外すか、残す理由を明記します。
- sample itemはGameData上に残しても、通常ランダム生成・宝箱カテゴリ抽選からは除外されている必要があります。

## Debug Flag Taxonomy

| 領域 | DebugSettingsでの入口 | 主な確認内容 | 備考 |
| --- | --- | --- | --- |
| Combat / damage | `debug_damage_calculate` | damage formula、命中、crit等 | `DamageCalculator` 側 |
| Equipment passive effect | `debug_equipment_effects` | 装備中apply_modifier、stat差分 | `Unit` 側。`debug_equipment_attack_effects` でもpassive logが出る |
| Equipment attack effect | `debug_equipment_attack_effects` | 攻撃時effect候補、proc失敗、deal_damage、apply_status、restore_resource | `CombatManager` 側 |
| Death drop | `debug_player_death_drop_scope_test_enabled`, `debug_player_death_drop_scope_mode` | player死亡時のdrop対象scope | player限定。enemy/npc TSV検証用ではない |
| Save / Load | なし | SaveManager内local debugあり | DebugSettings集中管理ではない |
| Inventory / held item | なし | held item scene跨ぎはPlayerDataで管理 | InventoryUIはDebugSettingsを直接参照しない |
| Item spawn | `debug_item_spawn` | item spawn ruleの期待/実績ログ | 現状true |
| Enchant | `debug_enchant` | random equipment enchant、chest/equipment spawn | 現状true |
| Skill | `debug_dynamic_skill_apply`, `debug_skill_exp`, `debug_action_skill_growth`, move skill flags | dynamic skill適用、growth、移動確認 | Step 7系の確認用 |
| AI | `debug_ai_turn`, `debug_ai_target`, `debug_ai_candidates` | AIターン・候補・target | ほかAI flagは現状参照なし候補 |
| Quest / Dialogue | なし | Quest docs/checklistで確認 | DebugSettings flagは現状なし |
| Map / World reset | なし | map script / WorldState docsで確認 | DebugSettings flagは現状なし |

## DebugSettings Reference Map

| Script | 参照している設定 | 影響する機能 | 注意 |
| --- | --- | --- | --- |
| `scripts/core/unit.gd` | `debug_give_player_start_items`, `debug_player_start_items`, `debug_player_death_drop_scope_test_enabled`, `debug_player_death_drop_scope_mode`, `debug_equipment_effects`, `debug_equipment_attack_effects`, `print_tile_info`, movement skill flags, `debug_action_skill_growth`, `debug_free_action` | player開始所持品、player死亡drop scope、装備passiveログ、tileログ、skill成長確認、free action | Unitは影響範囲が広い。確認flagのON/OFFをdeath dropやsave/load変更と混ぜない |
| `scripts/combat/combat_manager.gd` | `debug_equipment_attack_effects` | 攻撃時装備効果ログ | proc_failedやapplyログはこのflagがtrueの時だけ |
| `scripts/combat/damage_calculator.gd` | `debug_damage_calculate` | damage計算ログ | ログ量が増えるため通常OFF |
| `scripts/controllers/player_controller.gd` | `debug_free_action` | player入力・行動消費 | 通常プレイ確認ではOFF |
| `scripts/controllers/ai_controller.gd` | `debug_ai_turn`, `debug_ai_candidates`, `debug_ai_target` | enemy AIの候補・target・turnログ | 他AI flagは現状参照なし |
| `scripts/core/skills.gd` | `debug_dynamic_skill_apply`, `debug_skill_exp` | skill適用・expログ | Step 7以降、skill本体はSkillsノード旧API寄せ |
| `scripts/item/item_database.gd` | `debug_enchant` | random equipment entry / enchant候補ログ | sample装備除外やspawn_weight調査時にもログが出る |
| `scripts/item/item_world_manager.gd` | `debug_enchant` | chest/item world側のenchantログ | `DebugSettings`参照あり |
| `scripts/data/item_spawn_rule_database.gd` | `debug_item_spawn` | item spawn rule report | 現状true。通常ログ量に注意 |
| `scripts/save_manager.gd` | DebugSettings参照なし | save時non-player Unit debugはlocal設定 | `debug_print_non_player_units_on_save` は別管理 |
| `scripts/data/player_data.gd` | DebugSettings参照なし | `debug_start_items_applied` と held item state保持 | DebugSettings start itemの再配布抑止に使われる |
| `scripts/item/inventory_ui.gd` | DebugSettings参照なし | held item、normal/trade/chest UI | UI modeとheld stateはDebugSettingsではなくPlayerData中心 |
| `scripts/managers/unit_spawn_manager.gd` | DebugSettings参照なし | spawn debug helperあり | DebugSettings flagでは制御されていない |
| `scripts/hud/game_and_hud.gd` | DebugSettings参照なし | map/UI親 | DebugSettingsによる直接制御なし |
| `scripts/world/world_state.gd` | DebugSettings参照なし | world persistence/reset | DebugSettingsによる直接制御なし |
| `scripts/data/game_data_registry.gd` | DebugSettings参照なし | load後debug dump | DebugSettings flagでは制御されていない |

## 確認後に通常状態へ戻すもの

Step確認で一時的に変更されやすいもの:

| 対象 | 戻す目安 |
| --- | --- |
| `debug_equipment_effects` | 装備passive確認後は `false` |
| `debug_equipment_attack_effects` | 装備攻撃効果確認後は `false` |
| `debug_player_death_drop_scope_test_enabled` | player死亡drop scope確認後は必ず `false` |
| `debug_player_death_drop_scope_mode` | 通常初期値は `"all"` |
| `debug_player_move_skill_exp` | skill移動確認後は `false` |
| `debug_player_move_legacy_gathering_growth` | legacy確認後は `false` |
| `debug_action_skill_growth` | action skill growth確認後は `false` |
| `debug_skill_exp` | skill exp確認後は `false` |
| `debug_dynamic_skill_apply` | dynamic skill確認後は `false` |
| `debug_damage_calculate` | damage確認後は `false` |
| `print_tile_info` | tile確認後は `false` |
| AI系log flag | AI確認後は `false` |
| `debug_player_start_items` | Step固有の確認用itemは完了後に削除または残す理由を書く |

現在 `debug_enchant`, `debug_give_player_start_items`, `debug_item_spawn` はtrueです。このdocsでは値を変更していません。これらを通常OFFへ寄せるかは、別Stepでログ量・確認方針を決めてから扱います。

## 過去Stepとの関係

| Step | DebugSettingsとの関係 | 参照docs |
| --- | --- | --- |
| Step 7 Skill | 移動skill growth、`gain_action_skill_growth()` の確認flagが追加された | [unit_lifecycle_deep_dive.md](unit_lifecycle_deep_dive.md) |
| Step 8 Equipment effect | `debug_equipment_effects`, `debug_equipment_attack_effects` でpassive/attack effectを確認した | [script_responsibility_map.md](../architecture/script_responsibility_map.md) |
| Step 9 Initial inventory | debug start itemと `debug_start_items_applied` の再配布抑止がSave/Load確認対象になった | [map_spawn_persistence_deep_dive.md](map_spawn_persistence_deep_dive.md) |
| Step 10 Death drop | `debug_player_death_drop_scope_test_enabled` とmodeでplayer死亡drop scopeを確認した | [death_drop_spec.md](death_drop_spec.md), [death_path_diagram.md](death_path_diagram.md) |
| Scene transition / held item | DebugSettingsではなく、PlayerData held stateでscene跨ぎを管理する | [inventory_ui_state_transition.md](inventory_ui_state_transition.md) |
| Save/Load matrix | DebugSettings一時flagが通常状態か、debug start item再配布が自然かを確認する | [../checklists/save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md) |
| Quest / generated quest | 現状Quest用DebugSettings flagはない | [quest_generated_lifecycle_deep_dive.md](quest_generated_lifecycle_deep_dive.md) |

## CodexにDebugSettings作業を依頼する時の注意

依頼文に入れるとよいこと:

- どのflagを一時的にONにしてよいか。
- 最終的にそのflagをOFFへ戻すか。
- `debug_player_start_items` にitemを追加する場合、確認後に削除するか残すか。
- `PlayerData.debug_start_items_applied` のsave/load影響を確認するか。
- `debug_enchant` / `debug_item_spawn` のような現状trueのログを変更してよいか。
- DebugSettings外のlocal debug設定を触ってよいか。
- Godot実行確認が必要か、docsだけでよいか。

Codexに避けさせること:

- 複数Stepの確認用itemを残したまま通常運用へ戻す。
- DebugSettingsの値変更と実装リファクタを同じStepで混ぜる。
- `DebugSettings.gd` の値だけを変えて、`PlayerData.debug_start_items_applied` の挙動を見落とす。
- `InventoryUI` のheld item挙動をDebugSettingsで解決しようとする。
- DebugSettings外のdebug printをDebugSettings管理だと思い込む。

## 変更チェックリスト

DebugSettingsを変更するStepでは、最低限以下を確認します。

| 確認 | 内容 |
| --- | --- |
| 目的 | 一時確認か、恒久的なdebug入口か |
| default | 通常プレイでONにする理由があるか |
| 影響範囲 | player限定か、enemy/npc/world generationにも影響するか |
| Save/Load | `PlayerData` や `WorldState` に残る状態があるか |
| Start item | item_idが存在するか、amountが過剰でないか |
| 復帰 | 確認後にOFF/削除するものを最終報告に書いたか |
| Logs | 通常プレイでログが出ないか、出るなら理由があるか |
| Tests | `py tools/validate_master_data.py` と `git diff --check` を実行したか |

## 禁止・注意

- `skill_state` や旧 `Unit.add_skill_exp()` をDebugSettings確認のために復活させない。
- 装備効果確認のために `equipment_effect_links.tsv` を作らない。装備効果は `item_effect_links.tsv` を使う。
- initial inventoryはspawn時所持品であり、death時に再抽選しない。
- death dropはUnitが実際に持っているinventory/hotbar/equipmentを落とす方式であり、drop-only reward tableはまだ作らない。
- DebugSettings変更だけのStepでは、`master_data.xlsx` や `data/master/*.tsv` を触らない。
- 確認用flagをONにした場合、最終報告で戻したかを必ず書く。

## 気になる点・今後の候補

- `debug_enchant`, `debug_item_spawn`, `debug_give_player_start_items` は現状trueです。通常運用としてこのままでよいかは、別Stepで確認してもよいです。
- SaveManager、GameDataRegistry、UnitSpawnManagerにはDebugSettings外のdebug出力があります。ログ整理をするなら、DebugSettingsへの集約ではなく「どれを残すか」を先に決めます。
- DebugSettings内の日本語コメントは、一部環境で文字化けして見えます。コメント整理は値変更と混ぜず、別Stepで扱うのが安全です。
- AI系flagには現状参照が見つからないものがあります。削除する場合は、今後のAI実装予定と合わせて確認します。
