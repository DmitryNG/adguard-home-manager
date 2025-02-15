// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_split_view/flutter_split_view.dart';
import 'package:provider/provider.dart';
import 'package:store_checker/store_checker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/settings/general_settings/reorderable_top_items_home.dart';

import 'package:adguard_home_manager/widgets/custom_list_tile.dart';
import 'package:adguard_home_manager/widgets/section_label.dart';

import 'package:adguard_home_manager/functions/check_app_updates.dart';
import 'package:adguard_home_manager/functions/desktop_mode.dart';
import 'package:adguard_home_manager/functions/snackbar.dart';
import 'package:adguard_home_manager/functions/open_url.dart';
import 'package:adguard_home_manager/functions/app_update_download_link.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';

class GeneralSettings extends StatefulWidget {
  final bool splitView;

  const GeneralSettings({
    super.key,
    required this.splitView,
  });

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

enum AppUpdatesStatus { available, checking, recheck }

class _GeneralSettingsState extends State<GeneralSettings> {
  AppUpdatesStatus appUpdatesStatus = AppUpdatesStatus.recheck;

  @override
  Widget build(BuildContext context) {
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    final width = MediaQuery.of(context).size.width;

    Future updateSettings({
      required bool newStatus,
      required Future Function(bool) function
    }) async {
      final result = await function(newStatus);
      if (result == true) {
        showSnacbkar(
          appConfigProvider: appConfigProvider, 
          label: AppLocalizations.of(context)!.settingsUpdatedSuccessfully, 
          color: Colors.green
        );
      }
      else {
        showSnacbkar(
          appConfigProvider: appConfigProvider, 
          label: AppLocalizations.of(context)!.cannotUpdateSettings, 
          color: Colors.red
        );
      }
    }

    Future checkUpdatesAvailable() async {
      setState(() => appUpdatesStatus = AppUpdatesStatus.checking);
      
      final res = await checkAppUpdates(
        currentBuildNumber: appConfigProvider.getAppInfo!.buildNumber, 
        setUpdateAvailable: appConfigProvider.setAppUpdatesAvailable, 
        installationSource: appConfigProvider.installationSource,
        isBeta: appConfigProvider.getAppInfo!.version.contains('beta'),
      );

      if (!mounted) return;
      if (res != null) {
        setState(() => appUpdatesStatus = AppUpdatesStatus.available);
      }
      else {
        setState(() => appUpdatesStatus = AppUpdatesStatus.recheck);
      }
    }

    Widget generateAppUpdateStatus() {
      if (appUpdatesStatus == AppUpdatesStatus.available) {
        return IconButton(
          onPressed: appConfigProvider.appUpdatesAvailable != null
            ? () async {
                final link = getAppUpdateDownloadLink(appConfigProvider.appUpdatesAvailable!);
                if (link != null) {
                  openUrl(link);
                }
              }
            : null, 
          icon: const Icon(Icons.download_rounded),
          tooltip: AppLocalizations.of(context)!.downloadUpdate,
        );
      }
      else if (appUpdatesStatus == AppUpdatesStatus.checking) {
        return const Padding(
          padding: EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            )
          ),
        );
      }
      else {
        return IconButton(
          onPressed: checkUpdatesAvailable, 
          icon: const Icon(Icons.refresh_rounded),
          tooltip: AppLocalizations.of(context)!.checkUpdates,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generalSettings),
        surfaceTintColor: isDesktop(width) ? Colors.transparent : null,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            SectionLabel(label: AppLocalizations.of(context)!.home),
            CustomListTile(
              icon: Icons.exposure_zero_rounded,
              title: AppLocalizations.of(context)!.hideZeroValues,
              subtitle: AppLocalizations.of(context)!.hideZeroValuesDescription,
              trailing: Switch(
                value: appConfigProvider.hideZeroValues, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setHideZeroValues
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.hideZeroValues, 
                function: appConfigProvider.setHideZeroValues
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            CustomListTile(
              icon: Icons.show_chart_rounded,
              title: AppLocalizations.of(context)!.combinedChart,
              subtitle: AppLocalizations.of(context)!.combinedChartDescription,
              trailing: Switch(
                value: appConfigProvider.combinedChartHome, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setCombinedChartHome
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.combinedChartHome, 
                function: appConfigProvider.setCombinedChartHome
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            CustomListTile(
              icon: Icons.remove_red_eye_rounded,
              title: AppLocalizations.of(context)!.hideServerAddress,
              subtitle: AppLocalizations.of(context)!.hideServerAddressDescription,
              trailing: Switch(
                value: appConfigProvider.hideServerAddress, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setHideServerAddress
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.hideServerAddress, 
                function: appConfigProvider.setHideServerAddress
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            CustomListTile(
              icon: Icons.reorder_rounded,
              title: AppLocalizations.of(context)!.topItemsOrder,
              subtitle: AppLocalizations.of(context)!.topItemsOrderDescription,
              onTap: () => widget.splitView == true 
                ? SplitView.of(context).push(const ReorderableTopItemsHome())
                : Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReorderableTopItemsHome()
                    )
                  ) 
            ),
            CustomListTile(
              icon: Icons.donut_large_rounded,
              title: AppLocalizations.of(context)!.showTopItemsChart,
              subtitle: AppLocalizations.of(context)!.showTopItemsChartDescription,
              trailing: Switch(
                value: appConfigProvider.showTopItemsChart, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setShowTopItemsChart
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.showTopItemsChart, 
                function: appConfigProvider.setShowTopItemsChart
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            SectionLabel(label: AppLocalizations.of(context)!.logs),
            CustomListTile(
              icon: Icons.timer_rounded,
              title: AppLocalizations.of(context)!.timeLogs,
              subtitle: AppLocalizations.of(context)!.timeLogsDescription,
              trailing: Switch(
                value: appConfigProvider.showTimeLogs, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setshowTimeLogs
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.showTimeLogs, 
                function: appConfigProvider.setshowTimeLogs
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            CustomListTile(
              icon: Icons.more,
              title: AppLocalizations.of(context)!.ipLogs,
              subtitle: AppLocalizations.of(context)!.ipLogsDescription,
              trailing: Switch(
                value: appConfigProvider.showIpLogs, 
                onChanged: (value) => updateSettings(
                  newStatus: value, 
                  function: appConfigProvider.setShowIpLogs
                ),
              ),
              onTap: () => updateSettings(
                newStatus: !appConfigProvider.showIpLogs, 
                function: appConfigProvider.setShowIpLogs
              ),
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 10
              )
            ),
            if (
              !(Platform.isAndroid || Platform.isIOS) || 
              (Platform.isAndroid && (
                appConfigProvider.installationSource == Source.IS_INSTALLED_FROM_LOCAL_SOURCE ||
                appConfigProvider.installationSource == Source.IS_INSTALLED_FROM_PLAY_PACKAGE_INSTALLER ||
                appConfigProvider.installationSource == Source.UNKNOWN
              ))
            ) ...[
              SectionLabel(label: AppLocalizations.of(context)!.application),
              CustomListTile(
                icon: Icons.system_update_rounded,
                title: AppLocalizations.of(context)!.appUpdates,
                subtitle: appConfigProvider.appUpdatesAvailable != null
                  ? AppLocalizations.of(context)!.updateAvailable
                  : AppLocalizations.of(context)!.usingLatestVersion,
                trailing: generateAppUpdateStatus()
              )
            ]
          ],
        ),
      )
    );  
  }
}