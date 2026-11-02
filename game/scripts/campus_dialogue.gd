extends RefCounted
## Role-specific conversations; actions are handled by CampusDay, routes by the level.
var visits: Dictionary = {}
var lines: Dictionary = {}


func greeting(who: String, key: String, day, map_id: String) -> String:
	var count := int(visits.get(key, 0))
	visits[key] = count + 1
	match who:
		"wardrobe":
			if day.jacket_stored:
				return "Снова здравствуйте! Куртка на месте, ваш номерок №27. Как первый день?"
		"mentor":
			var first: bool = not day.mentor_met
			day.mentor_met = true
			if day.badge_paid:
				return "С оплатой бейджика разобрались, отлично! %s" % _schedule(day)
			if first:
				return "Привет, первокурсник! Бейджик стоит 150 ₽: оплати его в зелёном банкомате в андере. Пара в 1421 в 13:30. Что сделать первым — решай сам."
			return "Как осваиваешься? Бейджик ещё можно оплатить в зелёном банкомате в андере. %s" % _schedule(day)
		"atm":
			if day.badge_paid:
				return "Оплата бейджика выполнена. Чек №Б-027 доступен. Повторный платёж не нужен."
			if day.mentor_met:
				return "Платёж: бейджик первокурсника. К оплате 150 ₽, без комиссии. На счёте %d ₽. Подтвердите оплату." % day.money
			return "Добро пожаловать. Чтобы оплатить бейджик, сначала получите назначение платежа у наставника. Баланс: %d ₽." % day.money
	if who.begins_with("teacher") and map_id == day.CLASSROOM:
		if day.class_attended:
			return "Присутствие я отметил. %s" % ("В следующий раз постарайтесь прийти к началу." if day.class_late else "Рад, что вы пришли вовремя. После вводной встречи можно продолжить знакомство с кампусом.")
		return "Добрый день! Это аудитория 1421. Начинаем в 13:30, пока можете осмотреться. Если готовы, дождёмся начала вместе."
	var entry: Dictionary = lines.get(who, lines.get("student", {}))
	var variants: Array = entry.get("greetings", [entry.get("greeting", "Здравствуйте!")])
	return str(variants[count % variants.size()])


func options(who: String, day, map_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match who:
		"wardrobe":
			result.append({"label": "Мой номерок" if day.jacket_stored else "Сдать куртку", "action": "store_jacket"})
		"mentor":
			result.append({"label": "Бейджик уже оплачен" if day.badge_paid else "Как оплатить бейджик?", "action": "badge_info"})
		"atm":
			if day.mentor_met:
				result.append({"label": "Посмотреть чек" if day.badge_paid else "Оплатить бейджик · 150 ₽", "action": "pay_badge"})
			result.append({"label": "Проверить баланс", "action": "balance"})
			result.append({"label": "Закончить", "action": "close"})
			return result
	if who.begins_with("teacher") and map_id == day.CLASSROOM and not day.class_attended:
		result.append({"label": "Дождаться начала пары · 13:30", "action": "wait_class"})
	if result.is_empty():
		result.append({"label": "Спросить дорогу", "action": "directions"})
	var entry: Dictionary = lines.get(who, lines.get("student", {}))
	result.append({"label": str(entry.get("topic", "Как проходит первый день?")), "action": "topic"})
	if result[0]["action"] != "directions":
		result.append({"label": "Спросить дорогу", "action": "directions"})
	else:
		result.append({"label": "Когда и где первая пара?", "action": "schedule"})
	result.append({"label": "Попрощаться", "action": "close"})
	return result


func answer(action: String, who: String, day, map_id: String) -> String:
	if action == "schedule":
		return _schedule(day)
	if action == "topic":
		var entry: Dictionary = lines.get(who, lines.get("student", {}))
		return str(entry.get("reply", "Сначала найди аудиторию, а остальное успеешь между парами. Не стесняйся спрашивать дорогу."))
	return day.act(action, map_id)


func _schedule(day) -> String:
	if day.class_attended:
		return "Ты уже отметился на вводной паре. Оставшиеся дела можно закончить в удобном порядке."
	if day.time_seconds >= day.CLASS_TIME:
		return "Пара уже началась. Иди на четвёртый этаж, аудитория 1421. Даже с опозданием лучше зайти и отметиться."
	return "Первая пара в 13:30, аудитория 1421 на четвёртом этаже. Лестница справа от гардероба. Заранее можно прийти и подождать преподавателя."
