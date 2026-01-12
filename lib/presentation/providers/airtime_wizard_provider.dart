import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_models.dart';

class AirtimeWizardState {
  final Country? selectedCountry;
  final String? phoneNumber;
  final AutodetectData? operatorData;
  final double? selectedAmount;
  final String? customIdentifier;

  AirtimeWizardState({
    this.selectedCountry,
    this.phoneNumber,
    this.operatorData,
    this.selectedAmount,
    this.customIdentifier,
  });

  AirtimeWizardState copyWith({
    Country? selectedCountry,
    String? phoneNumber,
    AutodetectData? operatorData,
    double? selectedAmount,
    String? customIdentifier,
    bool clearCountry = false,
    bool clearPhone = false,
    bool clearOperator = false,
    bool clearAmount = false,
    bool clearIdentifier = false,
  }) {
    return AirtimeWizardState(
      selectedCountry: clearCountry ? null : (selectedCountry ?? this.selectedCountry),
      phoneNumber: clearPhone ? null : (phoneNumber ?? this.phoneNumber),
      operatorData: clearOperator ? null : (operatorData ?? this.operatorData),
      selectedAmount: clearAmount ? null : (selectedAmount ?? this.selectedAmount),
      customIdentifier: clearIdentifier ? null : (customIdentifier ?? this.customIdentifier),
    );
  }

  bool get canProceedToPhone => selectedCountry != null;
  bool get canProceedToAmount => phoneNumber != null && operatorData != null;
  bool get canProceedToConfirm => selectedAmount != null && operatorData != null;
}

class AirtimeWizardNotifier extends StateNotifier<AirtimeWizardState> {
  AirtimeWizardNotifier() : super(AirtimeWizardState());

  void selectCountry(Country country) {
    state = state.copyWith(
      selectedCountry: country,
      clearPhone: true,
      clearOperator: true,
      clearAmount: true,
    );
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone, clearOperator: true, clearAmount: true);
  }

  void setOperatorData(AutodetectData data) {
    state = state.copyWith(operatorData: data);
  }

  void setAmount(double amount) {
    state = state.copyWith(selectedAmount: amount);
  }

  void setCustomIdentifier(String identifier) {
    state = state.copyWith(customIdentifier: identifier);
  }

  void reset() {
    state = AirtimeWizardState();
  }
}

final airtimeWizardProvider = StateNotifierProvider<AirtimeWizardNotifier, AirtimeWizardState>((ref) {
  return AirtimeWizardNotifier();
});

