// Запустить выполнение процедуры в фоновом задании, если это возможно.
// При выполнении любого из следующих условий запуск выполняется не в фоне, а сразу в основном потоке:
//  * если вызов выполняется в файловой базе во внешнем соединении (в этом режиме фоновые задания не поддерживаются);
//  * если приложение запущено в режиме отладки (параметр /C РежимОтладки) - для упрощения отладки конфигурации;
//  * если в файловой ИБ имеются активные фоновые задания - для снижения времени ожидания пользователя;
//  * если выполняется процедура модуля внешней обработки или внешнего отчета.
//
// Не следует использовать эту функцию, если необходимо безусловно запускать фоновое задание.
// Может применяться совместно с функцией ДлительныеОперацииКлиент.ОжидатьЗавершение.
// 
// Параметры:
//  ИмяПроцедуры           - Строка    - имя экспортной процедуры общего модуля, модуля менеджера объекта 
//                                       или модуля обработки, которую необходимо выполнить в фоне.
//                                       Например, "МойОбщийМодуль.МояПроцедура", "Отчет.ЗагруженныеДанные.Сформировать"
//                                       или "Обработка.ЗагрузкаДанных.МодульОбъекта.Загрузить". 
//                                       У процедуры может быть два или три формальных параметра:
//                                        * Параметры       - Структура - произвольные параметры ПараметрыПроцедуры;
//                                        * АдресРезультата - Строка    - адрес временного хранилища, в которое нужно
//                                          поместить результат работы процедуры. Обязательно;
//                                        * АдресДополнительногоРезультата - Строка - если в ПараметрыВыполнения установлен 
//                                          параметр ДополнительныйРезультат, то содержит адрес дополнительного временного
//                                          хранилища, в которое нужно поместить результат работы процедуры. Опционально.
//                                       При необходимости выполнить в фоне функцию, ее следует обернуть в процедуру,
//                                       а ее результат возвращать через второй параметр АдресРезультата.
//  ПараметрыПроцедуры     - Структура - произвольные параметры вызова процедуры ИмяПроцедуры.
//  ПараметрыВыполнения    - Структура - см. функцию ПараметрыВыполненияВФоне.
//
// Возвращаемое значение:
//  Структура              - параметры выполнения задания: 
//   * Статус               - Строка - "Выполняется", если задание еще не завершилось;
//                                     "Выполнено", если задание было успешно выполнено;
//                                     "Ошибка", если задание завершено с ошибкой;
//                                     "Отменено", если задание отменено пользователем или администратором.
//   * ИдентификаторЗадания - УникальныйИдентификатор - если Статус = "Выполняется", то содержит 
//                                     идентификатор запущенного фонового задания.
//   * АдресРезультата       - Строка - адрес временного хранилища, в которое будет
//                                     помещен (или уже помещен) результат работы процедуры.
//   * АдресДополнительногоРезультата - Строка - если установлен параметр ДополнительныйРезультат, 
//                                     содержит адрес дополнительного временного хранилища,
//                                     в которое будет помещен (или уже помещен) результат работы процедуры.
//   * КраткоеПредставлениеОшибки   - Строка - краткая информация об исключении, если Статус = "Ошибка".
//   * ПодробноеПредставлениеОшибки - Строка - подробная информация об исключении, если Статус = "Ошибка".
// 
Функция ВыполнитьВФоне(Знач ИмяПроцедуры, Знач ПараметрыПроцедуры, Знач ПараметрыВыполнения) Экспорт

	UT_CommonClientServer.ПроверитьПараметр("УИ_ДлительныеОперации.ВыполнитьВФоне", "ПараметрыВыполнения",
		ПараметрыВыполнения, Тип("Структура"));
	Если ПараметрыВыполнения.ЗапуститьНеВФоне И ПараметрыВыполнения.ЗапуститьВФоне Тогда
		ВызватьИсключение НСтр("ru = 'Параметры ""ВсегдаНеВФоне"" и ""ВсегдаВФоне""
							   |не могут одновременно принимать значение Истина в УИ_ДлительныеОперации.ВыполнитьВФоне.'");
	КонецЕсли;

	АдресРезультата = ?(ПараметрыВыполнения.АдресРезультата <> Неопределено, ПараметрыВыполнения.АдресРезультата,
		ПоместитьВоВременноеХранилище(Неопределено, ПараметрыВыполнения.ИдентификаторФормы));

	Результат = Новый Структура;
	Результат.Вставить("Статус", "Выполняется");
	Результат.Вставить("ИдентификаторЗадания", Неопределено);
	Результат.Вставить("АдресРезультата", АдресРезультата);
	Результат.Вставить("АдресДополнительногоРезультата", "");
	Результат.Вставить("КраткоеПредставлениеОшибки", "");
	Результат.Вставить("ПодробноеПредставлениеОшибки", "");
	Результат.Вставить("Сообщения", Новый ФиксированныйМассив(Новый Массив));

	Если ПараметрыВыполнения.БезРасширений Тогда
		//ПараметрыВыполнения.БезРасширений = ЗначениеЗаполнено(ПараметрыСеанса.ПодключенныеРасширения);
	КонецЕсли;

	ПараметрыЭкспортнойПроцедуры = Новый Массив;
	ПараметрыЭкспортнойПроцедуры.Добавить(ПараметрыПроцедуры);
	ПараметрыЭкспортнойПроцедуры.Добавить(АдресРезультата);

	Если ПараметрыВыполнения.ДополнительныйРезультат Тогда
		Результат.АдресДополнительногоРезультата = ПоместитьВоВременноеХранилище(Неопределено,
			ПараметрыВыполнения.ИдентификаторФормы);
		ПараметрыЭкспортнойПроцедуры.Добавить(Результат.АдресДополнительногоРезультата);
	КонецЕсли;

	ВыполнитьБезФоновогоЗадания = Не ПараметрыВыполнения.БезРасширений И (ПараметрыВыполнения.ЗапуститьНеВФоне
		Или (ЕстьФоновыеЗаданияВФайловойИБ() И Не ПараметрыВыполнения.ЗапуститьВФоне) Или Не ВозможноВыполнитьВФоне(
		ИмяПроцедуры));

	// Выполнить в основном потоке.
	Если ВыполнитьБезФоновогоЗадания Тогда
		Попытка
			ВыполнитьПроцедуру(ИмяПроцедуры, ПараметрыЭкспортнойПроцедуры);
			Результат.Статус = "Выполнено";
		Исключение
			Результат.Статус = "Ошибка";
			Результат.КраткоеПредставлениеОшибки = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
			Результат.ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
			ЗаписьЖурналаРегистрации(НСтр("ru = 'Ошибка выполнения'",
				UT_CommonClientServer.DefaultLanguageCode()), УровеньЖурналаРегистрации.Ошибка, , ,
				Результат.ПодробноеПредставлениеОшибки);
		КонецПопытки;
		Возврат Результат;
	КонецЕсли;
	
	// Выполнить в фоне.
	Попытка
		Задание = ЗапуститьФоновоеЗаданиеСКонтекстомКлиента(ИмяПроцедуры, ПараметрыВыполнения,
			ПараметрыЭкспортнойПроцедуры);
	Исключение
		Результат.Статус = "Ошибка";
		Если Задание <> Неопределено И Задание.ИнформацияОбОшибке <> Неопределено Тогда
			Результат.КраткоеПредставлениеОшибки = КраткоеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
			Результат.ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
		Иначе
			Результат.КраткоеПредставлениеОшибки = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
			Результат.ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		КонецЕсли;
		Возврат Результат;
	КонецПопытки;

	Если Задание <> Неопределено И Задание.ИнформацияОбОшибке <> Неопределено Тогда
		Результат.Статус = "Ошибка";
		Результат.КраткоеПредставлениеОшибки = КраткоеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
		Результат.ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
		Возврат Результат;
	КонецЕсли;

	Результат.ИдентификаторЗадания = Задание.УникальныйИдентификатор;
	ЗаданиеВыполнено = Ложь;

	Если ПараметрыВыполнения.ОжидатьЗавершение <> 0 Тогда
		Попытка
			Задание.ОжидатьЗавершения(ПараметрыВыполнения.ОжидатьЗавершение);
			ЗаданиеВыполнено = Истина;
		Исключение
			// Специальная обработка не требуется, возможно исключение вызвано истечением времени ожидания.
		КонецПопытки;
	КонецЕсли;

	Если ЗаданиеВыполнено Тогда
		ПрогрессИСообщения = ПрочитатьПрогрессИСообщения(Задание.УникальныйИдентификатор, "ПрогрессИСообщения");
		Результат.Сообщения = ПрогрессИСообщения.Сообщения;
	КонецЕсли;

	ЗаполнитьЗначенияСвойств(Результат, ОперацияВыполнена(Задание.УникальныйИдентификатор), , "Сообщения");
	Возврат Результат;

КонецФункции

Функция ОперацияВыполнена(Знач ИдентификаторЗадания, Знач ИсключениеПриОшибке = Ложь,
	Знач ВыводитьПрогрессВыполнения = Ложь, Знач ВыводитьСообщения = Ложь) Экспорт

	Результат = Новый Структура;
	Результат.Вставить("Статус", "Выполняется");
	Результат.Вставить("КраткоеПредставлениеОшибки", Неопределено);
	Результат.Вставить("ПодробноеПредставлениеОшибки", Неопределено);
	Результат.Вставить("Прогресс", Неопределено);
	Результат.Вставить("Сообщения", Неопределено);

	Задание = НайтиЗаданиеПоИдентификатору(ИдентификаторЗадания);
	Если Задание = Неопределено Тогда
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Длительные операции'", UT_CommonClientServer.DefaultLanguageCode()),
			УровеньЖурналаРегистрации.Ошибка, , , НСтр("ru = 'Фоновое задание не найдено:'") + " " + Строка(
			ИдентификаторЗадания));
		Если ИсключениеПриОшибке Тогда
			ВызватьИсключение (НСтр("ru = 'Не удалось выполнить данную операцию.'"));
		КонецЕсли;
		Результат.Статус = "Ошибка";
		Возврат Результат;
	КонецЕсли;

	Если ВыводитьПрогрессВыполнения Тогда
		ПрогрессИСообщения = ПрочитатьПрогрессИСообщения(ИдентификаторЗадания, ?(ВыводитьСообщения,
			"ПрогрессИСообщения", "Прогресс"));
		Результат.Прогресс = ПрогрессИСообщения.Прогресс;
		Если ВыводитьСообщения Тогда
			Результат.Сообщения = ПрогрессИСообщения.Сообщения;
		КонецЕсли;
	ИначеЕсли ВыводитьСообщения Тогда
		Результат.Сообщения = Задание.ПолучитьСообщенияПользователю(Истина);
	КонецЕсли;

	Если Задание.Состояние = СостояниеФоновогоЗадания.Активно Тогда
		Возврат Результат;
	КонецЕсли;

	Если Задание.Состояние = СостояниеФоновогоЗадания.Отменено Тогда
		УстановитьПривилегированныйРежим(Истина);
		
		//TODO Переделать на работу через хранилище настроек
