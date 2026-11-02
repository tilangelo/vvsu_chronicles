extends RefCounted
## One visit to campus. Map changes keep this object; a new game starts a new day.
const START_TIME := 12 * 3600 + 40 * 60
const CLASS_TIME := 13 * 3600 + 30 * 60
const CLASSROOM := "class_1421"
const TIME_SCALE := 10.0
const BADGE_PRICE := 150
const TICKET := 27

var time_seconds := float(START_TIME)
var money := 500
var jacket_stored := false
var mentor_met := false
var badge_paid := false
var class_attended := false
var class_late := false


func advance(delta: float, map_id: String) -> void:
	var previous := time_seconds
	time_seconds += maxf(delta, 0.0) * TIME_SCALE
	if not class_attended and map_id == CLASSROOM and previous <= CLASS_TIME and time_seconds >= CLASS_TIME:
		class_attended = true
		class_late = false
	check_attendance(map_id)


func check_attendance(map_id: String) -> void:
	if not class_attended and map_id == CLASSROOM and time_seconds >= CLASS_TIME:
		class_attended = true
		class_late = time_seconds > CLASS_TIME


func clock_text() -> String:
	var minutes := int(time_seconds / 60.0)
	return "%02d:%02d" % [(minutes / 60) % 24, minutes % 60]


func lesson_hint(map_id: String) -> String:
	if class_attended:
		return "Пара посещена · можно заняться делами"
	if time_seconds >= CLASS_TIME:
		return "Пара уже началась · ауд. 1421"
	if map_id == CLASSROOM:
		return "Вы на месте · начало в 13:30"
	var minutes := ceili((CLASS_TIME - time_seconds) / 60.0)
	return "До пары %d мин · ауд. 1421" % minutes


func tasks(map_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append({"done": jacket_stored, "title": "Сдать куртку в гардероб", "detail": "Номерок №27 получен" if jacket_stored else "Гардеробщица · главный вход"})
	if not mentor_met:
		result.append({"done": false, "title": "Поговорить с наставником", "detail": "Коридор 1 этажа или зимний сад"})
	else:
		result.append({"done": badge_paid, "title": "Оплатить бейджик · 150 ₽", "detail": "Оплата принята · чек получен" if badge_paid else "Зелёный банкомат · зимний сад"})
	var detail := "4 этаж · аудитория 1421 · к 13:30"
	if class_attended:
		detail = "Посещена с опозданием" if class_late else "Вы пришли вовремя"
	elif time_seconds >= CLASS_TIME:
		detail = "Вы опаздываете · ещё можно прийти"
	elif map_id == CLASSROOM:
		detail = "Дождитесь 13:30 или поговорите с преподавателем"
	result.append({"done": class_attended, "title": "Прийти на первую пару", "detail": detail, "late": time_seconds >= CLASS_TIME and not class_attended})
	return result


func act(action: String, map_id: String) -> String:
	match action:
		"store_jacket":
			if jacket_stored:
				return "Ваша куртка уже у нас. Номерок №27 сохранён — не волнуйтесь, до конца дня всё под присмотром."
			jacket_stored = true
			return "Давайте куртку. Вот номерок №27, держите его при себе. Теперь можно налегке идти на пару!"
		"badge_info":
			mentor_met = true
			if badge_paid:
				return "Вижу оплату, чек у тебя есть. С бейджиком на сегодня всё — можешь спокойно заниматься остальными делами."
			return "Для бейджика нужно оплатить 150 ₽ в зелёном банкомате в зимнем саду, за тёмной колонной у стеклянной стены. Выбери «Оплатить бейджик». Можешь сделать это до пары или после неё."
		"pay_badge":
			if badge_paid:
				return "Бейджик уже оплачен. Чек №Б-027 сохранён. Повторное списание не требуется."
			if not mentor_met:
				return "Назначение платежа пока не получено. Поговорите с наставником в коридоре первого этажа или в зимнем саду."
			if money < BADGE_PRICE:
				return "Недостаточно средств для оплаты. Сумма: 150 ₽. Средства не списаны."
			money -= BADGE_PRICE
			badge_paid = true
			return "Оплата бейджика: 150 ₽. Платёж выполнен. Чек №Б-027 сохранён. Остаток: %d ₽." % money
		"wait_class":
			if map_id != CLASSROOM:
				return "Встречаемся в аудитории 1421 на четвёртом этаже. Приходи к 13:30."
			if time_seconds < CLASS_TIME:
				time_seconds = float(CLASS_TIME)
			check_attendance(map_id)
			return "13:30. Начинаем знакомство с университетом! Присутствие отмечено. После вводной встречи можешь вернуться к своим делам."
		"balance":
			return "Доступно: %d ₽. %s" % [money, "Бейджик оплачен, чек №Б-027 сохранён." if badge_paid else "Комиссия за оплату бейджика: 0 ₽."]
	return ""
