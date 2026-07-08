# Cognitive Debt Backlog

Step 11-L 時点で見えている認知的負債の整理候補です。これは修正指示ではなく、「将来どこを深掘り・整理すると楽になるか」のメモです。

## 整理候補一覧

| 領域 | 現状のしんどさ | 理由 | 今すぐ直すべきか | 将来の整理案 | リスク |
| --- | --- | --- | --- | --- | --- |
| `scripts/core/unit.gd` | 非常に大きい | 移動、interaction、装備、initial inventory、effects、death drop、save/loadが同居 | いいえ | [../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md) を入口に、将来helper分割候補を小さく検討 | 無理に分けるとsave/loadや死亡処理を壊しやすい |
| `scripts/item/inventory_ui.gd` | 高密度 | normal/trade/chest/held item/keyboard/tooltipが同居 | いいえ | [../systems/inventory_ui_state_transition.md](../systems/inventory_ui_state_transition.md) を足場に、将来 side panel / held item helper 分離を検討 | UI操作の退行、item消失、free済み参照 |
| `scripts/data/game_data_registry.gd` | loaderが多い | 全TSVのload/build/validate/debug dumpが集中 | いいえ | [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md) を入口にし、将来 registry sub-loader 化を検討 | 読み込み順・fallback互換性を壊す |
| map scene scripts | 似たspawn/save処理が複数 | `main.gd`, `FiledMap.gd`, `dungeon_main.gd` に似た責務がある | いいえ | [../systems/map_spawn_persistence_deep_dive.md](../systems/map_spawn_persistence_deep_dive.md) を入口に、共通化候補だけ棚卸し | mapごとの例外を消してしまう |
| `QuestManager` | 広い | template/generated quest、受注、完了、報酬、WorldState連携がある | いいえ | [../systems/quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md) を入口に、repeatableやgeneration block保存仕様を小さく確認 | quest resetやsave互換性の破損 |
| Save / WorldState 境界 | 分かりづらい | PlayerData、WorldState、GlobalDungeon、GlobalDetailMap、map scene saveが絡む | いいえ | [../systems/save_worldstate_playerdata_map.md](../systems/save_worldstate_playerdata_map.md) を入口にし、将来ownerごとのhelper整理を検討 | 状態消失、二重復元、new game reset漏れ |
| Save/Load実機確認 | 手順が長い | PlayerData、WorldState、map遷移、enemy/NPC、pickup/chest、dungeon、questを横断する | いいえ | [../checklists/save_load_regression_matrix.md](../checklists/save_load_regression_matrix.md) を使い、確認ログを継続的に追記 | 確認漏れ、回帰の見落とし |
| DebugSettings | 確認機能が増えている | Stepごとのdebug flag/start item/scope設定が蓄積 | 急ぎではない | [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) を入口に、default ON/OFFやDebugSettings外debug出力を確認 | debug defaultを誤ると通常プレイに影響 |
| Equipment effect | 仕様は安定したが入口が複数 | passiveはUnit、attackはCombatManager、dataはitem_effect_links | いいえ | [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md) を入口に、将来共通化や分割調査はStep 12以降で扱う | consumable effectと混同しやすい |
| Death drop | docsはあるが実装入口がUnitに埋まる | `Unit.handle_death()` と `drop_inventory_items_on_death_if_needed()` が大きい | いいえ | death path diagramを追加 | 二重drop、装備drop漏れ |
| Initial inventory | death dropと名前が混同されやすい | spawn時所持品でありdeath時lootではない | いいえ | Data docsに「spawn-time carried inventory」と繰り返し明記 | drop tableを早く作りすぎる |
| Trade / Chest ownership | 不正取得リスクが見えづらい | held item sourceがscene跨ぎで無効になることがある | いいえ | [../systems/trade_chest_ownership_deep_dive.md](../systems/trade_chest_ownership_deep_dive.md) を入口に、将来の所有権整理・分割調査はStep 12以降で扱う | item消失、不正取得、free済み参照 |
| UI lock | 通常inventoryだけ移動可という例外がある | `is_ui_locked()` と `is_inventory_open()` の意味が違う | 中 | UI lock matrixを維持する | 通常inventory中移動を誤って止める |

## 今すぐ直さない理由

- 現在の目的は認知的負債の可視化であり、実装変更ではありません。
- 高密度ファイルほど、目的なしの分割は退行リスクが高いです。
- まずはdocsで「どこが危ないか」を共有し、次に小さいStepで深掘り・検証・分割候補を決める方が安全です。

## 完了した深掘り

