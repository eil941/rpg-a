# Trade / Chest Ownership Deep Dive

このdocsは、trade / chest / held item / side inventory の所有権と参照寿命を、現状コードから分かる範囲で整理するための地図です。

目的は、item消失、不正取得、free済み参照、scene跨ぎ参照持ち越しを避けるために、今の実装がどこに状態を置き、どこで境界を切っているかを把握することです。将来の改善案、分割案、リファクタ判断は扱いません。

## 関連する主なファイル

| File | 現状の役割 |
| --- | --- |
| `scripts/item/inventory_ui.gd` | normal / trade / chest mode、held item、side inventory操作の中心 |
| `scripts/item/inventory.gd` | bag / hotbar のentry管理、save/load、item use |
| `scripts/item/chest/chest.gd` | chest node、chest inventory、chest UI起動、chest単位のsave/load |
| `scripts/hud/game_and_hud.gd` | InventoryUIの通常open、trade UI起動、特殊Inventory UI判定 |
| `scripts/managers/dialogue_manager.gd` | dialogue actionからtrade UIを開く入口 |
| `scripts/trade_price_calculator.gd` | trade価格計算。inventory移動そのものは持たない |
| `scripts/data/player_data.gd` | player永続状態と、scene跨ぎheld item一時状態 |
| `scripts/world/world_state.gd` | map単位chest/pickup/unit/quest等のworld状態 |
| `scripts/save_manager.gd` | PlayerData / WorldState のsnapshot保存復元 |
| `scripts/core/unit.gd` | Unit本体inventory、equipment、death drop、interaction入口 |

## InventoryUIのmode整理

`InventoryUI` の `UIMode` は3種類です。

- `UIMode.NORMAL`: playerの通常inventory。bag / hotbar / equipment を操作する。
- `UIMode.TRADE`: player inventory と merchant側inventoryを並べる。
- `UIMode.CHEST`: player inventory と chest側inventoryを並べる。

重要なのは、UI mode と held item source は別概念であることです。

- UI modeは「今どの画面として開いているか」です。
- held item sourceは「今持ち上げているentryがどこから来たか」です。
- `held_from_area` は `inventory` / `hotbar` / `equipment` / `trade` などを持ちます。
- chest modeでも、side panel側の実装変数は `trade_inventory` が使われます。modeが `UIMode.CHEST` かどうかで、表示や権限判定を分けます。

移動制御の境界は次の通りです。

- 通常inventory中は移動可。
- trade / chest など特殊Inventory UI中は移動不可。
- `PlayerController.is_ui_locked()` は `is_special_inventory_ui_open()` を見るため、trade/chest中の移動は止まります。
- `GameAndHud.is_special_inventory_ui_open()` は `InventoryUI.is_special_inventory_mode_open()` を優先し、trade/chestをまとめて特殊modeとして扱います。

UI lock matrixの詳細は [ui_input_scene_transition_deep_dive.md](ui_input_scene_transition_deep_dive.md) と [inventory_ui_state_transition.md](inventory_ui_state_transition.md) を参照してください。このdocsでは、所有権と参照寿命を中心に扱います。

## Held item の所有権

held item は、InventoryUI上で持ち上げ中のentryです。現状の主な状態は `InventoryUI` にあります。

- `held_entry`
- `held_from_area`
- `held_from_index`
- `held_from_slot_name`

`held_entry` は `entry.duplicate(true)` で複製されます。これは、装備品やエンチャント付きitemが持つ `instance_data` を壊さずに保持するために重要です。`item_id` だけを持つのではなく、entry全体を保持します。

held item を掴める主なsourceは次の通りです。

- `inventory`: player / Unit のbag slot。
- `hotbar`: player / Unit のhotbar slot。
- `equipment`: Unitの装備slot。
- `trade`: trade modeのmerchant側、またはchest modeのside panel側。

scene遷移時には、古い `InventoryUI` やUnit nodeがfreeされる可能性があります。そのため、held item は `PlayerData.held_inventory_*` に一時退避されます。

- `PlayerData.held_inventory_entry`
- `PlayerData.held_inventory_source_area`
- `PlayerData.held_inventory_source_index`
- `PlayerData.held_inventory_source_slot_name`
- `PlayerData.held_inventory_previous_ui_mode`

`InventoryUI._exit_tree()` は held item がある場合に `persist_held_state_to_player_data()` を呼び、`current_inventory` / `current_unit` / `trade_inventory` / `trade_unit` をnullにします。

新しいInventoryUI側では `restore_held_state_from_player_data()` がentryを復元します。通常inventoryを開く `open_with_inventory()` では `restore_held_state_from_player_data(true)` を呼ぶため、前回がtrade/chestだった場合は `normalize_to_normal_inventory_mode()` で通常modeへ戻します。

現状コードから確認できること:

