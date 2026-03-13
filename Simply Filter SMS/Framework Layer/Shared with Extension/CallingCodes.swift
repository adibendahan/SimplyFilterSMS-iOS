//
//  CallingCodes.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/03/2026.
//

import Foundation


// MARK: - CallingCodeEntry Enum

/// Each case represents a country or group of countries sharing an ITU calling code.
enum CallingCodeEntry: CaseIterable {

    // MARK: Cases (grouped by region)

    // Americas
    case nanp               // +1  — North America (NANP)
    case peru               // +51
    case mexico             // +52
    case cuba               // +53
    case argentina          // +54
    case brazil             // +55
    case chile              // +56
    case colombia           // +57
    case venezuela          // +58
    case belize             // +501
    case guatemala          // +502
    case elSalvador         // +503
    case honduras           // +504
    case nicaragua          // +505
    case costaRica          // +506
    case panama             // +507
    case saintPierreMiquelon // +508
    case haiti              // +509
    case guadeloupe         // +590
    case bolivia            // +591
    case guyana             // +592
    case ecuador            // +593
    case frenchGuiana       // +594
    case paraguay           // +595
    case martinique         // +596
    case suriname           // +597
    case uruguay            // +598
    case netherlandsAntilles // +599

    // Europe
    case russiaKazakhstan   // +7
    case greece             // +30
    case netherlands        // +31
    case belgium            // +32
    case france             // +33
    case spain              // +34
    case hungary            // +36
    case italy              // +39
    case romania            // +40
    case switzerland        // +41
    case austria            // +43
    case unitedKingdom      // +44
    case denmark            // +45
    case sweden             // +46
    case norway             // +47
    case poland             // +48
    case germany            // +49
    case gibraltar          // +350
    case portugal           // +351
    case luxembourg         // +352
    case ireland            // +353
    case iceland            // +354
    case albania            // +355
    case malta              // +356
    case cyprus             // +357
    case finland            // +358
    case bulgaria           // +359
    case lithuania          // +370
    case latvia             // +371
    case estonia            // +372
    case moldova            // +373
    case armenia            // +374
    case belarus            // +375
    case andorra            // +376
    case monaco             // +377
    case sanMarino          // +378
    case ukraine            // +380
    case serbia             // +381
    case montenegro         // +382
    case kosovo             // +383
    case croatia            // +385
    case slovenia           // +386
    case bosniaHerzegovina  // +387
    case northMacedonia     // +389
    case czechRepublic      // +420
    case slovakia           // +421
    case liechtenstein      // +423
    case falklandIslands    // +500
    case faroeIslands       // +298
    case greenland          // +299

    // Africa
    case egypt              // +20
    case southAfrica        // +27
    case morocco            // +212
    case algeria            // +213
    case tunisia            // +216
    case libya              // +218
    case gambia             // +220
    case senegal            // +221
    case mauritania         // +222
    case mali               // +223
    case guinea             // +224
    case ivoryCoast         // +225
    case burkinaFaso        // +226
    case niger              // +227
    case togo               // +228
    case benin              // +229
    case mauritius          // +230
    case liberia            // +231
    case sierraLeone        // +232
    case ghana              // +233
    case nigeria            // +234
    case chad               // +235
    case centralAfricanRepublic // +236
    case cameroon           // +237
    case capeVerde          // +238
    case saoTomePrincipe    // +239
    case equatorialGuinea   // +240
    case gabon              // +241
    case congo              // +242
    case drc                // +243
    case angola             // +244
    case guineaBissau       // +245
    case britishIndianOceanTerritory // +246
    case ascensionIsland    // +247
    case seychelles         // +248
    case sudan              // +249
    case rwanda             // +250
    case ethiopia           // +251
    case somalia            // +252
    case djibouti           // +253
    case kenya              // +254
    case tanzania           // +255
    case uganda             // +256
    case burundi            // +257
    case mozambique         // +258
    case zambia             // +260
    case madagascar         // +261
    case reunionMayotte     // +262
    case zimbabwe           // +263
    case namibia            // +264
    case malawi             // +265
    case lesotho            // +266
    case botswana           // +267
    case eswatini           // +268
    case comoros            // +269
    case saintHelena        // +290
    case eritrea            // +291
    case aruba              // +297