| Step | 内容 | 成果 |
| --- | --- | --- |
| Step 11-D | `Unit.gd` の lifecycle別読み方docsを作成 | Unit変更時の入口、生成/data適用/initial inventory/death/saveの関係を確認しやすくした |
| Step 11-E | `GameDataRegistry` のTSVカテゴリ別loader map docsを作成 | TSV追加時に、loader、data class、lookup、post-process、validatorの対応を確認しやすくした |
| Step 11-F | `SaveManager` / `PlayerData` / `WorldState` の保存対象一覧docsを作成 | 保存先、復元入口、reset対象、scene跨ぎ保持/破棄の判断基準を確認しやすくした |
| Step 11-G | map scene scripts中心のspawn/persistence docsを作成 | field/detail/dungeon/simple mapの違い、spawn保存優先順、WorldState対応、reset/regenerationを確認しやすくした |
| Step 11-H | Quest / generated quest / NPC quest lifecycle docsを作成 | QuestManager、UnitInteractionLogic、DialogueManager、WorldState、Quest boardの関係を確認しやすくした |
| Step 11-I | Save/Load実機確認マトリクスを作成 | Smoke/Core/Extendedの確認範囲、失敗時の切り分け先、最小確認セットを揃えた |
| Step 11-J | DebugSettings / debug flag / debug start item docsを作成 | DebugSettingsの現在値、参照先、debug start item、通常状態へ戻す対象を確認しやすくした |
| Step 11-K | Equipment effect / ItemEffect execution path docsを作成 | 消耗品効果、装備パッシブ、装備攻撃効果の入口とTSV共有関係を確認しやすくした |
| Step 11-L | Trade / Chest ownership docsを作成 | trade/chest/held item/side inventoryの所有権境界、scene跨ぎ参照寿命、save/death dropとの境界を確認しやすくした |

## 近い将来の深掘り候補

| 候補 | 内容 | 期待効果 |
| --- | --- | --- |
| GameDataRegistry分割調査 | `GameDataRegistry` のsub-loader化可否を調査する | 将来の分割候補を、読み込み順とfallback互換性を壊さず評価できる |
| map scene共通化調査 | map scene scriptsの共通化可否だけ調査する | `save_map_tiles()` / `save_all_units()` / saved-random優先処理を、仕様差を潰さず棚卸しできる |
| Debug出力通常化 | `debug_enchant`, `debug_item_spawn`, SaveManager local debugなど現状true/無条件のログを通常化できるか調査する | 通常プレイログ量を整理しつつ、必要な確認入口を残せる |
| Quest残課題監査 | repeatable quest、generation block保存、quest active dataのResource参照を個別に確認する | Quest docsで見えた未整理点を小さく検証できる |
| Effect実行経路の将来調査 | consumable、equipment passive、equipment attackの共通化可否をStep 12以降で調査する | 現状仕様docsを足場に、実装変更なしで分割候補を評価できる |
| Trade / Chest ownership整理調査 | side inventory helper、ownership model、UI lock matrixの整理可否をStep 12以降で調査する | 現状仕様docsを足場に、item消失や不正取得を避けながら整理候補を評価できる |

## Step 11-Dで見えた追加注意

- Enemyは `enemy_data_to_apply` を渡して `_ready()` 内でdata適用されますが、NPCは `UnitSpawnManager` から `add_child()` 後に `apply_npc_data()` を直接呼ぶ経路があります。save/loadやinitial inventoryに触る時は、このタイミング差を先に確認します。
- `Unit.get_stats_data()` は名前より広く、inventory、equipment、effect runtimes、skills、tileも含むUnit runtime保存データです。将来、保存対象一覧docsで呼び方を補足すると安全です。
- `unit.gd` には確認用printが多く残っています。ログ整理は挙動変更と混ぜず、別Stepで扱うのが安全です。

## Step 11-Eで見えた追加注意

- `GameDataRegistry.load_all()` は読み込み順そのものが仕様に近いです。item/effect/link、enemy/npc、spawn rule子テーブルの順番を変える時は、依存関係を先に棚卸しします。
- `tools/validate_master_data.py` が実質的な強い検証層で、runtimeの `validate_all()` は限定的です。TSV列追加時はruntime loaderだけでなくvalidator更新を必ず確認します。
- deprecated fallbackとして `initial_inventory_items` と `initial_inventory_entries.drop_chance` が残っています。削除する場合は互換性監査を別Stepで行います。
- `item_effect_links.tsv` は消耗品と装備の両方で使います。装備効果用に別テーブルを足す判断は、既存link方式で足りない理由が明確になってからにします。

## Step 11-Fで見えた追加注意

- `SaveManager.PLAYER_DATA_PROPS` には `PlayerData.held_inventory_*` が含まれていません。現状のheld itemはscene跨ぎruntime一時状態として扱われています。将来、held item中の手動saveを許可するなら、保存するかsaveを拒否するかを仕様化します。
- `SaveManager.debug_print_non_player_units_on_save` は現状trueです。保存調査には便利ですが、ログ整理は挙動変更と混ぜず別Stepで扱うのが安全です。
- `WorldState` のresetはmonthly reset、NPC reset、new game resetで意味が違います。新しい状態を追加する時は、どのresetで消すかを先に決めます。

## Step 11-Gで見えた追加注意

