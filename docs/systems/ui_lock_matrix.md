# UI Lock Matrix

## このdocsの目的

このdocsは、UI表示中のplayer移動、攻撃、hotbar、scene遷移、UI操作が、現状コードでどのように制御されているかを整理した地図です。

特に、次の違いを見失わないために使います。

- 通常inventoryは開いていても移動できます。
- trade / chestは特殊inventory modeなので移動できません。
- `is_ui_locked()` と `is_inventory_open()` は同じ意味ではありません。
- held item stateとUI modeは別の状態です。
- keyboard target modeはCanvas UIではなく、`PlayerController` 内の操作modeです。

これは将来の改善案、共通化案、分割案ではありません。現状仕様と現状コードの入口だけを記録します。UI lockの再設計や入力制御リファクタの判断はStep 12以降の別フェーズです。

## UI lockに関わる主要スクリプト

### `scripts/controllers/player_controller.gd`

- keyboard / mouseの移動、interaction、攻撃、wait、hotbar選択・使用を受け取ります。
- `_physics_process()` が継続的な入力処理の中心です。
- `is_ui_locked()` でdialogue、special inventory、statusを確認します。
- 通常inventoryは `is_ui_locked()` の対象にしません。
- keyboard target modeはController内の一時状態として管理します。
- action成功後は `_advance_player_turn_after_action()` から時間経過とAI turn解決へ進みます。

### `scripts/hud/game_and_hud.gd`

- `InventoryUI`、`StatusUI`、HUD、map containerの親です。
- 通常inventoryの開閉、trade起動、status開閉を仲介します。
- `is_inventory_open()` はInventoryUI全体の表示状態を返します。
- `is_special_inventory_ui_open()` はtrade / chest等のside modeだけを返します。
- player死亡時はDeathMenuを表示し、SceneTreeをpauseします。

### `scripts/item/inventory_ui.gd`

- `UIMode.NORMAL` / `TRADE` / `CHEST` を持ちます。
- bag / hotbar / equipment / side inventory操作を受け取ります。
- `is_special_inventory_mode_open()` は「visibleかつtrade/chest mode」を判定します。
- held itemのentryとsource情報をUI modeとは別に保持します。
- sceneを跨ぐ必要があるheld stateを `PlayerData.held_inventory_*` に退避します。
- trade/chestのruntime参照はsceneを跨いで保持しません。

### `scripts/dialogue_ui.gd` / `scripts/managers/dialogue_manager.gd`

- `DialogueManager.is_open` が会話の論理状態です。
- `DialogueUI.is_open` / `is_dialog_visible()` が画面側の状態です。
- DialogueUIは上下、決定、キャンセルを受け取ります。
- dialogue actionが `open_trade_ui` を返すと、`DialogueManager` から `GameAndHud.open_trade_ui()` へ進みます。
- trade起動時はdialogueを閉じ、trade終了後は保存したcontextからdialogueを開き直す経路があります。

### `scripts/object/questboard/quest_board_ui.gd` / `scripts/managers/quest_board_manager.gd`

- `QuestBoardManager.is_open` がboardの論理状態です。
- QuestBoardUIは上下、決定、キャンセル、detail内の選択を受け取ります。
- `Unit.is_any_ui_locked()` が `QuestBoardManager.is_board_open()` を確認し、Unit移動を止めます。
- `PlayerController.is_ui_locked()` 自体にはquest board判定は含まれていません。

### `scripts/hud/status_ui.gd`

- `StatusUI.is_open()` はrootのvisibleを返します。
- status / skill / quest等のpage表示と、左右page切替、上下scrollを扱います。
- `GameAndHud.is_status_open()` を経由して `PlayerController.is_ui_locked()` の対象になります。

### `scripts/combat/combat_manager.gd`

- targetへの攻撃可否、通常攻撃、対象指定item使用を実行します。
- UI表示状態そのものは管理しません。
- keyboard target modeで対象が確定した後、`PlayerController` から呼ばれます。

