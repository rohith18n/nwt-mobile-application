import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_result_parser.dart';
import 'package:nwt_app/services/account_aggregators/finarkein_data_store.dart';
import 'package:nwt_app/services/assets/banks/transactions/bank_transactions.dart';
import 'package:nwt_app/services/assets/investments/transactions/investment_transactions.dart';
import 'package:nwt_app/types/finarkein/firnarkein_data_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Finarkein parsing + service overrides', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });

    test(
      '*.transactions do not inflate holdings; transactions are parsed separately',
      () {
        final data = <String, dynamic>{
          'deposit.summary': [
            ['linkedAccRef', 'maskedAccNumber', 'fipName', 'currentValue'],
            ['ACC1', 'XXXX1234', 'HDFC', 1000],
          ],
          'deposit.transactions': [
            [
              'linkedAccRef',
              'amount',
              'type',
              'transactiontimestamp',
              'narration',
              'balanceaftertransaction',
              'txnid',
            ],
            [
              'ACC1',
              50,
              'DEBIT',
              '2026-01-01T10:00:00Z',
              'Coffee',
              950,
              'TXN1',
            ],
            [
              'ACC1',
              200,
              'CREDIT',
              '2026-01-02T10:00:00Z',
              'Salary',
              1150,
              'TXN2',
            ],
          ],
          'equities.summary': [
            ['linkedAccRef', 'issuerName', 'currentValue', 'units'],
            ['EQ1', 'ABC', 5000, 10],
          ],
          'equities.transactions': [
            [
              'isin',
              'transactionDateTime',
              'amount',
              'type',
              'units',
              'issuerName',
            ],
            ['IN123', '2026-01-03T10:00:00Z', 1000, 'BUY', 2, 'ABC'],
            ['IN123', '2026-01-04T10:00:00Z', 500, 'SELL', 1, 'ABC'],
          ],
        };

        final parsed = FinarkeinDataResultParser.parse(data);

        // Holdings must come ONLY from *.summary keys
        expect(parsed.banks.length, 1);
        expect(parsed.banks.first.currentvalue, 1000);
        expect(parsed.stocks.length, 1);

        // Transactions must be available separately
        expect(parsed.bankTransactions.length, 2);
        expect(parsed.equityTransactions.length, 2);
      },
    );

    test(
      'BankTransactionService returns in-memory Finarkein transactions with filters/pagination',
      () async {
        final store = Get.put(FinarkeinDataStore());

        final data = <String, dynamic>{
          'deposit.summary': [
            ['linkedAccRef', 'maskedAccNumber', 'fipName', 'currentValue'],
            ['ACC1', 'XXXX1234', 'HDFC', 1000],
          ],
          'deposit.transactions': [
            [
              'linkedAccRef',
              'amount',
              'type',
              'transactiontimestamp',
              'narration',
              'balanceaftertransaction',
              'txnid',
            ],
            [
              'ACC1',
              50,
              'DEBIT',
              '2026-01-01T10:00:00Z',
              'Coffee',
              950,
              'TXN1',
            ],
            [
              'ACC1',
              200,
              'CREDIT',
              '2026-01-02T10:00:00Z',
              'Salary',
              1150,
              'TXN2',
            ],
          ],
        };
        store.setFromParsedResult(FinarkeinDataResultParser.parse(data));

        final service = BankTransactionService();
        final res = await service.getBankTransactions(
          bankGUIDs: ['ACC1'],
          amountMin: 100,
          page: 0,
          limit: 1,
          onLoading: (_) {},
        );

        expect(res.success, true);
        expect(res.data, isNotNull);
        expect(res.data!.banktransations.length, 1);
        // Newest matching transaction is Salary (200)
        expect(res.data!.banktransations.first.txnid, 'TXN2');
        expect(res.data!.pagination, isNotNull);
        expect(res.data!.pagination!.total, 1);
        expect(res.data!.pagination!.totalpages, 1);
      },
    );

    test(
      'InvestmentTransactionService returns in-memory Finarkein transactions filtered by isin',
      () async {
        final store = Get.put(FinarkeinDataStore());

        final data = <String, dynamic>{
          'equities.transactions': [
            [
              'isin',
              'transactionDateTime',
              'amount',
              'type',
              'units',
              'issuerName',
            ],
            ['IN123', '2026-01-03T10:00:00Z', 1000, 'BUY', 2, 'ABC'],
            ['IN123', '2026-01-04T10:00:00Z', 500, 'SELL', 1, 'ABC'],
          ],
        };
        store.setFromParsedResult(FinarkeinDataResultParser.parse(data));

        final service = InvestmentTransactionService();
        final res = await service.getInvestmentTransactions(
          onLoading: (_) {},
          page: 1,
          limit: 1,
          isinCode: 'IN123',
        );

        expect(res, isNotNull);
        expect(res!.statusCode, 200);
        expect(res.data, isNotNull);
        final count =
            res.data!.equities.length +
            res.data!.mfs.length +
            res.data!.etfs.length;
        expect(count, 1);
        expect(res.data!.equities.length, 1);
        // Newest is 2026-01-04
        expect(res.data!.equities.first.txnamount, 500);
        expect(res.data!.equities.first.brokercode, 'IN123');
      },
    );

    test(
      'FinarkeinDataResponse parses real JSON with int->double conversion',
      () {
        final json = {
          "statusCode": 200,
          "message": "AA result fetched successfully",
          "data": {
            "summary": {
              "totalinvestedamount": 480000,
              "totalinvestmentamount": 480000,
              "toalinvestmentamount": 480000,
              "totalbankamount": 183211.93,
              "totalinsuranceamount": null,
              "totalequitiesamount": 14532,
              "totalmfandetfamount": 483367.73,
              "totalpersonalassetamount": 681111.6599999999,
              "totalnpsamount": null,
              "totalcurrentvalue": 681111.6599999999,
              "networth": 681111.6599999999,
              "totalunrealisedgain": null,
              "totalrealisedgain": null,
              "totalgain": null,
              "totalgainpercentage": null,
              "dailygain": 1250.5,
              "dailygainpercentage": 1.82,
              "absolutereturnpercentage": null,
              "portfolioxirr": 14.25,
              "onedaychangeamount": null,
              "onedaychangepercentage": null,
            },
          },
        };

        final response = FinarkeinDataResponse.fromJson(json);

        expect(response.statusCode, 200);
        expect(response.data, isNotNull);
        expect(response.data!.summary, isNotNull);

        // Verify integer fields in JSON are doubles in model
        expect(response.data!.summary['totalinvestedamount'], 480000.0);
        expect(response.data!.summary['totalequitiesamount'], 14532.0);

        // Verify decimal fields
        expect(response.data!.summary['totalbankamount'], 183211.93);
        expect(response.data!.summary['dailygain'], 1250.5);
      },
    );
    test(
      'FinarkeinDataResponse handles top-level asset keys in data block',
      () {
        final json = {
          "statusCode": 200,
          "message": "Success",
          "data": {
            "summary": {"totalbankamount": 100},
            "deposit.summary": [
              ["linkedAccRef", "currentValue"],
              ["ACC1", 100],
            ],
            "insurance.summary": [
              ["account_guid", "sum_assured"],
              ["INS1", 50000],
            ],
            "aaData": {
              "equities.summary": [
                ["isin", "currentValue"],
                ["ISIN1", 200],
              ],
            },
          },
        };

        final response = FinarkeinDataResponse.fromJson(json);
        final aaData = response.data?.aaData;

        expect(aaData, isNotNull);
        // Should capture top-level deposit.summary
        expect(aaData!.allData.containsKey("deposit.summary"), true);
        expect(aaData.allData["deposit.summary"]!.length, 2);

        // Should capture top-level insurance.summary
        expect(aaData.allData.containsKey("insurance.summary"), true);
        expect(aaData.allData["insurance.summary"]!.length, 2);

        // Should capture nested equities.summary
        expect(aaData.allData.containsKey("equities.summary"), true);
        expect(aaData.allData["equities.summary"]!.length, 2);
      },
    );
  });
}
