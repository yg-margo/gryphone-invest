class CompanyDescriptions {
  static String get(String symbol, {bool isRussian = true}) {
    final map = isRussian ? _ru : _en;
    return map[symbol] ?? (isRussian ? 'Описание недоступно.' : 'Description not available.');
  }

  static const Map<String, String> _ru = {
    'AAPL':
        'Apple Inc. — одна из крупнейших технологических компаний мира, основанная в 1976 году Стивом Джобсом, Стивом Возняком и Рональдом Уэйном. Компания проектирует, производит и продаёт смартфоны (iPhone), персональные компьютеры (Mac), планшеты (iPad), носимые устройства (Apple Watch, AirPods) и предоставляет широкий спектр сервисов: App Store, Apple Music, iCloud, Apple TV+. Apple является одной из немногих компаний, чья рыночная капитализация превысила 3 триллиона долларов. Штаб-квартира расположена в Купертино, Калифорния.',

    'MSFT':
        'Microsoft Corporation — глобальная технологическая корпорация, основанная в 1975 году Биллом Гейтсом и Полом Алленом. Компания разрабатывает операционные системы (Windows), офисное программное обеспечение (Microsoft 365), облачные сервисы (Azure), игровые платформы (Xbox) и профессиональную социальную сеть LinkedIn. Microsoft является лидером в сфере облачных вычислений и активно инвестирует в искусственный интеллект, в том числе через стратегическое партнёрство с OpenAI. Штаб-квартира расположена в Редмонде, штат Вашингтон.',

    'GOOGL':
        'Alphabet Inc. — холдинговая компания, созданная в 2015 году как реструктуризация Google. Основные активы включают поисковую систему Google, занимающую более 90% мирового рынка, видеохостинг YouTube, мобильную ОС Android, облачную платформу Google Cloud, а также ряд венчурных проектов под брендом Other Bets. Компания получает большую часть доходов за счёт цифровой рекламы. Alphabet активно развивает направления ИИ (Gemini), автономного вождения (Waymo) и квантовых вычислений. Штаб-квартира — Маунтин-Вью, Калифорния.',

    'NVDA':
        'NVIDIA Corporation — американская компания, специализирующаяся на разработке графических процессоров (GPU), систем искусственного интеллекта и высокопроизводительных вычислительных платформ. Основана в 1993 году Дженсеном Хуангом. GPU серии GeForce стали стандартом для игровой индустрии, а чипы серии A100 и H100 — основой для обучения крупнейших ИИ-моделей в мире. NVIDIA доминирует на рынке ускорителей для машинного обучения с долей свыше 80%. Штаб-квартира расположена в Санта-Кларе, Калифорния.',

    'AMZN':
        'Amazon.com Inc. — крупнейшая в мире компания в сфере электронной коммерции и облачных вычислений, основанная Джеффом Безосом в 1994 году как онлайн-магазин книг. Сегодня Amazon управляет глобальной торговой платформой, подписочным сервисом Prime, стриминговым сервисом Amazon Prime Video, а также Amazon Web Services (AWS) — лидирующим провайдером облачных услуг с долей рынка около 32%. Компания также развивает направления логистики, умных устройств (Alexa, Echo) и здравоохранения. Штаб-квартира — Сиэтл, Вашингтон.',

    'TSLA':
        'Tesla Inc. — американская компания, производящая электромобили, системы накопления энергии и солнечные панели. Основана в 2003 году, с 2008 года возглавляется Илоном Маском. Tesla выпускает модели Model S, 3, X, Y, Cybertruck и Semi. Компания также разрабатывает технологии автономного вождения Autopilot и Full Self-Driving, а через дочернее подразделение Megapack поставляет промышленные аккумуляторы. Tesla является крупнейшим в мире производителем электромобилей по объёму продаж. Штаб-квартира расположена в Остине, Техас.',

    'META':
        'Meta Platforms Inc. — технологический холдинг, управляющий крупнейшими социальными сетями мира: Facebook (3+ млрд пользователей), Instagram и мессенджером WhatsApp. Основана Марком Цукербергом в 2004 году. В 2021 году компания сменила название с Facebook на Meta, обозначив курс на развитие метавселенной через платформу Horizon Worlds и VR-устройства серии Quest. Meta получает основной доход от таргетированной рекламы и активно инвестирует в искусственный интеллект (Llama) и AR/VR-технологии. Штаб-квартира — Менло-Парк, Калифорния.',

    'NFLX':
        'Netflix Inc. — мировой лидер в сфере стримингового видео с более чем 260 миллионами подписчиков в 190+ странах. Компания основана в 1997 году Ридом Хастингсом как сервис доставки DVD, а в 2007 году запустила онлайн-стриминг. Netflix производит оригинальный контент (сериалы, фильмы, документалистику) под собственным брендом, включая такие хиты, как «Игра в кальмара», «Корона» и «Очень странные дела». Компания активно внедряет рекламную модель подписки и борьбу с шерингом паролей. Штаб-квартира — Лос-Гатос, Калифорния.',

    'JPM':
        'JPMorgan Chase & Co. — крупнейший банк США и один из крупнейших финансовых институтов мира с активами свыше 3,9 триллиона долларов. Основан в результате слияния J.P. Morgan и Chase Manhattan в 2000 году. Компания предоставляет полный спектр финансовых услуг: розничный и корпоративный банкинг, инвестиционно-банковские услуги, управление активами и частный банкинг. Банк обслуживает миллионы клиентов по всему миру и является ключевым игроком на мировых рынках капитала. Штаб-квартира расположена в Нью-Йорке.',

    'BRK.B':
        'Berkshire Hathaway Inc. — диверсифицированный холдинг под управлением легендарного инвестора Уоррена Баффета, который возглавляет компанию с 1965 года. Холдинг полностью владеет такими компаниями, как GEICO, BNSF Railway, Berkshire Hathaway Energy и Dairy Queen, а также держит крупные пакеты акций Apple, Bank of America, Coca-Cola и American Express. Berkshire известна долгосрочной инвестиционной стратегией, фокусом на компаниях с устойчивыми конкурентными преимуществами и минимальным использованием заёмного капитала. Штаб-квартира — Омаха, Небраска.',
  };

  static const Map<String, String> _en = {
    'AAPL':
        'Apple Inc. is one of the world\'s largest technology companies, founded in 1976 by Steve Jobs, Steve Wozniak, and Ronald Wayne. The company designs, manufactures, and sells smartphones (iPhone), personal computers (Mac), tablets (iPad), wearables (Apple Watch, AirPods), and a wide range of services including the App Store, Apple Music, iCloud, and Apple TV+. Apple is one of the few companies whose market capitalization has exceeded \$3 trillion. Headquartered in Cupertino, California.',

    'MSFT':
        'Microsoft Corporation is a global technology corporation founded in 1975 by Bill Gates and Paul Allen. The company develops operating systems (Windows), productivity software (Microsoft 365), cloud services (Azure), gaming platforms (Xbox), and the professional network LinkedIn. Microsoft is a leader in cloud computing and is heavily investing in artificial intelligence, including through a strategic partnership with OpenAI. Headquartered in Redmond, Washington.',

    'GOOGL':
        'Alphabet Inc. is a holding company created in 2015 as a restructuring of Google. Core assets include the Google search engine with over 90% global market share, YouTube, the Android mobile OS, the Google Cloud platform, and a range of moonshot projects under Other Bets. The company generates most of its revenue through digital advertising. Alphabet is actively developing AI (Gemini), autonomous driving (Waymo), and quantum computing. Headquartered in Mountain View, California.',

    'NVDA':
        'NVIDIA Corporation is an American company specializing in graphics processing units (GPUs), AI systems, and high-performance computing platforms. Founded in 1993 by Jensen Huang. GeForce GPUs became the standard for the gaming industry, while A100 and H100 chips are the backbone for training the world\'s largest AI models. NVIDIA dominates the machine learning accelerator market with over 80% share. Headquartered in Santa Clara, California.',

    'AMZN':
        'Amazon.com Inc. is the world\'s largest e-commerce and cloud computing company, founded by Jeff Bezos in 1994 as an online bookstore. Today Amazon operates a global marketplace, the Prime subscription service, Amazon Prime Video streaming, and Amazon Web Services (AWS) — the leading cloud provider with approximately 32% market share. The company also develops logistics, smart devices (Alexa, Echo), and healthcare solutions. Headquartered in Seattle, Washington.',

    'TSLA':
        'Tesla Inc. is an American company that manufactures electric vehicles, energy storage systems, and solar panels. Founded in 2003 and led by Elon Musk since 2008. Tesla produces the Model S, 3, X, Y, Cybertruck, and Semi. The company also develops Autopilot and Full Self-Driving autonomous driving technologies, and through its Megapack division supplies industrial-scale batteries. Tesla is the world\'s largest EV manufacturer by volume. Headquartered in Austin, Texas.',

    'META':
        'Meta Platforms Inc. is a technology holding company operating the world\'s largest social networks: Facebook (3+ billion users), Instagram, and WhatsApp. Founded by Mark Zuckerberg in 2004. In 2021 the company rebranded from Facebook to Meta, signaling a push into the metaverse through the Horizon Worlds platform and Quest VR devices. Meta earns the majority of its revenue from targeted advertising and is investing heavily in artificial intelligence (Llama) and AR/VR technologies. Headquartered in Menlo Park, California.',

    'NFLX':
        'Netflix Inc. is the world\'s leading streaming video service with more than 260 million subscribers in 190+ countries. Founded in 1997 by Reed Hastings as a DVD delivery service, it launched online streaming in 2007. Netflix produces original content under its own brand, including global hits such as Squid Game, The Crown, and Stranger Things. The company is actively rolling out an ad-supported subscription tier and cracking down on password sharing. Headquartered in Los Gatos, California.',

    'JPM':
        'JPMorgan Chase & Co. is the largest bank in the United States and one of the world\'s largest financial institutions with assets exceeding \$3.9 trillion. Formed through the merger of J.P. Morgan and Chase Manhattan in 2000, the company provides a full spectrum of financial services including retail and commercial banking, investment banking, asset management, and private banking. The bank serves millions of clients worldwide and is a key player in global capital markets. Headquartered in New York City.',

    'BRK.B':
        'Berkshire Hathaway Inc. is a diversified holding company managed by legendary investor Warren Buffett, who has led the company since 1965. The conglomerate wholly owns companies such as GEICO, BNSF Railway, Berkshire Hathaway Energy, and Dairy Queen, and holds major stakes in Apple, Bank of America, Coca-Cola, and American Express. Berkshire is known for its long-term investment philosophy, focus on companies with durable competitive advantages, and minimal use of debt. Headquartered in Omaha, Nebraska.',
  };
}
