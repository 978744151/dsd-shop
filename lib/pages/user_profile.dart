import 'package:flutter/material.dart';

class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({Key? key}) : super(key: key);

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户协议与免责声明'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            _buildSectionTitle('用户协议与免责声明'),
            SizedBox(height: 8),
            Text(
              '最后更新日期：${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 24),

            // 重要提示
            _buildImportantNotice(),
            SizedBox(height: 20),

            // 知识产权声明
            _buildIntellectualPropertySection(),
            SizedBox(height: 20),

            // 免责声明
            _buildDisclaimerSection(),
            SizedBox(height: 20),

            // 用户责任
            _buildUserResponsibilitySection(),
            SizedBox(height: 20),

            // 服务条款
            _buildTermsOfServiceSection(),
            SizedBox(height: 20),

            // 同意按钮
            _buildAgreementButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '重要提示',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '请仔细阅读以下协议。使用本应用即表示您同意接受本协议的所有条款。',
            style: TextStyle(color: Colors.orange[800], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIntellectualPropertySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('知识产权声明'),
        SizedBox(height: 8),
        Text(
          '1. 本应用中提及的所有品牌名称、商标、Logo均归各自品牌权利人所有。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '2. 本应用对品牌信息的使用属于描述性、事实性使用，旨在为用户提供商场品牌信息查询和对比服务。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '3. 本应用与任何品牌方不存在官方授权、赞助或许可关系。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '4. 本应用不声称对任何第三方品牌拥有所有权或控制权。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDisclaimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('免责声明'),
        SizedBox(height: 8),
        Text(
          '1. 本应用提供的品牌信息仅供参考，不保证信息的准确性、完整性或及时性。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '2. 用户应知悉品牌信息可能随时变更，建议在使用前通过官方渠道核实相关信息。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '3. 本应用不对因使用品牌信息而导致的任何直接、间接损失承担责任。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '4. 品牌对比结果基于用户提供的数据生成，不代表本应用的官方推荐或评价。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUserResponsibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('用户责任'),
        SizedBox(height: 8),
        Text(
          '1. 用户应遵守相关法律法规，不得利用本应用从事任何侵权或违法行为。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '2. 用户不得将本应用信息用于商业用途或误导性宣传。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '3. 如用户发现侵权信息，应及时通过应用内反馈渠道通知我们。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '4. 用户应对其使用本应用的行为承担全部责任。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTermsOfServiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('服务条款'),
        SizedBox(height: 8),
        Text(
          '1. 本应用保留随时修改或终止服务的权利，恕不另行通知。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '2. 我们致力于保护用户隐私，具体政策请参阅《隐私政策》。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '3. 如有任何问题或建议，请通过应用内反馈功能联系我们。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          '4. 本协议的最终解释权归应用开发者所有。',
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildAgreementButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _saveAgreementStatus();
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          '同意并继续',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _saveAgreementStatus() {
    // 保存用户同意状态
  }
}