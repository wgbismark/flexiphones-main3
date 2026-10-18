// const user_1 = {
//   "status": "success",
//   "message": "Login successful.",
//   "data": {
//     "customer_id": 1,
//     "name": "Enoch Tetteh Bosomprah",
//     "email": "etbosomprah@gmail.com",
//     "token": "1|CEC9vPw1toZ5xQT7NdxVNd0hr8ONOqd2IvCyPwcx9722d76e",
//   },
// };

// const products_1 = {
//   "status": "success",
//   "message": "Products retrieved successfully",
//   "products": {
//     "data": [
//       {
//         "id": 3,
//         "model": "GALAXY A13 5G",
//         "brand": "SAMSUNG",
//         "colors": "{BLACK, BLUE, WHITE}",
//         "image": ["products/qQohmKjZge0PtrgN5ev2SbEIMBaxsWZXfnPIrqSV.jpg"],
//         "status": "Available",
//       },
//       {
//         "id": 4,
//         "model": "GALAXY A54",
//         "brand": "SAMSUNG",
//         "colors": "{LIME, GRAPHITE, VIOLET, WHITE}",
//         "image": ["products/T5kBgKfoJegh8kQch99NVAHHhwhMCmglMgjEbAdT.jpg"],
//         "status": "Available",
//       },
//       {
//         "id": 6,
//         "model": "GALAXY A22",
//         "brand": "SAMSUNG",
//         "colors": "{BLUE, BLACK, WHITE}",
//         "image": ["products/1IIsB05Oe9SzqNMOfjoVrMdaZ1fxBwIgTl28jlkI.jpg"],
//         "status": "Available",
//       },
//     ],
//     "path": "https://portal.flexiphones.app/api/v1/get-products",
//     "per_page": 15,
//     "next_cursor": null,
//     "next_page_url": null,
//     "prev_cursor": null,
//     "prev_page_url": null,
//   },
// };

// const vendors_1 = {
//   "status": "success",
//   "message": "Vendors retrieved successfully",
//   "vendors": {
//     "data": [
//       {
//         "id": 1,
//         "name": "Norchs BMS",
//         "email": "etbosomprah@gmail.com",
//         "phone_number": "0543680103",
//         "image": null,
//         "location": "New Achimota",
//         "opening_time": "09:00:00",
//         "closing_time": "22:00:00",
//         "status": "active",
//         "created_at": "2025-06-19T10:15:27.000000Z",
//         "updated_at": "2025-06-19T10:15:27.000000Z",
//         "deleted_at": null,
//       },
//     ],
//     "path": "https://portal.flexiphones.app/api/v1/get-vendors",
//     "per_page": 15,
//     "next_cursor": null,
//     "next_page_url": null,
//     "prev_cursor": null,
//     "prev_page_url": null,
//   },
// };