    // Asia-Pacific
    case malaysia           // +60
    case australia          // +61
    case indonesia          // +62
    case philippines        // +63
    case newZealand         // +64
    case singapore          // +65
    case thailand           // +66
    case japan              // +81
    case southKorea         // +82
    case vietnam            // +84
    case china              // +86
    case turkey             // +90
    case india              // +91
    case pakistan           // +92
    case afghanistan        // +93
    case sriLanka           // +94
    case myanmar            // +95
    case iran               // +98
    case timorLeste         // +670
    case norfolkIsland      // +672
    case brunei             // +673
    case nauru              // +674
    case papuaNewGuinea     // +675
    case tonga              // +676
    case solomonIslands     // +677
    case vanuatu            // +678
    case fiji               // +679
    case palau              // +680
    case wallisAndFutuna    // +681
    case cookIslands        // +682
    case niue               // +683
    case samoa              // +685
    case kiribati           // +686
    case newCaledonia       // +687
    case tuvalu             // +688
    case frenchPolynesia    // +689
    case tokelau            // +690
    case micronesia         // +691
    case marshallIslands    // +692
    case northKorea         // +850
    case hongKong           // +852
    case macau              // +853
    case cambodia           // +855
    case laos               // +856
    case bangladesh         // +880
    case taiwan             // +886

    // Middle East
    case israel             // +972
    case maldives           // +960
    case lebanon            // +961
    case jordan             // +962
    case syria              // +963
    case iraq               // +964
    case kuwait             // +965
    case saudiArabia        // +966
    case yemen              // +967
    case oman               // +968
    case palestine          // +970
    case uae                // +971
    case bahrain            // +973
    case qatar              // +974
    case bhutan             // +975
    case mongolia           // +976
    case nepal              // +977
    case tajikistan         // +992
    case turkmenistan       // +993
    case azerbaijan         // +994
    case georgia            // +995
    case kyrgyzstan         // +996
    case uzbekistan         // +998


    // MARK: - Computed Properties

    /// Calling code string including the leading '+'.
    var callingCode: String { data.0 }

    /// Human-readable display name, always localized to the current locale.
    /// Single-country entries use the system locale name. Grouped multi-country entries
    /// use an app localization key (e.g. "callingCode_+1") with fallback to the hardcoded name.
    var displayName: String {
        guard isoCountryCodes.count > 1 else {
            return Locale.current.localizedString(forRegionCode: isoCountryCodes[0]) ?? data.1
        }
        let key = "callingCode_\(callingCode)"
        let localized = NSLocalizedString(key, comment: "")
        return localized != key ? localized : data.1
    }

    /// Display name for use in summaries — same as displayName since no suffix is ever appended.
    var summaryName: String { displayName }

    /// ISO 3166-1 alpha-2 codes for the countries in this entry.
    var isoCountryCodes: [String] { data.2 }

    /// Flag emoji derived from the first ISO country code.
    var flagEmoji: String {
        let code = isoCountryCodes.first ?? ""
        guard code.count == 2 else { return "🌍" }
        let base: UInt32 = 127397
        return code.uppercased().unicodeScalars.compactMap {
            Unicode.Scalar(base + $0.value)
        }.map(String.init).joined()
    }

    // MARK: - Lookup

    /// O(1) lookup by calling code string.
    static let byCallingCode: [String: CallingCodeEntry] =
        Dictionary(uniqueKeysWithValues: allCases.map { ($0.callingCode, $0) })


    // MARK: - Private Data

