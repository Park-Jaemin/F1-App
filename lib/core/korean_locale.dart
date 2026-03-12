/// ISO 3166-1 alpha-3 → alpha-2 변환 맵 (F1 관련 국가 포함 전체 목록)
const Map<String, String> _alpha3ToAlpha2 = {
  'ABW': 'AW', 'AFG': 'AF', 'AGO': 'AO', 'ALB': 'AL', 'AND': 'AD',
  'ARE': 'AE', 'ARG': 'AR', 'ARM': 'AM', 'AUS': 'AU', 'AUT': 'AT',
  'AZE': 'AZ', 'BDI': 'BI', 'BEL': 'BE', 'BEN': 'BJ', 'BFA': 'BF',
  'BGD': 'BD', 'BGR': 'BG', 'BHR': 'BH', 'BHS': 'BS', 'BIH': 'BA',
  'BLR': 'BY', 'BLZ': 'BZ', 'BOL': 'BO', 'BRA': 'BR', 'BRB': 'BB',
  'BTN': 'BT', 'BWA': 'BW', 'CAF': 'CF', 'CAN': 'CA',
  'CHE': 'CH', 'CHL': 'CL', 'CHN': 'CN', 'CIV': 'CI', 'CMR': 'CM',
  'COD': 'CD', 'COG': 'CG', 'COK': 'CK', 'COL': 'CO', 'CPV': 'CV',
  'CRI': 'CR', 'CUB': 'CU', 'CYP': 'CY', 'CZE': 'CZ', 'DEU': 'DE',
  'DJI': 'DJ', 'DMA': 'DM', 'DNK': 'DK', 'DOM': 'DO', 'DZA': 'DZ',
  'ECU': 'EC', 'EGY': 'EG', 'ERI': 'ER', 'ESP': 'ES', 'EST': 'EE',
  'ETH': 'ET', 'FIN': 'FI', 'FJI': 'FJ', 'FRA': 'FR', 'FRO': 'FO',
  'FSM': 'FM', 'GAB': 'GA', 'GBR': 'GB', 'GEO': 'GE', 'GHA': 'GH',
  'GIB': 'GI', 'GIN': 'GN', 'GMB': 'GM', 'GNB': 'GW', 'GNQ': 'GQ',
  'GRC': 'GR', 'GRD': 'GD', 'GRL': 'GL', 'GTM': 'GT', 'GUY': 'GY',
  'HKG': 'HK', 'HND': 'HN', 'HRV': 'HR', 'HTI': 'HT', 'HUN': 'HU',
  'IDN': 'ID', 'IND': 'IN', 'IRL': 'IE', 'IRN': 'IR', 'IRQ': 'IQ',
  'ISL': 'IS', 'ISR': 'IL', 'ITA': 'IT', 'JAM': 'JM', 'JOR': 'JO',
  'JPN': 'JP', 'KAZ': 'KZ', 'KEN': 'KE', 'KGZ': 'KG', 'KHM': 'KH',
  'KIR': 'KI', 'KNA': 'KN', 'KOR': 'KR', 'KWT': 'KW', 'LAO': 'LA',
  'LBN': 'LB', 'LBR': 'LR', 'LBY': 'LY', 'LCA': 'LC', 'LIE': 'LI',
  'LKA': 'LK', 'LSO': 'LS', 'LTU': 'LT', 'LUX': 'LU', 'LVA': 'LV',
  'MAC': 'MO', 'MAR': 'MA', 'MCO': 'MC', 'MDA': 'MD', 'MDG': 'MG',
  'MDV': 'MV', 'MEX': 'MX', 'MHL': 'MH', 'MKD': 'MK', 'MLI': 'ML',
  'MLT': 'MT', 'MMR': 'MM', 'MNE': 'ME', 'MNG': 'MN', 'MOZ': 'MZ',
  'MRT': 'MR', 'MUS': 'MU', 'MWI': 'MW', 'MYS': 'MY', 'NAM': 'NA',
  'NCL': 'NC', 'NER': 'NE', 'NGA': 'NG', 'NIC': 'NI', 'NIU': 'NU',
  'NLD': 'NL', 'NOR': 'NO', 'NPL': 'NP', 'NRU': 'NR', 'NZL': 'NZ',
  'OMN': 'OM', 'PAK': 'PK', 'PAN': 'PA', 'PER': 'PE', 'PHL': 'PH',
  'PLW': 'PW', 'PNG': 'PG', 'POL': 'PL', 'PRK': 'KP', 'PRT': 'PT',
  'PRY': 'PY', 'PSE': 'PS', 'QAT': 'QA', 'ROU': 'RO', 'RUS': 'RU',
  'RWA': 'RW', 'SAU': 'SA', 'SDN': 'SD', 'SEN': 'SN', 'SGP': 'SG',
  'SHN': 'SH', 'SLB': 'SB', 'SLE': 'SL', 'SLV': 'SV', 'SMR': 'SM',
  'SOM': 'SO', 'SRB': 'RS', 'SSD': 'SS', 'STP': 'ST', 'SUR': 'SR',
  'SVK': 'SK', 'SVN': 'SI', 'SWE': 'SE', 'SWZ': 'SZ', 'SYC': 'SC',
  'SYR': 'SY', 'TCD': 'TD', 'TGO': 'TG', 'THA': 'TH', 'TJK': 'TJ',
  'TKM': 'TM', 'TLS': 'TL', 'TON': 'TO', 'TTO': 'TT', 'TUN': 'TN',
  'TUR': 'TR', 'TUV': 'TV', 'TWN': 'TW', 'TZA': 'TZ', 'UGA': 'UG',
  'UKR': 'UA', 'URY': 'UY', 'USA': 'US', 'UZB': 'UZ', 'VAT': 'VA',
  'VCT': 'VC', 'VEN': 'VE', 'VNM': 'VN', 'VUT': 'VU', 'WSM': 'WS',
  'YEM': 'YE', 'ZAF': 'ZA', 'ZMB': 'ZM', 'ZWE': 'ZW',
  // F1/OpenF1에서 사용하는 비표준 코드 (FIA/IOC/FIFA 기반)
  'MON': 'MC', // 모나코 (표준은 MCO)
  'SUI': 'CH', // 스위스 (표준은 CHE)
  'DEN': 'DK', // 덴마크 (표준은 DNK)
  'BRN': 'BH', // 바레인 (OpenF1 사용, 표준은 BHR)
  'KSA': 'SA', // 사우디아라비아 (OpenF1 사용, 표준은 SAU)
  'NED': 'NL', // 네덜란드 (OpenF1 사용, 표준은 NLD)
  'UAE': 'AE', // 아랍에미리트 (OpenF1 사용, 표준은 ARE)
  'GER': 'DE', // 독일 (IOC 코드, 표준은 DEU)
  'POR': 'PT', // 포르투갈 (IOC 코드, 표준은 PRT)
  'CRO': 'HR', // 크로아티아 (IOC 코드, 표준은 HRV)
  'GRE': 'GR', // 그리스 (IOC 코드, 표준은 GRC)
  'MAS': 'MY', // 말레이시아 (IOC 코드, 표준은 MYS)
  'TPE': 'TW', // 타이완 (IOC 코드, 표준은 TWN)
  'CHI': 'CN', // 중국 (IOC 대안 코드)
  'RSA': 'ZA', // 남아프리카공화국 (IOC 코드, 표준은 ZAF)
  'SLO': 'SI', // 슬로베니아 (IOC 코드, 표준은 SVN)
  'ANG': 'AO', // 앙골라 (IOC 코드, 표준은 AGO)
};

