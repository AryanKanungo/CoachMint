import 'package:supabase_flutter/supabase_flutter.dart';

class SchemeService {
  final _supabase = Supabase.instance.client;

  // Fallback Mock Data
  final List<Map<String, dynamic>> _mockSchemes = [
    {
      'name': 'e-Shram',
      'description': 'National database for unorganized workers providing access to social security schemes.',
      'eligibility': {"income_type": ["gig", "freelancer"], "min_age": 16, "max_age": 59},
      'documents': ["Aadhaar", "Bank account details", "Mobile number linked to Aadhaar"],
      'apply_url': 'https://eshram.gov.in'
    },
    {
      'name': 'PM SVANidhi',
      'description': 'Micro-credit scheme providing working capital loans to street vendors affected by COVID.',
      'eligibility': {"income_type": ["gig", "self_employed"], "occupation": "street_vendor"},
      'documents': ["Aadhaar", "Vending certificate or ID", "Bank account"],
      'apply_url': 'https://pmsvanidhi.mohua.gov.in'
    },
    {
      'name': 'PM Kisan',
      'description': 'Income support scheme providing ₹6000 per year to eligible farmer families.',
      'eligibility': {"occupation": "farmer", "land_owner": true},
      'documents': ["Aadhaar", "Land ownership records", "Bank passbook"],
      'apply_url': 'https://pmkisan.gov.in'
    }
  ];

  Future<List<Map<String, dynamic>>> fetchWelfareSchemes() async {
    try {
      final response = await _supabase
          .from('welfare_schemes')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Supabase error: $e. Using fallback mock data.');
      return _mockSchemes;
    }
  }
}