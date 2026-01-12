import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_models.dart';

class DataWizardState {
  final Country? selectedCountry;
  final String? phoneNumber;
  final AutodetectData? operatorData;
  final List<DataOperator>? availableOperators;
  final DataOperator? selectedOperator;
  final DataBundle? selectedBundle;
  final String? customIdentifier;

  DataWizardState({
    this.selectedCountry,
    this.phoneNumber,
    this.operatorData,
    this.availableOperators,
    this.selectedOperator,
    this.selectedBundle,
    this.customIdentifier,
  });

  DataWizardState copyWith({
    Country? selectedCountry,
    String? phoneNumber,
    AutodetectData? operatorData,
    List<DataOperator>? availableOperators,
    DataOperator? selectedOperator,
    DataBundle? selectedBundle,
    String? customIdentifier,
    bool clearCountry = false,
    bool clearPhone = false,
    bool clearOperator = false,
    bool clearOperators = false,
    bool clearSelectedOperator = false,
    bool clearBundle = false,
    bool clearIdentifier = false,
  }) {
    return DataWizardState(
      selectedCountry: clearCountry ? null : (selectedCountry ?? this.selectedCountry),
      phoneNumber: clearPhone ? null : (phoneNumber ?? this.phoneNumber),
      operatorData: clearOperator ? null : (operatorData ?? this.operatorData),
      availableOperators: clearOperators ? null : (availableOperators ?? this.availableOperators),
      selectedOperator: clearSelectedOperator ? null : (selectedOperator ?? this.selectedOperator),
      selectedBundle: clearBundle ? null : (selectedBundle ?? this.selectedBundle),
      customIdentifier: clearIdentifier ? null : (customIdentifier ?? this.customIdentifier),
    );
  }

  bool get canProceedToPhone => selectedCountry != null;
  bool get canProceedToBundle => phoneNumber != null && operatorData != null && availableOperators != null;
  bool get canProceedToConfirm => selectedOperator != null && selectedBundle != null;
}

class DataWizardNotifier extends StateNotifier<DataWizardState> {
  DataWizardNotifier() : super(DataWizardState());

  void selectCountry(Country country) {
    state = state.copyWith(
      selectedCountry: country,
      clearPhone: true,
      clearOperator: true,
      clearOperators: true,
      clearSelectedOperator: true,
      clearBundle: true,
    );
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone, clearOperator: true, clearOperators: true, clearSelectedOperator: true, clearBundle: true);
  }

  void setOperatorData(AutodetectData data) {
    state = state.copyWith(operatorData: data);
  }

  void setAvailableOperators(List<DataOperator> operators) {
    state = state.copyWith(availableOperators: operators);
  }

  void selectOperator(DataOperator operator) {
    state = state.copyWith(selectedOperator: operator, clearBundle: true);
  }

  void selectBundle(DataBundle bundle) {
    state = state.copyWith(selectedBundle: bundle);
  }

  void setCustomIdentifier(String identifier) {
    state = state.copyWith(customIdentifier: identifier);
  }

  void reset() {
    state = DataWizardState();
  }
}

final dataWizardProvider = StateNotifierProvider<DataWizardNotifier, DataWizardState>((ref) {
  return DataWizardNotifier();
});

