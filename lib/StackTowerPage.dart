import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math';


import 'dart:ui';

import 'package:audioplayers/audioplayers.dart' as audioplayers;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openworld_gl/openworld_gl.dart';

import 'package:openworld/three_dart/three3d/objects/index.dart';
import 'package:openworld/three_dart/three_dart.dart' as THREE;
import 'package:openworld/three_dart_jsm/three_dart_jsm.dart' as THREE_JSM;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openworld/three_dart_jsm/three_dart_jsm/controls/index.dart';
import 'package:openworld/three_dart_jsm/extra/dom_like_listenable.dart';
import 'package:http/http.dart';

String gamename = 'Stack Tower';

const leftEx = -0.9;
const rightEx = 0.9;
const frontEx = 0.9;
const backEx = -0.9;
const heighti = 0.08;
//var  colorArr = [THREE.Color(0xFB9EC6), THREE.Color(0xFBB4A5), THREE.Color(0xFFE893), THREE.Color(0xFCFFC1)];
var  colorArr = [THREE.Color(0xf49604),THREE.Color(0x88f404),THREE.Color(0xf40404),THREE.Color(0xf4de04),THREE.Color(0xf404de),THREE.Color(0x37f404),THREE.Color(0x0f04f4)];

var points = 0;
var maxpoints = 0;
var tower;
var currentBlock;
var blockDepth;
var blockWidth;
var dir;
var colorIndex;
var changeColor;
var isGameOver=false;
var matii;

//var music;

class Block extends THREE.Mesh {
  var width;
  var depth;
  var direction;
  var color;
  var mainX;
  var mainY;
  var mainZ;

  Block(width, height, depth, color, direction, mainX, mainY, mainZ): super(
  THREE.BoxGeometry(width, height, depth),
      new THREE.MeshStandardMaterial({'emissive': color })
//  new THREE.MeshStandardMaterial({'emmi': color })
  ) {
    /*mat.emissive=THREE.Color(0x049ef4);
    // mat.color=THREE.Color(0x049ef4);
    mat.metalness = 1;
    mat.roughness = 0.5;*/
    this.width = width;
    this.depth = depth;
    this.direction = direction;
    this.color = color;

    this.mainX = mainX;
    this.mainY = mainY;
    this.mainZ = mainZ;

    var xPos = mainX;
    var yPos = mainY + heighti;
    var  zPos = mainZ;
    if (dir == 1) xPos = leftEx;
    else if (dir == 2) xPos = rightEx;
    else if (dir == 3) zPos = backEx;
    this.extra['yPosOrig']= yPos;
    this.position.set(xPos, yPos+heighti, zPos);
  }
}

class StackTowerPage extends StatefulWidget {


  StackTowerPage({Key? key})
      : super(key: key);

  @override
  createState() => _State();
}

class _State extends State<StackTowerPage> {
  //UserGuidanceController userGuidanceController = UserGuidanceController();

  late OpenworldGlPlugin three3dRender;
  THREE.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  late Timer _timer;
  Size? screenSize;

  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;

  late THREE.Clock clock;

  double dpr = 1.0;

  bool verbose = false;
  bool disposed = false;

  late THREE.Object3D object;

  late THREE.Texture texture;

  late THREE.WebGLMultisampleRenderTarget renderTarget;

  dynamic? sourceTexture;

  bool loaded = false;

  var base;

  var starttext='Start';
  static double defaultspeed=0.015*1.5;

  var speed=defaultspeed;//0.015*3;

  var msg="";

  var rng = new Random();
 // for (var i = 0; i < 10; i++) {
 // print(rng.nextDouble() + rng.nextInt(50));
  //}
  var iTime=0.0;
  var mati;

  var wobble=false;
//  var down=false;
/*

  Map<LogicalKeyboardKey, bool> keyStates = {
    LogicalKeyboardKey.keyW: false,
    LogicalKeyboardKey.keyA: false,
    LogicalKeyboardKey.keyS: false,
    LogicalKeyboardKey.keyD: false,
    LogicalKeyboardKey.space: false,

    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };*/