### `scripts/core/unit.gd`

- `try_move()` はplayerの場合に `is_any_ui_locked()` を確認します。
- `is_any_ui_locked()` はdialogueとquest boardを確認します。
- `_physics_process()` もdialogue / quest board中のplayer Unit更新を止めます。
- interactionはinventory、dialogue、quest board等の状態を確認してからtalk / board / pickup / chestへ進みます。

### `scripts/pause_menu.gd` / `scripts/death_menu.gd`

- PauseMenuは開くとSceneTreeをpauseします。
- InventoryUI、DialogueUI、StatusUI、QuestBoardUI、TradeUI、DeathMenuが開いている時は、同じEscでPauseMenuを重ねて開かないようにします。
- DeathMenuはplayer死亡後に表示され、SceneTreeをpauseします。

## 用語整理

### UIが開いている

何らかのCanvas UIがvisible、またはmanagerがopen状態になっている総称です。全UIを横断する単一の `is_any_ui_open()` は確認できません。各UIに別々の判定があります。

### 通常inventoryが開いている

`InventoryUI.visible == true` かつ `ui_mode == UIMode.NORMAL` の状態です。

- `GameAndHud.is_inventory_open()` はtrueです。
- `GameAndHud.is_special_inventory_ui_open()` はfalseです。
- `PlayerController.is_ui_locked()` は通常inventoryだけではtrueになりません。

### special inventory modeが開いている

`InventoryUI.visible == true` かつ `ui_mode` が `TRADE` または `CHEST` の状態です。`InventoryUI.is_special_inventory_mode_open()` と `GameAndHud.is_special_inventory_ui_open()` がこの状態を表します。

### trade mode

player inventoryとmerchant inventoryを並べて操作する `UIMode.TRADE` です。merchant側のinventory / Unit参照を持つため、通常inventoryと異なり移動lock対象です。

### chest mode

player inventoryとChest.inventoryを並べて操作する `UIMode.CHEST` です。コード上のside inventory変数名はtradeと共通の `trade_inventory` / `trade_unit` ですが、modeはCHESTです。

### dialogue中

`DialogueManager.is_dialog_open()` がtrueで、DialogueUIが会話と選択肢を表示している状態です。失敗quest通知には `showing_failed_quest_dialog` による追加lockもあります。

### quest board中

`QuestBoardManager.is_board_open()` がtrueで、QuestBoardUIが表示されている状態です。移動lockは主にUnit側の `is_any_ui_locked()` で確認されます。

### status UI中

`StatusUI.is_open()`、または `GameAndHud.is_status_open()` がtrueの状態です。PlayerControllerのUI lock対象です。

### target item選択中

独立したCanvas UIではなく、`PlayerController.keyboard_target_mode == true` の状態です。選択中hotbar itemがtarget action itemなら、Eで `CombatManager.perform_selected_target_item_use()` へ進みます。

### death / pause / title

- DeathMenu: player死亡後にGameAndHudが表示し、SceneTreeをpauseします。
- PauseMenu: 他のblocking UIが開いていない時に開き、設定によりSceneTreeをpauseします。現状は `pause_game_when_open == true` です。
- TitleScreen: gameplay scene外です。このdocsのplayer入力matrixの対象外です。

### held item中

`InventoryUI.held_entry` が空でない状態です。sourceは `held_from_area` / `held_from_index` / `held_from_slot_name` にあります。

held item中であること自体は、UI lockを意味しません。通常inventoryでheld itemを持ったまま移動・scene移動できます。

### UI lock中

playerのworld入力を止める状態です。ただし、現状は1つの統一lockではありません。

- PlayerController側: dialogue、special inventory、status。
- Unit側: dialogue、quest board。
- Pause / Death: SceneTree pause。
- 各UI側: `_input()` / `_unhandled_input()` でUI操作を消費。

