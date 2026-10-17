extends SceneTree
func _init() -> void:call_deferred("run")
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://customer_feedback_test_only.json";ui.start_upgrade_test([]);ui.paused=false
	var slots: Array=[]
	for i in range(3):
		var c:Dictionary=ui.game.customers[i]
		c.present=true;c.arriving=false;c.departing=false;c.tea=0;c.tea_done=false;c.eggs=1;c.eggs_done=0
		var slot=ui.get_node("Shop/WindowMask/Customers/Customer%d"%i);slots.append(slot)
		slot.reset_motion();slot.initialized=true;slot.was_present=true
		slot.get_node("Avatar").visible=true;slot.get_node("OrderCard").visible=true
	ui.game.customers[2].tea=-1;ui.game.customers[2].tea_done=true
	ui.sync_ui();await process_frame
	var feedback=ui.get_node("Shop/Effects/CustomerFeedback")
	for i in range(3):
		ui.game.bowl="full";ui.game.tea=0 if i!=1 else 2
		ui.return_time=0;ui.return_item="";ui.drag="tea"
		ui.drag_visual_pos=ui.customer_rect(i).get_center()
		ui.finish_drag(ui.customer_rect(i).get_center())
		var popup=feedback.get_children().back()
		assert(popup.rating==i,"correct, imperfect and rejected ratings")
		assert(popup.get_node("Text").text==["唔該~","唔係好口岩wo","都無話要呢樣"][i])
		var font: FontVariation=popup.get_node("Text").get_theme_font("font")
		assert(font.variation_embolden>0 and font.base_font.resource_path.ends_with("jf-openhuninn-2.1.ttf"))
		assert(popup.get_node("Text").get_theme_constant("outline_size")>=3)
	assert(ui.return_time>0 and ui.game.bowl=="full","rejected tea returns without consuming")
	await create_timer(.07).timeout
	assert(slots[0].receive_factor<1 and slots[1].receive_factor<1,"accepted delivery causes squash")
	assert(slots[2].receive_factor==1,"rejected item is not received")
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/customer_feedback_preview.png")
	ui.paused=true;ui.sync_ui()
	var popup=feedback.get_children()[0];var p:Vector2=popup.position;var opacity:float=popup.modulate.a
	var avatar=slots[0].get_node("Avatar");var before:Vector2=avatar.position
	await create_timer(.25).timeout
	assert(popup.position.is_equal_approx(p) and is_equal_approx(popup.modulate.a,opacity))
	assert(avatar.position.is_equal_approx(before),"pause freezes breathing and popups")
	ui.paused=false;ui.sync_ui();await create_timer(.6).timeout
	assert(avatar.scale.is_equal_approx(slots[0].home_scale),"receive effect returns to authored scale")
	assert(avatar.pivot_offset.is_equal_approx(slots[0].home_pivot))
	var breath_before:Vector2=avatar.position;await create_timer(.3).timeout
	assert(not avatar.position.is_equal_approx(breath_before),"stationary customer breathes")
	assert(absf(avatar.position.y-slots[0].home_avatar.y)<=slots[0].breath_amplitude+.01)
	await create_timer(2.3).timeout
	assert(feedback.get_child_count()==0,"floating messages fade and clean up")
	print("PASS: three delivery results, UI bold/outline, rejected return, breathing, receive squash, pause and popup cleanup")
	quit()
