import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'detector.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection TFLite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  AnimationController rippleController;
  AnimationController scaleController;

  Animation<double> rippleAnimation;
  Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    rippleController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    scaleController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              scaleController.reverse();
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.fade, child: DetectorPage()));
            }
          });
    rippleAnimation =
        Tween<double>(begin: 80.0, end: 90.0).animate(rippleController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              rippleController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              rippleController.forward();
            }
          });
    scaleAnimation =
        Tween<double>(begin: 1.0, end: 30.0).animate(scaleController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              rippleController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              rippleController.forward();
            }
          });
  }

  @override
  void dispose() {
    rippleController.dispose();
    scaleController.dispose();
    super.dispose();
  }

  TextStyle boldStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        fontFamily: 'Segoe UI');
  }

  TextStyle normalStyle(BuildContext context) {
    return Theme.of(context)
        .textTheme
        .bodyText1
        .copyWith(color: Colors.white, fontSize: 25, fontFamily: 'Segoe UI');
  }

  TextStyle appBarStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 25,
        );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        body: SafeArea(
            child: Align(
                child: AnimatedBuilder(
                    animation: rippleAnimation,
                    builder: (context, child) => Container(
                        width: rippleAnimation.value * 5,
                        height: rippleAnimation.value * 4,
                        child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyan[100]),
                            child: InkWell(
                                onTap: () {
                                  scaleController.forward();
                                },
                                child: AnimatedBuilder(
                                  animation: scaleAnimation,
                                  builder: (context, child) => Transform.scale(
                                    scale: scaleAnimation.value,
                                    child: Container(
                                      child: Align(
                                          child: RichText(
                                              text: TextSpan(
                                                  style: DefaultTextStyle.of(
                                                          context)
                                                      .style,
                                                  children: <TextSpan>[
                                            TextSpan(
                                                text: "O B J E C T I F Y",
                                                style: boldStyle(context)),
                                            // TextSpan(text: 'Detect', style: normalStyle(context))
                                          ]))),
                                      margin: EdgeInsets.all(40),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.cyan),
                                    ),
                                  ),
                                ))))))));
  }
}
