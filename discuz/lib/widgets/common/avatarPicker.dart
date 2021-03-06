import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:discuzq/utils/permissionHepler.dart';
import 'package:discuzq/utils/request/urls.dart';
import 'package:discuzq/utils/request/request.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/states/scopedState.dart';
import 'package:discuzq/states/appState.dart';
import 'package:discuzq/utils/authHelper.dart';

class AvatarPicker extends StatefulWidget {
  final Widget avatar;
  final Function onSuccess;
  AvatarPicker({Key key, this.avatar, this.onSuccess});

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

enum PickerState {
  free,
  picked,
  cropped,
}

class _AvatarPickerState extends State<AvatarPicker> {
  PickerState pickerState;
  File imageFile;

  @override
  void initState() {
    super.initState();
    pickerState = PickerState.free;
  }

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScopedStateModelDescendant<AppState>(
      rebuildOnChange: true,
      builder: (context, child, state) => GestureDetector(
            onTap: () {
              // open avatar seletor
              _clearImage();
              _pickImage(state: state);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  child: widget.avatar,
                  onTap: () {
                    // open avatar seletor
                    _clearImage();
                    _pickImage(state: state);
                  },
                ),
              ],
            ),
          ));

  ///
  /// 选择图片
  Future<Null> _pickImage({AppState state}) async {
    final bool havePermission =
        await PermissionHelper.checkWithNotice(PermissionGroup.photos);
    if (havePermission == false) {
      return;
    }
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        pickerState = PickerState.picked;
      });
      _cropImage(state: state);
    }
  }

  ///
  /// 图片剪裁
  Future<Null> _cropImage({AppState state}) async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        aspectRatio: CropAspectRatio(ratioX: 100, ratioY: 100),
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ));

    if (croppedFile != null) {
      setState(() {
        imageFile = croppedFile;
        pickerState = PickerState.cropped;
      });

      Function close = DiscuzToast.loading();
      final bool result = await _uploadAvatar(state: state);
      close();

      DiscuzToast.show(
          context: context,
          message: result == true ? '头像上传成功' : '上传失败，可能是网络问题，请重试。');
      if (result == true) {
        if (widget.onSuccess != null) {
          widget.onSuccess();
        }

        /// 刷新用户资料
        await AuthHelper.refreshUser(context: context, state: state);
      }
      // should clear image success or failed
      _clearImage();
    }
  }

  ///
  /// 压缩文件
  ///
  Future<File> compressAndGetFile(File file, String targetPath) async {
    return await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 200,
      minHeight: 200,
      rotate: 0,
    );
  }

  ///
  /// 上传头像
  Future<bool> _uploadAvatar({AppState state}) async {
    if (imageFile != null) {
      try {
        Directory appDocDir = await getTemporaryDirectory();
        File compressedFile = await compressAndGetFile(
            imageFile, appDocDir.path + path.basename(imageFile.path));
        final Response resp = await Request(context: context).uploadFile(
            url: "${Urls.users}/${state.user.id.toString()}/avatar",
            name: 'avatar',

            /// 上传头像
            file: MultipartFile.fromFileSync(compressedFile.path));
        
        if (resp == null) {
          return Future.value(false);
        }

        return Future.value(true);
      } catch (e) {
        print("Error on upload avatar: $e");
        return Future.value(false);
      }
    }

    return Future.value(false);
  }

  void _clearImage() {
    imageFile = null;
    setState(() {
      pickerState = PickerState.free;
    });
  }
}
