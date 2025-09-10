import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Maps (flutter_map + latlong2)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

// ============ CONFIG ============
const String supabaseUrl = 'https://ihwvfwonsssntrwprlel.supabase.co';
const String supabaseAnonKey = 'sb_publishable_VCiVp-3ZNLRq4W_MM-ceeA_mRXjpxFN';

// Helper
ll.LatLng _toLatLng(Position? p) =>
    (p != null) ? ll.LatLng(p.latitude, p.longitude) : const ll.LatLng(23.1793, 75.7849);

// ============ ENTRY ============
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SmartKumbhApp());
}

// ============ MODEL ============
class UserProfile {
  final String name;
  final int phone;        // int8 (BIGINT)
  final String state;
  final String city;
  final int family;       // int2 (SMALLINT)
  final int aadhaar;      // int4 (INTEGER)
  final String language;
  final String? qrUrl;    // varchar

  const UserProfile({
    required this.name,
    required this.phone,
    required this.state,
    required this.city,
    required this.family,
    required this.aadhaar,
    required this.language,
    this.qrUrl,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,          // numeric
        'state': state,
        'city': city,
        'family': family,        // numeric
        'aadhaar': aadhaar,      // numeric
        'language': language,
        'qr_url': qrUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static int _numFrom(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final digits = RegExp(r'\d+').stringMatch(v);
      return int.tryParse(digits ?? '0') ?? 0;
    }
    return 0;
  }

  static UserProfile fromJson(Map<String, dynamic> m) => UserProfile(
        name: (m['name'] ?? '').toString(),
        phone: _numFrom(m['phone']),
        state: (m['state'] ?? '').toString(),
        city: (m['city'] ?? '').toString(),
        family: _numFrom(m['family']),
        aadhaar: _numFrom(m['aadhaar']),
        language: (m['language'] ?? '').toString(),
        qrUrl: m['qr_url']?.toString(),
      );

  UserProfile copyWith({String? qrUrl}) => UserProfile(
        name: name,
        phone: phone,
        state: state,
        city: city,
        family: family,
        aadhaar: aadhaar,
        language: language,
        qrUrl: qrUrl ?? this.qrUrl,
      );
}

// ============ SUPABASE SERVICE ============
final supabase = Supabase.instance.client;

class BackendService {
  static const String usersTable = 'users';
  static const String bucket = 'qr-codes';

  static Future<Uint8List> _qrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final pngData = await painter.toImageData(600);
    return pngData!.buffer.asUint8List();
  }

  // phonePath is stringified for storage path
  static Future<String> uploadQrAndGetUrl(String phonePath, String qrData) async {
    final bytes = await _qrPngBytes(qrData);
    final path = 'public/$phonePath.png';
    await supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );
    final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  static Future<UserProfile> upsertUser(UserProfile p) async {
    final rows = await supabase
        .from(usersTable)
        .upsert(p.toJson(), onConflict: 'phone')
        .select();
    final row =
        (rows is List && rows.isNotEmpty) ? rows.first as Map<String, dynamic> : p.toJson();
    return UserProfile.fromJson(row);
  }
}

// ============ LOCAL SESSION ============
class SessionStore {
  static const _kLoggedIn = 'logged_in';
  static const _kCurrentPhone = 'current_phone';
  static String _profileKey(String phone) => 'profile_$phone';

  static Future<void> saveLogin(UserProfile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLoggedIn, true);
    await sp.setString(_kCurrentPhone, p.phone.toString());
    await sp.setString(_profileKey(p.phone.toString()), jsonEncode(p.toJson()));
  }

  static Future<UserProfile?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    if (!(sp.getBool(_kLoggedIn) ?? false)) return null;
    final phone = sp.getString(_kCurrentPhone);
    if (phone == null) return null;
    final raw = sp.getString(_profileKey(phone));
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw));
  }

  static Future<void> updateCached(UserProfile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_profileKey(p.phone.toString()), jsonEncode(p.toJson()));
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLoggedIn, false);
    await sp.remove(_kCurrentPhone);
  }
}

// ============ THEME + APP ============
class SmartKumbhApp extends StatelessWidget {
  const SmartKumbhApp({super.key});
  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF121212);
    const surface = Color(0xFF1A1A1A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartKumbh',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.dark,
          surface: surface,
          primary: Colors.orangeAccent,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashGate(),
    );
  }
}

