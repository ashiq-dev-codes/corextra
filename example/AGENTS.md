# Example App Instructions

Rules for `example/`. Package-wide rules are in [../AGENTS.md](../AGENTS.md).

This is a runnable demo of every corextra feature, including the DevTools panel. It isn't published, but people read it to learn how to use the package, so write it the way a real app should.

- Import only `package:corextra/corextra.dart`, never a file under `package:corextra/` directly. If the demo needs something that isn't exported, the package is missing an export.
- Keep the layers: widgets in `lib/presentation/`, demo actions in [demo_controller.dart](lib/application/demo_controller.dart), Dio setup in [network_service.dart](lib/infrastructure/network/network_service.dart).
- A new demo is a method on `DemoController` and a button in the matching tab under `lib/presentation/tabs/`.
- Demo actions catch the errors they expect, such as `DioException`, so an error scenario doesn't crash the demo.
- Use `https://httpbin.org` for real requests. For a response it can't produce, add a scenario to [fake_scenario_interceptor.dart](lib/infrastructure/network/fake_scenario_interceptor.dart) and call `/simulate/<key>`. That interceptor stays last in the chain so the logging interceptors still see the response.
- `pubspec.lock` is committed here (unlike the package) so the demo builds the same way every time.
