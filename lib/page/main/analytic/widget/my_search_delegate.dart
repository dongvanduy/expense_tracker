import 'package:expense_tracker/controls/spending_repository.dart';
import 'package:flutter/material.dart';

class MySearchDelegate extends SearchDelegate<String> {
  String q;
  bool check = true;
  String text;

  MySearchDelegate({required this.text, required this.q}) {
    query = q;
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        TextButton(
          onPressed: () {
            close(context, query);
          },
          child: Text(text),
        )
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () {
          close(context, q);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
      );

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (check) {
      query = q;
      check = false;
    }

    return FutureBuilder<List<String>>(
      future: SpendingRepository.getHistory(query),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  query = history[index];
                  showResults(context);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 20),
                        Text(
                          history[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            query = history[index];
                          },
                          icon: const Icon(Icons.call_made_rounded),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    const Divider(
                      height: 1,
                      endIndent: 20,
                      indent: 20,
                      color: Colors.black38,
                    )
                  ],
                ),
              );
            },
          );
        }
        return const Center(child: SingleChildScrollView());
      },
    );
  }

  @override
  void showResults(BuildContext context) {
    // super.showResults(context);
    if (query.isNotEmpty) {
      SpendingRepository.saveHistory(query);
      close(context, query);
    }
  }

  @override
  String? get searchFieldLabel => text;

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: Colors.black54, fontSize: 18);
}
