# Database And Manager Roles
## このページで理解すること
このページは、主要スクリプトの責務を混同しないための学習用入口です。

読んだ後に、`GameDataRegistry`、`ItemDatabase`、`Inventory`、`ItemEffectManager`、`CombatManager`、`Unit`、`Stats` が「何をするか」「何をしないか」「不具合時に最初にどこを見るか」を説明できる状態を目指します。

## 最初に全体像
これは厳密な一本道ではなく、役割の大まかな関係です。
```text
TSV
↓
GameDataRegistry
↓
ItemDatabase
↓
Inventory / ItemEffectManager
↓
CombatManager / Unit / Stats
```
`Inventory` は実際の所持品を持ち、必要な時に `ItemDatabase` で定義を確認します。`ItemEffectManager` は item data の effects を実行します。`CombatManager` は通常攻撃、対象指定アイテム、装備攻撃効果の入口です。`Unit` はキャラクター全体、`Stats` は HP などの数値を担当します。

## まず覚える短い言い方
| 名前 | 短い言い方 |
| --- | --- |
| `GameDataRegistry` | 読む・保持する |
| `ItemDatabase` | 探す・返す |
| `Inventory` | 持つ・増減する・消費する |
| `ItemEffectManager` | 効果を実行する |
| `CombatManager` | 戦闘行動の入口を管理する |
| `Unit` | キャラクター全体をまとめる |
| `Stats` | 数値を持ち、変更する |

## 各スクリプトの役割

### GameDataRegistry
- ファイル: `scripts/data/game_data_registry.gd`
- 一言で: TSV を読み込み、ゲーム内で参照できるデータとして保持する入口。
- 主にやること: `data/master/*.tsv` を読み、`ItemData`、`EquipmentData`、`ItemEffectData` を作り、item と effect の link を接続する。
- 主にやらないこと: アイテム使用、攻撃、HP回復、所持数管理、death drop。
- 主な呼び出し元: Autoload の `GameData`、`ItemDatabase` などの検索用 wrapper。
- 主な呼び出し先: `_load_tsv()`、各 `_load_*()` loader。
- 最初に読む関数: `load_all()`、`_load_items()`、`_apply_item_effect_links()`。
- この関数を見る理由: 読み込み順、item data 作成、effect link 接続が分かるため。
- 入力: `items.tsv`、`equipment.tsv`、`item_effects.tsv`、`item_effect_links.tsv`。
- 結果・変更される状態: `items`、`effects`、`item_effect_links` など registry 内辞書。
- 間違えやすい相手: `ItemDatabase`。
- 困ったときに最初に見る場面: TSV にあるはずの item / effect がゲーム内で見つからない。
- 次に読むスクリプト: `scripts/item/item_database.gd`。

### ItemDatabase
- ファイル: `scripts/item/item_database.gd`
- 一言で: 登録済み item data を item_id から探して返す窓口。
- 主にやること: `GameData.get_item(item_id)` から data を取り、表示名、使用可否、装備データ、spawn 候補判定などを返す。
- 主にやらないこと: TSV 読み込み、正本管理、所持数管理、effect 実行。
- 主な呼び出し元: `Inventory`、`Unit`、UI、spawn、world item 系。
- 主な呼び出し先: `GameData.get_item()`。
- 最初に読む関数: `get_item_data()`、`is_usable()`、`get_equipment_resource()`。
- この関数を見る理由: item_id から定義を取る入口、使用可否、装備 data 取得が分かるため。
- 入力: `item_id`。
- 結果・変更される状態: 基本的に状態は変えず、登録済み data を返す。
- 間違えやすい相手: `GameDataRegistry`、`Inventory`。
- 困ったときに最初に見る場面: アイテム名、説明、装備データ、使用可否が取れない。
- 次に読むスクリプト: `scripts/item/inventory.gd`、`scripts/core/unit.gd`。

