import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_hub_demo/authentication/service/auth_provider.dart';
import 'package:student_hub_demo/generated/l10n.dart';
import 'package:student_hub_demo/navigation/routes.dart';
import 'package:student_hub_demo/resources/banner.dart';
import 'package:student_hub_demo/widgets/button.dart';
import 'package:student_hub_demo/widgets/dialog.dart';
import 'package:student_hub_demo/widgets/form_card.dart';

class LoginView extends StatefulWidget {
  static const String routeName = '/login';

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  var emailController = TextEditingController();
  List<FormCardField> formItems;

  List<FormCardField> _buildFormItems() {
    // Only build them once to avoid the cursor staying everywhere
    if (formItems != null) {
      return formItems;
    }

    final authProvider = Provider.of<AuthProvider>(context);
    return formItems = <FormCardField>[
      FormCardField(
        label: S.of(context).labelEmail,
        hint: S.of(context).hintEmail,
        controller: emailController,
        autocorrect: false,
        autofillHints: [AutofillHints.username],
        check: (email, {context}) =>
            authProvider.canSignInWithPassword(email: email, context: context),
      ),
      FormCardField(
        label: S.of(context).labelPassword,
        hint: S.of(context).hintPassword,
        obscureText: true,
        autofillHints: [AutofillHints.password],
      ),
    ];
  }

  AppDialog _resetPasswordDialog(BuildContext context) => AppDialog(
        title: S.of(context).actionResetPassword,
        message: S.of(context).messageResetPassword,
        content: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey('reset_password_email_text_field'),
                  controller: emailController,
                  decoration:
                      InputDecoration(hintText: S.of(context).hintEmail),
                ),
              ),
            ],
          )
        ],
        actions: [
          AppButton(
            key: const ValueKey('send_email_button'),
            text: S.of(context).actionSendEmail.toUpperCase(),
            width: 130,
            onTap: () async {
              final success =
                  await Provider.of<AuthProvider>(context, listen: false)
                      .sendPasswordResetEmail(
                          email: emailController.text, context: context);
              if (success) {
                Navigator.pop(context);
              }
              return;
            },
          ),
        ],
      );

  FormCard _buildForm(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FormCard(
      title: S.of(context).actionLogIn,
      fields: _buildFormItems(),
      onSubmitted: (fields) async {
        final result = await authProvider.signIn(
          email: fields[S.of(context).labelEmail],
          password: fields[S.of(context).labelPassword],
          context: context,
        );
        if (result) {
          await Navigator.pushReplacementNamed(context, Routes.home);
        }
      },
      trailing: <Widget>[
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
                child: Text(
                  S.of(context).actionResetPassword,
                  style: Theme.of(context)
                      .accentTextTheme
                      .subtitle1
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  showDialog(context: context, builder: _resetPasswordDialog);
                  final currentFocus = FocusScope.of(context);
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                })
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final loginForm = _buildForm(context);

    return GestureDetector(
      onTap: () {
        // Remove current focus on tap
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: FractionalOffset.topRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                    height: MediaQuery.of(context).size.height / 3,
                    child: Image.asset(
                        'assets/illustrations/undraw_digital_nomad.png')),
              ),
            ),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 4,
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 1,
                      minHeight: 1,
                    ),
                    child: Image.asset('assets/images/city_doodle.png',
                        color: Theme.of(context).accentColor.withOpacity(0.4)),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 28, bottom: 8),
                child: IntrinsicHeight(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            UniBanner(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(child: loginForm),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: AppButton(
                              key: const ValueKey('log_in_anonymously_button'),
                              text: S.of(context).actionLogInAnonymously,
                              onTap: () async {
                                final result = await authProvider
                                    .signInAnonymously(context: context);
                                if (result) {
                                  await Navigator.pushReplacementNamed(
                                      context, Routes.home);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: AppButton(
                              key: const ValueKey('log_in_button'),
                              color: Theme.of(context).accentColor,
                              text: S.of(context).actionLogIn,
                              onTap: () => loginForm.submit(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '${S.of(context).messageNewUser} ',
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .copyWith(fontWeight: FontWeight.w400),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.signUp);
                            },
                            child: Text(S.of(context).actionSignUp,
                                style: Theme.of(context)
                                    .accentTextTheme
                                    .subtitle1
                                    .copyWith(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