//		Если ПараметрыСеанса.ИмяПараметраСеанса.Найти(ИдентификаторЗадания) = Неопределено Тогда
//			Результат.Статус = "Ошибка";
//			Если Задание.ИнформацияОбОшибке <> Неопределено Тогда
//				Результат.КраткоеПредставлениеОшибки   = НСтр("ru = 'Операция отменена администратором.'");
//				Результат.ПодробноеПредставлениеОшибки = Результат.КраткоеПредставлениеОшибки;
//			КонецЕсли;
//			Если ИсключениеПриОшибке Тогда
//				Если Не ПустаяСтрока(Результат.КраткоеПредставлениеОшибки) Тогда
//					ТекстСообщения = Результат.КраткоеПредставлениеОшибки;
//				Иначе
//					ТекстСообщения = НСтр("ru = 'Не удалось выполнить данную операцию.'");
//				КонецЕсли;
//				ВызватьИсключение ТекстСообщения;
//			КонецЕсли;
//		Иначе
		Результат.Статус = "Отменено";
//		КонецЕсли;
		УстановитьПривилегированныйРежим(Ложь);
		Возврат Результат;
	КонецЕсли;

	Если Задание.Состояние = СостояниеФоновогоЗадания.ЗавершеноАварийно Или Задание.Состояние
		= СостояниеФоновогоЗадания.Отменено Тогда

		Результат.Статус = "Ошибка";
		Если Задание.ИнформацияОбОшибке <> Неопределено Тогда
			Результат.КраткоеПредставлениеОшибки   = КраткоеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
			Результат.ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
		КонецЕсли;
		Если ИсключениеПриОшибке Тогда
			Если Не ПустаяСтрока(Результат.КраткоеПредставлениеОшибки) Тогда
				ТекстСообщения = Результат.КраткоеПредставлениеОшибки;
			Иначе
				ТекстСообщения = НСтр("ru = 'Не удалось выполнить данную операцию.'");
			КонецЕсли;
			ВызватьИсключение ТекстСообщения;
		КонецЕсли;
		Возврат Результат;
	КонецЕсли;

	Результат.Статус = "Выполнено";
	Возврат Результат;

