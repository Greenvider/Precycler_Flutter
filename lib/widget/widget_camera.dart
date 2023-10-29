import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'dart:math';
import 'package:precycler/screen/screen_changePoint.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CameraWidget extends StatefulWidget {
  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
{
  //카메라가 초기화 되었는지를 설정하는 변수
  bool _cameraInitialized = false;

  //카메라 컨트롤러
  late CameraController _cameraController;

  //위젯 초기화 함수
  @override
  void initState()
  {
    super.initState();

    //화면에 처음 진입할 때 카메라 사용을 준비 하도록
    readyToCamera();
  }

  //카메라 사용 준비
  void readyToCamera() async
  {
    // 사용할 수 있는 카메라 목록을 OS로부터 받아 옵니다.
    final cameras = await availableCameras();

    //만약 카메라를 가져올 수 없다면
    if( 0 == cameras.length )
    {
      //로그 출력
      print( "not found any cameras" );
      return;
    }

    //마메라 저장할 변수
    late CameraDescription backCamera;

    //가져온 카메라만큼 for문 돌리기
    for( var camera in cameras )
    {
      //만약 현재 반복중인 카메라가 후면 카메라라면
      if( camera.lensDirection == CameraLensDirection.back )
      {
        //변수에 저장
        backCamera = camera;
        break;
      }
    }

    //카메라 컨트롤러 설정
    _cameraController =
        CameraController(
          //카메라는 저장한 카메라로
          backCamera,

          //카메라 해상도는 최대 해상도
          ResolutionPreset.max, // 가장 높은 해상도의 기능을 쓸 수 있도록 합니다
        );

    //카메라 컨트롤러 초기화
    _cameraController.initialize()
        .then(
            ( value )
        {
          // 카메라 준비가 끝나면 카메라 컨트롤러 초기화 변수 참으로 바꾸기
          setState( ()=>_cameraInitialized = true );
        } );
  }

  //셔터를 누르고 페이지 전환 사이에서 현재 로딩중인지를 판단하는 변수
  bool _isLoadingChangePointScreen = false;

  @override
  Widget build(BuildContext context) {
    //미디어 쿼리로 width와 height을 지정하여 상대적인 수치 사용
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    //현재 로딩을 해야 한다면
    if (_isLoadingChangePointScreen) {
      //로딩 인디케이터 표시
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
    }
    //로딩을 해야하지 않다면 정상적인 화면 출력
    else {
      //만약 카메라가 초기화되었다면
      return _cameraInitialized
          //정상적인 화면 출력
          ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //간격
              Container(height: height * 0.05),

              //현재 보유 포인트 출력
              Text(
                '000님의 보유 포인트는 190입니다',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),

              //간격
              Container(height: height * 0.08),

              //카메라 미리보기
              Container(
                height: width * 0.8,
                width: width * 0.8,
                //미리보기 위젯 호출
                child: _cameraPreview(),
              ),

              //간격
              Container(height: height * 0.05),

              //셔터버튼
              IconButton(
                //셔터를 누르면
                onPressed: () {
                  //셔터눌림 함수 호출
                  onSutterPressed(context);
                },
                icon: Icon(Icons.camera_alt),
              ),
            ],
          )
          //만약 초기화되지 않았다면 로딩화면 출력
          : Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
    }
  }

  //카메라 미리보기 위젯
  Widget _cameraPreview() {
    //미디어 쿼리로 width와 height을 지정하여 상대적인 수치 사용
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;
    //미리보기 비율 1:1로 보여주기
    return Stack(
      children: [
        //미리보기
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40.0),
            child: Transform.scale(
              scale: _cameraController.value.aspectRatio,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
            ),
          ),
        ),

        //topLeft
        Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: width*0.1,left:width*0.1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    left: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                  ),
                ),
                width: width*0.1, // 모서리의 크기를 조절하세요
                height: width*0.1,
              ),
            )
        ),
        //topRight
        Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(top: width*0.1,right:width*0.1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    right: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                  ),
                ),
                width: width*0.1, // 모서리의 크기를 조절하세요
                height: width*0.1,
              ),
            )
        ),
        //bottomLeft
        Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: width*0.1,left:width*0.1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    left: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                  ),
                ),
                width: width*0.1, // 모서리의 크기를 조절하세요
                height: width*0.1,
              ),
            )
        ),
        //bottomRight
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: width*0.1, right:width*0.1),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    right: BorderSide(
                      color: Colors.white,
                      width: 4.0,
                    ),
                  ),
                ),
                width: width*0.1, // 모서리의 크기를 조절하세요
                height: width*0.1,
              ),
            )
        ),
      ],
    );
  }

  //셔터 눌림 함수
  void onSutterPressed(BuildContext context) async {
    //로딩 시작
    setState(() {
      _isLoadingChangePointScreen = true;
    });

    //플래쉬 끄기
    _cameraController.setFlashMode(FlashMode.off);

    //사직 찍기
    final XFile image = await _cameraController.takePicture();

    //미리보기에 맞도록 이미지 자르기
    ImageProperties properties = await FlutterNativeImage.getImageProperties(image.path);
    var cropSize = min(properties.width!,properties.height!);
    int offSetX = (properties.width! - cropSize) ~/2;
    int offSetY = (properties.height! - cropSize) ~/2;
    var imageFile = await FlutterNativeImage.cropImage(image.path, offSetX, offSetY, cropSize, cropSize);

    //서버로 이미지 전송을 위해 base64로 변환
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);


    //포인트 전환 페이지로 이동
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePointScreen(),
      ),
    );

    //로딩 끝내기
    setState(() {
      _isLoadingChangePointScreen = false;
    });

    return;
  }
}