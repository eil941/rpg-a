# Feature Addition Guide

新機能追加時に「まずどこを見るか」をまとめた入口表です。実装前には `script_responsibility_map.md` と `runtime_flow_overview.md` も合わせて確認すると迷いにくくなります。

## 入口表

| やりたいこと | まず見るファイル | 変更候補 | 触らない方がいい場所 | 確認方法 |
| --- | --- | --- | --- | --- |
| 新アイテムを追加したい | `master_data.xlsx`, `data/master/items.tsv`, `scripts/data/item_data.gd`, `scripts/item/item_database.gd` | Excel `items` sheet、icon/resource path、category | 挙動追加が不要ならruntime script | export、validate、inventory表示、`ItemDatabase` lookup。 |
| 新しいアイテム効果を追加したい | `data/master/item_effects.tsv`, `scripts/data/item_effect_data.gd`, `scripts/item/item_effect_manager.gd` | Excel `item_effects`, `item_effect_links`, 新effect typeなら実行handler | 装備攻撃効果でなければ `CombatManager` | item使用、effect発動、save/load必要性確認。 |
| 新しい装備を追加したい | `data/master/items.tsv`, `data/master/equipment.tsv`, `scripts/data/equipment_data.gd` | Excel `items` + `equipment` sheets | slot UI変更がなければ `InventoryUI` | debug start itemやchestで入手、装備/解除確認。 |
| 装備中パッシブ効果を追加したい | `item_effects.tsv`, `item_effect_links.tsv`, `Unit.get_equipped_item_effects()` | `apply_modifier` effect と link | `equipment_effect_links.tsv` は作らない | 装備中だけstatが上がり、外すと戻る。 |
| 装備攻撃効果を追加したい | `item_effects.tsv`, `item_effect_links.tsv`, `CombatManager._apply_equipment_attack_effects()` | 既存effect typeならlinkだけ。新typeならdispatcher/helper追加 | 消耗品effect経路を大きく変えない | 攻撃命中時、`trigger_chance`、死亡済みtarget挙動を確認。 |
| 新しい敵を追加したい | `data/master/enemies.tsv`, `scripts/data/enemy_data.gd`, map spawn scripts | Excel `enemies`、spawn tags、equipment、initial inventory | spawn logic変更はタグ/ルールで表現できない時だけ | export、validate、対象mapでspawn確認。 |
| 敵の初期所持品を追加したい | `initial_inventory_tables.tsv`, `initial_inventory_entries.tsv`, `enemies.tsv`, `InitialInventoryEntry` | inventory table追加/再利用、`initial_inventory_table_id`設定 | death drop logic、旧 `initial_inventory_items` | enemy生成時に所持品を持ち、死亡時に持っていた物だけ落ちる。 |
| 死亡時ドロップ仕様を変更したい | `docs/death_drop_spec.md`, `Unit.drop_inventory_items_on_death_if_needed()`, `ItemDropHelper` | 仕様docs更新後、flagやdrop helperを小さく変更 | `initial_inventory_*`、drop table追加 | 3 flag mode、bag/hotbar/equipment、stack、装備instanceを確認。 |
| インベントリUIを変更したい | `InventoryUI.tscn`, `scripts/item/inventory_ui.gd`, `scripts/item/inventory.gd` | UI layout、mode別処理、held item処理 | PlayerData変更はscene跨ぎstateが必要な時だけ | bag/hotbar/equipment/trade/chest、held item scene transition。 |
| hotbarを変更したい | `scripts/item/inventory.gd`, `scripts/item/inventory_ui.gd`, `scripts/controllers/player_controller.gd`, `scripts/hud/game_hud.gd` | slot数、選択、使用、表示 | death dropはhotbar drop semantics変更時だけ | hotbar選択/使用、save/load、death drop。 |
| trade/chestを変更したい | `InventoryUI.gd`, `chest.gd`, `DialogueManager`, `GameAndHud.open_trade_ui()`, `TradePriceCalculator` | transfer rule、価格、chest権限 | 通常inventory移動やdeath drop | trade売買、chest出し入れ、特殊mode中移動不可。 |
| 新しいNPCを追加したい | `data/master/npcs.tsv`, `scripts/data/npc_data.gd`, `DialogueManager`, `QuestManager` | Excel `npcs`、dialogue、shop table、quest link | enemy spawn ruleはrandom NPCが必要な時だけ | spawn、talk、trade、quest確認。 |
| 新しいクエストを追加したい | quest系TSV、`QuestManager`, quest board UI | Excel quest sheets、NPC link、報酬 | inventory codeは特殊報酬が必要な時だけ | 受注、進行、完了、失敗、save/load。 |
| 新しいマップ/シーン遷移を追加したい | map scene script、`GameAndHud.load_map_by_path()`, `GlobalPlayerSpawn`, `WorldState` | event tile、request map change、spawn tile context | SaveManagerは永続load仕様を変える時だけ | 遷移、戻り位置、save/load。 |
| Debug用確認機能を追加したい | `DebugSettings.gd`, 対象feature script | default-off flag、scoped log/action | master dataは必要な時だけ | default off確認、ON時のみログ/挙動確認。 |

