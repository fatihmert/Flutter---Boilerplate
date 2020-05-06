// Only CLI params

import 'dart:io';
import 'dart:async';

class Utils{
  static Future<List<String>> readFileAsLineByline({String filePath}) async {
    String fileAsString = await File(filePath).readAsString();
    return fileAsString.split("\n");
  }

  static Future<File> writeFile({String filePath, String content}) {
    return File(filePath).writeAsString(content);
  }

  static String pascalCase(String term){
    return '${term.substring(0, 1).toUpperCase()}${term.substring(1).toLowerCase()}';
  }
}

class Path{
  String templates = ".\\templates\\";

  String ui = ".\\lib\\ui\\";
  String views = ".\\lib\\ui\\views\\";
  String widgets = ".\\lib\\ui\\widgets\\";

  Path._privateConstructor();

  static final Path _instance = Path._privateConstructor();

  static Path get instance {
    if (Platform.isMacOS || Platform.isLinux) {
      _instance.templates = "templates/";

      _instance.ui = "lib/ui/";
      _instance.views = "lib/ui/views/";
      _instance.widgets = "lib/ui/widgets/";
    }
    return _instance;
  }
}

// store artisan.env
Map<String, String> artisan;

void main(List<String> arguments) async{
  print(arguments.toString());

  // init empty artisan.env object
  artisan = Map();

  // Storage to build variable from build.env file
  List<String> lines = new File('artisan.env').readAsLinesSync();
  for (var line in lines) {
    if (line.isNotEmpty && line[0] != "#"){ //skip comment line and empty line
      var splitted = line.split("=");
      artisan[splitted[0]] = splitted[1];
    }
  }

  print("ARTISAN:: ${artisan.toString()}");

  if(arguments.length == 2){
    // Only View and Widget

    if(arguments[0].toLowerCase() == "view"){ // Create view
      var name = arguments[1];
      var folderName = name.toLowerCase();
      var classNamePrefix = Utils.pascalCase(name);

      var viewName = classNamePrefix + artisan["VIEW_APPENDIX"];
      var viewModelName = classNamePrefix + artisan["VIEWMODEL_APPENDIX"];

      var viewFileName = folderName + "_" + artisan["VIEW_APPENDIX"].toLowerCase();
      var viewModelFileName = folderName + "_" + artisan["VIEWMODEL_APPENDIX"].toLowerCase();

//      print("name:: $name | FolderName:: $folderName | classNamePrefix:: $classNamePrefix \nViewName: $viewName | ViewModelName: $viewModelName");
//      print("ViewFileName:: $viewFileName | ViewModelFileName:: $viewModelFileName");

      bool exists = await Directory(Path.instance.views + folderName).exists();

      if (exists){
        throw("Already ${Path.instance.views + folderName} directory exists!");
      }else{
        var _viewFile = new File(Path.instance.templates + artisan["VIEW_TEMPLATE"]).readAsStringSync();
        var _viewModelFile = new File(Path.instance.templates + artisan["VIEWMODEL_TEMPLATE"]).readAsStringSync();

        _viewFile = _viewFile.replaceAll("{VIEW_NAME}", viewName).replaceAll("{VIEW_MODEL_NAME}", viewModelName).replaceAll("{VIEW_MODEL_FILE_NAME}", viewModelFileName);
        _viewModelFile = _viewModelFile.replaceAll("{VIEW_NAME}", viewName).replaceAll("{VIEW_MODEL_NAME}", viewModelName);

//        print("NEW_VIEW_FILE:: ${_viewFile.toString()}");
//        print("NEW_VIEW_MODEL_FILE:: ${_viewModelFile.toString()}");

        new Directory(Path.instance.views + folderName).create().then((Directory newDir) async{
          var transPathForPlatform = newDir.path + "\\";
          if (Platform.isMacOS || Platform.isLinux) {
            transPathForPlatform = newDir.path + "/";
          }

          await Utils.writeFile(
            filePath: transPathForPlatform + viewFileName + ".dart",
            content: _viewFile
          );

          await Utils.writeFile(
            filePath: transPathForPlatform + viewModelFileName + ".dart",
            content: _viewModelFile
          );

          print("CREATED ${viewName.toString()} View !");
        });

      }
    }
  }


}