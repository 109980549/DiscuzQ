import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/widgets/editor/discuzEditorRequestResult.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

import 'package:discuzq/models/postModel.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/widgets/common/discuzIcon.dart';
import 'package:discuzq/widgets/posts/postLikeButton.dart';
import 'package:discuzq/widgets/share/shareNative.dart';
import 'package:discuzq/widgets/ui/ui.dart';
import 'package:discuzq/widgets/editor/discuzEditorHelper.dart';

///
/// 按钮图标的大小
const double _kIconsize = 22;

class ThreadCardQuickActions extends StatelessWidget {
  ///
  /// 首贴
  final PostModel firstPost;

  ///
  /// 关联帖子
  final ThreadModel thread;

  const ThreadCardQuickActions({@required this.firstPost, @required this.thread});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ///
          /// 点赞按钮
          PostLikeButton(
              size: _kIconsize,
              post: firstPost,
            ),

          ///
          /// 评论按钮
          IconButton(
            icon: DiscuzIcon(
              SFSymbols.bubble_left_bubble_right,
              size: _kIconsize,
              color: DiscuzApp.themeOf(context).textColor,
            ),
            onPressed: () async {
              final DiscuzEditorRequestResult res =
                  await DiscuzEditorHelper(context: context)
                      .reply(post: firstPost, thread: thread);
              if (res != null) {
                ////
                /// 这种时候，用户是在卡片操作回复的，仅提示回复成功即可
                DiscuzToast.success(context: context, message: '回复成功');
              }
            },
          ),

                    ///
          /// 分享按钮
          IconButton(
            icon: DiscuzIcon(
              SFSymbols.square_arrow_up,
              size: _kIconsize,
              color: DiscuzApp.themeOf(context).textColor,
            ),
            onPressed: () => ShareNative.shareThread(thread: thread),
          ),
        ],
      ),
    );
  }
}
