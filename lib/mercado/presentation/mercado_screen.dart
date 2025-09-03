import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_comprinhas/mercado/presentation/bloc/mercado_bloc.dart';

class MercadoScreen extends StatelessWidget {
  const MercadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => context.read<MercadoBloc>().add(SendNfe('33250817833301002819652070002722239353987899')),
        child: const Text("teste"),
      ),
    );
  }
}
