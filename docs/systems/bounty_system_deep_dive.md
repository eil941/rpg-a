# 賞金首システム詳細

## 目的

賞金首システムは、既存の enemy、詳細マップ、ドロップ、セーブ、NPC会話に接続する期間限定の強敵イベントです。

最小実装（MVP）では、詳細マップやダンジョンなど `WorldState.is_regenerable_map_id()` が true になるマップに、既存の `EnemyData` を元にした賞金首をランダム生成します。賞金首は通常敵より能力値が高く、倒すと通常ドロップとは別に `gold` を追加で落とします。

Godotに詳しくない人向けに言うと、`Unit` はUnityでいうキャラクター用のGameObjectに近い実行時ノードで、`WorldState` はワールド側の保存対象データを置く場所です。賞金首は見た目や戦闘処理では通常の enemy Unit を使いますが、発生状態は通常敵とは別の `WorldState.bounty_data` に保存します。

重要な方針として、賞金首個体は `master_data.xlsx` や専用TSVで1件ずつ作成しません。ExcelやTSVで管理するのは、元になる通常 enemy とマップごとの enemy spawn pool です。ゲーム内では、その候補の中からランダムに敵を選び、賞金首インスタンスとして `WorldState.bounty_data` に発生状態を保存します。

## 最小実装での前提

| 項目 | 内容 |
| --- | --- |
| 対象Unit | `enemy` のみ。NPC、player、objectは賞金首にしない。 |
| 生成方法 | 既存の enemy spawn pool から候補を受け取り、対象マップごとにランダムで1体を選ぶ。 |
| データ方針 | 賞金首個体はExcel/TSVで直接作らない。既存 enemy 候補をゲーム内で賞金首化する。 |
| 出現期間 | `start_day` から `end_day` まで。日数は `TimeManager.get_day()` を基準にする。 |
| 保存場所 | `WorldState.bounty_data`。通常敵の `WorldState.map_enemy_spawns` には混ぜない。 |
| 報酬 | 討伐時に追加の `gold` pickup を地面に落とす。 |
| 強化方法 | 通常の enemy データ適用後、賞金首用の `stat_multiplier` をかける。 |
| 表示補助 | 名前に `賞金首: ` を付け、頭上に `!` マーカーを出す。これは見た目専用で、状態の正本ではない。 |
| 情報確認 | GUARD、QUEST_GIVER、または `extra_interact_actions=bounty_board` / `bounty_info` のUnitから確認する。 |

## 関連スクリプト

| スクリプト | 役割 |
| --- | --- |
| `scripts/managers/bounty_manager.gd` | 賞金首データの生成、期間判定、討伐済み・期限切れ状態、NPC表示用テキストを管理する。 |
| `scripts/managers/unit_spawn_manager.gd` | 通常 enemy の保存済み復元またはランダム生成後に、現在マップの賞金首を追加スポーンする。 |
| `scripts/core/unit.gd` | `is_bounty` / `bounty_id` などの実行時情報を持ち、賞金首の能力値倍率、表示名、頭上マーカー、討伐時の追加 `gold` ドロップを処理する。 |
| `scripts/world/world_state.gd` | `bounty_data` を保持し、new game時にクリアする。 |
| `scripts/save_manager.gd` | `bounty_data` をセーブ/ロード対象のsnapshotに含める。 |
| `scripts/systems/time_manager.gd` | 時間経過後に賞金首の期限切れ判定を呼び、現在シーン上の期限切れ賞金首も消す。 |
| `scripts/unit_interaction_logic.gd` | NPC会話のアクションに賞金首一覧表示を追加する。 |
| `scripts/item/item_drop_helper.gd` | 討伐報酬の `gold` pickup を既存の地面ドロップ経路で生成し、WorldStateへ保存する。 |

## 保存される状態

賞金首の正本は `WorldState.bounty_data` です。キーは `bounty_id`、値はDictionaryです。

| 項目 | 内容 |
| --- | --- |
| `bounty_id` | 賞金首インスタンスの一意ID。 |
| `enemy_type_id` | 元になる `EnemyData.enemy_type_id`。対象は enemy 限定。 |
| `map_id` | 出現する詳細マップまたはダンジョン階層の識別子。 |
| `spawn_position` | `{ "x": int, "y": int }` 形式の出現タイル。 |
| `start_day` / `end_day` | 有効期間。`TimeManager.get_day()` 基準で、`end_day` 当日も有効期間に含む。 |
| `reward_gold` | 討伐時に追加で落とす `gold` 量。 |
| `stat_multiplier` | 通常敵より強くするための能力値倍率。 |
| `state` | `active` / `defeated` / `expired`。 |
| `is_defeated` | 討伐済みかどうかを簡単に見るためのフラグ。 |
| `unit_id` | ランタイムUnitに割り当てるID。 |