- held item entryはscene跨ぎで消さずにPlayerDataへ退避されます。
- trade/chest modeそのものはscene跨ぎで維持しません。
- trade/chest由来のheld itemは、元のside inventory参照が無効なら無条件にplayer bagへ置かないように拒否されます。

未確認として残ること:

- held item中に手動saveを許可するべきかは、このdocsでは判断しません。
- `PlayerData.held_inventory_*` は `SaveManager.PLAYER_DATA_PROPS` に含まれていないため、現状はsave file snapshot対象ではなく、runtime一時状態として扱われています。

## Trade mode の所有権

trade modeは、会話actionから開かれます。

1. `DialogueManager` が会話actionの結果として `open_trade_ui` を受け取る。
2. `DialogueManager._open_trade_ui()` がGame rootを探し、`GameAndHud.open_trade_ui()` を呼ぶ。
3. `GameAndHud.open_trade_ui()` がdialogを閉じ、`InventoryUI.open_trade_mode()` に player inventory と merchant inventory を渡す。
4. `InventoryUI` は `ui_mode = UIMode.TRADE` とし、player側を `current_inventory`、merchant側を `trade_inventory` に保持する。

所有権の境界:

- player側: `player_unit.inventory`
- merchant/shop側: `merchant_unit.inventory`
- InventoryUIは両方の参照を一時的に持ち、UI操作でentryを移動します。
- merchant nodeやmerchant inventory参照はscene node由来なので、scene跨ぎで持ち越してはいけません。

buy / sell の現状:

- merchant側からplayer側へ置く場合、`notify_trade_transfer_if_needed()` が購入として扱います。
- player側からmerchant側へ置く場合、売却として扱います。
- 価格計算は `TradePriceCalculator` が担当します。
- `InventoryUI` は価格計算結果をentryへ `trade_buy_price` / `trade_sell_price` として付与することがあります。

`TradePriceCalculator` の責務は価格計算です。inventoryの所有権移動やslot更新は `InventoryUI` 側が担当します。

trade中にsceneが切り替わる場合、trade modeは維持しません。held itemはPlayerDataへ退避されますが、`trade_inventory` / `trade_unit` はnull化されます。新しいsceneでは通常inventoryとして開かれます。

merchant/shop inventoryをUnit本体inventoryやdeath drop対象と混同しないでください。shop inventoryは売り物用であり、death dropはUnitが実際に持っているinventory / hotbar / equipmentを対象にします。

## Chest mode の所有権

chest modeは、chest interactionから開かれます。

1. playerのinteractionやmouse actionが `Chest.open_chest(player)` に到達する。
2. `Chest.open_chest()` が自身の `Inventory` と `self` を `InventoryUI.open_chest_mode()` に渡す。
3. `InventoryUI` は `ui_mode = UIMode.CHEST` とし、player側を `current_inventory`、chest側を `trade_inventory` に保持する。

chest modeでもside inventory用の変数名は `trade_inventory` です。ただし `ui_mode == UIMode.CHEST` のときは、`Chest.can_player_take_item()` / `Chest.can_player_put_item()` を使って出し入れ権限を確認します。

所有権の境界:

- player側: `player.inventory`
- chest側: `Chest.inventory`
- chest nodeはmap scene配下のnodeです。
- chest inventoryはchest storageであり、Unit本体inventoryではありません。

chestの保存:

- `Chest.get_save_data()` は `inventory.save_inventory_data()` を含む辞書を返します。
- `Chest.load_from_save_data()` は保存済みinventoryをchestへ読み戻します。
- `ItemWorldManager.save_chests_to_world_state()` はmap内chestの `get_save_data()` を集め、`WorldState.map_chests[map_id]` に保存します。
- `ItemWorldManager.load_chests_from_world_state()` は `WorldState.map_chests[map_id]` からchestを再生成します。
- `SaveManager.WORLD_STATE_PROPS` には `map_chests` が含まれています。

scene跨ぎで `Chest` node参照や `Chest.inventory` 参照そのものを持ち越すと、free済み参照に触る危険があります。保存したいchest状態は `WorldState.map_chests` に寄せ、scene node参照は保存しません。

chest inventoryはworld pickup、death drop、initial inventoryとは別です。chest storageをUnit death drop対象と混同しないでください。

## Scene遷移と参照寿命

map scene切替では、古いscene nodeはfreeされる前提です。

sceneを跨いで持ち越してよいもの:

- item entryとしての held item 一時状態。
- player固有の永続状態としての `PlayerData.inventory_data` / `equipment_data` など。
- map/world状態としての `WorldState.map_chests` / `map_item_pickups` / `unit_states` など。

sceneを跨いで持ち越してはいけないもの:

- `current_inventory`
- `current_unit`
- `trade_inventory`
- `trade_unit`
- `Chest` node参照
- merchant Unit node参照

`InventoryUI.sanitize_runtime_references()` はfree済み参照をnullへ寄せる入口です。`_exit_tree()` でもscene内参照をnull化します。

