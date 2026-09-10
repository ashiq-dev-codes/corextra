import 'package:corextra/corextra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveBreakpoints.deviceTypeOf', () {
    test('classifies widths below lg as mobile', () {
      expect(ResponsiveBreakpoints.deviceTypeOf(320), DeviceType.mobile);
    });

    test('classifies widths between lg and xl as tablet', () {
      expect(ResponsiveBreakpoints.deviceTypeOf(800), DeviceType.tablet);
    });

    test('classifies widths at or above xl as desktop', () {
      expect(ResponsiveBreakpoints.deviceTypeOf(1200), DeviceType.desktop);
    });
  });

  group('ResponsiveBreakpoints.valueOf', () {
    test('falls back to base when width is below every provided breakpoint', () {
      expect(
        ResponsiveBreakpoints.valueOf<int>(300, base: 1, md: 2, lg: 3),
        1,
      );
    });

    test('returns the highest-matching provided value', () {
      expect(
        ResponsiveBreakpoints.valueOf<int>(600, base: 1, sm: 2, md: 3),
        3,
      );
      expect(
        ResponsiveBreakpoints.valueOf<int>(900, base: 1, md: 2, lg: 3),
        3,
      );
    });

    test('skips breakpoints with no value and keeps looking downward', () {
      expect(
        ResponsiveBreakpoints.valueOf<int>(2000, base: 1, lg: 3),
        3,
      );
    });
  });

  group('ResponsiveContextExtensions', () {
    testWidgets('deviceType, screen size and responsive() reflect MediaQuery', (
      tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 400)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(capturedContext.screenWidth, 900);
      expect(capturedContext.screenHeight, 400);
      expect(capturedContext.isLandscape, isTrue);
      expect(capturedContext.isPortrait, isFalse);
      expect(capturedContext.deviceType, DeviceType.tablet);
      expect(capturedContext.isTablet, isTrue);
      expect(capturedContext.responsive(base: 1, md: 2, lg: 3), 3);
    });
  });

  group('ResponsiveConstraintsExtensions', () {
    test('deviceType classifies maxWidth', () {
      expect(
        const BoxConstraints(maxWidth: 320).deviceType,
        DeviceType.mobile,
      );
      expect(
        const BoxConstraints(maxWidth: 800).deviceType,
        DeviceType.tablet,
      );
      expect(
        const BoxConstraints(maxWidth: 1200).deviceType,
        DeviceType.desktop,
      );
    });

    test('responsive() picks the highest matching value for maxWidth', () {
      expect(
        const BoxConstraints(maxWidth: 900).responsive(base: 1, md: 2, lg: 3),
        3,
      );
    });

    test('isPortrait / isLandscape compare maxWidth and maxHeight', () {
      expect(
        const BoxConstraints(
          maxWidth: 300,
          maxHeight: 600,
        ).isPortrait,
        isTrue,
      );
      expect(
        const BoxConstraints(
          maxWidth: 600,
          maxHeight: 300,
        ).isLandscape,
        isTrue,
      );
    });
  });
}