## Data Feature Checklist

1. 既存TSVと既存行を確認します。
2. `master_data.xlsx` を編集します。
3. `tools/export_master_tsv.py` を実行します。
4. `tools/validate_master_data.py` を実行します。
5. `git diff --check` を実行します。
6. TSVの件数、参照ID、空欄default、既存行への影響を確認します。
7. 可能ならGodotで起動エラーと Variant warning-as-error がないことを確認します。

## Runtime Feature Checklist

1. `docs/runtime_flow_overview.md` で処理フローを探します。
2. `docs/script_responsibility_map.md` でowner scriptを探します。
3. 既存の近い関数/helperに寄せます。
4. 大きな設計変更ではなく、小さなdispatcher/helper追加から始めます。
5. debug flagは原則default OFFにします。
6. validateとdiff checkを実行します。
7. UI/戦闘/死亡/保存などruntime挙動はGodotで確認します。

## 共通ガードレール

| 領域 | 守ること |
| --- | --- |
| Master data | `master_data.xlsx` と `data/master/*.tsv` を同期させる。 |
| 装備効果 | `item_effect_links.tsv` を使う。`equipment_effect_links.tsv` は追加しない。 |
| 死亡時ドロップ | 実際に持っている inventory/hotbar/equipment を落とす。死亡時に `initial_inventory_*` を再抽選しない。 |
| Initial inventory | `initial_inventory_table_id` を使う。deprecated `initial_inventory_items` は新規データで使わない。 |
| Skills / status UI | 明示依頼がない限り触らない。 |
| InventoryUI | held item state と source ownership を守る。free済み参照に注意。 |
| sample/test content | 通常ランダム生成に混ざらないよう、tagや `spawn_weight <= 0` で隔離。 |

## System別の入口

| System | Start here | Notes |
| --- | --- | --- |
| Items | `ItemDatabase`, `GameDataRegistry`, `ItemData` | runtime lookupはGameData経由。 |
| Effects | `ItemEffectData`, `ItemEffectManager`, `CombatManager` | 消耗品と装備攻撃は同じデータを使うが実行経路が違う。 |
| Equipment | `Unit` equipment getters, `InventoryUI`, `EquipmentData` | total statは装備、enchant、passive effect、runtime modifierを含む。 |
| Combat | `CombatManager`, `DamageCalculator`, `Stats` | 死亡処理の共通経路を壊さない。 |
| Spawn | `UnitSpawnManager`, map scene scripts, `EnemyData`/`NpcData` | 保存済みUnitではinitial inventoryを再抽選しない。 |
| World persistence | `WorldState`, `SaveManager`, map `save_all_units()` | runtime辞書がmap復元の元。 |
| UI | `GameAndHud`, 各UI script | rootが開閉を持ち、各UI scriptが画面内挙動を持つ。 |

## 確認コマンド

データ変更あり:

```powershell
py tools\export_master_tsv.py
py tools\validate_master_data.py
git diff --check
```

データ変更なし:

```powershell
py tools\validate_master_data.py
git diff --check
```

`py` がない環境では、利用可能なPythonまたは同梱Pythonで代替し、最終報告に書きます。