КонецФункции

// Считывает информацию о ходе выполнения фонового задания и сообщения, которые в нем были сформированы.
//
// Параметры:
//   ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания.
//   Режим                - Строка - "ПрогрессИСообщения", "Прогресс" или "Сообщения".
//
// Возвращаемое значение:
//   Структура - со свойствами:
//    * Прогресс  - Неопределено, Структура - Информация о ходе выполнения фонового задания, записанная процедурой СообщитьПрогресс:
//     ** Процент                 - Число  - Необязательный. Процент выполнения.
//     ** Текст                   - Строка - Необязательный. Информация о текущей операции.
//     ** ДополнительныеПараметры - Произвольный - Необязательный. Любая дополнительная информация.
//    * Сообщения - ФиксированныйМассив - Массив объектов СообщениеПользователю, которые были сформированы в фоновом задании.
//
Функция ПрочитатьПрогрессИСообщения(Знач ИдентификаторЗадания, Знач Режим = "ПрогрессИСообщения")

	Сообщения = Новый ФиксированныйМассив(Новый Массив);
	Результат = Новый Структура("Сообщения, Прогресс", Сообщения, Неопределено);

	Задание = ФоновыеЗадания.НайтиПоУникальномуИдентификатору(ИдентификаторЗадания);
	Если Задание = Неопределено Тогда
		Возврат Результат;
	КонецЕсли;

	МассивСообщений = Задание.ПолучитьСообщенияПользователю(Истина);
	Если МассивСообщений = Неопределено Тогда
		Возврат Результат;
	КонецЕсли;

	Количество = МассивСообщений.Количество();
	Сообщения = Новый Массив;
	ЧитатьСообщения = (Режим = "ПрогрессИСообщения" Или Режим = "Сообщения");
	ЧитатьПрогресс  = (Режим = "ПрогрессИСообщения" Или Режим = "Прогресс");

	Если ЧитатьСообщения И Не ЧитатьПрогресс Тогда
		Результат.Сообщения = Новый ФиксированныйМассив(МассивСообщений);
		Возврат Результат;
	КонецЕсли;

	Для Номер = 0 По Количество - 1 Цикл
		Сообщение = МассивСообщений[Номер];

		Если ЧитатьПрогресс И СтрНачинаетсяС(Сообщение.Текст, "{") Тогда
			Позиция = СтрНайти(Сообщение.Текст, "}");
			Если Позиция > 2 Тогда
				ИдентификаторМеханизма = Сред(Сообщение.Текст, 2, Позиция - 2);
				Если ИдентификаторМеханизма = СообщениеПрогресса() Тогда
					ПолученныйТекст = Сред(Сообщение.Текст, Позиция + 1);
					Результат.Прогресс = UT_Common.ЗначениеИзСтрокиXML(ПолученныйТекст);
					Продолжить;
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;
		Если ЧитатьСообщения Тогда
			Сообщения.Добавить(Сообщение);
		КонецЕсли;
	КонецЦикла;

	Результат.Сообщения = Новый ФиксированныйМассив(Сообщения);
	Возврат Результат;