`Unit.get_stats_data()` にも `is_bounty`, `bounty_id`, `bounty_reward_gold`, `bounty_stat_multiplier` が含まれます。ただし、賞金首の発生状態そのものの正本は `WorldState.bounty_data` です。Unit側の値は、実行時の判別や途中保存・デバッグ確認を助けるための補助情報です。

頭上マーカーの `BountyMarkerLabel` は表示補助として実行時に作られるNodeです。セーブ対象ではなく、賞金首かどうかの判定にも使いません。賞金首状態の判定や復元は、引き続き `WorldState.bounty_data` と `Unit` の `is_bounty` / `bounty_id` を使います。

## 通常敵との分離

通常 enemy は、マップごとの保存済みスポーンとして `WorldState.map_enemy_spawns` や `WorldState.unit_states` に保存されます。詳細マップのリセットでは、この通常敵の台帳やタイル、pickup、chestなどが消えることがあります。

賞金首はこの通常敵台帳に混ぜません。`WorldState.bounty_data` に `map_id`、`spawn_position`、期間、討伐状態を持つことで、通常マップリセットとは独立して扱います。

この分離により、プレイヤーが詳細マップを離れて通常のリセット期間を跨いでも、賞金首がまだ期間中なら同じ `bounty_id`、同じ `map_id`、同じ `spawn_position` から再スポーンできます。一方で、期限切れまたは討伐済みの賞金首は再スポーン対象から外れます。

## 生成から討伐までの流れ

1. マップ読み込み
2. 通常 enemy の生成または復元
3. `UnitSpawnManager` が賞金首追加スポーンを確認
4. `BountyManager` が既存の active bounty を探す
5. なければランダムに賞金首を生成
6. `Unit` に `is_bounty` / `bounty_id` / 報酬 / ステータス倍率を渡す
7. `Unit._ready()` で通常 enemy データ適用後に賞金首倍率、`賞金首: 敵名` 表示、頭上マーカーを適用
8. 死亡時に討伐済みにして `gold` を落とす
9. セーブ/ロード後も状態が維持される

もう少し細かく追うと、`UnitSpawnManager` はまず保存済みUnitや通常ランダム enemy を扱います。その後で `spawn_active_bounty_for_current_map()` を呼び、`BountyManager.ensure_active_bounty_for_map()` に現在マップの賞金首が必要か確認します。既に有効な賞金首があればそのデータを使い、同期間内に討伐済みの賞金首があれば新規生成しません。

新規生成が必要な場合は、現在マップが賞金首対象か、候補 enemy があるか、歩けるタイルがあるかを確認してから、`WorldState.bounty_data` に追加します。その後、enemy sceneを通常通りinstantiateしつつ、`Unit` に賞金首用の実行時情報を渡します。

## マップリセットとの関係

通常の詳細マップリセットは `WorldState.clear_regenerable_map_data()` で、`map_enemy_spawns`、`map_item_pickups`、`map_chests`、マップタイルなどを消します。

賞金首は `map_enemy_spawns` に入らず、`WorldState.bounty_data` に残ります。そのため、通常敵が再抽選されるタイミングでも、期間中の賞金首は同じデータから復元されます。

期限切れは `BountyManager.expire_bounties()` が処理します。期限を過ぎた賞金首は `state=expired` になり、対応する `unit_id` の `WorldState.unit_states` も消されます。時間経過中にプレイヤーが同じマップ上にいる場合は、`TimeManager.advance_time()` から `BountyManager.expire_bounties_and_remove_runtime()` が呼ばれ、シーン上の期限切れ賞金首も `queue_free()` で消えます。

## 討伐時の流れ

賞金首Unitが死亡すると、通常の死亡処理の中で `Unit.handle_bounty_death_reward_if_needed()` が呼ばれます。

1. `is_bounty` と `bounty_id` を確認する。
2. `BountyManager.mark_bounty_defeated()` で `WorldState.bounty_data[bounty_id]` を `state=defeated` / `is_defeated=true` にする。
3. `reward_gold` が0より大きければ、`ItemDropHelper.drop_entry_near_unit()` で `gold` pickupをUnitの近くに落とす。
4. 生成されたpickupは既存の地面ドロップ経路に乗るため、pickup状態もWorldState側へ保存される。

