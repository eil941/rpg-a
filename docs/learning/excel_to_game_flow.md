# Excel To Game Flow
## このページで理解すること
このページは、`master_data.xlsx` の内容がゲーム内で使える data になるまでを、item / equipment / item effect 周辺に絞って追う入口です。
読んだ後に、Excel が正本であること、Python は開発時の変換処理であること、Godot 実行時は TSV を `GameDataRegistry` が読むこと、`ItemDatabase` は登録済み data を取得する窓口であることを説明できる状態を目指します。
## 最初に全体像
これは全システム共通の完全な経路ではなく、item 周辺を理解するための代表的な流れです。
```text
master_data.xlsx
↓
tools/export_master_tsv.py
↓
data/master/*.tsv
↓
GameDataRegistry.load_all()
↓
各loader
↓
ItemData / EquipmentData / ItemEffectData
↓
itemとeffectのlink適用
↓
ItemDatabaseや各Managerが利用
↓
ゲーム内処理
```
Godot は Excel を直接読みません。開発時に Python で TSV を生成し、実行時に Godot 側が TSV を読みます。
## 各段階の役割
### `master_data.xlsx`
- 人間が編集する正本です。
- 今回の主なシートは `items`、`equipment`、`item_effects`、`item_effect_links` です。
- `items` は item の基本情報、`equipment` は装備固有情報、`item_effects` は効果本体、`item_effect_links` は item と effect の接続です。
- TSV は生成結果なので、原則として直接編集しない運用です。
### Python変換
- 対象ファイル: `tools/export_master_tsv.py`
- Excel から `data/master/*.tsv` を生成する開発時ツールです。ゲーム実行中に Python が動いているわけではありません。
- `tools/validate_master_data.py` は生成後 TSV の参照や値を検証する別ツールです。
- 失敗時は Python エラー、対象シート名、出力先、validator 結果を確認します。
### TSV
- `data/master/items.tsv`: item の基本定義です。item_id、表示名、カテゴリ、使用可否などを持ちます。
- `data/master/equipment.tsv`: 装備 item に slot や固定 bonus などを追加します。同じ item_id が `items.tsv` 側に必要です。
- `data/master/item_effects.tsv`: effect 本体です。`restore_resource` などの effect_type と値を持ちます。
- `data/master/item_effect_links.tsv`: item_id と effect_id をつなぎます。効果内容そのものはここには書きません。
### GameDataRegistry
- 対象ファイル: `scripts/data/game_data_registry.gd`
- Autoload の `GameData` として使われる runtime loader です。
- `load_all()` が読み込み全体の入口です。
- item 周辺では `_load_items()`、`_load_equipment()`、`_load_item_effects()`、`_load_item_effect_links()`、`_apply_item_effect_links()` の順に読みます。
- TSV の行を data class に変換し、辞書へ登録します。
### Data class
- `scripts/data/item_data.gd`: `ItemData`。item の基本情報と `effects` 配列を持ちます。
- `scripts/data/equipment_data.gd`: `EquipmentData`。`ItemData` を継承し、装備 slot や bonus を持ちます。
- `scripts/data/item_effect_data.gd`: `ItemEffectData`。effect_type、resource_type、power などを持ちます。
- TSV の1行を、ゲーム中で扱いやすい Resource へ変換したものです。
### ItemDatabaseと利用側
- 対象ファイル: `scripts/item/item_database.gd`
- `ItemDatabase` は TSV を直接読む中心ではありません。
- `GameDataRegistry` に登録済みの item data を検索・取得する窓口です。
- `Inventory`、UI、`Unit`、spawn 系などが `ItemDatabase` 経由で data を取り、Manager が実際の処理に使います。
## 読み込み順
item 周辺の現行順序は次です。
```text
_load_items()
↓
_load_equipment()
↓
_load_item_effects()
↓
_load_item_effect_links()
↓
_apply_item_effect_links()
```
- `_load_items()`: `items.tsv` から `ItemData` を作り、`items[item_id]` に登録します。
- `_load_equipment()`: `equipment.tsv` を読み、既存 `ItemData` を元に `EquipmentData` を作って置き換えます。
- `_load_item_effects()`: `item_effects.tsv` から `ItemEffectData` を作り、`effects[effect_id]` に登録します。
- `_load_item_effect_links()`: `item_effect_links.tsv` から item_id と effect_id の対応を集めます。
- `_apply_item_effect_links()`: link を order 順に並べ、対象 item の `effects` 配列へ `ItemEffectData` を追加します。
## 具体例: `healing_potion`
現行 TSV にある `healing_potion` を追います。
```text
items sheet
↓
data/master/items.tsv: healing_potion
↓
ItemData
↓
data/master/item_effects.tsv: healing_potion_restore_hp
↓
ItemEffectData
↓
data/master/item_effect_links.tsv: healing_potion -> healing_potion_restore_hp
↓
ItemData.effects
↓
ItemDatabase.get_item_data("healing_potion")
↓
Inventory / ItemEffectManager が利用
```
確認した現行 TSV:
- `items.tsv`: `healing_potion` は `category=consumable`、`usable=true`、説明は「HPを30回復する...」です。
- `item_effects.tsv`: `healing_potion_restore_hp` は `effect_type=restore_resource`、`resource_type=hp`、`power_min=30`、`power_max=30` です。
- `item_effect_links.tsv`: `healing_potion` と `healing_potion_restore_hp` が `order=1` でつながっています。
この例では `equipment.tsv` は使いません。装備 item の場合は、まず `items.tsv` に item があり、その後 `equipment.tsv` の同じ item_id で装備情報が追加されます。
## 対象コードと関数
### Python
対象ファイル: `tools/export_master_tsv.py`  
対象関数/場所: `SHEET_TO_TSV`  
このコードを見る理由: Excel のどのシートがどの TSV になるかを確認するため。
```python
SHEET_TO_TSV = {
    "item_categories": "item_categories.tsv",
    "items": "items.tsv",
    "equipment": "equipment.tsv",
    "item_effects": "item_effects.tsv",
    "item_effect_links": "item_effect_links.tsv",
    "chest_tables": "chest_tables.tsv",
}
```
ここで何をしているか: シート名と TSV ファイル名の対応を定義しています。  
入力: Excel の sheet。結果: 出力すべき TSV 名が決まります。次に進む処理: `main()` がこの対応を使って各 sheet を出力します。
対象ファイル: `tools/export_master_tsv.py`  
対象関数: `main()`  
このコードを見る理由: Excel を開き、`data/master` へ出力する流れを見るため。
```python
xlsx_path = project_root / "master_data.xlsx"
out_dir = project_root / "data" / "master"
wb = load_workbook(xlsx_path, data_only=True)

for sheet_name, tsv_name in SHEET_TO_TSV.items():
    if sheet_name not in wb.sheetnames:
        missing_sheets.append(sheet_name)
        continue
    ws = wb[sheet_name]
    rows = worksheet_to_rows(ws)
```
ここで何をしているか: `master_data.xlsx` を開き、対象 sheet を順番に取り出します。  
入力: `master_data.xlsx`。結果: sheet の行データが `rows` になります。次に進む処理: `export_tsv(rows, out_path)` で TSV を書き出します。
### GameDataRegistry
対象ファイル: `scripts/data/game_data_registry.gd`  
対象関数: `load_all()`  
このコードを見る理由: item 周辺の loader 順を確認するため。
```gdscript
_load_items()
_load_equipment()
_load_chest_tables()
_load_chest_loot_tables()
_load_shop_tables()
_load_shop_loot_tables()
_load_initial_inventory_tables()
_load_initial_inventory_entries()
_load_item_effects()
_load_item_effect_links()
_apply_item_effect_links()
```
ここで何をしているか: item、equipment、effect、link を決まった順に読みます。  
入力: `data/master/*.tsv`。結果: registry 内の辞書が埋まります。次に進む処理: lookup や Manager が登録済み data を使います。
対象ファイル: `scripts/data/game_data_registry.gd`  
対象関数: `_load_items()`  
このコードを見る理由: `items.tsv` の行が `ItemData` になる入口を見るため。
```gdscript
var rows := _load_tsv("res://data/master/items.tsv")

for row in rows:
    var item := ItemData.new()
    item.item_id = _get_string(row, "item_id")
    item.display_name = _get_string(row, "display_name")
    item.description = _get_string(row, "description")
```
ここで何をしているか: TSV 行から `ItemData` を作り始めます。  
入力: `items.tsv`。結果: `ItemData` の基本フィールドが入ります。次に進む処理: `_register_item(item)` で `items` 辞書へ登録されます。
対象ファイル: `scripts/data/game_data_registry.gd`  
対象関数: `_apply_item_effect_links()`  
このコードを見る理由: link が item の `effects` 配列へ適用される場所を見るため。
```gdscript
var links: Array = item_effect_links[item_id]
links.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))

item.effects.clear()

for link in links:
    var effect_id := String(link["effect_id"])
    var effect: ItemEffectData = effects.get(effect_id)
```
ここで何をしているか: item ごとの link を order 順にし、effect_id から `ItemEffectData` を探します。  
入力: `item_effect_links` と `effects` 辞書。結果: item の `effects` 配列へ effect を入れる準備をします。次に進む処理: `item.effects.append(effect)` で接続されます。
### ItemDatabase
対象ファイル: `scripts/item/item_database.gd`  
対象関数: `get_item_resource()` / `get_item_data()`  
このコードを見る理由: `ItemDatabase` が TSV ではなく `GameData` から取得していることを見るため。
```gdscript
static func get_item_resource(item_id: String):
    if item_id == "":
        return null
    if GameData == null:
        return null
    return GameData.get_item(item_id)

static func get_item_data(item_id: String):
    return get_item_resource(item_id)
```
ここで何をしているか: item_id を使って `GameData` から登録済み item を取得します。  
入力: `item_id`。結果: `ItemData` または `EquipmentData` が返ります。次に進む処理: `Inventory`、UI、`Unit`、Manager 側が data を利用します。
## 誰が何を持つか
- Excel: 人間が編集する正本です。
- TSV: 変換後のゲーム入力データです。
- `GameDataRegistry`: 実行時に TSV を読み、data と辞書を保持します。
- `ItemDatabase`: 登録済み item data を検索・取得する窓口です。
- `Inventory`: player や Unit が実際に持つ item entry と個数を持ちます。
- `ItemEffectManager`: item data に接続済みの effect を実行します。
## 反映されない場合の確認順
### Excelに追加したがTSVにない
- 最初に見る場所: `master_data.xlsx` の対象シート名、item_id、Python 実行結果。
- 次に見る場所: `tools/export_master_tsv.py` の出力先、Python エラー、`tools/validate_master_data.py` の結果。
- 理由: Godot 以前に、変換が成功しているかを確認する必要があります。
### TSVにはあるがゲームで見つからない
- 最初に見る場所: TSV の形式、重複 ID、`GameDataRegistry.load_all()` と対応 loader。
- 次に見る場所: error log、`ItemDatabase.get_item_data()`。
- 理由: TSV は存在しても、loader が登録できていなければ runtime data になりません。
### itemはあるが装備性能がない
- 最初に見る場所: `items.tsv` と `equipment.tsv` の item_id 一致。
- 次に見る場所: `_load_equipment()`、`ItemDatabase.get_equipment_resource()`。
- 理由: `equipment.tsv` は既存 item に装備情報を足す表なので、base item が必要です。
### itemはあるが効果がない
- 最初に見る場所: `item_effects.tsv` の effect_id と `item_effect_links.tsv` の item_id / effect_id / order。
- 次に見る場所: `_load_item_effects()`、`_apply_item_effect_links()`、`ItemData.effects`。
- 理由: effect 本体があっても、link されなければ item の effects には入りません。
## よくある勘違い
- Godot が Excel を直接読む: 読みません。実行時に読むのは TSV です。
- TSV が正本である: 正本は `master_data.xlsx` です。
- Python がゲーム実行中に動く: Python は開発時の変換です。
- `ItemDatabase` が TSV を直接読み込む中心である: TSV 読み込みは `GameDataRegistry` です。
- `equipment.tsv` だけで装備を新規作成できる: `items.tsv` に同じ item_id が必要です。
- `item_effect_links.tsv` に効果内容を書く: 効果本体は `item_effects.tsv` です。
- `item_effects.tsv` を書けば自動的に全 item へ効果が付く: `item_effect_links.tsv` で接続が必要です。
- 新しい `effect_type` を TSV に書くだけで動く: GDScript 側の enum / loader / handler / validator 対応が必要です。
- `equipment_effect_links.tsv` を使っている: 現行では `item_effect_links.tsv` を使います。
## 関連ファイル一覧
| 種類 | ファイル | 役割 |
| --- | --- | --- |
| 正本 | `master_data.xlsx` | 人間が編集 |
| 変換 | `tools/export_master_tsv.py` | TSV生成 |
| 検証 | `tools/validate_master_data.py` | データ整合性確認 |
| 実行時入力 | `data/master/items.tsv` など | Godotが読む |
| loader | `scripts/data/game_data_registry.gd` | data登録 |
| lookup | `scripts/item/item_database.gd` | item data取得 |
## このページでは扱わないこと
- 通常アイテム使用の完全な処理経路
- 対象指定アイテム
- 装備パッシブの完全な処理経路
- 装備攻撃効果
- 全 effect_type
- 全 TSV
- Save / Load
- spawn 全般
- death drop
- 新しい TSV 追加の完全手順
- 新しい effect_type の完全実装手順
## 詳細を確認する既存 docs
- [../systems/game_data_registry_loader_map.md](../systems/game_data_registry_loader_map.md)
- [../guides/item_addition_guide.md](../guides/item_addition_guide.md)
- [../architecture/script_responsibility_map.md](../architecture/script_responsibility_map.md)
- [../systems/equipment_item_effect_execution_path.md](../systems/equipment_item_effect_execution_path.md)
- [database_and_manager_roles.md](database_and_manager_roles.md)
- [start_here.md](start_here.md)
## 理解度チェック
1. 正本は Excel と TSV のどちらですか。
2. Python はいつ使われますか。
3. Godot が直接読むのは何ですか。
4. `GameDataRegistry` の役割は何ですか。
5. `ItemDatabase` の役割は何ですか。
6. `items.tsv` と `equipment.tsv` の違いは何ですか。
7. `item_effects.tsv` と `item_effect_links.tsv` の違いは何ですか。
8. Excel にはあるが TSV にない場合、最初に何を確認しますか。
9. TSV にはあるがゲームで見つからない場合、何を確認しますか。
10. item はあるが effect が接続されていない場合、何を確認しますか。
---
## 回答例
1. 正本は `master_data.xlsx` です。
2. Python は開発時に Excel から TSV を生成するときに使います。
3. Godot が直接読むのは `data/master/*.tsv` です。
4. `GameDataRegistry` は TSV を読み込み、data class や辞書へ登録します。
5. `ItemDatabase` は登録済み item data を検索・取得する窓口です。
6. `items.tsv` は基本 item、`equipment.tsv` は同じ item_id の装備固有情報です。
7. `item_effects.tsv` は効果本体、`item_effect_links.tsv` は item と effect の接続です。
8. シート名、item_id、Python 実行、Python エラー、出力先、validator 結果を確認します。
9. TSV 形式、`GameDataRegistry.load_all()`、対応 loader、重複 ID、error log、`ItemDatabase.get_item_data()` を確認します。
10. `item_effects.tsv`、`item_effect_links.tsv`、effect_id、item_id、order、`_apply_item_effect_links()`、`ItemData.effects` を確認します。
## このページを読んだら説明できること
- [ ] Excel が正本である
- [ ] Python が TSV を生成する
- [ ] Godot は TSV を読む
- [ ] `GameDataRegistry` が data を登録する
- [ ] `ItemDatabase` が登録済み data を取得する
- [ ] `items` / `equipment` / `effects` / `links` の違い
- [ ] Excel からゲームまでの大まかな流れ
- [ ] 反映されない場合の確認順