КонецФункции

Функция ЕстьФоновыеЗаданияВФайловойИБ()

	ЗапущеноЗаданийВФайловойИБ = 0;
	Если UT_Common.ИнформационнаяБазаФайловая() Тогда
		Отбор = Новый Структура;
		Отбор.Вставить("Состояние", СостояниеФоновогоЗадания.Активно);
		ЗапущеноЗаданийВФайловойИБ = ФоновыеЗадания.ПолучитьФоновыеЗадания(Отбор).Количество();
	КонецЕсли;
	Возврат ЗапущеноЗаданийВФайловойИБ > 0;

КонецФункции

Функция ВозможноВыполнитьВФоне(ИмяПроцедуры)

	ЧастиИмени = СтрРазделить(ИмяПроцедуры, ".");
	Если ЧастиИмени.Количество() = 0 Тогда
		Возврат Ложь;
	КонецЕсли;

	ЭтоВнешняяОбработка = (ВРег(ЧастиИмени[0]) = "ВНЕШНЯЯОБРАБОТКА");
	ЭтоВнешнийОтчет = (ВРег(ЧастиИмени[0]) = "ВНЕШНИЙОТЧЕТ");
	Возврат Не (ЭтоВнешняяОбработка Или ЭтоВнешнийОтчет);

КонецФункции
Процедура ВыполнитьПроцедуру(ИмяПроцедуры, ПараметрыПроцедуры)

	ЧастиИмени = СтрРазделить(ИмяПроцедуры, ".");
	ЭтоПроцедураМодуляОбработки = (ЧастиИмени.Количество() = 4) И ВРег(ЧастиИмени[2]) = "МОДУЛЬОБЪЕКТА";
	Если Не ЭтоПроцедураМодуляОбработки Тогда
		UT_Common.ВыполнитьМетодКонфигурации(ИмяПроцедуры, ПараметрыПроцедуры);
		Возврат;
	КонецЕсли;

	ЭтоОбработка = ВРег(ЧастиИмени[0]) = "ОБРАБОТКА";
	ЭтоОтчет = ВРег(ЧастиИмени[0]) = "ОТЧЕТ";
	Если ЭтоОбработка Или ЭтоОтчет Тогда
		МенеджерОбъекта = ?(ЭтоОтчет, Отчеты, Обработки);
		ОбработкаОтчетОбъект = МенеджерОбъекта[ЧастиИмени[1]].Создать();
		UT_Common.ВыполнитьМетодОбъекта(ОбработкаОтчетОбъект, ЧастиИмени[3], ПараметрыПроцедуры);
		Возврат;
	КонецЕсли;

	ЭтоВнешняяОбработка = ВРег(ЧастиИмени[0]) = "ВНЕШНЯЯОБРАБОТКА";
	ЭтоВнешнийОтчет = ВРег(ЧастиИмени[0]) = "ВНЕШНИЙОТЧЕТ";
	Если ЭтоВнешняяОбработка Или ЭтоВнешнийОтчет Тогда
		ВыполнитьПроверкуПравДоступа("ИнтерактивноеОткрытиеВнешнихОбработок", Метаданные);
		МенеджерОбъекта = ?(ЭтоВнешнийОтчет, ВнешниеОтчеты, ВнешниеОбработки);
		ОбработкаОтчетОбъект = МенеджерОбъекта.Создать(ЧастиИмени[1], БезопасныйРежим());
		UT_Common.ВыполнитьМетодОбъекта(ОбработкаОтчетОбъект, ЧастиИмени[3], ПараметрыПроцедуры);
		Возврат;
	КонецЕсли;

	ВызватьИсключение СтрШаблон(
		НСтр("ru = 'Неверный формат параметра ИмяПроцедуры (переданное значение: %1)'"), ИмяПроцедуры);