held itemは例外的に `PlayerData.held_inventory_*` へ一時保持されます。ただし、trade/chest mode自体はscene跨ぎでnormalへ戻します。これは、item消失を避けつつ、無効になったside inventory参照へアクセスしないための境界です。

## Save / Load との関係

`PlayerData` が持つ主なもの:

- playerのstats。
- playerのmap位置。
- playerのinventory/equipment save data。
- held itemのruntime一時状態。

`WorldState` が持つ主なもの:

- map単位のpickup。
- map単位のchest。
- Unit状態。
- quest関連状態。

`SaveManager` がsnapshot対象にするもの:

- `PlayerData` の `PLAYER_DATA_PROPS` に列挙されたもの。
- `WorldState` の `WORLD_STATE_PROPS` に列挙されたもの。

現状では、`PlayerData.held_inventory_*` は `SaveManager.PLAYER_DATA_PROPS` に含まれていません。そのため、held itemはscene跨ぎのruntime一時状態として扱われ、永続save対象ではないと読めます。

chest inventoryは `WorldState.map_chests` に含まれ、`SaveManager.WORLD_STATE_PROPS` 経由でsave対象です。

merchant/shop inventoryについては、Unit本体inventoryとして保存される場合と、shop生成処理由来の一時/再生成状態が混ざりやすい領域です。このdocsでは再設計や仕様判断は行わず、少なくとも「merchant/shop inventoryをdeath drop対象と混同しない」ことだけを現状理解の境界として扱います。

## Death drop / initial inventory / shop inventory との境界

- `initial_inventory_*` はspawn時にUnit本体inventoryへ入る初期所持品です。死亡時drop tableではありません。
- 死亡時dropは、Unitが実際に持っている inventory / hotbar / equipment を落とします。
- shop inventoryはmerchantの売り物用です。Unit本体inventoryと混ぜると、死亡時dropや保存復元の理解を誤ります。
- chest inventoryはchest storageです。Unit death dropとは別です。
- world pickupはmap上の落ちているitemであり、chest storageともUnit inventoryとも別です。

## よくある誤解・注意点

- trade/chestのnode参照をscene跨ぎで持ち越さない。
- side inventory参照をPlayerDataなどへ雑に保存しない。
- scene node参照は保存しない。
- 保存したい状態はPlayerDataやWorldStateへ逃がす。
- held item entryは `instance_data` を壊さないように扱う。
- trade/chest modeはscene跨ぎでnormalへ正規化する。
- 通常inventory中は移動可、trade/chest中は移動不可。
- merchant/shop inventoryとUnit本体inventoryを混同しない。
- chest inventoryとworld pickup/death drop/initial inventoryを混同しない。
- 今回は現状理解docsであり、所有権モデルの改善やリファクタ判断はStep 12以降で扱う。

## 変更・確認時に見る場所

InventoryUI mode / held itemを確認する時:

- `scripts/item/inventory_ui.gd`
- `UIMode`
- `held_entry`
- `held_from_area`
- `persist_held_state_to_player_data()`
- `restore_held_state_from_player_data()`
- `normalize_to_normal_inventory_mode()`
- `restore_held_entry_on_close()`

trade open / closeを確認する時:

- `scripts/managers/dialogue_manager.gd`
- `scripts/hud/game_and_hud.gd`
- `scripts/item/inventory_ui.gd`
- `scripts/trade_price_calculator.gd`

chest open / closeを確認する時:

- `scripts/item/chest/chest.gd`
- `scripts/hud/game_and_hud.gd`
- `scripts/item/inventory_ui.gd`
- `scripts/item/item_world_manager.gd`

scene遷移時のheld item保持を確認する時:

- `scripts/item/inventory_ui.gd`
- `scripts/data/player_data.gd`
- `scripts/hud/game_and_hud.gd`
- [inventory_ui_state_transition.md](inventory_ui_state_transition.md)
- [ui_input_scene_transition_deep_dive.md](ui_input_scene_transition_deep_dive.md)

保存対象を見る時:

- `scripts/save_manager.gd`
- `scripts/data/player_data.gd`
- `scripts/world/world_state.gd`
- [save_worldstate_playerdata_map.md](save_worldstate_playerdata_map.md)

DebugSettingsや確認ログを見る時:

- `scripts/debug/DebugSettings.gd`
- [debug_settings_deep_dive.md](debug_settings_deep_dive.md)

## このdocsで分かること / 分からないこと

このdocsで分かること:

- trade/chest/held itemの所有権の大まかな境界。
- player inventoryとside inventoryの違い。
- scene跨ぎで持ち越してよい状態と危険な参照。
- normal/trade/chest modeの基本的な違い。
- death drop / initial inventory / shop inventory / chest inventoryの境界。

このdocsでは分からないこと:

- 将来どこを分割すべきか。
- side inventory helperを作るべきか。
- trade/chest ownership modelを再設計すべきか。
- held item中saveを許可するべきか。

これらはStep 12以降の別フェーズで扱います。
