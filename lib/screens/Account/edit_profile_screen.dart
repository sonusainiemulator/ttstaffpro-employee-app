import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/dio_api/repositories/profile_repository.dart';
import 'package:open_core_hr/main.dart';
import 'package:open_core_hr/utils/app_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileRepo = ProfileRepository();
  final _picker = ImagePicker();

  late final TextEditingController _phoneCont;
  late final TextEditingController _altPhoneCont;
  late final TextEditingController _addressCont;

  String? _selectedGender;
  File? _pickedImage;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  static const _genders = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    _phoneCont = TextEditingController(text: getStringAsync(phoneNumberPref));
    _altPhoneCont =
        TextEditingController(text: getStringAsync(alternateNumberPref));
    _addressCont = TextEditingController(text: getStringAsync(addressPref));
    final stored = getStringAsync(genderPref).toLowerCase();
    _selectedGender = _genders.contains(stored) ? stored : null;
  }

  @override
  void dispose() {
    _phoneCont.dispose();
    _altPhoneCont.dispose();
    _addressCont.dispose();
    super.dispose();
  }

  // ── Photo picking ────────────────────────────────────────────────────────

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(language.lblSelectImage,
                  style: boldTextStyle(size: 16)),
              const SizedBox(height: 16),
              _sourceOption(
                icon: Icons.camera_alt_rounded,
                label: language.lblCamera,
                onTap: () {
                  finish(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _sourceOption(
                icon: Icons.photo_library_rounded,
                label: language.lblGallery,
                onTap: () {
                  finish(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImage != null || sharedHelper.hasProfileImage())
                _sourceOption(
                  icon: Icons.delete_rounded,
                  label: language.lblRemove,
                  color: Colors.redAccent,
                  onTap: () {
                    finish(context);
                    setState(() => _pickedImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? appStore.appColorPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: c),
      ),
      title: Text(label, style: primaryTextStyle()),
      onTap: onTap,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xfile == null) return;
    setState(() => _pickedImage = File(xfile.path));
  }

  // ── Upload photo ─────────────────────────────────────────────────────────

  Future<bool> _uploadPhoto() async {
    if (_pickedImage == null) return true;
    setState(() => _isUploadingPhoto = true);
    final url = await _profileRepo.uploadAvatar(_pickedImage!.path);
    setState(() => _isUploadingPhoto = false);
    if (url != null) {
      await setValue(avatarPref, url);
      return true;
    }
    toast(language.lblSomethingWentWrongWhileUploadingTheFile);
    return false;
  }

  // ── Save text fields ─────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    hideKeyboard(context);
    setState(() => _isSaving = true);

    final photoOk = await _uploadPhoto();
    if (!photoOk) {
      setState(() => _isSaving = false);
      return;
    }

    final payload = {
      'phoneNumber': _phoneCont.text.trim(),
      'alternateNumber': _altPhoneCont.text.trim(),
      'address': _addressCont.text.trim(),
      if (_selectedGender != null) 'gender': _selectedGender,
    };

    final ok = await _profileRepo.updateProfile(payload);
    if (ok) {
      await setValue(phoneNumberPref, _phoneCont.text.trim());
      await setValue(alternateNumberPref, _altPhoneCont.text.trim());
      await setValue(addressPref, _addressCont.text.trim());
      if (_selectedGender != null) {
        await setValue(genderPref, _selectedGender!);
      }
      toast(language.lblProfileUpdatedSuccessfully);
      if (!mounted) return;
      finish(context, true);
    } else {
      toast(language.lblPleaseTryAgainLater);
    }
    setState(() => _isSaving = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? const Color(0xFF111827)
          : const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor:
            appStore.isDarkModeOn ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: appStore.isDarkModeOn ? Colors.white : const Color(0xFF111827),
              size: 20),
          onPressed: () => finish(context),
        ),
        title: Text(
          language.lblEditProfile,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: appStore.isDarkModeOn ? Colors.white : const Color(0xFF111827),
          ),
        ),
        actions: [
          if (_isSaving || _isUploadingPhoto)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                language.lblSave,
                style: TextStyle(
                  color: appStore.appColorPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 28),
              _buildSectionLabel(language.lblContactInformation),
              const SizedBox(height: 12),
              _buildField(
                controller: _phoneCont,
                label: language.lblPhone,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return language.lblPhoneNumberIsRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _altPhoneCont,
                label: language.lblAlternateNumber,
                icon: Icons.phone_forwarded_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),
              _buildSectionLabel(language.lblPersonalDetails),
              const SizedBox(height: 12),
              _buildGenderDropdown(),
              const SizedBox(height: 12),
              _buildField(
                controller: _addressCont,
                label: language.lblAddress,
                icon: Icons.location_on_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isUploadingPhoto) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appStore.appColorPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: (_isSaving || _isUploadingPhoto)
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          language.lblSaveChanges,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final bool hasCurrentAvatar =
        _pickedImage != null || sharedHelper.hasProfileImage();

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPhotoPicker,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appStore.appColorPrimary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor:
                        appStore.appColorPrimary.withOpacity(0.15),
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : sharedHelper.hasProfileImage()
                            ? NetworkImage(sharedHelper.getProfileImage())
                            : null,
                    child: !hasCurrentAvatar
                        ? Text(
                            sharedHelper.getUserInitials(),
                            style: boldTextStyle(size: 28, color: appStore.appColorPrimary),
                          )
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appStore.appColorPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            language.lblTapToChangePhoto,
            style: secondaryTextStyle(size: 13),
          ),
          if (_isUploadingPhoto) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: appStore.appColorPrimary,
                backgroundColor: appStore.appColorPrimary.withOpacity(0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: appStore.isDarkModeOn
              ? Colors.grey[400]
              : const Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(appStore.isDarkModeOn ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: appStore.isDarkModeOn ? Colors.white : const Color(0xFF111827),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: appStore.isDarkModeOn
                ? Colors.grey[400]
                : const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon,
              color: appStore.appColorPrimary.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: appStore.appColorPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: appStore.isDarkModeOn ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(appStore.isDarkModeOn ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(
          labelText: language.lblGender,
          labelStyle: TextStyle(
            color: appStore.isDarkModeOn
                ? Colors.grey[400]
                : const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
          prefixIcon: Icon(Icons.wc_rounded,
              color: appStore.appColorPrimary.withOpacity(0.7), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: appStore.appColorPrimary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor:
            appStore.isDarkModeOn ? const Color(0xFF1F2937) : Colors.white,
        style: TextStyle(
          color: appStore.isDarkModeOn ? Colors.white : const Color(0xFF111827),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        items: _genders
            .map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g[0].toUpperCase() + g.substring(1)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedGender = v),
      ),
    );
  }
}
