import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class UsuarioProvider extends ChangeNotifier {
  UserModel? _usuario;

  UserModel? get usuario => _usuario;

  void setUsuario(UserModel usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrarSesion() {
    _usuario = null;
    notifyListeners();
  }
}
