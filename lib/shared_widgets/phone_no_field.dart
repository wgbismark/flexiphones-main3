import 'package:flexiphones/provider/provider_class.dart';
import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flexiphones/shared_widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class CountryCodePhoneInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextInputType keyboardType;
  final bool enabled;

  const CountryCodePhoneInput({
    super.key,
    this.controller,
    this.hintText = 'Enter Your Mobile Number',
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.phone,
    this.enabled = true,
  });

  @override
  State<CountryCodePhoneInput> createState() => _CountryCodePhoneInputState();
}

class _CountryCodePhoneInputState extends State<CountryCodePhoneInput> {
  // Default: Ghana

  // List of country codes (you can expand or import from package if needed)
  final List<String> countryCodes = [
    '+1', // USA/Canada
    '+7', // Russia
    '+20', // Egypt
    '+27', // South Africa
    '+30', // Greece
    '+31', // Netherlands
    '+32', // Belgium
    '+33', // France
    '+34', // Spain
    '+36', // Hungary
    '+39', // Italy
    '+40', // Romania
    '+41', // Switzerland
    '+43', // Austria
    '+44', // UK
    '+45', // Denmark
    '+46', // Sweden
    '+47', // Norway
    '+48', // Poland
    '+49', // Germany
    '+51', // Peru
    '+52', // Mexico
    '+53', // Cuba
    '+54', // Argentina
    '+55', // Brazil
    '+56', // Chile
    '+57', // Colombia
    '+58', // Venezuela
    '+60', // Malaysia
    '+61', // Australia
    '+62', // Indonesia
    '+63', // Philippines
    '+64', // New Zealand
    '+65', // Singapore
    '+66', // Thailand
    '+81', // Japan
    '+82', // South Korea
    '+84', // Vietnam
    '+86', // China
    '+90', // Turkey
    '+91', // India
    '+92', // Pakistan
    '+93', // Afghanistan
    '+94', // Sri Lanka
    '+95', // Myanmar
    '+98', // Iran
    '+212', // Morocco
    '+213', // Algeria
    '+216', // Tunisia
    '+220', // Gambia
    '+221', // Senegal
    '+222', // Mauritania
    '+223', // Mali
    '+224', // Guinea
    '+225', // Ivory Coast
    '+226', // Burkina Faso
    '+227', // Niger
    '+228', // Togo
    '+229', // Benin
    '+230', // Mauritius
    '+231', // Liberia
    '+232', // Sierra Leone
    '+233', // Ghana 👈 Default
    '+234', // Nigeria
    '+235', // Chad
    '+236', // Central African Republic
    '+237', // Cameroon
    '+238', // Cape Verde
    '+239', // Sao Tome & Principe
    '+240', // Equatorial Guinea
    '+241', // Gabon
    '+242', // Congo-Brazzaville
    '+243', // DR Congo
    '+244', // Angola
    '+245', // Guinea-Bissau
    '+246', // British Indian Ocean Territory
    '+248', // Seychelles
    '+249', // Sudan
    '+250', // Rwanda
    '+251', // Ethiopia
    '+252', // Somalia
    '+253', // Djibouti
    '+254', // Kenya
    '+255', // Tanzania
    '+256', // Uganda
    '+257', // Burundi
    '+258', // Mozambique
    '+260', // Zambia
    '+261', // Madagascar
    '+262', // Reunion
    '+263', // Zimbabwe
    '+264', // Namibia
    '+265', // Malawi
    '+266', // Lesotho
    '+267', // Botswana
    '+268', // Eswatini
    '+269', // Comoros
    '+290', // Saint Helena
    '+291', // Eritrea
    '+297', // Aruba
    '+298', // Faroe Islands
    '+299', // Greenland
    '+350', // Gibraltar
    '+351', // Portugal
    '+352', // Luxembourg
    '+353', // Ireland
    '+354', // Iceland
    '+355', // Albania
    '+356', // Malta
    '+357', // Cyprus
    '+358', // Finland
    '+359', // Bulgaria
    '+370', // Lithuania
    '+371', // Latvia
    '+372', // Estonia
    '+373', // Moldova
    '+374', // Armenia
    '+375', // Belarus
    '+376', // Andorra
    '+377', // Monaco
    '+378', // San Marino
    '+379', // Vatican City
    '+380', // Ukraine
    '+381', // Serbia
    '+382', // Montenegro
    '+383', // Kosovo
    '+385', // Croatia
    '+386', // Slovenia
    '+387', // Bosnia & Herzegovina
    '+389', // North Macedonia
    '+420', // Czech Republic
    '+421', // Slovakia
    '+423', // Liechtenstein
    '+500', // Falkland Islands
    '+501', // Belize
    '+502', // Guatemala
    '+503', // El Salvador
    '+504', // Honduras
    '+505', // Nicaragua
    '+506', // Costa Rica
    '+507', // Panama
    '+508', // Saint Pierre & Miquelon
    '+509', // Haiti
    '+590', // Guadeloupe
    '+591', // Bolivia
    '+592', // Guyana
    '+593', // Ecuador
    '+594', // French Guiana
    '+595', // Paraguay
    '+596', // Martinique
    '+597', // Suriname
    '+598', // Uruguay
    '+599', // Curacao, Bonaire, Sint Maarten
    '+670', // Timor-Leste
    '+672', // Australian External Territories
    '+673', // Brunei
    '+674', // Nauru
    '+675', // Papua New Guinea
    '+676', // Tonga
    '+677', // Solomon Islands
    '+678', // Vanuatu
    '+679', // Fiji
    '+680', // Palau
    '+681', // Wallis & Futuna
    '+682', // Cook Islands
    '+683', // Niue
    '+685', // Samoa
    '+686', // Kiribati
    '+687', // New Caledonia
    '+688', // Tuvalu
    '+689', // French Polynesia
    '+690', // Tokelau
    '+691', // Micronesia
    '+692', // Marshall Islands
    '+850', // North Korea
    '+852', // Hong Kong
    '+853', // Macao
    '+855', // Cambodia
    '+856', // Laos
    '+880', // Bangladesh
    '+886', // Taiwan
    '+960', // Maldives
    '+961', // Lebanon
    '+962', // Jordan
    '+963', // Syria
    '+964', // Iraq
    '+965', // Kuwait
    '+966', // Saudi Arabia
    '+967', // Yemen
    '+968', // Oman
    '+970', // Palestine
    '+971', // UAE
    '+972', // Israel
    '+973', // Bahrain
    '+974', // Qatar
    '+975', // Bhutan
    '+976', // Mongolia
    '+977', // Nepal
    '+992', // Tajikistan
    '+993', // Turkmenistan
    '+994', // Azerbaijan
    '+995', // Georgia
    '+996', // Kyrgyzstan
    '+998', // Uzbekistan
  ];

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    var ch = Theme.of(context).colorScheme;
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.6,
      child: AbsorbPointer(
        absorbing: !widget.enabled,
        child: Container(
          decoration: BoxDecoration(
            color: ch.primaryFixedDim.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 2,
                  bottom: 2,
                ),
                // decoration: BoxDecoration(
                //   color: ch.primaryContainer.withOpacity(0.5),
                //   borderRadius: BorderRadius.circular(8),
                // ),
                alignment: Alignment.center,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sharedProvider.countryCode,
                    menuMaxHeight: 300,

                    onChanged: (String? newValue) {
                      setState(() {
                        sharedProvider.countryCode = newValue!;
                      });
                      // Optional: Notify parent of change
                      widget.onChanged?.call(
                        '${sharedProvider.countryCode} ${widget.controller?.text ?? ""}',
                      );
                    },
                    items:
                        countryCodes.map<DropdownMenuItem<String>>((
                          String code,
                        ) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          );
                        }).toList(),
                    style: ptstyle(
                      size: 12,
                      weight: 600,
                      color: ch.onPrimaryContainer,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    isExpanded: false,
                  ),
                ),
              ),

              SizedBox(height: 40, child: VerticalDivider()),
              Expanded(
                child: FilledInput(
                  filled: false,
                  controller: widget.controller,
                  hintText: widget.hintText,
                  error: sharedProvider.phoneInValid,
                  keyboardType: widget.keyboardType,
                  enabled: widget.enabled,
                  maxLength: 9,
                  onChange: (value) {
                    sharedProvider.phoneInValid = false;
                    widget.onChanged?.call(
                      '${sharedProvider.countryCode} $value',
                    );
                  },
                  onSubmitted: widget.onSubmitted,
                  label: '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