### Inventory
- ファイル: `scripts/item/inventory.gd`
- 一言で: Unit が実際に持っている item entry と個数を管理する。
- 主にやること: bag / hotbar の item entry、stack、追加、削除、使用時の消費を扱い、使用時に `ItemDatabase.is_usable()` を見て `ItemEffectManager` へ渡す。
- 主にやらないこと: effect の中身、通常攻撃、HPや攻撃力の数値管理。
- 主な呼び出し元: `Unit`、`InventoryUI`、pickup / grant item 系。
- 主な呼び出し先: `ItemDatabase`、`ItemEffectManager`。
- 最初に読む関数: `use_item_at()`、`use_hotbar_item_at()`、`add_item()`。
- この関数を見る理由: 通常使用、hotbar 使用、所持品増加の入口が分かるため。
- 入力: inventory index、hotbar index、`item_id`、`amount`。
- 結果・変更される状態: `items`、`hotbar_items`、entry の `amount`。
- 間違えやすい相手: `ItemDatabase`、`ItemEffectManager`。
- 困ったときに最初に見る場面: 個数、stack、使用後の消費がおかしい。
- 次に読むスクリプト: `scripts/item/item_effect_manager.gd`。

### ItemEffectManager
- ファイル: `scripts/item/item_effect_manager.gd`
- 一言で: item data に入っている effects を実行する。
- 主にやること: `ItemData.effects` を順番に処理し、回復、状態異常、ダメージ、buff / debuff などを target へ適用する。
- 主にやらないこと: 所持数管理、通常攻撃全体の管理、装備パッシブ stat 集計の中心。
- 主な呼び出し元: `Inventory`、`CombatManager`、一部の `Unit` 内処理。
- 主な呼び出し先: `ItemDatabase`、`Stats`、`DamageCalculator`、`Unit` の status / grant / teleport 系 method。
- 最初に読む関数: `apply_item_effect()`、`apply_item_effects()`、`apply_single_effect()`。
- この関数を見る理由: effect 実行入口、effects 配列の処理、effect_type 分岐が分かるため。
- 入力: user、target、`ItemData`、`ItemEffectData`。
- 結果・変更される状態: target の HP、status、runtime modifier、grant item など。
- 間違えやすい相手: `Inventory`、`CombatManager`。
- 困ったときに最初に見る場面: ポーション、状態異常、effect_type の効果が出ない。
- 次に読むスクリプト: `scripts/core/stats.gd`、`scripts/combat/combat_manager.gd`。

### CombatManager
- ファイル: `scripts/combat/combat_manager.gd`
- 一言で: 攻撃や対象指定アイテムなど、戦闘行動の入口を管理する。
- 主にやること: 通常攻撃、対象指定アイテム、命中、damage、装備攻撃効果の入口を扱う。
- 主にやらないこと: TSV 読み込み、inventory 保持、Unit 全体保存、death drop。
- 主な呼び出し元: `Unit`、controller 系、player の対象指定行動。
- 主な呼び出し先: `DamageCalculator`、`Stats.take_damage()`、`ItemEffectManager`、`Unit.check_death()`、`Unit.get_equipped_attack_effects()`。
- 最初に読む関数: `perform_attack()`、`can_use_selected_target_item()`、`_apply_equipment_attack_effects()`。
- この関数を見る理由: 通常攻撃、対象指定アイテムの guard、装備攻撃効果の中心が分かるため。
- 入力: attacker、target、selected target item、equipped attack effects。
- 結果・変更される状態: target の HP / status、行動結果、death check。
- 間違えやすい相手: `ItemEffectManager`、`Unit`。
- 困ったときに最初に見る場面: 通常攻撃、対象指定アイテム、装備攻撃効果がおかしい。
- 次に読むスクリプト: `scripts/core/unit.gd`、`scripts/core/stats.gd`、`scripts/combat/damage_calculator.gd`。

### Unit
- ファイル: `scripts/core/unit.gd`
- 一言で: キャラクター全体をまとめる本体。
- 主にやること: `Stats`、`Inventory`、装備、移動、死亡処理、drop、save/load 用状態をつなぎ、装備パッシブを stat 合計へ反映する。
- 主にやらないこと: TSV 読み込み、item 定義の正本管理、HP 数値だけの単独管理。
- 主な呼び出し元: controller 系、`CombatManager`、`Stats.die()`、map / spawn / save 系。
- 主な呼び出し先: `Stats`、`Inventory`、`ItemDatabase`、`ItemDropHelper`、`WorldState`。
- 最初に読む関数: `get_equipped_item_effects()`、`get_total_attack()`、`check_death()`。
- この関数を見る理由: 装備 effect 取得、装備パッシブの stat 反映、HP0 から death への入口が分かるため。
- 入力: Unit の現在状態、equipped item entry、Stats の現在値。
- 結果・変更される状態: 合計 stat、`death_handled`、death drop、world state 関連状態。
- 間違えやすい相手: `CombatManager`、`Stats`。
- 困ったときに最初に見る場面: 装備 stat、HP0 後の死亡処理、death drop がおかしい。
- 次に読むスクリプト: `scripts/core/stats.gd`、`scripts/item/item_drop_helper.gd`。