    // swiftlint:disable large_tuple
    private var data: (String, String, [String]) {
        switch self {
        case .nanp:
            return ("+1", "North America", ["US","CA","AG","AI","AS","BB","BL","BM","BS","DM","DO","GD","GU","JM","KN","KY","LC","MF","MP","MS","PR","SX","TC","TT","VC","VG","VI"])
        case .russiaKazakhstan:
            return ("+7", "Russia & Kazakhstan", ["RU","KZ"])
        case .egypt:
            return ("+20", "Egypt", ["EG"])
        case .southAfrica:
            return ("+27", "South Africa", ["ZA"])
        case .greece:
            return ("+30", "Greece", ["GR"])
        case .netherlands:
            return ("+31", "Netherlands", ["NL"])
        case .belgium:
            return ("+32", "Belgium", ["BE"])
        case .france:
            return ("+33", "France", ["FR"])
        case .spain:
            return ("+34", "Spain", ["ES"])
        case .hungary:
            return ("+36", "Hungary", ["HU"])
        case .italy:
            return ("+39", "Italy", ["IT"])
        case .romania:
            return ("+40", "Romania", ["RO"])
        case .switzerland:
            return ("+41", "Switzerland", ["CH"])
        case .austria:
            return ("+43", "Austria", ["AT"])
        case .unitedKingdom:
            return ("+44", "United Kingdom", ["GB"])
        case .denmark:
            return ("+45", "Denmark", ["DK"])
        case .sweden:
            return ("+46", "Sweden", ["SE"])
        case .norway:
            return ("+47", "Norway", ["NO","SJ"])
        case .poland:
            return ("+48", "Poland", ["PL"])
        case .germany:
            return ("+49", "Germany", ["DE"])
        case .peru:
            return ("+51", "Peru", ["PE"])
        case .mexico:
            return ("+52", "Mexico", ["MX"])
        case .cuba:
            return ("+53", "Cuba", ["CU"])
        case .argentina:
            return ("+54", "Argentina", ["AR"])
        case .brazil:
            return ("+55", "Brazil", ["BR"])
        case .chile:
            return ("+56", "Chile", ["CL"])
        case .colombia:
            return ("+57", "Colombia", ["CO"])
        case .venezuela:
            return ("+58", "Venezuela", ["VE"])
        case .malaysia:
            return ("+60", "Malaysia", ["MY"])
        case .australia:
            return ("+61", "Australia", ["AU"])
        case .indonesia:
            return ("+62", "Indonesia", ["ID"])
        case .philippines:
            return ("+63", "Philippines", ["PH"])
        case .newZealand:
            return ("+64", "New Zealand", ["NZ"])
        case .singapore:
            return ("+65", "Singapore", ["SG"])
        case .thailand:
            return ("+66", "Thailand", ["TH"])
        case .japan:
            return ("+81", "Japan", ["JP"])
        case .southKorea:
            return ("+82", "South Korea", ["KR"])
        case .vietnam:
            return ("+84", "Vietnam", ["VN"])
        case .china:
            return ("+86", "China", ["CN"])
        case .turkey:
            return ("+90", "Turkey", ["TR"])
        case .india:
            return ("+91", "India", ["IN"])
        case .pakistan:
            return ("+92", "Pakistan", ["PK"])
        case .afghanistan:
            return ("+93", "Afghanistan", ["AF"])
        case .sriLanka:
            return ("+94", "Sri Lanka", ["LK"])
        case .myanmar:
            return ("+95", "Myanmar", ["MM"])
        case .iran:
            return ("+98", "Iran", ["IR"])
        case .morocco:
            return ("+212", "Morocco", ["MA"])
        case .algeria:
            return ("+213", "Algeria", ["DZ"])
        case .tunisia:
            return ("+216", "Tunisia", ["TN"])
        case .libya:
            return ("+218", "Libya", ["LY"])
        case .gambia:
            return ("+220", "Gambia", ["GM"])
        case .senegal:
            return ("+221", "Senegal", ["SN"])
        case .mauritania:
            return ("+222", "Mauritania", ["MR"])
        case .mali:
            return ("+223", "Mali", ["ML"])
        case .guinea:
            return ("+224", "Guinea", ["GN"])
        case .ivoryCoast:
            return ("+225", "Ivory Coast", ["CI"])
        case .burkinaFaso:
            return ("+226", "Burkina Faso", ["BF"])
        case .niger:
            return ("+227", "Niger", ["NE"])
        case .togo:
            return ("+228", "Togo", ["TG"])
        case .benin:
            return ("+229", "Benin", ["BJ"])
        case .mauritius:
            return ("+230", "Mauritius", ["MU"])
        case .liberia:
            return ("+231", "Liberia", ["LR"])
        case .sierraLeone:
            return ("+232", "Sierra Leone", ["SL"])
        case .ghana:
            return ("+233", "Ghana", ["GH"])
        case .nigeria:
            return ("+234", "Nigeria", ["NG"])
        case .chad:
            return ("+235", "Chad", ["TD"])
        case .centralAfricanRepublic:
            return ("+236", "Central African Republic", ["CF"])
        case .cameroon:
            return ("+237", "Cameroon", ["CM"])
        case .capeVerde:
            return ("+238", "Cape Verde", ["CV"])
        case .saoTomePrincipe:
            return ("+239", "São Tomé & Príncipe", ["ST"])
        case .equatorialGuinea:
            return ("+240", "Equatorial Guinea", ["GQ"])
        case .gabon:
            return ("+241", "Gabon", ["GA"])
        case .congo:
            return ("+242", "Republic of the Congo", ["CG"])
        case .drc:
            return ("+243", "DR Congo", ["CD"])
        case .angola:
            return ("+244", "Angola", ["AO"])
        case .guineaBissau:
            return ("+245", "Guinea-Bissau", ["GW"])
        case .britishIndianOceanTerritory:
            return ("+246", "British Indian Ocean Territory", ["IO"])
        case .ascensionIsland:
            return ("+247", "Ascension Island", ["AC"])
        case .seychelles:
            return ("+248", "Seychelles", ["SC"])
        case .sudan:
            return ("+249", "Sudan", ["SD"])
        case .rwanda:
            return ("+250", "Rwanda", ["RW"])
        case .ethiopia:
            return ("+251", "Ethiopia", ["ET"])
        case .somalia:
            return ("+252", "Somalia", ["SO"])
        case .djibouti:
            return ("+253", "Djibouti", ["DJ"])
        case .kenya:
            return ("+254", "Kenya", ["KE"])
        case .tanzania:
            return ("+255", "Tanzania", ["TZ"])
        case .uganda:
            return ("+256", "Uganda", ["UG"])
        case .burundi:
            return ("+257", "Burundi", ["BI"])
        case .mozambique:
            return ("+258", "Mozambique", ["MZ"])
        case .zambia:
            return ("+260", "Zambia", ["ZM"])
        case .madagascar:
            return ("+261", "Madagascar", ["MG"])
        case .reunionMayotte:
            return ("+262", "Reunion & Mayotte", ["RE","YT"])
        case .zimbabwe:
            return ("+263", "Zimbabwe", ["ZW"])
        case .namibia:
            return ("+264", "Namibia", ["NA"])
        case .malawi:
            return ("+265", "Malawi", ["MW"])
        case .lesotho:
            return ("+266", "Lesotho", ["LS"])
        case .botswana:
            return ("+267", "Botswana", ["BW"])
        case .eswatini:
            return ("+268", "Eswatini", ["SZ"])
        case .comoros:
            return ("+269", "Comoros", ["KM"])
        case .saintHelena:
            return ("+290", "Saint Helena (+290)", ["SH"])
        case .eritrea:
            return ("+291", "Eritrea", ["ER"])
        case .aruba:
            return ("+297", "Aruba", ["AW"])
        case .faroeIslands:
            return ("+298", "Faroe Islands", ["FO"])
        case .greenland:
            return ("+299", "Greenland", ["GL"])
        case .gibraltar:
            return ("+350", "Gibraltar", ["GI"])
        case .portugal:
            return ("+351", "Portugal", ["PT"])
        case .luxembourg:
            return ("+352", "Luxembourg", ["LU"])
        case .ireland:
            return ("+353", "Ireland", ["IE"])
        case .iceland:
            return ("+354", "Iceland", ["IS"])
        case .albania:
            return ("+355", "Albania", ["AL"])
        case .malta:
            return ("+356", "Malta", ["MT"])
        case .cyprus:
            return ("+357", "Cyprus", ["CY"])
        case .finland:
            return ("+358", "Finland", ["FI"])
        case .bulgaria:
            return ("+359", "Bulgaria", ["BG"])
        case .lithuania:
            return ("+370", "Lithuania", ["LT"])
        case .latvia:
            return ("+371", "Latvia", ["LV"])
        case .estonia:
            return ("+372", "Estonia", ["EE"])
        case .moldova:
            return ("+373", "Moldova", ["MD"])
        case .armenia:
            return ("+374", "Armenia", ["AM"])
        case .belarus:
            return ("+375", "Belarus", ["BY"])
        case .andorra:
            return ("+376", "Andorra", ["AD"])
        case .monaco:
            return ("+377", "Monaco", ["MC"])
        case .sanMarino:
            return ("+378", "San Marino", ["SM"])
        case .ukraine:
            return ("+380", "Ukraine", ["UA"])
        case .serbia:
            return ("+381", "Serbia", ["RS"])
        case .montenegro:
            return ("+382", "Montenegro", ["ME"])
        case .kosovo:
            return ("+383", "Kosovo", ["XK"])
        case .croatia:
            return ("+385", "Croatia", ["HR"])
        case .slovenia:
            return ("+386", "Slovenia", ["SI"])
        case .bosniaHerzegovina:
            return ("+387", "Bosnia & Herzegovina", ["BA"])
        case .northMacedonia:
            return ("+389", "North Macedonia", ["MK"])
        case .czechRepublic:
            return ("+420", "Czech Republic", ["CZ"])
        case .slovakia:
            return ("+421", "Slovakia", ["SK"])
        case .liechtenstein:
            return ("+423", "Liechtenstein", ["LI"])
        case .falklandIslands:
            return ("+500", "Falkland Islands", ["FK"])
        case .belize:
            return ("+501", "Belize", ["BZ"])
        case .guatemala:
            return ("+502", "Guatemala", ["GT"])
        case .elSalvador:
            return ("+503", "El Salvador", ["SV"])
        case .honduras:
            return ("+504", "Honduras", ["HN"])
        case .nicaragua:
            return ("+505", "Nicaragua", ["NI"])
        case .costaRica:
            return ("+506", "Costa Rica", ["CR"])
        case .panama:
            return ("+507", "Panama", ["PA"])
        case .saintPierreMiquelon:
            return ("+508", "Saint Pierre & Miquelon", ["PM"])
        case .haiti:
            return ("+509", "Haiti", ["HT"])
        case .guadeloupe:
            return ("+590", "Guadeloupe", ["GP","BL","MF"])
        case .bolivia:
            return ("+591", "Bolivia", ["BO"])
        case .guyana:
            return ("+592", "Guyana", ["GY"])
        case .ecuador:
            return ("+593", "Ecuador", ["EC"])
        case .frenchGuiana:
            return ("+594", "French Guiana", ["GF"])
        case .paraguay:
            return ("+595", "Paraguay", ["PY"])
        case .martinique:
            return ("+596", "Martinique", ["MQ"])
        case .suriname:
            return ("+597", "Suriname", ["SR"])
        case .uruguay:
            return ("+598", "Uruguay", ["UY"])
        case .netherlandsAntilles:
            return ("+599", "Netherlands Antilles", ["CW","BQ"])
        case .timorLeste:
            return ("+670", "Timor-Leste", ["TL"])
        case .norfolkIsland:
            return ("+672", "Norfolk Island", ["NF"])
        case .brunei:
            return ("+673", "Brunei", ["BN"])
        case .nauru:
            return ("+674", "Nauru", ["NR"])
        case .papuaNewGuinea:
            return ("+675", "Papua New Guinea", ["PG"])
        case .tonga:
            return ("+676", "Tonga", ["TO"])
        case .solomonIslands:
            return ("+677", "Solomon Islands", ["SB"])
        case .vanuatu:
            return ("+678", "Vanuatu", ["VU"])
        case .fiji:
            return ("+679", "Fiji", ["FJ"])
        case .palau:
            return ("+680", "Palau", ["PW"])
        case .wallisAndFutuna:
            return ("+681", "Wallis & Futuna", ["WF"])
        case .cookIslands:
            return ("+682", "Cook Islands", ["CK"])
        case .niue:
            return ("+683", "Niue", ["NU"])
        case .samoa:
            return ("+685", "Samoa", ["WS"])
        case .kiribati:
            return ("+686", "Kiribati", ["KI"])
        case .newCaledonia:
            return ("+687", "New Caledonia", ["NC"])
        case .tuvalu:
            return ("+688", "Tuvalu", ["TV"])
        case .frenchPolynesia:
            return ("+689", "French Polynesia", ["PF"])
        case .tokelau:
            return ("+690", "Tokelau", ["TK"])
        case .micronesia:
            return ("+691", "Micronesia", ["FM"])
        case .marshallIslands:
            return ("+692", "Marshall Islands", ["MH"])
        case .northKorea:
            return ("+850", "North Korea", ["KP"])
        case .hongKong:
            return ("+852", "Hong Kong", ["HK"])
        case .macau:
            return ("+853", "Macau", ["MO"])
        case .cambodia:
            return ("+855", "Cambodia", ["KH"])
        case .laos:
            return ("+856", "Laos", ["LA"])
        case .bangladesh:
            return ("+880", "Bangladesh", ["BD"])
        case .taiwan:
            return ("+886", "Taiwan", ["TW"])
        case .maldives:
            return ("+960", "Maldives", ["MV"])
        case .lebanon:
            return ("+961", "Lebanon", ["LB"])
        case .jordan:
            return ("+962", "Jordan", ["JO"])
        case .syria:
            return ("+963", "Syria", ["SY"])
        case .iraq:
            return ("+964", "Iraq", ["IQ"])
        case .kuwait:
            return ("+965", "Kuwait", ["KW"])
        case .saudiArabia:
            return ("+966", "Saudi Arabia", ["SA"])
        case .yemen:
            return ("+967", "Yemen", ["YE"])
        case .oman:
            return ("+968", "Oman", ["OM"])
        case .palestine:
            return ("+970", "Palestinian Territories", ["PS"])
        case .uae:
            return ("+971", "United Arab Emirates", ["AE"])
        case .israel:
            return ("+972", "Israel", ["IL"])
        case .bahrain:
            return ("+973", "Bahrain", ["BH"])
        case .qatar:
            return ("+974", "Qatar", ["QA"])
        case .bhutan:
            return ("+975", "Bhutan", ["BT"])
        case .mongolia:
            return ("+976", "Mongolia", ["MN"])
        case .nepal:
            return ("+977", "Nepal", ["NP"])
        case .tajikistan:
            return ("+992", "Tajikistan", ["TJ"])
        case .turkmenistan:
            return ("+993", "Turkmenistan", ["TM"])
        case .azerbaijan:
            return ("+994", "Azerbaijan", ["AZ"])
        case .georgia:
            return ("+995", "Georgia", ["GE"])
        case .kyrgyzstan:
            return ("+996", "Kyrgyzstan", ["KG"])
        case .uzbekistan:
            return ("+998", "Uzbekistan", ["UZ"])
        }
    }
    // swiftlint:enable large_tuple
}


// MARK: - CallingCodes Namespace

enum CallingCodes {

    /// Normalize a raw sender string: keep only digits and '+'.
    static func normalize(_ sender: String) -> String {
        sender.filter { $0.isNumber || $0 == "+" }
    }

    /// Identify the calling-code entry for a raw sender string.
    ///
    /// - Normalizes formatting characters.
    /// - Returns `nil` if the string does not start with `+`.
    /// - Tries longest-prefix match: 4-char prefix, then 3-char, then 2-char.
    /// - Returns `nil` if no prefix matches.
    static func callingCode(for sender: String) -> CallingCodeEntry? {
        let normalized = normalize(sender)
        guard normalized.hasPrefix("+"), normalized.count >= 2 else { return nil }

        for length in [4, 3, 2] {
            guard normalized.count >= length else { continue }
            let prefix = String(normalized.prefix(length))
            if let entry = CallingCodeEntry.byCallingCode[prefix] {
                return entry
            }
        }
        return nil
    }
}