通常の死亡時ドロップと賞金首追加報酬は別処理です。通常ドロップではUnitが実際に持っているinventory / hotbar / equipmentを落とし、賞金首報酬では追加の `gold` を落とします。

## 情報確認の流れ

NPC会話から賞金首情報を確認する入口は `scripts/unit_interaction_logic.gd` です。

`UnitInteractionLogic.can_show_bounty_board()` が true になるUnitでは、会話アクションに賞金首情報が追加されます。対象は次のいずれかです。

| 条件 | 用途 |
| --- | --- |
| `UnitRole.GUARD` | 街や拠点の警備NPCに賞金首情報を持たせる。 |
| `UnitRole.QUEST_GIVER` | 依頼を扱うNPCから賞金首情報も確認できるようにする。 |
| `extra_interact_actions` に `bounty_board` または `bounty_info` | master TSVで明示的に賞金首情報NPCを指定する。 |

表示文は `BountyManager.build_bounty_board_text()` が作ります。現在発生中の賞金首について、`賞金首: 敵名`、出現場所、残り期間、報酬金額を簡易テキストで表示します。

現時点の実装では、会話アクション名、戻るボタン、賞金首一覧の基本文言は日本語です。ただし専用UIではなく、既存の会話テキスト上に出す簡易表示です。

## セーブ/ロードとの関係

`SaveManager` のWorldState snapshot対象に `bounty_data` が含まれています。そのため、セーブ後にロードしても以下の状態が維持されます。

| 維持される内容 | 説明 |
| --- | --- |
| 発生中の賞金首 | `bounty_id`、対象 enemy、map、出現タイル、期間、報酬、倍率が残る。 |
| 討伐済み状態 | `state=defeated` と `is_defeated=true` が残り、再スポーンしない。 |
| 期限切れ状態 | `state=expired` が残り、期限切れ賞金首として扱われる。 |
| 追加報酬のpickup | `gold` pickupは既存の地面ドロップ保存経路で扱われる。 |

new game時は `WorldState.reset_for_new_game()` で `bounty_data` がクリアされます。

## 今できること

| できること | 現在の接続先 |
| --- | --- |
| enemy を元にした賞金首のランダム生成 | `UnitSpawnManager` と `BountyManager`。 |
| 期間付き管理 | `TimeManager.get_day()` と `BountyManager.expire_bounties()` |
| 期間中の再スポーン | `WorldState.bounty_data` から同じ `map_id` / `spawn_position` を使う |
| 討伐済み管理 | `BountyManager.mark_bounty_defeated()` |
| 期限切れ管理 | `state=expired` とruntime Unitの除去 |
| `gold` 追加報酬 | `Unit.handle_bounty_death_reward_if_needed()` と `ItemDropHelper` |
| GUARD / QUEST_GIVER / `extra_interact_actions=bounty_board` からの情報表示 | `UnitInteractionLogic` と `BountyManager.build_bounty_board_text()` |
| 名前・頭上マーカー・発見ログ | `Unit.apply_bounty_display()` と `UnitSpawnManager.spawn_active_bounty_for_current_map()`。発見時は `賞金首を発見: 賞金首: 敵名` をHUDログとGodot出力ログへ出す。 |

## リセット確認ログ

通常リセット間隔は、現在デバッグ確認しやすいように `TimeManager.DAYS_PER_RESET = 1` です。NPCリセット間隔も `TimeManager.NPC_DAYS_PER_RESET = 1` です。

リセットの挙動確認用に、Godot出力ログへ `[RESET DEBUG]` を出します。これはゲーム内ログではなく、マップリセットとNPCリセットの検証用ログです。

| ログ | 分かること |
| --- | --- |
| `Day=... 通常リセット間隔=... index=... NPCリセット間隔=... npc_index=...` | 日付が進んで通常/NPCリセットindexが変わったこと。 |
| `通常リセット予約` | 通常リセットの周期を跨ぎ、FieldMapに戻った時に実行する予約が立ったこと。 |
| `通常リセット実行` | FieldMap上で通常リセットが実行されたこと。 |
| `NPCリセット実行` | NPCリセットが実行されたこと。 |

