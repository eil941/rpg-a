# Inventory / Trade / Chest System Deep Dive

Inventory、Hotbar、Equipment、Trade、Chest は `InventoryUI` にかなり集約されています。ここでは「どのarea/sourceが何を意味し、状態がどこにあるか」を横断的に整理します。

`InventoryUI` の `UIMode` と held item の状態遷移だけを追う場合は、先に [inventory_ui_state_transition.md](inventory_ui_state_transition.md) を読むと見通しがよくなります。

## 関連スクリプト

| Script | 役割 |
| --- | --- |
| `scripts/item/inventory.gd` | bag と hotbar のentry配列、stack、add/remove、save/load、item use。 |
| `scripts/item/inventory_ui.gd` | 通常inventory、trade、chest、equipment、held item、tooltip、transfer操作。 |
| `scripts/core/unit.gd` | `inventory` nodeと `equipped_items` を持つ。装備save/load、死亡drop元にもなる。 |
| `scripts/data/player_data.gd` | player inventory/equipment の永続状態、scene跨ぎheld item一時状態。 |
| `scripts/hud/game_and_hud.gd` | InventoryUIを開閉し、trade UIを開く入口を持つ。 |
| `scripts/item/chest/chest.gd` | chest inventory と chest mode 起動、put/take権限。 |
| `scripts/managers/dialogue_manager.gd` | dialogue action から trade UI を起動。 |
| `scripts/trade_price_calculator.gd` | 売買価格計算。 |
| `scripts/controllers/player_controller.gd` | UI lock判定。trade/chest中は移動不可、通常inventory中は移動可。 |

## UIMode

`InventoryUI` には以下のmodeがあります。

| UIMode | 意味 | 移動可否 | scene跨ぎ |
| --- | --- | --- | --- |
| `UIMode.NORMAL` | 通常inventory。bag/hotbar/equipmentを見る | 移動可 | held itemは `PlayerData` で保持可能 |
| `UIMode.TRADE` | player inventory + merchant inventory | 移動不可 | modeは維持しない。新sceneではnormalへ戻す |
| `UIMode.CHEST` | player inventory + chest inventory | 移動不可 | modeは維持しない。新sceneではnormalへ戻す |

## area/source 一覧

| area/source | 意味 | 主な操作 | 状態の置き場所 | scene跨ぎ | 注意 |
| --- | --- | --- | --- | --- | --- |
| `inventory` | player/Unitのbag slot | 移動、stack merge、item use、drop | `Inventory.items` | playerは `PlayerData.inventory_data` に保存 | stack amountとentry辞書を壊さない。 |
| `hotbar` | player/Unitのhotbar slot | hotbar使用、bagとの入れ替え、死亡drop対象 | `Inventory.hotbar_items` | playerは inventory save data に含まれる | death dropではinventory扱い。 |
| `equipment` | Unitの装備slot | 装備/解除、stat反映、装備効果 | `Unit.equipped_items` | playerは `PlayerData.equipment_data` に保存 | 装備entryの `instance_data` を守る。 |
| `trade` | trade/chestのside inventory側 | 売買、交換、side panel出し入れ | `InventoryUI.trade_inventory` | 持ち越さない | scene跨ぎ後のfree済み参照に触らない。 |
| `chest` | 実装上はside modeで扱うchest inventory | chest出し入れ、権限確認 | `Chest.inventory` と `InventoryUI.trade_inventory` | 持ち越さない | `UIMode.CHEST` として通常tradeとは権限が違う。 |

## 通常inventory mode

- `GameAndHud.toggle_inventory_ui()` から `InventoryUI.toggle_with_inventory(player.inventory)` に進みます。
- 通常inventory中でも `PlayerController.is_ui_locked()` は特殊inventory扱いにしないため、移動可能です。
- held itemを持ったままscene移動しても、`PlayerData.held_inventory_*` に保存され、新しいInventoryUIで復元されます。
- 操作対象は基本的に player の `Inventory` と `Unit.equipped_items` です。

## Hotbar

- `Inventory.hotbar_items` は bag とは別配列です。
- PlayerControllerのhotbar inputから使用されます。
- 死亡時dropでは bag と同じ「carried inventory」として扱われます。
- hotbarにあるentryとbagにあるentryは別entryです。同じ `item_id` でも両方持っていれば両方落ちます。

## Equipment

