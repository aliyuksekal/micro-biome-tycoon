extends Node
## Çok dilli metin kaynağı. Metinler görsellere gömülmez; buradan okunur.
## Diller: tr, en, ru, uz, zh, ko. Anahtar bulunamazsa İngilizce, o da yoksa anahtarın kendisi döner.

signal language_changed

const LANGS: Array[String] = ["tr", "en", "ru", "uz", "zh", "ko"]
const LANG_NAMES := {
	"tr": "Türkçe", "en": "English", "ru": "Русский",
	"uz": "Oʻzbekcha", "zh": "中文", "ko": "한국어",
}

var lang: String = "en"

const S := {
	"app_title": {"tr": "Micro-Biome Tycoon", "en": "Micro-Biome Tycoon", "ru": "Micro-Biome Tycoon", "uz": "Micro-Biome Tycoon", "zh": "Micro-Biome Tycoon", "ko": "Micro-Biome Tycoon"},
	"tagline": {"tr": "Kur · Dengele · Büyüt", "en": "Build · Balance · Thrive", "ru": "Строй · Балансируй · Процветай", "uz": "Qur · Muvozanatla · Rivojlantir", "zh": "建造 · 平衡 · 繁荣", "ko": "건설 · 균형 · 번영"},
	"play": {"tr": "Oyna", "en": "Play", "ru": "Играть", "uz": "Oʻynash", "zh": "开始游戏", "ko": "플레이"},
	"continue": {"tr": "Devam et", "en": "Continue", "ru": "Продолжить", "uz": "Davom etish", "zh": "继续", "ko": "계속하기"},
	"how_to_play": {"tr": "Nasıl oynanır?", "en": "How to play", "ru": "Как играть", "uz": "Qanday oʻynaladi?", "zh": "玩法说明", "ko": "플레이 방법"},
	"settings": {"tr": "Ayarlar", "en": "Settings", "ru": "Настройки", "uz": "Sozlamalar", "zh": "设置", "ko": "설정"},
	"about": {"tr": "Hakkında", "en": "About", "ru": "Об игре", "uz": "Oʻyin haqida", "zh": "关于", "ko": "정보"},
	"best_score": {"tr": "En iyi skor: {v}", "en": "Best score: {v}", "ru": "Рекорд: {v}", "uz": "Eng yaxshi natija: {v}", "zh": "最高分：{v}", "ko": "최고 점수: {v}"},
	"version": {"tr": "Sürüm {v}", "en": "Version {v}", "ru": "Версия {v}", "uz": "Versiya {v}", "zh": "版本 {v}", "ko": "버전 {v}"},
	"exit_q": {"tr": "Oyundan çıkılsın mı?", "en": "Quit the game?", "ru": "Выйти из игры?", "uz": "Oʻyindan chiqilsinmi?", "zh": "要退出游戏吗？", "ko": "게임을 종료할까요?"},
	"exit": {"tr": "Çık", "en": "Quit", "ru": "Выйти", "uz": "Chiqish", "zh": "退出", "ko": "종료"},
	"cancel": {"tr": "Vazgeç", "en": "Cancel", "ru": "Отмена", "uz": "Bekor qilish", "zh": "取消", "ko": "취소"},
	"ok": {"tr": "Tamam", "en": "OK", "ru": "ОК", "uz": "Mayli", "zh": "好的", "ko": "확인"},
	"close": {"tr": "Kapat", "en": "Close", "ru": "Закрыть", "uz": "Yopish", "zh": "关闭", "ko": "닫기"},
	"back": {"tr": "Geri", "en": "Back", "ru": "Назад", "uz": "Orqaga", "zh": "返回", "ko": "뒤로"},
	# Tanıtım
	"intro1_t": {"tr": "Bağırsak dünyasına hoş geldin!", "en": "Welcome to the gut world!", "ru": "Добро пожаловать в мир кишечника!", "uz": "Ichak olamiga xush kelibsiz!", "zh": "欢迎来到肠道世界！", "ko": "장 속 세계에 오신 걸 환영해요!"},
	"intro1_b": {"tr": "Burada sevimli dost bakterilerden bir koloni kuracaksın. Bu oyun eğlence amaçlı bir kurgudur.", "en": "You'll grow a colony of cute friendly bacteria. This game is playful fiction.", "ru": "Ты вырастишь колонию милых дружелюбных бактерий. Эта игра — весёлый вымысел.", "uz": "Siz yoqimtoy doʻst bakteriyalar koloniyasini oʻstirasiz. Bu oʻyin — qiziqarli toʻqima.", "zh": "你将培育一群可爱的友好细菌。本游戏纯属娱乐虚构。", "ko": "귀여운 친구 박테리아 군집을 키워 보세요. 이 게임은 재미를 위한 허구예요."},
	"intro2_t": {"tr": "Yerleştir ve kazan", "en": "Place and earn", "ru": "Размещай и зарабатывай", "uz": "Joylashtiring va yigʻing", "zh": "放置并收获", "ko": "배치하고 모으기"},
	"intro2_b": {"tr": "Alttan bir bakteri seç, boş karoya dokun. Her koloni saniyede besin üretir.", "en": "Pick a bacterium below and tap an empty tile. Every colony produces nutrients each second.", "ru": "Выбери бактерию внизу и коснись пустой клетки. Каждая колония приносит питательные вещества.", "uz": "Pastdan bakteriya tanlang va boʻsh katakka bosing. Har bir koloniya har soniyada ozuqa beradi.", "zh": "在下方选择细菌，再点击空格子。每个菌落每秒都会产出营养。", "ko": "아래에서 박테리아를 고르고 빈 칸을 누르세요. 군집은 매초 영양분을 만들어요."},
	"intro3_t": {"tr": "Kötü mikroplara dokun!", "en": "Tap the bad germs!", "ru": "Жми на вредных микробов!", "uz": "Yomon mikroblarga bosing!", "zh": "点击坏细菌！", "ko": "나쁜 세균을 터치하세요!"},
	"intro3_b": {"tr": "Patojenler bariyeri yıpratır ve yayılır. Onlara dokunarak yen; lif kazan.", "en": "Pathogens wear down the barrier and spread. Tap them to defeat them and earn fiber.", "ru": "Патогены ослабляют барьер и распространяются. Жми на них, чтобы победить и получить клетчатку.", "uz": "Patogenlar toʻsiqni yemiradi va tarqaladi. Ularni bosib yenging va tola oling.", "zh": "病原体会削弱屏障并扩散。点击击败它们，获得纤维。", "ko": "병원균은 장벽을 약하게 하고 퍼져요. 터치해서 물리치고 식이섬유를 얻으세요."},
	"intro4_t": {"tr": "Dengeyi koru", "en": "Keep the balance", "ru": "Сохраняй баланс", "uz": "Muvozanatni saqlang", "zh": "保持平衡", "ko": "균형을 지키세요"},
	"intro4_b": {"tr": "Farklı türler bonus verir. Lif ile kolonileri besle, bariyer sıfırlanmasın!", "en": "Different species give a bonus. Feed colonies with fiber and don't let the barrier hit zero!", "ru": "Разные виды дают бонус. Корми колонии клетчаткой и не дай барьеру упасть до нуля!", "uz": "Turli turlar bonus beradi. Koloniyalarni tola bilan boqing, toʻsiq nolga tushmasin!", "zh": "物种越多样加成越高。用纤维喂养菌落，别让屏障降到零！", "ko": "다양한 종은 보너스를 줘요. 식이섬유로 군집을 먹이고 장벽이 0이 되지 않게 하세요!"},
	"next": {"tr": "İleri", "en": "Next", "ru": "Далее", "uz": "Keyingi", "zh": "下一步", "ko": "다음"},
	"skip": {"tr": "Atla", "en": "Skip", "ru": "Пропустить", "uz": "Oʻtkazib yuborish", "zh": "跳过", "ko": "건너뛰기"},
	"start": {"tr": "Başla", "en": "Start", "ru": "Начать", "uz": "Boshlash", "zh": "开始", "ko": "시작"},
	# HUD
	"nutrients": {"tr": "Besin", "en": "Nutrients", "ru": "Питание", "uz": "Ozuqa", "zh": "营养", "ko": "영양분"},
	"fiber": {"tr": "Lif", "en": "Fiber", "ru": "Клетчатка", "uz": "Tola", "zh": "纤维", "ko": "식이섬유"},
	"barrier": {"tr": "Bağırsak bariyeri", "en": "Gut barrier", "ru": "Кишечный барьер", "uz": "Ichak toʻsigʻi", "zh": "肠道屏障", "ko": "장 장벽"},
	"per_sec": {"tr": "{v}/sn", "en": "{v}/s", "ru": "{v}/с", "uz": "{v}/s", "zh": "{v}/秒", "ko": "{v}/초"},
	"ecosystem": {"tr": "Ekosistem", "en": "Ecosystem", "ru": "Экосистема", "uz": "Ekotizim", "zh": "生态系统", "ko": "생태계"},
	"upgrades": {"tr": "Geliştir", "en": "Upgrades", "ru": "Улучшения", "uz": "Yaxshilash", "zh": "升级", "ko": "강화"},
	"gift": {"tr": "Hediye", "en": "Gift", "ru": "Подарок", "uz": "Sovgʻa", "zh": "礼物", "ko": "선물"},
	"pause": {"tr": "Duraklat", "en": "Pause", "ru": "Пауза", "uz": "Pauza", "zh": "暂停", "ko": "일시정지"},
	"paused": {"tr": "Oyun durdu", "en": "Paused", "ru": "Пауза", "uz": "Oʻyin toʻxtatildi", "zh": "已暂停", "ko": "일시정지됨"},
	"resume": {"tr": "Devam et", "en": "Resume", "ru": "Продолжить", "uz": "Davom etish", "zh": "继续", "ko": "계속"},
	"main_menu": {"tr": "Ana menü", "en": "Main menu", "ru": "Главное меню", "uz": "Bosh menyu", "zh": "主菜单", "ko": "메인 메뉴"},
	"locked": {"tr": "Kilitli", "en": "Locked", "ru": "Закрыто", "uz": "Qulflangan", "zh": "未解锁", "ko": "잠김"},
	"unlock_at": {"tr": "Toplam {v} besinle açılır", "en": "Unlocks at {v} total nutrients", "ru": "Откроется при {v} питания всего", "uz": "Jami {v} ozuqada ochiladi", "zh": "累计 {v} 营养后解锁", "ko": "누적 영양분 {v}에서 해금"},
	# Türler
	"sp_lactobacillus": {"tr": "Lactobacillus", "en": "Lactobacillus", "ru": "Лактобацилла", "uz": "Laktobatsilla", "zh": "乳杆菌", "ko": "락토바실러스"},
	"sp_bifidobacterium": {"tr": "Bifidobacterium", "en": "Bifidobacterium", "ru": "Бифидобактерия", "uz": "Bifidobakteriya", "zh": "双歧杆菌", "ko": "비피도박테리움"},
	"sp_streptococcus": {"tr": "Streptococcus", "en": "Streptococcus", "ru": "Стрептококк", "uz": "Streptokokk", "zh": "链球菌", "ko": "스트렙토코쿠스"},
	"sp_e_faecalis": {"tr": "E. faecalis", "en": "E. faecalis", "ru": "E. faecalis", "uz": "E. faecalis", "zh": "粪肠球菌", "ko": "E. 페칼리스"},
	"sp_pathogen": {"tr": "Patojen", "en": "Pathogen", "ru": "Патоген", "uz": "Patogen", "zh": "病原体", "ko": "병원균"},
	"sp_inflammatory": {"tr": "İltihap", "en": "Inflammatory", "ru": "Воспаление", "uz": "Yalligʻlanish", "zh": "炎症怪", "ko": "염증균"},
	"sp_c_difficile": {"tr": "C. difficile", "en": "C. difficile", "ru": "C. difficile", "uz": "C. difficile", "zh": "艰难梭菌", "ko": "C. 디피실"},
	"d_lactobacillus": {"tr": "Çalışkan başlangıç dostu. Ucuz ve hızlı.", "en": "Hard-working starter buddy. Cheap and quick.", "ru": "Трудолюбивый стартовый друг. Дёшево и быстро.", "uz": "Mehnatkash boshlangʻich doʻst. Arzon va tez.", "zh": "勤劳的入门伙伴，便宜又高效。", "ko": "부지런한 첫 친구. 싸고 빨라요."},
	"d_bifidobacterium": {"tr": "Bariyeri yavaşça onarır.", "en": "Slowly repairs the barrier.", "ru": "Медленно восстанавливает барьер.", "uz": "Toʻsiqni asta-sekin tiklaydi.", "zh": "缓慢修复屏障。", "ko": "장벽을 천천히 회복해요."},
	"d_streptococcus": {"tr": "Komşu mikroplara otomatik saldırır.", "en": "Automatically attacks neighbouring germs.", "ru": "Сам атакует соседних микробов.", "uz": "Qoʻshni mikroblarga avtomatik hujum qiladi.", "zh": "自动攻击相邻的坏细菌。", "ko": "이웃한 세균을 자동으로 공격해요."},
	"d_e_faecalis": {"tr": "Komşu karoları yayılmaya karşı korur.", "en": "Shields neighbouring tiles from spreading.", "ru": "Защищает соседние клетки от заражения.", "uz": "Qoʻshni kataklarni tarqalishdan himoya qiladi.", "zh": "保护相邻格子不被感染扩散。", "ko": "이웃 칸을 확산으로부터 보호해요."},
	"d_pathogen": {"tr": "Bariyeri yıpratır ve yayılır.", "en": "Wears the barrier down and spreads.", "ru": "Ослабляет барьер и распространяется.", "uz": "Toʻsiqni yemiradi va tarqaladi.", "zh": "削弱屏障并扩散。", "ko": "장벽을 약하게 하고 퍼져요."},
	"d_inflammatory": {"tr": "Komşu kolonilere zarar verir.", "en": "Hurts neighbouring colonies.", "ru": "Вредит соседним колониям.", "uz": "Qoʻshni koloniyalarga zarar yetkazadi.", "zh": "伤害相邻菌落。", "ko": "이웃 군집에 피해를 줘요."},
	"d_c_difficile": {"tr": "Çeşitlilik azalınca ortaya çıkan güçlü bela.", "en": "A tough troublemaker that appears when diversity is low.", "ru": "Сильный вредитель, появляется при низком разнообразии.", "uz": "Xilma-xillik kamayganda paydo boʻladigan kuchli bezori.", "zh": "多样性不足时出现的强大麻烦制造者。", "ko": "다양성이 낮을 때 나타나는 강한 말썽꾼."},
	# Koloni penceresi
	"level": {"tr": "Seviye {v}", "en": "Level {v}", "ru": "Уровень {v}", "uz": "Daraja {v}", "zh": "等级 {v}", "ko": "레벨 {v}"},
	"production": {"tr": "Üretim: {v}", "en": "Production: {v}", "ru": "Производство: {v}", "uz": "Ishlab chiqarish: {v}", "zh": "产量：{v}", "ko": "생산량: {v}"},
	"health": {"tr": "Can: {v}", "en": "Health: {v}", "ru": "Здоровье: {v}", "uz": "Sogʻliq: {v}", "zh": "生命：{v}", "ko": "체력: {v}"},
	"feed": {"tr": "Besle ({v} lif)", "en": "Feed ({v} fiber)", "ru": "Покормить ({v} клетч.)", "uz": "Boqish ({v} tola)", "zh": "喂养（{v} 纤维）", "ko": "먹이 주기 (식이섬유 {v})"},
	"max_level": {"tr": "En yüksek seviye", "en": "Max level", "ru": "Макс. уровень", "uz": "Eng yuqori daraja", "zh": "已满级", "ko": "최고 레벨"},
	"remove": {"tr": "Kaldır (+{v})", "en": "Remove (+{v})", "ru": "Убрать (+{v})", "uz": "Olib tashlash (+{v})", "zh": "移除（+{v}）", "ko": "제거 (+{v})"},
	"not_enough": {"tr": "Yeterli kaynak yok", "en": "Not enough resources", "ru": "Не хватает ресурсов", "uz": "Resurs yetarli emas", "zh": "资源不足", "ko": "자원이 부족해요"},
	"select_species": {"tr": "Önce alttan bir bakteri seç", "en": "Pick a bacterium below first", "ru": "Сначала выбери бактерию внизу", "uz": "Avval pastdan bakteriya tanlang", "zh": "请先在下方选择细菌", "ko": "먼저 아래에서 박테리아를 고르세요"},
	"rock": {"tr": "Kaya", "en": "Rock", "ru": "Камень", "uz": "Tosh", "zh": "岩石", "ko": "바위"},
	"clear_rock": {"tr": "Kayayı temizle ({v} besin)", "en": "Clear rock ({v} nutrients)", "ru": "Убрать камень ({v} питания)", "uz": "Toshni tozalash ({v} ozuqa)", "zh": "清除岩石（{v} 营养）", "ko": "바위 치우기 (영양분 {v})"},
	"tile_boost": {"tr": "Verim karosu: üretim ×2", "en": "Boost tile: production ×2", "ru": "Клетка-усилитель: производство ×2", "uz": "Kuchaytirgich katak: ishlab chiqarish ×2", "zh": "增益格：产量 ×2", "ko": "부스트 칸: 생산량 ×2"},
	"tile_heal": {"tr": "Şifa karosu: bariyeri onarır", "en": "Heal tile: repairs the barrier", "ru": "Клетка лечения: чинит барьер", "uz": "Shifo katagi: toʻsiqni tiklaydi", "zh": "治疗格：修复屏障", "ko": "회복 칸: 장벽을 회복해요"},
	# Ekosistem
	"eco_title": {"tr": "Ekosistem durumu", "en": "Ecosystem status", "ru": "Состояние экосистемы", "uz": "Ekotizim holati", "zh": "生态系统状态", "ko": "생태계 상태"},
	"diversity": {"tr": "Çeşitlilik bonusu: ×{v}", "en": "Diversity bonus: ×{v}", "ru": "Бонус разнообразия: ×{v}", "uz": "Xilma-xillik bonusi: ×{v}", "zh": "多样性加成：×{v}", "ko": "다양성 보너스: ×{v}"},
	"barrier_trend": {"tr": "Bariyer: %{v} ({t}/sn)", "en": "Barrier: {v}% ({t}/s)", "ru": "Барьер: {v}% ({t}/с)", "uz": "Toʻsiq: {v}% ({t}/s)", "zh": "屏障：{v}%（{t}/秒）", "ko": "장벽: {v}% ({t}/초)"},
	"threats": {"tr": "Tehditler", "en": "Threats", "ru": "Угрозы", "uz": "Tahdidlar", "zh": "威胁", "ko": "위협"},
	"friends": {"tr": "Dost bakteriler", "en": "Friendly bacteria", "ru": "Полезные бактерии", "uz": "Doʻst bakteriyalar", "zh": "友好细菌", "ko": "친구 박테리아"},
	"none": {"tr": "Yok", "en": "None", "ru": "Нет", "uz": "Yoʻq", "zh": "无", "ko": "없음"},
	"eco_tip_low": {"tr": "İpucu: Daha çok tür ekle, bonus büyüsün!", "en": "Tip: add more species to grow the bonus!", "ru": "Совет: добавь больше видов для бонуса!", "uz": "Maslahat: bonus uchun koʻproq tur qoʻshing!", "zh": "提示：增加更多物种以提高加成！", "ko": "팁: 더 많은 종을 추가해 보너스를 키우세요!"},
	# Geliştirmeler
	"up_tap": {"tr": "Güçlü dokunuş", "en": "Strong tap", "ru": "Сильное касание", "uz": "Kuchli bosish", "zh": "强力点击", "ko": "강한 터치"},
	"up_tap_d": {"tr": "Dokunuş hasarı +1", "en": "Tap damage +1", "ru": "Урон касания +1", "uz": "Bosish zarari +1", "zh": "点击伤害 +1", "ko": "터치 피해 +1"},
	"up_prod": {"tr": "Verimli sindirim", "en": "Efficient digestion", "ru": "Эффективное пищеварение", "uz": "Samarali hazm", "zh": "高效消化", "ko": "효율적 소화"},
	"up_prod_d": {"tr": "Tüm üretim +%15", "en": "All production +15%", "ru": "Всё производство +15%", "uz": "Barcha ishlab chiqarish +15%", "zh": "全部产量 +15%", "ko": "모든 생산량 +15%"},
	"up_immune": {"tr": "Bağışıklık devriyesi", "en": "Immune patrol", "ru": "Иммунный патруль", "uz": "Immun patrul", "zh": "免疫巡逻", "ko": "면역 순찰"},
	"up_immune_d": {"tr": "Her 5 sn tüm mikroplara hasar", "en": "Damages all germs every 5 s", "ru": "Каждые 5 с урон всем микробам", "uz": "Har 5 s da barcha mikroblarga zarar", "zh": "每 5 秒伤害所有坏细菌", "ko": "5초마다 모든 세균에 피해"},
	"up_offline": {"tr": "Uzun dinlenme", "en": "Long rest", "ru": "Долгий отдых", "uz": "Uzoq dam", "zh": "长时休息", "ko": "긴 휴식"},
	"up_offline_d": {"tr": "Çevrimdışı kazanç süresi +1 saat", "en": "Offline earnings time +1 hour", "ru": "Офлайн-доход +1 час", "uz": "Oflayn daromad vaqti +1 soat", "zh": "离线收益时长 +1 小时", "ko": "오프라인 수익 시간 +1시간"},
	"up_barrier": {"tr": "Kalın mukus", "en": "Thick mucus", "ru": "Плотная слизь", "uz": "Qalin shilliq", "zh": "厚实黏液", "ko": "두꺼운 점액"},
	"up_barrier_d": {"tr": "Mikropların bariyer hasarı −%10", "en": "Germ barrier damage −10%", "ru": "Урон барьеру от микробов −10%", "uz": "Mikroblar toʻsiq zarari −10%", "zh": "坏细菌对屏障伤害 −10%", "ko": "세균의 장벽 피해 −10%"},
	"buy": {"tr": "Al: {v}", "en": "Buy: {v}", "ru": "Купить: {v}", "uz": "Olish: {v}", "zh": "购买：{v}", "ko": "구매: {v}"},
	"maxed": {"tr": "Tamamlandı", "en": "Maxed", "ru": "Максимум", "uz": "Toʻliq", "zh": "已满", "ko": "최대"},
	"lv_short": {"tr": "Sv.{v}", "en": "Lv.{v}", "ru": "Ур.{v}", "uz": "D.{v}", "zh": "Lv.{v}", "ko": "Lv.{v}"},
	# Hediye
	"gift_title": {"tr": "Günlük hediye", "en": "Daily gift", "ru": "Ежедневный подарок", "uz": "Kunlik sovgʻa", "zh": "每日礼物", "ko": "일일 선물"},
	"gift_body": {"tr": "2 dakika boyunca üretim ×2 ve +5 lif!", "en": "Production ×2 for 2 minutes and +5 fiber!", "ru": "Производство ×2 на 2 минуты и +5 клетчатки!", "uz": "2 daqiqa davomida ishlab chiqarish ×2 va +5 tola!", "zh": "2 分钟内产量 ×2，外加 5 纤维！", "ko": "2분 동안 생산량 ×2, 식이섬유 +5!"},
	"gift_claim": {"tr": "Hediyeyi al", "en": "Claim gift", "ru": "Забрать подарок", "uz": "Sovgʻani olish", "zh": "领取礼物", "ko": "선물 받기"},
	"gift_wait": {"tr": "Sonraki hediye: {v}", "en": "Next gift in {v}", "ru": "Следующий подарок через {v}", "uz": "Keyingi sovgʻa: {v}", "zh": "下次礼物：{v}", "ko": "다음 선물까지 {v}"},
	"boost_active": {"tr": "×2 aktif: {v}", "en": "×2 active: {v}", "ru": "×2 активно: {v}", "uz": "×2 faol: {v}", "zh": "×2 生效中：{v}", "ko": "×2 적용 중: {v}"},
	# Çevrimdışı
	"offline_title": {"tr": "Sen yokken…", "en": "While you were away…", "ru": "Пока тебя не было…", "uz": "Siz yoʻqligingizda…", "zh": "你离开的时候……", "ko": "자리를 비운 동안…"},
	"offline_body": {"tr": "Kolonin {t} boyunca çalıştı.", "en": "Your colony worked for {t}.", "ru": "Колония работала {t}.", "uz": "Koloniyangiz {t} davomida ishladi.", "zh": "你的菌落工作了 {t}。", "ko": "군집이 {t} 동안 일했어요."},
	"offline_cap": {"tr": "(En fazla {v} saat sayılır)", "en": "(Counts up to {v} hours)", "ru": "(Учитывается до {v} ч)", "uz": "(Koʻpi bilan {v} soat hisoblanadi)", "zh": "（最多计算 {v} 小时）", "ko": "(최대 {v}시간까지 계산)"},
	"claim": {"tr": "Topla", "en": "Collect", "ru": "Собрать", "uz": "Yigʻish", "zh": "领取", "ko": "받기"},
	# Oyun bitti
	"gameover_title": {"tr": "Bariyer çöktü!", "en": "Gut barrier lost!", "ru": "Барьер разрушен!", "uz": "Toʻsiq qulab tushdi!", "zh": "肠道屏障失守！", "ko": "장벽이 무너졌어요!"},
	"gameover_body": {"tr": "Mikroplar kazandı. Daha dengeli bir bağırsak için yeniden dene!", "en": "The germs won this time. Try again for a healthier balance!", "ru": "На этот раз победили микробы. Попробуй снова!", "uz": "Bu safar mikroblar yutdi. Yana urinib koʻring!", "zh": "这次坏细菌赢了。再试一次，打造更平衡的肠道！", "ko": "이번엔 세균이 이겼어요. 다시 도전해 보세요!"},
	"gameover_score": {"tr": "Skor: {v}", "en": "Score: {v}", "ru": "Счёт: {v}", "uz": "Natija: {v}", "zh": "得分：{v}", "ko": "점수: {v}"},
	"try_again": {"tr": "Yeniden dene", "en": "Try again", "ru": "Ещё раз", "uz": "Qayta urinish", "zh": "再试一次", "ko": "다시 하기"},
	"revive": {"tr": "Kurtar (besinin yarısı)", "en": "Rescue (half your nutrients)", "ru": "Спасти (половина питания)", "uz": "Qutqarish (ozuqaning yarmi)", "zh": "救援（消耗一半营养）", "ko": "구조하기 (영양분 절반)"},
	# Ayarlar
	"language": {"tr": "Dil", "en": "Language", "ru": "Язык", "uz": "Til", "zh": "语言", "ko": "언어"},
	"lang_auto": {"tr": "Telefona göre", "en": "Phone default", "ru": "Как в системе", "uz": "Telefon boʻyicha", "zh": "跟随系统", "ko": "기기 설정"},
	"theme": {"tr": "Görünüm", "en": "Theme", "ru": "Тема", "uz": "Koʻrinish", "zh": "外观", "ko": "테마"},
	"theme_auto": {"tr": "Otomatik", "en": "Auto", "ru": "Авто", "uz": "Avto", "zh": "自动", "ko": "자동"},
	"theme_light": {"tr": "Açık", "en": "Light", "ru": "Светлая", "uz": "Yorugʻ", "zh": "浅色", "ko": "라이트"},
	"theme_dark": {"tr": "Koyu", "en": "Dark", "ru": "Тёмная", "uz": "Qorongʻi", "zh": "深色", "ko": "다크"},
	"sound": {"tr": "Ses efektleri", "en": "Sound effects", "ru": "Звуковые эффекты", "uz": "Ovoz effektlari", "zh": "音效", "ko": "효과음"},
	"music": {"tr": "Müzik", "en": "Music", "ru": "Музыка", "uz": "Musiqa", "zh": "音乐", "ko": "음악"},
	"vibration": {"tr": "Titreşim", "en": "Vibration", "ru": "Вибрация", "uz": "Tebranish", "zh": "振动", "ko": "진동"},
	"privacy": {"tr": "Gizlilik politikası", "en": "Privacy policy", "ru": "Политика конфиденциальности", "uz": "Maxfiylik siyosati", "zh": "隐私政策", "ko": "개인정보 처리방침"},
	"reset": {"tr": "İlerlemeyi sıfırla", "en": "Reset progress", "ru": "Сбросить прогресс", "uz": "Jarayonni tiklash", "zh": "重置进度", "ko": "진행 초기화"},
	"reset_q": {"tr": "Tüm ilerleme silinsin mi? Bu geri alınamaz.", "en": "Delete all progress? This can't be undone.", "ru": "Удалить весь прогресс? Это нельзя отменить.", "uz": "Barcha jarayon oʻchirilsinmi? Buni qaytarib boʻlmaydi.", "zh": "要删除全部进度吗？此操作无法撤销。", "ko": "모든 진행을 삭제할까요? 되돌릴 수 없어요."},
	"reset_yes": {"tr": "Sıfırla", "en": "Reset", "ru": "Сбросить", "uz": "Tiklash", "zh": "重置", "ko": "초기화"},
	"reset_done": {"tr": "İlerleme sıfırlandı", "en": "Progress reset", "ru": "Прогресс сброшен", "uz": "Jarayon tiklandi", "zh": "进度已重置", "ko": "진행이 초기화됐어요"},
	# Hakkında
	"about_body": {"tr": "Micro-Biome Tycoon, mikrobiyom temalı eğlence amaçlı bir kurgu oyunudur. Karakterler stilize maskotlardır; oyun tıbbi bilgi, sağlık tavsiyesi veya bilimsel doğruluk iddiası içermez.", "en": "Micro-Biome Tycoon is a playful work of fiction with a microbiome theme. The characters are stylised mascots; the game offers no medical information, health advice or claims of scientific accuracy.", "ru": "Micro-Biome Tycoon — развлекательная выдуманная игра на тему микробиома. Персонажи — стилизованные талисманы; игра не содержит медицинской информации, советов о здоровье или научных утверждений.", "uz": "Micro-Biome Tycoon — mikrobiom mavzusidagi koʻngilochar toʻqima oʻyin. Qahramonlar stilize maskotlar; oʻyin tibbiy maʼlumot, sogʻliq boʻyicha maslahat yoki ilmiy aniqlik daʼvosini bermaydi.", "zh": "Micro-Biome Tycoon 是一款以微生物组为主题的娱乐虚构游戏。角色均为风格化吉祥物；游戏不提供医疗信息、健康建议，也不声称科学准确。", "ko": "Micro-Biome Tycoon은 마이크로바이옴을 주제로 한 재미용 허구 게임이에요. 캐릭터는 스타일화된 마스코트이며, 의료 정보나 건강 조언, 과학적 정확성을 제공하지 않아요."},
	"about_data": {"tr": "Reklam yok. Veri toplanmaz; ilerlemen yalnızca bu cihazda saklanır ve internet izni kullanılmaz.", "en": "No ads. No data is collected; your progress stays on this device and the game uses no internet permission.", "ru": "Без рекламы. Данные не собираются; прогресс хранится только на устройстве, разрешение на интернет не используется.", "uz": "Reklama yoʻq. Maʼlumot yigʻilmaydi; jarayoningiz faqat shu qurilmada saqlanadi va internet ruxsati ishlatilmaydi.", "zh": "无广告。不收集任何数据；进度只保存在本设备上，游戏不使用网络权限。", "ko": "광고 없음. 데이터를 수집하지 않으며, 진행 상황은 이 기기에만 저장되고 인터넷 권한을 쓰지 않아요."},
	"developer": {"tr": "Geliştirici: matali", "en": "Developer: matali", "ru": "Разработчик: matali", "uz": "Ishlab chiquvchi: matali", "zh": "开发者：matali", "ko": "개발자: matali"},
	"contact": {"tr": "İletişim", "en": "Contact", "ru": "Связаться", "uz": "Aloqa", "zh": "联系我们", "ko": "문의"},
	"engine": {"tr": "Godot Engine ile yapıldı", "en": "Made with Godot Engine", "ru": "Сделано на Godot Engine", "uz": "Godot Engine yordamida yaratilgan", "zh": "使用 Godot 引擎制作", "ko": "Godot 엔진으로 제작"},
	# Bildirim balonları
	"toast_unlocked": {"tr": "Yeni tür açıldı: {v}!", "en": "New species unlocked: {v}!", "ru": "Открыт новый вид: {v}!", "uz": "Yangi tur ochildi: {v}!", "zh": "解锁新物种：{v}！", "ko": "새로운 종 해금: {v}!"},
	"toast_threat": {"tr": "{v} ortaya çıktı!", "en": "{v} appeared!", "ru": "Появился: {v}!", "uz": "{v} paydo boʻldi!", "zh": "{v} 出现了！", "ko": "{v} 등장!"},
	"toast_saved": {"tr": "Kaydedildi", "en": "Saved", "ru": "Сохранено", "uz": "Saqlandi", "zh": "已保存", "ko": "저장됨"},
	"toast_barrier_low": {"tr": "Bariyer zayıflıyor!", "en": "Barrier is getting weak!", "ru": "Барьер слабеет!", "uz": "Toʻsiq zaiflashmoqda!", "zh": "屏障正在变弱！", "ko": "장벽이 약해지고 있어요!"},
	"time_h": {"tr": "{h} sa {m} dk", "en": "{h}h {m}m", "ru": "{h} ч {m} мин", "uz": "{h} soat {m} daq", "zh": "{h} 小时 {m} 分", "ko": "{h}시간 {m}분"},
	"time_m": {"tr": "{m} dk {s} sn", "en": "{m}m {s}s", "ru": "{m} мин {s} с", "uz": "{m} daq {s} s", "zh": "{m} 分 {s} 秒", "ko": "{m}분 {s}초"},
	"time_s": {"tr": "{s} sn", "en": "{s}s", "ru": "{s} с", "uz": "{s} s", "zh": "{s} 秒", "ko": "{s}초"},
}


func _ready() -> void:
	apply_setting("auto")


func detect_system_language() -> String:
	var l: String = OS.get_locale_language().to_lower()
	if l in LANGS:
		return l
	return "en"


func apply_setting(setting: String) -> void:
	var new_lang: String = detect_system_language() if setting == "auto" or not (setting in LANGS) else setting
	if new_lang != lang:
		lang = new_lang
		TranslationServer.set_locale(lang)
		language_changed.emit()


func t(key: String, args: Dictionary = {}) -> String:
	var text: String = key
	if S.has(key):
		var entry: Dictionary = S[key]
		if entry.has(lang):
			text = entry[lang]
		elif entry.has("en"):
			text = entry["en"]
	for k in args.keys():
		text = text.replace("{" + str(k) + "}", str(args[k]))
	return text


func missing_report() -> Array[String]:
	## Test için: eksik çeviri anahtarlarını listeler.
	var out: Array[String] = []
	for key in S.keys():
		var entry: Dictionary = S[key]
		for l in LANGS:
			if not entry.has(l) or str(entry[l]).strip_edges() == "":
				out.append("%s/%s" % [key, l])
	return out
