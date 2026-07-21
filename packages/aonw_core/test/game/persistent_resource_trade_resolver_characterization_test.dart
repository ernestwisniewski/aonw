import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'support/persistent_resource_trade_characterization_fixture.dart';
part 'support/persistent_resource_trade_exchange_characterization_cases.dart';
part 'support/persistent_resource_trade_gold_characterization_cases.dart';

void main() {
  _registerGoldResourceTradeCharacterizationTests();
  _registerResourceExchangeCharacterizationTests();
}
