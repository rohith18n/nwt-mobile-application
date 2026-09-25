import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final double? size;

  const LoadingWidget({
    Key? key,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? MediaQuery.of(context).size.width * 0.45,
        child: Lottie.asset('assets/lottie/mf_loading.json'),
      ),
    );
  }
}
