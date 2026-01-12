import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

class CountryTestScreen extends ConsumerStatefulWidget {
  const CountryTestScreen({super.key});

  @override
  ConsumerState<CountryTestScreen> createState() => _CountryTestScreenState();
}

class _CountryTestScreenState extends ConsumerState<CountryTestScreen> {
  List<dynamic> _countries = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _testCountriesAPI() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/api/v1/reloadly/country-list',
      );

      setState(() {
        _countries = response.data;
        _isLoading = false;
      });

      print('✅ API Response: ${response.data}');
      print('📊 Total countries: ${_countries.length}');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ API Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countries API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testCountriesAPI,
              child: const Text('Test Countries API'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error.isNotEmpty)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              )
            else if (_countries.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      title: Text(country['name'] ?? 'No name'),
                      subtitle: Text(country['code'] ?? 'No code'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
