extends "res://Tests/test_v003_ui.gd"
var window

func settle() -> void:
	for i in 8: await process_frame

func click_dialog(control: Control) -> void:
	var scroll: ScrollContainer=window.queue.get_parent().get_parent()
	scroll.ensure_control_visible(control)
	await settle()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position=Vector2(window.position)+control.get_global_rect().get_center()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		root.push_input(event,true)
		await process_frame

func run() -> void:
	root.get_node("AppSettings").apply_video(Vector2i(1280,720),false)
	root.get_node("Localization").choose("pt")
	game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused=true
	game.village_level=3
	for worker in game.workers: worker.assign_to("idle",game.base)
	var depot=game.add_building("warehouse",Vector2i(43,28),true)
	depot.stored.wood=40
	depot.stored.stone=40
	depot.stored.gold_bar=20
	var port=game.add_building("trading_port",Vector2i(44,37),true)
	game.rebuild_navigation()
	game.workers[1].assign_to("carrier",game.base)
	game.merchant.tick(60)
	for i in 1000:
		if game.merchant.state=="docked": break
		game.merchant.tick(0.5)
	game.select_entity(port)
	game.hud.refresh()
	await settle()
	await click(game.hud.trade_button.get_global_rect().get_center())
	window=game.hud.trade_window
	await settle()
	check(window.visible,"Port trade action opens the actual commercial panel")
	check(window.quantity.step==10 and window.quantity.value==10,"Quantity control displays actual units in tens")
	check(not window.confirm_button.disabled,"Valid purchase can be confirmed")
	await capture("v0061_trade_buy_pt")
	window.tabs.current_tab=1
	window.quantity.value=20
	await settle()
	check(window.side=="sell" and "20" in window.price_label.text and "2" in window.price_label.text,"Sell tab shows twenty wood for two bars")
	check("Depósito" in window.locations.text,"Quote identifies the real origin and destination warehouse")
	await click_dialog(window.confirm_button)
	check(game.commerce.orders.size()==1 and depot.stored.wood==40,"Click reserves one order without removing physical stock")
	window.submit()
	check(game.commerce.orders.size()==1 and window.confirm_button.disabled,"Repeated click cannot create duplicate orders")
	await settle()
	check(window.rows.has(1) and "0/20" in window.rows[1].label.text,"Queue displays the unfulfilled delivery quantity")
	await capture("v0061_trade_queue_pt")
	await click_dialog(window.rows[1].cancel)
	check(game.commerce.orders[0].phase=="cancelled" and game.merchant.budget==30,"Queue cancellation releases exact reservations")
	root.get_node("Localization").choose("en")
	window.new_form()
	await settle()
	check(window.confirm_button.text=="Confirm trade" and "Sell 20 units" in window.price_label.text,"Commercial controls and quantity are translated")
	await capture("v0061_trade_en")
	game.workers[1].assign_to("idle",game.base)
	window.refresh()
	check(window.confirm_button.disabled and "carrier" in window.reason_label.text,"Missing carrier blocks confirmation with a specific explanation")
	for dimensions in [Vector2i(960,540),Vector2i(640,360),Vector2i(1920,1080)]:
		root.size=dimensions
		await settle()
		check(root.get_visible_rect().encloses(Rect2(window.position,window.size)),"Commercial window fits viewport "+str(dimensions))
	window.hide()
	print("Trade UI: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