## 判定関数の整理

### `PlayerController.is_ui_locked()`

- 見るもの: dialogue、special inventory、status。
- 主な呼び出し元: `_physics_process()`、mouse map input、hotbar selection/use。
- 移動制御: 使います。trueならmove holdとmouse auto navigationを止めます。
- UI開閉判定: 個別UIを開閉する関数ではありません。
- 通常inventory: lock扱いにしません。
- quest board: この関数には直接含まれません。

### `PlayerController.is_inventory_open()`

- 見るもの: Unitの親をたどり、`is_inventory_open()` を持つrootへ委譲します。
- 主な呼び出し元: hotbar selection/use。
- 移動制御: 直接は使いません。
- UI開閉判定: InventoryUI全体の表示確認に使います。
- 通常inventory: trueです。
- trade/chest: InventoryUIがvisibleなのでtrueです。

### `GameAndHud.is_inventory_open()`

- 見るもの: `inventory_ui.visible`。
- 主な呼び出し元: PlayerController、Unit interaction、status open guard。
- 移動制御: 直接は行いません。
- UI開閉判定: normal / trade / chestを区別せず、InventoryUIが見えているかを返します。
- 通常inventory: trueです。

### `GameAndHud.is_special_inventory_ui_open()`

- 見るもの: `InventoryUI.is_special_inventory_mode_open()`。
- 主な呼び出し元: PlayerControllerの祖先探索。
- 移動制御: `PlayerController.is_ui_locked()` 経由で使います。
- UI開閉判定: trade / chestだけを区別します。
- 通常inventory: falseです。

### `InventoryUI.visible`

InventoryUI全体が表示中かを表します。コード上に独立した `InventoryUI.is_open` propertyはなく、`visible` がopen判定です。

### `InventoryUI.is_special_inventory_mode_open()`

- 見るもの: `visible and is_side_mode()`。
- `is_side_mode()` は `ui_mode == TRADE or CHEST` です。
- 移動制御: GameAndHudとPlayerControllerを経由して使います。
- 通常inventory: falseです。

### `InventoryUI.ui_mode`

normal / trade / chestを区別するenum値です。held itemのsourceではありません。

### `DialogueManager.is_dialog_open()`

- 見るもの: managerの `is_open`。
- 主な呼び出し元: Unit、GameAndHud、map rootの委譲関数。
- 移動制御: Unit側のlockで直接使います。PlayerControllerは祖先にある `is_dialog_open()` へ委譲します。
- UI開閉判定: inventory/statusをdialogueへ重ねて開かないためにも使います。
- 通常inventory: 無関係です。

### `QuestBoardManager.is_board_open()`

- 見るもの: managerの `is_open`。
- 主な呼び出し元: `Unit.is_any_ui_locked()`。
- 移動制御: Unitの `_physics_process()` / `try_move()` で使います。
- UI開閉判定: QuestBoardUIのopen / closeと同期します。
- PlayerController.is_ui_locked: 直接は含まれません。

### `StatusUI.is_open()` / `GameAndHud.is_status_open()`

- 見るもの: StatusUI rootのvisible。
- 主な呼び出し元: GameAndHud、PlayerController。
- 移動制御: `PlayerController.is_ui_locked()` で使います。
- UI開閉判定: inventory/dialogue/tradeとの重複open防止にも使います。
- 通常inventory: status側を開く時にinventory openなら拒否します。

### target item選択中の判定

- `PlayerController.keyboard_target_mode`: target cursor mode全体。
- `Unit.get_selected_target_item_data()`: 選択hotbar entryがtarget itemかを返します。
- `PlayerController.is_keyboard_using_target_item_action()`: 現在のtarget modeがitem target actionかを判定します。
- `CombatManager.can_use_selected_target_item()`: 対象、射程、item適用可否を確認します。
- UI lockとの関係: target mode中にUI lockまたはtransitionが発生するとmodeをcancelします。