КонецПроцедуры

Функция ЗапуститьФоновоеЗаданиеСКонтекстомКлиента(ИмяПроцедуры, ПараметрыВыполнения, ПараметрыПроцедуры = Неопределено) Экспорт

	КлючФоновогоЗадания = ПараметрыВыполнения.КлючФоновогоЗадания;
	НаименованиеФоновогоЗадания = ?(ПустаяСтрока(ПараметрыВыполнения.НаименованиеФоновогоЗадания), ИмяПроцедуры,
		ПараметрыВыполнения.НаименованиеФоновогоЗадания);

	ВсеПараметры = Новый Структура;
	ВсеПараметры.Вставить("ИмяПроцедуры", ИмяПроцедуры);
	ВсеПараметры.Вставить("ПараметрыПроцедуры", ПараметрыПроцедуры);
//	..ВсеПараметры.Вставить("ПараметрыКлиентаНаСервере", СтандартныеПодсистемыСервер.ПараметрыКлиентаНаСервере());

	ПараметрыПроцедурыФоновогоЗадания = Новый Массив;
	ПараметрыПроцедурыФоновогоЗадания.Добавить(ВсеПараметры);

	Возврат ВыполнитьФоновоеЗадание(ПараметрыВыполнения, "УИ_ДлительныеОперации.ВыполнитьСКонтекстомКлиента",
		ПараметрыПроцедурыФоновогоЗадания, КлючФоновогоЗадания, НаименованиеФоновогоЗадания);

КонецФункции

Функция НайтиЗаданиеПоИдентификатору(Знач ИдентификаторЗадания)

	Если ТипЗнч(ИдентификаторЗадания) = Тип("Строка") Тогда
		ИдентификаторЗадания = Новый УникальныйИдентификатор(ИдентификаторЗадания);
	КонецЕсли;

	Задание = ФоновыеЗадания.НайтиПоУникальномуИдентификатору(ИдентификаторЗадания);
	Возврат Задание;

