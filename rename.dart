import 'dart:io';
import 'dart:async';

class Path{
  String androidManifestPath = ".\\android\\app\\src\\main\\AndroidManifest.xml";
  String androidKotlinPath = ".\\android\\app\\src\\main\\kotlin\\"; //additional
  String iosInfoPlistPath = ".\\ios\\Runner\\Info.plist";
  String androidAppBuildGradlePath = ".\\android\\app\\build.gradle";
  String iosProjectPbxprojPath = ".\\ios\\Runner.xcodeproj\\project.pbxproj";
  String macosAppInfoxprojPath = ".\\macos\\Runner\\Configs\\AppInfo.xcconfig";
  String pubspec = ".\\pubspec.yaml";

  Path._privateConstructor();

  static final Path _instance = Path._privateConstructor();

  static Path get instance {
    if (Platform.isMacOS || Platform.isLinux) {
      _instance.androidManifestPath = "android/app/src/main/AndroidManifest.xml";
      _instance.androidKotlinPath = "android/app/src/main/kotlin/"; //additional
      _instance.iosInfoPlistPath = "ios/Runner/Info.plist";
      _instance.androidAppBuildGradlePath = "android/app/build.gradle";
      _instance.iosProjectPbxprojPath = "ios/Runner.xcodeproj/project.pbxproj";
      _instance.macosAppInfoxprojPath = "macos/Runner/Configs/AppInfo.xcconfig";
      _instance.pubspec = "pubspec.yaml";
    }
    return _instance;
  }
}

class Utils{
  static Future<List<String>> readFileAsLineByline({String filePath}) async {
    String fileAsString = await File(filePath).readAsString();
    return fileAsString.split("\n");
  }

  static Future<File> writeFile({String filePath, String content}) {
    return File(filePath).writeAsString(content);
  }

  // ignore: missing_return
  static Future<String> getCurrentIosAppName() async {
    List contentLineByLine = await readFileAsLineByline(
      filePath: Path.instance.iosInfoPlistPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("<key>CFBundleName</key>")) {
        return (contentLineByLine[i + 1] as String).trim().substring(5, 5);
      }
    }
  }

  // ignore: missing_return
  static Future<String> getCurrentAndroidAppName() async {
    List contentLineByLine = await readFileAsLineByline(
      filePath: Path.instance.androidManifestPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("android:label")) {
        return (contentLineByLine[i] as String).split('"')[1];
      }
    }
  }

  // ignore: missing_return
  static Future<String> getCurrentAndroidBundleId() async {
    List contentLineByLine = await readFileAsLineByline(
      filePath: Path.instance.androidManifestPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("package")) {
        return (contentLineByLine[i] as String).split('"')[1];
      }
    }
  }


}


class Android{
  Future<File> changeAndroidAppName(String appName) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.androidManifestPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("android:label")) {
        contentLineByLine[i] = "        android:label=\"${appName}\"";
        break;
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.androidManifestPath,
      content: contentLineByLine.join('\n'),
    );
    print("Android appname changed successfully to : $appName");
    return writtenFile;
  }

  Future<void> changeAndroidBundleId(String oldId, String newId) async{
    print("OLD: $oldId >> NEW: $newId");

    var currentPackageDir = oldId.replaceAll('.', '\\') + '\\';
    var newPackageDir = newId.replaceAll('.', '\\') + '\\';

    if (Platform.isMacOS || Platform.isLinux) {
      currentPackageDir = oldId.replaceAll('.', '/') + '/';
      newPackageDir = oldId.replaceAll('.', '/') + '/';
    }

    print("CurrentPkgDir:: $currentPackageDir");
    var mainActivityPath = Path.instance.androidKotlinPath + currentPackageDir + "MainActivity.kt";
    var mainActivityRead = await Utils.readFileAsLineByline(
      filePath: mainActivityPath,
    );

    for (int i = 0; i < mainActivityRead.length; i++) {
      if (mainActivityRead[i].contains("package $oldId")) {
        mainActivityRead[i] = "package $newId";
        break;
      }
    }

    var findFirstDomainNameForDir = oldId.split('.')[0].toString();
    var domainDirForDelete = Directory(Path.instance.androidKotlinPath + findFirstDomainNameForDir);
    domainDirForDelete.deleteSync(recursive: true);
    

    var newDomainDirectoryPath = Path.instance.androidKotlinPath + newPackageDir;
    print("newDomainDirectoryPath: ${newDomainDirectoryPath.toString()}");

    new Directory(newDomainDirectoryPath).create(recursive: true).then((Directory newDir) async{
      print("CreatednewPath:: ${newDir.path}");
      await Utils.writeFile(
        filePath: newDir.path + "MainActivity.kt",
        content: mainActivityRead.join('\n'),
      );
    });

    print("Android bundleId package changed with folder system");

    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.androidAppBuildGradlePath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("applicationId")) {
        contentLineByLine[i] = "        applicationId \"${newId.toString()}\"";
        break;
      }
    }

    await Utils.writeFile(
      filePath: Path.instance.androidAppBuildGradlePath,
      content: contentLineByLine.join('\n'),
    );
    print("Android bundleId changed successfully to : $newId");


    List contentLineByLine2 = await Utils.readFileAsLineByline(
      filePath: Path.instance.androidManifestPath,
    );
    for (int i = 0; i < contentLineByLine2.length; i++) {
      if (contentLineByLine2[i].contains("package")) {
        contentLineByLine2[i] = "        package=\"${newId.toString()}\"";
        break;
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.androidManifestPath,
      content: contentLineByLine2.join('\n'),
    );
    print("Android manifest package name changed to : $newId");
    
  }
}


