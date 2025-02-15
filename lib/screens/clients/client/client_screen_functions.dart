import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:adguard_home_manager/screens/clients/client/client_screen.dart';
import 'package:adguard_home_manager/screens/clients/client/remove_client_modal.dart';
import 'package:adguard_home_manager/screens/clients/client/safe_search_modal.dart';
import 'package:adguard_home_manager/screens/clients/client/services_modal.dart';
import 'package:adguard_home_manager/screens/clients/client/tags_modal.dart';

import 'package:adguard_home_manager/models/clients.dart';
import 'package:adguard_home_manager/providers/clients_provider.dart';
import 'package:adguard_home_manager/models/safe_search.dart';

void openTagsModal({
  required BuildContext context,
  required List<String> selectedTags,
  required void Function(List<String>) onSelectedTags
}) {
  showDialog(
    context: context, 
    builder: (context) => TagsModal(
      selectedTags: selectedTags,
      tags: Provider.of<ClientsProvider>(context, listen: false).clients!.supportedTags,
      onConfirm: onSelectedTags,
    )
  );
}

void openServicesModal({
  required BuildContext context,
  required List<String> blockedServices,
  required void Function(List<String>) onUpdateBlockedServices
}) {
  showDialog(
    context: context, 
    builder: (context) => ServicesModal(
      blockedServices: blockedServices,
      onConfirm: onUpdateBlockedServices,
    )
  );
}

void openDeleteClientScreen({
  required BuildContext context,
  required void Function() onDelete
}) {
  showDialog(
    context: context, 
    builder: (ctx) => RemoveClientModal(
      onConfirm: () {
        Navigator.pop(context);
        onDelete();
      }
    )
  );
}

void openSafeSearchModal({
  required BuildContext context,
  required List<String> blockedServices,
  required void Function(SafeSearch) onUpdateSafeSearch,
  required SafeSearch? safeSearch,
  required SafeSearch defaultSafeSearch
}) {
  showDialog(
    context: context, 
    builder: (context) => SafeSearchModal(
      safeSearch: safeSearch ?? defaultSafeSearch, 
      disabled: false,
      onConfirm: onUpdateSafeSearch
    )
  );
}

void openClientFormModal({
  required BuildContext context,
  required double width,
  Client? client,
  required void Function(Client) onConfirm,
  void Function(Client)? onDelete,
}) {
  showGeneralDialog(
    context: context, 
    barrierColor: !(width > 900 || !(Platform.isAndroid | Platform.isIOS))
      ?Colors.transparent 
      : Colors.black54,
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1), 
          end: const Offset(0, 0)
        ).animate(
          CurvedAnimation(
            parent: anim1, 
            curve: Curves.easeInOutCubicEmphasized
          )
        ),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => ClientScreen(
      fullScreen: !(width > 900 || !(Platform.isAndroid | Platform.isIOS)),
      client: client,
      onConfirm: onConfirm,
      onDelete: onDelete,
    ),
  );
}

bool validateNumber(String value) {
  if (value == "") return true;
  final regexp = RegExp(r'^\d+$');
  return regexp.hasMatch(value);
}