### PauseMenuのblocking UI判定

`PauseMenu._has_blocking_ui_open()` はnode名でInventoryUI、DialogueUI、StatusUI、QuestBoardUI、TradeUI、DeathMenuを確認します。

これはplayer移動用の `PlayerController.is_ui_locked()` とは別用途です。通常inventoryもPauseMenuを重ねて開かない対象です。

## UI状態別の入力可否

以下は現状コードから確認できる範囲です。「できる」はその状態専用の明示的なblockがないことを含みます。入力actionがUI側とworld側で重なる場合、実際にはUIが先に入力を消費する場合があります。

### UIなし

- 移動: できます。
- 通常攻撃: keyboard target modeまたはmouse actionから実行できます。
- hotbar使用: HUD選択と `inventory_use` が使えます。
- inventory: 開けます。
- scene遷移: tile event、stairs、interaction等の通常経路を使えます。
- turn: 成功した移動、攻撃、wait、対象item使用等から時間経過とAI turn解決へ進みます。

### 通常inventory

- 移動: できます。通常inventoryは `is_ui_locked()` の対象外です。
- bag / hotbar / equipment操作: InventoryUI内でできます。
- HUD hotbar選択・使用: PlayerController側は `is_inventory_open()` により直接操作を止め、InventoryUI側へ任せます。
- 通常攻撃: normal inventoryを理由にworld action全体を止めるlockはありません。ただしEnter等はInventoryUIの操作actionと重なるため、UI入力が優先されます。通常inventory中の戦闘操作を独立仕様として保証する専用判定は確認できません。
- scene遷移: 移動可能なので発生し得ます。
- held item: 持ったまま移動・scene移動できます。held stateとUI modeは別です。
- turn: inventory内のカーソル移動や持ち替え自体はPlayerControllerのturn進行入口を呼びません。通常inventoryを開いたままworld移動が成功すれば、通常の移動と同じくturnが進みます。

### trade mode

- 移動: できません。special inventory判定が `PlayerController.is_ui_locked()` に入ります。
- inventory操作: player inventoryとmerchant inventoryを操作できます。
- 通常攻撃: UI lock後のworld action branchへ進みません。
- hotbar使用: PlayerController側はinventory open / UI lockで止まり、InventoryUI内操作へ任せます。
- scene遷移: 通常のplayer移動経路からは発生しません。
- 万一のscene遷移: held item entry/sourceは保持対象ですが、merchant node / side inventory参照は保持しません。新しいInventoryUIではnormalへ正規化します。

### chest mode

- 移動: できません。tradeと同じspecial inventory判定です。
- inventory操作: player inventoryとChest.inventoryを操作できます。
- 通常攻撃: UI lock後のworld action branchへ進みません。
- hotbar使用: PlayerController側はinventory open / UI lockで止まり、InventoryUI内操作へ任せます。
- scene遷移: 通常のplayer移動経路からは発生しません。
- 万一のscene遷移: held item entry/sourceは保持対象ですが、Chest node / side inventory参照は保持しません。新しいInventoryUIではnormalへ正規化します。

### dialogue中

- 移動: できません。Unit側のdialogue lockが移動更新と `try_move()` を止めます。
- 会話選択肢: DialogueUIが上下、決定、キャンセルを受け取ります。
- inventory: PlayerControllerとGameAndHudのopen guardにより、新規openしません。
- status: GameAndHudのopen guardにより、新規openしません。
- tradeへの移行: dialogue action結果 `open_trade_ui` から `DialogueManager._open_trade_ui()`、`GameAndHud.open_trade_ui()`、`InventoryUI.open_trade_mode()` へ進みます。
- turn: 会話選択そのものからPlayerControllerのturn進行入口を呼ぶ処理は確認できません。

### quest board中

