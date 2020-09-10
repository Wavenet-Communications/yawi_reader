import 'dart:ui';
import 'package:flutter/services.dart';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YAWi Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'YAWi Reader',
              style: TextStyle(fontSize: 50),
              ),
            Container(height: 80,),
            Image.asset(
              'assets/WNC_QRCode.png',
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
            Container(height: 20,),

            RaisedButton(
                onPressed:  () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanPage()),
                  );
                },
                child: Text(
                  'Scan code',
                  style: TextStyle(fontSize: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}




class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  bool resultSent = false;
  BarcodeDetector detector = FirebaseVision.instance.barcodeDetector();
  _ScannerOverlayShape overlayShape;
  AnimationController _animationController;
  bool _animationStopped = false;
  String _contentString;
  int _contentScanCount;

  @override
  void initState() {
    _animationController = new AnimationController(
        duration: new Duration(seconds: 3), vsync: this);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animateScanAnimation(true);
      } else if (status == AnimationStatus.dismissed) {
        animateScanAnimation(false);
      }
    });
    _contentScanCount = 0;
    _contentString = "";
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    if (this.overlayShape == null) {
      var height = MediaQuery.of(context).size.height;
      final width  = MediaQuery.of(context).size.width;
      var padding = MediaQuery.of(context).padding;
      height = height - padding.top - padding.bottom- kToolbarHeight;

      this.overlayShape =  _ScannerOverlayShape(
          borderColor: Theme.of(context).primaryColorDark,
          borderWidth: 3.0,
          );
      this.overlayShape.focusedRect = this.overlayShape.calculateOverlayRect(h: height, w: width);
    }
    animateScanAnimation(false);

    return Scaffold(
      appBar: AppBar(
        title: Text("YAWi Reader"),
      ),
      body: SafeArea(
       child: Stack(
          fit: StackFit.expand,
          children: [

          CameraMlVision<List<Barcode>>(
            overlayBuilder: (c) {
              return Container(
                decoration: ShapeDecoration(
                  shape: this.overlayShape,
                ),

              );
            },
            detector: detector.detectInImage,
            onResult: (List<Barcode> barcodes) {
              if (!mounted ||
                  resultSent ||
                  barcodes == null ||
                  barcodes.isEmpty) {
                return;
              }
                gotoResultScreen(barcodes);
              },
            onDispose: () {
              detector.close();
            },
          ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                Text('Scan the code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100 ,  color: Colors.white)),
                Container(height: 60,),
              ]),
            ImageScannerAnimation(
              _animationStopped,
              334,
              this.overlayShape.focusedRect,
              animation: _animationController,
            )
          ],

        ),
      ),
    );
  }
  gotoResultScreen(List<Barcode> barcodes) async {
    Barcode lFocusedBarcode;
    debugPrint('*** gotoResultScreen');
    barcodes.forEach((barcode) {
      var pixRatio = MediaQuery.of(context).devicePixelRatio;
      var lTempRect = Rect.fromLTRB(
          overlayShape.focusedRect.left * pixRatio,
          overlayShape.focusedRect.top * pixRatio,
          overlayShape.focusedRect.right * pixRatio, overlayShape.focusedRect.bottom * pixRatio);
      debugPrint('*** overlayShape Rect' + lTempRect.toString() + "    barcode-rect  " + barcode.boundingBox.toString());
      if (lTempRect.overlaps(barcode.boundingBox)){
        lFocusedBarcode = barcode;
        if(this._contentString == barcode.displayValue){
          this._contentScanCount ++;
          debugPrint(" *** barcode value -- " + this._contentString+ "  count -" + this._contentScanCount.toString());
        }else {
          this._contentString = barcode.displayValue;
          this._contentScanCount = 1;
          debugPrint(" *** new barcode value -- " + this._contentString+ "  count -" + this._contentScanCount.toString());
        }
      }
    });
    if (lFocusedBarcode != null && this._contentScanCount > 1) {
      resultSent = true;
      HapticFeedback.vibrate();
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) =>
            ResultScreen(urlString: lFocusedBarcode)),
      );
      resultSent = false;
      this._contentScanCount = 0;
      this._contentString = "";
    }
  }
  void animateScanAnimation(bool reverse) {
    if (reverse) {
      _animationController.reverse(from: 1.0);
    } else {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ResultScreen extends StatelessWidget {
  final Barcode urlString;
  ResultScreen({Key key, this.urlString}): super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contents"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Contents: ',
              style: TextStyle(fontSize: 20),
            ),
            Container(height: 20,),
            Text(
              (this.urlString != null) ? this.urlString.displayValue: 'temp name',
              style: TextStyle(fontSize: 20,),
            )
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;


  Rect focusedRect;

  _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0xff000000),
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  Rect calculateOverlayRect({double h, double w}) {

    final width = w;
    final borderWidthSize = width * 30 / 100;
    final height = h;
    final borderHeightSize = height - (2*borderWidthSize);
    final borderSize = Size(borderWidthSize / 2, borderHeightSize / 2);



    final borderOffset = borderWidth / 2;
    final realReact = Rect.fromLTRB(
        borderSize.width + borderOffset,
        - borderOffset+ (height/2 - borderSize.height/2) ,
        width - borderSize.width - borderOffset,
        height/2 + borderSize.height/2 + borderOffset);

    return realReact;

  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    const lineSize = 30;

    final width = rect.width;
    final borderWidthSize = width * 30 / 100;
    final height = rect.height;
    final borderHeightSize = height - (2*borderWidthSize);
    final borderSize = Size(borderWidthSize / 2, borderHeightSize / 2);

    var centerLinePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth/4;

    var paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas
      ..drawRect(
        Rect.fromLTRB(
            rect.left, rect.top, rect.right, borderSize.height + rect.top),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, rect.bottom - borderSize.height, rect.right,
            rect.bottom),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(rect.left, rect.top + borderSize.height,
            rect.left + borderSize.width, rect.bottom - borderSize.height),
        paint,
      )
      ..drawRect(
        Rect.fromLTRB(
            rect.right - borderSize.width,
            rect.top + borderSize.height,
            rect.right,
            rect.bottom - borderSize.height),
        paint,
      );


    final borderOffset = borderWidth / 2;
    final realReact = Rect.fromLTRB(
        borderSize.width + borderOffset,
        borderSize.height + borderOffset + rect.top,
        width - borderSize.width - borderOffset,
        height - borderSize.height - borderOffset + rect.top);

    //this.focusedRect = realReact;

    paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth/10;
    canvas
      ..drawRect(realReact, paint)
    ;


    paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;


    //Draw top right corner
    canvas
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.top)
            ..lineTo(realReact.right, realReact.top + lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.top)
            ..lineTo(realReact.right - lineSize, realReact.top),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.right, realReact.top)],
        paint,
      )

      //Draw top left corner
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.top)
            ..lineTo(realReact.left, realReact.top + lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.top)
            ..lineTo(realReact.left + lineSize, realReact.top),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.left, realReact.top)],
        paint,
      )

      //Draw bottom right corner
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.bottom)
            ..lineTo(realReact.right, realReact.bottom - lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.right, realReact.bottom)
            ..lineTo(realReact.right - lineSize, realReact.bottom),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.right, realReact.bottom)],
        paint,
      )

      //Draw bottom left corner
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.bottom)
            ..lineTo(realReact.left, realReact.bottom - lineSize),
          paint)
      ..drawPath(
          Path()
            ..moveTo(realReact.left, realReact.bottom)
            ..lineTo(realReact.left + lineSize, realReact.bottom),
          paint)
      ..drawPoints(
        PointMode.points,
        [Offset(realReact.left, realReact.bottom)],
        paint,
      )
    ;



  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}


class ImageScannerAnimation extends AnimatedWidget {
  final bool stopped;
  final double width;
  Rect rect;

  ImageScannerAnimation(this.stopped, this.width, this.rect,
      {Key key, Animation<double> animation})
      : super(key: key, listenable: animation);

  Widget build(BuildContext context) {
    if(this.rect == null){
      this.rect = Rect.fromLTRB(10, 100, 100, 100);
    }
    final Animation<double> animation = listenable;

    final double scorePosition = (animation.value  * this.rect.height );

    Color color1 =  Colors.white10;
    Color color2 = Colors.white70;

    if (animation.status == AnimationStatus.reverse) {
      color1 = Colors.white70;
      color2 = Colors.white10;
    }


    return new Positioned(
        top: scorePosition+ this.rect.top,
        left: this.rect.left + 10,
        child: new Opacity(
            opacity: (stopped) ? 0.0 : 1.0,
            child: Container(
              height: 3.0,
              width: this.rect.width-20,
              decoration: new BoxDecoration(
                  gradient: new LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.1, 0.9],
                    colors: [color1, color2],
                  )),
            )));
  }
}