КонецФункции

Функция СообщениеПрогресса() Экспорт
	Возврат "УИ_УниверсальныеИнструменты.ДлительныеОперации";
КонецФункции
Функция ВыполнитьФоновоеЗадание(ПараметрыВыполнения, ИмяМетода, Параметры, Ключ, Наименование)

	Если ТекущийРежимЗапуска() = Неопределено И UT_Common.ИнформационнаяБазаФайловая() Тогда

		Сеанс = ПолучитьТекущийСеансИнформационнойБазы();
		Если ПараметрыВыполнения.ОжидатьЗавершение = Неопределено И Сеанс.ИмяПриложения = "BackgroundJob" Тогда
			ВызватьИсключение НСтр(
				"ru = 'В файловой информационной базе невозможно одновременно выполнять более одного фонового задания'");
		ИначеЕсли Сеанс.ИмяПриложения = "COMConnection" Тогда
			ВызватьИсключение НСтр(
				"ru = 'В файловой информационной базе можно запустить фоновое задание только из клиентского приложения'");
		КонецЕсли;

	КонецЕсли;

	Если ПараметрыВыполнения.БезРасширений Тогда
		Возврат РасширенияКонфигурации.ВыполнитьФоновоеЗаданиеБезРасширений(ИмяМетода, Параметры, Ключ, Наименование);
	Иначе
		Возврат ФоновыеЗадания.Выполнить(ИмяМетода, Параметры, Ключ, Наименование);
	КонецЕсли;

КонецФункции

// Продолжение процедуры ЗапуститьФоновоеЗаданиеСКонтекстомКлиента.
Процедура ВыполнитьСКонтекстомКлиента(ВсеПараметры) Экспорт
	
//	УстановитьПривилегированныйРежим(Истина);
//	Если ПравоДоступа("Установка", Метаданные.ПараметрыСеанса.ПараметрыКлиентаНаСервере) Тогда
//		ПараметрыСеанса.ПараметрыКлиентаНаСервере = ВсеПараметры.ПараметрыКлиентаНаСервере;
//	КонецЕсли;
//	Справочники.ВерсииРасширений.ЗарегистрироватьИспользованиеВерсииРасширений();
//	УстановитьПривилегированныйРежим(Ложь);

	ВыполнитьПроцедуру(ВсеПараметры.ИмяПроцедуры, ВсеПараметры.ПараметрыПроцедуры);

КонецПроцедуры

// Возвращает новую структуру для параметра ПараметрыВыполнения функции ВыполнитьВФоне.
//
// Параметры:
//   ИдентификаторФормы - УникальныйИдентификатор - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//
// Возвращаемое значение:
//   Структура - со свойствами:
//     * ИдентификаторФормы      - УникальныйИдентификатор - уникальный идентификатор формы, 
//                               во временное хранилище которой надо поместить результат выполнения процедуры.
//     * ДополнительныйРезультат - Булево     - признак использования дополнительного временного хранилища для передачи 
//                                 результата из фонового задания в родительский сеанс. По умолчанию - Ложь.
//     * ОжидатьЗавершение       - Число, Неопределено - таймаут в секундах ожидания завершения фонового задания. 
//                               Если задано Неопределено, то ждать до момента завершения задания. 
//                               Если задано 0, то ждать завершения задания не требуется. 
//                               По умолчанию - 2 секунды; а для низкой скорости соединения - 4. 
//     * НаименованиеФоновогоЗадания - Строка - описание фонового задания. По умолчанию - имя процедуры.
//     * КлючФоновогоЗадания      - Строка    - уникальный ключ для активных фоновых заданий, имеющих такое же имя процедуры.
//                                              По умолчанию, не задан.
//     * АдресРезультата          - Строка - адрес временного хранилища, в которое должен быть помещен результат
//                                           работы процедуры. Если не задан, адрес формируется автоматически.
//     * ЗапуститьВФоне           - Булево - если Истина, то задание будет всегда выполняться в фоне,
//                               за исключением режима отладки.
//                               В файловом варианте, при наличии ранее запущенных заданий,
//                               новое задание становится в очередь и начинает выполняться после завершения предыдущих.
//     * ЗапуститьНеВФоне         - Булево - если Истина, задание всегда будет запускаться непосредственно,
//                               без использования фонового задания.
//     * БезРасширений            - Булево - если Истина, то фоновое задание будет запущено без подключения
//                               расширений конфигурации.
//
Функция ПараметрыВыполненияВФоне(Знач ИдентификаторФормы) Экспорт

	Результат = Новый Структура;
	Результат.Вставить("ИдентификаторФормы", ИдентификаторФормы);
	Результат.Вставить("ДополнительныйРезультат", Ложь);
	Результат.Вставить("ОжидатьЗавершение", ?(ПолучитьСкоростьКлиентскогоСоединения()
		= СкоростьКлиентскогоСоединения.Низкая, 4, 0.8));
	Результат.Вставить("НаименованиеФоновогоЗадания", "");
	Результат.Вставить("КлючФоновогоЗадания", "");
	Результат.Вставить("АдресРезультата", Неопределено);
	Результат.Вставить("ЗапуститьНеВФоне", Ложь);
	Результат.Вставить("ЗапуститьВФоне", Ложь);
	Результат.Вставить("БезРасширений", Ложь);
	Возврат Результат;

