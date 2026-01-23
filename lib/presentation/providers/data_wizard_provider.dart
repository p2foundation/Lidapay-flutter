import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/api_models.dart';

class DataWizardState {
  final Country? selectedCountry;
  final String? phoneNumber;
  final AutodetectData? operatorData;
  final List<DataOperator>? availableOperators;
  final DataOperator? selectedOperator;
  final DataBundle? selectedBundle;
  final Map<int, Map<String, dynamic>>? operatorMetadata;
  final String? customIdentifier;
  final int? selectedGhanaNetworkCode;

  DataWizardState({
    this.selectedCountry,
    this.phoneNumber,
    this.operatorData,
    this.availableOperators,
    this.selectedOperator,
    this.selectedBundle,
    this.operatorMetadata,
    this.customIdentifier,
    this.selectedGhanaNetworkCode,
  });

  DataWizardState copyWith({
    Country? selectedCountry,
    String? phoneNumber,
    AutodetectData? operatorData,
    List<DataOperator>? availableOperators,
    DataOperator? selectedOperator,
    DataBundle? selectedBundle,
    Map<int, Map<String, dynamic>>? operatorMetadata,
    String? customIdentifier,
    int? selectedGhanaNetworkCode,
    bool clearCountry = false,
    bool clearPhone = false,
    bool clearOperator = false,
    bool clearOperators = false,
    bool clearSelectedOperator = false,
    bool clearBundle = false,
    bool clearOperatorMetadata = false,
    bool clearIdentifier = false,
    bool clearGhanaNetwork = false,
  }) {
    return DataWizardState(
      selectedCountry: clearCountry ? null : (selectedCountry ?? this.selectedCountry),
      phoneNumber: clearPhone ? null : (phoneNumber ?? this.phoneNumber),
      operatorData: clearOperator ? null : (operatorData ?? this.operatorData),
      availableOperators: clearOperators ? null : (availableOperators ?? this.availableOperators),
      selectedOperator: clearSelectedOperator ? null : (selectedOperator ?? this.selectedOperator),
      selectedBundle: clearBundle ? null : (selectedBundle ?? this.selectedBundle),
      operatorMetadata: clearOperatorMetadata ? null : (operatorMetadata ?? this.operatorMetadata),
      customIdentifier: clearIdentifier ? null : (customIdentifier ?? this.customIdentifier),
      selectedGhanaNetworkCode: clearGhanaNetwork ? null : (selectedGhanaNetworkCode ?? this.selectedGhanaNetworkCode),
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
      clearOperatorMetadata: true,
      clearGhanaNetwork: true,
    );
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(
      phoneNumber: phone,
      clearOperator: true,
      clearOperators: true,
      clearSelectedOperator: true,
      clearBundle: true,
      clearOperatorMetadata: true,
      clearGhanaNetwork: true,
    );
  }

  void setOperatorData(AutodetectData data) {
    state = state.copyWith(operatorData: data);
  }

  void setAvailableOperators(List<DataOperator> operators) {
    state = state.copyWith(availableOperators: operators);
  }

  void setOperatorMetadata(Map<int, Map<String, dynamic>> metadata) {
    state = state.copyWith(operatorMetadata: metadata);
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

  void setSelectedGhanaNetwork(int? networkCode) {
    state = state.copyWith(selectedGhanaNetworkCode: networkCode);
  }

  void reset() {
    state = DataWizardState();
  }
}

final dataWizardProvider = StateNotifierProvider<DataWizardNotifier, DataWizardState>((ref) {
  return DataWizardNotifier();
});