  static GlobalKey<DomLikeListenableState> _globalKey =
  GlobalKey<DomLikeListenableState>();


  @override
  void initState() {
    super.initState();
    iTime=rng.nextDouble()*1000;
    getMaxPoints();
  }

  getMaxPoints()
  async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
  //  await prefs.setInt("maxpoints", 0);
    if (prefs.containsKey('maxpoints')) {
      setState(() {
        maxpoints = prefs.getInt('maxpoints')!;
      });
    }

// Save an integer value to 'counter' key.


  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = OpenworldGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    print("begin initialize");
    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    // Future.delayed(const Duration(milliseconds: 100), () async {
    Timer(Duration(milliseconds: 100), () async {
      print("begin prepare context");
      // try {
      await three3dRender.prepareContext();
      // } on Exception catch (exception) {
      //   print('never reached');
//
      //   ... // only executed if error is of type Exception
      //} catch (error) {
      //  ... // executed for errors of all types other than Exception
      //print('errr!');
      //}

      print("done prepare context");

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    print("screen" + screenSize!.width.toString()+" dpr"+dpr.toString());
    initPlatformState();
  }


  @override
  void reassemble() {
    super.reassemble();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //  title: Text('voor'), //widget.fileName),
      // ),
      body:
      DomLikeListenable(
        key: _globalKey,
        builder: (BuildContext context) {
          initSize(context);
          return _build(context);
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    /*SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);*/

    //print("width"+width.toString());
    return
       Scaffold(
            // resizeToAvoidBottomInset: true,
           appBar: !kIsWeb&&(Platform.isIOS||Platform.isAndroid)?AppBar(
             // TRY THIS: Try changing the color here to a specific color (to
             // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
             // change color while the other colors stay the same.
             backgroundColor: Theme.of(context).colorScheme.inversePrimary,
             // Here we take the value from the MyHomePage object that was created by
             // the App.build method, and use it to set our appbar title.
             title: Text('Stack Tower', style:TextStyle(color:Colors.white)),
           ):null,
              body: Container(
                child: Stack(
                  children: [
                    //  Text("hi"),
                    Container(
                        child: loaded ? Container(
                            width: width,
                            height: height,
                            color: Colors.black,
                            child: Builder(builder: (BuildContext context) {
                              if (kIsWeb) {
                                return three3dRender.isInitialized
                                    ? HtmlElementView(
                                    viewType: three3dRender.textureId!
                                        .toString())
                                    : Container();
                              } else {
                                return three3dRender.isInitialized
                                    ?
                                Texture(textureId: three3dRender.textureId!)

                                    : Container();
                              }
                            })) :
                        Stack(
                            children: [
                              Center(child: Image.asset(
                                "icons/stacktower2.jpg", fit: BoxFit.cover,)),
                              //house2.jpg"),


                              Center(child: Container(

                                child: Center(child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: ListView(
                                        shrinkWrap: true,
                                        children: [
                                          Center(
                                              child: SizedBox(width: 400,
                                              child: Container(
                                                  padding: EdgeInsets.all(15),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          width: 1,
                                                          color: Colors
                                                              .transparent),
                                                      //color is transparent so that it does not blend with the actual color specified
                                                      borderRadius: const BorderRadius
                                                          .all(
                                                          const Radius.circular(
                                                              10.0)),
                                                      color: Colors
                                                          .black //.withOpacity(0.2) // Specifies the background color and the opacity
                                                  ),
                                                  child: Row(
                                                      children: [
                                                        Text(gamename
                                                            //Welcome to Second Temple.\n"

                                                            //  "Its 72AD before destruction of jeruaslem by the romans.\n"
                                                            //  "Can you find the ark before this great calamity?"
                                                            ,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight: FontWeight
                                                                    .bold)),
                                                        Text("  is",
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .white)),
                                                        SizedBox(width: 25),
                                                        Text(
                                                                "Loading"
                                                                ,
                                                                textAlign: TextAlign
                                                                    .center,
                                                                style: TextStyle(
                                                                    fontSize: 20,
                                                                    color: Colors
                                                                        .yellow,
                                                                    fontWeight: FontWeight
                                                                        .bold))
                                                      ])))),
                                          SizedBox(height: 15),

                                        ]
                                    )
                                )),
                              )

                              )
                            ])
                    ),
                    loaded?
                        Container(
                           alignment: Alignment.topCenter,

                    child:Container(
                      // set the height property to take the screen width
                        width: 350,//MediaQuery.of(context).size.width,
                        height:150,
                      //  Container(
                      //      width:200,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),

                       //    child:
                        child:Column(
                   //   mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,

                              children:[
                                SizedBox(height:10),
                             msg!=''?   Text(msg):SizedBox.shrink(),
                                 Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children:[
                          Text('Score: ', style:TextStyle(color:Colors.lightGreenAccent)),//,backgroundColor: Colors.blue.withOpacity(0.5))),
                        Text(points.toString(), style:TextStyle(fontWeight:FontWeight.bold,color:Colors.white)//.lightGreenAccent)
                     )]),
                     maxpoints>0?Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children:[
                           Text("Highest Score: ", style:TextStyle(color:Colors.lightBlueAccent)),
                           Text(maxpoints.toString(),style:TextStyle(/*fontWeight:FontWeight.bold,*/color:Colors.amberAccent))
                         ]):SizedBox.shrink(),
                    isGameOver?Text('Game Over',style:TextStyle(color:Colors.red)):SizedBox.shrink(),
                    SizedBox(height:10),
                    currentBlock == base||isGameOver?
                    ElevatedButton(
                      child: Text(starttext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        if (currentBlock == base || isGameOver) {
                          startGame();
                        }
                      },
                    ):SizedBox.shrink(),
                  /*  TextButton(

                      child: Text(starttext),
                      onPressed: () {
                       // print("voot"+currentBlock.toString()+" "+base.toString());
                        if (currentBlock == base || isGameOver) {
                          startGame();
                        }
                      },
                    ):SizedBox.shrink(),*/
                    ]))):SizedBox.shrink()
                  ],
                ),
              ));
  }

  render() {
    int _t = DateTime
        .now()
        .millisecondsSinceEpoch;


    final _gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int _t1 = DateTime
        .now()
        .millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    _gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }


   /* var delta = clock.getDelta();
    if (delta > 0.2) {
      print("delta too long" + delta.toString() + " " + camera.far.toString());
    }*/


  }

  initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = THREE.WebGLRenderer(_options);
    // print("dpr"+dpr.toString()); 1.0
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);

    renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      var pars = THREE.WebGLRenderTargetOptions({"format": THREE.RGBAFormat});
      renderTarget = THREE.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);

      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }


  newBlock() {
    var b = new Block(
        blockWidth,
        heighti,
        blockDepth,
        colorArr[colorIndex],
        dir,
        currentBlock.position.x,
        currentBlock.extra['yPosOrig'],
//        currentBlock.position.y,
        currentBlock.position.z
    );
    //b.material.emissive=b.material.color;//THREE.Color(0x049ef4);
    // mat.color=THREE.Color(0x049ef4);
    b.material.metalness = 1;
    b.material.roughness = 0.5;
    scene.add(b);
    currentBlock = b;
    ++dir;
    if (dir == 4)
      dir = 1;
    colorIndex += changeColor;
    if (colorIndex == 6) {
      changeColor = -1;
    } else if (colorIndex == 0)
      changeColor = 1;
  }

  checkOverlap() async {
    var blockDir = currentBlock.direction;
    currentBlock.direction = 0;
    var xDiff = (currentBlock.position.x - currentBlock.mainX).abs();
    var zDiff = (currentBlock.position.z - currentBlock.mainZ).abs();
    if (blockDir <= 2) {
      if (xDiff > currentBlock.width) {
        tower.add(currentBlock);
        setState(() {
          isGameOver = true;
        });
      } else {
        var fallWidth = xDiff;
        var overWidth = currentBlock.width - xDiff;
        var fallCen = 0.0;
        var overCen = 0.0;
        var leftPoint = currentBlock.position.x - currentBlock.width / 2;
        if (currentBlock.position.x > currentBlock.mainX) {
          overCen = leftPoint + overWidth / 2;
          fallCen = leftPoint + overWidth + fallWidth / 2;
        } else {
          fallCen = leftPoint + fallWidth / 2;
          overCen = leftPoint + fallWidth + overWidth / 2;
        }
        freeFall(
            fallWidth,
            currentBlock.depth,
            currentBlock.color,
            fallCen,
            currentBlock.position.y,
            currentBlock.position.z
        );
        cutOffBlock(
            overWidth,
            currentBlock.depth,
            currentBlock.color,
            overCen,
            currentBlock.position.y,
            currentBlock.position.z
        );
      }
    } else {
      if (zDiff > currentBlock.depth) {
        setState(() {
          isGameOver = true;
        });

        tower.add(currentBlock);
      } else {
        var fallDepth = zDiff;
        var overDepth = currentBlock.depth - zDiff;
        var fallCen;
        var overCen;
        var backPoint = currentBlock.position.z - currentBlock.depth / 2;
        if (currentBlock.position.z > currentBlock.mainZ) {
          overCen = backPoint + overDepth / 2;
          fallCen = backPoint + overDepth + fallDepth / 2;
        } else {
          fallCen = backPoint + fallDepth / 2;
          overCen = backPoint + fallDepth + overDepth / 2;
        }
        freeFall(
            currentBlock.width,
            fallDepth,
            currentBlock.color,
            currentBlock.position.x,
            currentBlock.position.y,
            fallCen
        );
        cutOffBlock(
            currentBlock.width,
            overDepth,
            currentBlock.color,
            currentBlock.position.x,
            currentBlock.position.y,
            overCen
        );
      }
    }
    if (!isGameOver) {
     // document.getElementById("points").innerHTML = points;
      setState(() {
        ++points;

      });
      if (points % 5 == 0) {
         for (var b in tower) {
           b.position.setY(b.position.y - 0.4);
           b.extra['yPosOrig']-=0.4;//(b.position.y - 0.4);
         }

      }
      newBlock();
     //var speed=0.015;
      // Dont go too fast when tower is high but still increase it as you get higher
      speed+=0.35*defaultspeed/tower.length;

      wobble=true;
      Future.delayed(const Duration(milliseconds: 200), () {
        wobble=false;
      });
     /* down=true;
      Future.delayed(const Duration(milliseconds: 100), () {
        down=false;
      });*/

    } else {
      setState(() {
        starttext='Restart';

      });
      if (points>maxpoints) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('maxpoints',points);

        setState(() {
           maxpoints=points;
           msg="Congratulations. You got the highest score";
        });
      }
      //document.getElementById("points").style.display = "none";
      ////document.querySelector("#restart h3").innerHTML = "Score : " + points;
     // document.getElementById("restart").style.display = "block";
      //document.getElementById("instruction").style.disply = "none";
    //  music.pause();
    }
  }

  cutOffBlock(w, d, color, x, y, z) {
    var overLappingArea = new THREE.Mesh(
        new THREE.BoxGeometry(w, heighti, d),
        new THREE.MeshStandardMaterial({'emissive': color })
       // new THREE.MeshStandardMaterial({'color': color })
    );
    overLappingArea.material.metalness = 1;
    overLappingArea.material.roughness = 0.5;
    overLappingArea.position.set(x, y, z);
    tower.add(overLappingArea);
    blockWidth = w;
    blockDepth = d;
    scene.remove(currentBlock);
    overLappingArea.extra['yPosOrig']=currentBlock.extra['yPosOrig'];
    currentBlock = overLappingArea;
    scene.add(currentBlock);
  }

  var  fallingArea;
  freeFall(w, d, color, x, y, z) {
    fallingArea = new THREE.Mesh(
        new THREE.BoxGeometry(w, heighti, d),
        new THREE.MeshStandardMaterial({ 'emissive':color })
//        new THREE.MeshStandardMaterial({ 'color':color })
    );
    fallingArea.material.metalness = 1;
    fallingArea.material.roughness = 0.5;

    fallingArea.position.set(x, y, z);
    scene.add(fallingArea);

    Timer(Duration(milliseconds: 400), () {
        scene.remove(fallingArea);
        //fallingArea = None;
    });

   /* setTimeout(() => {
    //watch it falling for 1s then remove it
        scene.remove(fallingArea);
        fallingArea = undefined;
    }, 400);*/
  }


   startGame() async {
    print("start game");
  /*  document.getElementById("startBtn").style.display = "none";
    document.getElementById("points").style.display = "flex";
    document.getElementById("restart").style.display = "none";
    document.getElementById("instruction").style.display = "block";*/
    if (currentBlock != base) {
      tower.add(currentBlock);

      ++points;
    }
    if (tower.length > 1) {
   //   ++points;

      var wait= await removeTower(tower.length - 1);
      // Wait for the tower to be dismantled
      await Future.delayed(Duration(milliseconds: wait));
      wait=  await centerBase();
      // Wait for the camera to center
      await Future.delayed(Duration(milliseconds: wait));
    }
    setState(() {
      isGameOver = false;
      points = 0;
      msg="";
    });

    blockDepth = 0.8;
    blockWidth = 0.8;
    dir = 1;
    colorIndex = 0;
    changeColor = 1;
    base.position.set(0.0, -0.5, 0.0);
    base.extra['yPosOrig']=-0.5;
    currentBlock = base;
    speed=defaultspeed;
    newBlock();
   // music = document.getElementsByTagName("audio")[0];
    //music.play();
  }

  // Dismantle dower
  removeTower(index) async {
    var delay=70;
    await Timer(Duration(milliseconds: delay), () async {
      scene.remove(tower[index]);
      tower.removeLast();
      // setState(() {
      //   --points;

       //});
       if (tower.length > 1) {
         await removeTower(tower.length - 1);

       }
         // document.getElementById("points").innerHTML = points;
     // resolve();

    });

   /* while (tower.length > 1) {
    await removeTowerElement(tower.length - 1);
    }*/
    return delay*(index+2);
  }

  // Move the base back up to -0.5
  centerBase() async {
    var delay=50;
   Timer(Duration(milliseconds: delay), () {
     base.position.setY(base.position.y + 0.1);
     if (base.position.y < -0.5)
       centerBase();
     // document.getElementById("points").innerHTML = points;
     // resolve();*/

   });
   return  (delay*(-base.position.y /*- 0.5*/)/0.1).toInt();
    /*while (base.position.y < -0.5) {
    await upward();
    }*/
  }

  initPage() async {

    print("init page");
    camera = THREE.PerspectiveCamera(50, width / height, 0.1, 100);

    camera.position.set(-0.4, 1.0, 1.5);

    clock = THREE.Clock();

    print("create scene");
    scene = THREE.Scene();
   // scene.add(camera);
    //scene.rotation.order = "YXZ";
    //scene.background = new THREE.Color( 0x444444 );
    scene.background = new THREE.Color(0xA1D6CB);
   /* var pmremGenerator = new THREE.PMREMGenerator( renderer );
  //  THREE_JSM.Ro
    scene.environment = pmremGenerator.fromScene( new  THREE_JSM.RoomEnvironment(), 0.04 ).texture;*/
  //  scene.environment = pmremGenerator.fromScene( new  THREE_JSM.RoomEnvironment(), 0.04 ).texture;
    //scene.fbackground = THREE.Color(1.0, 1.0, 1.0);
    //scene.add( new THREE.AmbientLight( 0xA1D6CB, null ) );
   // scene.add( new THREE.AmbientLight( 0x000000, null ) );
    var light = THREE.DirectionalLight(0x666666, 1.9);
    light.position.set(-1, 7, 1);
    scene.add(light);

  /*  var light1 = new THREE.DirectionalLight( 0xffffff, 3 );
    light1.position.set( 0, 200, 0 );
    scene.add( light1 );

    var light2 = new THREE.DirectionalLight( 0xffffff, 3 );
    light2.position.set( 100, 200, 100 );
    scene.add( light2 );

    var light3 = new THREE.DirectionalLight( 0xffffff, 3 );
    light3.position.set( - 100, - 200, - 100 );
    scene.add( light3 );*/


    var geometry = new THREE.PlaneGeometry( 16,16 );
   // var  mati = new THREE.MeshBasicMaterial( {'color': THREE.Color(0xffff00)});//, 'side': THREE.DoubleSide} );
    // Background shader
    Map<String, dynamic> SkyShaderiii = {
      "uniforms": {
        'iTime': { 'value': 0.0 },
        'iResolution': {'value': new THREE.Vector2(600.0,600.0) }//width/2,height/2) }
      },
      "vertexShader": [
        'void main() {',
        'gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
        '}',

      ].join('\n'),
      "fragmentShader": [
        "uniform float iTime;",
        "uniform vec2 iResolution;",

        "void main() {",
        "vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;",
        "uv.x *= iResolution.x / iResolution.y;",

        "vec3 color = vec3(0.0);",
        "for( int i = 0; i < 128; i++ ) {",
        "float pha = sin(float(i) * 546.13 + 1.0) * 0.5 + 0.5;",
        "float siz = pow(sin(float(i) * 651.74 + 5.0) * 0.5 + 0.5, 4.0);",
        "float pox = sin(float(i) * 321.55 + 4.1) * iResolution.x / iResolution.y;",
        "float rad = 0.1 + 0.5 * siz + sin(pha + siz) / 4.0;",
        "vec2 pos = vec2(pox + sin(iTime / 15.0 + pha + siz), -1.0 - rad + (2.0 + 2.0 * rad) * mod(pha + 0.3 * (iTime / 7.0) * (0.2 + 0.8 * siz), 1.0));",
        "float dis = length(uv - pos);",
        "vec3 col = mix(vec3(0.194 * sin(iTime / 6.0) + 0.3, 0.2, 0.3 * pha), vec3(1.1 * sin(iTime / 9.0) + 0.3, 0.2 * pha, 0.4), 0.5 + 0.5 * sin(float(i)));",
        "float f = length(uv - pos) / rad;",
        "f = sqrt(clamp(1.0 + (sin(iTime * siz) * 0.5) * f, 0.0, 1.0));",
        "color += col.zyx * (1.0 - smoothstep(rad * 0.15, rad, dis));",
        "}",

        "color *= sqrt(1.5 - 0.5 * length(uv));",
        "gl_FragColor = vec4(color, 1.0);",
        "}",

      ].join('\n')

    };


    Map<String, dynamic> SkyShaderii = {
      "uniforms": {
        'iTime': { 'value': 0.0 },
        'iResolution': {'value': new THREE.Vector2(600.0,600.0) }//width/2,height/2) }
//        'iResolution': {'value': new THREE.Vector2(600.0,600.0) }//width/2,height/2) }
      },
      "vertexShader": [
        'void main() {',
        'gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
        '}',

      ].join('\n'),
      "fragmentShader": [
        "uniform float iTime;",
        "uniform vec2 iResolution;",

        "const float speed = 0.15;",

        "float hash1( float n ) { return fract(sin(n)*43758.5453); }",
        "vec2  hash2( vec2  p ) { p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) ); return fract(sin(p)*43758.5453); }",

// The parameter w controls the smoothness
        "vec4 voronoi(in vec2 x, float w) {",
        " vec2 n = floor( x );",
        " vec2 f = fract( x );",

        " vec4 m = vec4( 8.0, 0.0, 0.0, 0.0 );",
        " for( int j=-2; j<=2; j++ )",
        " for( int i=-2; i<=2; i++ )",
        " {",
        "  vec2 g = vec2( float(i),float(j) );",
        "  vec2 o = hash2( n + g );",

        // animate
        "  o = 0.5 + 0.5*sin( iTime * speed + 6.2831*o );",

        // distance to cell
        "  float d = length(g - f + o);",

        // cell color
        "  vec3 col = 0.5 + 0.5*sin( hash1(dot(n+g,vec2(7.0,113.0)))*2.5 + 3.5 + vec3(2.0,3.0,0.0));",
        // in linear space
        "  col = col*col;",

        // do the smooth min for colors and distances
        "  float h = smoothstep( -1.0, 1.0, (m.x-d)/w );",
        "  m.x   = mix( m.x,     d, h ) - h*(1.0-h)*w/(1.0+3.0*w); ",// distance
        "  m.yzw = mix( m.yzw, col, h ) - h*(1.0-h)*w/(1.0+3.0*w);", // color
        " }",

        " return m;",
        "}",

         // https://iquilezles.org/articles/palettes/
        // cosine based palette, 4 vec3 params
        "vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {",
          "return a + b*cos( 6.283185*(c*t+d) );",
        "}",

        "void main() {",
        //"void main(out vec4 FragColor, in vec2 FragCoord) {",


       // "void main() {",
        //"vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;",
        //"uv.x *= iResolution.x / iResolution.y;",

        "vec2 p =gl_FragCoord.xy/iResolution.y;",
        "p += hash2( p ) * 0.005;",

        "vec4 v = voronoi( 1.5 * p, 0.05 );",

        "vec3 col = palette((v.x + v.y + v.z + v.w) * 0.3 - (p.y - 0.5) * 0.3,",
        "vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30)",
        ");",

        "col *= 0.9;",
        "col += 0.1;",

        "col = pow(col, vec3(0.5));",

        "gl_FragColor.rgb = col;",
        // "FragColor = vec4( col, 1.0 );",
        "}"


      ].join('\n')

    };
    mati = new THREE.ShaderMaterial(SkyShaderii);
   /* mati.map?.repeat.y=20.0;
    mati.map?.repeat.x=20.0;
    mati.needsUpdate = true;*/
    var  plane = new THREE.Mesh( geometry, mati);
    plane.position.set(0.0, -8.0, -2.0);
    scene.add( plane );

    var geo =  THREE.BoxGeometry(0.8, 0.08, 0.8);
   /* var mat = new THREE.MeshPhysicalMaterial({
      'color':THREE.Color(0x213555)
    });*/
    var mat = new THREE.MeshPhysicalMaterial();

  /* var texture = await THREE.TextureLoader().loadAsync('assets/textures/wood.jpg');
   // var texture = await THREE.TextureLoader().load('textures/land_ocean_ice_cloud_2048.jpg' );
// immediately use the texture for material creation

    var mat = new THREE.MeshBasicMaterial( { 'map':texture } );*/
 //   var mat = THREE.MeshStandardMaterial();

   // mat.emissive = THREE.Color(
   //     0x213555);//665600);
    mat.emissive=THREE.Color(0x049ef4);
   // mat.color=THREE.Color(0x049ef4);
    mat.metalness = 1;
    mat.roughness = 0.5;
 /*   THREE_JSM.RGBELoader _loader = THREE_JSM.RGBELoader();
    _loader.setPath('assets/textures/');
    var _hdrTexture = await _loader.loadAsync('quarry_01_1k.hdr');
    _hdrTexture.mapping = THREE.EquirectangularReflectionMapping;
    mat.envMap=_hdrTexture;
    mat.aoMap=_hdrTexture;
    mat.emissiveMap=_hdrTexture;
    mat.needsUpdate = true;*/

    base = new THREE.Mesh(geo, mat);
    base.position.set(0.0, -0.5, 0.0);
    scene.add(base);

    tower = [base];
    currentBlock  = base;

    camera.lookAt(base.position);

    var fpsControl = PointerLockControls(camera, _globalKey);

    fpsControl.domElement.addEventListener('keyup', (event) {

      //_joystick?.keyboard.onKeyChange(event, 'keyup');

      /// if(event.keyId == 32){
      //  playerVelocity.y = 15;
      // }
    }, false);
    fpsControl.domElement.addEventListener('keydown', (event) {
      if (event.keyId==32&& !isGameOver && currentBlock != base)
        checkOverlap();
     // _joystick?.keyboard.onKeyChange(event, 'keydown');
    }, false);
    fpsControl.domElement.addEventListener('pointerup', (event) {
      //throwBall();
      //print("mmm");
    }, false);
    fpsControl.domElement.addEventListener('pointerdown', (event) {
      if ( !isGameOver && currentBlock != base)
         checkOverlap();
     // _joystick?.onTouchDown(event.clientX, event.clientY);
      //print("mmm");
    }, false);
    //  if (!kIsWeb) {
    fpsControl.domElement.addEventListener('pointerup', (event) {
     // _joystick?.onTouchUp();
      //print("mmm");
    }, false);
    fpsControl.domElement.addEventListener('pointermove', (event) {
      // this should be in openworld!!
      /*if (!_joystick?.getStickPressed()) {

        _joystick?.onTouch(
            event.clientX, event.clientY, width, height, clock.getDelta());

      }*/
    }, false);


    setState(() {
      loaded = true;
    });

    animate();
    startGame();
    setState(() {
      msg="Press Space to lower the block";
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        msg="";
      });
    });
  }




  var frames = 0;
  var frames10 = 0;


  animate() async {
    // if app in background dont keep animating
    //print("animate");
   /* if (!kIsWeb ) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        animate();
      });
      return;
    }*/

    if (!mounted || disposed) {
      return;
    }

    if (!loaded) {
      return;
    }
    frames++;
    frames10++;
    var frameTime = clock.getDelta();

    //controls(frameTime.toDouble());


    if (currentBlock is Block) {
      if (currentBlock.direction == 1) {
        if (currentBlock.position.x + speed > rightEx)
          currentBlock.direction = 2;
        else
          currentBlock.position.setX(currentBlock.position.x + speed);
      } else if (currentBlock.direction == 2) {
        if (currentBlock.position.x - speed < leftEx)
          currentBlock.direction = 1;
        else
          currentBlock.position.setX(currentBlock.position.x - speed);
      } else if (currentBlock.direction == 3) {
        if (currentBlock.position.z + speed > frontEx)
          currentBlock.direction = 4;
        else
          currentBlock.position.setZ(currentBlock.position.z + speed);
      } else if (currentBlock.direction == 4) {
        if (currentBlock.position.z - speed < backEx)
          currentBlock.direction = 3;
        else
          currentBlock.position.setZ(currentBlock.position.z - speed);
      }
      if (fallingArea != null) {
        fallingArea.position.setY(fallingArea.position.y - 0.08);
      }
    }


    // Move the shader
    iTime+=40.0*speed*frameTime;//0.05;
    if (wobble) {
      tower[tower.length-1].rotateX(0.006 * (cos(10 * iTime)));
      tower[tower.length-1].rotateY(0.006 * (sin(10 * iTime)));
      tower[tower.length-1].rotateZ(0.006 * (sin(10 * iTime)));
      if (tower[tower.length-1].position.y>tower[tower.length-1].extra['yPosOrig']) {
        tower[tower.length - 1].position.setY(
            tower[tower.length - 1].position.y - frameTime);
        print("down");
      }

    }
 //   base.rotateY(frameTime);

   // print("time"+iTime.toString());
    mati.uniforms['iTime']['value'] = iTime;//{

 //   matii.uniforms['iTime']['value'] = iTime;//{
    render();

    Future.delayed(Duration(
        milliseconds: 40), () { // was 40 which is 1000/40 = 25 fps
      animate();
    });
  }



  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;

    three3dRender.dispose();

    super.dispose();
  }
}