КонецФункции

// Отменяет выполнение фонового задания по переданному идентификатору.
// 
// Параметры:
//  ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания. 
// 
Процедура ОтменитьВыполнениеЗадания(Знач ИдентификаторЗадания) Экспорт

	Если Не ЗначениеЗаполнено(ИдентификаторЗадания) Тогда
		Возврат;
	КонецЕсли;
	
//	УстановитьПривилегированныйРежим(Истина);
//	Если ПараметрыСеанса.УИ_ОтмененныеДлительныеОперации.Найти(ИдентификаторЗадания) = Неопределено Тогда
//		ОтмененныеДлительныеОперации = Новый Массив(ПараметрыСеанса.УИ_ОтмененныеДлительныеОперации);
//		ОтмененныеДлительныеОперации.Добавить(ИдентификаторЗадания);
//		ПараметрыСеанса.УИ_ОтмененныеДлительныеОперации = Новый ФиксированныйМассив(ОтмененныеДлительныеОперации);
//	КонецЕсли;
//	УстановитьПривилегированныйРежим(Ложь);

	Задание = НайтиЗаданиеПоИдентификатору(ИдентификаторЗадания);
	Если Задание = Неопределено Или Задание.Состояние <> СостояниеФоновогоЗадания.Активно Тогда

		Возврат;
	КонецЕсли;

	Попытка
		Задание.Отменить();
	Исключение
		// Возможно задание как раз в этот момент закончилось и ошибки нет.
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Длительные операции.Отмена выполнения фонового задания'",
			UT_CommonClientServer.DefaultLanguageCode()), УровеньЖурналаРегистрации.Предупреждение, , ,
			ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;

КонецПроцедуры
Функция ОперацииВыполнены(Знач Задания) Экспорт

	Результат = Новый Соответствие;
	Для Каждого Задание Из Задания Цикл
		Результат.Вставить(Задание.ИдентификаторЗадания, ОперацияВыполнена(Задание.ИдентификаторЗадания, Ложь,
			Задание.ВыводитьПрогрессВыполнения, Задание.ВыводитьСообщения));
	КонецЦикла;
	Возврат Результат;

КонецФункции

// Регистрирует информацию о ходе выполнения фонового задания.
// В дальнейшем ее можно считать при помощи функции ПрочитатьПрогресс.
//
// Параметры:
//  Процент - Число  - Необязательный. Процент выполнения.
//  Текст   - Строка - Необязательный. Информация о текущей операции.
//  ДополнительныеПараметры - Произвольный - Необязательный. Любая дополнительная информация,
//      которую необходимо передать на клиент. Значение должно быть простым (сериализуемым в XML строку).
//
Процедура СообщитьПрогресс(Знач Процент = Неопределено, Знач Текст = Неопределено,
	Знач ДополнительныеПараметры = Неопределено) Экспорт

	Если ПолучитьТекущийСеансИнформационнойБазы().ПолучитьФоновоеЗадание() = Неопределено Тогда
		Возврат;
	КонецЕсли;

	ПередаваемоеЗначение = Новый Структура;
	Если Процент <> Неопределено Тогда
		ПередаваемоеЗначение.Вставить("Процент", Процент);
	КонецЕсли;
	Если Текст <> Неопределено Тогда
		ПередаваемоеЗначение.Вставить("Текст", Текст);
	КонецЕсли;
	Если ДополнительныеПараметры <> Неопределено Тогда
		ПередаваемоеЗначение.Вставить("ДополнительныеПараметры", ДополнительныеПараметры);
	КонецЕсли;

	ПередаваемыйТекст = UT_Common.ЗначениеВСтрокуXML(ПередаваемоеЗначение);

	Текст = "{" + СообщениеПрогресса() + "}" + ПередаваемыйТекст;
	UT_CommonClientServer.СообщитьПользователю(Текст);

