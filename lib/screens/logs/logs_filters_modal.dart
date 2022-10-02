// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/functions/format_time.dart';
import 'package:adguard_home_manager/providers/logs_provider.dart';

class LogsFiltersModal extends StatelessWidget {
  const LogsFiltersModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logsProvider = Provider.of<LogsProvider>(context);
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    void selectTime() async {
      DateTime now = DateTime.now();
      DateTime? dateValue = await showDatePicker(
        context: context, 
        initialDate: now, 
        firstDate: DateTime(now.year, now.month-1, now.day), 
        lastDate: now
      );
      if (dateValue != null) {
        TimeOfDay? timeValue = await showTimePicker(
          context: context, 
          initialTime: TimeOfDay.now(),
          helpText: AppLocalizations.of(context)!.selectTime,
        );
        if (timeValue != null) {
          DateTime value = DateTime(
            dateValue.year,
            dateValue.month,
            dateValue.day,
            timeValue.hour,
            timeValue.minute,
            dateValue.second
          ).toUtc();

          logsProvider.setLogsOlderThan(value);

          logsProvider.setLoadStatus(0);

          logsProvider.setOffset(0);

          final result = await getLogs(
            server: serversProvider.selectedServer!, 
            count: logsProvider.logsQuantity,
            olderThan: logsProvider.logsOlderThan
          );
          if (result['result'] == 'success') {
            logsProvider.setLogsData(result['data']);
            logsProvider.setLoadStatus(1);
          }
          else {
            appConfigProvider.addLog(result['log']);
            logsProvider.setLoadStatus(2);
          }
        }
      }
    }

    void resetFilters() async {
      logsProvider.setLoadStatus(0);

      logsProvider.resetFilters();

      final result = await getLogs(
        server: serversProvider.selectedServer!, 
        count: logsProvider.logsQuantity
      );

      if (result['result'] == 'success') {
        logsProvider.setLogsData(result['data']);
        logsProvider.setLoadStatus(1);
      }
      else {
        appConfigProvider.addLog(result['log']);
        logsProvider.setLoadStatus(2);
      }
    }

    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28)
        )
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 24,
              bottom: 20,
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 26,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.filters,
            style: const TextStyle(
              fontSize: 24
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: selectTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 24,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.logsOlderThan,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                logsProvider.logsOlderThan != null
                                  ? formatTimestampUTC(logsProvider.logsOlderThan!, 'HH:mm - dd/MM/yyyy')
                                  : AppLocalizations.of(context)!.notSelected,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 24,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.responseStatus,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "12/12/2000",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: resetFilters, 
                  child: Text(AppLocalizations.of(context)!.resetFilters)
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(AppLocalizations.of(context)!.close)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}