### Stats
- ファイル: `scripts/core/stats.gd`
- 一言で: HP などの数値を持ち、damage / heal / die を扱う。
- 主にやること: HP、stamina、hunger、基礎能力値を持ち、damage / heal / HP0 時の親 Unit 呼び出しを扱う。
- 主にやらないこと: death drop、inventory、equipment、TSV 読み込み。
- 主な呼び出し元: `CombatManager`、`ItemEffectManager`、`Unit`。
- 主な呼び出し先: 親 `Unit.handle_death()`。
- 最初に読む関数: `take_damage()`、`heal()`、`die()`。
- この関数を見る理由: HP が減る、回復する、Unit の death 処理へ渡る流れが分かるため。
- 入力: damage amount、heal amount。
- 結果・変更される状態: `hp`、必要なら親 Unit の death 処理。
- 間違えやすい相手: `Unit`。
- 困ったときに最初に見る場面: HP が減らない、回復しない、HP0 なのに death trigger されない。
- 次に読むスクリプト: `scripts/core/unit.gd`。

## 混同しやすい違い
### GameDataRegistry と ItemDatabase
- TSV を読むのは `GameDataRegistry`、検索窓口は `ItemDatabase` です。
- 正本は `master_data.xlsx`、実行時入力は `data/master/*.tsv` です。
- ゲームに出ないなら TSV 生成と `GameDataRegistry`、取得できないなら `ItemDatabase` を見ます。
### ItemDatabase と Inventory
- `ItemDatabase` は item_id から定義を取ります。
- `Inventory` は実際の item entry、個数、stack を持ちます。
### Inventory と ItemEffectManager
- 使用可否と個数消費は主に `Inventory`、効果実行は `ItemEffectManager` です。
- `ItemEffectManager` が失敗したら、`Inventory` は個数を減らさない経路があります。
### ItemEffectManager と CombatManager
- `ItemEffectManager` は item effect 実行担当です。
- `CombatManager` は通常攻撃、対象指定アイテム、装備攻撃効果の入口です。
- 装備パッシブの中心は `Unit` の stat 集計です。
### CombatManager と Unit
- `CombatManager` は戦闘行動を開始します。
- `Unit` はキャラクター全体の状態、装備、死亡処理、drop をまとめます。
### Unit と Stats
- `Unit` はキャラクター全体、`Stats` は HP などの数値です。
- damage / heal は `Stats`、death 処理と drop は `Unit` 側まで追います。

## 症状から最初に見る場所
| 症状 | 最初 | 次 | 理由 |
| --- | --- | --- | --- |
| Excelに追加したのにゲームに出ない | TSV生成と `GameDataRegistry` | `ItemDatabase` | runtime 入力と読み込みを先に確認するため |
| アイテム名や説明が取得できない | `ItemDatabase` | `GameDataRegistry` | 表示名取得は検索窓口から始まるため |
| アイテム個数がおかしい | `Inventory` | `ItemDatabase` | 実個数と stack は inventory entry 側の状態だから |
| ポーションを使っても回復しない | `Inventory` | `ItemEffectManager`、`Stats` | 使用入口、効果実行、HP変更の順で見るため |
| 対象指定アイテムが使えない | `CombatManager` | `ItemEffectManager` | 距離・対象・命中の guard が戦闘側にあるため |
| 装備しても能力値が上がらない | `Unit` | `ItemDatabase`、関連 TSV | 装備パッシブは Unit の stat 集計で効くため |
| 攻撃がおかしい | `CombatManager` | `DamageCalculator`、`Stats` | 攻撃入口、計算、HP変更を順に見るため |
| HPが0になったのに死亡処理されない | `Stats` | `Unit` | HP0 trigger から Unit の death 処理へ渡るため |

## 関連データ
- `items.tsv`: item の基本定義です。item_id、表示名、カテゴリ、使用可否、stack などの入口です。
- `equipment.tsv`: 装備 item の追加定義です。slot、固定 bonus、攻撃情報などを持ちます。
- `item_effects.tsv`: effect 本体です。effect_type と値を定義します。
- `item_effect_links.tsv`: item_id と effect_id をつなぎます。効果本体を定義する場所ではありません。
- `initial_inventory_tables.tsv`: 初期所持品 table の見出し側です。
- `initial_inventory_entries.tsv`: Unit 生成時の初期所持品 entry です。死亡時 drop table ではありません。