賞金首は通常 enemy の `map_enemy_spawns` ではなく `WorldState.bounty_data` を正本にするため、通常リセットを跨いでも期間中なら同じ賞金首が復元されます。`[RESET DEBUG]` はこの挙動を確認するための補助ログです。

## まだ未実装

| 未実装のもの | 今後の方向 |
| --- | --- |
| 専用UI | 会話テキストではなく、一覧・地図・難度・期限を見やすくする画面を作る。 |
| 専用賞金首ギルド | `extra_interact_actions=bounty_board` を使い、専用NPCや施設へ広げる。 |
| 特殊アイテム報酬 | `reward_items` や報酬テーブルIDを `bounty_data` またはmaster側に追加する。 |
| 複数賞金首の同時発生 | mapごとの上限数や同時発生数をルール化する。 |
| クエスト目標との連携 | Quest objectiveが `bounty_id` の討伐状態を参照できるようにする。 |
| カルマ・勢力評価との連携 | 討伐時にFactionやKarma系へイベント通知する。 |
| 発生率や倍率の設定データ化 | 必要になった場合、発生率、報酬倍率、能力値倍率などを設定データに逃がす余地がある。ただし、賞金首個体をExcelで1件ずつ作る運用にはしない。 |

## データ追加方法

最小実装では、新しい賞金首専用Excel sheetや専用TSVは追加していません。現在の方針でも、賞金首個体を `master_data.xlsx` で直接追加する運用にはしません。

賞金首を増やしたい場合は、「賞金首データ」を直接追加するのではなく、元になる通常 enemy 候補を増やします。賞金首候補は、現在マップの enemy spawn pool に渡された `Array[EnemyData]` からゲーム内でランダムに選ばれます。そのため、どの敵が賞金首候補になるかは、既存の enemy データ、spawn rule、dungeon spawn rule 側に依存します。

enemy候補を増やす場合は、通常の enemy 追加手順に従います。`enemies` の内容やマップごとのspawn poolを調整すると、そのマップでランダムに選ばれる賞金首候補も変わります。発生した賞金首インスタンスの `bounty_id`、`enemy_type_id`、`map_id`、`spawn_position`、期間、報酬、倍率、状態は `WorldState.bounty_data` に保存されます。

特定NPCに賞金首情報を見せたい場合だけ、NPC側の設定を調整します。これは「賞金首データ追加」ではなく、「賞金首情報を見せるNPC設定」です。

1. `master_sub/npcs.tsv` の対象NPCに GUARD または QUEST_GIVER のroleを設定する。
2. `extra_interact_actions` に `bounty_board` または `bounty_info` を入れる。

Excelを正本としてNPCやenemyを編集する場合は、通常どおり `master_data.xlsx` 側とTSVを同期します。ただし、ここで作るのは通常 enemy や情報表示NPCであり、賞金首インスタンスそのものではありません。

## 今後の拡張案

| 拡張 | 方針 |
| --- | --- |
| 特殊アイテム報酬 | `reward_items` または報酬テーブルIDを追加し、討伐時に `ItemDropHelper` へ複数entryを渡す。 |
| 発生設定のデータ化 | 将来、発生率、報酬倍率、能力値倍率、対象map、enemy tagなどをデータから調整したくなった場合は、設定用TSVを検討する余地がある。ただし、現方針では賞金首個体そのものをExcel/TSVで1件ずつ作らない。 |
| 複数賞金首 | active bountyを複数返せる形に変更し、mapごとの上限数をルールで制御する。 |
| 情報NPCの専用化 | `extra_interact_actions=bounty_board` を使い、賞金首ギルドNPCや掲示板役のUnitをmasterで明示する。 |
| ギルド・依頼連携 | `QuestManager` に bounty objective を追加し、討伐状態をquest完了条件として参照する。 |
| カルマ・評判連携 | 討伐時にfaction reputationやkarma系へイベント通知する。 |
| UI強化 | Dialogue textではなく専用一覧UIを作り、map名、難度、報酬、期限でソート・フィルタする。 |
| バランス調整 | 報酬計算や倍率を調整し、map difficulty、enemy rank、期間を反映する。データ化する場合も、既存enemyからランダム選出する方針は維持する。 |

## 確認メモ

docsだけを変更する場合は、最低限 `git diff --check` で空白やpatch上の問題を確認します。

ゲーム本体を変更した場合は、必要に応じてGodotのheadless起動や `tools/validate_master_data.py` も実行します。