/// 3자리 또는 2자리 국가코드를 받아 국기 이모지를 반환합니다.
String countryCodeToFlag(String code) {
  if (code.isEmpty) return '';
  final upper = code.toUpperCase();
  final alpha2 = upper.length == 2 ? upper : (_alpha3ToAlpha2[upper] ?? upper.substring(0, 2));
  if (alpha2.length < 2) return '';
  const offset = 0x1F1E6 - 0x41;
  return String.fromCharCodes(alpha2.codeUnits.take(2).map((c) => c + offset));
}

/// F1 그랑프리 한국어 이름 (meeting_name 기준)
const Map<String, String> kGrandPrixNames = {
  'Bahrain Grand Prix': '바레인 그랑프리',
  'Saudi Arabian Grand Prix': '사우디아라비아 그랑프리',
  'Australian Grand Prix': '호주 그랑프리',
  'Japanese Grand Prix': '일본 그랑프리',
  'Chinese Grand Prix': '중국 그랑프리',
  'Miami Grand Prix': '마이애미 그랑프리',
  'Emilia-Romagna Grand Prix': '에밀리아 로마냐 그랑프리',
  'Monaco Grand Prix': '모나코 그랑프리',
  'Canadian Grand Prix': '캐나다 그랑프리',
  'Spanish Grand Prix': '스페인 그랑프리',
  'Austrian Grand Prix': '오스트리아 그랑프리',
  'British Grand Prix': '영국 그랑프리',
  'Hungarian Grand Prix': '헝가리 그랑프리',
  'Belgian Grand Prix': '벨기에 그랑프리',
  'Dutch Grand Prix': '네덜란드 그랑프리',
  'Italian Grand Prix': '이탈리아 그랑프리',
  'Singapore Grand Prix': '싱가포르 그랑프리',
  'Qatar Grand Prix': '카타르 그랑프리',
  'United States Grand Prix': '미국 그랑프리',
  'Mexico City Grand Prix': '멕시코시티 그랑프리',
  'Mexican Grand Prix': '멕시코 그랑프리',
  'São Paulo Grand Prix': '상파울루 그랑프리',
  'Brazilian Grand Prix': '브라질 그랑프리',
  'Las Vegas Grand Prix': '라스베이거스 그랑프리',
  'Abu Dhabi Grand Prix': '아부다비 그랑프리',
  'Azerbaijan Grand Prix': '아제르바이잔 그랑프리',
  'Turkish Grand Prix': '터키 그랑프리',
  'Bahrain Virtual Grand Prix': '바레인 가상 그랑프리',
  'Styrian Grand Prix': '슈타이어마르크 그랑프리',
};