class Apple {
  Future<File> changeIosBundleId({String bundleId}) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.iosProjectPbxprojPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("PRODUCT_BUNDLE_IDENTIFIER")) {
        contentLineByLine[i] = "				PRODUCT_BUNDLE_IDENTIFIER = $bundleId;";
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.iosProjectPbxprojPath,
      content: contentLineByLine.join('\n'),
    );
    print("IOS BundleIdentifier changed successfully to : $bundleId");
    return writtenFile;
  }

  Future<File> changeMacOsBundleId({String bundleId}) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.macosAppInfoxprojPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("PRODUCT_BUNDLE_IDENTIFIER")) {
        contentLineByLine[i] = "PRODUCT_BUNDLE_IDENTIFIER = $bundleId;";
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.macosAppInfoxprojPath,
      content: contentLineByLine.join('\n'),
    );
    print("MacOS BundleIdentifier changed successfully to : $bundleId");
    return writtenFile;
  }

  Future<File> changeIosAppName(String appName) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.iosInfoPlistPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("<key>CFBundleName</key>")) {
        contentLineByLine[i + 1] = "\t<string>${appName}</string>\r";
        break;
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.iosInfoPlistPath,
      content: contentLineByLine.join('\n'),
    );
    print("IOS appname changed successfully to : $appName");
    return writtenFile;
  }

  Future<File> changeMacOsAppName(String appName) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.macosAppInfoxprojPath,
    );
    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("PRODUCT_NAME")) {
        contentLineByLine[i] = "PRODUCT_NAME = $appName;";
        break;
      }
    }
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.macosAppInfoxprojPath,
      content: contentLineByLine.join('\n'),
    );
    print("MacOS appname changed successfully to : $appName");
    return writtenFile;
  }
}

class PubSpec{
  Future<File> change(String appName, String description) async {
    List contentLineByLine = await Utils.readFileAsLineByline(
      filePath: Path.instance.pubspec,
    );

    int i = 0;

    for (int i = 0; i < contentLineByLine.length; i++) {
      if (contentLineByLine[i].contains("name:")) {
        contentLineByLine[i] = "name: $appName;";
        i++;
      }
      if (contentLineByLine[i].contains("description:")) {
        contentLineByLine[i] = "description: $description;";
        i++;
      }
      if (i == 2){
        break;
      }
    }
    
    File writtenFile = await Utils.writeFile(
      filePath: Path.instance.pubspec,
      content: contentLineByLine.join('\n'),
    );

    print("Updated pubspec.yaml: $appName | $description");
    return writtenFile;
  }
}


// store build.enb
Map<String, String> build;

void main(List<String> args) async{
  // init empty build.env object
  build = Map();

  // Storage to build variable from build.env file
  List<String> lines = new File('build.env').readAsLinesSync();
  for (var line in lines) {
    if (line.isNotEmpty && line[0] != "#"){ //skip comment line and empty line
      var splitted = line.split("=");
      build[splitted[0]] = splitted[1];
    }
  } 

  // FileRepository repo = new FileRepository();

  // Change app name
  // await repo.changeAndroidAppName(build["APPLICATION_NAME"]);
  // await repo.changeIosAppName(build["APPLICATION_NAME"]);
  // await repo.changeMacOsAppName(build["APPLICATION_NAME"]);

  // Bundle Id
  // await repo.changeIosBundleId(bundleId: build["DOMAIN_NAME"]);
  // await repo.changeMacOsBundleId(bundleId: build["DOMAIN_NAME"]);

  Android android = new Android();
  Apple apple = new Apple();
  PubSpec pubspec = new PubSpec();

  
  var currentPackageName = await Utils.getCurrentAndroidBundleId();

  await android.changeAndroidAppName(build["APPLICATION_NAME"]);
  await android.changeAndroidBundleId(currentPackageName, build["DOMAIN_NAME"]);

  await apple.changeIosAppName(build["APPLICATION_NAME"]);
  await apple.changeIosBundleId(bundleId: build["DOMAIN_NAME"]);
  await apple.changeMacOsAppName(build["APPLICATION_NAME"]);
  await apple.changeMacOsBundleId(bundleId: build["DOMAIN_NAME"]);

  await pubspec.change(build["APPLICATION_NAME"], build["APPLICATON_DESCRIPTION"])

  print("----------------------------------");
  print("COMPLETED RENAME PROCESSING");
  print("----------------------------------");
}