- 移動: できません。`Unit.is_any_ui_locked()` がQuestBoardManagerを見て、Unit更新と `try_move()` を止めます。
- board操作: QuestBoardUIが上下、決定、キャンセルを受け取ります。
- inventory / statusとの関係: boardを開くinteractionはinventory open中に拒否されます。一方、board表示後のGameAndHud inventory/status toggle側にはQuestBoardManagerを直接見るguardは確認できません。重複表示可否を統一する単一判定も確認できません。
- 通常攻撃 / hotbar: `PlayerController.is_ui_locked()` にquest boardは直接含まれません。QuestBoardUIが扱う方向・決定入力は消費しますが、全world actionを同じ判定で止める構造ではありません。このdocsでは移動不可までを確認済み仕様とし、その他の入力競合は個別action依存とします。
- turn: board内のaccept / complete操作からPlayerControllerのturn進行入口を呼ぶ処理は確認できません。

### status UI中

- 移動: できません。`PlayerController.is_ui_locked()` の対象です。
- status / skill / quest表示: StatusUI内でpage切替・scroll・表示を操作できます。
- inventory: status open中はGameAndHudがinventoryの新規openを拒否します。
- 通常攻撃 / hotbar: UI lock後のworld action branchへ進みません。
- turn: status内操作では進みません。

### target item選択中

- 移動: できます。target modeは通常のUI lockではなく、専用入力以外を通常移動へ流します。
- target選択: 矢印で候補変更、Eで対象item使用、attack / acceptで攻撃を確定します。
- wait: wait actionを実行し、turnを進めた後もmodeを更新して継続します。
- cancel: attack modeキー再押しまたはEscでmodeを終了します。
- inventory / status入力: 最初の入力ではtarget modeをcancelして処理を消費します。開閉処理は同じframeのそのbranchでは続行しません。
- CombatManager: target確定後に攻撃または対象item使用のcan/perform APIを呼びます。
- turn: target候補を移動するだけでは進みません。攻撃、item使用、wait、world移動が成功した時に進みます。

### PauseMenu

- 移動・通常world入力: SceneTree pauseにより止まります。
- open条件: 他のblocking UIが開いているEscでは重ねて開きません。
- 通常inventoryとの関係: InventoryUIはnormalを含めてblocking UI扱いです。これは移動lockとは別のPauseMenu重複防止判定です。

### DeathMenu

- 移動・通常world入力: SceneTree pauseにより止まります。
- 操作: continue / new game / title / quitを選びます。
- `PlayerController.is_ui_locked()` の一部ではなく、死亡処理とSceneTree pauseで止まります。

### TitleScreen

- gameplay Unit / PlayerControllerがないため、このmatrixのworld入力対象外です。

## 通常inventoryだけ移動可である理由と注意

現行仕様では、normal inventoryはplayer自身のbag / hotbar / equipmentを操作する画面であり、開いたまま移動とscene遷移ができます。

trade / chestは、scene内のmerchant / chestとside inventory参照を持つ特殊modeです。対象から離れたまま操作を続けないよう、special inventoryだけを移動lock対象にしています。

このため、次の読み替えはできません。

- `is_inventory_open() == is_ui_locked()`
- InventoryUI visibleなら必ず移動不可
- held item中なら必ず移動不可

`is_inventory_open()` をそのまま移動禁止判定に使うと、通常inventory中移動可の現行仕様が変わります。special inventory modeだけを止める場面では、`is_special_inventory_ui_open()` / `is_special_inventory_mode_open()` の意味を確認します。

このStepでは、この境界を変更していません。

## Trade / Chest ownershipとの接続

trade / chest中はspecial inventory modeなので移動不可です。

sceneを跨いで保持するもの:

- held item entry
- held source area
- held source index
- held equipment slot名
- 直前のUI mode名

sceneを跨いで保持しないもの:

- merchant Unit node
- Chest node
- `trade_inventory`
- `trade_unit`
- side inventoryのscene node参照

