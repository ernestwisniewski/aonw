class AssetAdjustmentSaveResult {
  final bool saved;
  final String message;

  const AssetAdjustmentSaveResult({required this.saved, required this.message});
}

Future<AssetAdjustmentSaveResult> saveAssetAdjustmentsJson(String json) async {
  return const AssetAdjustmentSaveResult(
    saved: false,
    message: 'Saving asset config is available in desktop dev builds.',
  );
}
