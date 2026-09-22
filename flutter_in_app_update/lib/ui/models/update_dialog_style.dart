import 'package:flutter/material.dart';

/// Styling options for the built-in update dialogs.
class UpdateDialogStyle {
  /// The title text of the dialog.
  final String? title;

  /// The description text of the dialog.
  final String? description;

  /// Text for the update/install button.
  final String? updateButtonText;

  /// Text for the later/cancel button.
  final String? laterButtonText;

  /// Background color of the dialog.
  final Color? backgroundColor;

  /// Text style for the title.
  final TextStyle? titleStyle;

  /// Text style for the description.
  final TextStyle? descriptionStyle;

  /// Button style for the primary action button.
  final ButtonStyle? updateButtonStyle;
  
  /// Button style for the secondary action button.
  final ButtonStyle? laterButtonStyle;

  const UpdateDialogStyle({
    this.title,
    this.description,
    this.updateButtonText,
    this.laterButtonText,
    this.backgroundColor,
    this.titleStyle,
    this.descriptionStyle,
    this.updateButtonStyle,
    this.laterButtonStyle,
  });
}