新しいInventoryUIで通常inventoryを開く時、前回がtrade / chestならmodeをnormalへ正規化し、held itemだけを復元します。held sourceが無効なtrade/chest由来なら、不正配置せずheld stateを保持します。

所有権と参照寿命の詳細は [trade_chest_ownership_deep_dive.md](trade_chest_ownership_deep_dive.md) を参照してください。

## Scene transitionとの関係

### 通常inventory

- 移動可能なので、通常操作からmap / scene遷移が起こり得ます。
- held itemはInventoryUI内に保持され、UI tree自体が終了する場合は `_exit_tree()` からPlayerDataへ退避されます。
- 新しいplayer inventory参照が必要な場合、InventoryUIは無効参照をnull化し、scene treeからplayer inventoryを再取得します。

### Trade / Chest

- 通常の移動経路はUI lockで止まるため、player操作によるscene遷移は発生しません。
- scene遷移が別経路で発生しても、special modeのnode参照は持ち越しません。
- InventoryUI再構築後に通常inventoryを開く経路ではnormalへ正規化します。

### Held item

- held item stateとUI modeは別です。
- held entry/source情報はPlayerDataへ一時退避できます。
- scene nodeそのものは保存しません。
- `PlayerData.held_inventory_*` はruntimeのscene跨ぎ一時状態で、現状のsave snapshot対象ではありません。

### Map / GameAndHud

- `GameAndHud.load_map()` はcurrent map nodeをfreeし、新しいmapをinstantiateします。
- InventoryUIはGameAndHud側のUI nodeなので、map nodeとは寿命が異なります。
- map側のplayer / chest / merchant参照はfreeされ得るため、InventoryUIはruntime参照をsanitize / rebindします。

## Input / turn progressionとの関係

`PlayerController._physics_process()` のUI lockに関係する順序は概ね次の通りです。

1. keyboard target modeを更新し、専用入力を処理します。
2. status toggleを処理します。
3. status open中なら停止します。
4. inventory toggleを処理します。
5. selected hotbar item useを試します。
6. `is_ui_locked()` を確認し、lock中なら移動とmouse auto navigationを止めます。
7. turn解決中 / scene遷移中なら停止します。
8. interaction、attack mode、attack、waitを処理します。
9. mouse auto actionまたはkeyboard移動へ進みます。

補足:

- hotbar selectionは `_unhandled_input()` 入口ですが、inventory open、UI lock、transition中は拒否します。
- InventoryUI open中のhotbarはInventoryUI側の操作へ任せます。
- mouse map inputも `is_ui_locked()` を確認します。
- Unit側にもdialogue / quest board用のlockがあります。

turn進行:

- 成功したplayer移動は `_advance_player_turn_after_action()` を呼びます。
- keyboard target modeで成功した攻撃・対象item使用・waitも同じturn進行へ進みます。
- `TimeManager.advance_time()` 後に `TimeManager.resolve_ai_turns()` を呼びます。
- UI内のcursor移動、held item移動、dialogue選択、status page操作、quest board操作だけでは、このPlayerControllerのturn進行入口は呼ばれません。
- 通常inventory中でもworld移動が成功すればturnは進みます。
- `Inventory.use_selected_hotbar_item()` の内部効果とturn消費の全種類については、このdocsでは個別監査していません。PlayerControllerの `use_selected_hotbar_item_from_controller()` 自体には `_advance_player_turn_after_action()` の直接呼び出しはありません。

## よくある誤解・注意点

- `is_ui_locked()` と `is_inventory_open()` は同じ意味ではありません。
- 通常inventory中は移動できます。
- trade / chest中は移動できません。
- special inventory modeとnormal inventoryを混同しません。
- held item中であることとUI lock中であることを混同しません。
- trade / chest modeはscene跨ぎでnormalへ正規化します。
- trade / chest node参照やside inventory参照をscene跨ぎで持ち越しません。
- quest boardの移動lockはPlayerControllerだけでなくUnit側を見ます。
- target item選択はInventoryUI modeではなくPlayerControllerのkeyboard target modeです。
- PauseMenuのblocking UI判定はplayer移動用UI lockとは別です。
- UI lock仕様変更はこのStepでは行っていません。
- 今回は現状理解docsです。UI lock整理や入力制御リファクタ判断はStep 12以降です。

