import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_demo/Deshboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController txPhNumber = TextEditingController();
  TextEditingController txSubmit = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  String? vId;
  String smsCode = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) {
            return DashBoard();
          },
        ));
        print('User is signed in!');
      }
    });
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TextField(keyboardType: TextInputType.number, controller: txPhNumber),

          // TextField(keyboardType: TextInputType.number, controller: txSubmit),

          OTPTextField(
            onChanged: (value) {
              setState(() {
                smsCode = value;
              });
            },
            length: 6,
            width: MediaQuery.of(context).size.width,
            fieldWidth: 45,
            style: TextStyle(fontSize: 17),
            textFieldAlignment: MainAxisAlignment.spaceAround,
            fieldStyle: FieldStyle.box,
            onCompleted: (pin) {
              print("Completed: " + pin);
            },
          ),
          ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: '+91${txPhNumber.text}',
                  verificationCompleted: (PhoneAuthCredential credential) {},
                  verificationFailed: (FirebaseAuthException e) {
                    if (e.code == 'invalid-phone-number') {
                      print('The provided phone number is not valid.');
                    }
                  },
                  codeSent: (String verificationId, int? resendToken) {
                    setState(() {
                      vId = verificationId;
                    });
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {},
                );
              },
              child: Text("send otp")),
          ElevatedButton(
              onPressed: () async {
                // String smsCode1 = txSubmit.text;

                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: vId ?? "", smsCode: smsCode);

                await auth.signInWithCredential(credential);
              },
              child: Text("submit")),
          SizedBox(
            height: 50,
          ),
          GestureDetector(
              onTap: () {
                signInWithGoogle().then((value) {
                  print("==========================>${value}");
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) {
                      return DashBoard(
                        userCredential: value,
                      );
                    },
                  ));
                });
              },
              child: SvgPicture.asset("Assets/google-fill.svg")),
          ElevatedButton(
              onPressed: () {
                signInWithFacebook().then((value) {
                  print(value);
                });
              },
              child: Text("Facebook"))
        ],
      ),
    );
  }
}