КонецПроцедуры

// Получает сообщения пользователю, отфильтровывает служебные сообщения о состоянии длительной операции.
// 
// Параметры:
//  УдалятьПолученные - Булево - Признак необходимости удаления полученных сообщений.
//  ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания.
// 
// Возвращаемое значение:
//  Массив - ФиксированныйМассив - Массив объектов СообщениеПользователю, которые были сформированы в
//  фоновом задании.
Функция СообщенияПользователю(УдалятьПолученные = Ложь, ИдентификаторЗадания = Неопределено) Экспорт

	Если ЗначениеЗаполнено(ИдентификаторЗадания) Тогда
		ФоновоеЗадание = ФоновыеЗадания.НайтиПоУникальномуИдентификатору(ИдентификаторЗадания);
		Если ФоновоеЗадание <> Неопределено Тогда
			ВсеСообщения = ФоновоеЗадание.ПолучитьСообщенияПользователю(УдалятьПолученные);
		КонецЕсли;
	Иначе
		ВсеСообщения = ПолучитьСообщенияПользователю(УдалятьПолученные);
	КонецЕсли;

	Результат = Новый Массив;

	Для Каждого Сообщение Из ВсеСообщения Цикл
		Если СтрНачинаетсяС(Сообщение.Текст, "{" + СообщениеПрогресса() + "}") Тогда
			Если УдалятьПолученные Тогда
				Сообщение.Сообщить();
			КонецЕсли;
		Иначе
			Результат.Добавить(Сообщение);
		КонецЕсли;
	КонецЦикла;

	Возврат Новый ФиксированныйМассив(Результат);

КонецФункции

// Проверяет состояние фонового задания по переданному идентификатору.
// При аварийном завершении задания вызывает исключение.
//
// Параметры:
//  ИдентификаторЗадания - УникальныйИдентификатор - идентификатор фонового задания. 
//
// Возвращаемое значение:
//  Булево - состояние выполнения задания.
// 
Функция ЗаданиеВыполнено(Знач ИдентификаторЗадания) Экспорт

	Задание = НайтиЗаданиеПоИдентификатору(ИдентификаторЗадания);

	Если Задание <> Неопределено И Задание.Состояние = СостояниеФоновогоЗадания.Активно Тогда
		Возврат Ложь;
	КонецЕсли;

	ОперацияНеВыполнена = Истина;
	ПоказатьПолныйТекстОшибки = Ложь;
	Если Задание = Неопределено Тогда
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Длительные операции.Фоновое задание не найдено'",
			UT_CommonClientServer.DefaultLanguageCode()), УровеньЖурналаРегистрации.Ошибка, , , Строка(
			ИдентификаторЗадания));
	Иначе
		Если Задание.Состояние = СостояниеФоновогоЗадания.ЗавершеноАварийно Тогда
			ОшибкаЗадания = Задание.ИнформацияОбОшибке;
			Если ОшибкаЗадания <> Неопределено Тогда
				ПоказатьПолныйТекстОшибки = Истина;
			КонецЕсли;
		ИначеЕсли Задание.Состояние = СостояниеФоновогоЗадания.Отменено Тогда
			ЗаписьЖурналаРегистрации(
				НСтр("ru = 'Длительные операции.Фоновое задание отменено администратором'",
				UT_CommonClientServer.DefaultLanguageCode()), УровеньЖурналаРегистрации.Ошибка, , , НСтр(
				"ru = 'Задание завершилось с неизвестной ошибкой.'"));
		Иначе
			Возврат Истина;
		КонецЕсли;
	КонецЕсли;

	Если ПоказатьПолныйТекстОшибки Тогда
		ТекстОшибки = КраткоеПредставлениеОшибки(Задание.ИнформацияОбОшибке);
		ВызватьИсключение (ТекстОшибки);
	ИначеЕсли ОперацияНеВыполнена Тогда
		ВызватьИсключение (НСтр("ru = 'Не удалось выполнить данную операцию. 
								|Подробности см. в Журнале регистрации.'"));
	КонецЕсли;

КонецФункции