- `FiledMap.gd` は実ファイル名です。typoに見えますが、renameはscene/script参照を巻き込むため専用Stepにします。
- detail/dungeon/start/simple biome map scriptsには、似た `save_all_units()` / tile save-load / saved-random spawn優先処理があります。ただしfield/detail/dungeonで例外が多いため、すぐに共通化しない方が安全です。
- `dungeon_spawn_rules.tsv` はcode pathがあり、fallback/repairもあります。rule追加時は既存saveの `dungeon_floor_data` 互換を確認します。
- `ItemWorldManager` のpickup/chest生成は `WorldState.map_item_pickups/map_chests` がない時だけ行う前提です。再訪問時の再抽選を起こさないようにします。

## Step 11-Hで見えたQuest系の追加注意

- Quest lifecycle docsは [../systems/quest_generated_lifecycle_deep_dive.md](../systems/quest_generated_lifecycle_deep_dive.md) を入口にします。
- `npc_quest_generation_blocked_until_reset` はWorldStateにありますが、現在の `SaveManager.WORLD_STATE_PROPS` には含まれていません。runtime reset stateとして十分か、save/loadをまたぐべきかは将来仕様確認候補です。
- `QuestData.repeatable` は読み込まれていますが、現状はcompleted questを隠す実装が優先されています。repeatable questを本格利用する場合は、受注可能条件と履歴管理を別Stepで整理します。
- `Unit.quest_template_pool` はexportされていますが、現在のgenerated quest候補選定は `QuestDatabase.get_all_quests()`、`npc_quest_links.tsv`、`allowed_unit_role_flags` が中心です。使うなら用途の再確認が必要です。
- `quest_active_data` に `giver_portrait` が入っています。保存互換性を堅くするなら、Resource参照ではなくpath/id中心に寄せるか監査します。

## Step 11-Iで見えた追加注意

- Save/Load回帰確認は単一機能ではなく、PlayerData、WorldState、map scene、Unit、InventoryUI、ItemWorldManager、QuestManagerを横断します。変更範囲に応じてSmoke/Core/Extendedを選びます。
- matrixは作成時点では確認手順表であり、実機確認ログは空です。Save/Load系の変更をしたStepでは結果を追記して育てます。
- held item、trade/chest、dungeon、quest resetは失敗時の切り分けが難しいため、最小確認セットに追加するかを変更内容ごとに判断します。

## Step 11-Jで見えたDebugSettings系の追加注意

- DebugSettings docsは [../systems/debug_settings_deep_dive.md](../systems/debug_settings_deep_dive.md) を入口にします。
- `debug_enchant`, `debug_item_spawn`, `debug_give_player_start_items` は現状trueです。通常運用でこのままにするか、確認Step後にOFFへ寄せるかは別Stepで判断します。
- `SaveManager.debug_print_non_player_units_on_save`、`GameDataRegistry.debug_print_loaded_data()`、`UnitSpawnManager.debug_unit_structure()` はDebugSettings外のdebug出力です。ログ整理時にDebugSettings管理と混同しないようにします。
- `debug_player_start_items` は `PlayerData.debug_start_items_applied` によりsave/load後に再配布されません。開始所持品を変えた時はnew game/reset条件も確認します。
- AI系flagには現状参照が見つからないものがあります。削除や統合は、AI実装方針確認と合わせて別Stepで扱います。

## Step 11-Kで見えたEffect系の追加注意

- Equipment / ItemEffect execution path docsは [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md) を入口にします。
- `item_effect_links.tsv` は消耗品と装備効果で共有されています。装備効果用に `equipment_effect_links.tsv` を追加する判断は、既存link方式で足りない理由が明確になってからにします。
- `trigger_chance` は `ItemEffectData` に読み込まれますが、現状の発動判定入口は装備攻撃効果側です。消耗品や装備パッシブへ広げる場合は別Stepで仕様化します。
- `apply_modifier` は消耗品ではruntime modifier、装備パッシブではUnitのstat合計、装備攻撃では現状候補外です。同じeffect_typeでも入口ごとの意味を混同しないようにします。
- `sample_*` 装備はGameData上に残しますが、`spawn_weight=0` により通常random spawn候補から外す前提です。

## Step 11-Lで見えたTrade / Chest ownership系の追加注意

- Trade / Chest ownership docsは [../systems/trade_chest_ownership_deep_dive.md](../systems/trade_chest_ownership_deep_dive.md) を入口にします。
- `InventoryUI` では `UIMode.CHEST` のside inventoryも `trade_inventory` 変数を使います。modeとsource areaを混同しないようにします。
- sceneを跨いで持ち越すのはheld item entry/source情報であり、trade/chestのnode参照やside inventory参照は持ち越しません。
- chest inventoryは `WorldState.map_chests` 経由で保存対象ですが、merchant/shop inventoryとUnit本体inventoryは混同しないようにします。
- 所有権モデルの再設計、side inventory helper、UI lock matrixの整理はStep 12以降の別フェーズで扱います。

## Codex依頼時に指定するとよいこと

- 対象サブシステム名。
- 触ってよいファイルと触らないファイル。
- データ変更あり/なし。
- scene跨ぎやsave/load確認が必要か。
- Godot実行確認の範囲。
- debug flagを一時ONにしてよいか、最後にOFFへ戻すか。
