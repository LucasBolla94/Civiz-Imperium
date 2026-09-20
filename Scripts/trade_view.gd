extends AcceptDialog
const THEME=preload("res://Scripts/menu_theme.gd")
var game
var side := "buy"
var resource := "wood"
var form_serial := 0
var submitted := false
var form_key := ""
var last_notice := ""
var tabs: TabBar
var status_label: Label
var budget_label: Label
var quantity: SpinBox
var price_label: Label
var locations: Label
var reason_label: Label
var confirm_button: Button
var next_button: Button
var transfer_button: Button
var resource_buttons := {}
var queue: VBoxContainer
var rows := {}

func text_label(parent: Node, text := "", size := 15) -> Label:
	var result := Label.new()
	result.text=text
	result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size",size)
	result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	return result

func action(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text=text
	result.custom_minimum_size.y=34
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func _ready() -> void:
	title="Porto comercial"
	theme=THEME.create()
	exclusive=true
	get_ok_button().text="Fechar"
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	scroll.custom_minimum_size=Vector2(320,180)
	add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	scroll.add_child(body)
	status_label=text_label(body,"",18)
	budget_label=text_label(body)
	tabs=TabBar.new()
	tabs.add_tab("Comprar")
	tabs.add_tab("Vender")
	tabs.tab_changed.connect(func(index): side="buy" if index==0 else "sell"; new_form())
	body.add_child(tabs)
	var materials := HFlowContainer.new()
	body.add_child(materials)
	for key in ["wood","stone","produce"]:
		var button := action(materials,"",func(): resource=key; new_form())
		button.toggle_mode=true
		button.icon=game.DATA.resource_texture(key)
		button.expand_icon=false
		button.add_theme_constant_override("icon_max_width",24)
		button.custom_minimum_size.x=136
		resource_buttons[key]=button
	var quantities := HBoxContainer.new()
	body.add_child(quantities)
	text_label(quantities,"Quantidade de unidades")
	quantity=SpinBox.new()
	quantity.min_value=10
	quantity.max_value=60
	quantity.step=10
	quantity.value=10
	quantity.custom_minimum_size.x=120
	quantities.add_child(quantity)
	quantity.value_changed.connect(func(_value): new_form())
	price_label=text_label(body,"",18)
	locations=text_label(body)
	reason_label=text_label(body)
	var controls := HFlowContainer.new()
	body.add_child(controls)
	confirm_button=action(controls,"Confirmar negócio",submit)
	confirm_button.theme_type_variation="PrimaryButton"
	next_button=action(controls,"Preparar outro pedido",new_form)
	transfer_button=action(controls,"Levar material ao galpão",transfer)
	action(controls,"Abrir Habitantes",func():
		hide()
		if not game.hud.workforce_panel.visible: game.hud.toggle_workforce()
	)
	text_label(body,"Pedidos e entregas",18)
	queue=VBoxContainer.new()
	queue.add_theme_constant_override("separation",8)
	body.add_child(queue)
	hide()

func open() -> void:
	new_form()
	var viewport: Vector2=game.get_viewport_rect().size
	popup_centered(Vector2i(minf(740,viewport.x-40),minf(600,viewport.y-48)))
	refresh()

func new_form() -> void:
	form_serial+=1
	form_key="port-ui:"+Crypto.new().generate_random_bytes(16).hex_encode()
	submitted=false
	last_notice=""
	if is_instance_valid(confirm_button): refresh()

func submit() -> void:
	if submitted: return
	var id: int=game.commerce.confirm(side,resource,int(quantity.value),form_key)
	if id>0:
		submitted=true
		confirm_button.disabled=true
		last_notice="Pedido %d confirmado. O pagamento depende da entrega completa."%id
	else: last_notice=game.commerce.error
	refresh()

func transfer() -> void:
	var amount := int(quantity.value)
	var input_resource := resource
	if side=="buy":
		input_resource="gold_bar"
		amount=game.DATA.ECONOMY.BUY_PRICES[resource]*(amount/10)
	game.commerce.request_transfer(input_resource,amount)
	last_notice="Transporte ao galpão solicitado. Confirme o negócio depois que o material chegar."
	refresh()

func names(allocations: Array) -> String:
	var labels: PackedStringArray=[]
	for allocation in allocations:
		var target=game.commerce.building(allocation.building)
		if is_instance_valid(target) and allocation.remaining>0: labels.append("%s: %d"%[target.display_name(),allocation.remaining])
	return " · ".join(labels)

func refresh() -> void:
	if not is_instance_valid(status_label): return
	var merchant=game.merchant
	status_label.text=merchant.description()
	budget_label.text="Orçamento do comerciante: %d barras · Recebimento: %d/200 unidades"%[merchant.budget,merchant.port().used() if is_instance_valid(merchant.port()) else 0]
	var l10n=game.get_node("/root/Localization")
	tabs.set_tab_title(0,l10n.text("Comprar"))
	tabs.set_tab_title(1,l10n.text("Vender"))
	for key in resource_buttons:
		resource_buttons[key].text="%s\nVende %d · Compra %d"%[{"wood":"Madeira","stone":"Pedra","produce":"Hortifruti"}[key],merchant.offers.get(key,0),merchant.buying_caps.get(key,0)]
		resource_buttons[key].set_pressed_no_signal(resource==key)
	var units := int(quantity.value)
	var price: int=(game.DATA.ECONOMY.BUY_PRICES if side=="buy" else game.DATA.ECONOMY.SELL_PRICES)[resource]*(units/10)
	price_label.text=("Comprar %d unidades por %d barras" if side=="buy" else "Vender %d unidades por %d barras")%[units,price]
	var plan: Dictionary=game.commerce.quote(side,resource,units)
	locations.text="Origem: %s\nDestino: %s"%[names(plan.origins),names(plan.destinations)]
	var explanation: String=plan.reason
	if explanation.is_empty(): explanation="Transportadores ocupados ou descansando; o pedido aguardará na fila." if plan.get("waiting",false) else "A carga será levada ao barco em viagens; nada é trocado ao clicar."
	reason_label.text=last_notice if not last_notice.is_empty() else explanation
	confirm_button.disabled=submitted or not plan.reason.is_empty()
	next_button.visible=submitted
	transfer_button.visible=plan.reason=="Leve este material ao galpão para vender"
	var shown := {}
	for value in game.commerce.orders:
		if value.visit!=merchant.visit_id and value.phase!="pending" and value.to_store==0: continue
		shown[value.id]=true
		if not rows.has(value.id):
			var panel := PanelContainer.new()
			queue.add_child(panel)
			var column := VBoxContainer.new()
			panel.add_child(column)
			var label := text_label(column)
			var cancel_button := action(column,"Cancelar negócio",func(): game.commerce.cancel(value.id); refresh())
			rows[value.id]={"panel":panel,"label":label,"cancel":cancel_button}
		var row: Dictionary=rows[value.id]
		row.cancel.visible=value.phase=="pending"
		var progress: String="Entregue ao barco: %d/%d"%[value.custody,value.input_amount] if value.phase=="pending" else ("Carga recebida · Restam %d unidades até o galpão"%value.to_store if value.phase=="settled" else "Cancelado · Restam %d unidades para devolver"%value.to_store)
		var issue: String=value.reason
		if value.phase=="pending" and game.commerce.first_pending().get("id")!=value.id: issue="Na fila, aguardando o negócio anterior."
		row.label.text="#%d · %s · %d %s · %d barras\n%s"%[value.id,"Compra" if value.side=="buy" else "Venda",value.quantity,game.DATA.RESOURCES[value.resource].name,value.payment,progress]
		if not issue.is_empty(): row.label.text+="\n"+issue
		var origins := names(value.origins)
		var destinations := names(value.destinations)
		if not origins.is_empty(): row.label.text+="\nOrigem: "+origins
		if not destinations.is_empty(): row.label.text+="\nDestino: "+destinations
	for id in rows.keys():
		if not shown.has(id): rows[id].panel.queue_free(); rows.erase(id)
	l10n.render(self)