## 変更・確認時に見る場所

移動可否:

- `scripts/controllers/player_controller.gd`
  - `_physics_process()`
  - `is_ui_locked()`
  - `handle_move_input()`
- `scripts/core/unit.gd`
  - `_physics_process()`
  - `try_move()`
  - `is_any_ui_locked()`

inventory open:

- `scripts/hud/game_and_hud.gd`
  - `toggle_inventory_ui()`
  - `is_inventory_open()`
- `scripts/item/inventory_ui.gd`
  - `visible`
  - `ui_mode`

trade / chest lock:

- `scripts/hud/game_and_hud.gd`
  - `is_special_inventory_ui_open()`
- `scripts/item/inventory_ui.gd`
  - `is_trade_mode_open()`
  - `is_chest_mode_open()`
  - `is_special_inventory_mode_open()`

dialogue lock:

- `scripts/managers/dialogue_manager.gd`
  - `is_dialog_open()`
- `scripts/dialogue_ui.gd`
  - `is_dialog_visible()`
- `scripts/core/unit.gd`
  - `is_any_ui_locked()`

quest board lock:

- `scripts/managers/quest_board_manager.gd`
  - `is_board_open()`
- `scripts/object/questboard/quest_board_ui.gd`
  - `_input()`
- `scripts/core/unit.gd`
  - `is_any_ui_locked()`

target item:

- `scripts/controllers/player_controller.gd`
  - `keyboard_target_mode`
  - `handle_keyboard_target_mode_input()`
  - `confirm_keyboard_target_item_use()`
- `scripts/combat/combat_manager.gd`
  - `can_use_selected_target_item()`
  - `perform_selected_target_item_use()`

scene遷移時のUI正規化:

- `scripts/item/inventory_ui.gd`
  - `_exit_tree()`
  - `persist_held_state_to_player_data()`
  - `restore_held_state_from_player_data()`
  - `normalize_to_normal_inventory_mode()`
  - `sanitize_runtime_references()`
- `scripts/hud/game_and_hud.gd`
  - `load_map()`

DebugSettings / 確認ログ:

- `scripts/debug/DebugSettings.gd`
- [debug_settings_deep_dive.md](debug_settings_deep_dive.md)

## 関連docs

- [inventory_ui_state_transition.md](inventory_ui_state_transition.md)
- [trade_chest_ownership_deep_dive.md](trade_chest_ownership_deep_dive.md)
- [ui_input_scene_transition_deep_dive.md](ui_input_scene_transition_deep_dive.md)
- [inventory_trade_chest_system_deep_dive.md](inventory_trade_chest_system_deep_dive.md)
- [save_worldstate_playerdata_map.md](save_worldstate_playerdata_map.md)

## このdocsで分かること / 分からないこと

### 分かること

- UI状態ごとの移動可否。
- normal inventoryとspecial inventoryの違い。
- `is_ui_locked()` と `is_inventory_open()` の違い。
- trade / chest中に移動不可となる理由。
- scene跨ぎで正規化されるUI状態。
- held item stateとUI modeの違い。
- 入力制御を確認するコード入口。
- actionとturn進行が接続する主な場所。

### 分からないこと

- 将来どこを共通化するべきか。
- UI lock判定を再設計するべきか。
- InputControllerを分割するべきか。
- UIごとのlock policyをデータ化するべきか。
- held item中のsaveを許可するべきか。
- UI間の重複open guardを将来統一するべきか。

これらはStep 12以降の別フェーズです。
