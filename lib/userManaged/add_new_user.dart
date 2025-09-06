import 'package:flutter/material.dart';
import 'package:pentype_probe_viewer/database/database.dart';

class AddNewUser extends StatefulWidget {
  const AddNewUser({super.key});

  @override
  State<AddNewUser> createState() => _AddNewUserState();
}

class _AddNewUserState extends State<AddNewUser> {
  final dbHelper = DatabaseHelper();

  final TextEditingController _idTextEditingController =
      TextEditingController();
  final TextEditingController _nameTextEditingController =
  TextEditingController();
  final TextEditingController _pwTextEditingController =
      TextEditingController();
  final TextEditingController _reEnterTextEditingController =
      TextEditingController();

  final FocusNode _idTextFieldFocusNode = FocusNode();
  final FocusNode _nameTextFieldFocusNode = FocusNode();
  final FocusNode _pwTextFieldFocusNode = FocusNode();
  final FocusNode _reEnterTextFieldFocusNode = FocusNode();

  final List<String> _authorities = ['USER', 'ADMIN'];

  late String _selectedAuthority;
  late bool _isButtonEnabled;
  late String _message;

  void _checkInput() {
    setState(() {
      _isButtonEnabled = _idTextEditingController.text.trim().isNotEmpty &&
          _pwTextEditingController.text.trim().isNotEmpty &&
          _pwTextEditingController.text.trim().isNotEmpty;
    });
  }

  Future<void> _addUser() async {
    _message = "";

    _idTextFieldFocusNode.unfocus();
    _pwTextFieldFocusNode.unfocus();
    _reEnterTextFieldFocusNode.unfocus();

    String userId = _idTextEditingController.text.trim();
    String userName = _nameTextEditingController.text.trim();
    String userPw = _pwTextEditingController.text;
    String userPwReEnter = _reEnterTextEditingController.text;

    if (userPw != userPwReEnter) {
      setState(() {
        _message = "비밀번호 재입력이 틀립니다.";
      });
      return;
    }

    final db = await dbHelper.database;

    // 아이디 중복 확인
    final existingUsers = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (existingUsers.isNotEmpty) {
      setState(() {
        _message = "이미 존재하는 아이디입니다.";
      });
      return;
    }

    // 비밀번호 해시 및 salt 생성
    String salt = generateSalt();
    String hashedPassword = hashPassword(userPw, salt);

    // 사용자 추가
    await db.insert('users', {
      'user_id': userId,
      'password': hashedPassword,
      'salt': salt,
      'name': userName,
      'authority': _selectedAuthority,
      'is_locked': 0,
      'login_attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': null,
      'deleted_at': null,
    });

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    _isButtonEnabled = false;

    _message = "";

    _idTextEditingController.addListener(_checkInput);
    _nameTextEditingController.addListener(_checkInput);
    _pwTextEditingController.addListener(_checkInput);
    _reEnterTextFieldFocusNode.addListener(_checkInput);

    _selectedAuthority = 'USER';
  }

  @override
  void dispose() {
    super.dispose();

    _idTextEditingController.dispose();
    _nameTextEditingController.dispose();
    _pwTextEditingController.dispose();
    _reEnterTextEditingController.dispose();

    _idTextFieldFocusNode.dispose();
    _nameTextFieldFocusNode.dispose();
    _pwTextFieldFocusNode.dispose();
    _reEnterTextFieldFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          _idTextFieldFocusNode.unfocus();
          _pwTextFieldFocusNode.unfocus();
        },
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: screenWidth * 0.05,
                  ),
                  Container(
                    height: screenWidth * 0.075,
                    child: Image.asset("assets/images/logo.png"),
                  ),
                  SizedBox(
                    height: screenWidth * 0.025,
                  ),
                  Container(
                    height: screenWidth * 0.05,
                    width: screenWidth * 0.4,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _idTextFieldFocusNode,
                            controller: _idTextEditingController,
                            style: TextStyle(fontSize: screenWidth * 0.02),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (value) {
                              FocusScope.of(context)
                                  .requestFocus(_pwTextFieldFocusNode);
                            },
                            decoration: InputDecoration(
                              labelText: "ID",
                              labelStyle:
                                  TextStyle(fontSize: screenWidth * 0.02),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          width: screenWidth * 0.1,
                          height: screenWidth * 0.05,
                          alignment: Alignment.bottomCenter,
                          child: DropdownButtonFormField<String>(
                            value: _selectedAuthority,
                            decoration: InputDecoration(
                              labelText: '권한',
                              labelStyle: TextStyle(fontSize: screenWidth * 0.015),
                              contentPadding: EdgeInsets.zero,
                            ),
                            items: _authorities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(fontSize: screenWidth * 0.0175),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedAuthority = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: screenWidth * 0.01,
                  ),
                  Container(
                    height: screenWidth * 0.05,
                    width: screenWidth * 0.4,
                    alignment: Alignment.center,
                    child: TextField(
                      focusNode: _nameTextFieldFocusNode,
                      controller: _nameTextEditingController,
                      style: TextStyle(fontSize: screenWidth * 0.02),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context)
                            .requestFocus(_pwTextFieldFocusNode);
                      },
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.02),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    height: screenWidth * 0.05,
                    width: screenWidth * 0.4,
                    alignment: Alignment.center,
                    child: TextField(
                      obscureText: true,
                      focusNode: _pwTextFieldFocusNode,
                      controller: _pwTextEditingController,
                      style: TextStyle(fontSize: screenWidth * 0.02),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context)
                            .requestFocus(_reEnterTextFieldFocusNode);
                      },
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.02),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenWidth * 0.01,
                  ),
                  Container(
                    height: screenWidth * 0.05,
                    width: screenWidth * 0.4,
                    alignment: Alignment.center,
                    child: TextField(
                      obscureText: true,
                      focusNode: _reEnterTextFieldFocusNode,
                      controller: _reEnterTextEditingController,
                      style: TextStyle(fontSize: screenWidth * 0.02),
                      decoration: InputDecoration(
                        labelText: "Re-Enter Password",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.02),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenWidth * 0.01,
                  ),
                  Text(
                    _message,
                    style: TextStyle(
                        fontSize: screenWidth * 0.01, color: Colors.red),
                  ),
                  SizedBox(
                    height: screenWidth * 0.025,
                  ),
                  Container(
                    height: 75,
                    width: screenWidth * 0.35,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _addUser : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled
                            ? const Color.fromARGB(255, 0, 31, 99)
                            : Colors.grey, // 배경색
                        foregroundColor: Colors.white, // 텍스트 색상
                        elevation: 5, // 버튼의 그림자 높이
                      ),
                      child: Text(
                        "추가",
                        style: TextStyle(
                            fontSize: screenWidth * 0.025, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