- `Unit.equipped_items` がslot別entryを保持します。
- `InventoryUI.drop_held_entry_to_equipment()` などで装備/交換します。
- 装備中パッシブ効果は `Unit.get_equipped_item_effects()` から `apply_modifier` を拾い、stat getter側で合計されます。
- 装備entryには enchant などの `instance_data` が入ることがあります。移動・drop・saveで深く複製して維持する必要があります。

## Trade mode

- `DialogueManager` の会話actionから `GameAndHud.open_trade_ui()` に入り、`InventoryUI.open_trade_mode()` を呼びます。
- player inventory が左、merchant inventory がside panelです。
- 価格は `TradePriceCalculator` が担当します。
- `UIMode.TRADE` 中は `PlayerController.is_ui_locked()` により移動不可です。
- scene遷移が万一起きた場合、trade modeや `trade_inventory` / `trade_unit` は持ち越しません。

## Chest mode

- `Unit.try_open_chest_on_current_tile()` やmouse interactionから `Chest.open_chest(player)` に入り、`InventoryUI.open_chest_mode()` を呼びます。
- 実装上は side inventory として `trade_inventory` 相当の変数を使いますが、`ui_mode == UIMode.CHEST` で権限や表示を分けます。
- `Chest.can_player_take_item()` / `can_player_put_item()` が出し入れ時の権限確認に関わります。
- `UIMode.CHEST` 中も移動不可です。
- scene遷移時にchest nodeはfreeされる可能性があるため、chest参照は持ち越しません。

## Held item state

`InventoryUI` が持つ主なheld state:

- `held_entry`
- `held_from_area`
- `held_from_index`
- `held_from_slot_name`

`PlayerData` が持つscene跨ぎ一時状態:

- `held_inventory_entry`
- `held_inventory_source_area`
- `held_inventory_source_index`
- `held_inventory_source_slot_name`
- `held_inventory_previous_ui_mode`

`InventoryUI._exit_tree()` は held item があれば `PlayerData` に保存し、`current_inventory`、`current_unit`、`trade_inventory`、`trade_unit` などのscene内参照をnull化します。新しいUIでは `restore_held_state_from_player_data()` でentryを戻します。

## scene跨ぎ時の扱い

| 前回状態 | 新sceneでのUI mode | held item | 注意 |
| --- | --- | --- | --- |
| 通常inventory | `UIMode.NORMAL` | 復元する | 通常inventory/hotbar/equipmentへ操作可能。 |
| trade | `UIMode.NORMAL` | 消さずに復元 | merchant参照は持ち越さない。不正配置を拒否する必要がある。 |
| chest | `UIMode.NORMAL` | 消さずに復元 | chest参照は持ち越さない。不正配置を拒否する必要がある。 |

重要なのは、held item state と UI mode を分離することです。held itemは保持してよいですが、trade/chest modeそのものはsceneを跨がせません。

## trade/chest由来 held item の不正配置拒否

- `held_from_area == "trade"` のまま新sceneへ来る可能性があります。
- その場合、元の `trade_inventory` がfree済みなら戻し先がありません。
- 所有権がplayerへ移っていると判断できないentryは、勝手にplayer bagへ置くと不正取得になる可能性があります。
- そのため、配置やclose/cancel時は「元が有効なら戻す」「player所有ならbagへ戻す」「所有権不明ならheld stateを消さず拒否」が安全です。

## entry / instance_data を守る理由

- 通常stack itemは `item_id` と `amount` が重要です。
- 装備品は `instance_data` にenchantや個体情報を持つ場合があります。
- `instance_data` を落とすと、装備効果、enchant、価格、death drop後の復元が壊れます。
- `duplicate(true)` などで深く複製する設計が多いため、浅い代入や手作り辞書への置き換えには注意が必要です。

## Inventory系変更時の確認項目

- bag内移動、stack merge、分割移動
- hotbarとの入れ替え、hotbar使用
- equipment装備/解除、slot不一致拒否
- trade売買、価格、merchant側在庫
- chest出し入れ、put/take権限
- held itemを持ったままscene移動
- trade/chest中にscene遷移してもfree済み参照に触らないこと
- item消失がないこと
- enchanted equipment / `instance_data` が保持されること
- 通常inventory中は移動可能、trade/chest中は移動不可
- death dropでbag/hotbar/equipmentが意図通り扱われること