final List<String> suggestedLocations = [
  // Ahafo Region
  'mim',
  'goaso',
  'bechem',
  'duayaw_nkwanta',
  'techimantia',
  'kenyasi',
  'hwidiem',
  'acherensua',
  'akrodie',
  'asumura',
  'bedabour',
  'derma',
  'ebenezer',
  'kasapin',
  'kwapong',
  'kukuom',
  'new_brosankro',
  'new_sayereso',
  'nkaseim',
  'ntotroso',
  'nyameyeadom',
  'sankore',
  'tanoso',
  'yamfo',
  'sunyani', // Also listed in some sources as part of former Brong-Ahafo
  'prang', // Also listed in some sources as part of former Brong-Ahafo
  'nkoranza', // Also listed in some sources as part of former Brong-Ahafo
  // Ashanti Region
  'kumasi',
  'obuasi',
  'ejura',
  'tafo',
  'mampong',
  'konongo',
  'agogo',
  'ejisu',
  'suame',
  'bantama',
  'new_edubiase',
  'effiduase',
  'bonwire',
  'juaban',
  'juaso',
  'kasei',
  'kodie',
  'kokofu',
  'kumawu',
  'kuntanase',
  'kwadaso',
  'maabang',
  'mamponteng',
  'mankranso',
  'manso_adubia',
  'manso_atwere',
  'manso_nkwanta',
  'mpasatia',
  'aduagyama',
  'asokwa', // Major district in Kumasi
  'kortwia_abodom', // Town in Ashanti
  'kwaso', // Town in Ashanti
  // Bono Region
  'sunyani',
  'berekum',
  'wenchi',
  'sampa',
  'drobo',
  'dormaa_ahenkro', // Principal town
  'odumasi', // Principal town
  'adamsu', // Town in Bono
  'ammassu', // Town in Bono
  'atronie', // Town in Bono
  'babianiha', // Town in Bono
  'badu', // Town in Bono
  'chiraa', // Town in Bono
  'debibi', // Town in Bono
  'fiapre', // Town in Bono
  'japekrom', // Town in Bono
  'jinijini', // Town in Bono
  'kyeremasu', // Town in Bono
  'new_drobo', // Town in Bono
  'nkrankwanta', // Town in Bono
  'nsawkaw', // Town in Bono
  'nsoatre', // Town in Bono
  'seikwa', // Town in Bono
  'banda_ahenkro', // Capital of Banda District
  // Bono East Region
  'techiman',
  'kintampo',
  'nkoranza',
  'jema',
  'prang',
  'atebubu', // Top town
  'yeji', // Important town
  'akropong', // Town in Bono East
  'amantin', // Town in Bono East
  'apesika', // Town in Bono East
  'bomini', // Town in Bono East
  'busunya', // Town in Bono East
  'dama_nkwanta', // Town in Bono East
  'donkro_nkwanta', // Town in Bono East
  'agyina', // Town in Bono East
  'offuman', // Town in Bono East
  'buoyem', // Town in Bono East
  'sene_west', // District in Bono East
  'sene_east', // District in Bono East
  // Central Region
  'cape_coast',
  'elmina',
  'winneba',
  'mankessim',
  'ansafo',
  'agona_swedru', // Major city
  'kasoa', // Top town
  'dunkwa_on_offin', // Major city
  'apam', // Major city
  'saltpond', // Major city
  'nyakrom', // Major city
  'foso', // Major city
  'mumford', // Major city
  'anomabu', // Major city
  'oduponkpehe', // Major city
  'komenda', // Town in Central
  'kormantse', // Town in Central
  'kwamankese', // Town in Central
  'moree', // Town in Central
  'mozano', // Town in Central
  'abenze', // Historical town
  'duakwa', // Historical town
  'mensa_krom', // Historical town
  // Eastern Region
  'koforidua',
  'suhum',
  'nsawam',
  'nkawkaw',
  'akim_oda',
  'omonkro',
  'akyem_asinase',
  'adeiso', // Major commercialized town
  'asamankese', // Major city
  'akosombo', // Major city
  'kwahu_nkwatia', // Major city
  'kade', // Town in Eastern
  'kibi', // Town in Eastern
  'kitase_akuapem', // Town in Eastern
  'koforidua_asokore', // Town in Eastern
  'koforidua_effiduase', // Town in Eastern
  'kpong', // Town in Eastern
  'krobo_odumase', // Town in Eastern
  'kukurantumi', // Town in Eastern
  'anyaboni', // Town in Eastern
  'denkyembour', // Town in Eastern
  // Greater Accra Region
  'accra',
  'tema',
  'prampram',
  'tafra',
  'teshie',
  'nungua',
  'ashiaman',
  'dodowa',
  'ningo',
  'la',
  'osu',
  'adenta',
  'ledzokuku',
  'dansoman',
  'kasoa',
  'madina',
  'gba',
  'weija',
  'lartebiokorshie',
  'latebiokorshie',
  'nima',
  'ayawaso',
  'ablekuma',
  'okaikwei',
  'odododiodioo',
  'ashiedu',
  'okaikoi',
  'ga_east',
  'ga_west',
  'ada_east',
  'ada_west',
  'shai_osudoku',
  'la_dade_kotopon',
  'la_nkwantanang_madina',
  'arabella',
  'bankuman',
  'kokrobite',
  'lapaz',
  'tuba_junction',
  'nim_tree_circle',
  'new_barrier',
  'old_barrier',
  'ayigbe_town',
  'bojo_beach',

  // North East Region
  'nalerigu',
  'gambaga',
  'bunkpurugu',
  'bima', // Major city
  'chereponi', // Major city
  'dimi', // Major city
  'walewale', // Town in North East
  'yagaba', // Town in North East
  'gbimsi', // Town in North East ,
  // Northern Region
  'tamale',
  'yendi',
  'savelugu',
  'kumbungu',
  'zabzugu',
  'lboom',
  'nyankpala', // Major city
  'kpandae', // Major city
  'bimbilla', // Major city
  'buya', // Major city
  'gushiegu', // District capital
  'karaga', // District capital
  'target', // Community in Tamale
  'ticheli', // Community in Northern Region
  'saboba', // Town in Northern
  'sang', // Town in Northern
  'santa', // Town in Northern
  'sheini', // Town in Northern
  'shienga', // Town in Northern
  'sumniboma', // Town in Northern
  'tatale', // Town in Northern
  'tolon', // Town in Northern
  'wulensi', // Town in Northern
  'yapei', // Town in Northern
  'adibo', // Town in Northern
  'daboya', // Town in Northern
  'kambali', // Town in Northern
  // Oti Region
  'dambai',
  'krachi',
  'biatri',
  'nkwanta',
  'jasikan', // Top town
  'kete_krachi', // Top town
  'kadjebi', // Top town
  'biakoye', // District capital
  'chinderi', // District capital
  'nkonya', // Town in Oti
  'nkonya_ahenkro', // Town in Oti
  'okadjakrom', // Town in Oti
  'tapa_abotoase', // Town in Oti
  'teteman', // Town in Oti
  'worawora', // Town in Oti
  // Savannah Region
  'damongo',
  'bole',
  'sataviaso',
  'veniyili',
  'buipe', // Major city
  'daboya', // Major city
  'bamboi', // Major town
  'maluwe', // Major town
  'tinga', // Major town
  'tasilma', // Major town
  'mandari', // Major town
  'banda_nkwanta', // Major town
  'sawla', // Town in Savannah
  'zebilla', // Town in Savannah
  'kpembe', // Town in Savannah
  'kulmasa', // Town in Savannah
  'larabanga', // Town in Savannah
  'lukula', // Town in Savannah
  'mempeasem', // Town in Savannah
  'old_buipe', // Town in Savannah
  'salaga', // Town in Savannah
  // Upper East Region
  'bolgatanga',
  'navrongo',
  'bawku',
  'tongu',
  'zuarungu',
  'paga', // Top town
  'sandema', // Major town
  'zebilla', // Top town
  'tempane', // District in Upper East
  'pusiga', // District in Upper East
  'garu', // Major town
  'pwalugu', // Major town
  'tongo', // Major town
  'kongo', // Major town
  'belingogo', // Town in Upper East
  'binaba', // Town in Upper East
  'builsa', // Town in Upper East
  'dabila', // Town in Upper East
  // Upper West Region
  'wa',
  'lawra',
  'jirapa',
  'lambussie',
  'nandom', // Top town
  'tumu', // Top town
  'daffiema', // Major town
  'kaleo', // Major town
  'nadowli', // Major town
  'bugubelle', // Town in Upper West
  'charia', // Town in Upper West
  'doung', // Town in Upper West
  'funsi', // Town in Upper West
  'hamile', // Town in Upper West
  'han', // Town in Upper West
  'jeffisi', // Town in Upper West
  'eregon', // Town in Upper West
  'gworlu', // Town in Upper West
  // Volta Region
  'ho',
  'hohoe',
  'kpando',
  'keta',
  'aflao',
  'amele',
  'aregade',
  'anloga', // Major city
  'kpandu', // Major city
  'sogakope', // Major town
  'dodji', // Major market town
  'kpassa', // Major market town
  'dzodze', // Border town
  'akatsi', // District capital
  'abor', // Town in Volta
  'abutia_kpota', // Town in Volta
  'abutia_teti', // Town in Volta
  'adafienu', // Town in Volta
  'adaklu', // Town in Volta
  'adaklu_waya', // Town in Volta
  'adidome', // Town in Volta
  'agbozume', // Town in Volta
  'agortime_kpetoe', // Town in Volta
  'akome', // Town in Volta
  // Western Region
  'sekondi_takoradi',
  'axim',
  'cape_three_points',
  'essikado',
  'nkwanta',
  'tarkwa', // Top town
  'bogoso', // Top town
  'aboadze', // Town in Western
  'aboso', // Town in Western
  'adiembra', // Town in Western
  'adubrim', // Town in Western
  'adum_banso', // Town in Western
  'airport_ridge', // Town in Western
  'akotom', // Town in Western
  'anaji', // Town in Western
  'apowa', // Town in Western
  'apremodo', // Town in Western
  'asankragua', // Town in Western
  'ebonloa', // Town in Western
  'mpatabo', // Town in Western
  'bakakole_nkwanta', // Town in Western
  'ahobre', // Town in Western
  'nawule', // Town in Western
  'allowule', // Town in Western
  'tikobo_no1', // Town in Western
  'edu', // Town in Western
  'damofu', // Town in Western
  'ave_lenu', // Town in Western
  // Western North Region
  'sefwi_wiawso',
  'bibiani',
  'sefwi_adabokrom',
  'sefwi_esiso',
  'ench', // Top town
  'juaboso', // Top town
  'adabokrom', // Top town
  'dadieso', // Town in Western North
  'essam', // Town in Western North
  'sefwi_akontombra', // Town in Western North
  'sefwi_bodi', // Town in Western North
  'abokyea', // Town in Western North
  'achimfo', // Town in Western North
  'akotombra_nkwanta', // Town in Western North
  'amoya', // Town in Western North
  'antubia', // Town in Western North
  'asawinso', // Town in Western North
  'asempanaye', // Town in Western North
  'awaso', // Town in Western North
  'aowin', // District in Western North
  'suaman', // District in Western North
  'bia_east', // District in Western North
  'bia_west', // District in Western North
  'bodi', // District in Western North
  'akontombra', // District in Western North
];
