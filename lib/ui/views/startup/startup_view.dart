import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'startup_viewmodel.dart';

class StartupView extends ViewModelBuilderWidget<StartupViewModel>{
  const StartupView({Key key}) : super(key: key);

  @override
  bool get reactive => false;

  @override
  bool get createNewModelOnInsert => false;

  @override
  bool get disposeViewModel => true;

  @override
  Widget builder(BuildContext context, StartupViewModel model, Widget child) {
    return Scaffold(
      body: Center(
        child: Text(
            'Startup View'
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: model.navigateToHome,
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(BuildContext context) {
    return StartupViewModel();
  }
}