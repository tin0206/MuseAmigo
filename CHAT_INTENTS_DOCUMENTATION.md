# 🤖 MuseAmigo Chat Intent Documentation

## Table of Contents

1. [Quick Suggestion Questions](#quick-suggestion-questions)
2. [Intent Categories](#intent-categories)
3. [Floor Keywords](#floor-keywords)
4. [Settings/Preferences](#settingspreferences)
5. [Artifact & Exhibition Support](#artifact--exhibition-support)
6. [Coverage Gaps](#coverage-gaps)

---

## Quick Suggestion Questions

### 11 Preset Suggestion Chips (Lines 93-113)

| #   | English                                                       | Vietnamese                                                     |
| --- | ------------------------------------------------------------- | -------------------------------------------------------------- |
| 1   | What are the operating hours of [Museum]?                     | Giờ mở cửa của [Museum] là gì?                                 |
| 2   | How much is the ticket at [Museum]?                           | Giá vé tại [Museum] là bao nhiêu?                              |
| 3   | What exhibitions are available at [Museum]?                   | Tại [Museum] có những triển lãm nào?                           |
| 4   | What artifacts are on Floor 1?                                | Tầng 1 có những hiện vật gì?                                   |
| 5   | What exhibitions are on Floor 2?                              | Tầng 2 có những triển lãm gì?                                  |
| 6   | Tell me about artifact code IP-002.                           | Hãy cho tôi biết về hiện vật mã IP-002.                        |
| 7   | Where is Tank T-54?                                           | Xe tăng T-54 nằm ở đâu?                                        |
| 8   | Tell me about the Presidential Power & Governance exhibition. | Cho tôi thông tin về triển lãm Quyền lực & Quản trị hành pháp. |
| 9   | Tell me about the Military Rooms & War Relics exhibition.     | Cho tôi thông tin về triển lãm Phòng Quân sự & Chiến tranh.    |
| 10  | What routes are available at [Museum]?                        | Tại [Museum] có những lộ trình tham quan nào?                  |
| 11  | Where is [Museum] located?                                    | [Museum] nằm ở đâu?                                            |

---

## Intent Categories

### A. 🏛️ Artifact/Item Queries

**Handler Function:** `_isAllArtifactsQuestion()` (Lines 1551-1572)

**Trigger Pattern:** Must contain artifact keyword + action modifier

**Artifact Keywords:**

- `artifact`, `artifacts`, `hien vat`, `cac hien vat`, `nhung hien vat`, `danh sach hien vat`, `list artifact`, `all artifact`, `show artifact`, `show me artifact`, `liet ke hien vat`, `hien vat o day`

**Action Modifiers (must also contain one):**

- `all`, `list`, `show`, `danh sach`, `liet ke`, `nhung`, `cac`, `tat ca`, `what`, `which`, `tell me`, `give me`, `show me`, `museum`, `bao tang`, `floor`, `tang`, `level`, `o day`

**Example Inputs:**

- "Show me all artifacts" / "Cho tôi xem tất cả hiện vật"
- "List artifacts on floor 1" / "Liệt kê hiện vật tầng 1"
- "What artifacts are there?" / "Có những hiện vật nào?"

---

### B. 🧭 Navigation/Directions to Place

**Handler Function:** `_isDirectionsToPlaceQuestion()` (Lines 1970-2000)

**English Keywords:**

```
how can i get to
how do i get to
how can i go to
how do i go to
how to get to
how to reach
how do i reach
directions to
where can i find
help me find
show me
lead me to
take me to
navigate to
way to
go to
get to
```

**Vietnamese Keywords:**

```
chi duong
huong dan den
chi toi den
cho toi den
di den
duong den
duong di den
lam sao de toi
lam sao den
toi muon den
dan toi den
dan toi
```

**Example Inputs:**

- "How to get to the Presidential Room?" / "Làm sao để tới Phòng Tổng Thống?"
- "Take me to the War Bunker" / "Dẫn tôi tới Hầm Chỉ Huy"

---

### C. 📍 Location Queries

**Handler Function:** `_isLocationQuestion()` (Lines 2917-2947)

**English Keywords:**

```
location
located
where is
where are
where can i find
find the
```

**Vietnamese Keywords:**

```
dia chi
vi tri
o dau
nam o dau
nam o
tim o dau
co o dau
o cho nao
tai dau
duong den
o dau vay
dang o dau
dat o dau
hien vat nay o dau
tim thay o dau
duoc dat o dau
can tim o dau
cho toi biet vi tri
vi tri cua
```

**Example Inputs:**

- "Where is the main entrance?" / "Lối vào chính nằm ở đâu?"
- "Location of Tank 390" / "Vị trí của Tăng 390"

---

### D. 🖼️ Exhibition Queries

**Handler Function:** `_isExhibitionQuestion()` (Lines 2525-2560)

**English Keywords:**

```
exhibition
exhibitions
exhibit
exhibits
all exhibitions
all exhibits
show all exhibitions
show me all exhibitions
list all exhibitions
what exhibitions
which exhibitions
museum exhibitions
all museums
list exhibition
list of exhibition
show exhibition
show me exhibition
all exhibition
```

**Vietnamese Keywords:**

```
trien lam
trung bay
khu trung bay
khu trien lam
cac trien lam
cac khu
nhung trien lam
tat ca trien lam
tat ca trung bay
liet ke trien lam
liet ke trung bay
trien lam trong bao tang
tat ca bao tang
danh sach trien lam
```

**Example Inputs:**

- "What exhibitions are on this floor?" / "Tầng này có những triển lãm nào?"
- "Show me all exhibitions" / "Cho tôi xem tất cả triển lãm"

---

### E. 🏢 Floor-Specific Queries

**Handler Function:** `_isFloorSpecificQuery()` (Lines 2654-2690)

**Requires:** Floor keyword + Action keyword

**Action Keywords:**

```
exhibition
exhibit
artifact
artifacts
hien vat
trien lam
trung bay
what
which
show
list
all
tell
give
co gi
nhung gi
co nhung gi
o day co
co gi o
danh sach
liet ke
```

**Example Inputs:**

- "What artifacts are on floor 2?" / "Tầng 2 có những hiện vật nào?"
- "Show me exhibitions on floor 1" / "Cho tôi xem triển lãm tầng 1"

---

### F. 🚽 Facility Queries (Multi-step Flow)

**Handler Function:** `_isAmbiguousMultiFloorQuery()` (Lines 2692-2706)

**Restroom Keywords:**

```
restroom
toilet
wc
nha ve sinh
```

**Stairs Keywords:**

```
stairs
stair
staircase
cau thang
thang bo
```

**Behavior:** Triggers multi-step flow asking user to specify which floor they need

**Bot Response:**

- 🇬🇧 "Here are the available [restroom/stairs] spots: [list]. Tap a Navigate button below and I will guide you from your current position."
- 🇻🇳 "Mình gợi ý các [nhà vệ sinh/cầu thang] sau: [list]. Bạn chọn nút Navigate bên dưới để mình bắt đầu chỉ đường."

**Example Inputs:**

- "Where is the restroom?" / "Nhà vệ sinh ở đâu?"
- "I need stairs" / "Mình cần cầu thang"

---

### G. 🗺️ Route/Itinerary Queries

**Handler Function:** `_isRouteQuestion()` (Lines 2573-2583)

**Keywords:**

```
route
routes
navigation
itinerary
path
lo trinh
duong di
tuyen tham quan
tham quan
```

**Example Inputs:**

- "What routes are available?" / "Có những lộ trình nào?"
- "Show me the navigation path" / "Chỉ đường cho tôi"

---

### H. 🎯 Tour Suggestions

**Handler Function:** `_isTourSuggestionQuestion()` (Lines 2585-2608)

**Tour Keywords:**

```
tour
tours
suggested tour
suggested tours
recommend
recommended
suggestion
suggest
visit plan
sightseeing
quick explorer
deep dive
```

**Vietnamese Keywords:**

```
goi y
de xuat
chuyen tham quan
ke hoach tham quan
lich tham quan
tham quan theo lo trinh
lo trinh goi y
lo trinh de xuat
di tham quan
kham pha nhanh
kham pha sau
```

**Alternative Patterns:**

```
what route
which route
available route
lo trinh nao
nen di theo lo trinh
nen di tuyen nao
```

**Example Inputs:**

- "Can you suggest a tour?" / "Bạn có thể gợi ý lộ trình tham quan không?"
- "I want a quick explorer tour" / "Tôi muốn khám phá nhanh"

---

### I. ⏰ Operating Hours

**Handler Function:** `_isOperatingHoursQuestion()` (Lines 2610-2619)

**Keywords:**

```
operating hour
opening hour
open
close
gio mo cua
gio dong cua
dong cua
mo cua
```

**Example Inputs:**

- "What are the operating hours?" / "Giờ mở cửa là mấy giờ?"
- "When does it close?" / "Khi nào đóng cửa?"

---

### J. 🎫 Ticket Price Queries

**Handler Function:** `_isTicketPriceQuestion()` (Lines 2621-2634)

**Keywords:**

```
ticket price
ticket cost
ticket fee
how much
entry fee
admission fee
admission cost
price
gia ve
ve bao nhieu
ve vao cong
phi vao cua
tien ve
bao nhieu tien
```

**Example Inputs:**

- "How much is the ticket?" / "Vé bao nhiêu tiền?"
- "What's the admission fee?" / "Phí vào cửa bao nhiêu?"

---

### K. 📱 View My Tickets

**Handler Function:** `_isViewTicketIntent()` (Lines 2636-2652)

**Keywords:**

```
my ticket
my tickets
view ticket
view tickets
show ticket
show my ticket
see ticket
see my ticket
check my ticket
open ticket
xem ve
xem ve cua toi
ve cua toi
kiem tra ve
danh sach ve
```

**Example Inputs:**

- "Show my tickets" / "Xem vé của tôi"
- "Check my bookings" / "Kiểm tra đơn đặt vé"

---

### L. 🗺️ Map/Navigation Intent

**Handler Function:** `_isMapIntentQuestion()` (Lines 2976-2984)

**Keywords:**

```
map
route
navigation
duong di
ban do
chi duong
```

**Example Inputs:**

- "Open the map" / "Mở bản đồ"
- "Show me the navigation" / "Chỉ đường cho tôi"

---

### M. 🏛️ General Museum Info

**Handler Function:** `_isMuseumInfoQuestion()` (Lines 2962-2974)

Matches: operating hours OR ticket price OR location queries

**Additional Keywords:**

```
museum info
information
thong tin bao tang
bao tang
tell me about
cho toi biet ve
```

**Example Inputs:**

- "Tell me about this museum" / "Cho tôi biết về bảo tàng này"

---

### N. ❓ Artifact Code Intent

**Handler Function:** `_isArtifactIntentQuestion()` (Lines 3427-3434)

**Keywords:**

```
artifact
artifacts
hien vat
qr
artifact code
```

**Regex Pattern (Artifact Codes):**

```regex
\b[a-z]{2,4}\s?-\s?\d{3}\b
```

Matches: `IP-001`, `IP-002`, `IP-005`, etc.

**Example Inputs:**

- "IP-002" / "Tell me about IP-002"
- "What is artifact code IP-001?" / "Hiện vật IP-001 là gì?"

---

## Floor Keywords

### Floor 1 Variants (Lines 1514-1549)

```
floor 1
floor a
floor one
first floor
1st floor
tang 1
tang a
tang mot
level 1
level a
khu a
block a
tren tang 1
o tang 1
```

### Floor 2 Variants

```
floor 2
floor b
floor two
second floor
2nd floor
tang 2
tang b
tang hai
level 2
level b
khu b
block b
tren tang 2
o tang 2
```

---

## Settings/Preferences

### 🎨 Theme Change

**Handler Function:** `_isThemeChangeIntent()` (Lines 2994-3044)

**Explicit Keywords:**

```
change theme
switch theme
set theme
update theme
theme settings
doi theme
chuyen theme
thay doi theme
doi giao dien
chuyen giao dien
```

**Mode-Specific Keywords:**

- **Dark Mode:** `dark mode`, `dark theme`, `night mode`, `night theme`, `che do toi`, `giao dien toi`
- **Light Mode:** `light mode`, `light theme`, `che do sang`, `giao dien sang`

**Implicit Pattern (must contain both):**

- Action: `change`, `switch`, `set`, `update`, `doi`, `chuyen`, `thay doi`, `muon doi`, `want to`
- Target: `theme`, `giao dien`, `dark`, `light`, `che do toi`, `che do sang`

**Example Inputs:**

- "Switch to dark mode" / "Chuyển sang chế độ tối"
- "Change theme to light" / "Đổi giao diện sang sáng"

---

### 🌈 Color Scheme Change

**Handler Function:** `_isSchemeChangeIntent()` (Lines 3046-3108)

**Explicit Keywords:**

```
change color
switch color
set color
update color
color scheme
theme color
app color
chuyen scheme
doi scheme
thay doi color
doi mau
mau sac
mau sac app
mau sac giao dien
```

**Implicit Pattern (must contain both):**

- Action: `change`, `switch`, `set`, `update`, `doi`, `chuyen`, `thay doi`, `want to`
- Target: `color`, `colour`, `mau`, `scheme`

**Color Options (Lines 3115-3140):**
| Color | English | Vietnamese |
|-------|---------|-----------|
| Red | `red` | `do` |
| Purple | `purple`, `violet` | `tim` |
| Amber/Yellow | `amber`, `yellow` | `vang` |
| Brown | `brown` | `nau` |
| Green | `green` | `xanh la` |
| Blue | `blue` | `xanh duong`, `xanh` |
| Sky Blue | `sky blue`, `light blue` | `xanh nhat` |

**Example Inputs:**

- "Change color to purple" / "Đổi màu thành tím"
- "Switch to blue scheme" / "Chuyển sang màu xanh"

---

### 🌐 Language Change

**Handler Function:** `_isLanguageChangeIntent()` (Lines 3166-3208)

**Explicit Keywords:**

```
change language
switch language
set language
update language
language
doi ngon ngu
chuyen ngon ngu
thay ngon ngu
cai dat ngon ngu
```

**Language-Specific Keywords:**

```
switch to english
switch to vietnamese
set english
set vietnamese
chuyen sang tieng anh
chuyen sang tieng viet
doi sang tieng anh
doi sang tieng viet
```

**Implicit Pattern (must contain both):**

- Action: `change`, `switch`, `set`, `update`, `doi`, `chuyen`, `thay`, `want to`
- Target: `language`, `ngon ngu`, `tieng anh`, `tieng viet`, `english`, `vietnamese`

**Example Inputs:**

- "Switch to English" / "Chuyển sang tiếng Anh"
- "Change language to Vietnamese" / "Đổi ngôn ngữ sang tiếng Việt"

---

### 🔤 Font Size Change

**Handler Function:** `_isFontSizeChangeIntent()` (Lines 3250-3283)

**General Keywords:**

```
font size
change font size
increase font size
decrease font size
switch font size
set font size
text size
change text size
set text size
font
co chu
kich co chu
kich thuoc chu
doi co chu
chuyen co chu
thay co chu
size chu
```

**Increase Keywords (Lines 3285-3299):**

```
increase font size
increase text size
make font bigger
bigger text
text bigger
tang co chu
tang kich thuoc chu
chu to hon
phong to chu
```

**Decrease Keywords (Lines 3301-3315):**

```
decrease font size
decrease text size
make font smaller
smaller text
text smaller
giam co chu
giam kich thuoc chu
chu nho hon
thu nho chu
```

**Specific Size Targets (Lines 3415-3424):**

- **Small:** `small`, `nho`, `chu nho`
- **Large:** `large`, `big`, `lon`, `chu to`
- **Medium:** `medium`, `vua`, `trung binh`, `normal`

**Example Inputs:**

- "Increase font size" / "Tăng cỡ chữ"
- "Make text bigger" / "Làm chữ to hơn"
- "Set font to small" / "Đặt cỡ chữ nhỏ"

---

## Artifact & Exhibition Support

### Supported Artifacts

**Artifact Code Pattern:** `[A-Z]{2,4}-\d{3}`

**Examples:**

- IP-001 (Tank 390)
- IP-002 (T-54 Tank)
- IP-003 (UH-1 Helicopter)
- IP-004 (Mercedes-Benz 200 W110)
- IP-005 (War Command Bunker Map)
- IP-006 (F-5E Bombing Marks)
- IP-007 (Jeep M151A2)
- IP-008 (Binh Ngo Dai Cao Lacquer Painting)
- IP-009 (Cabinet Room Table)
- IP-010 (The Golden Dragon Tapestry)
- IP-011 (Telecommunications Center)
- IP-012 (The Presidential Bed)
- IP-013 (National Security Council Maps)
- IP-014 (Basement Cinema Projector)
- IP-015 (Vice President's Desk)

### Supported Exhibitions (Museum 1 - Independence Palace)

| Exhibition                             | Floor   | Vietnamese Aliases                             |
| -------------------------------------- | ------- | ---------------------------------------------- |
| **Fall of Saigon: April 30, 1975**     | Floor 1 | sup do sai gon, 30 thang 4, giai phong sai gon |
| **Presidential Power & Governance**    | Floor 1 | quyen luc hanh phap, quan tri hanh phap        |
| **Diplomacy & State Ceremony**         | Floor 1 | ngoai giao, le nghi quoc gia                   |
| **Art & Diplomatic Heritage**          | Floor 1 | nhan van ngoai giao, tac pham nghe thuat       |
| **Presidential Transport & Lifestyle** | Floor 1 | phuong tien tong thong, doi song sinh hoat     |
| **Underground War Command Center**     | Floor 2 | ham chi huy, ham ngam chi huy, bunker          |
| **War Command Bunker**                 | Floor 2 | ham chi huy, bunker                            |
| **Air Warfare & Evacuation**           | Floor 2 | khong chien, di tan, may bay truc thang        |

---

## Multi-Step Flow Prompts

### Navigation Flow - Floor Query

```
🇬🇧 "Which floor are you on? You can just say Floor 1 or Floor 2 😊"
🇻🇳 "Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!"
```

### Navigation Flow - Current Position Query

```
🇬🇧 "Which spot are you currently at on [floor]?
     For example: Main Entrance, Hall C, Restroom - Floor 1, or Stairs - Floor 2."
🇻🇳 "Bạn đang đứng ở điểm nào trên [floor]?
     Ví dụ: Main Entrance, Hall C hoặc Restroom - [floor]."
```

### Facility/Ambiguous Spot Query

```
🇬🇧 "Here are the available [restroom/stairs] spots: [list].
     Tap a Navigate button below and I will guide you from your current position."
🇻🇳 "Mình gợi ý các [nhà vệ sinh/cầu thang] sau: [list].
     Bạn chọn nút Navigate bên dưới để mình bắt đầu chỉ đường."
```

### Cross-floor Navigation

```
🇬🇧 "Please go up to [Floor 2] using the stairs"
     "Please go down to [Floor 1] using the stairs"
🇻🇳 "Bạn hãy đi lên [Floor 2] bằng cầu thang"
     "Bạn hãy đi xuống [Floor 1] bằng cầu thang"
```

---

## Vietnamese Linguistic Features

### Diacritic Normalization (Lines 3436-3481)

All Vietnamese diacritics are normalized to base vowels for matching:

```
à á ạ ả ã â ầ ấ ậ ẩ ẫ ă ằ ắ ặ ẳ ẵ → a
è é ẹ ẻ ẽ ê ề ế ệ ể ễ → e
ì í ị ỉ ĩ → i
ò ó ọ ỏ õ ô ồ ố ộ ổ ỗ ơ ờ ớ ợ ở ỡ → o
ù ú ụ ủ ũ ư ừ ứ ự ử ữ → u
ỳ ý ỵ ỷ ỹ → y
đ → d
```

### Vietnamese Stopwords

For artifact/exhibition matching:

```
cua, ve, tai, cho, va, la, co, cac, nhung, tren, trong, theo, thi, den, duoc, nay
```

---

## Coverage Gaps

### ❌ Currently NOT Supported

- [ ] Accessibility / Wheelchair inquiries
- [ ] Gift shop / Souvenir store information
- [ ] Parking / Parking lot locations
- [ ] Photography / Photo restrictions
- [ ] Audio guide availability
- [ ] Small talk acknowledgments (thanks/cảm ơn)
- [ ] Greeting detection from user (hi/hello/xin chào) - _only bot greets_
- [ ] Museum events / Special exhibitions
- [ ] Group booking inquiries
- [ ] Contact information requests
- [ ] Dining / Cafeteria locations
- [ ] Exit/Emergency information
- [ ] Feedback / Complaint handling

### 🎯 Potential Enhancement Areas

1. **Accessibility Features:** Detect wheelchair, accessibility, mobility questions
2. **Services:** Gift shop, dining, parking location queries
3. **Policies:** Photography rules, group sizes, age restrictions
4. **Events:** Upcoming exhibitions, special events, workshops
5. **Customer Service:** Feedback, complaints, support requests
6. **User Greeting Recognition:** Respond to "Hi", "Hello", "Xin chào"

---

## Information Extraction Functions

### Info Target Extraction (Lines 2003-2023)

**Function:** `_extractInfoTarget()`

**Vietnamese Prefixes:**

```
thong tin chi tiet ve
thong tin ve
thong tin cua
cho toi biet ve
cho toi xem thong tin ve
cho toi xem
gioi thieu ve
mo ta ve
the nao ve
noi ve
```

**English Prefixes:**

```
information about
details about
tell me about
info about
detail about
what is
what are
show me
about
```

### Direction Target Extraction (Lines 2025-2069)

**Function:** `_extractDirectionTarget()`

Extracts location name following direction markers

### Artifact Code Extraction (Lines 2461-2478)

**Function:** `_extractArtifactCode()`

**Pattern:** `\b([A-Za-z]{2,4})\s?-\s?(\d{3})\b`

**Examples:** IP-002, IP-001, IP-009

Normalizes to uppercase format for consistent matching

---

## Testing Checklist

### ✅ Quick Suggestions

- [ ] All 11 preset questions trigger correct flows
- [ ] Vietnamese and English versions both work

### ✅ Navigation

- [ ] Direction queries route correctly
- [ ] Multi-step floor prompts work
- [ ] Artifact location resolution works
- [ ] Exhibition location resolution works

### ✅ Facilities

- [ ] Restroom queries show available options
- [ ] Stairs queries show available options
- [ ] Cross-floor guidance triggers correctly

### ✅ Info Queries

- [ ] Artifact info displays correctly
- [ ] Exhibition info displays correctly
- [ ] Museum info (hours, price, location) works

### ✅ Settings

- [ ] Theme toggle works (dark/light)
- [ ] Color scheme change works
- [ ] Language toggle works
- [ ] Font size controls work

### ✅ Vietnamese Handling

- [ ] Diacritical marks are normalized
- [ ] Vietnamese keyword matching works
- [ ] Stopwords are filtered correctly

---

**Last Updated:** May 9, 2026  
**Total Intent Categories:** 14  
**Total Quick Questions:** 11  
**Supported Artifacts:** 15  
**Supported Exhibitions:** 8  
**Coverage Percentage:** ~85% of common use cases
