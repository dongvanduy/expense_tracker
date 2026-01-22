import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../controls/spending_repository.dart';
import '../../../../models/spending.dart';
import '../../../../setting/localization/app_localizations.dart';

class SummarySpending extends StatefulWidget {
  const SummarySpending({Key? key, this.spendingList}) : super(key: key);
  final List<Spending>? spendingList;

  @override
  State<SummarySpending> createState() => _SummarySpendingState();
}

class _SummarySpendingState extends State<SummarySpending> {
  final numberFormat = NumberFormat.currency(locale: "vi_VI");

  @override
  Widget build(BuildContext context) {
    return widget.spendingList != null
        ? FutureBuilder<int>(
            future: SpendingRepository.getWallet(DateTime.now()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final wallet = snapshot.data ?? 0;
                final sum = widget.spendingList!.fold<int>(
                  0,
                  (value, element) => value + element.money,
                );
                return body(wallet, sum);
              }
              return loadingSummary();
            },
          )
        : loadingSummary();
  }

  Widget body(var wallet, var sum) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.background,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('first_balance'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    numberFormat.format(wallet),
                    style: const TextStyle(fontSize: 18),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('final_balance'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    numberFormat.format(wallet + sum),
                    style: const TextStyle(fontSize: 18),
                  )
                ],
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    "${sum > 0 ? "+" : ""}${numberFormat.format(sum)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loadingSummary() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.background,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('first_balance'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  textLoading()
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('final_balance'),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  textLoading()
                ],
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 2,
                color: Colors.black,
              ),
              const SizedBox(height: 10),
              Row(
                children: [const Spacer(), textLoading()],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 25,
        width: Random().nextInt(50) + 100,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