/// F1 드라이버 한국어 이름 (name_acronym 기준)
const Map<String, String> kDriverNames = {
  'VER': '막스 베르스타펜',
  'HAM': '루이스 해밀턴',
  'LEC': '샤를 르끌레르',
  'NOR': '랜도 노리스',
  'SAI': '카를로스 사인츠',
  'RUS': '조지 러셀',
  'PER': '세르히오 페레스',
  'ALO': '페르난도 알론소',
  'GAS': '피에르 가슬리',
  'OCO': '에스테반 오콘',
  'STR': '랜스 스트롤',
  'TSU': '츠노다 유키',
  'ALB': '알렉산더 알본',
  'BOT': '발테리 보타스',
  'ZHO': '저우 관위',
  'HUL': '니코 휠켄베르크',
  'MAG': '케빈 마그누센',
  'RIC': '다니엘 리카르도',
  'LAW': '리암 로슨',
  'SAR': '로건 사전트',
  'BEA': '올리버 베어먼',
  'COL': '프랑코 콜라핀토',
  'ANT': '키미 안토넬리',
  'HAD': '아이작 하자르',
  'DOO': '잭 두한',
  'BOR': '가브리엘 보톨레토',
  'PIA': '오스카 피아스트리',
  'MSC': '믹 슈마허',
  'VET': '세바스티안 베텔',
  'RAI': '키미 라이코넨',
  'GIO': '안토니오 조비나치',
  'MAZ': '니키타 마제핀',
  'GRO': '로맹 그로장',
  'KVY': '다닐 크비야트',
  'DEV': '닉 더브리스',
  'FIT': '피에르 필리피',
  'WEH': '파스칼 베흘라인',
  'ERI': '마르쿠스 에릭손',
  'CHI': '쑤밍하오',
  'LIN': '아비드 린드블라드',
};

/// F1 팀 한국어 이름
const Map<String, String> kTeamNames = {
  'Red Bull Racing': '레드불 레이싱',
  'Mercedes': '메르세데스',
  'Ferrari': '페라리',
  'McLaren': '맥라렌',
  'Aston Martin': '애스턴 마틴',
  'Alpine': '알핀',
  'Williams': '윌리엄스',
  'AlphaTauri': '알파타우리',
  'Visa Cash App RB': 'VCARB',
  'Racing Bulls': '레이싱 불스',
  'RB': '레이싱 불스',
  'Alfa Romeo': '알파 로메오',
  'Kick Sauber': '킥 자우버',
  'Haas F1 Team': '하스 F1 팀',
  'Haas': '하스 F1 팀',
  'Racing Point': '레이싱 포인트',
  'Renault': '르노',
  'Toro Rosso': '토로 로소',
  'Force India': '포스 인디아',
  'Sauber': '자우버',
  'Lotus F1 Team': '로터스 F1 팀',
  'Audi': '아우디',
  'Cadillac': '캐딜락'
};

/// F1 세션 한국어 이름
const Map<String, String> kSessionNames = {
  'Practice 1': '연습 주행 1',
  'Practice 2': '연습 주행 2',
  'Practice 3': '연습 주행 3',
  'Qualifying': '퀄리파잉',
  'Sprint Shootout': '스프린트 슈트아웃',
  'Sprint Qualifying': '스프린트 퀄리파잉',
  'Sprint': '스프린트',
  'Race': '레이스',
};

/// 그랑프리 이름을 한국어로 반환합니다. 매핑이 없으면 원본 반환.
String localizeGrandPrix(String meetingName) {
  if (kGrandPrixNames.containsKey(meetingName)) {
    return kGrandPrixNames[meetingName]!;
  }
  // 부분 일치 시도
  for (final entry in kGrandPrixNames.entries) {
    if (meetingName.contains(entry.key.replaceAll(' Grand Prix', '')) &&
        meetingName.contains('Grand Prix')) {
      return entry.value;
    }
  }
  return meetingName;
}

/// 세션 이름을 한국어로 반환합니다.
String localizeSession(String sessionName) {
  return kSessionNames[sessionName] ?? sessionName;
}

/// 드라이버 이름을 한국어로 반환합니다. 매핑이 없으면 broadcastName 반환.
String localizeDriver(String nameAcronym, String broadcastName) {
  return kDriverNames[nameAcronym] ?? broadcastName;
}

/// 팀 이름을 한국어로 반환합니다. 매핑이 없으면 원본 반환.
String localizeTeam(String teamName) {
  return kTeamNames[teamName] ?? teamName;
}