## よくある勘違い
- `ItemDatabase` が正本である: 正本は `master_data.xlsx`、実行時入力は TSV です。
- `Inventory` が HP 回復処理を直接実行する: 効果実行は `ItemEffectManager` です。
- `ItemEffectManager` が通常攻撃全体を管理する: 通常攻撃の入口は `CombatManager` です。
- 装備パッシブは `ItemEffectManager` が毎回実行する: 中心は `Unit` の stat 集計です。
- `Stats` が死亡 drop まで管理する: death trigger は持ちますが、drop は `Unit` 側です。
- `Unit` が TSV を直接読む: TSV 読み込みは `GameDataRegistry` です。
- `item_effect_links.tsv` が効果本体を定義する: 本体は `item_effects.tsv`、links は接続です。
- `equipment_effect_links.tsv` を使っている: 現行実装では消耗品も装備効果も `item_effect_links.tsv` を使います。

## このページでは扱わないこと
- 全 effect_type の詳細
- 全 TSV 列の説明
- 装備パッシブの完全な処理経路
- 装備攻撃効果の完全な処理経路
- 攻撃から死亡までの完全な処理経路
- death drop の詳細
- Save / Load
- UI state machine
- Trade / Chest

## 詳細を確認する既存 docs
- [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)
- [../systems/data/game_data_registry_loader_map.md](../systems/data/game_data_registry_loader_map.md)
- [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)
- [../systems/unit_lifecycle_deep_dive.md](../systems/unit_lifecycle_deep_dive.md)
- [../systems/combat/unit_combat_death_system_deep_dive.md](../systems/combat/unit_combat_death_system_deep_dive.md)
- [../systems/combat/death_path_diagram.md](../systems/combat/death_path_diagram.md)

## 理解度チェック
1. `GameDataRegistry` と `ItemDatabase` の違いは何ですか。
2. `ItemDatabase` と `Inventory` の違いは何ですか。
3. `Inventory` と `ItemEffectManager` の違いは何ですか。
4. `ItemEffectManager` と `CombatManager` の違いは何ですか。
5. `Unit` と `Stats` の違いは何ですか。
6. Excel に追加したのにゲームに出ない場合、最初に何を見ますか。
7. ポーションが回復しない場合、どの順番で見ますか。
8. 装備しても攻撃力が上がらない場合、最初に何を見ますか。
9. HP が 0 になったのに死亡処理されない場合、どこを見ますか。
10. `item_effect_links.tsv` の役割は何ですか。

---

## 回答例
1. `GameDataRegistry` は TSV を読み込み保持します。`ItemDatabase` は登録済み item data を検索して返します。
2. `ItemDatabase` は定義を返します。`Inventory` は実際の所持品、個数、stack を持ちます。
3. `Inventory` は使用入口と消費を扱います。`ItemEffectManager` は効果を実行します。
4. `ItemEffectManager` は effect 実行担当です。`CombatManager` は攻撃や対象指定行動の入口です。
5. `Unit` はキャラクター全体、`Stats` は HP などの数値担当です。
6. TSV が生成されているか、`GameDataRegistry` が読んでいるかを見ます。その後 `ItemDatabase` で取得できるかを見ます。
7. `Inventory`、`ItemEffectManager`、`Stats` の順で見ます。
8. まず `Unit` の stat 集計と装備 effect 取得を見ます。次に `ItemDatabase` と関連 TSV を見ます。
9. `Stats.take_damage()` / `Stats.die()`、次に `Unit.check_death()` / `Unit.handle_death()` を見ます。
10. item_id と effect_id を接続する table です。効果本体は `item_effects.tsv` にあります。

## このページを読んだら説明できること
- [ ] `GameDataRegistry` と `ItemDatabase` の違い
- [ ] `ItemDatabase` と `Inventory` の違い
- [ ] `Inventory` と `ItemEffectManager` の違い
- [ ] `ItemEffectManager` と `CombatManager` の違い
- [ ] `Unit` と `Stats` の違い
- [ ] 症状から最初に見るスクリプト
- [ ] 各スクリプトで次に読む関数