// ============ SOFT UI HELPER ============
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final bool inset;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.color,
    this.inset = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = color ?? scheme.surface;
    final lightShadow = Colors.white.withValues(alpha: 0.06);
    final darkShadow = Colors.black.withValues(alpha: 0.60);

    final boxShadow = inset
        ? [
            BoxShadow(color: darkShadow, offset: const Offset(4, 4), blurRadius: 12, spreadRadius: 1),
            BoxShadow(color: lightShadow, offset: const Offset(-4, -4), blurRadius: 12, spreadRadius: 1),
          ]
        : [
            BoxShadow(color: darkShadow, offset: const Offset(8, 8), blurRadius: 24, spreadRadius: 1),
            BoxShadow(color: lightShadow, offset: const Offset(-6, -6), blurRadius: 20, spreadRadius: 1),
          ];

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha: 0.98), base],
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fade =
          Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
          position: animation.drive(slide),
          child: FadeTransition(opacity: animation.drive(fade), child: child));
    },
  );
}

// ============ SPLASH ============
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}
class _SplashGateState extends State<SplashGate> {
  double _opacity = 0;
  @override
  void initState() {
    super.initState();
    _sequence();
  }

  Future<void> _sequence() async {
    setState(() => _opacity = 1);
    await Future.delayed(const Duration(milliseconds: 1750));
    setState(() => _opacity = 0);
    await Future.delayed(const Duration(milliseconds: 750));
    final user = await SessionStore.currentUser();
    if (!mounted) return;
    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
          fadeSlideRoute(RootShell(initialUser: user)), (r) => false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          fadeSlideRoute(const LoginPage()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: _opacity,
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeumorphicCard(
                color: Colors.orange.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(28),
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/logo.png', height: 120),
              ),
              const SizedBox(height: 16),
              const Text('SmartKumbh',
                  style: TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ LOGIN ============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  String name = "", phoneS = "", familyS = "", aadhaarS = "", language = "";
  String? selectedState;
  String? selectedCity;
  Position? currentPosition;

  final List<String> states = const [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat',
    'Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra',
    'Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu',
    'Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal'
  ];
  final Map<String, List<String>> cities = const {
    'Andhra Pradesh': ['Visakhapatnam','Vijayawada','Guntur','Nellore','Tirupati','Kurnool'],
    'Arunachal Pradesh': ['Itanagar','Naharlagun','Tawang','Ziro','Pasighat'],
    'Assam': ['Guwahati','Silchar','Dibrugarh','Jorhat','Tezpur'],
    'Bihar': ['Patna','Gaya','Bhagalpur','Muzaffarpur','Darbhanga'],
    'Chhattisgarh': ['Raipur','Bhilai','Bilaspur','Durg','Korba'],
    'Goa': ['Panaji','Margao','Vasco da Gama','Mapusa'],
    'Gujarat': ['Ahmedabad','Surat','Vadodara','Rajkot','Bhavnagar','Jamnagar'],
    'Haryana': ['Gurugram','Faridabad','Panipat','Ambala','Hisar'],
    'Himachal Pradesh': ['Shimla','Dharamshala','Mandi','Solan','Kullu'],
    'Jharkhand': ['Ranchi','Jamshedpur','Dhanbad','Hazaribagh','Bokaro'],
    'Karnataka': ['Bengaluru','Mysuru','Mangaluru','Hubballi','Belagavi'],
    'Kerala': ['Thiruvananthapuram','Kochi','Kozhikode','Thrissur','Kollam'],
    'Madhya Pradesh': ['Bhopal','Indore','Ujjain','Gwalior','Jabalpur'],
    'Maharashtra': ['Mumbai','Pune','Nagpur','Nashik','Thane','Aurangabad'],
    'Manipur': ['Imphal','Thoubal','Kakching','Churachandpur'],
    'Meghalaya': ['Shillong','Tura','Jowai','Nongpoh'],
    'Mizoram': ['Aizawl','Lunglei','Champhai','Serchhip'],
    'Nagaland': ['Kohima','Dimapur','Mokokchung','Wokha'],
    'Odisha': ['Bhubaneswar','Cuttack','Rourkela','Sambalpur','Puri'],
    'Punjab': ['Ludhiana','Amritsar','Jalandhar','Patiala','Mohali'],
    'Rajasthan': ['Jaipur','Jodhpur','Udaipur','Kota','Bikaner','Ajmer'],
    'Sikkim': ['Gangtok','Namchi','Gyalshing','Mangan'],
    'Tamil Nadu': ['Chennai','Coimbatore','Madurai','Tiruchirappalli','Salem','Erode','Vellore'],
    'Telangana': ['Hyderabad','Warangal','Nizamabad','Karimnagar'],
    'Tripura': ['Agartala','Udaipur','Dharmanagar','Belonia'],
    'Uttar Pradesh': ['Lucknow','Varanasi','Prayagraj','Kanpur','Agra','Noida','Ghaziabad'],
    'Uttarakhand': ['Dehradun','Haridwar','Rishikesh','Haldwani','Roorkee'],
    'West Bengal': ['Kolkata','Howrah','Durgapur','Siliguri','Asansol'],
  };
  final List<String> languagesAll = const [
    'Assamese','Bengali','Bodo','Dogri','Gujarati','Hindi','Kannada','Kashmiri','Konkani',
    'Maithili','Malayalam','Manipuri','Marathi','Nepali','Odia','Punjabi','Sanskrit','Santali',
    'Sindhi','Tamil','Telugu','Urdu','English'
  ];

  Future<void> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => currentPosition = pos);
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.orangeAccent),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _field({
    required String label,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return NeumorphicCard(
      child: TextFormField(
        decoration: _dec(label, hint: hint),
        keyboardType: keyboardType,
        validator: validator ?? (v) => (v == null || v.isEmpty) ? "Enter $label" : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _auto({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
    String? hint,
  }) {
    final lower = options.map((e) => e.toLowerCase()).toList();
    return NeumorphicCard(
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue tev) {
          final q = tev.text.trim().toLowerCase();
          if (q.isEmpty) return options;
          return options.where((o) => o.toLowerCase().contains(q));
        },
        onSelected: onSelected,
        fieldViewBuilder: (context, ctrl, focus, onSubmit) {
          if (ctrl.text.isEmpty && selectedValue != null) ctrl.text = selectedValue!;
          return TextFormField(
            controller: ctrl,
            focusNode: focus,
            decoration: _dec(label, hint: hint),
            validator: (v) {
              if (v == null || v.isEmpty) return "Select $label";
              return lower.contains(v.toLowerCase()) ? null : "Pick a valid $label";
            },
          );
        },
        optionsViewBuilder: (context, onOptionSelected, opts) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260, minWidth: 280),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemBuilder: (_, i) {
                    final opt = opts.elementAt(i);
                    return ListTile(dense: true, title: Text(opt), onTap: () => onOptionSelected(opt));
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: opts.length,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final phoneDigits = phoneS.replaceAll(RegExp(r'\D'), '');
    final aadhaarDigits = aadhaarS.replaceAll(RegExp(r'\D'), '');
    final familyDigits = familyS.replaceAll(RegExp(r'\D'), '');

    final phoneNum = int.parse(phoneDigits);
    final aadhaarNum = int.parse(aadhaarDigits);
    final familyNum = int.tryParse(familyDigits) ?? 0;

    var profile = UserProfile(
      name: name,
      phone: phoneNum,
      state: selectedState ?? '',
      city: selectedCity ?? '',
      family: familyNum,
      aadhaar: aadhaarNum,
      language: language,
    );

    await SessionStore.saveLogin(profile);

    try {
      final qrUrl = await BackendService.uploadQrAndGetUrl(
        profile.phone.toString(),
        '${profile.name}-${profile.phone}',
      );
      final upserted = await BackendService.upsertUser(profile.copyWith(qrUrl: qrUrl));
      await SessionStore.updateCached(upserted);
      profile = upserted;
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(fadeSlideRoute(RootShell(initialUser: profile)), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cityOptions = selectedState == null ? const <String>[] : (cities[selectedState] ?? const <String>[]);
    return Scaffold(
      appBar: AppBar(title: const Text("SmartKumbh")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            children: [
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: const [
                    Icon(Icons.person_outline_rounded, color: Colors.orangeAccent, size: 36),
                    SizedBox(width: 12),
                    Expanded(child: Text("Sign in to your account", style: TextStyle(fontSize: 18, color: Colors.white70))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field(label: "Name", onChanged: (v) => name = v.trim()),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 6),
                      Text("Mobile number must be 10 digits",
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              _field(
                label: "Phone",
                hint: "Enter 10-digit mobile number",
                keyboardType: TextInputType.phone,
                onChanged: (v) => phoneS = v.trim(),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter Phone";
                  final d = v.replaceAll(RegExp(r'\D'), '');
                  if (d.length != 10) return "Enter exactly 10 digits";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _auto(
                label: "State",
                options: states,
                selectedValue: selectedState,
                hint: "Type to search State",
                onSelected: (sel) => setState(() {
                  selectedState = sel;
                  selectedCity = null;
                }),
              ),
              const SizedBox(height: 12),
              if (selectedState != null)
                _auto(
                  label: "City",
                  options: cityOptions,
                  selectedValue: selectedCity,
                  hint: "Type to search City",
                  onSelected: (sel) => setState(() => selectedCity = sel),
                ),
              if (selectedState != null) const SizedBox(height: 12),
              _field(
                label: "Family Members",
                keyboardType: TextInputType.number,
                onChanged: (v) => familyS = v.trim(),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter Family Members";
                  final d = v.replaceAll(RegExp(r'\D'), '');
                  if (d.isEmpty) return "Enter a number";
                  final n = int.tryParse(d) ?? -1;
                  if (n < 0 || n > 32767) return "Must be 0..32767";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                label: "Aadhaar (Last 4)",
                keyboardType: TextInputType.number,
                onChanged: (v) => aadhaarS = v.trim(),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter Aadhaar (Last 4)";
                  final d = v.replaceAll(RegExp(r'\D'), '');
                  if (d.length != 4) return "Enter exactly 4 digits";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _auto(
                label: "Preferred Language",
                options: languagesAll,
                selectedValue: language.isEmpty ? null : language,
                hint: "Type to search Language",
                onSelected: (sel) => setState(() => language = sel),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _login,
                  child: const Text("Log in"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============ ROOT SHELL ============
class RootShell extends StatefulWidget {
  final UserProfile initialUser;
  const RootShell({super.key, required this.initialUser});
  @override
  State<RootShell> createState() => _RootShellState();
}
class _RootShellState extends State<RootShell> {
  int _index = 0;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _position = pos);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(user: widget.initialUser, position: _position),
      const _LiveConcertsTab(),
      _MapTab(position: _position),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartKumbh"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Colors.orangeAccent),
            onPressed: () => Navigator.of(context)
                .push(fadeSlideRoute(ProfilePage(user: widget.initialUser))),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: pages[_index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_available_rounded), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Map'),
        ],
      ),
    );
  }
}

// ============ HOME TAB ============
class _HomeTab extends StatelessWidget {
  final UserProfile user;
  final Position? position;
  const _HomeTab({required this.user, required this.position});
  @override
  Widget build(BuildContext context) {
    final features = [
      {"title": "QR Code", "icon": Icons.qr_code_2_rounded, "color": Colors.orange},
      {"title": "Info", "icon": Icons.info_rounded, "color": Colors.teal},
      {"title": "SOS", "icon": Icons.emergency_rounded, "color": Colors.redAccent},
      {"title": "Map", "icon": Icons.map_rounded, "color": Colors.blueAccent},
    ];
    Widget tile(Map<String, dynamic> it) {
      return InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          switch (it["title"] as String) {
            case "QR Code":
              Navigator.of(context)
                  .push(fadeSlideRoute(QRPage(userId: "${user.name}-${user.phone}")));
              break;
            case "Info":
              Navigator.of(context).push(fadeSlideRoute(InfoPage(user)));
              break;
            case "SOS":
              Navigator.of(context)
                  .push(fadeSlideRoute(SOSPage(user.name, user.phone.toString(), position)));
              break;
            case "Map":
              Navigator.of(context).push(fadeSlideRoute(MapPage(position)));
              break;
          }
        },
        child: NeumorphicCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: (it["color"] as Color).withValues(alpha: 0.22),
                child: Icon(it["icon"] as IconData, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                it["title"] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18),
      itemCount: features.length,
      itemBuilder: (_, i) => tile(features[i]),
    );
  }
}

// ============ LIVE TAB ============
class _LiveConcertsTab extends StatelessWidget {
  const _LiveConcertsTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: NeumorphicCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_available_rounded, color: Colors.orangeAccent, size: 36),
            SizedBox(height: 10),
            Text("Live Concerts coming soon", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// ============ MAP TAB (flutter_map) ============
class _MapTab extends StatelessWidget {
  final Position? position;
  const _MapTab({required this.position});
  @override
  Widget build(BuildContext context) {
    final initialTarget = _toLatLng(position);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialTarget,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.smartkumbh.app',
              maxZoom: 19,
            ),
            if (position != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: initialTarget,
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PROFILE ============
class ProfilePage extends StatelessWidget {
  final UserProfile user;
  const ProfilePage({super.key, required this.user});

  Widget _row(String label, String value) {
    return NeumorphicCard(
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orangeAccent),
          children: [TextSpan(text: value, style: const TextStyle(fontSize: 18, color: Colors.white))],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await SessionStore.logout();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Successfully logged out!!"), duration: Duration(milliseconds: 900)));
    await Future.delayed(const Duration(milliseconds: 900));
    if (!context.mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(fadeSlideRoute(const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row("Name", user.name),
          const SizedBox(height: 10),
          _row("Phone", user.phone.toString()),
          const SizedBox(height: 10),
          _row("State", user.state),
          const SizedBox(height: 10),
          _row("City", user.city),
          const SizedBox(height: 10),
          _row("Family Members", user.family.toString()),
          const SizedBox(height: 10),
          _row("Aadhaar", user.aadhaar.toString()),
          const SizedBox(height: 10),
          _row("Language", user.language),
          const SizedBox(height: 10),
          _row("QR URL", user.qrUrl ?? "-"),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ QR VIEW ============
class QRPage extends StatelessWidget {
  final String userId;
  const QRPage({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your QR Code")),
      body: Center(
        child: NeumorphicCard(
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(data: userId, size: 260, backgroundColor: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ============ INFO VIEW ============
class InfoPage extends StatelessWidget {
  final UserProfile user;
  const InfoPage(this.user, {super.key});
  Widget _row(String label, String value) {
    return NeumorphicCard(
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orangeAccent),
          children: [TextSpan(text: value, style: const TextStyle(fontSize: 18, color: Colors.white))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personal Information")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row("Name", user.name),
          const SizedBox(height: 10),
          _row("Phone", user.phone.toString()),
          const SizedBox(height: 10),
          _row("State", user.state),
          const SizedBox(height: 10),
          _row("City", user.city),
          const SizedBox(height: 10),
          _row("Family Members", user.family.toString()),
          const SizedBox(height: 10),
          _row("Aadhaar", user.aadhaar.toString()),
          const SizedBox(height: 10),
          _row("Language", user.language),
        ],
      ),
    );
  }
}

// ============ SOS ============
class SOSPage extends StatefulWidget {
  final String name, phone;
  final Position? position;
  const SOSPage(this.name, this.phone, this.position, {super.key});
  @override
  State<SOSPage> createState() => _SOSPageState();
}
class _SOSPageState extends State<SOSPage> {
  int tapCount = 0;
  void _onTap() {
    setState(() => tapCount++);
    if (tapCount >= 3) {
      tapCount = 0;
      _showConfirm();
    }
  }

  void _showConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Confirm Emergency", style: TextStyle(color: Colors.orange)),
        content: const Text("Are you sure you want to contact emergency services?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              debugPrint(
                  "🚨 EMERGENCY ALERT: ${widget.name}, ${widget.phone}, Location: ${widget.position}");
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Emergency Alert Sent 🚨")));
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency SOS")),
      body: Center(
        child: GestureDetector(
          onTap: _onTap,
          child: NeumorphicCard(
            borderRadius: BorderRadius.circular(90),
            child: const CircleAvatar(
              radius: 90,
              backgroundColor: Colors.redAccent,
              child: Text("SOS",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MAP FULL ============
class MapPage extends StatefulWidget {
  final Position? position;
  const MapPage(this.position, {super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}
class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  ll.LatLng get _initialTarget => _toLatLng(widget.position);

  Future<void> _recenter() async {
    _mapController.move(_initialTarget, 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Map")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialTarget,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartkumbh.app',
                maxZoom: 19,
              ),
              if (widget.position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _initialTarget,
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: "recenter",
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          )
        ],
      ),
    );
  }
}
