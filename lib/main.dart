import 'dart:io';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

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

const String yolo = "assets/yolov2_tiny.tflite";

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

class DetectorPage extends StatefulWidget {
  @override
  _DetectorPageState createState() => _DetectorPageState();
}

class _DetectorPageState extends State<DetectorPage> {
  String _model = yolo;
  File _image;

  double _imageWidth;
  double _imageHeight;
  bool _busy = false;

  List _recognitions;
  var recognitions;

  TextStyle boldStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 25,
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
  void initState() {
    super.initState();
    _busy == true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  loadModel() async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite", labels: "assets/coco.txt");
      print("MODEL LOADED");
    } on PlatformException {
      print("Failed to load model");
    }
  }

  selectFromImagePickerGALLERY() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    print("Image Picked");
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    await predictImage(image);
    // print('recognitions');
    // print(recognitions);
    // print(recognitions[0]);
  }

  selectFromImagePickerCAMERA() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    print("Image Picked");
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    var x = await predictImage(image);
    // x.then(print(recognitions));
    // print(recognitions[0]['detectedClass']);
  }

  predictImage(var image) async {
    print("Predict Image Function");
    if (image == null)
      return;
    else
      await yolotflite(image);

    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  yolotflite(var image) async {
    print("predicting - IN YOLO MODEL");
    recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.2,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1);

    setState(() {
      _recognitions = recognitions;
    });
    print(recognitions);
    // print(recognitions[0]['detectedClass']);
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];
    double factorX = (screen.width - 50);
    double factorY = _imageHeight / _imageWidth * (screen.width - 50);
    //_imageHeight;

    Color blue = Colors.blue;

    return _recognitions.map((re) {
      return Positioned(
          left: (re["rect"]["x"] * factorX) + 25,
          top: (re["rect"]["y"] * factorY) + 25,
          width: re["rect"]["w"] * factorX,
          height: re["rect"]["h"] * factorY,
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                color: Colors.blue,
                width: 3,
              )),
              child: Text(
                  "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}",
                  style: TextStyle(
                    background: Paint()..color = blue,
                    color: Colors.white,
                    fontSize: 12,
                  ))));
    }).toList();
  }

  DataRow _getDataRow(recognitions) {
    return DataRow(
      cells: <DataCell>[
        DataCell(Text(recognitions['detectedClass'].toString())),
        DataCell(
            Text(recognitions['confidenceInClass'].toStringAsPrecision(2))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];
    stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        child: _image == null
            ? Container(
                width: size.width,
                height: size.height,
                padding: EdgeInsets.all(50),
                child: Column(children: [
                  Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.cyan,
                      ),
                      alignment: Alignment.center,
                      width: size.width / 2,
                      height: size.height / 3,
                      child: RichText(
                          text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(text: "Let's ", style: boldStyle(context)),
                          TextSpan(text: 'Detect', style: normalStyle(context))
                        ],
                      ))),
                  Container(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.cyanAccent)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: Text(
                          "Choose Image",
                        ),
                        onPressed: () {
                          selectFromImagePickerGALLERY();
                        },
                      ),
                      RaisedButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.cyanAccent)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                        child: Text("Click Image"),
                        onPressed: () {
                          selectFromImagePickerCAMERA();
                          print(recognitions);
                        },
                      ),
                    ],
                  )),
                ]))
            : SingleChildScrollView(
                child: Container(
                    width: size.width,
                    height: size.height,
                    padding: EdgeInsets.all(20),
                    child: Column(
                        // mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7.5),
                                color: Colors.cyan),
                            child: Image.file(_image),
                          ),
                          SizedBox(height: 5),
                          Column(children: <Widget>[
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.cyan),
                              child:
                                  Text("STATS", style: TextStyle(fontSize: 15)),
                            ),
                            //   //-------------------------------------- DATA TABLE ----------------------------------------------
                            SingleChildScrollView(
                                child: Container(
                                    padding: EdgeInsets.all(10.0),
                                    child: recognitions.isEmpty
                                        ? Column(children: <Widget>[
                                            Image.asset(
                                              'assets/noobject.png',
                                              height: 100,
                                              width: 100,
                                              // scale: 0.5,
                                            ),
                                            Text(
                                              'No Object Detected',
                                            )
                                          ])
                                        : SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columns: const <DataColumn>[
                                                DataColumn(
                                                  label: Text(
                                                    'Objects',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Confidence',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                ),
                                              ],
                                              rows: List.generate(
                                                  recognitions.length,
                                                  (index) => _getDataRow(
                                                      recognitions[index])),
                                            ))))
                          ]),
                          SizedBox(height: 5),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RaisedButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side:
                                          BorderSide(color: Colors.cyanAccent)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 10),
                                  child: Text("Choose Image",
                                      style: TextStyle(fontSize: 15)),
                                  onPressed: () {
                                    selectFromImagePickerGALLERY();
                                  },
                                ),
                                RaisedButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side:
                                          BorderSide(color: Colors.cyanAccent)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 35, vertical: 10),
                                  child: Text("Click Image",
                                      style: TextStyle(fontSize: 15)),
                                  onPressed: () {
                                    selectFromImagePickerCAMERA();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ])))));

    stackChildren.addAll(renderBoxes(size));

    return Scaffold(
      appBar: AppBar(
        title: Text("  OBJECTIFY", style: appBarStyle(context)),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.camera),
      //   tooltip: "Pick Image",
      //   onPressed: selectFromImagePickerCAMERA(),
      // ),
      body: Stack(children: stackChildren),
    );
  }
}
