import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flexiphones/helpers/st_values.dart';
import 'package:flutter/material.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class Bgw extends StatelessWidget {
  const Bgw({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RotatedBox(
          quarterTurns: 90,
          child: WaveWidget(
            config: CustomConfig(
              colors:
                  AdaptiveTheme.of(context).mode.isDark
                      ? STV.waveColors2Dark
                      : STV.waveColors2,
              durations: STV.waveDurations,

              heightPercentages: STV.waveHeightPercentages2,
            ),
            backgroundColor: Colors.transparent,
            size: Size(double.infinity, 50),
            waveAmplitude: 10,
            waveFrequency: 0.8,
          ),
        ),
        SizedBox(height: 50),
        Opacity(
          opacity: 0.05,
          child: RotatedBox(
            quarterTurns: 180,
            child: WaveWidget(
              config: CustomConfig(
                colors:
                    AdaptiveTheme.of(context).mode.isDark
                        ? STV.waveColorsDark
                        : STV.waveColors,
                durations: STV.waveDurations,

                heightPercentages: STV.waveHeightPercentages2,
              ),
              backgroundColor: Colors.transparent,
              size: Size(double.infinity, 250),
              waveAmplitude: 20,
              waveFrequency: 1.8,
            ),
          ),
        ),
        Expanded(
          child: WaveWidget(
            config: CustomConfig(
              colors:
                  AdaptiveTheme.of(context).mode.isDark
                      ? STV.waveColorsDark
                      : STV.waveColors,
              durations: STV.waveDurations,

              heightPercentages: STV.waveHeightPercentages,
            ),
            backgroundColor: Colors.transparent,
            size: Size(double.infinity, double.infinity),
            waveAmplitude: 1,
          ),
        ),
      ],
    );
  }
}

class Bgw2 extends StatelessWidget {
  const Bgw2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: 0.5,
          child: RotatedBox(
            quarterTurns: 90,
            child: WaveWidget(
              config: CustomConfig(
                colors:
                    AdaptiveTheme.of(context).mode.isDark
                        ? STV.waveColors33Dark
                        : STV.waveColors33,
                durations: STV.waveDurations,

                heightPercentages: STV.waveHeightPercentages2,
              ),
              backgroundColor: Colors.transparent,
              size: Size(double.infinity, 100),
              waveAmplitude: 10,
              waveFrequency: 0.8,
            ),
          ),
        ),
        SizedBox(height: 50),
        Opacity(
          opacity: 0.00,
          child: RotatedBox(
            quarterTurns: 180,
            child: WaveWidget(
              config: CustomConfig(
                colors:
                    AdaptiveTheme.of(context).mode.isDark
                        ? STV.waveColorsDark
                        : STV.waveColors,
                durations: STV.waveDurations,

                heightPercentages: STV.waveHeightPercentages2,
              ),
              backgroundColor: Colors.transparent,
              size: Size(double.infinity, 250),
              waveAmplitude: 20,
              waveFrequency: 1.8,
            ),
          ),
        ),
        Expanded(
          child: WaveWidget(
            config: CustomConfig(
              colors:
                  AdaptiveTheme.of(context).mode.isDark
                      ? STV.waveColors3Dark
                      : STV.waveColors3,
              durations: STV.waveDurations,

              heightPercentages: STV.waveHeightPercentages,
            ),
            backgroundColor: Colors.transparent,
            size: Size(double.infinity, double.infinity),
            waveAmplitude: 1,
          ),
        ),
      ],
    );
  }
}

class Bgw3 extends StatelessWidget {
  const Bgw3({super.key});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 90,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: WaveWidget(
          config: CustomConfig(
            colors:
                AdaptiveTheme.of(context).mode.isDark
                    ? STV.waveColors33aDark
                    : STV.waveColors33a,
            durations: STV.waveDurations,

            heightPercentages: [0.20, 0.60, 0.75, 0.90],
          ),
          backgroundColor: Colors.transparent,
          size: Size(double.infinity, 100),
          waveAmplitude: 10,
          waveFrequency: 0.9,
        ),
      ),
    );
  }
}

class Bgw4 extends StatelessWidget {
  const Bgw4({super.key});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 90,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: WaveWidget(
          config: CustomConfig(
            colors:
                AdaptiveTheme.of(context).mode.isDark
                    ? STV.waveColors33a1Dark
                    : STV.waveColors33a1,
            durations: STV.waveDurations,

            heightPercentages: [0.20, 0.60, 0.75, 0.90],
          ),
          backgroundColor: Colors.transparent,
          size: Size(double.infinity, 100),
          waveAmplitude: 10,
          waveFrequency: 0.9,
        ),
      ),
    );
  }
}
